#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to lookup the callable from a dedicated package, a frame, or a stack of frames, by the provided pattern  #
#   | of name, and escalate it into a separate callable with <self> as the first positional argument, for further binding to an         #
#   | instance as a method. Meanwhile, it enables to call the further bound method by ignoring excessive parameters.                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Dynamically lookup the method for an instance, basically for R6 Class                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |apiCls            :   <str     > Class/owner name of the method to lookup and bind                                                 #
#   |                      [None                ]<Default> System would raise exception if it is not provided                           #
#   |                      [str                 ]          Any string that is legal to form attribute names of a class                  #
#   |apiPkg            :   <str     > Package name in which to lookup the dedicated callable                                            #
#   |                      [None                ]<Default> System would search the callable from current session                        #
#   |                      [str                 ]          System would search the callable from within the package                     #
#   |apiPfx            :   <str     > Prefix of the pattern to search for the name of the callable: <apiPfx> + <apiCls> + <apiSfx>      #
#   |                      [<empty str>         ]<Default> No specific prefix                                                           #
#   |                      [str                 ]          Set a proper prefix to validate the search                                   #
#   |apiSfx            :   <str     > Suffix of the pattern to search for the name of the callable: <apiPfx> + <apiCls> + <apiSfx>      #
#   |                      [<empty str>         ]<Default> No specific suffix                                                           #
#   |                      [str                 ]          Set a proper suffix to validate the search                                   #
#   |lsOpt             :   <dict    > Additional options for <ls_frame> given <apiPkg> is not provided, for search in current session   #
#   |                      [<empty dict>        ]<Default> No additional options, see function definition for details                   #
#   |                      [dict                ]          See <AdvOp.ls_frame> for additional options                                  #
#   |attr_handler      :   <obj     > Attribute name to get from the bound instance, to mutate the result returned from the method call #
#   |                      [<missing>           ]<Default> No need to mutate the result from the newly bound method                     #
#   |                      [<bound object>      ]          Existing attribute to handle the result from the newly bound method          #
#   |attr_kwInit       :   <obj     > Attribute name to get from the bound instance, to initialize the keyword arguments of the newly   #
#   |                       bound method at the binding stage                                                                           #
#   |                      [<missing>           ]<Default> No need to adjust the default keyword arguments of the newly bound method    #
#   |                      [<bound object>      ]          Existing attribute to initialize the keyword arguments of the newly bound    #
#   |                                                       method                                                                      #
#   |attr_assign       :   <obj     > Attribute name to get from the bound instance, to assign the result from the newly bound method   #
#   |                      [<missing>           ]<Default> No need to store the result of the newly bound method to another attribute   #
#   |                      [<bound object>      ]          Existing attribute to store the result from the newly bound method           #
#   |attr_return       :   <obj     > Attribute name to get from the bound instance, to return from the newly bound method              #
#   |                      [<missing>           ]<Default> Only return the result from the newly bound method                           #
#   |                      [<bound object>      ]          Only return the value of the dedicated attribute, similar to <property>      #
#   |coerce_           :   <bool    > Whether to raise exception if the dedicated callable is not found                                 #
#   |                      [True                ]<Default> Return <None> if the callable is not found                                   #
#   |                      [False               ]          Raise exception if the callable is not found                                 #
#   |envir             :   <env     > The environment within which to invoke the call of the dedicated function                         #
#   |                      [<see def.>          ]<Default> Set the environment of the function found to the default one (as an instance #
#   |                                                       of R6 Class                                                                 #
#   |                      [environment         ]          The dedicated environment to invoke the function                             #
#   |privateName       :   <str     > The local name (preferably as a private variable name) to bind the function found                 #
#   |                      [<see def.>          ]<Default> Make the internal call to the newly bound function refer to this name        #
#   |                      [str                 ]          Ensure the private name is unique in the dedicated environment               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>        :   The new method which can be bound to any dedicated instance                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250104        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, re, inspect, typing                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isVEC                                                                                                                      #
#   |   |   |ls_frame                                                                                                                   #
#   |   |   |nameArgsByFormals                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

