#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to merge the signatures of <src> to the wrapped callable <dst> by expanding the <...> defined in <dst>,     #
#   | similar to <functools.wraps> in Python but applied to extended argument list in high order functions                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] One can extend the arguments of <src> with certain high order function, and merge the signature of <src> into the wrapper, also#
#   |     for the caller to inspect the new signature wrapped by that high order function                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |RATIONALE                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Without this class, when you need to call the traditionally wrapped callable, you need to do <dst(arg1,...)>, where            #
#   |     all these arguments are from the definition of <dst>. This indicates <...> holds all arguments of <src>                       #
#   |[2] We follow this rule, but further expand <...> by filling the respective holes with those in <src>                              #
#   |[3] By doing this, we hold the proper argument sequence and expansion rules                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SEQUENCE                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] All arguments in <src> will be expanded and replace <...> in the formals/signature of <dst>                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |EXPANSION                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Shared arguments in <src> and <dst> will be removed during expansion of <...> in <dst>, so there should be extra injection in  #
#   |     the function body of <dst> to send them back to the call to <src>, preferrably using <updParams()>, see the examples          #
#   |[5] Expansion is always done so <src> without argument will lead <dst> to output without <...> in the signature                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/2458013/what-ways-are-there-to-edit-a-function-in-r                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[initialize]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate the container of data input-output methods                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |src               :   <callable >Function as source to extract the signature and take place of the expanded holes in <dst> #
#   |   |   |instance          :   <chr      >Character string as the name of the wrapped instance holding various mutation methods     #
#   |   |   |                      [<see def.>          ]<Default> Use the default name, which is safe across different frames, as it is#
#   |   |   |                                                       defined in a local environment                                      #
#   |   |   |                      [chr                 ]          Valid character string to name the local R6Class                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<NULL>            :   Only for initialization                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[wrap]                                                                                                                         #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to create the decorator to merge the signature of <src> to <dst>                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |dst               :   <callable >Function to expand signature with that of <src>                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The decorated result                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[getParam]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to identify the input value inside the parameters represented by <...> by argument name, in    #
#   |   |   |   | terms of the signature of <src>                                                                                       #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |IMPORTANT                                                                                                              #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] This method is embedded in the local instance named by <instance> at instantiation                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |arg               :   <str     > Name of the argument in <src> to extract the input value from the parameters as passed to #
#   |   |   |                       the potential call of <src>                                                                         #
#   |   |   |args_             :   <alist   > Parameters passed to the arguments for the call to <src>                                  #
#   |   |   |inc_default       :   <logical > Whether to include the default values if no input is provided at runtime                  #
#   |   |   |                      [TRUE                ]<Default> Include the default values if no input is provided at runtime        #
#   |   |   |                      [FALSE               ]          Only obtain the input value at runtime                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<any>             :   Any possible type of value passed for <arg>                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[updParams]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to update the dedicated input parameters and validate the call to <src> in terms of the        #
#   |   |   |   | signature of <src>                                                                                                    #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |IMPORTANT                                                                                                              #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] This method is embedded in the local instance named by <instance> at instantiation                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |args_upd          :   <list    > Named list to be updated inside the parameters for the call to <src>                      #
#   |   |   |args_src          :   <alist   > Parameters passed to the arguments for the call to <src>                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   The same result returned from <nameArgsByFormals>                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[vfyConflict]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to Verify the conflict of argument names at runtime, to secure the dynamic signature expansion #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |IMPORTANT                                                                                                              #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] This method is embedded in the local instance named by <instance> at instantiation                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |args_share        :   <list    > The argument names shared by both functions that are declared to be excluded              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |None              :   This method is only used to raise exception if conflict is detected                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[isDefault]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to indicate whether the callable (primarily <src>) is called with the default value of an      #
#   |   |   |   | argument instead of from the input                                                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |arg               :   <chr     > The argument name to detect                                                               #
#   |   |   |scope_            :   <chr     > Within which signature of the callables to detect the flag                                #
#   |   |   |                      [src                 ]<Default> Detect the flag in the signature of <src> for most of cases          #
#   |   |   |                      [dst                 ]          Detect the flag in the signature of <dst> for certain cases          #
#   |   |   |                      [<any other strings> ]          Detect the flag among all the arguments with default values          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<logical>         :   True if its parameter passed to the call is from its default value in the signature                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[.genMethods]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to create a local container holding various methods to manipulate the parameters at runtime    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |src               :   <function> The function from which to extract the formals                                            #
#   |   |   |dst               :   <function> The function to be wrapped with expanded signature                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<R6Class>         :   Instance of R6Class                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[.prepFunc]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to obtain the function by its name in case it does not exist in current environment at runtime #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |funcName          :   <chr     > Name as character string of the dedicated function to find                                #
#   |   |   |srcEnv            :   <env     > Environment from which to search for the named function at top priority                   #
#   |   |   |                      [<see def.>          ]<Default> Search in the parent frame for the named function                    #
#   |   |   |                      [environment         ]          A separate environment in which to conduct the search                #
#   |   |   |srcPkg            :   <chr     > Name as character string of the installed package in which to find the dedicated function #
#   |   |   |                                  if it does not exist in current environment                                              #
#   |   |   |srcDir            :   <chr     > Name as character string of the top folder in which to find the dedicated function if it  #
#   |   |   |                                  cannot be obtained by above means                                                        #
#   |   |   |srcFile           :   <chr     > Name as character string of the script name to <source()>, in order to obtain the         #
#   |   |   |                                  dedicated function if it cannot be obtained by above means                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The callable obtained for further process                                                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250213        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20260101        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now supports method retrieval as <src>, e.g. set <CoreUserCalendar$public_methods$initialize> as <src> is now allowed   #
#   |      |[2] Generally <class$method> and <class[['method']]> are both recognized                                                    #
#   |      |[3] This allows to expand the signature of a method of some class, while previously only <function> could be recognized     #
#   |      |[4] Introduce method <isDefault> to detect whether an argument is passed during the call, esp. the call to <src>            #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |R6, rlang, glue, readr                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |nameArgsByFormals                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	R6, rlang, glue, readr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

