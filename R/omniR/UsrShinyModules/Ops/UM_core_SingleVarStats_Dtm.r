# User Defined Module: [Stats of the provided date/datetime variable in the provided data.frame]
# [Quote: https://www.stat.berkeley.edu/~s133/dates.html ]
# [Quote: https://www.r-bloggers.com/using-dates-and-times-in-r/ ]
# Details:
# [1]:[Count of Missing Values, with percentage]
# [2]:[# of unique dates and the corresponding % over the total number of days in the provided data]
# [3]:[Most frequent month (1 ~ 12), with its count and percentage]
# [4]:[Most frequent day (1 ~ 31), with its count and percentage]
# [4][1]:[Most frequent hour (if any), with its count and percentage]
# [5][1]:[Gini Coefficient (by month)]
# [5][2]:[Gini Coefficient (by day)]
# [6][1]:[Entropy (by month)]
# [6][2]:[Entropy (by day)]
# [p][1]:[Area chart showing the trend of frequency counts]
# [p][2]:[Heatmap by calendar, for the latest year as covered in the period]
# [p][3]:[Heatmap by calendar, for the second latest year as covered in the period if the latest one has not passed over a half]
# [p][4]:[Heatmap with [month] as x axis and [year] as y axis, for the entire period]
# [p][5]:[Heatmap with [date] as x axis and [month] as y axis, for the entire period]
# [p][6]:[Heatmap with [hour] as x axis and [weekday] as y axis, for the entire period (if any)]
# Required User-specified parameters:

# [Quote: "RV": User defined Reactive Values]
# [Quote: "uDiv": User defined Division on UI]
# [Quote: "uWg": User defined Widgets]
# [Quote: "urT": User defined renderTable]
# [Quote: "uEch": User defined ECharts]
# [Quote: "pT": User defined shinyWidgets::prettyToggle]
# [Quote: "pS": User defined shinyWidgets::prettySwitch]
# [Quote: "SI": User defined sliderInput]

# Required User-specified modules:
# [Quote:[omniR$UsrShinyModules$Ops$UM_divBookmarkWithModal.r]]

# Required User-specified functions:
# [Quote:[omniR$Styles$AdminLTE_colors.r]]

UM_core_SingleVarStats_Dtm_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	#Create a box as container of UI elements for the mainframe
	shiny::uiOutput(ns('svs_d_main'))
}