lookupMethod <- function(
	apiCls = NULL
	,apiPkg = NULL
	,apiPfx = ''
	,apiSfx = ''
	,lsOpt = list()
	,attr_handler
	,attr_kwInit
	,attr_assign
	,attr_return
	,coerce_ = TRUE
	,envir = self$.__enclos_env__
	,privateName = '..lm_func.'
) {
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	if (!isVEC(apiCls) | !is.character(apiCls) | (length(apiCls) != 1)) {
		stop(glue::glue('[{LfuncName}][apiCls] must be length-1 <character>!'))
	}
	if (all(nchar(apiCls) == 0)) {
		stop(glue::glue('[{LfuncName}][apiCls] cannot be empty!'))
	}
	if (!isVEC(apiPfx) | !is.character(apiPfx) | (length(apiPfx) != 1)) {
		stop(glue::glue('[{LfuncName}][apiPfx] must be length-1 <character>!'))
	}
	if (!isVEC(apiSfx) | !is.character(apiSfx) | (length(apiSfx) != 1)) {
		stop(glue::glue('[{LfuncName}][apiSfx] must be length-1 <character>!'))
	}

	#020. Local environment.
	#[ASSUMPTION]
	#[1] We cannot use <is.null> to verify the existence of below variables, otherwise they are evaluated and probably issue error
	miss_handler <- missing(attr_handler)
	miss_kwInit <- missing(attr_kwInit)
	miss_assign <- missing(attr_assign)
	miss_return <- missing(attr_return)
	candopt_rx <- list(
		'verbose' = TRUE
		,'predicate' = is.function
		,'ignore_case' = FALSE
		,'multiline' = FALSE
		,'comments' = FALSE
		,'dotall' = FALSE
	)
	lsOptNew <- c(
		candopt_rx
		,lsOpt[!names(lsOpt) %in% c(names(candopt_rx),'pattern')]
	)
	#[ASSUMPTION]
	#[1] <nchar(NULL)> returns <logical(0)> instead of <0>
	#[2] That is why we have to verify it at another step
	hasPkg <- isVEC(apiPkg) & is.character(apiPkg) & (length(apiPkg) == 1)
	if (hasPkg) {
		if (all(nchar(apiPkg) == 0)) hasPkg <- F
	}

	#100. Define the name pattern for search
	apiPtn <- paste0(apiPfx, apiCls, apiSfx)

	#200. Lookup the callable core
	if (hasPkg) {
		..dfl_func. <- get(apiPtn, pos = loadNamespace(apiPkg), mode = 'function')
	} else {
		..dfl_func. <- do.call(ls_frame, c(
			list(pattern = paste0('^',apiPtn,'$'))
			,lsOptNew
		))
		if (length(..dfl_func.) == 1) {
			..dfl_func. <- ..dfl_func.[[1]]
		} else {
			..dfl_func. <- NULL
		}
	}

	#300. Verify whether it can be found
	if (!is.function(..dfl_func.)) {
		if (coerce_) {
			return(NULL)
		} else {
			stop(glue::glue('[{LfuncName}][{apiPtn}] is not callable!'))
		}
	}

	#600. Prepare a decorator to expand the signature of the function to be returned
	thisenv <- environment()
	deco <- ExpandSignature$new(..dfl_func., instance = 'eSig', srcEnv = thisenv)

	#700. Define a method-like callable to wrap the original API
	func_ <- eval(substitute(function(...) {
		#020. Local environment.
		dots <- rlang::list2(...)

		#100. Verify input parameters
		#101. Create a pseudo parameter when necessary
		args_share <- list()

		#100. Reshape the parameters as provided
		args_in <- eSig$updParams(args_share, dots)

		#300. Overwrite the keyword arguments if they are not provided for each call of this method, but given at instantiation
		#[ASSUMPTION]
		#[1] We do not use <modifyList> to extend the parameter list, as it only modifies the sub-elements instead of replacing them,
		#     if the same element exists in both inputs
		#[2] Unlike the same function in Python branch, it is safe in R to patch the inputs with extra default values directly, as the
		#     input is not mutated by <ExpandSignature>
		if (!miss_kwInit) {
			if (!is.list(attr_kwInit)) {
				stop(glue::glue('[{clsname_}][attr_kwInit] evaluated by [{LfuncName}] is not a list!'))
			}
			kw_def <- c(attr_kwInit[!names(attr_kwInit) %in% names(args_in)], args_in)
		} else {
			kw_def <- args_in
		}

		#400. Eliminate the excessive parameters set inside the initial keyword parameter list
		#[ASSUMPTION]
		#[1] By doing this, we silently eliminate excessive parameters provided for the call
		#[2] As this function is designed primarily for R6 Class, the API callable does not require <self> to be set as an
		#     argument in its formals (internal variables such as <self> can still be referenced inside the function body)
		#[3] During the call of below function, <kw> is evaluated anyway; while at the meantime the environment of <lookupMethod>
		#     is NOT YET set as the caller instance of (probably R6) class. So the design of <lookupMethod> does not accept <self> as
		#     an argument of the API formals, otherwise the process fails at this step
		args_fnl <- eSig$updParams(args_share, kw_def)

		#500. Pull the data from the API
		private[[privateName]] <- ..dfl_func.
		environment(private[[privateName]]) <- envir
		rstOut <- do.call(private[[privateName]], args_fnl)

		#600. Handle the result if required
		#[ASSUMPTION]
		#[1] Currently it only takes one positional argument
		if (!miss_handler) {
			rstOut <- attr_handler(rstOut)
		}

		#700. Assign the result to another attribute if required
		#[ASSUMPTION]
		#[1] <attr_assign> is substituted before evaluation, hence the requested object can be assigned with correct value
		if (!miss_assign) {
			attr_assign <- rstOut
		}

		#900. Return values
		#[ASSUMPTION]
		#[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
		if (!miss_return) {
			return(attr_return)
		} else {
			return(rstOut)
		}
	}))

	#900. Return values
	#[ASSUMPTION]
	#[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
	return(deco$wrap(func_))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Define the API which can be bound as a method of some instance
		loader_api001 <- function(b){
			return(self$aaa + b)
		}

		#200. Directly call the function to bind the API to an instance
		#[ASSUMPTION]
		#[1] There should be an extra method <add> to bind the API and an extra step to add it, which is less efficient
		#[2] One can mannually assign any value to the newly added API, which is a risk of injection
		#[3] However, method lookup can become dynamic
		#[4] Currently this is the only way to realize dynamic method binding in R (basically for R6Class), since there is no magic
		#     method <__getattr__> or descriptor mechanism to do so
		#Below link demonstrates why we use <local> to create the class
		#Quote: https://github.com/r-lib/R6/issues/144
		MyClass <- local({
			mycls <- R6::R6Class(
				classname = 'MyClass'
				,public = list(
					initialize = function() {
						#100. Assign values to local variables
						self$aaa <- 10
						self$..class.. <- mycls
					}
					,aaa = NULL
					,..class.. = NULL
					#310. Add an API by its name
					,add = function(.attr) {
						func_ <- lookupMethod(
							apiCls = .attr
							,apiPkg = NULL
							,apiPfx = 'loader_'
							,apiSfx = ''
							,lsOpt = list(
								frame_from = sys.frame()
							)
							#[ASSUMPTION]
							#[1] Unlike the same function in Python branch, these attributes are provided by reference instead of name
							#[2] In R language, we can skip providing these parameters to ensure they are <missing>
							# ,attr_handler = NULL
							# ,attr_kwInit = NULL
							# ,attr_assign = NULL
							# ,attr_return = NULL
							,coerce_ = F
							,privateName = '..test_func.'
						)
						self[[.attr]] <- func_
						environment(self[[.attr]]) <- self$.__enclos_env__
					}
				)
				#[ASSUMPTION]
				#[1] Since the newly bound method references to a <private> object as named during the lookup, we need to define
				#     this <private> attribute to allow modification
				,private = list(
					..test_func. = NULL
				)
				#[ASSUMPTION]
				#[1] We have to unlock the instantiated object for member manipulation
				#[2] Unlike Python, there is no <__slots__> for R, hence this operation is dangerous
				,lock_objects = F
			)

			return(mycls)
		})

		testadd <- MyClass$new()
		testadd$add('api001')
		testadd$api001(20)
		# [1] 30

	}
}