ExpandSignature <- local({
mycls <- R6::R6Class(
	classname = 'ExpandSignature'
	,public = list(
		#015. Define slots
		..class.. = NULL
		#020. Constructor
		,initialize = function(
			src
			,instance = 'eSig'
			,srcEnv = parent.frame()
			,srcPkg = 'omniR'
			,srcDir = getOption('path.omniR')
			,srcFile = paste0(deparse(substitute(src)), '.r')
		) {
			#020. Local environment
			name_src <- deparse(substitute(src))
			private$src <- private$.prepFunc(name_src, srcEnv, srcPkg, srcDir, srcFile)
			private$instance <- instance
			#[ASSUMPTION]
			#[1] This step MUST BE set after the <initialize> call to the parent class
			#[2] It actually overwrites the same variable in the parent class
			#[3] One can set a unique name to enable storing all class information along the inheritance tree
			self$..class.. <- mycls

			#200. Retrieve the signature of the function
			private$fml_src <- formals(private$src)
			private$has_dots_src <- '...' %in% names(private$fml_src)
		}
		#300. Create the decorator
		,wrap = function(dst) {
			#020. Local environment
			lcl_env <- new.env()
			lcl_env$instance <- private$instance
			lcl_env$src <- private$src
			lcl_env$.genMethods <- private$.genMethods
			lcl_env$intMethods <- private$.genMethods(private$src, dst)
			lcl_env$has_dots_src <- private$has_dots_src

			#[ASSUMPTION]
			#[1] We evaluate the expression of <dst> to obtain the actual R object for the substitution
			#[2] It must evaluated here at the wrapping stage, otherwise it cannot be recognized at the call stage
			lcl_env$dst_call <- dst
			lcl_env$syms_to_call_wo_def <- lcl_env$intMethods$syms_to_call_wo_def
			lcl_env$args_to_call_with_def <- lcl_env$intMethods$args_to_call_with_def

			#800. Reshape the call
			deco <- eval(substitute(function(...){
				#100. Prepare local environment holding necessary methods to use in <dst>
				#[ASSUMPTION]
				#[1] <ExpandSignature> is executed immediately each time it is to be used for wrapping another callable, for it
				#     will be called inside <local({...})>
				#[2] Hence the local states, e.g. <$.isdefault>, will be `remembered` at its first call in current session,
				#     since we use <eval(substitute(...))> here
				#[3] That is why we have to instantiate <eSig> every time INSIDE the body of <deco> to avoid static call
				assign(instance, .genMethods(src, dst_call))

				#300. Determine whether there are inputs for those arguments with default values at runtime
				#[ASSUMPTION]
				#[1] Attributes of <instance> can only be accessed via `[[`, i.e. <.subset2()>, as it is created dynamically
				obj <- get(instance)
				for (nm in names(obj[['.isdefault']])){
					sym_eval <- rlang::sym(nm)
					if (eval(substitute(!missing(sym_eval)))) {
						obj[['.isdefault']][[nm]] <- F
						if (nm %in% names(obj[['defaulted_src']])){
							obj[['.isdefault.scope']][['src']][[nm]] <- F
						}
						if (nm %in% names(obj[['defaulted_dst']])){
							obj[['.isdefault.scope']][['dst']][[nm]] <- F
						}
					} else {
						if (nm %in% names(obj[['defaulted_dst']])){
							if (nm %in% names(obj[['defaulted_src']])){
								obj[['.isdefault.scope']][['src']][[nm]] <- F
							}
						}
					}
				}

				#200. Prepare the inputs
				syms_with_def <- alist()
				for (nm in args_to_call_with_def) {
					if (!obj[['isDefault']](nm, scope_ = 'all')){
						sym_eval <- rlang::sym(nm)
						syms_with_def <- c(syms_with_def, rlang::list2(!!nm := sym_eval))
					}
				}

				#400. Evaluate the dots
				#[ASSUMPTION]
				#[1] One of below statements is never evaluated after the substitution
				#[2] Hence it is safe to reference <...>, even if it does not exist in the modified formals
				if (has_dots_src) {
					dots <- rlang::list2(...)
				} else {
					dots <- alist()
				}

				#500. Update the instance as it has been modified
				assign(instance, obj)

				#550. Assign the local function for the final call
				#[ASSUMPTION]
				#[1] We should set a named object (which is a substituted function in this case) for environment binding
				funcRst <- dst_call

				#700. Bind the substituted function to the local environment
				#[ASSUMPTION]
				#[1] By doing this, the internal reference to the object named by <instance> can be done
				thisenv <- environment()
				environment(funcRst) <- thisenv

				#900. Call <dst> without verification of inputs\
				return(do.call(funcRst, c(syms_with_def, syms_to_call_wo_def, dots)))
			}, env = lcl_env))

			#890. Reset the formals of the decorator
			formals(deco) <- lcl_env$intMethods$fml_deco

			#990. Export the wrapped function
			return(deco)
		}
	)
	,private = list(
		src = NULL
		,instance = NULL
		,fml_src = NULL
		,has_dots_src = NULL
		#200. Prepare the function in case it does not exist at runtime
		,.prepFunc = function(funcName, srcEnv, srcPkg, srcDir, srcFile){
			#100. Determine the input type
			item_getter <- c('\\$','\\[\\[')
			ptn_getter <- paste0('(?:', paste(item_getter, collapse = '|'), ')')
			f_subset <- grepl(ptn_getter, funcName, perl = T)
			if (f_subset){
				ptn_fullstr <- paste0('^(.+?)(', ptn_getter, '.+)$')
				func_name <- gsub(ptn_fullstr, '\\1', funcName, perl = T)
				sub_name <- gsub(ptn_fullstr, '\\2', funcName, perl = T)
				srcFile <- paste0(func_name,'.r')
			} else {
				func_name <- funcName
			}
			func_obj <- NULL

			#300. Direct retrieval from the environment
			try (func_obj <- get(func_name, envir = srcEnv), silent = T)

			#400. Try to obtain the object from the package
			if (is.null(func_obj)){
				if (srcPkg %in% installed.packages()){
					try(
						func_obj <- get(func_name, envir = loadNamespace(srcPkg))
						,silent = T
					)
				}
			}

			#500. Try to load the file from its path and name
			if (is.null(func_obj)){
				f_path <- file.path(srcDir, srcFile)
				if (file.exists(f_path)) {
					f_enc <- readr::guess_encoding(f_path)$encoding[1]
					source(f_path, encoding = f_enc, local = T)
					try (func_obj <- get(func_name), silent = T)
				}
			}

			#600. Look into all sub-directories for the same file name as provided
			if (is.null(func_obj)){
				if (dir.exists(srcDir)) {
					f_rst <- list.files(
						srcDir
						,paste0('^', srcFile, '$')
						,full.names = T
						,ignore.case = T
						,recursive = T
						,include.dirs = T
					)
					if (length(f_rst) == 1) {
						f_enc <- readr::guess_encoding(f_rst[[1]])$encoding[1]
						source(f_rst[[1]], encoding = f_enc, local = T)
						try (func_obj <- get(func_name), silent = T)
					}
				}
			}

			#800. Ensure to obtain the attribute as indicated by the <subset> operator
			if (!is.null(func_obj)){
				if (f_subset) {
					# print(paste0(func_name, ': ', paste0(class(func_obj), collapse = ',')))
					# print(args(eval(str2expression(paste0('func_obj', sub_name)))))
					return(eval(str2expression(paste0('func_obj', sub_name))))
				} else {
					return(func_obj)
				}
			}

			#900. Raise without luck
			stop(glue::glue('[{head(class(self),1)}]Function <{funcName}> does not exist!'))
		}
		#500. Create the container holding various methods to manipulate the parameters at runtime
		,.genMethods = function(src, dst) {
			#100. Define the class with useful methods
			instance <- private$instance
			cls <- R6::R6Class(
				classname = paste0(instance, '.Class')
				,public = list(
					#015. Define slots
					src = NULL
					,dst = NULL
					,defaulted_src = NULL
					,defaulted_dst = NULL
					,args_to_call_with_def = NULL
					,args_to_call_wo_def = NULL
					,syms_to_call_wo_def = NULL
					,.isdefault = NULL
					,.isdefault.scope = NULL
					,fml_deco = NULL
					#020. Constructor
					,initialize = function(src, dst) {
						#100. Identify the attributes of the callables
						#110. Attributes of <src>
						self$src <- src
						private$fml_src <- formals(src)
						if (length(private$fml_src) == 0) {
							self$defaulted_src <- alist()
						} else {
							self$defaulted_src <- private$fml_src[!private$flagPositional(private$fml_src)]
						}

						#150. Attributes of <dst>
						self$dst <- dst
						private$fml_dst <- formals(dst)
						names_dst <- names(private$fml_dst)
						len_fml_dst <- length(private$fml_dst)
						private$named_dst <- private$fml_dst[!names(private$fml_dst) %in% c('...')]
						if (length(private$fml_dst) == 0) {
							self$defaulted_dst <- alist()
						} else {
							self$defaulted_dst <- private$fml_dst[!private$flagPositional(private$fml_dst)]
						}

						#159. Raise exception if there is no available expansion
						#[ASSUMPTION]
						#[1] Since R passes the functions only by their bodies instead of their references, it makes no sense to obtain their
						#     names at runtime
						if (!'...' %in% names_dst) {
							stop(
								glue::glue(paste0(
									'[{head(class(self),1)}]No expansion can be conducted for <src>'
									,' as dots <...> does not exist in <dst>!'
								))
							)
						}

						#200. Identify specific arguments
						#201. Dots
						loc_dots <- head(seq_along(private$fml_dst)[names_dst %in% c('...')], 1)

						#205. Named arguments
						named_dst <- private$fml_dst[!names_dst %in% c('...')]

						#206. All the arguments with default values, overwriting those in <src> with those in <dst>
						private$.defaults <- c(
							self$defaulted_src[!(names(self$defaulted_src) %in% names(self$defaulted_dst))]
							,self$defaulted_dst
						)

						#210. Arguments before dots
						if (loc_dots > 1) {
							args_dst_before_dots <- private$fml_dst[seq.int(1, loc_dots - 1)]
						} else {
							args_dst_before_dots <- alist()
						}

						#230. Arguments after dots
						if (loc_dots < len_fml_dst) {
							args_dst_after_dots <- private$fml_dst[seq.int(loc_dots + 1, len_fml_dst)]
						} else {
							args_dst_after_dots <- alist()
						}

						#400. Eliminate those arguments, which are shared by both functions, from the signature of <src>
						fml_src_rest <- private$fml_src[!names(private$fml_src) %in% names(named_dst)]

						#600. Prepare the formals/signature of the wrapped function
						self$fml_deco <- c(args_dst_before_dots, fml_src_rest, args_dst_after_dots)
						named_deco <- self$fml_deco[!names(self$fml_deco) %in% c('...')]

						#700. Prepare the injection of the call to <dst>
						if (length(named_deco) > 0) {
							self$args_to_call_with_def <- names(named_deco[!private$flagPositional(named_deco)])
						} else {
							self$args_to_call_with_def <- NULL
						}
						self$args_to_call_wo_def <- names(named_deco)[!names(named_deco) %in% self$args_to_call_with_def]
						self$syms_to_call_wo_def <- rlang::syms(self$args_to_call_wo_def)
						names(self$syms_to_call_wo_def) <- self$args_to_call_wo_def

						#700. Other private environment
						self$.isdefault <- rlang::rep_named(names(private$.defaults), T)
						self$.isdefault.scope <- list(
							'src' = rlang::rep_named(names(self$defaulted_src), T)
							,'dst' = rlang::rep_named(names(self$defaulted_dst), T)
						)
					}
					#500. Function to identify the input value by argument name
					#[ASSUMPTION]
					#[1] R parses the input parameters in below sequence
					#    [1] Retrieve all <named parameters> for first batch
					#    [2] Place all the rest parameters into the rest holes other than above, from left to right with no skip
					#    [3] If there is <...> (dots) in the signature of the function, there will be no input for the
					#         <positional arguments> AFTER the dots as it devours all the rest parameters
					,getParam = function(arg, args_, inc_default = T){
						#100. Reshape the input
						args_in <- nameArgsByFormals(self$src, args_, coerce_ = T, strict_ = F)

						#500. Determine the approach
						#[ASSUMPTION]
						#[1] We cannot use <modifyList> to introduce the default values list, as it only modifies the sub-elements
						#     if both lists share the same element, instead of replacing them
						if (inc_default) {
							args_int <- c(self$defaulted_src[!names(self$defaulted_src) %in% names(args_in)], args_in)
							args_out <- nameArgsByFormals(self$src, args_int, coerce_ = T, strict_ = T)
						} else {
							args_out <- args_in
						}

						#900. Obtain the dedicated parameter
						return(args_out[[arg]])
					}
					#700. Function to update the dedicated input parameters in terms of the signature
					#[ASSUMPTION]
					#[1] Unlike Python, there is no need to insert parameters as all the inputs can be attached a proper argument name
					#[2] Also, we cannot reshape the inputs before updating them, because during the reshaping, all unnamed parameters
					#     will be named without validation
					#[3] It is safe to update a correct argument if we directly update the input list, as a named input is always
					#     prioritized
					,updParams = function(args_upd, args_){
						args_in <- c(args_[!names(args_) %in% names(args_upd)], args_upd)
						return(nameArgsByFormals(self$src, args_in, coerce_ = T, strict_ = T))
					}
					#800. Miscellaneous functions
					#810. Verify the conflict of argument names in both callables, except those declared as acceptable
					,vfyConflict = function(args_share = list()){
						if (length(private$named_dst) == 0) {
							arg_conflict <- alist()
						} else {
							arg_conflict <- private$named_dst[
								(names(private$named_dst) %in% names(private$fml_src))
								& (!names(private$named_dst) %in% names(args_share))
							]
						}
						if (length(arg_conflict) > 0) {
							stop(glue::glue('[dst]Detected conflict arguments: {toString(names(arg_conflict))}'))
						}
					}
					#820. Verify whether the parameter is from the default value of an argument, useful at runtime
					,isDefault = function(arg, scope_ = 'src'){
						if (!(arg %in% self$args_to_call_with_def)){
							return(F)
						}
						if (scope_ %in% names(self$.isdefault.scope)){
							return(self$.isdefault.scope[[scope_]][[arg]])
						}
						return(self$.isdefault[[arg]])
					}
				)
				,private = list(
					fml_src = NULL
					,fml_dst = NULL
					,named_dst = NULL
					,.defaults = NULL
					,flagPositional = function(fml) {
						unlist(Map(rlang::is_missing, fml))
					}
				)
				,active = list()
				,lock_objects = T
			)

			#900. Export the instance
			return(cls$new(src, dst))
		}
		,flagPositional = function(fml) {
			unlist(Map(rlang::is_missing, fml))
		}
	)
	,active = list()
	,lock_objects = T
)

return(mycls)
})

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#050. Define a universal function to print the private environment
		printEnv <- function(...){
			frame_in <- as.list(parent.frame())
			dots <- rlang::list2(...)
			str(frame_in)
			if (length(dots) > 0){
				message('Structure: [...]')
				message('End of Structure: [...]', str(dots))
			}
		}

		#100. Define the function with all kinds of arguments
		testf_src <- function(arg1, arg2 = 2, arg3, ..., arg4 = 4, arg5){
			message('From testf_src:')
			printEnv(...)
		}

		#110. Function to take the signature of source function
		#[ASSUMPTION]
		#[1] Pipe operator from <magrittr> is also delayed during evaluation, hence the function cannot be properly wrapped
		#[2] To solve this, we wrap all the statements in one <local> environment to ensure:
		#    [1] The instance of <ExpandSignature> is properly created locally and thus safely referenced
		#    [2] The dedicated functions is wrapped immediately
		testf_dst <- local({
			deco <- ExpandSignature$new(testf_src, instance = 'eSig')
			myfunc <- deco$wrap(function(arg2, arg6, ..., arg7){
				message('From testf_dst:')
				printEnv(...)
				dots <- rlang::list2(...)

				#[ASSUMPTION]
				#[1] Since <arg2> is in the signature of <dst>, we should insert it into the parameters for the call of <src>
				args_share <- list('arg2' = arg2)
				args_in <- eSig$updParams(args_share, dots)

				do.call(eSig$src, args_in)
			})
			return(myfunc)
		})

		print(args(testf_dst))
		# function (arg2, arg6, arg1, arg3, ..., arg4 = 4, arg5, arg7)

		testf_dst(2, 6, 1, arg3 = 3, arg5 = 5, arg7 = 7, 9)
		# From testf_dst:
		# 	List of 3
		# $ arg2: num 2
		# $ arg6: num 6
		# $ arg7: num 7
		# Structure: [...]
		# List of 5
		# $ arg1: num 1
		# $ arg3: num 3
		# $ arg5: num 5
		# $     : num 9
		# End of Structure: [...]
		# From testf_src:
		# 	List of 5
		# $ arg1: num 1
		# $ arg2: num 2
		# $ arg3: num 3
		# $ arg4: num 4
		# $ arg5: num 5
		# Structure: [...]
		# List of 1
		# $ : num 9
		# End of Structure: [...]

		#300. Test if the <src> takes different arguments
		#310. No argument
		src1 <- function(){
			message('This is src1:')
		}
		dst1 <- local({
		deco <- ExpandSignature$new(src1, instance = 'eSig')
		myfunc <- deco$wrap(function(arg2, ...){
			eSig$src(...)
			message('This is dst1:')
			printEnv(...)
		})
		return(myfunc)
		})

		dst1(2)
		# This is src1:
		# This is dst1:
		# List of 1
		# $ arg2: num 2

		#330. <src> has different arguments than <dst>
		src2 <- function(arg1, arg3 = 3){
			message('This is src2:')
			message('arg1:');str(arg1)
			message('arg3:');str(arg3)
		}
		dst2 <- local({
		deco <- ExpandSignature$new(src2, instance = 'eSig')
		myfunc <- deco$wrap(function(arg2, ...){
			eSig$src(...)
			message('This is dst2:')
			message('arg2:');str(arg2)
		})
		return(myfunc)
		})

		dst2(2,1)
		# This is src2:
		# arg1:
		# 	num 1
		# arg3:
		# 	num 3
		# This is dst2:
		# arg2:
		# 	num 2

		#335. Use a different statement to do the wrapping
		#[ASSUMPTION]
		#[1] In this case, we define a separate function and wrap it using another statement
		#[2] This proves that the design on the local reference is safe
		dst2_1 <- local({
		deco <- ExpandSignature$new(src2, instance = 'eSig')
		tmpfunc <- function(arg2, ...){
			eSig$src(...)
			message('This is dst2:')
			message('arg2:');str(arg2)
		}
		myfunc <- deco$wrap(tmpfunc)
		return(myfunc)
		})

		dst2_1(2,5)
		# This is src2:
		# arg1:
		# 	num 5
		# arg3:
		# 	num 3
		# This is dst2:
		# arg2:
		# 	num 2

		#400. Real cases
		#410. Create a method out of an existing function with nested expansion
		src3 <- function(arg1, arg3 = 3, ...){
			message('This is src3:')
			message('arg1:');str(arg1)
			message('arg3:');str(arg3)
			message('...:');dots <- rlang::list2(...);str(dots)
		}
		dst3 <- local({
		deco <- ExpandSignature$new(src3, instance = 'eSig')
		myfunc <- deco$wrap(function(arg4, ..., arg8 = 8, arg9 = 9){
			eSig$src(...)
			dots <- rlang::list2(...)
			message('This is dst3:')
			message('arg4:');str(arg4)
			message('arg3:');tmparg <- eSig$getParam('arg3', dots);str(tmparg)
			message('Whether <arg8> is from default value: ');tmparg <- eSig$isDefault('arg8', 'dst');str(tmparg)
			message('Whether <arg9> is from default value of <dst>: ');tmparg <- eSig$isDefault('arg9', 'dst');str(tmparg)
		})
		return(myfunc)
		})
		#[ASSUMPTION]
		#[1] Since all process is conducted locally, it is safe to name the instance with methods as <eSig>, just as above
		#[2] One only needs to remember to reference the newly named instance in the body of <dst>
		dst4 <- local({
		deco <- ExpandSignature$new(dst3, instance = 'eSig')
		myfunc <- deco$wrap(function(argself, ..., arg5, arg9 = 90){
			dots <- rlang::list2(...)
			args_in <- eSig$updParams(list('arg9' = arg9), dots)
			do.call(eSig$src, args_in)
			message('This is dst4:')
			message('arg5:');str(arg5)
			message('arg3:');tmparg <- eSig$getParam('arg3', dots);str(tmparg)
			message('Whether <arg8> is from default value of <src>: ');tmparg <- eSig$isDefault('arg8', 'src');str(tmparg)
			message('Whether <arg9> is from default value of <dst>: ');tmparg <- eSig$isDefault('arg9', 'dst');str(tmparg)
			message('Whether <arg9> is from default value of <src>: ');tmparg <- eSig$isDefault('arg9', 'src');str(tmparg)
		})
		return(myfunc)
		})

		dst4
		# function (argself, arg4, arg1, arg3 = 3, ..., arg8 = 8, arg5, arg9 = 90)

		dst4(1, 4, 1, arg5 = 5, arg7 = 7)
		# This is src3:
		# arg1:
		#  num 1
		# arg3:
		#  num 3
		# ...:
		# List of 1
		#  $ arg7: num 7
		# This is dst3:
		# arg4:
		#  num 4
		# arg3:
		#  num 3
		# Whether <arg8> is from default value:
		#  logi TRUE
		# Whether <arg9> is from default value of <dst>:
		#  logi FALSE
		# This is dst4:
		# arg5:
		#  num 5
		# arg3:
		#  num 3
		# Whether <arg8> is from default value of <src>:
		#  logi TRUE
		# Whether <arg9> is from default value of <dst>:
		#  logi TRUE
		# Whether <arg9> is from default value of <src>:
		#  logi FALSE

	}
}

