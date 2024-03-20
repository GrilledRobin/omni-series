#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This script is intended to act as the [autoexec] as in other languages, to load necessary environment when a project is initiated  #
#   |Please [source] this script at the beginning of the scripts in your project to conduct below processes:                            #
#   |[1] Activate all user defined functions from [omniR] directory into current session                                                #
#   |[2] Find the location of [Calendar Adjustment Data] in preparation of any date-related operations                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Generated global environments, i.e. using [getOption()]                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |file.autoexec       :   Absolute path of the global environment setter script [autoexec.r]                                         #
#   |TZ                  :   Time Zone for date-like operations                                                                         #
#   |path.omniR          :   Physically existing directory of the user defined library, the same value as [path_omniR]                  #
#   |CountryCode         :   Country Code for specifying during function calls, such as [UserCalendar]                                  #
#   |ClndrAdj            :   Physically existing file path to the [Calendar Adjustment Data], the same value as [path_ClndrAdj]         #
#   |fmt.def.GTSFK       :   Default format to translate strings into date strings for function [DBuse_GetTimeSeriesForKpi]             #
#   |fmt.opt.def.GTSFK   :   Default options for the format [fmt.def.GTSFK] as defined above, both basically used in [apply_MapVal]     #
#   |args.def.GTSFK      :   Default arguments for function [DBuse_GetTimeSeriesForKpi]                                                 #
#   |fmt.parseDates      :   Default behavior to format the date values before assigning them to their respective local variables       #
#   |args.Calendar       :   Default arguments for instantiation of classes: [omniR$Dates$UserCalendar] and [omniR$Dates$ObsDates]      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Generated global variables                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |name_omniR          :   Name of the user defined library, which contains many useful functions                                     #
#   |candidate_ClndrAdj  :   Candidate full paths of the [Calendar Adjustment Data]                                                     #
#   |path_omniRs         :   Candidate directory names of the user defined library as [name_omniR]                                      #
#   |path_omniR          :   Physically existing directory of the user defined library as [name_omniR]                                  #
#   |omniR_Files         :   All functions stored within the user defined library as [name_omniR]                                       #
#   |G_clndr             :   Business calendar from 5 years ago to 1 month later, counting from [lubridate::today()]                    #
#   |G_obsDates          :   Business date-shifting tool covering the period from 5 years ago to 1 month later, counting from           #
#   |                         [lubridate::today()]; with default [G_obsDates$values==lubridate::today()]                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210106        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210614        | Version | 1.02        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce [fmt.parseDates] to assign the formatted date values to their corresponding local variables                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210816        | Version | 1.03        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now search for the subdirectory [omnimacro] among all candidate directories                                             #
#   |      |[2] Add default arguments [args.Calendar] for date-related classes                                                          #
#   |      |[3] Add option [file.autoexec] for current session to locate [autoexec.r]                                                   #
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
#   |   |magrittr, lubridate, tmcn, readr                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$FileSystem                                                                                                               #
#   |   |   |thisfile                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, lubridate, tmcn, readr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#100. Establish environment
#Below package provides the support of pipe operand [ %>% ]
#It is better to change the keyboard shortcut of [ %>% ] into: ALT+M (Default one is: CTRL+SHIFT+M)
library(magrittr)
#Below package provides the support of date operands, such as [ %m+% ]
library(lubridate)
#Below function provides the support to recognition of MBCS characters in the source programs
tmcn::setchs()

#110. Define the hard coding inputs
#[Quote: https://www.r-bloggers.com/doing-away-with-%e2%80%9cunknown-timezone%e2%80%9d-warnings/ ]
#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

drives_autoexec <- c('D:', 'C:')
paths_autoexec <- c('R', 'Robin', 'RobinLu', 'SAS')
name_omniR <- 'omniR'
name_omnimacro <- 'omnimacro'
#Quote: https://stackoverflow.com/questions/22099546/creating-combinations-of-two-vectors
comb_autoexec <- expand.grid(drives_autoexec, paths_autoexec, stringsAsFactors = F)
path_omniRs <- file.path(comb_autoexec[[1]], comb_autoexec[[2]], name_omniR)
paths_omnimacro <- file.path(comb_autoexec[[1]], comb_autoexec[[2]], name_omnimacro)
# candidate_ClndrAdj <- file.path(paths_omnimacro, 'Dates', 'CalendarAdj.csv')

#200. Import the user defined package
#210. Only retrieve the first valid path from the list of candidate paths
path_omniR <- head(Filter(dir.exists, path_omniRs), 1)

#290. Import the functions from the package
omniR_Files <- list.files( path_omniR , '^.+\\.r$' , full.names = T , ignore.case = T , recursive = T , include.dirs = T ) %>%
	normalizePath()
