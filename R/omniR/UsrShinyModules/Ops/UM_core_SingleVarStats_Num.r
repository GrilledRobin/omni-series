# User Defined Module: [Stats of the provided Numeric variable in the provided data.frame]
# Details:
# [1]:[Summary Table]
# [2]:[Other Stats]
# [2][1]:[Standard Deviation]
# [2][2]:[Count of Missing Values, with percentage]
# [2][3]:[Count of Infinite Values, with percentage]
# [2][4]:[Count of Zero Values, with percentage][round(,6)==0]
# [2][5]:[Gini Coefficient]
# [2][6]:[Herfindahl-Hirschman Index (HHI)]
# [2][7]:[Entropy]
# [2][*]:[Corrected Sum of Squares(CSS)](Deprecated)
# [3]:[Box Plot]
# [4]:[Histogram with Density]
# Required User-specified parameters:

# [Quote: "RV": User defined Reactive Values]
# [Quote: "uWg": User defined Widgets]
# [Quote: "urT": User defined renderTable]
# [Quote: "uEch": User defined ECharts]
# [Quote: "DDB": User defined shinyWidgets::dropdownButton]
# [Quote: "pT": User defined shinyWidgets::prettyToggle]
# [Quote: "pS": User defined shinyWidgets::prettySwitch]
# [Quote: "SI": User defined sliderInput]

# Required User-specified modules:
# [Quote:[omniR$UsrShinyModules$Ops$UM_divBookmarkWithModal.r]]

# Required User-specified functions:
# [Quote:[omniR$Styles$AdminLTE_colors.r]]
# [Quote:[omniR$AdvOp$scaleNum.r]]
# [Quote:[omniR$Visualization$noUiSliderInput_EchStyle.r]]

UM_core_SingleVarStats_Num_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	#Create a box as container of UI elements for the mainframe
	shiny::uiOutput(ns('svs_n_main'))
}

