#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the default UI Language of Windows OS, a.k.a Display Language                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   | https://stackoverflow.com/questions/3425294/how-to-detect-the-os-default-language-in-python                                       #
#   | https://stackoverflow.com/questions/7749999/converting-lcid-to-language-string                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not take argument                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>       :   String in the format of [zh_CN] or [en_US]                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240613        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |Rcpp                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |chr                                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	Rcpp
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

getWinUILanguage <- function(){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	#[ASSUMPTION]
	#[1] Introduce cache for the compiled DLL to expose C++ functions across R sessions
	thisenv <- new.env()
	cachedir <- file.path(getOption('path.omniR', tempdir()), '__rcache__')
	if (!dir.exists(cachedir)) dir.create(cachedir, recursive = T)

	#100. Define the C++ script to expose for R session
	#[ASSUMPTION]
	#[1] How to load <DLL> at runtime
	#    https://stackoverflow.com/questions/52025324/dynamically-load-user32-dll-from-r-call-external-function
	#[2] How to call C++ function via Rcpp
	#    https://stackoverflow.com/questions/59288265/rcpp-calling-c-function-in-r-without-exporting-c-function
	#[3] MS Official document for <GetUserDefaultUILanguage>, a.k.a. <Windows display language> in Control Panel
	#    https://learn.microsoft.com/zh-cn/windows/win32/api/winnls/nf-winnls-getuserdefaultuilanguage
	#[4] How to convert <LANGID>
	#    https://stackoverflow.com/questions/1192361/how-to-convert-microsoft-locale-id-lcid-into-language-code-or-locale-object-in
	#[5] How to safely convert <wchar_t>
	#    https://stackoverflow.com/questions/4339960/how-do-i-convert-wchar-t-to-stdstring
	cpp_script <- paste0(
		c(
			#010. Load namespaces
			#[ASSUMPTION]
			#[1] The sequence matters
			'#include <Windows.h>'
			,'#include <winnls.h>'
			,'#include <Rcpp.h>'
			,''
			#100. Function to extract the Windows display language
			,'// [[Rcpp::export]]'
			,'SEXP getUUILang(){'
				#100. Retrieve the language ID
				,paste0(chr(9),'LANGID rst = GetUserDefaultUILanguage();')
				#300. Translate the ID into Country Name
				#Quote: https://learn.microsoft.com/zh-cn/windows/win32/intl/locale-siso-constants
				,paste0(chr(9),'int nc_ctry = GetLocaleInfoW(rst, LOCALE_SISO3166CTRYNAME, NULL, 0);')
				,paste0(chr(9),'wchar_t* ctryName = new wchar_t[nc_ctry];')
				,paste0(chr(9),'GetLocaleInfoW(rst, LOCALE_SISO3166CTRYNAME, ctryName, nc_ctry);')
				# ,paste0(chr(9),'GetLocaleInfoW(rst, LOCALE_SISO3166CTRYNAME, ctryName, sizeof(ctryName));')
				,paste0(chr(9),'std::wstring ws_ctryName(ctryName);')
				,paste0(chr(9),'std::string s_CN(ws_ctryName.begin(), ws_ctryName.end());')
				,''
				#500. Translate the ID into Language Name
				,paste0(chr(9),'int nc_lang = GetLocaleInfoW(rst, LOCALE_SISO639LANGNAME, NULL, 0);')
				,paste0(chr(9),'wchar_t* langName = new wchar_t[nc_lang];')
				,paste0(chr(9),'GetLocaleInfoW(rst, LOCALE_SISO639LANGNAME, langName, nc_lang);')
				,paste0(chr(9),'std::wstring ws_langName(langName);')
				,paste0(chr(9),'std::string s_LN(ws_langName.begin(), ws_langName.end());')
				,''
				#900. Export the type of string
				#Quote: https://stackoverflow.com/questions/662918/how-do-i-concatenate-multiple-c-strings-on-one-line
				#[ASSUMPTION]
				#[1] We follow the convention of the Python equivalence, e.g. <zh_CN> and <en_US>
				,paste0(chr(9),'std::string cout;')
				,paste0(chr(9),'cout.append(s_LN).append("_").append(s_CN);')
				,paste0(chr(9),'return Rcpp::wrap(cout);')
			,'}'
		)
		,collapse = '\n'
	)

	#800. Expose the C++ functions into a temporary R environment
	Rcpp::sourceCpp(
		code = cpp_script
		,env = thisenv
		,cacheDir = cachedir
	)

	#999. Return the result
	return(thisenv$getUUILang())
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		dir_omniR <- 'D:\\R'
		source(file.path(dir_omniR, 'autoexec.r'))

		#100. Retrieve the result via C++ function
		userLang <- getWinUILanguage()
	}
}