UM_core_SingleVarStats_Dtm_svr <- function(input,output,session,
	fDebug = FALSE,indat = NULL,invar = NULL,invartype = NULL,themecolorset = NULL){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
	#[Quote: https://stackoverflow.com/questions/4047188/unknown-timezone-name-in-r-strptime-as-posixct ]
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	uRV$module_dt_bgn <- Sys.time()
	uRV$module_dt_end <- NULL
	uRV$module_texts <- list()
	uRV$module_charts <- list(
		SUMM = list(
			NAME = paste0('Variable: [',invar,'] - Quick Summary'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'left: 42px;',
				'top: 5px;'
			)
		),
		AREA = list(
			NAME = paste0('Variable: [',invar,'] - Distribution along Dates'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'right: 90px;',
				'top: 5px;'
			)
		),
		BARPLOT = list(
			NAME = paste0('Variable: [',invar,'] - Distribution by Month'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'right: 25px;',
				'top: 0;'
			)
		),
		CLOCK = list(
			NAME = paste0('Variable: [',invar,'] - Frequency by Hours at AM/PM'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'right: 25px;',
				'top: 0;'
			)
		),
		CLNDR = list(
			NAME = paste0('Variable: [',invar,'] - Heat Map on Calendar (Most Recent Years)'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				# 'top: 0;',
				'right: 55px;'
			)
		),
		HEAT_YM = list(
			NAME = paste0('Variable: [',invar,'] - Heat Map of Year-Month'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				# 'top: 0;',
				'right: 55px;'
			)
		),
		HEAT_MD = list(
			NAME = paste0('Variable: [',invar,'] - Heat Map of Month-Day'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				# 'top: 0;',
				'right: 55px;'
			)
		),
		HEAT_WH = list(
			NAME = paste0('Variable: [',invar,'] - Heat Map of Weekday-Hour'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				# 'top: 0;',
				'right: 55px;'
			)
		)
	)
	if (lubridate::is.Date(indat[[invar]])){
		uRV$module_charts <- uRV$module_charts[-which(names(uRV$module_charts)=='CLOCK')]
		uRV$module_charts <- uRV$module_charts[-which(names(uRV$module_charts)=='HEAT_WH')]
	} else {
		uRV$module_charts <- uRV$module_charts[-which(names(uRV$module_charts)=='BARPLOT')]
	}
	uRV$module_charts_names <- names(uRV$module_charts)
	uRV$module_inputs <- list()
	uRV$ValidDat <- TRUE
	uRV$ValidVar <- TRUE
	uRV$VarType <- NULL
	uRV$ValidVarType <- TRUE
	uRV$ValidInType <- TRUE
	uRV$ValidRows <- TRUE
	#Below is the list of important stages to trigger the increment of initial progress bar
	uRV$pb_k <- list(
		#[1] Loading data
		load = 0,
		#[2] Drawing charts
		chart = length(uRV$module_charts)
	)
	uRV$pb_k_all <- length(uRV$pb_k)
	#We observe the status of the progress bar every 1sec, and destroy it after is it reaches the end
	uRV$k_ms_invld <- 1000
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- reactiveVal(0)
	if (is.null(indat) | is.null(invar)){
		uRV$ValidDat <- !is.null(indat)
		uRV$ValidVar <- !is.null(invar)
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	if (length(invar)>1){
		uRV$ValidVar <- FALSE
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	uRV$VarType <- ifelse(is.factor(indat[[invar]]),
		ifelse(is.character(levels(indat[[invar]])),
			'Character Factor',
			'Numeric Factor'
		),
		ifelse(is.character(indat[[invar]]),
			'Character',
			'Numeric'
		)
	)
	if (uRV$VarType != 'Numeric'){
		uRV$ValidVarType <- FALSE
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	uRV$VarClass <- class(indat[[invar]])
	if (!lubridate::is.Date(indat[[invar]]) && !lubridate::is.POSIXct(indat[[invar]])){
		uRV$ValidVarType <- FALSE
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	if (invartype != 'Dtm'){
		uRV$ValidInType <- FALSE
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	#[Quote: https://stackoverflow.com/questions/2851015/convert-data-frame-columns-from-factors-to-characters ]
	#[Quote: Character conversion:[fact_character <- levels(fact)[as.numeric(fact)]]]
	#[Quote: Numeric conversion:[num_num <- as.numeric(levels(num_fact)[as.numeric(num_fact)])]]
	if (nrow(indat) == 0){
		uRV$ValidRows <- FALSE
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns('[Module Call][UM_SingleVarStats_Dtm]'))
	}

	#010. Prepare mapping table of variables
	#011. Create the breaks to differentiate the font-colors as indicators
	uRV$ind_brks <- list(
		'% Mis.' = c(0,0.2,1),
		'% Inf' = c(0,0.2,1),
		'% Zero' = c(0,0.4,1),
		'Gini-M' = c(0,0.382,1),
		'Gini-D' = c(0,0.382,1),
		'Entropy-M' = c(-Inf,0.5,Inf),
		'Entropy-D' = c(-Inf,0.5,Inf),
		'HHI' = c(0,0.3,1)
	)
	uRV$ind_fontcolor <- list(
		'% Mis.' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'% Inf' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'% Zero' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'Gini-M' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'Gini-D' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'Entropy-M' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'Entropy-D' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'HHI' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d))
	)
	uRV$map_units <- c(kilo = 'K', million = 'M', billion = 'B', trillion = 'T', quintillion = 'Q')

	#015. Map the color scales if the [themecolor] is provided
	if (is.null(themecolorset)){
		uRV$chartitem_color <- AdminLTE_color_primary
		uRV$color_scale <- c('snow',AdminLTE_color_primary)
	} else {
		uRV$chartitem_color <- themecolorset$s08$p[[length(themecolorset$s08$p)]]
		uRV$color_scale <- themecolorset$s08$p
	}
	uRV$chartitem_rgb <- grDevices::col2rgb(uRV$chartitem_color)

	#020. Prepare the interim data.frame for processing
	#021. Subset the input data frame to shrink the memory consumption
	#The more general way to rename a variable is: [names(aa)[names(aa) == vv] <- "a_test"]
	#[Quote: https://stackoverflow.com/questions/7531868/how-to-rename-a-single-column-in-a-data-frame ]
	uRV$df_eval <- indat %>% dplyr::select_at(invar)

	#025. Create necessary fields splitting the original date/datetime values
	if (lubridate::is.Date(uRV$df_eval[[invar]])){
		uRV$df_chart <- uRV$df_eval %>%
			filter_at(invar,~!(is.na(.) | nchar(paste0(.))==0)) %>%
			mutate(
				ue_yymm = strftime(.[[invar]],format = '%Y-%m',tz = Sys.getenv('TZ')),
				ue_date = lubridate::date(.[[invar]]),
				ue_weekday = lubridate::wday(.[[invar]], label = TRUE, abbr = TRUE),
				ue_year = lubridate::year(.[[invar]]),
				ue_month = lubridate::month(.[[invar]]),
				ue_monthC = lubridate::month(.[[invar]], label = TRUE, abbr = TRUE),
				ue_day = lubridate::day(.[[invar]])
			)
	} else {
		uRV$df_chart <- uRV$df_eval %>%
			filter_at(invar,~!(is.na(.) | nchar(paste0(.))==0)) %>%
			mutate(
				ue_yymm = strftime(.[[invar]],format = '%Y-%m',tz = Sys.getenv('TZ')),
				ue_date = lubridate::date(.[[invar]]),
				ue_weekday = lubridate::wday(.[[invar]], label = TRUE, abbr = TRUE),
				ue_year = lubridate::year(.[[invar]]),
				ue_month = lubridate::month(.[[invar]]),
				ue_monthC = lubridate::month(.[[invar]], label = TRUE, abbr = TRUE),
				ue_day = lubridate::day(.[[invar]]),
				ue_hour = lubridate::hour(.[[invar]]),
				ue_minute = lubridate::minute(.[[invar]]),
				ue_second = lubridate::second(.[[invar]])
			)
	}
	#The entire [title] grid will take the height as 50px
	#We leave 30px from the top of the chart to its upper grid
	#We leave 30px from the bottom of the chart to the bottom of the HTML division
	uRV$height_exclchart <- 30 + 30
	uRV$height_heatYM <- max(220,100 + 30 * length(unique(uRV$df_chart$ue_year)))

	#027. Create the entire calendar from the first date to the last one in the given data

	#050. Calculate the significant stats
	#051. Unique date values
	uRV$kunique_dates <- length(unique(uRV$df_chart$ue_date))
	uRV$punique_dates <- uRV$kunique_dates / (as.integer(difftime(max(uRV$df_chart$ue_date),min(uRV$df_chart$ue_date),units = 'days')) + 1)
	#Count the unique dates in the latest year
	uRV$df_CY <- uRV$df_chart %>%
		filter(ue_year == max(uRV$df_chart$ue_year)) %>%
		group_by(ue_date) %>%
		count() %>%
		ungroup() %>%
		arrange(desc(n))
	uRV$kdates_in_CY <- nrow(uRV$df_CY)
	uRV$tmpdf_year <- uRV$df_chart %>%
		filter(ue_year != max(uRV$df_chart$ue_year))
	if (nrow(uRV$tmpdf_year) > 0){
		uRV$height_heatCY <- 320
		uRV$uemaxyr2_heat_cal <- max(uRV$tmpdf_year$ue_year)
	} else {
		uRV$height_heatCY <- 220
	}

	#052. Most frequent month (1 ~ 12)
	uRV$df_mmonth <- uRV$df_chart %>%
		group_by(ue_month) %>%
		count() %>%
		ungroup() %>%
		arrange(desc(n))
	uRV$freq_mmonth <- uRV$df_mmonth[1,'ue_month'] %>% unlist() %>% as.vector()
	uRV$nfreq_mmonth <- uRV$df_mmonth[1,'n'] %>% unlist() %>% as.vector()
	uRV$pfreq_mmonth <- uRV$nfreq_mmonth / nrow(uRV$df_eval)

	#053. Most frequent day (1 ~ 31)
	uRV$df_mday <- uRV$df_chart %>%
		group_by(ue_day) %>%
		count() %>%
		ungroup() %>%
		arrange(desc(n))
	uRV$freq_mday <- uRV$df_mday[1,'ue_day'] %>% unlist() %>% as.vector()
	uRV$nfreq_mday <- uRV$df_mday[1,'n'] %>% unlist() %>% as.vector()
	uRV$pfreq_mday <- uRV$nfreq_mday / nrow(uRV$df_eval)

	#054. Most frequent hour (if any)
	uRV$height_datearea <- 275
	if (!lubridate::is.Date(uRV$df_eval[[invar]])){
		uRV$df_mhour <- uRV$df_chart %>%
			group_by(ue_hour) %>%
			count() %>%
			ungroup() %>%
			arrange(desc(n))
		uRV$freq_mhour <- uRV$df_mhour[1,'ue_hour'] %>% unlist() %>% as.vector()
		uRV$nfreq_mhour <- uRV$df_mhour[1,'n'] %>% unlist() %>% as.vector()
		uRV$pfreq_mhour <- uRV$nfreq_mhour / nrow(uRV$df_eval)

		uRV$df_summ_mhour <- data.frame(
			Stats = c('Pop. Hour',' - #',' - %'),
			Values_C = c(
				formatC(uRV$freq_mhour,format = 'f',digits = 0,big.mark = ','),
				formatC(uRV$nfreq_mhour,format = 'f',digits = 0,big.mark = ','),
				paste0(formatC(100*uRV$pfreq_mhour,format = 'f',digits = 2),'%')
			),
			Values = c(
				uRV$freq_mhour,
				uRV$nfreq_mhour,
				uRV$pfreq_mhour
			),
			stringsAsFactors = FALSE
		)

		# uRV$height_datearea <- 275
	} else {
		uRV$df_summ_mhour <- NULL
	}

	#070. Prepare other stats
	#072. Missing Values
	uRV$nmiss <- uRV$df_eval %>% dplyr::filter_at(invar,~(is.na(.) | nchar(paste0(.))==0)) %>% count() %>% unlist() %>% as.vector()
	uRV$pmiss <- uRV$nmiss / nrow(uRV$df_eval)

	#075. Inequality and Concentration
	#Gini Coefficient
	uRV$gini_month <- ineq::Gini(uRV$df_mmonth[['n']])
	uRV$gini_day <- ineq::Gini(uRV$df_mday[['n']])
	#Entropy
	uRV$entropy_month <- ineq::entropy(uRV$df_mmonth[['n']])
	uRV$entropy_day <- ineq::entropy(uRV$df_mday[['n']])
	uRV$df_summ_ineq <- data.frame(
		Stats = c('Gini-M','Gini-D','Entropy-M','Entropy-D'),
		Values_C = c(
			formatC(uRV$gini_month,format = 'f',digits = 2),
			formatC(uRV$gini_day,format = 'f',digits = 2),
			formatC(uRV$entropy_month,format = 'f',digits = 2),
			formatC(uRV$entropy_day,format = 'f',digits = 2)
		),
		Values = c(
			uRV$gini_month,
			uRV$gini_day,
			uRV$entropy_month,
			uRV$entropy_day
		),
		stringsAsFactors = FALSE
	)
	#Debug Mode
	if (fDebug){
		message(
			'kdates_in_CY:[',formatC(uRV$kdates_in_CY,format = 'f',digits = 0,big.mark = ','),']',
			'nmiss:[',formatC(uRV$nmiss,format = 'f',digits = 0,big.mark = ','),']',
			'pmiss:[',paste0(formatC(100*uRV$pmiss,format = 'f',digits = 2),'%'),']',
			'kunique_dates:[',formatC(uRV$kunique_dates,format = 'f',digits = 0,big.mark = ','),']',
			'punique_dates:[',paste0(formatC(100*uRV$punique_dates,format = 'f',digits = 2),'%'),']',
			'freq_mmonth:[',formatC(uRV$freq_mmonth,format = 'f',digits = 0,big.mark = ','),']',
			'nfreq_mmonth:[',formatC(uRV$nfreq_mmonth,format = 'f',digits = 0,big.mark = ','),']',
			'pfreq_mmonth:[',paste0(formatC(100*uRV$pfreq_mmonth,format = 'f',digits = 2),'%'),']',
			'freq_mday:[',formatC(uRV$freq_mday,format = 'f',digits = 0,big.mark = ','),']',
			'nfreq_mday:[',formatC(uRV$nfreq_mday,format = 'f',digits = 0,big.mark = ','),']',
			'pfreq_mday:[',paste0(formatC(100*uRV$pfreq_mday,format = 'f',digits = 2),'%'),']',
			'gini_month:[',formatC(uRV$gini_month,format = 'f',digits = 2),']',
			'gini_day:[',formatC(uRV$gini_day,format = 'f',digits = 2),']',
			'entropy_month:[',formatC(uRV$entropy_month,format = 'f',digits = 2),']',
			'entropy_day:[',formatC(uRV$entropy_day,format = 'f',digits = 2),']'
		)
		if (!lubridate::is.Date(uRV$df_eval[[invar]])){
			glimpse(uRV$df_summ_mhour)
			message(
				'freq_mhour:[',formatC(uRV$freq_mhour,format = 'f',digits = 0,big.mark = ','),']',
				'nfreq_mhour:[',formatC(uRV$nfreq_mhour,format = 'f',digits = 0,big.mark = ','),']',
				'pfreq_mhour:[',paste0(formatC(100*uRV$pfreq_mhour,format = 'f',digits = 2),'%'),']'
			)
		}
	}

	#090. Combine the stats to the summary table
	uRV$TblSummary <- data.frame(
		Stats = c('# Mis.','% Mis.','# Uni. Dates','- % of Period','Pop. Month',' - #',' - %','Pop. Day',' - #',' - %'),
		Values_C = c(
			formatC(uRV$nmiss,format = 'f',digits = 0,big.mark = ','),
			paste0(formatC(100*uRV$pmiss,format = 'f',digits = 2),'%'),
			formatC(uRV$kunique_dates,format = 'f',digits = 0,big.mark = ','),
			paste0(formatC(100*uRV$punique_dates,format = 'f',digits = 2),'%'),
			formatC(uRV$freq_mmonth,format = 'f',digits = 0,big.mark = ','),
			formatC(uRV$nfreq_mmonth,format = 'f',digits = 0,big.mark = ','),
			paste0(formatC(100*uRV$pfreq_mmonth,format = 'f',digits = 2),'%'),
			formatC(uRV$freq_mday,format = 'f',digits = 0,big.mark = ','),
			formatC(uRV$nfreq_mday,format = 'f',digits = 0,big.mark = ','),
			paste0(formatC(100*uRV$pfreq_mday,format = 'f',digits = 2),'%')
		),
		Values = c(
			uRV$nmiss,
			uRV$pmiss,
			uRV$kunique_dates,
			uRV$punique_dates,
			uRV$freq_mmonth,
			uRV$nfreq_mmonth,
			uRV$pfreq_mmonth,
			uRV$freq_mday,
			uRV$nfreq_mday,
			uRV$pfreq_mday
		),
		stringsAsFactors = FALSE
	)
	if (!is.null(uRV$df_summ_mhour)){
		uRV$TblSummary <- dplyr::bind_rows(uRV$TblSummary,uRV$df_summ_mhour)
	}
	if (!is.null(uRV$df_summ_ineq)){
		uRV$TblSummary <- dplyr::bind_rows(uRV$TblSummary,uRV$df_summ_ineq)
	}
	uRV$TblSummary_nrow <- nrow(uRV$TblSummary)
	#Debug Mode
	if (fDebug){
		glimpse(uRV$TblSummary)
	}

	#095. Prepare the specific font color for the dedicated stats values
	#[Quote: https://stackoverflow.com/questions/39240545/map-value-based-on-specified-intervals ]
	uRV$ind_vals_color <- sapply(
		names(uRV$ind_brks),
		function(x){
			if (!(x %in% uRV$TblSummary$Stats)) return(NULL)
			if (is.na(filter(uRV$TblSummary,Stats == x)$Values)) return(NULL)
			tmpInterval <- filter(uRV$TblSummary,Stats == x)$Values %>%
				as.vector() %>%
				Hmisc::cut2(cuts = uRV$ind_brks[[x]])
			return(uRV$ind_fontcolor[[x]][[as.numeric(tmpInterval)]])
		}
	)
	# message(uRV$ind_vals_color)

	#200. General settings of styles for the output charts
	#201. Prepare the styles for the buttons
	uRV$btn_styles <- paste0(
		'text-align: center;',
		'color: ',uRV$chartitem_color,';',
		'padding: 0;',
		'margin: 0;',
		#Refer to documents of [echarts4r]
		'font-size: 15px;',
		'border: none;',
		'background-color: rgba(0,0,0,0);'
	)

	#205. Prepare the styles for the bookmarks
	uRV$btn_styles_BM <- paste0(
		uRV$btn_styles,
		'font-size: 13px;'
	)

	#228. Grids for the major charts
	#[x : basic charts]
	#[h : heat maps]
	uRV$grid_x <- list(index = 0, top = '30px', right = '25px', bottom = '30px', left = '30px')
	uRV$grid_h <- list(index = 0, top = '30px', right = '80px', bottom = '30px', left = '45px')

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			'.svs_d_fluidRow {padding: 2px 15px 2px 15px;}',
			'.svs_d_Column {',
				'padding: 0px;',
				# 'height: 34px;',
				'vertical-align: middle;',
			'}'
		)
	)

	#300. Define internal functions
	#310. Define function to draw the clock chart
	genClock <- function(df_in,AMPM){
		#800. Create the chart object
		rst <- df_in %>%
			#The [height] option inside [e_charts] function only affects the [canvas] itself (e.g. for printing),
			# while has no effect upon the dynamic UI rendered by [echarts4r::echarts4rOutput]
			echarts4r::e_charts(x,height = 350) %>%
			echarts4r::e_polar() %>%
			echarts4r::e_angle_axis(
				x,
				polarIndex = 0,
				min = 'dataMin',
				max = 'dataMax',
				startAngle = 105,
				axisPointer = list(
					show = TRUE,
					label = list(
						formatter = htmlwidgets::JS(paste0(
							"function(params){",
								"return(",
									"params.value + ':00'",
								");",
							"}"
						))
					)
				),
				axisTick = list(
					show = TRUE,
					alignWithLabel = TRUE
				),
				axisLine = list(
					show = TRUE
				),
				axisLabel = list(
					show = TRUE
				),
				splitLine = list(
					show = TRUE,
					lineStyle = list(
						type = 'dashed'
					)
				)
			) %>%
			echarts4r::e_radius_axis(
				k_rec,
				polarIndex = 0,
				type = 'value',
				min = 0,
				max = uRV$clock_y_max,
				axisTick = list(
					show = FALSE
				),
				axisLine = list(
					show = FALSE
				),
				axisLabel = list(
					show = TRUE,
					margin = -12,
					showMaxLabel = NULL,
					formatter = htmlwidgets::JS(paste0(
						"function(value, index){",
							"return(",
								"(value/",1000^uRV$logK_x0_whole,").toFixed(",uRV$nfrac_x0,") + '",uRV$str_unit_x0,"'",
							");",
						"}"
					))
				),
				splitLine = list(
					show = TRUE,
					lineStyle = list(
						type = 'dashed'
					)
				)
			) %>%
			echarts4r::e_area(
				k_rec,
				name = '# Freq.',
				coord_system = 'polar',
				smooth = FALSE,
				#Below color represent [primary] in the default theme
				color = uRV$chartitem_color,
				tooltip = list(
					formatter = htmlwidgets::JS(paste0(
						"function(params){",
							"return(",
								"'<strong># Freq.</strong><br/>'",
								"+ '<i>[' + (params.dataIndex + ",ifelse(AMPM=='AM',0,12),") + ':00]</i>'",
								"+ ' : ' + echarts.format.addCommas(parseFloat(params.value).toFixed())",
							");",
						"}"
					))
				),
				polarIndex = 0
			) %>%
			echarts4r::e_legend(FALSE) %>%
			echarts4r::e_tooltip(
				trigger = 'item',
				axisPointer = list(
					type = 'cross'
				)
			) %>%
			echarts4r::e_title(
				paste0('# Freq. @ ',AMPM),
				left = 20,
				top = 2,
				textStyle=list(
					fontSize = 15
				)
			) %>%
			echarts4r::e_show_loading()

		#999. Output
		return(rst)
	}

	#500. Create the base for charting based on user interaction

	#580. Allow user to add bookmarks to all charts
	#581. Initialize the reactive values
	uRV$bmwm <- list()
	uRV$k_act <- list()
	for (i in seq_along(uRV$module_charts_names)){
		uRV$k_act[[i]] <- 0
		uRV$bmwm[[i]] <- shiny::reactiveValues(
			CallCounter = shiny::reactiveVal(0),
			ActionDone = shiny::reactive({FALSE}),
			EnvVariables = shiny::reactive({NULL})
		)
	}

	#585. Save the content of the bookmarks and the entire report at the same time once ready
	sapply(seq_along(uRV$module_charts_names), function(i){
		#100. Call module
		#There is no need to [observe] the call of this module, for the parent module is always called within
		# an [observe] environment.
		#IMPORTANT!!! It is tested that if we put this call inside an [observe] clause, it will be stuck in an infinite loop.
		#IMPORTANT!!! It is tested that if we put this call inside a [for] loop, the [style] will only be applied by the last one among the list.
		uRV$bmwm[[i]] <- shiny::callModule(
			UM_divBookmarkWithModal_svr,
			paste0('bmwm',i),
			fDebug = fDebug,
			text_in = NULL,
			themecolorset = myApp_themecolorset,
			btn_styles = uRV$btn_styles_BM,
			#Below [style] is for how to place the bookmark into its parent [div]
			style = uRV$module_charts[[i]]$BM_style
		)

		#500. Monitor user action once a bookmark is added/updated
		shiny::observeEvent(uRV$bmwm[[i]]$CallCounter(),
			{
				#100. Take dependencies
				#We only take one input to avoid the case when the values of slider input triggers twice at the same time.
				uRV$bmwm[[i]]$CallCounter()

				#900. Execute below block of codes only once upon the change of any one of above dependencies
				shiny::isolate({
					#Debug Mode
					if (fDebug){
						message(ns(paste0('[585][500][',i,'][observe][IN][uRV$bmwm[[',i,']]$CallCounter()]:',uRV$bmwm[[i]]$CallCounter())))
					}
					#010. Return if the condition is not valid
					if (is.null(uRV$bmwm[[i]]$CallCounter())) return()
					if (uRV$bmwm[[i]]$CallCounter() == 0) return()

					#300. Update the user action
					if (is.null(uRV$k_act[[i]])) uRV$k_act[[i]] <- uRV$bmwm[[i]]$CallCounter()
					else {
						if (uRV$k_act[[i]] == uRV$bmwm[[i]]$CallCounter()) return()
						else uRV$k_act[[i]] <- uRV$k_act[[i]] + 1
					}
				#End of [isolate]
				})
			}
			,label = ns(paste0('[585][500][',i,']Save the output once a bookmark is added/updated'))
		)

		#700. Save the output once a bookmark is added/updated
		shiny::observe(
			{
				#100. Take dependencies
				#We only take one input to avoid the case when the values of slider input triggers twice at the same time.
				uRV$k_act[[i]]

				#900. Execute below block of codes only once upon the change of any one of above dependencies
				shiny::isolate({
					#Debug Mode
					if (fDebug){
						message(ns(paste0('[585][700][',i,'][observe][IN][uRV$k_act[[',i,']]]:',uRV$k_act[[i]])))
					}
					#010. Return if the condition is not valid
					if (is.null(uRV$k_act[[i]])) return()
					if (uRV$k_act[[i]] == 0) return()

					#300. Retrieve the content of the bookmark
					uRV$module_charts[[i]]$TXT <- uRV$bmwm[[i]]$EnvVariables()$text_out

					#800. Simulate the action of [click] upon the [save] button
					shinyjs::click('uWg_AB_Save')
				#End of [isolate]
				})
			}
			,label = ns(paste0('[585][700][',i,']Save the output once a bookmark is added/updated'))
		)
	})

	#595. Increment the progress when necessary
	#[Quote: https://stackoverflow.com/questions/44367004/r-shiny-destroy-observeevent ]
	#We suspend the observer once the progress bar is closed
	pb_obs_chart <- shiny::observe({
		if (is.null(uRV$pb_chart)) return()
		#Close the progress bar as long as its value reaches 100%
		shiny::invalidateLater(uRV$k_ms_invld,session)
		if (is.null(uRV$pb_chart$getValue())) return()
		if (uRV$pb_chart$getValue() >= uRV$pb_chart$getMax()) {
			uRV$pb_chart$close()
			pb_obs_chart$suspend()
		}
	})

	#700. Prepare dynamic UIs
	#701. Prepare the primary UI

	#707. Mainframe
	output$svs_d_main <- shiny::renderUI({
		#Create a box as container of UI elements for the entire module
		shiny::tagList(
			#Set the overall control of the [fluidRow] in this module
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),
			shiny::fluidRow(
				class = 'svs_d_fluidRow',
				shiny::column(width = 3,
					class = 'svs_d_Column',
					#Display a table showing special values of the provided variable.
					shiny::div(
						style = 'text-align: center',
						UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='SUMM')))),
						DT::DTOutput(ns('urT_Summary'))
					#End of [div]
					)
				#End of [column]
				),

				shiny::column(width = 9,
					class = 'svs_d_Column',
					shiny::fillCol(
						flex = c(NA,NA),
						#Add box for Area Chart
						shiny::tags$div(
							#Add the button to save current charts as report
							shiny::tags$div(
								style = paste0(
									'z-index: 1;',
									'position: absolute;',
									'right: 60px;',
									'top: 4px;'
								),
								shiny::actionButton(ns('uWg_AB_Save'), NULL,
									style = uRV$btn_styles,
									icon = shiny::icon('download')
								),
								tippy::tippy_this(
									ns('uWg_AB_Save'),
									'Save Report',
									placement = 'top',
									distance = 2,
									arrow = FALSE,
									multiple = TRUE
								)
							#End of [div]
							),
							UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='AREA')))),
							echarts4r::echarts4rOutput(ns('uEch_Date_Area'),height = uRV$height_datearea)
						#End of [div]
						),
						#Add box for Distribution Bar Chart
						shiny::uiOutput(ns('ui_Single_Dist'))
					)
				#End of [column]
				)
			#End of [fluidRow]
			),
			shiny::fluidRow(
				class = 'svs_d_fluidRow',
				shiny::tags$div(
					UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='CLNDR')))),
					#Heatmap by calendar, for the latest year as covered in the period
					echarts4r::echarts4rOutput(ns('uEch_Heat_Cal'),height = uRV$height_heatCY)
				)
			#End of [fluidRow]
			),
			shiny::fluidRow(
				class = 'svs_d_fluidRow',
				shiny::tags$div(
					UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='HEAT_YM')))),
					#Heatmap with [month] as x axis and [year] as y axis, for the entire period
					echarts4r::echarts4rOutput(ns('uEch_Heat_Y_M'),height = uRV$height_heatYM)
				)
			#End of [fluidRow]
			),
			shiny::fluidRow(
				class = 'svs_d_fluidRow',
				shiny::tags$div(
					UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='HEAT_MD')))),
					#Heatmap with [date] as x axis and [month] as y axis, for the entire period
					echarts4r::echarts4rOutput(ns('uEch_Heat_M_D'),height = 300)
				)
			#End of [fluidRow]
			),
			shiny::uiOutput(ns('uDiv_Heat_W_H'))
		#End of [tagList]
		)
	#End of [renderUI] of [105]
	})

	#710. Diaplay the stats table for the provided variable
	#711. Create the object
	#[Quote: https://datascience-enthusiast.com/R/Modals_data_exploration_Shiny.html ]
	uRV$TblSummary_DT <- DT::datatable(
		uRV$TblSummary,
		# rownames = FALSE,
		width = '100%',
		class = 'compact hover stripe nowrap',
		selection = list(
			mode = 'single',
			target = 'row'
		),
		#[Quote: https://rstudio.github.io/DT/options.html ]
		#[Quote: https://rstudio.github.io/DT/010-style.html ]
		options = list(
			#We have to set the [stateSave=F], otherwise the table cannot be displayed completely!!
			stateSave = FALSE,
			scrollX = TRUE,
			#[Show N entries] on top left
			pageLength = uRV$TblSummary_nrow,
			#Only display the table
			dom = 't',
			columnDefs = list(
				list(
					#Suppress display of the row names
					#It is weird that the setting [rownames=FALSE] cannot take effect
					targets = 0,
					visible = FALSE
				),
				list(
					#Left-align the text columns
					targets = 1,
					className = 'dt-left'
				),
				list(
					#Right-align the numeric-like columns
					targets = 2,
					className = 'dt-right'
				),
				list(
					#Suppress display of the actual values
					targets = 3,
					visible = FALSE
				)
			)
		#End of [options]
		)
	#End of [datatable]
	) %>%
		#Set the font color for specific stats, indicating warnings
		DT::formatStyle(
			'Values_C',
			valueColumns = 'Stats',
			target = 'cell',
			color = styleEqual(
				names(uRV$ind_brks),
				uRV$ind_vals_color
			)
		)

	#719. Render the UI
	output$urT_Summary <- DT::renderDT({
		#008. Create a progress bar to notify the user when a large dataset is being loaded for chart drawing
		uRV$pb_chart <- shiny::Progress$new(session, min = 0, max = uRV$pb_k$chart)

		#009. Start to display the progress bar
		uRV$pb_chart$set(message = paste0(invar,' [2/',uRV$pb_k_all,']'), value = 0)
		pb_obs_chart$resume()

		#Take dependency from below action (without using its value):

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[719][renderDT][IN][output$urT_Summary]:')))
		}

		#Increment the progress bar
		#[Quote: https://nathaneastwood.github.io/2017/08/13/accessing-private-methods-from-an-r6-class/ ]
		#[Quote: https://github.com/rstudio/shiny/blob/master/R/progress.R ]
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: DataTable'))
		}

		#Render UI
		uRV$TblSummary_DT
	#End of [renderDataTable] of [719]
	})

	#750. Diaplay the charts adjacent to the data table
	#[Quote:[echarts4r][ https://echarts4r.john-coene.com/index.html ]]
	#751. Render the Area Chart for the entire period
	uRV$ue_area <- uRV$df_chart %>%
		group_by(ue_date) %>%
		count() %>%
		ungroup() %>%
		mutate(ue_year = lubridate::year(ue_date)) %>%
		# group_by(ue_year) %>%
		# arrange(ue_date) %>%
		echarts4r::e_charts(ue_date,timeline = FALSE,height = uRV$height_datearea) %>%
		echarts4r::e_area(
			n,
			name = '# Freq.',
			#Below color represent [primary] in the default theme
			color = uRV$chartitem_color
		) %>%
		echarts4r::e_mark_point(
			data = list(
				name = 'Max',
				type = 'max'
			),
			itemStyle = list(
				#Below color represent [primary] in the default theme
				color = uRV$chartitem_color
			)
		) %>%
		echarts4r::e_mark_point(
			data = list(
				name = 'Min',
				type = 'min'
			),
			#Below color represent [danger] in the default theme
			itemStyle = list(
				#Below color represent [danger] in the default theme
				color = ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)
			)
		) %>%
		echarts4r::e_mark_line(
			data = list(
				name = 'Avg',
				type = 'average'
			)
		) %>%
		echarts4r::e_y_axis(
			axisLabel = list(
				rotate = 90
			),
			splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			)
		) %>%
		echarts4r::e_legend(FALSE) %>%
		# echarts4r::e_flip_coords() %>%
		echarts4r::e_tooltip(
			trigger = 'item',
			axisPointer = list(
				type = 'cross'
			)
		) %>%
		echarts4r::e_toolbox() %>%
		# echarts4r::e_toolbox_feature(
		# 	feature = 'magicType',
		# 	type = list('area','line')
		# ) %>%
		echarts4r::e_toolbox_feature(feature = 'dataZoom') %>%
		echarts4r::e_title(
			'Frequency Trend',
			left = 20,
			top = 2,
			textStyle=list(
				fontSize = 15
			)
		) %>%
		echarts4r::e_show_loading()
	uRV$ue_area <- do.call(echarts4r::e_grid,
		append(
			list(e = uRV$ue_area),
			append(
				uRV$grid_x,
				list(height = paste0(uRV$height_datearea - uRV$height_exclchart,'px'))
			)
		)
	)
	output$uEch_Date_Area <- echarts4r::renderEcharts4r({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[751][renderEcharts4r][IN][output$uEch_Date_Area]:')))
		}
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Trend'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_area
	})

	#752. Render the Distribution Bar Chart by single axis
	#Construct a data frame of all 12 months in a year, or all 24 hours in a day
	if (lubridate::is.Date(uRV$df_eval[[invar]])){
		uRV$uedf_bar_s_d_base <- data.frame(
			tmpdate = seq.Date(
				from = as.Date('2016-01-01'),
				to = as.Date('2016-12-01'),
				by = 'months'
			)
		) %>%
			mutate(
				ue_month = lubridate::month(tmpdate)
			) %>%
			select(-starts_with('tmp'))
		uRV$uedf_bar_s_d <- uRV$df_chart %>%
			mutate(f_rec = 1) %>%
			right_join(uRV$uedf_bar_s_d_base,by = c('ue_month')) %>%
			group_by(ue_month) %>%
			summarise(k_rec = sum(f_rec)) %>%
			ungroup()
		names(uRV$uedf_bar_s_d)[names(uRV$uedf_bar_s_d) == 'ue_month'] <- 'x'
		uRV$uemin_bar_s_d <- 0
		uRV$uemax_bar_s_d <- 13

		uRV$ue_bar_s_d <- uRV$uedf_bar_s_d %>%
			echarts4r::e_charts(x,timeline = FALSE,height = uRV$height_datearea) %>%
			echarts4r::e_bar(
				k_rec,
				name = '# Freq.',
				#Below color represent [primary] in the default theme
				color = uRV$chartitem_color
			) %>%
			echarts4r::e_legend(FALSE) %>%
			echarts4r::e_x_axis(
				min = uRV$uemin_bar_s_d,
				max = uRV$uemax_bar_s_d,
				splitLine = list(
					lineStyle = list(
						type = 'dashed'
					)
				)
			) %>%
			echarts4r::e_y_axis(
				axisLabel = list(
					rotate = 90
				),
				splitLine = list(
					lineStyle = list(
						type = 'dashed'
					)
				)
			) %>%
			echarts4r::e_tooltip(
				trigger = 'item',
				axisPointer = list(
					type = 'cross'
				)
			) %>%
			# echarts4r::e_x_axis(
			# 	axisTick = list(
			# 		alignWithLabel = TRUE
			# 	)
			# ) %>%
			# echarts4r::e_toolbox() %>%
			# echarts4r::e_toolbox_feature(feature = 'dataZoom') %>%
			echarts4r::e_title(
				paste('Frequency Distribution by month'),
				left = 20,
				top = 2,
				textStyle=list(
					fontSize = 15
				)
			) %>%
			echarts4r::e_show_loading()

		uRV$ue_bar_s_d <- do.call(echarts4r::e_grid,
			append(
				list(e = uRV$ue_bar_s_d),
				append(
					uRV$grid_x,
					list(height = paste0(uRV$height_datearea - uRV$height_exclchart,'px'))
				)
			)
		)
		output$uEch_Single_Dist <- echarts4r::renderEcharts4r({
			#We pass a list here to sanitize the program
			uRV$ue_bar_s_d
		})
	} else {
		uRV$uedf_bar_s_d_base <- data.frame(
			tmpdate = seq.POSIXt(
				from = strptime('20160101 00:00:00',format = '%Y%m%d %H:%M:%S'),
				to = strptime('20160101 23:59:59',format = '%Y%m%d %H:%M:%S'),
				by = 'hours'
			)
		) %>%
			mutate(
				ue_hour = lubridate::hour(tmpdate)
			) %>%
			select(-starts_with('tmp'))
		uRV$uedf_bar_s_d <- uRV$df_chart %>%
			mutate(f_rec = 1) %>%
			right_join(uRV$uedf_bar_s_d_base,by = c('ue_hour')) %>%
			group_by(ue_hour) %>%
			summarise(k_rec = sum(f_rec)) %>%
			ungroup()
		names(uRV$uedf_bar_s_d)[names(uRV$uedf_bar_s_d) == 'ue_hour'] <- 'x'

		#Unify the radius axes
		#Since the input of function [scaleNum] is a single-element vector, its output [$values] is of the same shape.
		#[Quote:[omniR$AdvOp$scaleNum.r]]
		uRV$max_x0 <- max(uRV$uedf_bar_s_d$k_rec,na.rm = TRUE)
		uRV$logK_x0 <- log(uRV$max_x0,base = 1000)
		numfmt_x0 <- scaleNum(uRV$max_x0,1000,map_units=uRV$map_units)
		uRV$logK_x0_whole <- numfmt_x0$parts$k_exp %>% unlist()
		uRV$nfrac_x0 <- numfmt_x0$parts$k_dec %>% unlist()
		uRV$str_unit_x0 <- numfmt_x0$parts$c_sfx %>% unlist()
		uRV$clock_y_max <- ceiling(1000^(ceiling(uRV$logK_x0*100)/100))

		#Generate the clock chart for AM
		uRV$uedf_clock_s_d_am <- uRV$uedf_bar_s_d %>% filter(x < 12)
		uRV$ue_clock_s_d_am <- genClock(uRV$uedf_clock_s_d_am,'AM')
		uRV$ue_clock_s_d_am <- do.call(echarts4r::e_grid,
			append(
				list(e = uRV$ue_clock_s_d_am),
				append(
					uRV$grid_x,
					list(height = paste0(uRV$height_datearea - uRV$height_exclchart,'px'))
				)
			)
		)
		output$uEch_Clock_AM <- echarts4r::renderEcharts4r({
			#We pass a list here to sanitize the program
			uRV$ue_clock_s_d_am
		})

		#Generate the clock chart for AM
		uRV$uedf_clock_s_d_pm <- uRV$uedf_bar_s_d %>% filter(x >= 12)
		uRV$ue_clock_s_d_pm <- genClock(uRV$uedf_clock_s_d_pm,'PM')
		uRV$ue_clock_s_d_pm <- do.call(echarts4r::e_grid,
			append(
				list(e = uRV$ue_clock_s_d_pm),
				append(
					uRV$grid_x,
					list(height = paste0(uRV$height_datearea - uRV$height_exclchart,'px'))
				)
			)
		)
		output$uEch_Clock_PM <- echarts4r::renderEcharts4r({
			#We pass a list here to sanitize the program
			uRV$ue_clock_s_d_pm
		})
	}

	#Prepare the HTML elements
	output$ui_Single_Dist <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[752][renderUI][IN][output$ui_Single_Dist]:')))
		}
		if (lubridate::is.Date(uRV$df_eval[[invar]])){
			#Increment the progress bar
			if (!uRV$pb_chart$.__enclos_env__$private$closed){
				val <- uRV$pb_chart$getValue()+1
				uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Distribution by Month'))
			}

			return(
				shiny::tags$div(
					UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='BARPLOT')))),
					echarts4r::echarts4rOutput(ns('uEch_Single_Dist'),height = uRV$height_datearea)
				)
			)
		} else {
			#Increment the progress bar
			if (!uRV$pb_chart$.__enclos_env__$private$closed){
				val <- uRV$pb_chart$getValue()+1
				uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Clocks'))
			}

			return(
				shiny::tags$div(
					UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='CLOCK')))),
					shiny::column(width = 6,
						class = 'svs_d_Column',
						echarts4r::echarts4rOutput(ns('uEch_Clock_AM'),height = uRV$height_datearea)
					),
					shiny::column(width = 6,
						class = 'svs_d_Column',
						echarts4r::echarts4rOutput(ns('uEch_Clock_PM'),height = uRV$height_datearea)
					)
				)
			)
		}
	})

	#760. Display the charts below the data table
	#761. Heatmap by calendar, for the latest year as covered in the period
	#[Quote: https://echarts.apache.org/zh/option.html#calendar ]
	#Render the map for the latest year
	uRV$uedf_heat_cal <- uRV$df_chart %>%
		group_by(ue_year,ue_date) %>%
		count(name = 'k_rec') %>%
		ungroup()
	# glimpse(uRV$uedf_heat_cal)
	uRV$uemaxyr_heat_cal <- max(uRV$uedf_heat_cal$ue_year)
	uRV$ue_heat_cal <- uRV$uedf_heat_cal %>%
		group_by(ue_year) %>%
		# arrange(ue_date) %>%
		echarts4r::e_charts(ue_date,height = uRV$height_heatCY)

	#Determine how many charts to be shown
	#[IMPORTANT!!!] This part should be ahead of the [echarts4r::e_heatmap] part!
	if (nrow(uRV$tmpdf_year) > 0){
		uRV$uemin_heat_cal <- uRV$uedf_heat_cal %>%
			filter(ue_year >= uRV$uemaxyr2_heat_cal , !is.na(k_rec) , !is.infinite(k_rec)) %>%
			select(k_rec) %>%
			min()
		uRV$uemax_heat_cal <- uRV$uedf_heat_cal %>%
			filter(ue_year >= uRV$uemaxyr2_heat_cal , !is.na(k_rec) , !is.infinite(k_rec)) %>%
			select(k_rec) %>%
			max()
		#[IMPORTANT!!!] Sequence of the scripts regarding the years cannot be reversed! Otherwise the chart fails to render!
		uRV$ue_heat_cal <- uRV$ue_heat_cal %>%
			#Place the calendar of the second most recent year below the most recent one
			echarts4r::e_calendar(
				range = uRV$uemaxyr2_heat_cal,
				top = 200,
				left = 50,
				right = 80,
				cellSize = c('auto','15'),
				orient = 'horizontal'
			) %>%
			#Place the calendar of the most recent year on top
			echarts4r::e_calendar(
				range = uRV$uemaxyr_heat_cal,
				left = 50,
				right = 80,
				cellSize = c('auto','15'),
				orient = 'horizontal'
			) %>%
			echarts4r::e_heatmap(
				k_rec,
				name = '# Freq.',
				#Below is to ensure the first heatmap on the calendar is properly rendered
				calendarIndex = 0,
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				),
				coord_system = 'calendar'
			) %>%
			echarts4r::e_heatmap(
				k_rec,
				name = '# Freq.',
				#Below is to ensure the second heatmap on the calendar is properly rendered
				calendarIndex = 1,
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				),
				coord_system = 'calendar'
			)
	} else {
		uRV$uemin_heat_cal <- uRV$uedf_heat_cal %>%
			filter(ue_year >= uRV$uemaxyr_heat_cal , !is.na(k_rec) , !is.infinite(k_rec)) %>%
			select(k_rec) %>%
			min()
		uRV$uemax_heat_cal <- uRV$uedf_heat_cal %>%
			filter(ue_year >= uRV$uemaxyr_heat_cal , !is.na(k_rec) , !is.infinite(k_rec)) %>%
			select(k_rec) %>%
			max()
		uRV$ue_heat_cal <- uRV$ue_heat_cal %>%
			echarts4r::e_calendar(
				range = uRV$uemaxyr_heat_cal,
				left = 50,
				right = 80,
				cellSize = c('auto','15'),
				orient = 'horizontal'
			) %>%
			echarts4r::e_heatmap(
				k_rec,
				name = '# Freq.',
				calendarIndex = 0,
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				),
				coord_system = 'calendar'
			)
	}

	#Complete the components
	uRV$ue_heat_cal <- uRV$ue_heat_cal %>%
		echarts4r::e_visual_map(
			min = uRV$uemin_heat_cal,
			max = uRV$uemax_heat_cal,
			inRange = list(
				color = uRV$color_scale
			),
			orient = 'vertical',
			right = 2,
			top = 25
		) %>%
		echarts4r::e_tooltip(trigger = 'item') %>%
		echarts4r::e_title(
			'Heatmap for the latest year(s)',
			left = 20,
			top = 2,
			textStyle=list(
				fontSize = 15
			)
		) %>%
		echarts4r::e_show_loading()

	#Render the UI
	uRV$ue_heat_cal <- do.call(echarts4r::e_grid,
		append(
			list(e = uRV$ue_heat_cal),
			append(
				uRV$grid_h,
				list(height = paste0(uRV$height_heatCY - uRV$height_exclchart,'px'))
			)
		)
	)
	output$uEch_Heat_Cal <- echarts4r::renderEcharts4r({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[761][renderEcharts4r][IN][output$uEch_Heat_Cal]:')))
		}
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Calendar Heat Map'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_heat_cal
	})

	#762. Heatmap with [month] as x axis and [year] as y axis, for the entire period
	#[Quote: https://echarts.apache.org/zh/option.html#series-heatmap ]
	#Construct a data frame of all 12 months in a year
	uRV$uedf_heat_y_m_base <- data.frame(
		tmpdate = seq.Date(
			from = as.Date(paste0(min(uRV$df_chart$ue_year),'-01-01')),
			to = as.Date(paste0(max(uRV$df_chart$ue_year),'-12-01')),
			by = 'months'
		)
	) %>%
		mutate(
			ue_year = lubridate::year(tmpdate),
			ue_month = lubridate::month(tmpdate)
		) %>%
		select(-starts_with('tmp'))
	uRV$uedf_heat_y_m <- uRV$df_chart %>%
		mutate(f_rec = 1) %>%
		right_join(uRV$uedf_heat_y_m_base,by = c('ue_year','ue_month')) %>%
		group_by(ue_year,ue_month) %>%
		summarise(k_rec = sum(f_rec)) %>%
		ungroup() %>%
		arrange(ue_year,ue_month)
	uRV$uemin_heat_y_m <- min(filter(uRV$uedf_heat_y_m,!is.na(k_rec))$k_rec)
	uRV$uemax_heat_y_m <- max(filter(uRV$uedf_heat_y_m,!is.na(k_rec))$k_rec)

	uRV$ue_heat_y_m <- uRV$uedf_heat_y_m %>%
		#[IMPORTANT!!!] Both axes MUST be character/ordinal categories!!!
		mutate(
			ue_yearC = as.character(ue_year),
			ue_monthC = lubridate::month(ue_month, label = TRUE, abbr = TRUE)
		) %>%
		echarts4r::e_charts(ue_monthC,timeline = FALSE,height = uRV$height_heatYM) %>%
		echarts4r::e_heatmap(
			ue_yearC,
			k_rec,
			name = '# Freq.',
			itemStyle = list(
				emphasis = list(
					shadowBlur = 10,
					shadowColor = 'rgba(0,0,0,0.5)'
				)
			)
		) %>%
		echarts4r::e_visual_map(
			min = uRV$uemin_heat_y_m,
			max = uRV$uemax_heat_y_m,
			inRange = list(
				color = uRV$color_scale
			),
			orient = 'vertical',
			right = 2,
			top = 25,
			bottom = 25
		) %>%
		echarts4r::e_tooltip(trigger = 'item') %>%
		echarts4r::e_title(
			'Heatmap over month-year',
			left = 20,
			top = 2,
			textStyle=list(
				fontSize = 15
			)
		) %>%
		echarts4r::e_show_loading()

	uRV$ue_heat_y_m <- do.call(echarts4r::e_grid,
		append(
			list(e = uRV$ue_heat_y_m),
			append(
				uRV$grid_h,
				list(height = paste0(uRV$height_heatYM - uRV$height_exclchart,'px'))
			)
		)
	)
	output$uEch_Heat_Y_M <- echarts4r::renderEcharts4r({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[762][renderEcharts4r][IN][output$uEch_Heat_Y_M]:')))
		}
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Heat Map (Year-Month)'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_heat_y_m
	})

	#763. Heatmap with [date] as x axis and [month] as y axis, for the entire period
	#[Quote: https://echarts.apache.org/zh/option.html#series-heatmap ]
	#Find a leap year at first, for it has 366 days
	uRV$uedf_heat_m_d_base <- data.frame(
		tmpdate = seq.Date(from = as.Date('2016-01-01'),to = as.Date('2016-12-31'),by = 'days')
	) %>%
		mutate(
			ue_month = lubridate::month(tmpdate),
			ue_day = lubridate::day(tmpdate)
		) %>%
		select(-starts_with('tmp'))
	uRV$uedf_heat_m_d <- uRV$df_chart %>%
		mutate(f_rec = 1) %>%
		right_join(uRV$uedf_heat_m_d_base,by = c('ue_month','ue_day')) %>%
		group_by(ue_month,ue_day) %>%
		summarise(k_rec = sum(f_rec)) %>%
		ungroup() %>%
		arrange(ue_month,ue_day)
	uRV$uemin_heat_m_d <- min(filter(uRV$uedf_heat_m_d,!is.na(k_rec))$k_rec)
	uRV$uemax_heat_m_d <- max(filter(uRV$uedf_heat_m_d,!is.na(k_rec))$k_rec)

	uRV$ue_heat_m_d <- uRV$uedf_heat_m_d %>%
		#[IMPORTANT!!!] Both axes MUST be character/ordinal categories!!!
		mutate(
			ue_monthC = lubridate::month(ue_month, label = TRUE, abbr = TRUE),
			ue_dayC = as.character(ue_day)
		) %>%
		echarts4r::e_charts(ue_dayC,timeline = FALSE,height = 300) %>%
		echarts4r::e_heatmap(
			ue_monthC,
			k_rec,
			name = '# Freq.',
			itemStyle = list(
				emphasis = list(
					shadowBlur = 10,
					shadowColor = 'rgba(0,0,0,0.5)'
				)
			)
		) %>%
		echarts4r::e_visual_map(
			min = uRV$uemin_heat_m_d,
			max = uRV$uemax_heat_m_d,
			inRange = list(
				color = uRV$color_scale
			),
			orient = 'vertical',
			right = 2,
			top = 25
		) %>%
		echarts4r::e_tooltip(trigger = 'item') %>%
		echarts4r::e_title(
			'Heatmap over day-month',
			left = 20,
			top = 2,
			textStyle=list(
				fontSize = 15
			)
		) %>%
		echarts4r::e_show_loading()

	uRV$ue_heat_m_d <- do.call(echarts4r::e_grid,
		append(
			list(e = uRV$ue_heat_m_d),
			append(
				uRV$grid_h,
				list(height = paste0(300 - uRV$height_exclchart,'px'))
			)
		)
	)
	output$uEch_Heat_M_D <- echarts4r::renderEcharts4r({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[763][renderEcharts4r][IN][output$uEch_Heat_M_D]:')))
		}
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Heat Map (Month-Day)'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_heat_m_d
	})

	#764. Heatmap with [hour] as x axis and [weekday] as y axis, for the entire period
	#[Quote: https://echarts.apache.org/zh/option.html#series-heatmap ]
	output$uDiv_Heat_W_H <- shiny::renderUI({
		if (lubridate::is.Date(uRV$df_eval[[invar]])) return(NULL)
		shiny::fluidRow(
			class = 'svs_d_fluidRow',
			shiny::tags$div(
				UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='HEAT_WH')))),
				echarts4r::echarts4rOutput(ns('uEch_Heat_W_H'),height = '300px')
			)
		)
	})

	if (!lubridate::is.Date(uRV$df_eval[[invar]])) {
		#Construct a data frame of all 24 hours in every weekday
		uRV$uedf_heat_w_h_base <- data.frame(
			tmpdate = seq.POSIXt(
				from = strptime('20160103 00:00:00',format = '%Y%m%d %H:%M:%S'),
				to = strptime('20160109 00:00:00',format = '%Y%m%d %H:%M:%S'),
				by = 'hours'
			)
		) %>%
			mutate(
				ue_weekday = lubridate::wday(tmpdate, label = TRUE, abbr = TRUE),
				ue_hour = lubridate::hour(tmpdate)
			) %>%
			select(-starts_with('tmp'))
		uRV$uedf_heat_w_h <- uRV$df_chart %>%
			mutate(f_rec = 1) %>%
			right_join(uRV$uedf_heat_w_h_base,by = c('ue_weekday','ue_hour')) %>%
			group_by(ue_weekday,ue_hour) %>%
			summarise(k_rec = sum(f_rec)) %>%
			ungroup()
		uRV$uemin_heat_w_h <- min(filter(uRV$uedf_heat_w_h,!is.na(k_rec))$k_rec)
		uRV$uemax_heat_w_h <- max(filter(uRV$uedf_heat_w_h,!is.na(k_rec))$k_rec)
		# message(paste0('[uemax_heat_w_h]:[',uRV$uemax_heat_w_h,']'))

		uRV$ue_heat_w_h <- uRV$uedf_heat_w_h %>%
			#[IMPORTANT!!!] Both axes MUST be character/ordinal categories!!!
			mutate(
				ue_hourC = as.character(ue_hour)
			) %>%
			echarts4r::e_charts(ue_hourC,timeline = FALSE,height = 300) %>%
			echarts4r::e_heatmap(
				ue_weekday,
				k_rec,
				name = '# Freq.',
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				)
			) %>%
			echarts4r::e_visual_map(
				min = uRV$uemin_heat_w_h,
				max = uRV$uemax_heat_w_h,
				inRange = list(
					color = uRV$color_scale
				),
				orient = 'vertical',
				right = 2,
				top = 25
			) %>%
			echarts4r::e_tooltip(trigger = 'item') %>%
			echarts4r::e_title(
				'Heatmap over hour-weekday',
				left = 20,
				top = 2,
				textStyle=list(
					fontSize = 15
				)
			) %>%
			echarts4r::e_show_loading()

		uRV$ue_heat_w_h <- do.call(echarts4r::e_grid,
			append(
				list(e = uRV$ue_heat_w_h),
				append(
					uRV$grid_h,
					list(height = paste0(300 - uRV$height_exclchart,'px'))
				)
			)
		)
	#End of [if]
	}

	output$uEch_Heat_W_H <- echarts4r::renderEcharts4r({
		if (lubridate::is.Date(uRV$df_eval[[invar]])) return(NULL)
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[764][renderEcharts4r][IN][output$uEch_Heat_W_H]:')))
		}

		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Heat Map (Weekday-Hour)'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_heat_w_h
	})

	#800. Event Trigger
	#899. Determine the output value
	#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_Save

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[899][observe][IN][input$uWg_AB_Save]:',input$uWg_AB_Save)))
				}
				if (is.null(input$uWg_AB_Save)) return()
				if (input$uWg_AB_Save == 0) return()
				uRV_finish(input$uWg_AB_Save)
				uRV$ActionDone <- TRUE

				#900. Create the universal outputs
				uRV$module_dt_end <- Sys.time()
				uRV$module_charts$SUMM$OBJ <- uRV$TblSummary_DT
				uRV$module_charts$AREA$OBJ <- uRV$ue_area
				uRV$module_charts$CLNDR$OBJ <- uRV$ue_heat_cal
				uRV$module_charts$HEAT_YM$OBJ <- uRV$ue_heat_y_m
				uRV$module_charts$HEAT_MD$OBJ <- uRV$ue_heat_m_d
				if (lubridate::is.Date(indat[[invar]])){
					uRV$module_charts$BARPLOT$OBJ <- uRV$ue_bar_s_d
				} else {
					uRV$module_charts$CLOCK$C_HEIGHT <- 350
					clock_am <- do.call(echarts4r::e_grid,
						append(
							list(e = uRV$ue_clock_s_d_am),
							list(height = uRV$module_charts$CLOCK$C_HEIGHT)
						)
					)
					clock_pm <- do.call(echarts4r::e_grid,
						append(
							list(e = uRV$ue_clock_s_d_pm),
							list(height = uRV$module_charts$CLOCK$C_HEIGHT)
						)
					)
					uRV$uE_Clocks <- shiny::fillRow(
						flex = c(1,1),
						height = uRV$module_charts$CLOCK$C_HEIGHT,
						shiny::tags$div(clock_am),
						shiny::tags$div(clock_pm)
					)
					uRV$module_charts$CLOCK$OBJ <- uRV$uE_Clocks
					uRV$module_charts$CLOCK$OBJS[[1]] <- clock_am
					uRV$module_charts$CLOCK$OBJS[[2]] <- clock_pm

					uRV$module_charts$HEAT_WH$OBJ <- uRV$ue_heat_w_h
				}
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[899][observe][OUT][Done]')))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[899]Saving report')
		# ,priority = 001
	#End of [observe] of [899]
	)

	#999. Return the result
	#Next time I may try to append values as instructed below:
	#[Quote: https://community.rstudio.com/t/append-multiple-reactive-output-of-a-shiny-module-to-an-existing-reactivevalue-object-in-the-app/36985/2 ]
	return(
		list(
			CallCounter = shiny::reactive({uRV_finish()}),
			ActionDone = shiny::reactive({uRV$ActionDone()}),
			EnvVariables = shiny::reactive({uRV})
		)
	)
}