if (length(omniR_Files)>0){
	o_enc <- sapply(omniR_Files, function(x){readr::guess_encoding(x)$encoding[1]})
	for (i in 1:length(omniR_Files)){source(omniR_Files[i],encoding = o_enc[i])}
}

#301. Identify the absolute path of current script
#Below function is from [omniR$FileSystem]
LfileName <- thisfile()

#400. Identify the dates to be adjusted based on government policy
# path_ClndrAdj <- head(Filter(file.exists, candidate_ClndrAdj), 1)
path_ClndrAdj <- getCalendarAdj(
	lst_drives = drives_autoexec
	,lst_parent = paths_autoexec
	,lst_fpath = c(name_omniR, name_omnimacro)
	,lst_fcurr = 'Dates'
)

#500. Create global system options (similar to global variables, but more specific when being referenced to during program call)
#Below options are dependencies to the rest options
options(
	file.autoexec = LfileName
	,fmt.def.GTSFK = list(
		#The values of this list are the names of local variables defined in [DBuse_GetTimeSeriesForKpi]
		'&c_date.' = 'L_d_curr'
		,'&L_curdate.' = 'L_d_curr'
		,'&L_curMon.' = 'L_m_curr'
		,'&L_prevMon.' = 'L_m_curr'
	)
	,fmt.opt.def.GTSFK = list(
		#See syntax of function [apply_MapVal]
		PRX = F
		,fPartial = T
		,full.match = F
		,ignore.case = T
	)
	,fmt.parseDates = list(
		'L_d_curr' = '%Y%m%d'
		,'L_m_curr' = '%Y%m'
	)
	,CountryCode = 'CN'
	,ClndrAdj = path_ClndrAdj
)

options(
	path.omniR = path_omniR
	,args.Calendar = list(
		countrycode = getOption('CountryCode')
		,CalendarAdj = getOption('ClndrAdj')
		,fmtDateIn = c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
		,fmtDateOut = '%Y%m%d'
		,DateOutAsStr = FALSE
		#[1826 = 365 * 5 + 2 - 1] as there are 2 leap years within 5 years period
		,clnBgn = lubridate::today() - as.difftime(1825, units = 'days')
		#30 days is enough to determine whether current date is the last workday/tradeday of current month
		,clnEnd = lubridate::today() + as.difftime(30, units = 'days')
	)
	,args.def.GTSFK = list(
		inKPICfg = NULL
		,InfDatCfg = list(
			InfDat = NULL
			,.paths = NULL
			,DatType = 'RAM'
			,DF_NAME = NULL
			,.trans = getOption('fmt.def.GTSFK')
			,.trans.opt = getOption('fmt.opt.def.GTSFK')
			,.imp.opt = list(
				SAS = list(
					encoding = 'GB2312'
				)
			)
			,.func = NULL
			,.func.opt = NULL
		)
		,SingleInf = F
		,dnDates = NULL
		,ColRecDate = 'D_RecDate'
		,MergeProc = 'MERGE'
		,keyvar = 'nc_cifno'
		,SetAsBase = 'k'
		,KeepInfCol = F
		,fTrans = getOption('fmt.def.GTSFK')
		,fTrans.opt = getOption('fmt.opt.def.GTSFK')
		,fImp.opt = list(
			SAS = list(
				encoding = 'GB2312'
			)
		)
		#Whether to use multiple CPU cores to import the data in parallel; [T] is recommended for large number of large data files
		,.parallel = T
		,omniR.ini = LfileName
		,cores = 4
		,fDebug = F
		,miss.skip = T
		,miss.files = 'G_miss_files'
		,err.cols = 'G_err_cols'
		,dup.KPIs = 'G_dup_kpiname'
		#Provide the same value for [AggrBy] as [keyvar], or just [AggrBy=NULL] to keep all columns from [InfDat]
		,AggrBy = NULL
		#Below paramter is for [tidyr:pivot_wider] within function [DBuse_MrgKPItoInf]
		#Starting from [R.ver >= 4.0.0] it can be simplified as [values_fn = sum] given there is only one column for evaluation.
		,values_fn = list(A_KPI_VAL = sum)
		#Below parameters represent [...] for [tidyr:pivot_wider]
		,values_fill = list(A_KPI_VAL = 0)
	)
)

#700. Instantiate universal calendar objects for date retrieval and shifting process
#Below classes are from [omniR$Dates]
#710. Create Business calendar from 5 years ago to 1 month later, counting from [lubridate::today()]
G_clndr <- do.call(UserCalendar$new, getOption('args.Calendar'))

#720. Create Business date-shifting tool covering the period from 5 years ago to 1 month later, counting from [lubridate::today()]
G_obsDates <- do.call(ObsDates$new, getOption('args.Calendar'))
