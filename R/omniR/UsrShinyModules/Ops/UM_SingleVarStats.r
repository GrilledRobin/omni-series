# User Defined Module: [Respective Stats of the provided variables, with one visualization for each, in the provided data.frame]
# Details:
# Required User-specified parameters:

# [Quote: "RV": User defined Reactive Values]
# [Quote: "uMod": Caller of User Defined Modules]
# [Quote: "uWg": User defined Widgets]
# [Quote: "cbI": Check Box Input]
# [Quote: "csI": Check Box sliderInput]

# Required User-specified modules:
# [Quote:[omniR$UsrShinyModules$Ops$UM_core_SingleVarStats_Num.r]]

# Required User-specified functions:
# [Quote:[omniR$Styles$AdminLTE_colors.r]]
# [Quote:[omniR$Styles$css_inlineDiv.r]]

UM_SingleVarStats_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::tagList(
		#Set the overall control of the [fluidRow] in this module
		#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
		shiny::tags$head(
			tags$style(paste0(
				'.svs_fluidRow {padding: 2px 15px 2px 15px;}',
				#[Quote:[omniR$Styles$css_inlineDiv.r]]
				css_inlineDiv('svs_inlineDiv'),
				'.svs_Column {',
					'padding: 0px;',
					'vertical-align: middle;',
				'}'
			))
		),
		#Create a section to display the choices of [groupbyvar] for filtration
		shiny::uiOutput(ns('svs_grpby')),
		shiny::br(),
		#Create a box as container of UI elements for the mainframe
		shiny::uiOutput(ns('svs_main'))
	)
}