#[Full Test Program;]
if (FALSE){
	if (interactive()){
		lst_pkg <- c( 'dplyr' , 'haven' , 'DT' , 'lubridate' ,
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' ,
			'shinyWidgets' , 'styler' , 'shinyAce' , 'shinyjqui' , 'shinyEffects' , 'echarts4r' ,
			'openxlsx' , 'ineq' , 'Hmisc'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		source('D:\\R\\omniR\\Styles\\AdminLTE_colors.r')
		source('D:\\R\\omniR\\AdvOp\\scaleNum.r', encoding = 'utf-8')

		#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
		test_df <- lubridate::lakers %>%
			mutate(playtime = as.POSIXct(strptime(paste(date,time),format = '%Y%m%d %H:%M'),tz = Sys.getenv('TZ'))) %>%
			mutate(playdate = lubridate::date(playtime))
		source('D:\\R\\Project\\myApp\\Func\\UI\\theme_color_sets.r')

		ui <- shinydashboardPlus::dashboardPagePlus(
			shinyjs::useShinyjs(),
			header = shinydashboardPlus::dashboardHeaderPlus(),
			sidebar = shinydashboard::dashboardSidebar(),
			body = shinydashboard::dashboardBody(
				shiny::fluidPage(
					UM_core_SingleVarStats_Dtm_ui('uMod_D')
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$SVS_D <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL})
			)

			observeEvent(test_df,{
				modout$SVS_D <- shiny::callModule(
					UM_core_SingleVarStats_Dtm_svr,
					'uMod_D',
					fDebug = TRUE,
					indat = test_df,
					invar = 'playtime',
					invartype = 'Dtm',
					themecolorset = myApp_themecolorset
				)
			})
			shiny::observeEvent(modout$SVS_D$CallCounter(),{
				if (modout$SVS_D$CallCounter() == 0) return()
				message('[SVS_D$CallCounter()]:',modout$SVS_D$CallCounter())
				message('[SVS_D$EnvVariables]:')
				message('[SVS_D$EnvVariables()$sd]:',modout$SVS_D$EnvVariables()$sd)
				message('[SVS_D$EnvVariables()$nmiss]:',modout$SVS_D$EnvVariables()$nmiss)
				message('[SVS_D$EnvVariables()$module_charts$SUMM$TXT]:',modout$SVS_D$EnvVariables()$module_charts$SUMM$TXT)
				message('[SVS_D$EnvVariables()$module_charts$CLNDR$TXT]:',modout$SVS_D$EnvVariables()$module_charts$CLNDR$TXT)
			})
		}

		shinyApp(ui, server)
	}

}