UM_core_SingleVarStats_Num_svr <- function(input,output,session,
	fDebug = FALSE,indat = NULL,invar = NULL,invartype = NULL,themecolorset = NULL){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
	uRV$module_dt_bgn <- Sys.time()
	uRV$module_dt_end <- NULL
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
		BOXPLOT = list(
			NAME = paste0('Variable: [',invar,'] - Boxplot'),
			BM_style = paste0(
				'z-index: 1;',
				'position: absolute;',
				'right: 25px;',
				'top: 0;'
			)
		),
		HIST = list(
			NAME = paste0('Variable: [',invar,'] - Histogram & Density'),
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
	uRV$NumType <- NULL
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
	if (invartype != 'Num'){
		uRV$ValidInType <- FALSE
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV_f$ActionDone()}),
				EnvVariables = shiny::reactive({uRV_f})
			)
		)
	}
	#[Quote: https://stackoverflow.com/questions/2851015/convert-data-frame-columns-from-factors-to-characters ]
	#[Quote: Character conversion:[fact_character <- levels(fact)[as.numeric(fact)]]]
	#[Quote: Numeric conversion:[num_num <- as.numeric(levels(num_fact)[as.numeric(num_fact)])]]]
	uRV$NumType <- typeof(indat[[invar]])
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
		message(ns('[Module Call][UM_SingleVarStats_Num]'))
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

	#100. Prepare the interim data.frame for processing
	#110. Subset the input data frame to shrink the memory consumption
	#The more general way to rename a variable is: [names(aa)[names(aa) == vv] <- 'a_test']
	#[Quote: https://stackoverflow.com/questions/7531868/how-to-rename-a-single-column-in-a-data-frame ]
	uRV$df_eval <- indat %>% dplyr::select_at(invar)
	uRV$df_chartbase <- uRV$df_eval %>% dplyr::filter_at(invar,~(!is.infinite(.) & !is.na(.)))

	#170. Basic stats
	#172. Missing Values
	uRV$nmiss <- uRV$df_eval %>% dplyr::filter_at(invar,is.na) %>% count() %>% unlist() %>% as.vector()
	uRV$pmiss <- uRV$nmiss / nrow(uRV$df_eval)

	#173. Infinite Values
	uRV$n_inf <- uRV$df_eval %>% dplyr::filter_at(invar,is.infinite) %>% count() %>% unlist() %>% as.vector()
	uRV$p_inf <- uRV$n_inf / nrow(uRV$df_eval)

	#174. Zero Values
	uRV$nzero <- uRV$df_eval %>% dplyr::filter_at(invar,~(round(.,6) == 0)) %>% count() %>% unlist() %>% as.vector()
	uRV$pzero <- uRV$nzero / nrow(uRV$df_eval)

	#Corrected Sum of Squares
	# uRV$cssq <- var(uRV$df_eval[[invar]]) * (length(uRV$df_eval[[invar]]) - 1)

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

	#220. Styles for slicer on x-axis
	uRV$styles_slicer_x_div <- paste0(
		'width: 100%;',
		'height: 30px;',
		#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
		'position: relative;'
	)
	uRV$styles_slicer_x_chart <- paste0(
		'position: absolute;',
		'z-index: 0;',
		'top: 5px;',
		'right: 10px;',
		'left: 10px;'
	)
	uRV$grid_slicer_x_chart <- list(index = 0,height = '22px', bottom = '0', right = '0', left = '0')
	uRV$styles_slicer_x_slider <- paste0(
		'height: 100%;',
		'position: absolute;',
		#Ensure this layer is above the mini chart
		'z-index: 1;',
		'right: 10px;',
		'left: 10px;'
	)

	#228. Grids for the major charts
	uRV$grid_x <- list(index = 0, top = '20px', right = '25px', bottom = '20px', left = '25px')

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			'.btn-',gsub('\\W','_',ns('DDbtns'),perl = TRUE),' {',
				uRV$btn_styles,
			'}',
			'.caret {',
				'display: none;',
			'}',
			'[id="',ns('uWg_SI_ValRng'),'"] {',
				'background: rgba(10,10,10,0.05);',
				'top: 5px;',
			'}',
			'[id="',ns('slicer_x_out'),'"] {',
				'background: rgba(10,10,10,0.05);',
				'top: 5px;',
			'}',
			'.noUi-horizontal .noUi-handle {',
				'border-color: rgba(',paste0(uRV$chartitem_rgb, collapse = ','),',0.5);',
				'background: rgba(255,255,255,0.5);',
			'}',
			'.svs_n_fluidRow {padding: 2px 15px 2px 15px;}',
			'.svs_n_Column {',
				'padding: 0px;',
				# 'height: 34px;',
				'vertical-align: middle;',
			'}'
		)
	)

	#300. Define function to extract parameters from [base::hist]
	uRV$breaks <- 'Sturges'
	genHistInf <- function(df){
		rst <- list()

		#150. Prepare to scale the numbers on the labels of both axes for the scatter plot
		#151. x-axis
		#Since the input of function [scaleNum] is a single-element vector, its output [$values] is of the same shape.
		#[Quote:[omniR$AdvOp$scaleNum.r]]
		rst$max_x0 <- max(abs(df[[invar]]))
		numfmt_x0 <- scaleNum(rst$max_x0,1000,map_units=uRV$map_units)
		rst$logK_x0_whole <- numfmt_x0$parts$k_exp %>% unlist()
		rst$nfrac_x0 <- numfmt_x0$parts$k_dec %>% unlist()
		rst$str_unit_x0 <- numfmt_x0$parts$c_sfx %>% unlist()

		#200. Prepare the data for histograms
		#210. Extract the information for x-axis
		rst$x_prep <- hist(df[[invar]], plot = FALSE, breaks = uRV$breaks)
		rst$x_prep_df <- data.frame(
			mids = rst$x_prep$mids,
			mins = rst$x_prep$breaks[-length(rst$x_prep$breaks)],
			maxs = rst$x_prep$breaks[-1],
			counts = rst$x_prep$counts,
			density = rst$x_prep$density
		) %>%
			dplyr::mutate(itemColor = uRV$chartitem_color, xAxis = row_number()-1)
		rst$len_whole_x_axis <- max(nchar(gsub('^\\s*(-?\\d*)?((\\.)(\\d*))?$','\\1',rst$x_prep$mids,perl = TRUE)))
		rst$len_frac_x_axis <- max(nchar(gsub('^\\s*(-?\\d*)?((\\.)(\\d*))?$','\\4',rst$x_prep$mids,perl = TRUE)))
		rst$len_max_x_axis <- rst$len_whole_x_axis + rst$len_frac_x_axis + 1
		rst$fmtlen_x_axis <- min(rst$len_frac_x_axis,2)
		rst$x_prep_df <- rst$x_prep_df %>%
			dplyr::mutate(
				c_mids = paste0(
					ifelse(mids<0,'-',''),
					tmcn::right(
						paste0(paste0(rep('0',rst$len_max_x_axis),collapse = ''),abs(mids)),
						rst$len_max_x_axis
					)
				)
			)

		#250. Prepare to scale the numbers on the labels of axes for the histograms
		#251. y-axis for x-histogram (index==1)
		rst$max_x1 <- max(rst$x_prep$counts)
		numfmt_x1 <- scaleNum(rst$max_x1,1000,map_units=uRV$map_units)
		rst$logK_x1_whole <- numfmt_x1$parts$k_exp %>% unlist()
		rst$nfrac_x1 <- numfmt_x1$parts$k_dec %>% unlist()
		rst$str_unit_x1 <- numfmt_x1$parts$c_sfx %>% unlist()

		#400. Correct the attributes of axes
		#420. Correct the bar width of the x-histogram
		#This only happens when the minimum of [x] is larger than 0 for certain amount
		#421. Calculate interval
		rst$ntvl_x_scatter <- (rst$x_prep$mids[[1]] - rst$x_prep$breaks[[1]]) * 2
		rst$min_x_scatter <- rst$x_prep$breaks[[1]]
		rst$max_x_scatter <- rst$x_prep$breaks[[length(rst$x_prep$breaks)]]
		if (rst$min_x_scatter < 0 & min(df[[invar]]) > 0) rst$min_x_scatter <- 0

		#600. Attributes of density axis
		rst$max_dens <- max(rst$x_prep$density)
		rst$prec_dens <- floor(log(rst$max_dens,base = 10))

		#990. Return values
		return(rst)
	}

	#500. Create the base for charting based on user interaction
	#505. This step is to prevent an extra execution at initialization of the call when all these inputs are NULLs
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_pT_IncZero
			input$uWg_pT_IncNeg
			input$uWg_pS_ln
			input$uWg_pS_abs

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[505][observe][IN][input$uWg_pT_IncZero]:',input$uWg_pT_IncZero)))
					message(ns(paste0('[505][observe][IN][input$uWg_pT_IncNeg]:',input$uWg_pT_IncNeg)))
					message(ns(paste0('[505][observe][IN][input$uWg_pS_ln]:',input$uWg_pS_ln)))
					message(ns(paste0('[505][observe][IN][input$uWg_pS_abs]:',input$uWg_pS_abs)))
				}
				#100. Create the chart base in terms of the filtration from user interaction
				tmpdf <- uRV$df_eval
				if (!is.null(input$uWg_pT_IncZero)) if (!input$uWg_pT_IncZero) tmpdf <- tmpdf %>% dplyr::filter_at(invar,~. != 0)
				if (!is.null(input$uWg_pT_IncNeg)) if (!input$uWg_pT_IncNeg) tmpdf <- tmpdf %>% dplyr::filter_at(invar,~. >= 0)
				if (!is.null(input$uWg_pS_ln)) if (input$uWg_pS_ln) tmpdf <- tmpdf %>% dplyr::mutate_at(invar,log1p)
				if (!is.null(input$uWg_pS_abs)) if (input$uWg_pS_abs) tmpdf <- tmpdf %>% dplyr::mutate_at(invar,abs)
				uRV$df_chartbase <- tmpdf %>% dplyr::filter_at(invar,~(!is.infinite(.) & !is.na(.)))
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[505]Prepare chart base data')
		# ,priority = 990
	#End of [observe] of [505]
	)

	#510. Make sure the value of slider input is not prior to the change of source data
	#It is tested that during a recursive call of this module, the input values will retain from the previous call,
	# which affects the calculation of this round of call. That is why we ensure this event happens prior to the
	# change on source data, thus eliminate its impact.
	#IMPORTANT!!! [shiny::observeEvent] will trigger TWICE once user drags the slider input!
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_SI_ValRng

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[510][observeEvent][IN][input$uWg_SI_ValRng]:<',paste0(input$uWg_SI_ValRng,collapse = '>,<'),'>')))
				}
				if (is.null(input$uWg_SI_ValRng)) return()
				if (length(input$uWg_SI_ValRng) == 0) return()
				#100. Update the filter values
				uRV$charts_min <- input$uWg_SI_ValRng[[1]]
				uRV$charts_max <- input$uWg_SI_ValRng[[2]]
				uRV$charts_range <- paste0(uRV$charts_min,'||',uRV$charts_max)
			})
		}
		,label = ns('[510]Observe slider input')
	#End of [observeEvent] of [510]
	)

	#530. Define the chart base independent to the slider input
	shiny::observe(
		{
			#100. Take dependencies
			uRV$df_chartbase

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[530][observe][IN][uRV$df_chartbase]:',paste0(summary(uRV$df_chartbase),collapse = ' '))))
				}
				#200. Initialize the slicers
				#201. Retrieve the histogram information for the input data
				uRV$slicer_inf <- genHistInf(uRV$df_chartbase)
				uRV$charts_min <- uRV$slicer_inf$min_x_scatter
				uRV$charts_max <- uRV$slicer_inf$max_x_scatter
				uRV$charts_range <- paste0(uRV$charts_min,'||',uRV$charts_max)

				#205. Initialize the dataframe for charting
				#It is found that when the slider input is re-created or updated, its input value is NOT changed at the same time,
				# that is why we need to manually update the dataframe for charting when we need to update the slider input.
				uRV$df_charts <- uRV$df_chartbase %>%
					dplyr::filter_at(invar,~(. >= min(uRV$slicer_inf$min_x_scatter) & . <= max(uRV$slicer_inf$max_x_scatter)))

				#210. Mini chart on the slicer for x-axis
				uRV$slicer_x_chart <- echarts4r::e_charts(height = 22) %>%
					# echarts4r::e_grid(index = 0,height = "15px", top = "0", right = "0", left = "0") %>%
					echarts4r::e_data(uRV$slicer_inf$x_prep_df,c_mids) %>%
					echarts4r::e_bar(
						counts,
						legend = FALSE,
						barWidth = '98%',
						itemStyle = list(opacity = .3),
						color = uRV$chartitem_color,
						tooltip = list(
							confine = FALSE,
							formatter = htmlwidgets::JS(paste0(
								"function(params){",
									"return(",
										"'<strong>Overall</strong><br/>'",
										"+ '<i>[' + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(",uRV$slicer_inf$fmtlen_x_axis,")) + ']</i>'",
										"+ ' : ' + echarts.format.addCommas(params.value[1])",
									");",
								"}"
							))
						),
						x_index = 0,
						y_index = 0
					) %>%
					echarts4r::e_y_axis(
						index = 0,
						gridIndex = 0,
						show = FALSE
					) %>%
					echarts4r::e_x_axis(
						index = 0,
						gridIndex = 0,
						show = FALSE
					) %>%
					echarts4r::e_tooltip(
						trigger = 'item',
						# position = list(
						# 	right = '-64px',
						# 	top = '-32px'
						# ),
						axisPointer = list(show = FALSE)
					)
				output$uC_slicer_x <- echarts4r::renderEcharts4r({
					#We pass a list here to sanitize the program
					#[Quote: https://stackoverflow.com/questions/9129673/passing-list-of-named-parameters-to-function ]
					do.call(echarts4r::e_grid,
						append(
							list(e = uRV$slicer_x_chart),
							append(
								uRV$grid_slicer_x_chart,
								list(height = '22px')
							)
						)
					)
				})

				#220. Slicer for x-axis
				uRV$slicer_x <- shiny::tags$div(
					style = uRV$styles_slicer_x_div,
					shiny::tags$div(
						style = uRV$styles_slicer_x_chart,
						#The height of the slider bar of [noUiSliderInput] is [20px]
						echarts4r::echarts4rOutput(ns('uC_slicer_x'), width = '100%', height = '20px')
					),
					shiny::tags$div(
						style = uRV$styles_slicer_x_slider,
						# shinyWidgets::noUiSliderInput(
						#[Quote:[omniR$Visualization$noUiSliderInput_EchStyle.r]]
						noUiSliderInput_EchStyle(
							inputId = ns('uWg_SI_ValRng'),
							min = uRV$slicer_inf$min_x_scatter, max = uRV$slicer_inf$max_x_scatter,
							value = c(uRV$slicer_inf$min_x_scatter,uRV$slicer_inf$max_x_scatter),
							tooltips = FALSE,
							connect = c(TRUE, FALSE, TRUE),
							color = paste0('rgba(',paste0(uRV$chartitem_rgb, collapse = ','),',0.5)'),
							width = '100%',
							height = 20
						)
					)
				)
				output$uDiv_slicer_x <- shiny::renderUI({uRV$slicer_x})
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[530]Prepare chart data and slicer')
		# ,priority = 990
	#End of [observe] of [530]
	)

	#550. Update the dataframe for charting based on the change of slider input
	shiny::observe(
		{
			#100. Take dependencies
			#We only take one input to avoid the case when the values of slider input triggers twice at the same time.
			uRV$charts_range

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[550][observe][IN][uRV$charts_min]:',uRV$charts_min)))
					message(ns(paste0('[550][observe][IN][uRV$charts_max]:',uRV$charts_max)))
				}
				uRV$df_charts <- uRV$df_chartbase %>%
					dplyr::filter_at(invar,~(. >= uRV$charts_min & . <= uRV$charts_max))
			#End of [isolate]
			})
		}
		,label = ns('[550]Observe the changes of min/max values on the slider')
	)

	#570. Define the charts
	shiny::observe(
		{
			#100. Take dependencies
			uRV$df_charts

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[570][observe][IN][uRV$df_charts]:',paste0(summary(uRV$df_charts),collapse = ' '))))
				}
				#300. Prepare the summary table
				uRV$VarSummary <- summary(uRV$df_charts[[invar]]) %>%
					stack() %>%
					data.frame(Stats = .$ind,Values = .$values) %>%
					mutate(Values_C = formatC(Values,format = 'f',digits = ifelse(uRV$NumType == 'integer',0,2),big.mark = ',')) %>%
					select(Stats,Values_C,Values)
				uRV$valmin <- min(uRV$df_chartbase[[invar]])
				uRV$valmax <- max(uRV$df_chartbase[[invar]])
				uRV$histmin <- min(uRV$df_charts[[invar]])
				uRV$histmax <- max(uRV$df_charts[[invar]])

				#500. Prepare other stats
				#510. Standard Deviation
				uRV$sd <- sd(uRV$df_charts[[invar]])

				#550. Inequality and Concentration
				#Gini Coefficient
				uRV$gini <- ineq::Gini(uRV$df_charts[[invar]])
				#Herfindahl-Hirschman Index (HHI)
				#[Quote: https://baike.baidu.com/item/HHI指数/2654494?fr=aladdin ]
				uRV$HHI <- ineq::Herfindahl(uRV$df_charts[[invar]])
				#Entropy
				uRV$entropy <- ineq::entropy(uRV$df_charts[[invar]])

				#Corrected Sum of Squares
				# uRV$cssq <- var(uRV$df_eval()[[invar]]) * (length(uRV$df_eval()[[invar]]) - 1)

				#600. Combine the stats to the summary table
				uRV$TblSummary <- rbind(
					data.frame(
						Stats = c('# Mis.','% Mis.','# Inf','% Inf','# Zero','% Zero'),
						Values_C = c(
							formatC(uRV$nmiss,format = 'f',digits = 0,big.mark = ','),
							paste0(formatC(100*uRV$pmiss,format = 'f',digits = 2),'%'),
							formatC(uRV$n_inf,format = 'f',digits = 0,big.mark = ','),
							paste0(formatC(100*uRV$p_inf,format = 'f',digits = 2),'%'),
							formatC(uRV$nzero,format = 'f',digits = 0,big.mark = ','),
							paste0(formatC(100*uRV$pzero,format = 'f',digits = 2),'%')
						),
						Values = c(
							uRV$nmiss,
							uRV$pmiss,
							uRV$n_inf,
							uRV$p_inf,
							uRV$nzero,
							uRV$pzero
						)
					),
					uRV$VarSummary,
					data.frame(
						Stats = c('Std Dev.','Gini','HHI','Entropy'),
						Values_C = c(
							formatC(uRV$sd,format = 'f',digits = ifelse(uRV$NumType == 'integer',0,2),big.mark = ','),
							formatC(uRV$gini,format = 'f',digits = 2),
							formatC(uRV$HHI,format = 'f',digits = 2),
							formatC(uRV$entropy,format = 'f',digits = 2)
						),
						Values = c(
							uRV$sd,
							uRV$gini,
							uRV$HHI,
							uRV$entropy
						)
					)
				#End of [rbind]
				)

				#700. Prepare the specific font color for the dedicated stats values
				#[Quote: https://stackoverflow.com/questions/39240545/map-value-based-on-specified-intervals ]
				#[20191024] Below vector is created twice reactively upon any frontend operation! I cannot find a reason at present!
				#[20191024] This is the reason why there could be warning messages upon clicking of the button [uWg_pS_ln]
				uRV$ind_vals_color <- sapply(
					names(uRV$ind_brks),
					function(x){
						if (!(x %in% uRV$TblSummary$Stats)) return(NULL)
						if (is.na(filter(uRV$TblSummary,Stats == x)$Values)) return(NULL)
						# message(paste0('[',x,']:[',filter(uRV$TblSummary,Stats == x)$Values %>% unlist() %>% as.vector(),']'))
						tmpInterval <- filter(uRV$TblSummary,Stats == x)$Values %>%
							as.vector() %>%
							Hmisc::cut2(cuts = uRV$ind_brks[[x]])
						# message("[",x,"]:[",as.numeric(tmpInterval),"]-[",uRV$ind_fontcolor[[x]][[as.numeric(tmpInterval)]],"]")
						return(uRV$ind_fontcolor[[x]][[as.numeric(tmpInterval)]])
					}
				)

				#800. Update the UI
				#810. Create the summary table at frontend
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
						pageLength = nrow(uRV$TblSummary),
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
					#Set the background of specific stats, indicating that these values do not change
					DT::formatStyle(
						'Stats',
						target = 'row',
						backgroundColor = styleEqual(
							c('# Mis.','% Mis.','# Inf','% Inf','# Zero','% Zero'),
							rep(ifelse(is.null(themecolorset),AdminLTE_color_default,themecolorset$s01$p[[1]]),6)
						)
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

				#820. Define the Histogram
				#821. Retrieve the histogram information for the input data
				uRV$x_hist_inf <- genHistInf(uRV$df_charts)

				#822. Prepare the histogram
				uRV$ue_hist <- uRV$x_hist_inf$x_prep_df %>%
					echarts4r::e_charts(c_mids,height = 450) %>%
					echarts4r::e_bar(
						counts,
						name = 'Hist-Freq.',
						barWidth = '90%',
						itemStyle = list(opacity = .75),
						color = uRV$chartitem_color,
						tooltip = list(
							formatter = htmlwidgets::JS(paste0(
								"function(params){",
									"return(",
										"'<strong>[Count]",invar,"</strong><br/>'",
										"+ '<i>[' + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(",uRV$x_hist_inf$fmtlen_x_axis,")) + ']</i>'",
										"+ ' : ' + echarts.format.addCommas(params.value[1])",
									");",
								"}"
							))
						),
						x_index = 0,
						y_index = 0
					) %>%
					echarts4r::e_y_axis(
						index = 0,
						gridIndex = 0,
						show = TRUE,
						axisLabel = list(
							rotate = 90,
							formatter = htmlwidgets::JS(paste0(
								"function(value, index){",
									"return(",
										"(value/",1000^uRV$x_hist_inf$logK_x1_whole,").toFixed(",uRV$x_hist_inf$nfrac_x1,") + '",uRV$x_hist_inf$str_unit_x1,"'",
									");",
								"}"
							))
						),
						splitLine = list(
							lineStyle = list(
								type = 'dashed'
							)
						),
						nameGap = 20,
						nameLocation = 'center'
					) %>%
					echarts4r::e_x_axis(
						index = 0,
						gridIndex = 0,
						show = TRUE,
						axisPointer = list(
							label = list(
								formatter = htmlwidgets::JS(paste0(
									"function(params){",
										"return(",
											"(parseFloat(params.value)/",1000^uRV$x_hist_inf$logK_x0_whole,").toFixed(",uRV$x_hist_inf$nfrac_x0,") + '",uRV$x_hist_inf$str_unit_x0,"'",
										");",
									"}"
								))
							)
						),
						axisLabel = list(
							formatter = htmlwidgets::JS(paste0(
								"function(value, index){",
									"return(",
										"(parseFloat(value)/",1000^uRV$x_hist_inf$logK_x0_whole,").toFixed(",uRV$x_hist_inf$nfrac_x0,") + '",uRV$x_hist_inf$str_unit_x0,"'",
									");",
								"}"
							))
						)
					)

				#825. Add density
				uRV$ue_hist <- uRV$ue_hist %>%
					echarts4r::e_area(
						density,
						name = 'Density',
						itemStyle = list(opacity = .05),
						#Below color represent [danger] in the default theme
						color = ifelse(is.null(themecolorset),AdminLTE_color_danger,themecolorset$s06$p[[1]]),
						smooth = TRUE,
						smoothMonotone = 'x',
						tooltip = list(
							formatter = htmlwidgets::JS(paste0(
								"function(params){",
									"return(",
										"'<strong>[Density]",invar,"</strong><br/>'",
										"+ '<i>[' + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(",uRV$x_hist_inf$fmtlen_x_axis,")) + ']</i>'",
										"+ ' : ' + parseFloat(params.value[1]).toExponential(2)",
									");",
								"}"
							))
						),
						x_index = 0,
						y_index = 1
					) %>%
					echarts4r::e_y_axis(
						index = 1,
						gridIndex = 0,
						show = TRUE,
						axisLabel = list(
							rotate = -90
							,formatter = htmlwidgets::JS(paste0(
								"function(value, index){",
									"return(",
										#[Quote: https://www.techonthenet.com/js/number_toexponential.php ]
										"value.toExponential(1)",
									");",
								"}"
							))
						),
						splitLine = list(
							lineStyle = list(
								type = 'none'
							)
						),
						nameGap = 20,
						nameLocation = 'center'
					)

				#829. Add other gadgets
				uRV$ue_hist <- uRV$ue_hist %>%
					echarts4r::e_legend(TRUE) %>%
					echarts4r::e_show_loading() %>%
					echarts4r::e_tooltip(
						trigger = 'item',
						axisPointer = list(
							type = 'cross'
						)
					)

				#Finalize the grid
				uRV$ue_hist <- do.call(echarts4r::e_grid,
					append(
						list(e = uRV$ue_hist),
						append(
							uRV$grid_x,
							list(height = '410px')
						)
					)
				)

				#830. Define the boxplot
				uRV$ue_boxplot <- uRV$df_charts %>%
					echarts4r::e_charts(height = 450) %>%
					echarts4r::e_boxplot_(
						invar,
						name = invar,
						itemStyle = list(
							opacity = .75,
							color = ifelse(is.null(themecolorset),'snow',themecolorset$s08$p[[1]]),
							#Below color represent [primary] in the default theme
							borderColor = uRV$chartitem_color
						),
						outliers = TRUE
					) %>%
					echarts4r::e_y_axis(
						index = 0,
						gridIndex = 0,
						show = TRUE,
						name = NULL,
						axisLabel = list(
							rotate = 90,
							formatter = htmlwidgets::JS(paste0(
								"function(value, index){",
									"return(",
										"(value/",1000^uRV$x_hist_inf$logK_x0_whole,").toFixed(",uRV$x_hist_inf$nfrac_x0,") + '",uRV$x_hist_inf$str_unit_x0,"'",
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
					echarts4r::e_legend(FALSE) %>%
					echarts4r::e_tooltip(
						trigger = 'item',
						axisPointer = list(
							type = 'cross'
						)
					) %>%
					echarts4r::e_show_loading()

				#Finalize the grid
				uRV$ue_boxplot <- do.call(echarts4r::e_grid,
					append(
						list(e = uRV$ue_boxplot),
						append(
							uRV$grid_x,
							list(height = '410px')
						)
					)
				)

				# message("sd:[",uRV$sd(),"]")
				# message("gini:[",uRV$gini(),"]")
				# message("HHI:[",uRV$HHI(),"]")
				# message("entropy:[",uRV$entropy(),"]")
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[570]Draw charts')
		# ,priority = 980
	#End of [observe] of [570]
	)

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
	output$svs_n_main <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[707][renderUI][IN][output$svs_n_main:')))
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
				class = 'svs_n_Column',
				# style = 'padding-right: 15px;',
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
				class = 'svs_n_Column',
				# style = 'padding-left: 5px; padding-right: 15px;',
				shiny::fluidRow(
					class = 'svs_n_fluidRow',
					shiny::column(width = 6,
						class = 'svs_n_Column',
						shiny::fillRow(
							flex = c(1,NA),
							height = htmltools::validateCssUnit(30),
							#Add the title
							shiny::tags$div(
								style = uRV$styles_title_div,
								'Distribution'
							),
							#Add the drawing tools
							shiny::tags$div(
								style = paste0(
									'width: 34px;',
									'padding-left: 4px;',
									'margin-top: 2px;'
								),
								shinyWidgets::dropdownButton(
									inputId = ns('uWg_DDB_ShowTools'),
									icon = shiny::icon('gears'),
									circle = FALSE,
									right = TRUE,
									label = NULL,
									width = '100%',
									tooltip = FALSE,
									status = gsub('\\W','_',ns('DDbtns'),perl = TRUE),
									#Add toggle for removal of zero values
									shinyWidgets::prettyToggle(
										inputId = ns('uWg_pT_IncZero'),
										value = TRUE,
										animation = 'pulse',
										label_on = 'Incl. Zero Val.',
										label_off = 'Excl. Zero Val.',
										icon_on = shiny::icon('check'),
										status_on = 'primary',
										icon_off = shiny::icon('remove'),
										status_off = 'primary'
									),
									#Add toggle for removal of negative values
									shinyWidgets::prettyToggle(
										inputId = ns('uWg_pT_IncNeg'),
										value = TRUE,
										animation = 'pulse',
										label_on = 'Incl. Neg. Val.',
										label_off = 'Excl. Neg. Val.',
										icon_on = shiny::icon('check'),
										status_on = 'primary',
										icon_off = shiny::icon('remove'),
										status_off = 'primary'
									),
									#Add switch for obtaining the logarithm of the variable to the natural base
									shinyWidgets::prettySwitch(ns('uWg_pS_ln'), 'LOG() ?',
										fill = FALSE,
										status = 'primary'
									),
									#Add switch for obtaining the absolute value [ABS] of the variable
									shinyWidgets::prettySwitch(ns('uWg_pS_abs'), 'ABS() ?',
										fill = FALSE,
										status = 'primary'
									)
								#End of [dropdownButton]
								),
								tippy::tippy_this(
									ns('uWg_DDB_ShowTools'),
									'More Filters',
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
					),

					shiny::column(width = 6,
						class = 'svs_n_Column',
						shiny::fillRow(
							flex = c(1,NA),
							height = htmltools::validateCssUnit(30),
							#Add the value range selection
							shiny::uiOutput(ns('uDiv_slicer_x')),
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
					class = 'svs_n_fluidRow',
					shiny::column(width = 6,
						class = 'svs_n_Column',
						UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='BOXPLOT')))),
						#Add box for boxplot
						echarts4r::echarts4rOutput(ns('uEch_Conc_Boxplot'),height = '450px')
					#End of [column]
					),

					shiny::column(width = 6,
						class = 'svs_n_Column',
						UM_divBookmarkWithModal_ui(ns(paste0('bmwm',which(uRV$module_charts_names=='HIST')))),
						#Add box for histogram
						echarts4r::echarts4rOutput(ns('uEch_Conc_Hist'),height = '450px')
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
	#End of [renderDataTable] of [719]
	})

	#750. Diaplay the charts
	#[Quote:[echarts4r][ https://echarts4r.john-coene.com/index.html ]]

	#758. Arrange the charts
	#It is tested that these grouped charts cannot be rendered by [renderEcharts4r]
	# ue_final <- e_arrange(ue_hist, ue_boxplot, rows = 1, cols = 2)

	#759. Combine the charts
	output$uEch_Conc_Hist <- echarts4r::renderEcharts4r({
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Histogram'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_hist
	})
	output$uEch_Conc_Boxplot <- echarts4r::renderEcharts4r({
		#Increment the progress bar
		if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Drawing: Box Plot'))
		}

		#We pass a list here to sanitize the program
		uRV$ue_boxplot
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
				uRV$module_charts$BOXPLOT$OBJ <- uRV$ue_boxplot
				uRV$module_charts$HIST$OBJ <- uRV$ue_hist
				uRV$module_inputs[['Whether to include zeros']] <- input$uWg_pT_IncZero
				uRV$module_inputs[['Whether to include negative values']] <- input$uWg_pT_IncNeg
				uRV$module_inputs[['Whether obtain logarithm for non-negative and non-zero values']] <- input$uWg_pS_ln
				uRV$module_inputs[['whether obtain absolute values after logarithm']] <- input$uWg_pS_abs
				uRV$module_inputs[['Min value in the selected range']] <- input$uWg_SI_ValRng[[1]]
				uRV$module_inputs[['Max value in the selected range']] <- input$uWg_SI_ValRng[[2]]
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
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' , 'tippy' ,
			'shinyWidgets' , 'styler' , 'shinyAce' , 'shinyjqui' , 'shinyEffects' , 'echarts4r' ,
			'openxlsx' , 'ineq' , 'Hmisc'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		source(paste0(omniR,'\\UsrShinyModules\\Ops\\UM_divBookmarkWithModal.r'))
		source(paste0(omniR,'\\AdvOp\\scaleNum.r'),encoding = 'utf-8')
		source(paste0(omniR,'\\Styles\\AdminLTE_colors.r'))
		source(paste0(omniR,'\\Visualization\\noUiSliderInput_EchStyle.r'),encoding = 'utf-8')

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
					UM_core_SingleVarStats_Num_ui('uMod_n')
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$SVS_N <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL})
			)

			observeEvent(test_df,{
				modout$SVS_N <- shiny::callModule(
					UM_core_SingleVarStats_Num_svr,
					'uMod_n',
					fDebug = FALSE,
					indat = test_df,
					invar = 'a_aum_pfs',
					invartype = 'Num',
					themecolorset = myApp_themecolorset
				)
			})
			shiny::observeEvent(modout$SVS_N$CallCounter(),{
				if (modout$SVS_N$CallCounter() == 0) return()
				message('[SVS_N$CallCounter()]:',modout$SVS_N$CallCounter())
				message('[SVS_N$EnvVariables]:')
				message('[SVS_N$EnvVariables()$sd]:',modout$SVS_N$EnvVariables()$sd)
				message('[SVS_N$EnvVariables()$nmiss]:',modout$SVS_N$EnvVariables()$nmiss)
				message('[modout$SVS_N$EnvVariables()$module_charts$SUMM$TXT]:',modout$SVS_N$EnvVariables()$module_charts$SUMM$TXT)
				message('[modout$SVS_N$EnvVariables()$module_charts$HIST$TXT]:',modout$SVS_N$EnvVariables()$module_charts$HIST$TXT)
			})
		}

		shinyApp(ui, server)
	}

}
