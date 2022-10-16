#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to query the information of the Windows Registry Item.                                                   #
#   |It is useful to search for the installation path of any specific software on current Windows OS                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKEY       :   The Key within which to search for the item in Windows Registry, e.g. <HKEY_LOCAL_MACHINE\SOFTWARE>                #
#   |inRegExp    :   Name pattern of the item, i.e. <sub-key>s or the name of <value>s for a key                                        #
#   |                NOTE: If one needs to query the unnamed <Default> value of a key, just input '^HK_Def$' for this argument          #
#   |                 [^HK_Def$    ] <Default> Query the unnamed <Default> value of <inKEY>                                             #
#   |exRegExp    :   Name pattern of the item to be excluded from the searching result                                                  #
#   |                 [^$          ] <Default> Do not exclude any valid pattern                                                         #
#   |chkType     :   Type of the item to be searched                                                                                    #
#   |                 [1           ] <Default> Query the content of <value> of any Windows Registry Item                                #
#   |                 [2           ]           Query the names of <sub-key> of any Windows Registry Key (like a sub-directory)          #
#   |                 [0           ]           Query the names of <sub-key> and the content of <value> within the key                   #
#   |recursive   :   Whether to search for all sub-keys, if any, within the requested <inKEY> recursively                               #
#   |                 [False       ] <Default> Only query the direct subordinates of the requested <inKEY>                              #
#   |                 [True        ]           Query the names within all <sub-keys> in recursion                                       #
#   |loggerInf   :   Callable to print <NOTE> into the logging system for debugging purpose                                             #
#   |                 [message     ] <Default> Print the <NOTE> messages into current console                                           #
#   |                 [Callable    ]           Any Callable to conduct the log printing                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |list        :   List of named lists with below items:                                                                              #
#   |                 [path        ] Full path in the Windows Registry of current item                                                  #
#   |                 [name        ] Name of the item, or 'HK_Default' when it is the unnamed default value of any key                  #
#   |                                NOTE: If the default value of any key is not set, there will not be a result for this key          #
#   |                 [value       ] Value of the item, when [chkType==0], it is the same as <name>                                     #
#   |                 [type        ] Type of the item, current function cannot retrieve it hence it is set to [NA] for all              #
#   |                 [regtype     ] Registry Type of the item, <subkey> or <value>                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20221015        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |utils, magrittr, purrr                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, purrr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

