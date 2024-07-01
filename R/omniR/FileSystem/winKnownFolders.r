#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the special folders called [Known Folders] on Windows OS, derived from [KnownFolderID]       #
#   |Unlike the equivalent function Python branch, the argument <hToken> is omitted as R cannot provide a handle to C++ environment     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<RTools> compatible to R version must be installed, to compile the C++ script to DLL at runtime                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Original Article     ]: https://stackoverflow.com/questions/33179365/python-finding-user-id-and-moving-directories-windows        #
#   |[MSDN Reference       ]: https://msdn.microsoft.com/en-us/library/dd378457                                                         #
#   |[SHGetKnownFolderPath ]: https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath        #
#   |[Shell Solution       ]: https://stackoverflow.com/questions/29888071/                                                             #
#   |[KNOWN_FOLDER_FLAG    ]: https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/ne-shlobj_core-known_folder_flag          #
#   |[KNOWNFOLDERID        ]: https://learn.microsoft.com/zh-cn/windows/win32/shell/knownfolderid                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...         :   Any positional/named arguments that represent [Known folder names] for search via C++                              #
#   |inplace     :   Whether to keep the output the same as the input values if any cannot be found as [special folder names]           #
#   |                 [TRUE        ] <Default> Keep the input values as output if they cannot be found                                  #
#   |                 [FALSE       ]           Output [None] for those which cannot be found                                            #
#   |dwFlags     :   DWARD flags that specify special retrieval options, only length-1 is allowed                                       #
#   |                 [<see def.>  ] <Default> No special retrieval options                                                             #
#   |                 [int         ]           See constants <KNOWN_FOLDER_FLAG> as linked in above website                             #
#   |                 [hex-string  ]           String representation of the DWORD hexadecimal values, R will do the conversion          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>   :   This function output different values in below convention:                                                         #
#   |                [1] If [...] is not provided, return the full character vector of Known Folder Paths, with their respective names  #
#   |                     set as the official names, see the website: <KNOWNFOLDERID>                                                   #
#   |                [2] If [...] is provided with one element (character vector), return a named character vector with:                #
#   |                    [names ] The requested Known Folder Name as provided                                                           #
#   |                    [values] Absolute path of the requested names                                                                  #
#   |                             [Requested Name] if not found when <inplace=T>                                                        #
#   |                             [NA            ] if not found when <inplace=F>                                                        #
#   |                [3] If [...] is provided with at least two elements, return a [list] of character vectors in the convention as [2] #
#   |                    [names ] of the list: [str('.arg' + pos. num)] for [positional arguments] and [keys] for named arguments       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240629        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240701        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a value mapping                                                                                                     #
#   |      |[2] Make the C++ function more intuitive by referencing a constant than to provide a similar default value                  #
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
#   |   |Rcpp, dplyr, rlang, magrittr                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |FileSystem                                                                                                                     #
#   |   |   |thisfile                                                                                                                   #
#   |   |   |winReg_getInfByStrPattern                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	Rcpp, dplyr, rlang, magrittr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