UM_SingleVarStats_svr <- function(input,output,session,
	fDebug = FALSE,indat = NULL,
	invar = NULL,invartype = NULL,
	groupbyvar = NULL,groupbyvartype = NULL,
	themecolorset = NULL){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
	uRV$ValidDat <- TRUE
	uRV$ValidVar <- TRUE
	uRV$VarCat <- NULL
	uRV$ValidVarType <- TRUE
	uRV$ValidRows <- TRUE
	uRV$ActionDone <- FALSE
	uRV$outRpt <- list()
	uRV$outFilter <- list()
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
	#Convert named vector into named list: [a.list <- split(unname(a),names(a))]
	#[Quote: https://stackoverflow.com/questions/46251725/convert-named-vector-to-list-in-r ]
	uRV$param_invar <- as.vector(invar)
	uRV$param_groupbyvar <- as.vector(groupbyvar)
	uRV$VarCat <- sapply(
		uRV$param_invar,
		function(x){
			ifelse(is.factor(indat[[x]]),
				ifelse(is.character(levels(indat[[x]])),
					'Character Factor',
					'Numeric Factor'
				),
				ifelse(is.character(indat[[x]]),
					'Character',
					'Numeric'
				)
			)
		}
	)
	#[Quote: https://stackoverflow.com/questions/2851015/convert-data-frame-columns-from-factors-to-characters ]
	#[Quote: Character conversion:[fact_character <- levels(fact)[as.numeric(fact)]]]
	#[Quote: Numeric conversion:[num_num <- as.numeric(levels(num_fact)[as.numeric(num_fact)])]]]
	if (is.null(invartype)){
		#Predict the types of the variables
		uRV$VarType <- sapply(
			uRV$param_invar,
			function(x){
				if (is.factor(indat[[x]])) return('Fct')
				if (lubridate::is.Date(indat[[x]]) || lubridate::is.POSIXct(indat[[x]])) return('Dtm')
				if (length(unique(indat[[x]])) <= (0.05*nrow(indat)+5)) return('Fct')
				if (is.character(indat[[x]])) return('Chr')
				return('Num')
			}
		)
	}
	else {
		uRV$VarType <- as.vector(invartype)
	}
	if (!all(uRV$VarType %in% c('Num','Fct','Chr','Dtm'))){
		uRV$ValidVarType <- FALSE
		if (fDebug){
			message(ns(paste0('[Module Init][UM_SingleVarStats]:')))
			message(ns(paste0('[ValidationError][uRV$VarType]:[',paste0(uRV$VarType,collapse = ','),']')))
		}
		return(
			list(
				CallCounter = shiny::reactive({uRV_finish()}),
				ActionDone = shiny::reactive({uRV$ActionDone()}),
				EnvVariables = shiny::reactive({uRV})
			)
		)
	}
	if (is.null(groupbyvartype)){
		#Predict the types of the variables
		uRV$GrpByVarType <- sapply(
			uRV$param_groupbyvar,
			function(x){
				if (is.factor(indat[[x]])) return('Fct')
				if (lubridate::is.Date(indat[[x]]) || lubridate::is.POSIXct(indat[[x]])) return('Dtm')
				if (length(unique(indat[[x]])) <= (0.05*nrow(indat)+5)) return('Fct')
				if (is.character(indat[[x]])) return('Chr')
				return('Num')
			}
		)
	}
	else {
		uRV$GrpByVarType <- as.vector(groupbyvartype)
	}
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
		message(ns(paste0('[Module Call][UM_SingleVarStats]')))
		message(ns(paste0('[Parameters][indat]:')))
		glimpse(indat)
		message(ns(paste0('[Parameters][uRV$param_invar]:[',paste0(uRV$param_invar,collapse = ','),']')))
		message(ns(paste0('[Parameters][uRV$param_groupbyvar]:[',paste0(uRV$param_groupbyvar,collapse = ','),']')))
		message(ns(paste0('[Parameters][uRV$VarCat]:[',paste0(uRV$VarCat,collapse = ','),']')))
		message(ns(paste0('[Parameters][uRV$VarType]:[',paste0(uRV$VarType,collapse = ','),']')))
	}

	#010. Prepare mapping table of variables
	#011. [invar]

	#012. [groupbyvar]
	#Only select the value groups with top 5 counts of records, and group all the rest into one
	uRV$k_group <- 5
	#The more general way to rename a variable is: [names(aa)[names(aa) == vv] <- 'a_test']
	uRV$names_groupbyvar <- NULL
	if (!is.null(uRV$param_groupbyvar)){
		uRV$names_groupbyvar <- sapply(1:length(uRV$param_groupbyvar),function(x){paste0('.v_grpby',x)})
		names(uRV$names_groupbyvar) <- uRV$param_groupbyvar
	}

	#015. Determine the modules to be called in terms of the variable types
	uRV$StatsSelector <- list(
		Fct = list(
			fn_ui = UM_core_SingleVarStats_Fct_ui,
			fn_svr = UM_core_SingleVarStats_Fct_svr
		),
		Num = list(
			fn_ui = UM_core_SingleVarStats_Num_ui,
			fn_svr = UM_core_SingleVarStats_Num_svr
		),
		Chr = list(
			fn_ui = UM_core_SingleVarStats_Chr_ui,
			fn_svr = UM_core_SingleVarStats_Chr_svr
		),
		Dtm = list(
			fn_ui = UM_core_SingleVarStats_Dtm_ui,
			fn_svr = UM_core_SingleVarStats_Dtm_svr
		)
	)

	#020. Prepare the interim data.frame for processing
	#021. Subset the input data frame to shrink the memory consumption
	#[Quote: https://stackoverflow.com/questions/7531868/how-to-rename-a-single-column-in-a-data-frame ]
	uRV$df_eval <- indat %>%
		dplyr::select_at(c(uRV$param_invar,uRV$param_groupbyvar))

	#024. Create additional variables to group the values in [groupbyvar]
	tmpAssign <- shiny::observe({
		if (is.null(uRV$names_groupbyvar)){
			tmpAssign$destroy()
			return()
		}
		uRV$k_groupvar_num <- 0
		for (x in c(1:length(uRV$names_groupbyvar))){
			uRV$outFilter[[x]] <- list(
				NAME = names(uRV$names_groupbyvar)[[x]],
				VALUE = NA
			)
			if ((uRV$GrpByVarType[[x]] %in% c('Dtm','Num'))) {
				tmp_df <- uRV$df_eval %>%
					dplyr::select_at(names(uRV$names_groupbyvar)[[x]]) %>%
					dplyr::filter_at(names(uRV$names_groupbyvar)[[x]],~(is.na(.) | is.infinite(.)))
				uRV[[paste0('GrpByHasNA',x)]] <- ifelse(nrow(tmp_df)>0,TRUE,FALSE)
				uRV[[paste0('GrpByMin',x)]] <- uRV$df_eval %>%
					dplyr::filter_at(names(uRV$names_groupbyvar)[[x]],~(!is.na(.) & !is.infinite(.))) %>%
					.[[names(uRV$names_groupbyvar)[[x]]]] %>%
					min()
				uRV[[paste0('GrpByMax',x)]] <- uRV$df_eval %>%
					dplyr::filter_at(names(uRV$names_groupbyvar)[[x]],~(!is.na(.) & !is.infinite(.))) %>%
					.[[names(uRV$names_groupbyvar)[[x]]]] %>%
					max()
				if (class(uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]]) == 'numeric'){
					uRV$k_groupvar_num <- uRV$k_groupvar_num + 1
				}
			} else {
				topvals <- uRV$df_eval %>%
					dplyr::group_by_at(names(uRV$names_groupbyvar)[[x]]) %>%
					count() %>%
					arrange(desc(n),.by_group = FALSE) %>%
					.[1:uRV$k_group,] %>%
					.[[names(uRV$names_groupbyvar)[[x]]]]
				uRV$df_eval[[uRV$names_groupbyvar[[x]]]] <- as.factor(
					ifelse(
						uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]] %in% topvals,
						uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]],
						'.Other'
					)
				)

				#Put the choices other than [.Other] on the left side among the checkboxes
				choice_left <- uRV$df_eval %>%
					dplyr::filter_at(uRV$names_groupbyvar[[x]],~ . != '.Other') %>%
					.[[uRV$names_groupbyvar[[x]]]] %>%
					unique()
				#Put the choice of [.Other] on the right-most side among the checkboxes
				choice_right <- uRV$df_eval %>%
					dplyr::filter_at(uRV$names_groupbyvar[[x]],~ . == '.Other') %>%
					.[[uRV$names_groupbyvar[[x]]]] %>%
					unique()
				#Display the text instead of the levels of the factor
				uRV$choice_dis <- levels(uRV$df_eval[[uRV$names_groupbyvar[[x]]]])[c(choice_left,choice_right)]

				uRV$outFilter[[x]]$VALUE_pri <- choice_left
				uRV$outFilter[[x]]$VALUE_oth <- paste0('Other than: [' , paste0(choice_left , collapse = '],[') , ']')
			}
		#End of [for]
		}
		tmpAssign$destroy()
	}
	,label = ns('One-off observer to transform the [groupbyvar]')
	)

	#027. Create the base for charting
	uRV$df_chartbase_all <- shiny::reactive({
		tmpdf <- uRV$df_eval
		if (!is.null(uRV$names_groupbyvar)){
			#[apply] functions cannot assign the values to its parent environment, hence we use [for] loop instead
			for (x in c(1:length(uRV$names_groupbyvar))){
				# message('input[[paste0('uWg_cbI_grp',x)]]:',input[[paste0('uWg_cbI_grp',x)]])
				# message('uRV$names_groupbyvar[x]:',uRV$names_groupbyvar[x])
				if ((uRV$GrpByVarType[[x]] %in% c('Dtm','Num'))) {
					if (length(input[[paste0('uWg_csI_grp',x)]])>0){
						if (class(uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]]) == 'numeric') {
							tmpdf <- tmpdf %>%
								dplyr::filter_at(
									names(uRV$names_groupbyvar)[[x]],
									~(
										. >= min(input[[paste0('uWg_csI_grp',x)]]) &
										. <= max(input[[paste0('uWg_csI_grp',x)]])
									)
								)
							uRV$outFilter[[x]]$TYPE <- 'Numeric Range'
							uRV$outFilter[[x]]$VALUE <- paste0('[ ' , min(input[[paste0('uWg_csI_grp',x)]]) , ' , ' , max(input[[paste0('uWg_csI_grp',x)]]) , ' ]')
						} else {
							if (lubridate::is.Date(uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]])) {
								tmpval <- lubridate::as_date(input[[paste0('uWg_csI_grp',x)]])
								tmpdf <- tmpdf %>%
									dplyr::filter_at(
										names(uRV$names_groupbyvar)[[x]],
										~(
											. >= min(tmpval) &
											. <= max(tmpval)
										)
									)
								uRV$outFilter[[x]]$TYPE <- 'Date Range'
								uRV$outFilter[[x]]$VALUE <- paste0('[ ' , input[[paste0('uWg_csI_grp',x)]][[1]] , ' , ' , input[[paste0('uWg_csI_grp',x)]][[2]] , ' ]')
							} else {
								tmpval <- strptime(input[[paste0('uWg_csI_grp',x)]],format = '%Y-%m-%d %H:%M')
								tmpdf <- tmpdf %>%
									dplyr::filter_at(
										names(uRV$names_groupbyvar)[[x]],
										~(
											. >= min(tmpval) &
											. <= max(tmpval)
										)
									)
								uRV$outFilter[[x]]$TYPE <- 'Datetime Range'
								uRV$outFilter[[x]]$VALUE <- paste0('[ ' , input[[paste0('uWg_csI_grp',x)]][[1]] , ' , ' , input[[paste0('uWg_csI_grp',x)]][[2]] , ' ]')
							}
						}
					}
				} else {
					if (length(input[[paste0('uWg_cbI_grp',x)]])>0){
						tmpdf <- tmpdf %>%
							dplyr::filter_at(
								names(uRV$names_groupbyvar)[[x]],
								~ . %in% input[[paste0('uWg_cbI_grp',x)]]
							)
						vals <- input[[paste0('uWg_cbI_grp',x)]]
						vals <- sapply(vals, function(m) ifelse(m=='.Other',uRV$outFilter[[x]]$VALUE_oth,m))
						uRV$outFilter[[x]]$TYPE <- 'Character Factor'
						uRV$outFilter[[x]]$VALUE <- paste0('(' , paste0(vals , collapse = '),(') , ')')
					}
				}
			}
		}
		# message('nrows:',nrow(tmpdf))
		return(tmpdf)
	}
	,label = ns('Generate Chart data based on filters')
	)

	#100. Prepare dynamic UIs
	#101. Prepare the primary UI

	#110. Prepare the selection pane for [groupbyvar]
	output$svs_grpby <- shiny::renderUI({
		if (is.null(uRV$names_groupbyvar)) return(NULL)
		#We use [lapply] to return a list for UI rendering
		lapply(
			c(1:length(uRV$names_groupbyvar)),
			function(x){
				if ((uRV$GrpByVarType[[x]] %in% c('Dtm','Num'))) {
					#Return the UI
					shiny::fluidRow(
						class = 'svs_fluidRow',
						#[div] to ensure the buttons are placed in-line
						shiny::tags$div(
							class = 'svs_inlineDiv',
							shiny::column(width = 2,
								class = 'svs_Column',
								style = 'padding-right: 5px; -webkit-flex: 1; flex: 1;',
								shiny::actionButton(ns(paste0('uWg_AB_grp',x)),
									paste0('[',names(uRV$names_groupbyvar)[[x]],']'),
									width = '100%',
									# class = 'btn-primary',
									style = 'text-align: right;'
								),
								tippy::tippy_this(
									ns(paste0('uWg_AB_grp',x)),
									paste0(names(uRV$names_groupbyvar)[[x]],': ',ifelse(uRV[[paste0('GrpByHasNA',x)]],'NA/Inf Values are removed','No NA/Inf Value')),
									placement = 'top',
									distance = 2,
									arrow = FALSE
								)
							#End of [column]
							),
							shiny::column(width = 10,
								class = 'svs_Column',
								style = 'padding-left: 5px; -webkit-flex: 5; flex: 5;',
								shinyWidgets::setSliderColor(
									ifelse(is.null(themecolorset),AdminLTE_color_primary,themecolorset$s08$p[[length(themecolorset$s08$p)]]),
									uRV$k_groupvar_num
								),
								shinyWidgets::chooseSliderSkin(
									'Nice',
									ifelse(is.null(themecolorset),AdminLTE_color_primary,themecolorset$s08$p[[length(themecolorset$s08$p)]])
								),
								if (class(uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]]) == 'numeric') {
									shiny::sliderInput(ns(paste0('uWg_csI_grp',x)),
										NULL,
										min = uRV[[paste0('GrpByMin',x)]],
										max = uRV[[paste0('GrpByMax',x)]],
										value = c(uRV[[paste0('GrpByMin',x)]],uRV[[paste0('GrpByMax',x)]]),
										width = '100%'
									)
								} else {
									if (lubridate::is.Date(uRV$df_eval[[names(uRV$names_groupbyvar)[[x]]]])) {
										shinyWidgets::airDatepickerInput(ns(paste0('uWg_csI_grp',x)),
											NULL,
											minDate = uRV[[paste0('GrpByMin',x)]],
											maxDate = uRV[[paste0('GrpByMax',x)]],
											placeholder = 'Please select date range',
											inline = FALSE,
											range = TRUE,
											update_on = 'close',
											width = '100%'
										)
									} else {
										shinyWidgets::airDatepickerInput(ns(paste0('uWg_csI_grp',x)),
											NULL,
											timepicker = TRUE,
											minDate = uRV[[paste0('GrpByMin',x)]],
											maxDate = uRV[[paste0('GrpByMax',x)]],
											placeholder = 'Please select datetime range',
											inline = FALSE,
											range = TRUE,
											update_on = 'close',
											width = '100%',
											timepickerOpts = timepickerOptions(
												timeFormat = 'hh:ii'
											)
										)
									}
								}
							#End of [column]
							)
						#End of [div]
						)
					#End of [fluidRow]
					)
				#End of [if]
				} else {
					#Return the UI
					shiny::fluidRow(
						class = 'svs_fluidRow',
						shiny::tags$div(
							class = 'svs_inlineDiv',
							shiny::column(width = 2,
								class = 'svs_Column',
								style = 'padding-right: 5px; -webkit-flex: 1; flex: 1;',
								shiny::actionButton(ns(paste0('uWg_AB_grp',x)),
									paste0('[',names(uRV$names_groupbyvar)[[x]],']'),
									width = '100%',
									# class = 'btn-primary',
									style = 'text-align: right;'
								),
								tippy::tippy_this(
									ns(paste0('uWg_AB_grp',x)),
									names(uRV$names_groupbyvar)[[x]],
									placement = 'top',
									distance = 2,
									arrow = FALSE
								)
							#End of [column]
							),
							shiny::column(width = 10,
								class = 'svs_Column',
								style = 'padding-left: 5px; margin-top: -11px; -webkit-flex: 5; flex: 5;',
								shinyWidgets::prettyCheckboxGroup(ns(paste0('uWg_cbI_grp',x)),
									NULL,
									# style = 'color: light-blue;',
									thick = TRUE,
									inline = TRUE,
									animation = 'pulse',
									status = 'primary',
									choices = uRV$choice_dis
									# choiceNames = choice_dis,
									# choiceValues = c(choice_left,choice_right)
								)
							#End of [column]
							)
						#End of [div]
						)
					#End of [fluidRow]
					)
				#End of [else]
				}
			#End of lambda [function]
			}
		#End of [apply]
		)
	#End of [renderUI] of [110]
	})

	#120. Mainframe
	#121. Call the servers of respective modules
	uRV$VarStats <- list()
	uRV$Obs_VarStats <- list()
	sapply(c(1:length(uRV$param_invar)),function(x){
		uRV$Obs_VarStats[[x]] <- shiny::observe(
			{
				#100. Take dependencies
				uRV$df_chartbase_all()
				uRV$param_invar[[x]]
				uRV$VarType[[x]]

				#900. Execute below block of codes only once upon the change of any one of above dependencies
				shiny::isolate({
					uRV$VarStats[[x]] <- shiny::callModule(
						uRV$StatsSelector[[uRV$VarType[[x]]]]$fn_svr,
						paste0('uMod_svs',x),
						fDebug = fDebug,
						indat = uRV$df_chartbase_all(),
						invar = uRV$param_invar[[x]],
						invartype = uRV$VarType[[x]],
						themecolorset = themecolorset
					)
				})
			}
			,label = ns(paste0('Module Caller: [',uRV$param_invar[[x]],'][',uRV$VarType[[x]],']'))
		)
	#End of [apply]
	})

	sapply(c(1:length(uRV$param_invar)),function(x){
		#500. Check whether the Single Variable Stats module has been completed
		shiny::observe(
			{
				#100. Take dependencies
				uRV$VarStats[[x]]$CallCounter()

				#900. Execute below block of codes only once upon the change of any one of above dependencies
				shiny::isolate({
					#Debug Mode
					if (fDebug){
						message(ns(paste0('[121][500][observe][IN][uRV$VarStats[[',x,']]$CallCounter()]:',uRV$VarStats[[x]]$CallCounter())))
					}
					#010. Return if the condition is not valid
					if (is.null(uRV$VarStats[[x]]$CallCounter())) return()

					#300. Assign the refreshed values
					if (is.null(uRV$Var_Done)) uRV$Var_Done <- 0
					if (uRV$Var_Done == sum(sapply(1:length(uRV$param_invar),function(i) uRV$VarStats[[i]]$CallCounter()),na.rm = T)) return()
					uRV$Var_Done <- uRV$Var_Done + 1
				#End of [isolate]
				})
			}
			,label = ns('[595]SVS: Monitor module completion')
			# ,priority = 150
		)

		#700. When user confirms the output
		shiny::observe(
			{
				#100. Take dependencies
				uRV$Var_Done

				#900. Execute below block of codes only once upon the change of any one of above dependencies
				shiny::isolate({
					#Debug Mode
					if (fDebug){
						message(ns(paste0('[121][700][observe][IN][uRV$Var_Done]:',uRV$Var_Done)))
					}
					#010. Return if the condition is not valid
					if (is.null(uRV$Var_Done)) return()
					if (uRV$Var_Done == 0) return()
					uRV_finish(uRV_finish() + 1)
					uRV$ActionDone <- TRUE

					#300. Assign the refreshed values
					uRV$outRpt[[uRV$param_invar[[x]]]] <- list(
						CHARTS = uRV$VarStats[[x]]$EnvVariables()$module_charts,
						INPUTS = uRV$VarStats[[x]]$EnvVariables()$module_inputs
					)
				#End of [isolate]
				})
			}
			,label = ns('[597]Collect data for standalone report')
			# ,priority = 130
		)
	#End of [apply]
	})

	#129. Render the UIs
	output$svs_main <- shiny::renderUI({
		#Create a box as container of UI elements for the entire module
		usrAcd_main <- bsplus::bs_accordion(ns('uWg_Acd_svs'))

		for (x in 1:length(uRV$param_invar)){
			usrAcd_main <- usrAcd_main %>%
				bsplus::bs_set_opts(panel_type = 'default' , use_heading_link = TRUE) %>%
				bsplus::bs_append(
					title = shiny::tagList(
						#Below style is identical to the default one in [bsplus], but it shows the way to customize its style.
						tags$style(
							type = 'text/css',
							paste0(
								'.panel-title {text-align: left;}'
							)
						),
						paste0('[',uRV$param_invar[[x]],']')
					),
					content = shiny::tags$div(
						style = 'margin-left: 5px; margin-right: 5px;',
						uRV$StatsSelector[[uRV$VarType[[x]]]]$fn_ui(ns(paste0('uMod_svs',x)))
					)
				)
		}

		return(
			shiny::tagList(
				#Below [panel] related settings are for [bsplus::bs_accordion]
				tags$style(
					type = 'text/css',
					paste0(
						'.panel-heading {',
							'height: 34px;',
							'padding: 10px;',
						'}',
						'.panel-body {padding: 5px;}'
					)
				),
				usrAcd_main
			)
		)
	#End of [renderUI] of [120]
	})

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
		lst_pkg <- c( 'dplyr' , 'haven' , 'DT' , 'readr', 'jiebaR' , 'lubridate' ,
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' , 'bsplus' , 'tippy' ,
			'shinyWidgets' , 'styler' , 'shinyAce' , 'shinyjqui' , 'shinyEffects' , 'echarts4r' ,
			'openxlsx' , 'ineq' , 'Hmisc'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		omniR <- 'D:\\R\\omniR'
		omniR <- list.files( omniR , '^.+\\.r$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE , include.dirs = TRUE ) %>%
			normalizePath()
		if (length(omniR)>0){
			o_enc <- sapply(omniR, function(x){guess_encoding(x)$encoding[1]})
			for (i in 1:length(omniR)){source(omniR[i],encoding = o_enc[i])}
		}

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
					UM_SingleVarStats_ui('uMod_svs')
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$svs <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL})
			)

			observeEvent(test_df,{
				modout$svs <- shiny::callModule(
					UM_SingleVarStats_svr,
					'uMod_svs',
					fDebug = FALSE,
					indat = test_df,
					invar = c('a_aum_pfs','nc_officer_cd'),
					invartype = c('Num','Fct'),
					groupbyvar = c('nc_rm_branch_en','f_staff','d_data','a_aum_T1'),
					groupbyvartype = c('Fct','Fct','Dtm','Num'),
					themecolorset = myApp_themecolorset
				)
			})
			shiny::observeEvent(modout$svs$CallCounter(),{
				if (modout$svs$CallCounter() == 0) return()
				message('[svs$CallCounter()]:',modout$svs$CallCounter())
				message('[svs$EnvVariables]:')
				message('[svs$EnvVariables()$outRpt]:',str(modout$svs$EnvVariables()$outRpt))
			})
		}

		shinyApp(ui, server)
	}

}
