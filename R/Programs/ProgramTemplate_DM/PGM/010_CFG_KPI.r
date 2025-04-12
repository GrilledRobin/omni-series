#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to load the KPI configuration as well as the requested KPIs for current report                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] There may be multiple steps to load different KPIs under different conditions, hence we make this step standalone              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250412        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |magrittr, dplyr, rlang, openxlsx                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#

message('Load the KPI core configuration')
#010. Local environment
L_srcflnm1 <- file.path(dir_data_raw, 'CFG_KPI.xlsx')
L_stpflnm1 <- file.path(dir_data_src, 'CFG_KPI.RData')
dataIO$add('R')

message('100. Define helper functions')
#[ASSUMPTION]
#[1] We set the prefix of all helper functions as <h_>
#[2] This is to distinguish the objects from those imported from other modules or packages
#110. Function to join the paths out of vectors
safe_path <- function(fparent,fname) {
	psep <- '[\\\\/\\s]+'
	fname_int <- gsub(paste0('^', psep), '', fname)
	rstOut <- file.path(gsub(paste0(psep, '$'), '', fparent), fname_int)
	parent_empty <- nchar(fparent) == 0
	parent_empty[is.na(parent_empty)] <- T
	rstOut[parent_empty] <- fname_int[parent_empty]
	return(rstOut)
}

message('200. Determine whether to refresh the RData')
h_vfy_cfg <- function() {
	if (file.exists(L_stpflnm1)) {
		#Quote: https://datacornering.com/how-to-get-when-a-file-is-created-or-modified-in-r/
		if (file.info(L_srcflnm1)$mtime < file.info(L_stpflnm1)$mtime) {
			message('<CFG_KPI> is the latest, no need to import again.')
			return(invisible(NULL))
		}
	}

	message('300. Import the raw data')
	cfg_kpi_pre <- list(
		'KPIConfig' = openxlsx::readWorkbook(
			L_srcflnm1
			,sheet = 'KPIConfig'
			,detectDates = T
		)
		,'LibConfig' = openxlsx::readWorkbook(
			L_srcflnm1
			,sheet = 'LibConfig'
		)
	)

	message('500. Reshape the KPI configuration')
	cfg_kpi <- cfg_kpi_pre[['KPIConfig']] %>%
		dplyr::mutate(
			!!rlang::sym('C_LIB_NAME') := !!rlang::sym('C_LIB_NAME') %>% tidyr::replace_na('')
		) %>%
		dplyr::left_join(
			cfg_kpi_pre[['LibConfig']]
			,by = 'C_LIB_NAME'
		) %>%
		dplyr::mutate(
			!!rlang::sym('F_KPI_INUSE') := !!rlang::sym('F_KPI_INUSE') %>% as.integer()
			,!!rlang::sym('N_LIB_PATH_SEQ') := !!rlang::sym('N_LIB_PATH_SEQ') %>% tidyr::replace_na(0) %>% as.integer()
			,!!rlang::sym('C_LIB_PATH') := !!rlang::sym('C_LIB_PATH') %>% tidyr::replace_na('')
		) %>%
		#800. Create fields that further facilitate the process in <AdvDB$DBuse_GetTimeSeriesForKpi>
		#[ASSUMPTION]
		#[1] We do not upcase the paths, to ensure the output files are in the same case as user defined
		dplyr::mutate(
			!!rlang::sym('C_KPI_FILE_NAME') := !!rlang::sym('C_KPI_FILE_NAME') %>% trimws()
			,!!rlang::sym('C_LIB_PATH') := !!rlang::sym('C_LIB_PATH') %>% tidyr::replace_na('') %>% trimws()
			,!!rlang::sym('C_KPI_FILE_TYPE') := !!rlang::sym('C_KPI_FILE_TYPE') %>% trimws()
			,!!rlang::sym('DF_NAME') := !!rlang::sym('DF_NAME') %>% tidyr::replace_na('dummy') %>% trimws()
			,!!rlang::sym('options') := !!rlang::sym('options') %>% tidyr::replace_na('list()')
		) %>%
		#900. Create fields that further facilitate the process in <AdvDB$aggrByPeriod>
		dplyr::mutate(
			!!rlang::sym('FileName') := !!rlang::sym('C_KPI_FILE_NAME')
			,!!rlang::sym('FilePath') := safe_path(!!rlang::sym('C_LIB_PATH'), !!rlang::sym('C_KPI_FILE_NAME'))
			,!!rlang::sym('PathSeq') := !!rlang::sym('N_LIB_PATH_SEQ')
		)

	message('999. Save the result to harddrive')
	if (!dir.exists(dirname(L_stpflnm1))) dir.create(dirname(L_stpflnm1), recursive = T)
	if (file.exists(L_stpflnm1)) rc <- file.remove(L_stpflnm1)
	rc <- dataIO[['R']]$push(
		modifyList(
			cfg_kpi_pre
			,list(
				'cfg_kpi' = cfg_kpi
			)
		)
		,outfile = L_stpflnm1
	)

	return(rc)
}

rc <- h_vfy_cfg()
