# User Defined Module: [Split variables into groups for user selection]
# Change all variables with number of unique values less than 5%+5 of nrows() into [factors] before grouping.
# [Quote: How to create a "glass" button via CSS]
# [Quote: https://simplestepscode.com/css-glass-button-tutorial/ ]
# Grouping methods:
# [1 : Grp_C_N] [Dates], [Characters], [Numerics]
# [2 : Grp_F_S] [Dates], [Factors], [Statistics]
# Required User-specified parameters:

# [Quote: "RV": User defined Reactive Values]
# [Quote: "uWg": User defined Widgets]
# [Quote: "uAcd": User defined Accordion]
# [Quote: "uLbl": User defined dashboardLabel]
# [Quote: "DDBlk": User defined dropdownBlock]
# [Quote: "DDBtn": User defined dropdownButton]
# [Quote: "rGB": User defined radioGroupButtons]

# Required User-specified functions:

UM_varSelectByGroup_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	uiOutput(ns('uvsbg'))
}

UM_varSelectByGroup_svr <- function(input,output,session,
	fDebug = FALSE,indat = NULL,jqueryCore = 'http://code.jquery.com/jquery-3.4.1.js'){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
	uRV$outXName <- NULL
	uRV$outXType <- NULL
	uRV$outYName <- NULL
	uRV$outYType <- NULL
	uRV$outFName <- NULL
	uRV$outFType <- NULL
	uRV$ActionDone <- FALSE
	finish <- reactiveVal(0)
	if (is.null(indat)) return(
		list(
			CallCounter = shiny::reactive({finish()}),
			ActionDone = shiny::reactive({uRV$ActionDone}),
			EnvVariables = shiny::reactive({uRV}),
			VarXName = shiny::reactive({NULL}),
			VarXType = shiny::reactive({NULL}),
			VarYName = shiny::reactive({NULL}),
			VarYType = shiny::reactive({NULL}),
			VarFName = shiny::reactive({NULL}),
			VarFType = shiny::reactive({NULL})
		)
	)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[Module Call][UM_varSelectByGroup]')))
	}

	#030. Reset the necessary values once the module is called
	shinyjs::click('uWg_AB_ResetVar')

	#050. Prepare the lists of variables for user selection
	#051. Column Names and Indexes in the input data frame
	#[How to take dependency of input reactive values: https://community.rstudio.com/t/shiny-modules-reactive-values-do-not-update/7028 ]
	uRV$cols <- base::colnames(indat)
	uRV$coli <- sapply(1:length(uRV$cols),function(x){x})
	uRV$n_col <- length(uRV$cols)
	#Create a sequential number, marking the position of current field in the input data
	tmp_len <- nchar(uRV$coli)
	tmp_chr <- paste0(paste0(rep('0',nchar(uRV$n_col)),collapse = ''),uRV$coli)
	uRV$coliC <- substr(tmp_chr,nchar(tmp_chr)-nchar(uRV$n_col)+1,nchar(tmp_chr))

	#052. Names and Indexes of all date/time variables
	uRV$dt_fltr <- sapply(uRV$cols,function(x){lubridate::is.Date(indat[[x]]) || lubridate::is.POSIXct(indat[[x]])})
	uRV$dt_cols <- uRV$cols[uRV$dt_fltr]
	uRV$dt_coli <- uRV$coli[uRV$dt_fltr]
	uRV$dt_coliC <- uRV$coliC[uRV$dt_fltr]

	#053. Group the columns other than date/time ones into [Characters] and [Numerics]
	uRV$c_fltr <- sapply(uRV$cols,function(x){
		is.character(indat[[x]]) && !(x %in% uRV$dt_cols)
	})
	uRV$c_cols <- uRV$cols[uRV$c_fltr]
	uRV$c_coli <- uRV$coli[uRV$c_fltr]
	uRV$c_coliC <- uRV$coliC[uRV$c_fltr]
	uRV$n_cols <- uRV$cols[!(uRV$dt_fltr | uRV$c_fltr)]
	uRV$n_coli <- uRV$coli[!(uRV$dt_fltr | uRV$c_fltr)]
	uRV$n_coliC <- uRV$coliC[!(uRV$dt_fltr | uRV$c_fltr)]

	#054. Group the columns other than date/time ones into [Factors] and [Others]
	# Treat the variables with number of unique values less than 5%+5 of the number of rows as [factor]
	uRV$f_fltr <- sapply(uRV$cols,function(x){
		is.factor(indat[[x]]) ||
		(
			length(unique(indat[[x]])) <= (0.05*nrow(indat)+5) &&
				!(x %in% uRV$dt_cols)
		)
	})
	uRV$f_cols <- uRV$cols[uRV$f_fltr]
	uRV$f_coli <- uRV$coli[uRV$f_fltr]
	uRV$f_coliC <- uRV$coliC[uRV$f_fltr]
	uRV$s_cols <- uRV$cols[!(uRV$dt_fltr | uRV$f_fltr)]
	uRV$s_coli <- uRV$coli[!(uRV$dt_fltr | uRV$f_fltr)]
	uRV$s_coliC <- uRV$coliC[!(uRV$dt_fltr | uRV$f_fltr)]

	#060. Determine the analysis type of all variables
	uRV$vartype <- sapply(uRV$coli,function(x){
		if (uRV$dt_fltr[[x]]) return('Dtm')
		if (uRV$f_fltr[[x]]) return('Fct')
		if (uRV$c_fltr[[x]]) return('Chr')
		return('Num')
	})

	#070. Collect the grouping methods
	usrVec_VarGrpNm <- c('All','C/N','F/S')
	usrVec_VarGrpId <- c('Grp_NA','Grp_C_N','Grp_F_S')
	uRV$GrpMthd <- list(
		Grp_NA = list(
			.A = list(
				nm = 'All Variables',
				collapsed = FALSE,
				cols = uRV$cols,
				coli = uRV$coli,
				coliC = uRV$coliC
			)
		),
		Grp_C_N = list(
			.D = list(
				nm = 'Date/Time',
				collapsed = FALSE,
				cols = uRV$dt_cols,
				coli = uRV$dt_coli,
				coliC = uRV$dt_coliC
			),
			.C = list(
				nm = 'Characters',
				collapsed = TRUE,
				cols = uRV$c_cols,
				coli = uRV$c_coli,
				coliC = uRV$c_coliC
			),
			.N = list(
				nm = 'Numerics',
				collapsed = TRUE,
				cols = uRV$n_cols,
				coli = uRV$n_coli,
				coliC = uRV$n_coliC
			)
		),
		Grp_F_S = list(
			.D = list(
				nm = 'Date/Time',
				collapsed = FALSE,
				cols = uRV$dt_cols,
				coli = uRV$dt_coli,
				coliC = uRV$dt_coliC
			),
			.F = list(
				nm = 'Factors',
				collapsed = TRUE,
				cols = uRV$f_cols,
				coli = uRV$f_coli,
				coliC = uRV$f_coliC
			),
			.S = list(
				collapsed = TRUE,
				nm = 'Statistics',
				cols = uRV$s_cols,
				coli = uRV$s_coli,
				coliC = uRV$s_coliC
			)
		)
	)

	#200. General settings of styles for the output UI
	#201. Prepare the styles for the buttons indicating file attributes
	uRV$btn_styles_attr <- paste0(
		'width: 100%;',
		'text-align: left;',
		'vertical-align: middle;',
		'padding-left: 4px;',
		'background-color: rgba(0,0,0,0);',
		'border: none;'
	)

	#205. Prepare the styles for the buttons recording user actions
	uRV$btn_styles_AB <- paste0(
		'text-align: center;',
		'vertical-align: middle;',
		'color: white;',
		'overflow: hidden;'
	)

	#250. Styles for the UI to collect the selected variables
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_ShowVar <- shiny::HTML(
		paste0(
			'.label {',
				'padding: .1em .5em .1em;',
				'vertical-align: top;',
				'font-size: 70%;',
				#Below setting is to ensure the label in the shape of circle
				'width: 1.2em;',
				#Looks same effect as the [JQuery] injection above
				# 'height: 1.2em;',
			'}',
			'[id="',ns("uWg_DDBlk_Show_X"),'"] {',
				'width: 100%;',
				'text-align: center;',
				'vertical-align: middle;',
				'overflow: hidden;',
			'}',
			'[id="',ns("uWg_DDBlk_Show_Y"),'"] {',
				'width: 100%;',
				'text-align: center;',
				'vertical-align: middle;',
				'overflow: hidden;',
			'}',
			'[id="',ns("uWg_DDBlk_Show_F"),'"] {',
				'width: 100%;',
				'text-align: center;',
				'vertical-align: middle;',
				'overflow: hidden;',
			'}'
		)
	)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			#Below is to remove the [caret] sign created by [shinyWidgets::dropdownButton]
			'.caret {display: none;}',
			'.vsbg_fluidRow {padding: 2px 15px 2px 15px;}'
		)
	)

	#700. Prepare dynamic UIs
	#709. The overall UI
	output$uvsbg <- renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[709][renderUI][IN][uvsbg][is.null(indat)]:[',isolate(is.null(indat)),']')))
			message(ns(paste0('[709][renderUI][IN][uvsbg][length(uRV$cols]:[',isolate(length(uRV$cols)),']')))
		}
		#Suppress output if there is no data frame provided
		if (is.null(indat) | length(uRV$cols) == 0) return(NULL)

		#Create a box as container of UI elements for the entire module
		shiny::tagList(
			#Introduce the core library of [JQuery]
			#[Quote: https://stackoverflow.com/questions/5445491/height-equal-to-dynamic-width-css-fluid-layout?noredirect=1 ]
			shiny::tags$script(
				type = 'text/javascript',
				src = jqueryCore
			),

			#Prepare the [JQuery] function to set the [height] of any HTML tag the same as its [width]
			#Below injection seems to take the same effect as CSS3: [width:1.2em; height:1.2em;]
			#However, both solutions do not work perfectly on Chrome!!! (The circle looks like an ellipse)
			#[Quote: http://jsfiddle.net/n6DAu/24/ ]
			#One may try the solution with LESS (Leaner CSS)
			#[Quote: https://adminlte.io/blog/customizing-and-downsizing-adminlte-to-match-your-businsess ]
			#[Quote: http://lesscss.org/ ]
			shiny::tags$script(
				type = 'text/javascript',
				paste0(
					"function div_HeqW(id){",
						"var cw = $('#'+id).width();",
						"$('#'+id).css({",
						"'height': cw + 'px'",
						"});",
					"}\n",
					"div_HeqW('",ns("uLbl_X"),"');",
					"div_HeqW('",ns("uLbl_Y"),"');",
					"div_HeqW('",ns("uLbl_F"),"');"
				)
			),

			#Set the overall control of the [fluidRow] in this module
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			#Confirm the selection
			shiny::uiOutput(ns('uDiv_ConfVar')),

			#Show the selected variables in different categories
			#[div] to ensure the padding aligns with the division below it
			shiny::uiOutput(ns('uDDB_ShowVar')),

			#Radio Group Buttons for viewing the variables in groups
			shiny::tags$div(
				style = 'text-align: center',

				shinyWidgets::radioGroupButtons(ns('uWg_rGB_VarGrps'),
					label = NULL,
					justified = TRUE,
					choiceNames = usrVec_VarGrpNm,
					choiceValues = usrVec_VarGrpId,
					selected = 'Grp_NA'
				),
				#Accordion to display the variables
				shiny::uiOutput(ns('uAcd_SelVars'))
			#End of [div]
			)
		#End of [tagList]
		)
	#End of [renderUI] of [100]
	})

	#110. Display the variable as selected for confirmation
	uRV$SelName_X <- NULL
	uRV$SelType_X <- NULL
	uRV$SelIdx_X <- NULL
	uRV$SelName_Y <- NULL
	uRV$SelType_Y <- NULL
	uRV$SelIdx_Y <- NULL
	uRV$SelName_F <- NULL
	uRV$SelType_F <- NULL
	uRV$SelIdx_F <- NULL
	#111. Save the name of the selected variable by observing the click upon the various buttons
	#IMPORTANT!!! This observer MUST be executed before rendering UI, thus CANNOT be placed after that snippet.
	sapply(c(1:length(uRV$cols)),function(x){
		#[unique] will drop the names of the named vector, while [!duplicated] will reserve them although it is slower
		#[Quote: https://stackoverflow.com/questions/10769640/how-to-remove-repeated-elements-in-a-vector-similar-to-set-in-python ]
		shiny::observeEvent(input[[paste0('uWg_AB_X',x)]],{
			uRV$SelName_X <- c(uRV$SelName_X,uRV$cols[[x]])
			uRV$SelName_X <- uRV$SelName_X[!duplicated(uRV$SelName_X)]
			uRV$SelName_Y <- uRV$SelName_Y[uRV$SelName_Y != uRV$cols[[x]]]
			uRV$SelName_F <- uRV$SelName_F[uRV$SelName_F != uRV$cols[[x]]]
			#Reset the flag as Action Not Done
			uRV$ActionDone <- FALSE
		})
		shiny::observeEvent(input[[paste0('uWg_AB_Y',x)]],{
			uRV$SelName_Y <- c(uRV$SelName_Y,uRV$cols[[x]])
			uRV$SelName_Y <- uRV$SelName_Y[!duplicated(uRV$SelName_Y)]
			uRV$SelName_X <- uRV$SelName_X[uRV$SelName_X != uRV$cols[[x]]]
			uRV$SelName_F <- uRV$SelName_F[uRV$SelName_F != uRV$cols[[x]]]
			uRV$ActionDone <- FALSE
		})
		shiny::observeEvent(input[[paste0('uWg_AB_F',x)]],{
			uRV$SelName_F <- c(uRV$SelName_F,uRV$cols[[x]])
			uRV$SelName_F <- uRV$SelName_F[!duplicated(uRV$SelName_F)]
			uRV$SelName_X <- uRV$SelName_X[uRV$SelName_X != uRV$cols[[x]]]
			uRV$SelName_Y <- uRV$SelName_Y[uRV$SelName_Y != uRV$cols[[x]]]
			uRV$ActionDone <- FALSE
		})
		shiny::observeEvent(input[[paste0('uWg_AB_RM_X',x)]],{
			uRV$SelName_X <- uRV$SelName_X[uRV$SelName_X != uRV$cols[[x]]]
			uRV$ActionDone <- FALSE
		})
		shiny::observeEvent(input[[paste0('uWg_AB_RM_Y',x)]],{
			uRV$SelName_Y <- uRV$SelName_Y[uRV$SelName_Y != uRV$cols[[x]]]
			uRV$ActionDone <- FALSE
		})
		shiny::observeEvent(input[[paste0('uWg_AB_RM_F',x)]],{
			uRV$SelName_F <- uRV$SelName_F[uRV$SelName_F != uRV$cols[[x]]]
			uRV$ActionDone <- FALSE
		})
	})
	shiny::observe({
		uRV$SelType_X <- uRV$vartype[match(uRV$SelName_X,uRV$cols)]
		uRV$SelType_Y <- uRV$vartype[match(uRV$SelName_Y,uRV$cols)]
		uRV$SelType_F <- uRV$vartype[match(uRV$SelName_F,uRV$cols)]
		uRV$SelIdx_X <- match(uRV$SelName_X,uRV$cols)
		uRV$SelIdx_Y <- match(uRV$SelName_Y,uRV$cols)
		uRV$SelIdx_F <- match(uRV$SelName_F,uRV$cols)
		# message('[SelName_X]:[',uRV$SelName_X,'][SelType_X]:[',uRV$SelType_X,']')
		# message('[SelName_Y]:[',uRV$SelName_Y,'][SelType_Y]:[',uRV$SelType_Y,']')
		# message('[SelName_F]:[',uRV$SelName_F,'][SelType_F]:[',uRV$SelType_F,']')
		if (length(uRV$SelName_X)>0){
			uRV$DDBlkItem_X <- lapply(c(1:length(uRV$SelName_X)),function(x){
				shiny::actionButton(ns(paste0('uWg_AB_RM_X',uRV$SelIdx_X[[x]])), uRV$SelName_X[[x]],
					width = '100%',
					style = 'text-align: left;',
					icon = shiny::icon('remove')
				)
			})
		} else {
			uRV$DDBlkItem_X <- NULL
		}
		if (length(uRV$SelName_Y)>0){
			uRV$DDBlkItem_Y <- lapply(c(1:length(uRV$SelName_Y)),function(x){
				shiny::actionButton(ns(paste0('uWg_AB_RM_Y',uRV$SelIdx_Y[[x]])), uRV$SelName_Y[[x]],
					width = '100%',
					style = 'text-align: left;',
					icon = shiny::icon('remove')
				)
			})
		} else {
			uRV$DDBlkItem_Y <- NULL
		}
		if (length(uRV$SelName_F)>0){
			uRV$DDBlkItem_F <- lapply(c(1:length(uRV$SelName_F)),function(x){
				shiny::actionButton(ns(paste0('uWg_AB_RM_F',uRV$SelIdx_F[[x]])), uRV$SelName_F[[x]],
					width = '100%',
					style = 'text-align: left;',
					icon = shiny::icon('remove')
				)
			})
		} else {
			uRV$DDBlkItem_F <- NULL
		}
		uRV$DDBlk_X <- shinyWidgets::dropdownButton(
			inputId = ns('uWg_DDBlk_Show_X'),
			circle = FALSE,
			right = FALSE,
			icon = shiny::icon('bar-chart'),
			label = shiny::HTML(
				paste0(
					'X',
					shinydashboardPlus::dashboardLabel(
						ifelse(length(uRV$SelName_X)<=9,length(uRV$SelName_X),'+'),
						id = ns('uLbl_X'),
						status = 'danger',
						style = 'circle'
					)
				)
			),
			width = '100%',
			tooltip = FALSE,
			uRV$DDBlkItem_X
		#End of [dropdownButton]
		)
		uRV$DDBlk_Y <- shinyWidgets::dropdownButton(
			inputId = ns('uWg_DDBlk_Show_Y'),
			circle = FALSE,
			right = FALSE,
			icon = shiny::icon('line-chart'),
			label = shiny::HTML(
				paste0(
					'Y',
					shinydashboardPlus::dashboardLabel(
						ifelse(length(uRV$SelName_Y)<=9,length(uRV$SelName_Y),'+'),
						id = ns('uLbl_Y'),
						status = 'danger',
						style = 'circle'
					)
				)
			),
			width = '100%',
			tooltip = FALSE,
			uRV$DDBlkItem_Y
		#End of [dropdownButton]
		)
		uRV$DDBlk_F <- shinyWidgets::dropdownButton(
			inputId = ns('uWg_DDBlk_Show_F'),
			circle = FALSE,
			right = FALSE,
			icon = shiny::icon('filter'),
			label = shiny::HTML(
				paste0(
					'F',
					shinydashboardPlus::dashboardLabel(
						ifelse(length(uRV$SelName_F)<=9,length(uRV$SelName_F),'+'),
						id = ns('uLbl_F'),
						status = 'danger',
						style = 'circle'
					)
				)
			),
			width = '100%',
			tooltip = FALSE,
			uRV$DDBlkItem_F
		#End of [dropdownButton]
		)
	})

	#719. Create the UI
	output$uDiv_ConfVar <- renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[719][renderUI][IN][output$uDiv_ConfVar]')))
			message(ns(paste0('[719][renderUI][IN][uDiv_ConfVar][length(uRV$SelName_X)]:[',length(uRV$SelName_X),']')))
			message(ns(paste0('[719][renderUI][IN][uDiv_ConfVar][length(uRV$SelName_Y)]:[',length(uRV$SelName_Y),']')))
			message(ns(paste0('[719][renderUI][IN][uDiv_ConfVar][length(uRV$SelName_F)]:[',length(uRV$SelName_F),']')))
		}
		#Take dependency from below action (without using its value):

		#Render UI
		#Suppress output if there is no list to be displayed
		if (length(uRV$SelName_X) == 0 & length(uRV$SelName_Y) == 0 & length(uRV$SelName_F) == 0) return(NULL)

		#Create a box to display the selection result as well as the confirmation
		#[fluidRow] to ensure a tiny space against the division below it
		shiny::fluidRow(
			class = 'vsbg_fluidRow',
			tippy::tippy_this(
				ns('uWg_AB_ResetVar'),
				'Clear Selection',
				placement = 'top',
				distance = 2,
				arrow = FALSE
			),
			tippy::tippy_this(
				ns('uWg_AB_ConfirmVar'),
				'Confirm Selection',
				placement = 'top',
				distance = 2,
				arrow = FALSE
			),
			shiny::fillRow(
				flex = c(1,1),
				height = 34,
				shiny::actionButton(ns('uWg_AB_ResetVar'), 'Clear',
					width = '100%',
					class = 'btn-primary',
					style = uRV$btn_styles_AB,
					icon = shiny::icon('undo')
				),
				shiny::actionButton(ns('uWg_AB_ConfirmVar'), 'Confirm',
					width = '100%',
					class = 'btn-primary',
					style = uRV$btn_styles_AB,
					icon = shiny::icon('arrow-right')
				)
			#End of [fillRow]
			)
		#End of [fluidRow]
		)
	})

	#730. Create the UI to display the selected variables by categories
	output$uDDB_ShowVar <- renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[730][renderUI][IN][output$uDDB_ShowVar]')))
		}
		#Take dependency from below action (without using its value):

		#Render UI
		#Suppress output if there is no list to be displayed

		#Create a box to display the selection result as well as the confirmation
		#[fluidRow] to ensure a tiny space against the division below it
		shiny::fluidRow(
			id = ns('ShowVar'),
			class = 'vsbg_fluidRow',
			# shiny::br(),
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_ShowVar
			),

			tippy::tippy_this(
				ns('uWg_DDBlk_Show_X'),
				'Independents',
				placement = 'top',
				distance = 2,
				arrow = FALSE
			),
			tippy::tippy_this(
				ns('uWg_DDBlk_Show_Y'),
				'Dependents',
				placement = 'top',
				distance = 2,
				arrow = FALSE
			),
			tippy::tippy_this(
				ns('uWg_DDBlk_Show_F'),
				'Filters',
				placement = 'top',
				distance = 2,
				arrow = FALSE
			),
			shiny::fillRow(
				flex = c(1,1,1),
				height = 34,
				uRV$DDBlk_X,
				uRV$DDBlk_Y,
				uRV$DDBlk_F
			#End of [fillRow]
			)
		#End of [fluidRow]
		)
	})

	#780. Accordion to display the variables
	output$uAcd_SelVars <- renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[780][renderUI][IN][output$uAcd_SelVars]')))
			message(ns(paste0('[780][renderUI][IN][uAcd_SelVars][is.null(input$uWg_rGB_VarGrps)]:[',isolate(is.null(input$uWg_rGB_VarGrps)),']')))
		}
		#Suppress output if there is no list to be displayed
		if (is.null(input$uWg_rGB_VarGrps)) return(NULL)

		#Localize the selection items
		usrAcd_items <- uRV$GrpMthd[[input$uWg_rGB_VarGrps]]
		usrAcd_kitem <- length(usrAcd_items)
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[780][renderUI][ASSIGN][usrAcd_items]:[',usrAcd_items,']')))
			message(ns(paste0('[780][renderUI][ASSIGN][usrAcd_kitem]:[',usrAcd_kitem,']')))
		}

		#Create a box as container of UI elements for the entire module
		usrAcd_main <- bsplus::bs_accordion(ns('uWg_Acd_vsbg'))

		for (x in 1:usrAcd_kitem){
			usrAcd_cnt <- NULL
			if (length(usrAcd_items[[x]]$cols)>0){
				usrAcd_cnt <- lapply(c(1:length(usrAcd_items[[x]]$cols)),function(y){
					#Create the UI
					shiny::tagList(
						#Below style is applied to all buttons within current division
						#[Quote: https://www.w3school.com.cn/css/css_syntax_attribute_selector.asp ]
						tags$style(
							type = 'text/css',
							paste0(
								'[id="',ns(paste0('uWg_DDBtn_',usrAcd_items[[x]]$coli[[y]])),'"] {width: 100%; text-align: left; overflow: hidden;}'
							)
						),
						shinyWidgets::dropdownButton(
							inputId = ns(paste0('uWg_DDBtn_',usrAcd_items[[x]]$coli[[y]])),
							circle = FALSE,
							right = FALSE,
							label = paste0('[',usrAcd_items[[x]]$coliC[[y]],'] ',usrAcd_items[[x]]$cols[[y]]),
							width = '100%',
							tooltip = FALSE,
							shiny::actionButton(ns(paste0('uWg_AB_X',usrAcd_items[[x]]$coli[[y]])),
								label = 'Add to X',
								icon = shiny::icon('bar-chart'),
								width = '100%',
								# style = 'text-align: left;'
								style = 'text-align: left;'
							),
							shiny::actionButton(ns(paste0('uWg_AB_Y',usrAcd_items[[x]]$coli[[y]])),
								label = 'Add to Y',
								icon = shiny::icon('line-chart'),
								width = '100%',
								# style = 'text-align: left;'
								style = 'text-align: left;'
							),
							shiny::actionButton(ns(paste0('uWg_AB_F',usrAcd_items[[x]]$coli[[y]])),
								label = 'Add to Filter',
								icon = shiny::icon('filter'),
								width = '100%',
								# style = 'text-align: left;'
								style = 'text-align: left;'
							)
						#End of [dropdownButton]
						),
						tippy::tippy_this(
							ns(paste0('uWg_DDBtn_',usrAcd_items[[x]]$coli[[y]])),
							usrAcd_items[[x]]$cols[[y]],
							placement = 'right',
							distance = 2,
							arrow = FALSE
						)
					#End of [tagList]
					)
				#End of [lapply]
				})
			#End of [if]
			}

			usrAcd_main <- usrAcd_main %>%
				bsplus::bs_set_opts(panel_type = 'default' , use_heading_link = TRUE) %>%
				bsplus::bs_append(
					title = shiny::tagList(
						#Below style is identical to the default one in [bsplus], but it shows the way to customize its style.
						shiny::tags$style(
							type = 'text/css',
							paste0(
								'.panel-title {text-align: center;}'
							)
						),
						usrAcd_items[[x]]$nm
					),
					content = usrAcd_cnt
				)
		#End of [for (usrAcd_kitem)]
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
						'.panel-body {padding: 10px;}'
					)
				),
				usrAcd_main
			)
		)
	#End of [renderUI] of [180]
	})

	#500. Event Trigger
	#510. Reset all selections in one action
	shiny::observeEvent(input$uWg_AB_ResetVar,{
		uRV$SelName_X <- NULL
		uRV$SelName_Y <- NULL
		uRV$SelName_F <- NULL
		uRV$ActionDone <- FALSE
	})

	#599. Determine the output value
	shiny::observeEvent(input$uWg_AB_ConfirmVar,{
		if (input$uWg_AB_ConfirmVar == 0) return()
		uRV$outXName <- uRV$SelName_X
		uRV$outXType <- uRV$SelType_X
		uRV$outYName <- uRV$SelName_Y
		uRV$outYType <- uRV$SelType_Y
		uRV$outFName <- uRV$SelName_F
		uRV$outFType <- uRV$SelType_F

		#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
		# finish(finish() + 1)
		finish(input$uWg_AB_ConfirmVar)
		if (is.null(uRV$SelName_X)) return()
		uRV$ActionDone <- TRUE
	})

	#999. Return the result
	#Next time I may try to append values as instructed below:
	#[Quote: https://community.rstudio.com/t/append-multiple-reactive-output-of-a-shiny-module-to-an-existing-reactivevalue-object-in-the-app/36985/2 ]
	return(
		list(
			CallCounter = shiny::reactive({finish()}),
			ActionDone = shiny::reactive({uRV$ActionDone}),
			EnvVariables = shiny::reactive({uRV}),
			VarXName = shiny::reactive({uRV$outXName}),
			VarXType = shiny::reactive({uRV$outXType}),
			VarYName = shiny::reactive({uRV$outYName}),
			VarYType = shiny::reactive({uRV$outYType}),
			VarFName = shiny::reactive({uRV$outFName}),
			VarFType = shiny::reactive({uRV$outFType})
		)
	)
}

