#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to unify the APIs to communicate with various open sources, e.g. FTP, File System and DB Engines to      #
#   | <pull> data or <push> data in simplified and standardized manner                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This is to resemble the same metaclass in Python branch via R6 functionality                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...         :   Formal arguments of <R6::R6Class>                                                                                  #
#   |apiPkgPull  :   <str     > Name of the package from which to obtain the API function to pull the data                              #
#   |                [NULL        ] <Default> Obtain the API from current session in global environment                                 #
#   |                [<str>       ]           Package name from which to load functions as APIs                                         #
#   |apiPfxPull  :   <str     > Prefix of the puller API name to search as regular expression                                           #
#   |                [<empty>     ] <Default> No specific prefix, be careful to use this setting                                        #
#   |                [<str>       ]           Set a proper prefix to validate the search                                                #
#   |apiSfxPull  :   <str     > Suffix of the puller API name to search as regular expression                                           #
#   |                [<empty>     ] <Default> No specific suffix, be careful to use this setting                                        #
#   |                [<str>       ]           Set a proper suffix to validate the search                                                #
#   |apiPullHdl  :   <function> Function with only one argument as handler to process the data pulled at once                           #
#   |                [<see def.>  ] <Default> No handler is required                                                                    #
#   |                [<function>  ]           Function to process the pulled data                                                       #
#   |lsPullOpt   :   <list    > Options to list the <pull> functions given <apiPkgPull == NULL>                                         #
#   |                [<empty>     ]<Default> Use the default arguments during searching                                                 #
#   |                [<list>      ]          See definition of <AdvOp$ls_frame>                                                         #
#   |apiPkgPush  :   <str     > Name of the package from which to obtain the API function to push the data                              #
#   |                [NULL        ] <Default> Obtain the API from current session in global environment                                 #
#   |                [<str>       ]           Package name from which to load functions as APIs                                         #
#   |apiPfxPush  :   <str     > Prefix of the pusher API name to search as regular expression                                           #
#   |                [<empty>     ] <Default> No specific prefix, be careful to use this setting                                        #
#   |                [<str>       ]           Set a proper prefix to validate the search                                                #
#   |apiSfxPush  :   <str     > Suffix of the pusher API name to search as regular expression                                           #
#   |                [<empty>     ] <Default> No specific suffix, be careful to use this setting                                        #
#   |                [<str>       ]           Set a proper suffix to validate the search                                                #
#   |apiPushHdl  :   <function> Function with only one argument as handler to process the data pushed at once                           #
#   |                [<see def.>  ] <Default> No handler is required                                                                    #
#   |                [<function>  ]           Function to process the pushed data                                                       #
#   |lsPushOpt   :   <list    > Options to list the <push> functions given <apiPkgPull == NULL>                                         #
#   |                [<empty>     ]<Default> Use the default arguments during searching                                                 #
#   |                [<list>      ]          See definition of <AdvOp$ls_frame>                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<R6Class>   :   Dynamically created R6 class                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240216        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |   |magrittr, rlang, glue, R6                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ls_frame                                                                                                                   #
#   |   |   |gen_locals                                                                                                                 #
#   |   |   |nameArgsByFormals                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, glue, R6
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)
#We should use the big-bang operand [!!!] supported by below package
library(rlang)

