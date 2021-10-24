# User Defined Module: [Stats of the provided Factor variable in the provided data.frame]
# Details:
# [1]:[Count of Missing Values, with percentage]
# [2]:[# of levels and the corresponding % over the total number of rows in the provided data]
# [3]:[Most frequent level, with its count and percentage]
# [4]:[Least frequent level, with its count and percentage]
# [5]:[Gini Coefficient]
# [6]:[Herfindahl-Hirschman Index (HHI)]
# [7]:[Entropy]
# [8]:[Bar showing frequency by levels]
# [9]:[Donut differentiating the most frequent 5 levels against all others, or between each other if there are not so many levels]
# Required User-specified parameters:

# [Quote: "RV": User defined Reactive Values]
# [Quote: "uWg": User defined Widgets]
# [Quote: "urT": User defined renderTable]
# [Quote: "uEch": User defined ECharts]
# [Quote: "pT": User defined shinyWidgets::prettyToggle]
# [Quote: "pS": User defined shinyWidgets::prettySwitch]
# [Quote: "SI": User defined sliderInput]

# Required User-specified functions:
# [Quote:[omniR$Styles$AdminLTE_colors.r]]
# [Quote:[omniR$AdvOp$scaleNum.r]]

UM_core_SingleVarStats_Fct_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	#Create a box as container of UI elements for the mainframe
	shiny::uiOutput(ns('svs_f_main'))
}