#[Full Test Program;]
if (FALSE){
	if (interactive()){
		lst_pkg <- c( 'dplyr' , 'haven' , 'lubridate' ,
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' ,
			'shinyWidgets' , 'styler' , 'shinyAce' , 'shinyjqui' , 'shinyEffects' , 'bsplus' , 'tippy'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		jqcore <- list.files( paste0(omniR,'\\Styles') , '^jquery-.+\\.js$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE , include.dirs = TRUE ) %>%
			normalizePath()

		ui <- shinydashboardPlus::dashboardPagePlus(
			shinyjs::useShinyjs(),
			header = shinydashboardPlus::dashboardHeaderPlus(),
			sidebar = shinydashboard::dashboardSidebar(),
			body = shinydashboard::dashboardBody(
				shiny::fluidPage(
					shiny::column(width = 4,
						UM_varSelectByGroup_ui('uMod_vsbg')
					)
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$VarSel <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL}),
				VarXName = shiny::reactive({NULL}),
				VarXType = shiny::reactive({NULL}),
				VarYName = shiny::reactive({NULL}),
				VarYType = shiny::reactive({NULL}),
				VarFName = shiny::reactive({NULL}),
				VarFType = shiny::reactive({NULL})
			)

			modout$test_df <- haven::read_sas(
				'D:/R/Project/myApp/Data/test_DBQC_check_src.sas7bdat',
				encoding = 'GB2312'
			)

			observe({
				modout$VarSel <- shiny::callModule(
					UM_varSelectByGroup_svr,
					'uMod_vsbg',
					fDebug = FALSE,
					indat = modout$test_df,
					jqueryCore = jqcore
				)
			})
			shiny::observeEvent(modout$VarSel$CallCounter(),{
				message('[VarSel$CallCounter()]:',modout$VarSel$CallCounter())
				message('[VarSel$ActionDone()]:',modout$VarSel$ActionDone())
				message('[VarSel$EnvVariables]:')
				message('[VarSel$EnvVariables()$cols]:',modout$VarSel$EnvVariables()$cols)
				message('[VarSel$VarXName()]:',modout$VarSel$VarXName())
				message('[VarSel$VarXType()]:',modout$VarSel$VarXType())
				message('[VarSel$VarYName()]:',modout$VarSel$VarYName())
				message('[VarSel$VarYType()]:',modout$VarSel$VarYType())
				message('[VarSel$VarFName()]:',modout$VarSel$VarFName())
				message('[VarSel$VarFType()]:',modout$VarSel$VarFType())
			})
		}

		shinyApp(ui, server)
	}

}