winReg_getInfByStrPattern <- function(
	inKEY
	,inRegExp = '^HK_Def$'
	,exRegExp = '^$'
	,chkType = 1
	,recursive = FALSE
	,loggerInf = message
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	if (length(inKEY) > 1) {
		stop('[',LfuncName,'][inKEY] should be a string with length 1!')
	}
	rstDef <- list('(Default)' = NULL) %>% {Filter(Negate(is.null), .)}
	if (length(inKEY) == 0 | nchar(trimws(inKEY)) == 0) return(rstDef)
	if (nchar(trimws(inRegExp)) == 0) {
		loggerInf('[',LfuncName,']No pattern is specified, program only searches default value for current key.')
		inRegExp <- '^HK_Def$'
	}
	if (nchar(trimws(exRegExp)) == 0) {
		exRegExp <- '^$'
	}
	if (!chkType %in% c(0,1,2)) {
		loggerInf('[',LfuncName,']No type is specified. Program will search for <value> instead of <sub-key>.')
		chkType <- 1
	}
	if (!is.logical(recursive)) {
		stop('[',LfuncName,']Parameter [recursive] should be of the type [logical]!')
	}

	#015. Function local variables
	rstOut <- list()
	re.I <- re.S <- re.M <- re.X <- TRUE
	opts_switch <- stringi::stri_opts_regex(
		case_insensitive = re.I
		,dotall = re.S
		,multiline = re.M
		,comments = re.X
	)
	map_root <- c(
		'HLM' = 'HKEY_LOCAL_MACHINE'
		,'HCR' = 'HKEY_CLASSES_ROOT'
		,'HCU' = 'HKEY_CURRENT_USER'
		,'HU' = 'HKEY_USERS'
		,'HCC' = 'HKEY_CURRENT_CONFIG'
		,'HPD' = 'HKEY_PERFORMANCE_DATA'
	)
	if (.Platform$OS.type == 'windows') {
		filesep <- '\\'
	} else {
		filesep <- .Platform$file.sep
	}
	keySplit <- strsplit(inKEY, filesep, fixed = T)
	rootKey <- keySplit %>%
		sapply('[[', 1, simplify = T) %>%
		sapply(function(x){names(map_root)[[match(x, map_root)]]})
	keyPath <- keySplit %>%
		sapply(function(x){do.call(file.path, c(as.list(x[-1]), fsep = filesep))}, simplify = T)

	#100. Setup helper functions
	#110. Function to include certain types
	h_type <- function(x){chkType %in% c(0, ifelse(x == '<subkey>', 2, 1))}

	#170. Function to exclude certain patterns
	h_exclude <- purrr::partial(
		stringi::stri_detect_regex
		,pattern = exRegExp
		,negate = T
		,opts_regex = opts_switch
	)

	#180. Function to include certain patterns
	h_include <- purrr::partial(
		stringi::stri_detect_regex
		,pattern = inRegExp
		,negate = F
		,opts_regex = opts_switch
	)

	#200. Conduct the query in the Windows Registry
	#[ASSUMPTION]:
	#[1] The provided [inKEY] may be invalid
	#[2] There may not be a [sub-key] of the provided [inKEY]
	#[3] Resemble the behavior of [Python:winreg] by not raising errors
	regConn <- tryCatch(
		readRegistry(keyPath, rootKey)
		,error = function(e) {rstDef}
	)

	#300. Filter the result by type
	actkey <- Filter(h_type, regConn)

	#400. Translate certain items
	#410. Rename the unnamed <Default> value
	#[(Default)] is provided by R regardless of OS language
	names(actkey)[names(actkey) == '(Default)'] <- 'HK_Def'

	#500. Skip if it is requested to be excluded
	#Quote: https://community.rstudio.com/t/filtering-a-list-with-purrr-keep/24790/4
	filterKey <- actkey %>% {magrittr::extract(., Filter(h_exclude, names(.)))}

	#600. Skip if it does not match the requested pattern
	filterKey %<>% {magrittr::extract(., Filter(h_include, names(.)))}

	#700. Form the result
	rstOut <- lapply(
		seq_along(filterKey)
		,function(i){
			list(
				'path' = inKEY
				,'name' = names(filterKey)[[i]]
				,'value' = ifelse(filterKey[[i]] == '<subkey>', names(filterKey)[[i]], filterKey[[i]])
				,'type' = NA
				,'regtype' = ifelse(filterKey[[i]] == '<subkey>', 'subkey', 'value')
			)
		}
	)

	#800. Continue the recursion when required
	if (recursive) {
		#100. Identify all <sub-key>s regardless of the filtration logic
		recKey <- Filter(function(x){x == '<subkey>'}, regConn) %>%
			names() %>%
			lapply(function(x){ file.path(inKEY, x, fsep = filesep) })

		#900. Append the result
		rstOut <- c(
			rstOut
			,do.call(c, lapply(
				recKey
				,function(x){
					do.call(
						LfuncName
						,list(
							x
							,inRegExp = inRegExp
							,exRegExp = exRegExp
							,chkType = chkType
							,recursive = recursive
							,loggerInf = loggerInf
						)
					)
				}
			))
		)
	}

	#999. Return the values
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Retrieve the installation path for the latest version of [SAS] installed
		#Quote: https://web.mit.edu/r/current/lib/R/library/utils/html/compareVersion.html
		sasKey <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\SAS Institute Inc.\\The SAS System'
		#The names of the direct sub-keys are the version numbers of all installed [SAS] software
		sasVers <- winReg_getInfByStrPattern(sasKey, inRegExp = '^.*$', chkType = 2)
		if (length(sasVers) > 0) {
			sasVer <- Reduce(function(a,b){if (compareVersion(a[['name']],b[['name']]) >= 0) a else b}, sasVers)[['name']]
			message(winReg_getInfByStrPattern(file.path(sasKey, sasVer, fsep = '\\'), 'DefaultRoot')[[1]][['value']])
		}

		#200. Retrieve the installation path for the latest version of [Python] installed
		pyKey <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore'
		#The names of the direct sub-keys are the version numbers of all installed [Python] software
		pyVers <- winReg_getInfByStrPattern(pyKey, inRegExp = '^.*$', chkType = 2)
		if (length(pyVers) > 0) {
			pyVer <- Reduce(function(a,b){if (compareVersion(a[['name']],b[['name']]) >= 0) a else b}, pyVers)[['name']]
			message(winReg_getInfByStrPattern(file.path(pyKey, pyVer, 'InstallPath', fsep = '\\'))[[1]][['value']])
		}

		#300. Retrieve [R] installation path
		rKey <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\R-core\\R64'
		rVal <- 'InstallPath'
		r_install <- winReg_getInfByStrPattern(rKey, rVal)
		if (length(r_install) > 0) {
			message(r_install[[1]][['value']])
		}
	}
}