winKnownFolders <- function(
	...
	,inplace = TRUE
	,dwFlags = 0
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	dots <- rlang::list2(...)
	if (!is.logical(inplace)) inplace <- TRUE
	if (length(dwFlags) != 1) {
		stop('[',LfuncName,']','[dwFlags] must be length-1 hex-character representation or integer!')
	}
	if (is.character(dwFlags)) dwFlags <- strtoi(dwFlags)
	if (is.na(dwFlags)) dwFlags <- 0

	#050. Local environment
	len_input <- length(dots)
	root_FD <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions'
	cpp_file <- file.path(dirname(thisfile()), 'getKnownFolderByID.cpp')
	#[ASSUMPTION]
	#[1] Introduce cache for the compiled DLL to expose C++ functions across R sessions
	thisenv <- new.env()
	cachedir <- file.path(getOption('path.omniR', tempdir()), '__rcache__')
	if (!dir.exists(cachedir)) dir.create(cachedir, recursive = T)

	#060. Define mapper for folder names
	#[ASSUMPTION]
	#[1] Check the examples for the determination of these names
	#[2] Names on the right side is the official name, see below website
	#    https://learn.microsoft.com/zh-cn/windows/win32/shell/csidl
	#[3] Names on the left side may be different on various systems hence are unreliable
	#[4] We map these names to the official ones for standardization so that when it is not sure about the name to search,
	#     one can use the official name
	#[5] As a result, an input 'My Music' is invalid, while one can only search for 'Music' as officially suggested
	map_foldername <- c(
		'Administrative Tools' = 'AdminTools'
		,'Captures' = 'AppCaptures'
		,'Application Shortcuts' = 'ApplicationShortcuts'
		,'CD Burning' = 'CDBurning'
		,'Camera Roll' = 'CameraRoll'
		,'Common Administrative Tools' = 'CommonAdminTools'
		,'Common Programs' = 'CommonPrograms'
		,'Common Start Menu' = 'CommonStartMenu'
		,'Common Startup' = 'CommonStartup'
		,'Common Templates' = 'CommonTemplates'
		,'Device Metadata Store' = 'DeviceMetadataStore'
		,'Personal' = 'Documents'
		,'Cache' = 'InternetCache'
		,'Local AppData' = 'LocalAppData'
		,'Local Documents' = 'LocalDocuments'
		,'Local Downloads' = 'LocalDownloads'
		,'Local Music' = 'LocalMusic'
		,'Local Videos' = 'LocalVideos'
		,'My Music' = 'Music'
		,'3D Objects' = 'Objects3D'
		,'My Pictures' = 'Pictures'
		,'Common AppData' = 'ProgramData'
		,'Common Desktop' = 'PublicDesktop'
		,'Common Documents' = 'PublicDocuments'
		,'CommonDownloads' = 'PublicDownloads'
		,'CommonMusic' = 'PublicMusic'
		,'CommonPictures' = 'PublicPictures'
		,'CommonRingtones' = 'PublicRingtones'
		,'PublicAccountPictures' = 'PublicUserTiles'
		,'CommonVideo' = 'PublicVideos'
		,'Quick Launch' = 'QuickLaunch'
		,'Retail Demo' = 'RetailDemo'
		,'AppData' = 'RoamingAppData'
		,'Roaming Tiles' = 'RoamingTiles'
		,'Searches' = 'SavedSearches'
		,'OneDrive' = 'SkyDrive'
		,'Start Menu' = 'StartMenu'
		,'User Pinned' = 'UserPinned'
		,'My Video' = 'Videos'
	)

	#100. Retrieve the list of constants matching the KnownFolderID to Known Folder Names
	#110. Search in the Windows Registry
	#[ASSUMPTION]
	#[1] Search within the Windows Registry for all <FolderDescriptions>
	#[2] Not all items found are linked to Known Folder Names
	#[3] Among those with a proper <Name> as a Registry Value, not all absolute paths can be identified, either
	cand_dirs <- winReg_getInfByStrPattern(
		root_FD
		,inRegExp = '^Name$'
		,chkType = 1
		,recursive = T
	)

	#150. Convert the result into a convenient structure
	df_cand_dirs <- cand_dirs %>%
		lapply(as.data.frame) %>%
		dplyr::bind_rows() %>%
		dplyr::mutate(
			!!rlang::sym('FOLDERID') := basename(!!rlang::sym('path'))
			,!!rlang::sym('FOLDERNAME') := apply_MapVal(!!rlang::sym('value'), map_foldername)
		)

	#190. Prepare a pseudo list of request given there is no input
	if (len_input == 0) {
		inplace <- FALSE
		dots <- df_cand_dirs %>%
			dplyr::pull('FOLDERNAME') %>%
			list()
	}

	#200. Helper functions
	#210. Function as the item getter
	#[ASSUMPTION]
	#[1] [getKnownFolderByID] raises error when the provided string is not linked to a known folder
	get_path <- function(v){
		tryCatch(
			thisenv$getKnownFolderByID(v, dwFlags)
			,error = function(e){return('')}
		)
	}

	#270. Function to process each element among the input dots
	dotsHdl <- function(.vec){
		#100. Retrieve FOLDERID
		df_folderid <- data.frame(FOLDERNAME = unlist(.vec), stringsAsFactors = F) %>%
			dplyr::left_join(
				df_cand_dirs
				,by = 'FOLDERNAME'
			)
		vec_folder <- df_folderid %>% dplyr::pull('FOLDERID')
		names(vec_folder) <- df_folderid %>% dplyr::pull('FOLDERNAME')

		#300. Retrieve the absolute paths of the provided official names
		dict_found <- sapply(
			vec_folder
			,get_path
			,simplify = T
			,USE.NAMES = T
		)

		#500. Unify the invalid results
		dict_found[nchar(dict_found) == 0] <- NA

		#700. Set the result in terms of [inplace]
		if (inplace) {
			mask_null <- is.na(dict_found)
			dict_found[mask_null] <- unlist(.vec)[mask_null]
		}

		#999. Export
		return(dict_found)
	}

	#400. Expose the C++ functions into a temporary R environment
	#[ASSUMPTION]
	#[1] Below statement issues warning on some system, but it does not impact the call, hence we ignore it
	#    warning: Unable to parse C++ default value 'KF_FLAG_DEFAULT' for argument dwFlag of function getKnownFolderByID
	Rcpp::sourceCpp(
		cpp_file
		,env = thisenv
		,cacheDir = cachedir
	) %>%
		suppressWarnings()

	#700. Conduct the query
	rstOut <- sapply(
		dots
		,dotsHdl
		,simplify = F
		,USE.NAMES = T
	)

	#800. Post processing
	#830. Clean the result for default query
	if (len_input == 0) {
		rstOut %<>% lapply(function(x){Filter(Negate(is.na), x)})
	}

	#890. Extract the only one vector when necessary
	#[ASSUMPTION]
	#[1] It is often used to extract one folder at a time, or a vector of folders
	#[2] Form the similar result as the equivalent one in Python branch
	#[3] We do not use <len_input> here as <dots> may have been changed
	if (length(dots) == 1) {
		rstOut <- rstOut[[1]]
	}

	#999. Export
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Find the difference between the names defined in the Registry and the Shell Constants
	if (FALSE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		root_FD <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions'
		cand_dirs <- winReg_getInfByStrPattern(
			root_FD
			,inRegExp = '^Name$'
			,chkType = 1
			,recursive = T
		)
		df_cand_dirs <- cand_dirs %>%
			lapply(as.data.frame) %>%
			dplyr::bind_rows() %>%
			dplyr::mutate(
				!!rlang::sym('FOLDERID') := basename(!!rlang::sym('path'))
			)

		#The EXCEL file is exported by Python, check the equivalent function Python branch
		xlfile <- file.path(winKnownFolders('Documents'), 'shellcon.xlsx')
		df_shellcon <- openxlsx::read.xlsx(xlfile)

		df_err <- df_shellcon %>%
			dplyr::mutate_at('FOLDERID', toupper) %>%
			dplyr::inner_join(
				df_cand_dirs %>% dplyr::mutate_at('FOLDERID', toupper)
				,by = 'FOLDERID'
			) %>%
			dplyr::filter(value != Name)

		#Prepare the string representation of the mapping of the error names
		map_con <- df_err %>%
			dplyr::mutate(
				stmt = paste(shQuote(value), '=', shQuote(Name))
			) %>%
			dplyr::pull('stmt')
		message(paste0(map_con, collapse = '\n'))
	}

	#Simple test
	if (TRUE){
		library(magrittr)

		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Retrieve [My Documents] for current logged user
		MyDocs <- winKnownFolders('Documents')

		#300. Retrieve several special folders at the same time
		curr_folders <- winKnownFolders('Desktop', 'StartMenu')

		#500. Provide named arguments
		spfolders <- winKnownFolders('Favorites', chkfonts = 'Fonts')

		#600. Test multiple vectors
		spfolders_multi <- winKnownFolders(
			c('Programs','PrintHood')
			,chkScope = c('AllUsersPrograms','Programs')
			,withInvalidNames = c('Startup','Ringtones')
			,inplace = F
		)

		#800. Test when the folder names are stored in a table-like
		v_df <- data.frame(folders = c('Documents' , 'Favorites'), stringsAsFactors = F)
		testdf1 <- v_df %>%
			dplyr::mutate(
				paths = winKnownFolders(folders)
			)

		#900. Test invalid folders
		test_invld <- winKnownFolders('Downloads', 'Robin')
		test_invld2 <- winKnownFolders('Downloads', chk = 'Robin', inplace = F)

		#990. Get the available [FOLDERID]s for retrieval
		dodLocale <- winKnownFolders()
		print(dodLocale)

	}
}