OpenSourceApiMeta <- function(
	...
	,apiPkgPull = NULL
	,apiPfxPull = ''
	,apiSfxPull = ''
	,apiPullHdl = function(x) {x}
	,lsPullOpt = list()
	,apiPkgPush = NULL
	,apiPfxPush = ''
	,apiSfxPush = ''
	,apiPushHdl = function(x) {x}
	,lsPushOpt = list()
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Handle the parameter buffer.
	if (!isVEC(apiPfxPull) | !is.character(apiPfxPull) | (length(apiPfxPull) != 1)) {
		stop(glue::glue('[{LfuncName}]<apiPfxPull> must be a length-1 character string!'))
	}
	if (!isVEC(apiSfxPull) | !is.character(apiSfxPull) | (length(apiSfxPull) != 1)) {
		stop(glue::glue('[{LfuncName}]<apiSfxPull> must be a length-1 character string!'))
	}
	if (!isVEC(apiPfxPush) | !is.character(apiPfxPush) | (length(apiPfxPush) != 1)) {
		stop(glue::glue('[{LfuncName}]<apiPfxPush> must be a length-1 character string!'))
	}
	if (!isVEC(apiSfxPush) | !is.character(apiSfxPush) | (length(apiSfxPush) != 1)) {
		stop(glue::glue('[{LfuncName}]<apiSfxPush> must be a length-1 character string!'))
	}
	if (!is.function(apiPullHdl)) {
		apiPullHdl <- function(x) {x}
	}
	if (!is.function(apiPushHdl)) {
		apiPushHdl <- function(x) {x}
	}
	candopt_rx <- list(
		'verbose' = TRUE
		,'predicate' = is.function
		,'ignore_case' = FALSE
		,'multiline' = FALSE
		,'comments' = FALSE
		,'dotall' = FALSE
	)
	lsPullOpt <- c(
		candopt_rx
		,lsPullOpt[!names(lsPullOpt) %in% c(names(candopt_rx),'pattern')]
	)
	lsPushOpt <- c(
		candopt_rx
		,lsPushOpt[!names(lsPushOpt) %in% c(names(candopt_rx),'pattern')]
	)

	#013. Define the local environment.
	cls_kw <- rlang::list2(...)
	m_public <- cls_kw[['public']]
	if (is.null(m_public)) m_public <- list()
	m_private <- cls_kw[['private']]
	if (is.null(m_private)) m_private <- list()
	m_active <- cls_kw[['active']]
	if (is.null(m_active)) m_active <- list()
	cls <- cls_kw[['classname']]
	if (!isVEC(cls) | !is.character(cls) | (length(cls) != 1)) {
		stop(glue::glue('[{LfuncName}]<classname> must be a length-1 character string!'))
	}
	.init_org. <- m_public[['initialize']]
	hasInit <- is.function(.init_org.)
	if (!hasInit) .init_org. <- function(...){}
	#[ASSUMPTION]
	#[1] <nchar(NULL)> returns <logical(0)> instead of <0>
	#[2] That is why we have to verify it at another step
	hasPkgPull <- isVEC(apiPkgPull) & is.character(apiPkgPull) & (length(apiPkgPull) == 1)
	if (hasPkgPull) {
		if (nchar(apiPkgPull) == 0) hasPkgPull <- F
	}
	hasPkgPush <- isVEC(apiPkgPush) & is.character(apiPkgPush) & (length(apiPkgPush) == 1)
	if (hasPkgPush) {
		if (nchar(apiPkgPush) == 0) hasPkgPush <- F
	}

	#050. Define a separate environment for variable substitution purpose
	newcls_env <- new.env()
	newcls_env$cls <- cls
	newcls_env$apiPullHdl <- apiPullHdl
	newcls_env$apiPushHdl <- apiPushHdl
	newcls_env$apiPfxPull <- apiPfxPull
	newcls_env$apiSfxPull <- apiSfxPull
	newcls_env$apiPfxPush <- apiPfxPush
	newcls_env$apiSfxPush <- apiSfxPush
	newcls_env$hasPkgPull <- hasPkgPull
	newcls_env$hasPkgPush <- hasPkgPush
	newcls_env$lsPullOpt <- lsPullOpt
	newcls_env$lsPushOpt <- lsPushOpt

	#100. Extract the rest of keyword arguments
	cls_params_raw <- formals(R6::R6Class)

	#110. Obtain all defaults of keyword arguments of the function
	cls_kw_raw <- cls_params_raw[!names(cls_params_raw) %in% c('classname','public','private','active')]

	#190. Create the final keyword arguments for calling the function
	cls_kw_final <- cls_kw[(names(cls_kw) %in% names(cls_kw_raw)) & !(names(cls_kw) %in% c('classname','public','private','active'))]

	#200. Define helper functions
	#[ASSUMPTION]
	#[1] We avoid passing local variables to a lazy-evaluated function call by substituting its body
	#[2] We have to avoid the dots <...> from being substituted by those within the parent environment, hence we can
	#     leverage the argument <env> for <substitute> to only search for the dedicated variables during substitution

	#210. Define dynamic data reader based on pattern: <apiPfxPull + cls + apiSfxPull>
	.pull. <- eval(substitute(function(...) {
		#013. Define the local environment.
		kw <- rlang::list2(...)

		#100. Define dynamic data reader
		apiPtnPull <- paste0(apiPfxPull, cls, apiSfxPull)

		#200. Prepare the callable core for creating the reader method
		if (hasPkgPull) {
			..func_pull.. <- get(apiPtnPull, pos = loadNamespace(apiPkgPull), mode = 'function')
		} else {
			#[ASSUMPTION]
			#[1] We would call external function <glue::glue> for some conditions
			#[2] Hence the variables are lazy-evaluated
			#[3] Even if we add <.envir=> option to bind the call to current environment, it still fails
			#[4] Therefore, we set the pattern by text manipulation before any external function call
			#[5] In case the pattern contains dots (as R allows), we also need to escape it to avoid error searching
			..func_pull.. <- do.call(ls_frame, c(
				list(pattern = paste0('^',apiPtnPull,'$'))
				,lsPullOpt
			))
			if (length(..func_pull..) == 1) {
				..func_pull.. <- ..func_pull..[[1]]
			} else {
				..func_pull.. <- NULL
			}
		}

		#300. Verify whether the core reader is callable on the fly
		if (!is.function(..func_pull..)) {
			stop(glue::glue('[{self$..class..$classname}][{apiPtnPull}] is not callable!'))
		}

		#400. Correct the provided arguments during calling
		#401. Retrieve the formals of the function
		formals_raw <- formals(..func_pull..)

		#450. Validate the effective arguments as provided
		kw_ren <- nameArgsByFormals(kw, func = ..func_pull..)

		#500. Overwrite the keyword arguments if they are not provided for each call of this method, but given at instantiation
		kw_new <- modifyList(private$..inputkw_pull.., kw_ren, keep.null = T)

		#510. Obtain all defaults of keyword arguments of the raw API
		kw_raw <- formals_raw[!names(formals_raw) %in% c('...')]

		#550. In case the raw API takes any variant keywords, we also identify them
		#[ASSUMPTION]
		#[1] This only validates when the API takes variant keywords
		#[2] If the created class takes keyword arguments for both <pull> and <push>, there will not be KeyError raised
		#     when we add below handler to eliminate superfluous arguments for current API
		if ('...' %in% names(formals_raw)) {
			kw_varkw <- kw_new[!names(kw_new) %in% names(kw_raw)]
		} else {
			kw_varkw <- list()
		}

		#590. Create the final keyword arguments for calling the API
		kw_final <- c(
			kw_new[names(kw_new) %in% names(kw_raw)]
			,kw_varkw
		)
		# print(glue::glue('kw -> {paste0(paste(names(kw), as.character(kw), sep = " -> "), collapse = ";")}'))
		# print(glue::glue('kw_ren -> {paste0(paste(names(kw_ren), as.character(kw_ren), sep = " -> "), collapse = ";")}'))
		# print(glue::glue(
		# 	'private$..inputkw_pull.. ->'
		# 	,' {paste0(paste(names(private$..inputkw_pull..), as.character(private$..inputkw_pull..), sep = " -> "), collapse = ";")}'
		# ))
		# print(glue::glue('kw_new -> {paste0(paste(names(kw_new), as.character(kw_new), sep = " -> "), collapse = ";")}'))
		# print(glue::glue('kw_final -> {paste0(paste(names(kw_final), as.character(kw_final), sep = " -> "), collapse = ";")}'))

		#900. Pull the data from the API
		private$..pulled.. <- self$hdlPull(do.call(..func_pull.., kw_final))

		#900. Return values
		#[ASSUMPTION]
		#[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
		return(self$pulled)
	}, env = newcls_env))

	#220. Define dynamic data writer based on pattern: <apiPfxPush + cls + apiSfxPush>
	.push. <- eval(substitute(function(...) {
		#013. Define the local environment.
		kw <- rlang::list2(...)

		#100. Define dynamic data reader
		apiPtnPush <- paste0(apiPfxPush, cls, apiSfxPush)

		#200. Prepare the callable core for creating the reader method
		if (hasPkgPush) {
			..func_push.. <- get(apiPtnPush, pos = loadNamespace(apiPkgPush), mode = 'function')
		} else {
			..func_push.. <- do.call(ls_frame, c(
				list(pattern = paste0('^',apiPtnPush,'$'))
				,lsPushOpt
			))
			if (length(..func_push..) == 1) {
				..func_push.. <- ..func_push..[[1]]
			} else {
				..func_push.. <- NULL
			}
		}

		#300. Verify whether the core reader is callable on the fly
		if (!is.function(..func_push..)) {
			stop(glue::glue('[{self$..class..$classname}][{apiPtnPush}] is not callable!'))
		}

		#400. Correct the provided arguments during calling
		#401. Retrieve the formals of the function
		formals_raw <- formals(..func_push..)

		#450. Validate the effective arguments as provided
		kw_ren <- nameArgsByFormals(kw, func = ..func_push..)

		#500. Overwrite the keyword arguments if they are not provided for each call of this method, but given at instantiation
		kw_new <- modifyList(private$..inputkw_push.., kw_ren, keep.null = T)

		#510. Obtain all defaults of keyword arguments of the raw API
		kw_raw <- formals_raw[!names(formals_raw) %in% c('...')]

		#550. In case the raw API takes any variant keywords, we also identify them
		#[ASSUMPTION]
		#[1] This only validates when the API takes variant keywords
		#[2] If the created class takes keyword arguments for both <pull> and <push>, there will not be KeyError raised
		#     when we add below handler to eliminate superfluous arguments for current API
		if ('...' %in% names(formals_raw)) {
			kw_varkw <- kw_new[!names(kw_new) %in% names(kw_raw)]
		} else {
			kw_varkw <- list()
		}

		#590. Create the final keyword arguments for calling the API
		kw_final <- c(
			kw_new[names(kw_new) %in% names(kw_raw)]
			,kw_varkw
		)
		# print(glue::glue('kw -> {paste0(paste(names(kw), as.character(kw), sep = " -> "), collapse = ";")}'))
		# print(glue::glue('kw_ren -> {paste0(paste(names(kw_ren), as.character(kw_ren), sep = " -> "), collapse = ";")}'))
		# print(glue::glue(
		# 	'private$..inputkw_push.. ->'
		# 	,' {paste0(paste(names(private$..inputkw_push..), as.character(private$..inputkw_push..), sep = " -> "), collapse = ";")}'
		# ))
		# print(glue::glue('kw_new -> {paste0(paste(names(kw_new), as.character(kw_new), sep = " -> "), collapse = ";")}'))
		# print(glue::glue('kw_final -> {paste0(paste(names(kw_final), as.character(kw_final), sep = " -> "), collapse = ";")}'))

		#900. Pull the data from the API
		private$..pushed.. <- self$hdlPush(do.call(..func_push.., kw_final))

		#900. Return values
		#[ASSUMPTION]
		#[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
		return(self$pushed)
	}, env = newcls_env))

	#250. Define the <initialize> structure during instantiation of the newly created class
	#Below link demonstrates the way to initialize an R6 Class together with its parent class generator
	#[Quote: https://stackoverflow.com/questions/35925664/change-initialize-method-in-subclass-of-an-r6-class ]
	#Below link demonstrates the way to find all ancestors of an R6 Class recursively
	#[Quote: https://stackoverflow.com/questions/37303552/r-r6-get-full-class-name-from-r6generator-object ]
	#Below link demonstrates how to set methods for a class
	#Quote: https://stackoverflow.com/questions/56189576/how-to-add-functions-in-a-loop-to-r6class-in-r
	#[ASSUMPTION]
	#[1] Why we have to set <..hdlPull..> and <..hdlPush..> as <NULL> in the first place:
	#    Quote: https://stackoverflow.com/questions/62314410/
	#[2] We have to pass the handlers to <initialize> method BEFORE creating the class, otherwise the lazy evaluation
	#     of R function call would fail to identify them
	.init. <- eval(substitute(function(..., argsPull = list(), argsPush = list()) {
		#005. Set the default handlers BEFORE initialization, to allow the user to customize them at initialization
		self$hdlPull <- apiPullHdl
		self$hdlPush <- apiPushHdl

		#010. Hijack the original <initialize> and conduct its process ahead of the processes defined in the metaclass
		private$..init_org..(...)

		#100. Assign values to local variables
		#Below link demonstrates how to identify the class name from an R6 instance
		#Quote: https://github.com/r-lib/R6/issues/144
		# self$..classname.. <- class(self)
		self$..class.. <- mycls
		private$..pulled.. <- NULL
		private$..pushed.. <- NULL
		private$..inputkw_pull.. <- argsPull
		private$..inputkw_push.. <- argsPush
		private$..inputkw.. <- rlang::list2(...)
	}, env = newcls_env))

	#300. Properties that can be accessed by the newly created class
	.pulled. <- function() return(private$..pulled..)
	.pushed. <- function() return(private$..pushed..)
	.hdlPull. <- function(func) {
		#001. Define property getter
		if (missing(func)) return(private$..hdlPull..)

		#109. Verification
		if (!is.function(func)) {
			stop(glue::glue('[{self$..class..$classname}][hdlPull] must be assigned a callable!'))
		}

		#900. Define property setter
		#Quote: https://coolbutuseless.github.io/2021/02/19/modifying-r6-objects-after-creation/
		# unlockBinding(private$..hdlPull.., self$.__enclos_env__)
		private$..hdlPull.. <- func
		environment(private$..hdlPull..) <- self$.__enclos_env__
		# lockBinding(private$..hdlPull.., self$.__enclos_env__)
	}
	.hdlPush. <- function(func) {
		#001. Define property getter
		if (missing(func)) return(private$..hdlPush..)

		#109. Verification
		if (!is.function(func)) {
			stop(glue::glue('[{self$..class..$classname}][hdlPull] must be assigned a callable!'))
		}

		#900. Define property setter
		private$..hdlPush.. <- func
		environment(private$..hdlPush..) <- self$.__enclos_env__
	}

	#800. Create the class
	#[ASSUMPTION]
	#[1] We use a verbose mode to create the class, just for storing the <class> itself to its instances
	#Below link demonstrates why we use <local> to create the class
	#Quote: https://github.com/r-lib/R6/issues/144
	newcls <- local({
		mycls <- do.call(
			R6::R6Class
			,c(
				list(
					classname = cls
					,public = modifyList(
						m_public
						,list(
							initialize = .init.
							,pull = .pull.
							,push = .push.
							,..class.. = NULL
						)
						,keep.null = T
					)
					,private = modifyList(
						m_private
						,list(
							..init_org.. = .init_org.
							,..pulled.. = NULL
							,..pushed.. = NULL
							,..inputkw_pull.. = NULL
							,..inputkw_push.. = NULL
							,..inputkw.. = NULL
							,..hdlPull.. = NULL
							,..hdlPush.. = NULL
						)
						,keep.null = T
					)
					,active = modifyList(
						m_active
						,list(
							hdlPull = .hdlPull.
							,hdlPush = .hdlPush.
							,pulled = .pulled.
							,pushed = .pushed.
						)
						,keep.null = T
					)
				)
				,cls_kw_final
			)
		)

		return(mycls)
	})

	#999. Export
	return(newcls)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#We should use the big-bang operand [!!!] supported by below package
		library(rlang)

		#100. Prepare API in current session
		api_testMeta <- function() {
			return(list(
				'name' = 'test API'
				,'address' = 'RAM'
				,'data' = list(
					'rawdata' = c(1,2,3)
					,'dataframe' = data.frame(a = c(1,2,3))
				)
				,'rc' = 0
			))
		}

		#200. Create a class dynamically
		aaa <- OpenSourceApiMeta(classname = 'testMeta', apiPfxPull = 'api_')
		aaa_obj <- aaa$new()
		aaa_obj$hdlPush <- function(x) x

		#210. Load data from the API
		rst <- aaa_obj$pull()

		#230. Check if it is successful
		#[ASSUMPTION]
		#[1] Below statements return the same result
		#Return: RAM
		rst[['address']]
		aaa_obj$pulled[['address']]

		#250. Try to obtain a non-existing property since <initialize> is not customized
		# NULL
		aaa_obj$bcd

		#300. Create a class in a conventional way
		#301. Prepare the function to remove the key <address> from the pulled data
		h_remaddr <- function(inval) {
			rst <- inval[!names(inval) %in% c('address')]
			return(rst)
		}

		bbb <- eval(substitute(OpenSourceApiMeta(
			classname = 'testMeta'
			,public = list(
				initialize = function(bcd) {
					self$bcd <- bcd
					#[ASSUMPTION]
					#[1] Any statement within a <function> is lazy-evaluated
					#[2] Hence if one needs to use above function instead, <substitute> is required for the whole statement
					self$hdlPull <- h_remaddr
				}
				,bcd = NULL
			)
			,apiPfxPull = 'api_'
		)))
		bbb_obj <- bbb$new(112)

		#310. Try to obtain data from a non-existing API
		# NULL
		bbb_obj$pulled[['address']]

		#330. Manually read data from the API
		rst2 <- bbb_obj$pull()

		#350. Now check the result
		rst2[['name']]
		# [1] "test API"

		#360. Try to obtain the removed attribute (by the customized handler)
		# NULL
		bbb_obj$pulled[['address']]

		#390. Try to obtain the customized attribute
		bbb_obj$bcd
		# [1] 112

		#400. Create a universal framework to use API dynamically
		#[ASSUMPTION]
		#[1] This framework unifies the methods to call APIs when they are introduced on the fly
		#[2] One can define how to use these APIs by universal configurations
		#[3] We use a verbose mode to create the class, just for storing the <class> itself to its instances
		#Below link demonstrates why we use <local> to create the class
		#Quote: https://github.com/r-lib/R6/issues/144
		ApiOnTheFly <- local({
			mycls <- R6::R6Class(
				classname = 'ApiOnTheFly'
				,public = list(
					initialize = function(
						#Search for the callable APIs from current session
						pkg_loader = NULL
						#Search for the APIs given their names start with this string
						,pfx_loader = 'api_'
						#Default keyword arguments for all APIs when they are called
						,args_loader = list()
					) {
						#100. Assign values to local variables
						self$pkg_loader <- pkg_loader
						self$pfx_loader <- pfx_loader
						self$args_loader <- args_loader
						private$..lists_active.. <- sapply(self$full, function(x) F, simplify = T, USE.NAMES = T)
						self$..class.. <- mycls
					}
					,pkg_loader = NULL
					,pfx_loader = NULL
					,args_loader = NULL
					,..class.. = NULL
					#310. Add an API by its name
					#[ASSUMPTION]
					#[1] Pass <**kw> to indicate different arguments for different APIs
					#[2] Create the class of APIs on the fly, and assign their names as attributes to this framework
					#[3] We do not pull data from the newly created API, since the dots <...> cannot be determined for which
					#     of the available APIs, esp. when calling <self$addfull()>
					,add = function(.attr, argsPull = list(), ...) {
						#100. Verify whether the API can be found in the candidate packages
						if (!.attr %in% self$full) {
							stop(glue::glue('[{self$..class..$classname}]No method is found to register API for [{.attr}]!'))
						}

						#200. Create API class on the fly
						cls <- OpenSourceApiMeta(
							classname = .attr
							,apiPkgPull = self$pkg_loader
							,apiPfxPull = self$pfx_loader
						)

						#200. Prepare keyword arguments for reading data from the API
						#[ASSUMPTION]
						#[1] We take the default keyword arguments in current API as top priority,
						#     given neither <args_loader> nor <kw> is provided
						#[2] Given <args_loader> is non-empty while <**kw> is empty, we take <args_loader> to call the API
						#[3] Given <**kw> is provided, we call the API with it
						kw_pull_init <- self$args_loader[[.attr]]
						if (is.null(kw_pull_init)) kw_pull_init <- list()
						kw_add <- modifyList(kw_pull_init, argsPull)

						#500. Instantiate the API and read data from it at once
						obj <- cls$new(argsPull = kw_add, ...)

						#700. Add current API to the attribute list of current framework
						self[[.attr]] <- obj
						environment(self[[.attr]]) <- self$.__enclos_env__

						#900. Modify private environment
						private$..lists_active..[[.attr]] <- T
					}
					#320. Add all available APIs to current private environment
					,addfull = function(argsPull = list(), ...) {
						for (a in self$full) {
							kw_add <- argsPull[[a]]
							if (is.null(kw_add)) kw_add <- list()
							self$add(a, argsPull = kw_add, ...)
						}
					}
					#360. Remove API from private environment
					,remove = function(.attr) {
						attr_exist <- ls(self$.__enclos_env__$self, all.names = T, pattern = glue::glue('^{.attr}$'))
						if (length(attr_exist) > 0) rm(list = .attr, pos = self$.__enclos_env__$self)
						private$..lists_active..[[.attr]] <- F
					}
					#370. Remove all active APIs from private environment
					,removefull = function() {
						lapply(self$full, self$remove)
						invisible()
					}
				)
				,private = list(
					..lists_active.. = NULL
					#410. Verify whether there is at least 1 active API in the private environment
					,.chkactive. = function(funcname) {
						if (length(self$active) == 0) {
							stop(glue::glue('[{self$..class..$classname}][{funcname}] is empty as there is no active API!'))
						}
					}
					#430. Remove the affixes from the API names
					,.rem_affix. = function(mthdname, pfx = '', sfx = '') {
						gsub(glue::glue('^{pfx}(.*){sfx}$'), '\\1', mthdname, fixed = F, perl = T)
					}
				)
				,active = list(
					full = function() {
						#100. Determine the scope from which to search for the functions
						#[ASSUMPTION]
						#[1] <nchar(NULL)> returns <logical(0)> instead of <0>
						#[2] That is why we have to verify it at another step
						hasPkgPull <- isVEC(self$pkg_loader) & is.character(self$pkg_loader) & (length(self$pkg_loader) == 1)
						if (hasPkgPull) {
							if (nchar(self$pkg_loader) == 0) hasPkgPull <- F
						}

						#300. Differ the process
						if (hasPkgPull) {
							#100. List all candidate names
							apinames <- ls(
								loadNamespace(self$pkg_loader)
								,all.names = T
								,pattern = glue::glue('^{self$pfx_loader}')
							) %>%
								sapply(function(x){is.function(get(x, envir = loadNamespace(self$pkg_loader)))}) %>%
								{Filter(isTRUE, .)}
						} else {
							#100. List all candidate names
							apinames <- ls(
								.GlobalEnv
								,all.names = T
								,pattern = glue::glue('^{self$pfx_loader}')
							) %>%
								sapply(function(x){is.function(get_values(x, inplace = F))}) %>%
								{Filter(isTRUE, .)}
						}

						#500. Filter the result
						return(private$.rem_affix.(names(apinames), pfx = self$pfx_loader, sfx = ''))
					}
					#520. Obtain the status of all APIs
					,status = function() {
						return(private$..lists_active..)
					}
					#530. Obtain the names of active APIs
					,active = function() {
						return(names(Filter(isTRUE, private$..lists_active..)))
					}
					#550. Obtain the mapping of all active APIs to their names as obtained via their respective reader methods
					,names = function() {
						LfuncName <- deparse(sys.call()[[1]])
						private$.chkactive.(LfuncName)
						sapply(self$active, function(x){self[[x]]$pulled[['name']]}, simplify = F, USE.NAMES = T)
					}
				)
				#[ASSUMPTION]
				#[1] We have to unlock the instantiated object for member manipulation
				#[2] Unlike Python, there is no <__slots__> for R, hence this operation is dangerous
				,lock_objects = F
			)

			return(mycls)
		})

		#500. Instantiate the class with default arguments
		addAPI <- ApiOnTheFly$new()

		#510. List all available APIs at present
		addAPI$full

		#530. Load data from all APIs with default arguments
		addAPI$addfull()

		#590. Purge all active APIs and remove their loaded data
		addAPI$removefull()

		#599. Try to list all names of the APIs in vain as they have been purged at above step
		addAPI$active
		# [ApiOnTheFly][active] is empty as there is no active API!

		#600. Add the API defined above
		addAPI$add('testMeta')

		#610. Check the address of the data retrieved from current API
		addAPI[['testMeta']]$pull()
		addAPI[['testMeta']]$pulled[['address']]
		# "RAM"

		#630. Refresh data from the API with default arguments
		rst3 <- addAPI[['testMeta']]$pull()

		#700. Overwrite the default arguments to register APIs
		diff_args <- list(
			'fly' = list(
				'arg_in' = c(2,3,4)
			)
		)

		#705. Create a new API on the fly
		api_fly <- function(arg_in = 5) {
			return(list(
				'name' = 'on-the-fly'
				,'address' = 'RAM'
				,'data' = list(
					'rawdata' = c(2,3,5)
					,'dataframe' = data.frame(a = arg_in)
				)
				,'rc' = 0
			))
		}

		#710. Register and load data from all available APIs with the modified arguments
		addAPI$addfull(argsPull = diff_args)

		#730. Check the added APIs at current step
		ttt <- addAPI$active

		#740. Remove an API from the namespace, together with its retrieved data
		addAPI$remove('testMeta')

		#750. Register and load data from a specific API with modified arguments
		addAPI$add('fly', argsPull = diff_args[['fly']])
		addAPI[['fly']]$pull()

		#800. Check properties at current stage
		#810. List the mappings of API names
		addAPI$names
		# $fly
		# [1] "on-the-fly"

		#830. Check the status of registered APIs
		addAPI$status
	    #  fly testMeta
	    # TRUE    FALSE

		#850. Instantiate the framework with default arguments
		addAPI <- ApiOnTheFly$new(args_loader = diff_args)

		#855. Load data from API with the modified default arguments
		addAPI$add('fly')
		addAPI[['fly']]$pull()
		print(addAPI[['fly']]$pulled[['data']][['dataframe']])
		#   a
		# 1 2
		# 2 3
		# 3 4

		#900. Try to add an API that does not exist in vain
		addAPI$add('pseudo')
		# [ApiOnTheFly]No method is found to register API for [pseudo]!

	}
}
