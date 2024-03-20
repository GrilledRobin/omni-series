#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to write SAS dataset by executing SAS program to load CSV exported from the provided data frame          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDat       :   Data frame to be exported, within which the date/time like columns will be converted by certain arguments          #
#   |                [IMPORTANT] Only these dtypes can be recognized by SAS: <str>, <int>, <float>                                      #
#   |outFile     :   PathLike object indicating the full path of the output file, including file extension <sas7bdat>, although it is   #
#   |                 not verified but removed imperatively, since SAS creates its extension by all means                               #
#   |metaVar     :   Data frame that defines the meta information for SAS to import CSV datafile, see the example of the requirement    #
#   |                [None        ] <Default> Function infers the meta config                                                           #
#   |                If a data frame is provided, it should contain below columns                                                       #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |dtype      |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |VARNUM          |int        | Position of variables in the SAS dataset, as well as in the interim CSV file        #
#   |                |NAME            |str        | Column name in SAS syntax                                                           #
#   |                |FORMAT          |str        | Format name in SAS syntax                                                           #
#   |                |TYPE            |int        | Variable type, 1 for numeric, 2 for character                                       #
#   |                |LENGTH          |int        | Variable length of the actual storage in SAS dataset                                #
#   |                |FORMATL         |int        | Format length in SAS syntax, i.e. <w> in the definition <FORMATw.d>                 #
#   |                |                |           | [IMPORTANT] This value is only the display length in the converted data, the storage#
#   |                |                |           |              precision is always kept maximum during conversion                     #
#   |                |FORMATD         |int        | Format decimal in SAS syntax, i.e. <d> in the definition <FORMATw.d>                #
#   |                |                |           | [IMPORTANT] This value is only the display length in the converted data, the storage#
#   |                |                |           |              precision is always kept maximum during conversion                     #
#   |                |LABEL           |str        | [Optional] Column label in SAS syntax                                               #
#   |                |INFORMAT        |str        | [Omitted] Informat name in SAS syntax                                               #
#   |                |INFORML         |str        | [Omitted] Informat length in SAS syntax, i.e. <w> in the definition <INFORMATw.d>   #
#   |                |INFORMD         |str        | [Omitted] Informat decimal in SAS syntax, i.e. <d> in the definition <INFORMATw.d>  #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |dt_map      :   Mapping table to define the format for the SAS datetime values                                                     #
#   |                [ <see def.> ] <Default> See definition of the function                                                            #
#   |nlsMap      :   Mapping table to call SAS in native environment, see the directory <sasHome\nls>                                   #
#   |                [ <see def.> ] <Default> See definition of the function                                                            #
#   |encoding    :   Encoding of these items: SAS NLS configuration, output SAS dataset, SAS script, log message from command console   #
#   |                [ <see def.> ] <Default> See definition of the function                                                            #
#   |sasReg      :   Path of the SAS installation in Windows Registry (to search for SAS executable)                                    #
#   |                [ <see def.> ] <Default> See definition of the function                                                            #
#   |sasOpt      :   Additional options during the call to SAS executable                                                               #
#   |                [ <see def.> ] <Default> See definition of the function                                                            #
#   |wd          :   Directory of the temporary files to reside                                                                         #
#   |                [ <see def.> ] <Default> See definition of the function                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>       :   Integer return code from the communication with Windows Command Console during SAS programm execution              #
#   |                [0           ] Execution successful                                                                                #
#   |                [non-0 int   ] Failure                                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240214        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |glue, magrittr, rlang, dplyr, tidyselect, tidyr, fs, utils, lubridate                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvDB                                                                                                                    #
#   |   |   |inferContents                                                                                                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |chr                                                                                                                        #
#   |   |   |getDtypes                                                                                                                  #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$FileSystem                                                                                                               #
#   |   |   |winReg_getInfByStrPattern                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	glue, magrittr, rlang, dplyr, tidyselect, tidyr, fs, utils, lubridate
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