#Test the components
if (FALSE){
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	color_scale <- myApp_themecolorset$s08$p

	test_aaa <- lubridate::lakers %>%
		mutate(playtime = as.POSIXct(strptime(paste(date,time),format = "%Y%m%d %H:%M"),tz = Sys.getenv('TZ'))) %>%
		mutate(
			playdate = lubridate::date(playtime),
			ue_yymm = strftime(playtime,format = "%Y-%m",tz = Sys.getenv('TZ')),
			ue_date = lubridate::date(playtime),
			ue_weekday = lubridate::wday(playtime, label = TRUE, abbr = TRUE),
			ue_year = lubridate::year(playtime),
			ue_month = lubridate::month(playtime),
			ue_monthC = lubridate::month(playtime, label = TRUE, abbr = TRUE),
			ue_day = lubridate::day(playtime),
			ue_hour = lubridate::hour(playtime),
			ue_minute = lubridate::minute(playtime),
			ue_second = lubridate::second(playtime)
		)
	df_CY <- test_aaa %>%
		filter(ue_year == max(test_aaa$ue_year)) %>%
		group_by(ue_date) %>%
		count() %>%
		ungroup() %>%
		arrange(desc(n))
	kdates_in_CY <- nrow(df_CY)
	glimpse(test_aaa)

	#Test Area Chart
	if (TRUE){
		test_aaa %>%
			group_by(ue_date) %>%
			count() %>%
			ungroup() %>%
			mutate(ue_year = lubridate::year(ue_date)) %>%
			group_by(ue_year) %>%
			# arrange(ue_date) %>%
			echarts4r::e_charts(ue_date,timeline = TRUE) %>%
			echarts4r::e_area(
				n,
				name = "Freq.",
				#Below color represent [primary] in the default theme
				color = myApp_themecolorset$s08$p[[length(myApp_themecolorset$s08$p)]]
			) %>%
			# echarts4r::e_mark_point(
			# 	data = list(
			# 		name = "Max",
			# 		type = "max"
			# 	)
			# ) %>%
			# echarts4r::e_mark_point(
			# 	data = list(
			# 		name = "Min",
			# 		type = "min"
			# 	)
			# ) %>%
			# echarts4r::e_mark_line(
			# 	data = avg,
			# 	#Below color represent [danger] in the default theme
			# 	itemStyle = list(
			# 		color = "red"
			# 	)
			# ) %>%
			echarts4r::e_legend(FALSE) %>%
			# echarts4r::e_flip_coords() %>%
			echarts4r::e_tooltip(
				trigger = "item",
				axisPointer = list(
					type = "cross"
				)
			) %>%
			echarts4r::e_toolbox() %>%
			# echarts4r::e_toolbox_feature(
			# 	feature = "magicType",
			# 	type = list("area","line")
			# ) %>%
			echarts4r::e_toolbox_feature(feature = "dataZoom") %>%
			echarts4r::e_title("Frequency Trend")
	}

	#Test Heatmap for the recent years
	if (TRUE){
		#Render the map for the latest year
		uedf_heat_cal <- test_aaa %>%
			group_by(ue_year,ue_date) %>%
			count() %>%
			ungroup()
		names(uedf_heat_cal)[names(uedf_heat_cal) == "n"] <- "k_rec"
		uemin_heat_cal <- min(uedf_heat_cal$k_rec)
		uemax_heat_cal <- max(uedf_heat_cal$k_rec)
		uemaxyr_heat_cal <- max(uedf_heat_cal$ue_year)
		glimpse(uedf_heat_cal)
		ue_heat_cal <- uedf_heat_cal %>%
			group_by(ue_year) %>%
			# arrange(ue_date) %>%
			echarts4r::e_charts(ue_date)

		#Create another heatmap if there are not enough records in the most latest year
			tmpdf_year <- uedf_heat_cal %>%
				filter(ue_year != max(uedf_heat_cal$ue_year))
		if (kdates_in_CY < 183 && nrow(tmpdf_year) > 0){
			uemaxyr2_heat_cal <- max(tmpdf_year$ue_year)
			ue_heat_cal <- ue_heat_cal %>%
				echarts4r::e_calendar(
					range = uemaxyr2_heat_cal,
					width = "85%",
					left = "12%",
					cellSize = c("auto","15"),
					orient = "horizontal"
				) %>%
				echarts4r::e_calendar(
					range = uemaxyr_heat_cal,
							top = 200,
					width = "85%",
					left = "12%",
					cellSize = c("auto","15"),
					orient = "horizontal"
				)
		} else {
			ue_heat_cal <- ue_heat_cal %>%
				echarts4r::e_calendar(
					range = uemaxyr_heat_cal,
					width = "85%",
					left = "12%",
					cellSize = c("auto","15"),
					orient = "horizontal"
				)
		}

		ue_heat_cal <- ue_heat_cal %>%
			echarts4r::e_heatmap(
				k_rec,
				name = "# Freq.",
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				),
				coord_system = "calendar"
			) %>%
			echarts4r::e_visual_map(
				min = uemin_heat_cal,
				max = uemax_heat_cal,
				inRange = list(
					color = color_scale
				),
				orient = "vertical",
				top = 30
			) %>%
			echarts4r::e_tooltip(trigger = "item") %>%
			echarts4r::e_title("Heatmap for the latest year(s)")
	}

	#Test Heatmap of day-month
	if (TRUE){
		uedf_heat_m_d_base <- data.frame(
			tmpdate = seq.Date(from = as.Date("2016-01-01"),to = as.Date("2016-12-31"),by = "days")
		) %>%
			mutate(
				ue_month = lubridate::month(tmpdate),
				ue_day = lubridate::day(tmpdate)
			) %>%
			select(-starts_with("tmp"))
		# str(uedf_heat_m_d_base)
		uedf_heat_m_d <- test_aaa %>%
			mutate(f_rec = 1) %>%
			right_join(uedf_heat_m_d_base,by = c('ue_month','ue_day')) %>%
			group_by(ue_month,ue_day) %>%
			summarise(k_rec = sum(f_rec)) %>%
			ungroup() %>%
			arrange(ue_month,ue_day) %>%
			as.data.frame()
		glimpse(uedf_heat_m_d)
		uemin_heat_m_d <- min(filter(uedf_heat_m_d,!is.na(k_rec))$k_rec)
		uemax_heat_m_d <- max(filter(uedf_heat_m_d,!is.na(k_rec))$k_rec)

		uedf_heat_m_d %>%
			mutate(
				ue_monthC = lubridate::month(ue_month, label = TRUE, abbr = TRUE),
				ue_dayC = as.character(ue_day)
			) %>%
			echarts4r::e_charts(ue_dayC) %>%
			echarts4r::e_heatmap(
				ue_monthC,
				k_rec,
				name = "# Freq.",
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				),
				tooltip = list(
					formatter = "{a}:<br /> {b}: {c}"
				)
			) %>%
			echarts4r::e_visual_map(
				min = uemin_heat_m_d,
				max = uemax_heat_m_d,
				dimension = 2,
				type = "continuous",
				inRange = list(
					color = color_scale
				),
				orient = "vertical",
				top = 30
			) %>%
			# echarts4r::e_x_axis(axisTick = list(alignWithLabel = TRUE)) %>%
			# echarts4r::e_y_axis(min = "dataMin") %>%
			echarts4r::e_tooltip(trigger = "item") %>%
			echarts4r::e_title("Heatmap over day-month")
	}

	#Test Heatmap of hour-weekday
	if (TRUE){
		#Construct a data frame of all 24 hours in every weekday
		uedf_heat_w_h_base <- data.frame(
			tmpdate = seq.POSIXt(
				from = strptime("20160103 00:00:00",format = "%Y%m%d %H:%M:%S"),
				to = strptime("20160109 00:00:00",format = "%Y%m%d %H:%M:%S"),
				by = "hours"
			)
		) %>%
			mutate(
				ue_weekday = lubridate::wday(tmpdate, label = TRUE, abbr = TRUE),
				ue_hour = lubridate::hour(tmpdate)
			) %>%
			select(-starts_with("tmp"))
		unique(uedf_heat_w_h_base$ue_weekday)
		uedf_heat_w_h <- test_aaa %>%
			mutate(f_rec = 1) %>%
			right_join(uedf_heat_w_h_base,by = c('ue_weekday','ue_hour')) %>%
			group_by(ue_weekday,ue_hour) %>%
			summarise(k_rec = sum(f_rec)) %>%
			ungroup()
		uemin_heat_w_h <- min(filter(uedf_heat_w_h,!is.na(k_rec))$k_rec)
		uemax_heat_w_h <- max(filter(uedf_heat_w_h,!is.na(k_rec))$k_rec)
		# message(paste0("[uemax_heat_w_h]:[",uemax_heat_w_h,"]"))
		glimpse(uedf_heat_w_h)

		uedf_heat_w_h %>%
			#[IMPORTANT!!!] Both axes MUST be character/ordinal categories!!!
			mutate(
				ue_hourC = as.character(ue_hour)
			) %>%
			echarts4r::e_charts(ue_hourC,timeline = FALSE) %>%
			echarts4r::e_heatmap(
				ue_weekday,
				k_rec,
				name = "# Freq.",
				itemStyle = list(
					emphasis = list(
						shadowBlur = 10,
						shadowColor = 'rgba(0,0,0,0.5)'
					)
				)
			) %>%
			echarts4r::e_visual_map(
				min = uemin_heat_w_h,
				max = uemax_heat_w_h,
				inRange = list(
					color = color_scale
				),
				orient = "vertical",
				top = 30
			) %>%
			echarts4r::e_tooltip(trigger = "item") %>%
			echarts4r::e_title("Heatmap over hour-weekday")
	}


}