UM_core_SingleVarStats_Fct_svr <- function(input,output,session,
	fDebug = FALSE,indat = NULL,invar = NULL,invartype = NULL,themecolorset = NULL){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
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
		BARPLOT = list(
			NAME = paste0('Variable: [',invar,'] - Factor Frequency'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'right: 25px;',
				'top: 0;'
			)
		),
		PIEPLOT = list(
			NAME = paste0('Variable: [',invar,'] - Pie Chart of Significant Factors'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'right: 25px;',
				'top: 0;'
			)
		)
	)
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
	if (!(uRV$VarType %in% c('Character Factor','Numeric Factor'))){
		#Validate the [Factor]-like variable by its count of unique levels below 5%+5 of the number of rows
		if (length(unique(indat[[invar]])) > (0.05*nrow(indat)+5)){
			uRV$ValidVarType <- FALSE
			return(
				list(
					CallCounter = shiny::reactive({uRV_finish()}),
					ActionDone = shiny::reactive({uRV$ActionDone()}),
					EnvVariables = shiny::reactive({uRV})
				)
			)
		}
	}
	if (invartype != 'Fct'){
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
		message(ns('[Module Call][UM_SingleVarStats_Fct]'))
	}

	#010. Prepare mapping table of variables
	#011. Create the breaks to differentiate the font-colors as indicators
	uRV$ind_brks <- list(
		'% Mis.' = c(0,0.2,1),
		'% Inf' = c(0,0.2,1),
		'% Zero' = c(0,0.4,1),
		'Gini' = c(0,0.382,1),
		'Entropy' = c(-Inf,0.5,Inf),
		'HHI' = c(0,0.3,1)
	)
	uRV$ind_fontcolor <- list(
		'% Mis.' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'% Inf' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'% Zero' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'Gini' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'Entropy' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d)),
		'HHI' = c('#000000',ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s05$d))
	)
	uRV$map_units <- c(kilo = 'K', million = 'M', billion = 'B', trillion = 'T', quintillion = 'Q')

	#015. Prepare the color for the items in charts
	if (is.null(themecolorset)) {
		uRV$chartitem_color <- AdminLTE_color_primary
	} else {
		uRV$chartitem_color <- themecolorset$s08$p[[length(themecolorset$s08$p)]]
	}
	uRV$chartitem_rgb <- grDevices::col2rgb(uRV$chartitem_color)

	#020. Prepare the interim data.frame for processing
	#021. Subset the input data frame to shrink the memory consumption
	#The more general way to rename a variable is: [names(aa)[names(aa) == vv] <- 'a_test']
	#[Quote: https://stackoverflow.com/questions/7531868/how-to-rename-a-single-column-in-a-data-frame ]
	uRV$df_eval <- indat %>% dplyr::select_at(invar) %>% dplyr::mutate_all(as.factor)

	#025. Count the frequency by levels
	uRV$flevels <- levels(uRV$df_eval[[invar]])
	uRV$df_klevels <- uRV$df_eval %>%
		filter_at(invar,~!(is.na(.) | nchar(paste0(.))==0)) %>%
		group_by_at(invar) %>%
		count() %>%
		arrange_at('n',~desc(.)) %>%
		ungroup() %>%
		as.data.frame()

	#027. Create the base for charting
	if (nrow(uRV$df_klevels)<=5){
		uRV$df_chart_bar <- uRV$df_klevels
		uRV$df_chart_pie <- uRV$df_chart_bar
	} else {
		uRV$df_chart_bar <- uRV$df_klevels[1:5,]
		uRV$df_chart_pie <- data.frame(
			var_eval = c('Top 5','(Others)'),
			'n' = c(sum(uRV$df_chart_bar[['n']]),sum(uRV$df_klevels[['n']]) - sum(uRV$df_chart_bar[['n']]))
		)
		names(uRV$df_chart_pie)[names(uRV$df_chart_pie) == 'var_eval'] <- invar
	}

	#050. Prepare to scale the numbers on the labels of x-axis for the box plot
	uRV$max_x0 <- max(uRV$df_chart_bar[['n']])
	numfmt_x0 <- scaleNum(uRV$max_x0,1000,map_units=uRV$map_units)
	uRV$logK_x0_whole <- numfmt_x0$parts$k_exp %>% unlist()
	# uRV$nfrac_x0 <- numfmt_x0$parts$k_dec %>% unlist()
	uRV$nfrac_x0 <- 0
	uRV$str_unit_x0 <- numfmt_x0$parts$c_sfx %>% unlist()

	#070. Prepare other stats
	#072. Missing Values
	uRV$nmiss <- uRV$df_eval %>% dplyr::filter_at(invar,~(is.na(.) | nchar(paste0(.))==0)) %>% count() %>% unlist() %>% as.vector()
	uRV$pmiss <- uRV$nmiss / nrow(uRV$df_eval)

	#073. Most/Least frequent levels
	uRV$freq_m <- uRV$df_klevels[1,invar] %>% as.numeric()
	uRV$nfreq_m <- uRV$df_klevels[1,'n']
	uRV$pfreq_m <- uRV$nfreq_m / nrow(uRV$df_eval)
	uRV$freq_l <- uRV$df_klevels[nrow(uRV$df_klevels),invar] %>% as.numeric()
	uRV$nfreq_l <- uRV$df_klevels[nrow(uRV$df_klevels),'n']
	uRV$pfreq_l <- uRV$nfreq_l / nrow(uRV$df_eval)

	#075. Inequality and Concentration
	#Gini Coefficient
	uRV$gini <- ineq::Gini(uRV$df_klevels[['n']])
	#Herfindahl-Hirschman Index (HHI)
	#[Quote: https://baike.baidu.com/item/HHI指数/2654494?fr=aladdin ]
	uRV$HHI <- ineq::Herfindahl(uRV$df_klevels[['n']])
	#Entropy
	uRV$entropy <- ineq::entropy(uRV$df_klevels[['n']])
	# message(
	# 	'nmiss:[',formatC(uRV$nmiss,format = 'f',digits = 0,big.mark = ','),']',
	# 	'pmiss:[',paste0(formatC(100*uRV$pmiss,format = 'f',digits = 2),'%'),']',
	# 	'freq_m:[',as.character(levels(uRV$df_eval[[invar]])[uRV$freq_m]),']',
	# 	'nfreq_m:[',formatC(uRV$nfreq_m,format = 'f',digits = 0,big.mark = ','),']',
	# 	'pfreq_m:[',paste0(formatC(100*uRV$pfreq_m,format = 'f',digits = 2),'%'),']',
	# 	'freq_l:[',as.character(levels(uRV$df_eval[[invar]])[uRV$freq_l]),']',
	# 	'nfreq_l:[',formatC(uRV$nfreq_l,format = 'f',digits = 0,big.mark = ','),']',
	# 	'pfreq_l:[',paste0(formatC(100*uRV$pfreq_l,format = 'f',digits = 2),'%'),']'
	# )

	#090. Combine the stats to the summary table
	uRV$TblSummary <- rbind(
		data.frame(
			Stats = c('# Mis.','% Mis.','# Levels','#Lvl./#rows','Most Lvl.',' - #',' - %','Least Lvl.',' - #',' - %'),
			Values_C = c(
				formatC(uRV$nmiss,format = 'f',digits = 0,big.mark = ','),
				paste0(formatC(100*uRV$pmiss,format = 'f',digits = 2),'%'),
				formatC(length(uRV$flevels),format = 'f',digits = 0,big.mark = ','),
				paste0(formatC(100*(length(uRV$flevels)/nrow(uRV$df_eval)),format = 'f',digits = 2),'%'),
				as.character(levels(uRV$df_eval[[invar]])[uRV$freq_m]),
				formatC(uRV$nfreq_m,format = 'f',digits = 0,big.mark = ','),
				paste0(formatC(100*uRV$pfreq_m,format = 'f',digits = 2),'%'),
				as.character(levels(uRV$df_eval[[invar]])[uRV$freq_l]),
				formatC(uRV$nfreq_l,format = 'f',digits = 0,big.mark = ','),
				paste0(formatC(100*uRV$pfreq_l,format = 'f',digits = 2),'%')
			),
			Values = c(
				uRV$nmiss,
				uRV$pmiss,
				length(uRV$flevels),
				length(uRV$flevels)/nrow(uRV$df_eval),
				uRV$freq_m,
				uRV$nfreq_m,
				uRV$pfreq_m,
				uRV$freq_l,
				uRV$nfreq_l,
				uRV$pfreq_l
			)
		),
		data.frame(
			Stats = c('Gini','HHI','Entropy'),
			Values_C = c(
				formatC(uRV$gini,format = 'f',digits = 2),
				formatC(uRV$HHI,format = 'f',digits = 2),
				formatC(uRV$entropy,format = 'f',digits = 2)
			),
			Values = c(
				uRV$gini,
				uRV$HHI,
				uRV$entropy
			)
		)
	)
	# dt_test <<- uRV$TblSummary
	uRV$TblSummary_nrow <- nrow(uRV$TblSummary)

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

	#210. Styles for the title
	#Refer to documents of [echarts4r]
	uRV$styles_title_div <- paste0(
		'height: 30px;',
		'padding-left: 20px;',
		'padding-top: 2px;',
		'background-color: rgba(0,0,0,0);',
		'border: none;',
		'color: #333;',
		'font-family: sans-serif;',
		'font-size: 15px;',
		'font-weight: bold;'
	)

	#228. Grids for the major charts
	uRV$grid_x <- list(index = 0, top = '5px', right = '25px', bottom = '35px', left = '25px')

	#229. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			'.svs_f_fluidRow {padding: 2px 15px 2px 15px;}',
			'.svs_f_Column {',
				'padding: 0px;',
				# 'height: 34px;',
				'vertical-align: middle;',
			'}'
		)
	)

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
		if (uRV$pb_chart$getValue() >= uRV$pb_chart$getMax()){
			uRV$pb_chart$close()
			pb_obs_chart$suspend()
		}
	})

	#700. Prepare dynamic UIs
	#701. Prepare the primary UI

	#707. Mainframe
	output$svs_f_main <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[707][renderUI][IN][output$svs_f_main:')))
		}
		#Create a box as container of UI elements for the entire module
		shiny::tagList(
			#Set the overall control of the [fluidRow] in this module
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),
			shiny::column(width = 3,
				class = 'svs_f_Column',
				#Display a table showing special values of the provided variable.
				shiny::div(
					# style = 'text-align: center',
					UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='SUMM')))),
					DT::DTOutput(ns('urT_Summary'))
				#End of [div]
				)
			#End of [column]
			),

			shiny::column(width = 9,
				class = 'svs_f_Column',
				shiny::fluidRow(
					class = 'svs_f_fluidRow',
					shiny::column(width = 6,
						class = 'svs_f_Column',
						style = uRV$styles_title_div,
						'Level Significance'
					#End of [column]
					),

					shiny::column(width = 6,
						class = 'svs_f_Column',
						shiny::fillRow(
							flex = c(1,NA),
							height = htmltools::validateCssUnit(30),
							#Add a blank division as placement
							shiny::tags$div(
								style = paste0(
									'width: 100%;'
								)
							#End of [div]
							),
							#Add the button to save current charts as report
							shiny::tags$div(
								style = paste0(
									'width: 34px;',
									'padding-left: 4px;',
									'margin-top: 2px;'
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
							)
						#End of [fillRow]
						)
					#End of [column]
					)
				#End of [fluidRow]
				),
				shiny::fluidRow(
					class = 'svs_f_fluidRow',
					shiny::column(width = 6,
						class = 'svs_f_Column',
						UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='BARPLOT')))),
						#Add box for Bar Chart
						echarts4r::echarts4rOutput(ns('uEch_Conc_Bar'),height = '360px')
					#End of [column]
					),

					shiny::column(width = 6,
						class = 'svs_f_Column',
						UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='PIEPLOT')))),
						#Add box for Pie Chart
						echarts4r::echarts4rOutput(ns('uEch_Conc_Pie'),height = '360px')
					#End of [column]
					)
				#End of [fluidRow]
				)
			#End of [column]
			)
		#End of [tagList]
		)
	#End of [renderUI] of [707]
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
			# rownames = FALSE,
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

		#Increment the progress bar
		#[Quote: https://nathaneastwood.github.io/2017/08/13/accessing-private-methods-from-an-r6-class/ ]
		#[Quote: https://github.com/rstudio/shiny/blob/master/R/progress.R ]
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: DataTable'))
		}

		#Render UI
		uRV$TblSummary_DT
	#End of [renderDataTable] of [110]
	})

	#750. Diaplay the charts
	#[Quote:[echarts4r][ https://echarts4r.john-coene.com/index.html ]]
	#751. Render the bar chart
	uRV$ue_bar <- uRV$df_chart_bar %>%
		# arrange_at('n',~desc(.)) %>%
		echarts4r::e_charts_('n',height = 400) %>%
		echarts4r::e_bar_(
			invar,
			name = 'Freq.',
			tooltip = list(
				formatter = htmlwidgets::JS(paste0(
					"function(params){",
						"return(",
							"'<strong>[Count]",invar,"</strong><br/>'",
							"+ '<i>[' + params.value[1] + ']</i>'",
							"+ ' : ' + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(0))",
						");",
					"}"
				))
			),
			#Below color represent [primary] in the default theme
			color = ifelse(is.null(themecolorset),AdminLTE_color_primary,themecolorset$s08$p[[length(themecolorset$s08$p)]])
		) %>%
		echarts4r::e_legend(FALSE) %>%
		#[Quote: https://blog.csdn.net/maxwell0401/article/details/72861035 ]
		echarts4r::e_x_axis(
			type = 'value',
			name = '# Observations',
			nameGap = 20,
			nameLocation = 'center',
			axisLabel = list(
				formatter = htmlwidgets::JS(paste0(
					"function(value, index){",
						"return(",
							"(value/",1000^uRV$logK_x0_whole,").toFixed(",uRV$nfrac_x0,") + '",uRV$str_unit_x0,"'",
						");",
					"}"
				))
			),
			splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			)
		) %>%
		echarts4r::e_y_axis(
			type = 'category',
			axisLabel = list(
				rotate = 90
			)
		) %>%
		echarts4r::e_tooltip(
			trigger = 'item',
			axisPointer = list(
				type = 'cross'
			)
		)

	#Finalize the grid
	uRV$ue_bar <- do.call(echarts4r::e_grid,
		append(
			list(e = uRV$ue_bar),
			append(
				uRV$grid_x,
				list(height = '320px')
			)
		)
	)

	#752. Render the pie chart
	#[Quote: https://echarts.apache.org/zh/option.html#series-pie ]
	uRV$ue_pie <- uRV$df_chart_pie %>%
		echarts4r::e_charts_(invar,height = 400) %>%
		echarts4r::e_pie_(
			'n',
			name = 'Freq.',
			radius = c('50%','70%'),
			label = list(position = 'inside'),
			# emphasis = list(
			# 	label = list(
			# 		formatter = '{b}: {c}({d}%)'
			# 	)
			# ),
			tooltip = list(
				formatter = '[{b}]: {c}({d}%)'
			)
		) %>%
		echarts4r::e_tooltip(
			trigger = 'item',
			axisPointer = list(
				type = 'cross'
			)
		)
	if (!is.null(themecolorset)){
		#Prepare the series of colors
		ucolor <- paste0(
			sapply(
				#Make the color fade from dark
				rep(rev(themecolorset$s08$p),length.out = nrow(uRV$df_chart_pie)),
				function(x){
					paste0('"',x,'"')
				}
			),
			collapse = ","
		)
		uRV$ue_pie <- uRV$ue_pie %>%
			echarts4r::e_theme_custom(paste0('{"color":[',ucolor,']}'))
	}

	#Finalize the grid
	uRV$ue_pie <- do.call(echarts4r::e_grid,
		append(
			list(e = uRV$ue_pie),
			append(
				uRV$grid_x,
				list(height = '320px')
			)
		)
	)

	#758. Arrange the charts
	#It is tested that these grouped charts cannot be rendered by [renderEcharts4r]
	# ue_final <- e_arrange(ue_bar, ue_pie, rows = 1, cols = 2)

	#759. Combine the charts
	output$uEch_Conc_Bar <- echarts4r::renderEcharts4r({
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Bar Chart'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_bar
	})
	output$uEch_Conc_Pie <- echarts4r::renderEcharts4r({
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Pie Chart'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_pie
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
				uRV$module_charts$BARPLOT$OBJ <- uRV$ue_bar
				uRV$module_charts$PIEPLOT$OBJ <- uRV$ue_pie
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
		lst_pkg <- c( 'dplyr' , 'haven' , 'DT' ,
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' ,
			'shinyWidgets' , 'styler' , 'shinyAce' , 'shinyjqui' , 'shinyEffects' , 'echarts4r' ,
			'openxlsx' , 'ineq' , 'Hmisc'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		source('D:\\R\\omniR\\Styles\\AdminLTE_colors.r')

		test_df <- openxlsx::readWorkbook(
			'D:\\R\\Project\\myApp\\Data\\TestData.xlsx',
			sheet = 'Dual',
			detectDates = TRUE,
			fillMergedCells = TRUE
		)
		source('D:\\R\\Project\\myApp\\Func\\UI\\theme_color_sets.r')

		ui <- shinydashboardPlus::dashboardPagePlus(
			shinyjs::useShinyjs(),
			header = shinydashboardPlus::dashboardHeaderPlus(),
			sidebar = shinydashboard::dashboardSidebar(),
			body = shinydashboard::dashboardBody(
				shiny::fluidPage(
					UM_core_SingleVarStats_Fct_ui('uMod_F')
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$SVS_F <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL})
			)

			observeEvent(test_df,{
				modout$SVS_F <- shiny::callModule(
					UM_core_SingleVarStats_Fct_svr,
					'uMod_F',
					fDebug = FALSE,
					indat = test_df,
					invar = 'nc_officer_cd',
					invartype = 'Fct',
					themecolorset = myApp_themecolorset
				)
			})
			shiny::observeEvent(modout$SVS_F$CallCounter(),{
				if (modout$SVS_F$CallCounter() == 0) return()
				message('[SVS_F$CallCounter()]:',modout$SVS_F$CallCounter())
				message('[SVS_F$EnvVariables]:')
				message('[SVS_F$EnvVariables()$sd]:',modout$SVS_F$EnvVariables()$sd)
				message('[SVS_F$EnvVariables()$nmiss]:',modout$SVS_F$EnvVariables()$nmiss)
				message('[SVS_F$EnvVariables()$module_charts$SUMM$TXT]:',modout$SVS_F$EnvVariables()$module_charts$SUMM$TXT)
				message('[SVS_F$EnvVariables()$module_charts$PIEPLOT$TXT]:',modout$SVS_F$EnvVariables()$module_charts$PIEPLOT$TXT)
			})
		}

		shinyApp(ui, server)
	}

}