writeSASdat <- function(
	inDat
	,outFile
	,metaVar = NULL
	,dt_map = list(
		#[LHS] The original format in SAS
		#[RHS] The [function] to translate the corresponding values in the format of [LHS]
		#[IMPORTANT] The mapping is conducted by the sequence as provided below, check document for [apply_MapVal]
		#See official document of [SAS Date, Time, and Datetime Values]
		'(datetime|dateampm)+' = 'dt'
		,'(hhmm|mmss)+' = 't'
		,'(time|tod|hour)+' = 't'
		,'(ampm)+' = 't'
		,'(yy|mmdd|ddmm)+' = 'd'
		,'(dat|day|mon|qtr|year)+' = 'd'
		,'(jul)+' = 'd'
	)
	,nlsMap = list(
		'GB2312' = 'zh'
		,'GB18030' = 'zh'
		,'UTF-8' = 'u8'
		,'...' = '1d'
	)
	,encoding = 'GB2312'
	,sasReg = file.path('HKEY_LOCAL_MACHINE','SOFTWARE','SAS Institute Inc.','The SAS System',fsep = '\\')
	,sasOpt = paste('-MEMSIZE', '0', '-NOLOGO', '-NOLOG', '-ICON')
	,wd = getwd()
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Handle the parameter buffer.
	if (missing(metaVar) | is.null(metaVar)) metaVar <- inferContents(inDat)
	encoding <- toupper(encoding)
	trnsType <- c('dt','t','d')
	err_funcs <- Filter(function(x){!any(x %in% trnsType)}, dt_map)
	if (length(err_funcs) > 0) {
		stop(glue::glue(
			'[{LfuncName}]Values of [dt_map] should be among {toString(trnsType)}! These are not allowed: {toString(err_funcs)}'
		))
	}

	#013. Define the local environment.
	inDtype <- getDtypes(inDat)
	col_raw <- inDtype[inDtype == 'raw']
	outDir <- dirname(outFile)
	outDat <- fs::path_ext_remove(basename(outFile))
	cfg_nls <- apply_MapVal(
		encoding
		,dict_map = nlsMap
		, preserve = F
		, full.match = T
		, ignore.case = T
		, PRX = F
	)
	#[ASSUMPTION]
	#[1] There is no need to use <\r\n> or <chr(13)+chr(10)> to split lines, we only need <\n> as below
	crlf <- chr(10)
	strtab <- chr(9)

	#050. Locate SAS installation
	#The names of the direct sub-keys are the version numbers of all installed [SAS] software
	sasVers <- winReg_getInfByStrPattern(sasReg, inRegExp = '^\\d+(\\.\\d+)+$', chkType = 2)
	if (length(sasVers) == 0) {
		stop(glue::glue(
			'[{LfuncName}]SAS software is not properly installed! Check Windows Registry: <{sasReg}> for installation status.'
		))
	}
	sasVers_comp <- Filter(function(x){tryCatch({numeric_version(x[['name']]);T;}, error = function(e){F})}, sasVers)
	sasVer <- Reduce(function(a,b){if (compareVersion(a[['name']],b[['name']]) >= 0) a else b}, sasVers_comp)[['name']]
	sasHome <- winReg_getInfByStrPattern(file.path(sasReg, sasVer, fsep = '\\'), 'DefaultRoot')[[1]][['value']]
	sasExe <- shQuote(file.path(sasHome, 'sas.exe'))
	sasNls <- shQuote(file.path(sasHome, 'nls', cfg_nls, 'sasv9.cfg'))
	sasInit <- paste(sasOpt, '-CONFIG', sasNls)

	#100. Define converters
	#110. Helper functions
	#Quote: https://stat.ethz.ch/R-manual/R-devel/library/base/html/strptime.html
	h_convDT <- function(vec) strftime(vec, '%Y-%m-%d %H:%M:%OS6')
	h_convD <- function(vec) strftime(vec, '%Y%m%d')
	h_convT <- function(vec) strftime(lubridate::as_datetime(vec), '%H:%M:%OS6')
	h_convOth <- function(vec)vec

	#130. Map the conversion
	dt_conv <- data.frame(
		'.trns_type.' = c('dt','t','d','$','Oth')
		,'INFORMAT' = c('YMDDTTM','TIME','YYMMDD','$','BEST')
		,'INFORML' = c(26,15,10,0,32)
		,'INFORMD' = c(6,6,0,0,0)
	)
	map_funcs <- list(
		'dt' = h_convDT
		,'t' = h_convT
		,'d' = h_convD
		,'$' = h_convOth
		,'Oth' = h_convOth
	)

	#300. Mutate the meta config table to adapt to SAS syntax
	#310. Helper function to locate the special fields
	h_getInType <- function(v_type,v_format) {
		#100. Prepare the mapper for the entire vector, to save system effort
		v_mapper <- apply_MapVal(
			v_format
			,dt_map
			,preserve = F
			,full.match = F
			,ignore.case = T
			,PRX = T
		)

		#900. Calculation
		mapply(
			function(t,f,m) {
				if (t == 2) {
					return('$')
				} else {
					if (is.na(m)) {
						return('Oth')
					} else {
						return(m)
					}
				}
			}
			,v_type
			,v_format
			,v_mapper
		)
	}

	#380. Translation
	calcVar <- c('INFORMAT','INFORML','INFORMD')
	metaConv <- metaVar %>%
		dplyr::select(-tidyselect::any_of(calcVar)) %>%
		dplyr::arrange_at('VARNUM') %>%
		dplyr::mutate(
			!!rlang::sym('.trns_type.') := h_getInType(!!rlang::sym('TYPE'), !!rlang::sym('FORMAT'))
		) %>%
		dplyr::left_join(dt_conv, by = '.trns_type.') %>%
		dplyr::mutate(
			!!rlang::sym('FORMAT') := tidyr::replace_na(!!rlang::sym('FORMAT'), '')
			,!!rlang::sym('INFORML') := ifelse(
				!!rlang::sym('.trns_type.') == '$'
				,!!rlang::sym('LENGTH')
				,!!rlang::sym('INFORML')
			)
			,!!rlang::sym('INFORMD') := ifelse(
				!!rlang::sym('.trns_type.') == '$'
				,0
				,!!rlang::sym('INFORMD')
			)
		) %>%
		dplyr::mutate(
			!!rlang::sym('FORMATD') := ifelse(!!rlang::sym('NAME') %in% names(col_raw), 0, !!rlang::sym('FORMATD'))
		)
	if ('LABEL' %in% names(metaConv)) {
		metaConv %<>%
			dplyr::mutate(
				!!rlang::sym('LABEL') := trimws(tidyr::replace_na(!!rlang::sym('LABEL'), ''))
			)
	}

	#500. Mutate the provided data for export
	rstOut <- inDat

	#510. Convert datetime-like columns
	for (t in trnsType) {
		col_t <- metaConv %>%
			dplyr::filter(!!rlang::sym('.trns_type.') == t) %>%
			dplyr::pull('NAME')
		if (length(col_t) > 0) {
			rstOut %<>% dplyr::mutate_at(col_t, ~tidyr::replace_na(map_funcs[[t]](.),''))
		}
	}

	#530. Convert string-oriented columns
	col_str <- metaConv %>%
		dplyr::filter(!!rlang::sym('.trns_type.') == '$') %>%
		dplyr::pull('NAME')
	if (length(col_str) > 0) {
		rstOut %<>%
			dplyr::mutate_at(
				col_str
				,~tidyr::replace_na(
					sapply(., function(x){ if (is.na(x)) '' else toString(x)})
					,''
				)
			)
	}

	#550. Convert <raw> columns, literally hexadecimals, into integer columns
	if (length(col_raw) > 0) {
		rstOut %<>% dplyr::mutate_at(names(col_raw), as.integer)
	}

	#700. Prepare SAS script to load CSV file
	#710. Informat
	scr_infmt <- paste0(
		strtab,strtab
		,metaConv[['NAME']]
		,strtab
		,metaConv[['INFORMAT']]
		,metaConv[['INFORML']]
		,'.'
		,metaConv[['INFORMD']]
	) %>%
		paste0(collapse = crlf)

	#720. Format
	#[ASSUMPTION]
	#[1] SAS variables could have null formats
	#[2] In such case, we have to skip the statement for it
	metaSub_fmt <- metaConv %>% dplyr::filter(!!rlang::sym('FORMAT') != '')
	scr_fmt <- paste0(
		strtab
		,'FORMAT'
		,strtab
		,metaSub_fmt[['NAME']]
		,strtab
		,metaSub_fmt[['FORMAT']]
		,metaSub_fmt[['FORMATL']]
		,'.'
		,metaSub_fmt[['FORMATD']]
		,';'
	) %>%
		paste0(collapse = crlf)

	#730. Input statement
	scr_input <- paste0(
		strtab,strtab
		,metaConv[['NAME']]
		,strtab
		,ifelse(metaConv[['.trns_type.']] == '$', '$', '')
	) %>%
		paste0(collapse = crlf)

	#740. Length
	scr_length <- paste0(
		strtab,strtab
		,metaConv[['NAME']]
		,strtab
		,ifelse(metaConv[['.trns_type.']] == '$', '$', '')
		,metaConv[['LENGTH']]
	) %>%
		paste0(collapse = crlf)

	#750. Labels
	#[ASSUMPTION]
	#[1] SAS variables could have null labels
	#[2] In such case, we have to skip the statement for it
	if ('LABEL' %in% names(metaConv)) {
		metaSub_lbl <- metaConv %>% dplyr::filter(!!rlang::sym('LABEL') != '')
		scr_label <- paste0(
			strtab
			,'LABEL'
			,strtab
			,metaSub_lbl[['NAME']]
			,strtab
			,'='
			,strtab
			,'%sysfunc(quote(%nrstr('
			,metaSub_lbl[['LABEL']]
			,'), %nrstr(%\')));'
		) %>%
			paste0(collapse = crlf)
	} else {
		scr_label <- ''
	}

	#760. Determine whether to compress the data
	#[ASSUMPTION]
	#[1] SAS compression will consume more disk space if the original size of dataset is less than 128KB
	if (object.size(rstOut) > (128 * 1024)) {
		cmp <- 'yes'
	} else {
		cmp <- 'no'
	}

	#770. Input options
	time_file <- gsub('\\W','',h_convDT(lubridate::now()))
	int_csv <- file.path(wd, glue::glue('forsas{time_file}.csv'))
	scr_infile <- c(
		glue::glue('%sysfunc(quote(%nrstr({int_csv}),%nrstr(%\')))')
		,'firstobs = 1'
		,'dsd'
		,'missover'
		,'lrecl = 32767'
		,'dlm = "|"'
		,'encoding = "UTF-8"'
	) %>%
		paste0(collapse = paste0(crlf,strtab,strtab))

	#780. Full statements
	scr_final <- c(
		glue::glue('libname rst %sysfunc(quote(%nrstr({outDir}), %nrstr(%\')));')
		,glue::glue('data rst.{outDat}(compress = {cmp} encoding = "{encoding}");')
		,paste0(strtab,'length')
		,scr_length
		,paste0(strtab,';')
		,paste0(strtab,'informat')
		,scr_infmt
		,paste0(strtab,';')
		,scr_fmt
		,scr_label
		,paste0(strtab,'infile')
		,paste0(strtab,strtab,scr_infile)
		,paste0(strtab,';')
		,paste0(strtab,'input')
		,scr_input
		,paste0(strtab,';')
		,'run;'
		,''
	) %>%
		paste0(collapse = crlf)

	#790. Write the script to harddisk for later call
	sasScr <- file.path(wd, glue::glue('forsas{time_file}.sas'))
	rc <- writeLines(scr_final, sasScr)

	#800. Write SAS dataset
	#810. Export the data to harddisk
	if (file.exists(int_csv)) rc <- file.remove(int_csv)
	rc <- write.table(
		rstOut
		,file = int_csv
		,sep = '|'
		,col.names = F
		,row.names = F
		,fileEncoding = 'UTF-8'
		,qmethod = 'double'
		,na = ''
	)

	#850. Call SAS to load the data
	sas_cmd <- paste(sasExe, sasScr, sasInit)
	rstRC <- system(sas_cmd, intern = T, minimized = T)

	#858. Collect the execution result
	if (!is.null(attr(rstRC, 'status'))) {
		warning(glue::glue('[{LfuncName}]COMMAND CONSOLE WARNING:', toString(attr(rstRC, 'errmsg'))))
	}

	#900. Purge
	#910. Remove all temporary files
	if (file.exists(sasScr)) rc <- file.remove(sasScr)
	if (file.exists(int_csv)) rc <- file.remove(int_csv)

	#999. Return the RC from SAS console
	return(rstRC)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

		library(magrittr)

		#100. Load the meta config table for data conversion
		#[ASSUMPTION]
		#[1] There is no dtype as <Timestamp> in R, hence we drop its meta config
		dir_omniPy <- 'D:/Python'
		conv_meta <- openxlsx::readWorkbook(file.path(dir_omniPy, 'omniPy', 'AdvDB', 'meta_writeSASdat.xlsx')) %>%
			dplyr::filter(NAME != 'var_ts')

		#200. Create data frame in terms of the indication in above meta config table
		aaa <- data.frame(
			var_str = c('abcde')
			,var_int = c(5)
			,var_float = c(14.678)
			,var_date = c('2023-12-25')
			,var_dt = c('2023-12-25 12:34:56.789012')
			,var_time = c('12:34:56.789012')
			,stringsAsFactors = F
		) %>%
			dplyr::mutate(
				var_int = as.integer(var_int)
				,var_date = asDates(var_date)
				,var_dt = asDatetimes(var_dt)
				,var_time = asTimes(var_time)
			)

		#300. Convert the data to SAS dataset
		outf <- file.path(getwd(), 'vfysas.sas7bdat')
		rc <- writeSASdat(
			aaa
			,outf
			,metaVar = conv_meta
		)
		if (file.exists(outf)) rc <- file.remove(outf)

		#500. Convert the data to SAS dataset without meta config table
		#[ASSUMPTION]
		#[1] Dtypes that are not involved below CANNOT be exported, and will lead to exceptions
		testdf <- data.frame(
			var_str = c('abcde',NA)
			,var_raw = c(as.raw(40), charToRaw('A'))
			,var_int = c(5,7)
			,var_float = c(14.678,83.32)
			,var_date = c('2023-12-25','2023-12-32')
			,var_dt = c('2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812')
			,var_time = c('12:34:56.789012','789')
			,var_bool = c(T,F)
			,var_cat = as.factor(c('abc','def'))
			,var_complex = c(1 + 3i, 12.4 + 4.6i)
			,stringsAsFactors = F
		) %>%
			dplyr::mutate(
				var_int = as.integer(var_int)
				,var_date = asDates(var_date)
				,var_dt = asDatetimes(var_dt)
				,var_time = asTimes(var_time)
			)

		outf2 <- file.path(getwd(), 'vfysas2.sas7bdat')
		rc <- writeSASdat(
			testdf
			,outf2
		)
		if (file.exists(outf2)) rc <- file.remove(outf2)

		#700. Read SAS dataset and export it to SAS again
		loadsas <- std_read_SAS(file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat'), encoding = 'GB2312')
		outf3 <- file.path(getwd(), 'vfysas3.sas7bdat')
		rc <- writeSASdat(loadsas,outf3,encoding = 'GB2312')
		if (file.exists(outf3)) rc <- file.remove(outf3)

	}
}
