# User Defined Module: [Conduct analysis upon single variable for the input file]
# [Quote: https://shiny.rstudio.com/articles/isolation.html ]
# [Dependency]: acts as a trigger for when the reactive expression should re-calculate
# Required User-specified parameters:

# [Quote: 'SVA': Single Variable Analysis]
# [Quote: 'uMod': Caller of User Defined Modules]
# [Quote: 'uWg': User defined Widgets]
# [Quote: 'AB': User defined actionButton]
# [Quote: 'sI': User defined selectInput]
# [Quote: 'mk': Marker]

# Required User-specified modules:
# [Quote:[omniR$UsrShinyModules$Ops$UM_LoadXlSheet.r]]
# [Quote:[omniR$UsrShinyModules$Ops$UM_LoadSASDat.r]]
# [Quote:[omniR$UsrShinyModules$Ops$UM_varSelectByGroup.r]]
# [Quote:[omniR$UsrShinyModules$Ops$UM_SingleVarStats.r]]

# Required User-specified functions:
# [Quote:[omniR$Visualization$Input_boxCollapsed.r]]

UM_SingleVarAnalysis_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	styles_UI <- shiny::HTML(
		paste0(
			#Below change upon the class is to shrink the gaps between the two columns of the entire UI
			'.col-sm-12 {',
				'padding-left: 7px;',
				'padding-right: 7px;',
			'}',
			#Below change upon the class is to shrink the gaps between the upper and lower boxes of the entire UI
			'.box {',
				'border-radius: 1px;',
				'margin-bottom: 14px;',
			'}'
		)
	)

	#999. Output the UI
	shiny::tagList(
		#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
		shiny::tags$style(
			type = 'text/css',
			styles_UI
		),

		shiny::column(width = 3,style = 'padding-left: 0px; padding-right: 0px;',
			#Add box on top left of the page for file uploading.
			shiny::uiOutput(ns('uBox_DataUpload')),
			#Add a new UI for variable selection when necessary
			shiny::uiOutput(ns('uBox_VarSel'))
		#End of [column]
		),

		shiny::column(width = 9,style = 'padding-left: 0px; padding-right: 0px;',
			#Add box on top right of the page to display file specifications.
			shiny::uiOutput(ns('uBox_DataDisplay')),
			#Add box for concentration analysis
			shiny::uiOutput(ns('uBox_SVS'))
		#End of [column]
		)
	#End of [list]
	)
}

UM_SingleVarAnalysis_svr <- function(input,output,session,
	fDebug = FALSE,jqueryCore = 'http://code.jquery.com/jquery-3.4.1.js',
	reportTpl = NULL,
	themecolorset = NULL
){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	uRV$ActionDone <- FALSE
	uRV$outRef <- list()
	uRV$outFilter <- list()
	uRV$outRpt <- list()
	uRV_finish <- shiny::reactiveVal(0)
	uRV$AnlData <- shiny::reactiveValues(
		CallCounter = shiny::reactiveVal(0),
		ActionDone = shiny::reactive({FALSE}),
		EnvVariables = shiny::reactive({NULL}),
		outdat = shiny::reactive({NULL})
	)
	uRV$VarSel <- shiny::reactiveValues(
		CallCounter = shiny::reactiveVal(0),
		ActionDone = shiny::reactive({FALSE}),
		EnvVariables = shiny::reactive({NULL}),
		VarXName = shiny::reactive({NULL}),
		VarXType = shiny::reactive({NULL}),
		VarFName = shiny::reactive({NULL}),
		VarFType = shiny::reactive({NULL})
	)
	uRV$SVS <- shiny::reactiveValues(
		CallCounter = shiny::reactiveVal(0),
		ActionDone = shiny::reactive({FALSE}),
		EnvVariables = shiny::reactive({NULL})
	)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns('[Module Call][UM_SingleVarAnalysis]'))
	}

	#010. Prepare the list of Data Type Selector (This list is internal hence is NOT a reactive value)
	#[Quote: We can use the form: [get(paste0('test_fn_',fnname))()] to call different functions dynamically]
	#[Quote:[omniR$UsrShinyModules$Ops$UM_LoadXlSheet.r]]
	#[Quote:[omniR$UsrShinyModules$Ops$UM_LoadSASDat.r]]
	uRV$Mod_Selector <- list(
		EXCEL = list(
			sI_Opts = c('EXCEL File' = 'XLSXFile'),
			fn_ui_upload = UM_LoadXlSheet_ui_upload,
			fn_ui_display = UM_LoadXlSheet_ui_display,
			fn_svr = UM_LoadXlSheet_svr
		),
		SAS = list(
			sI_Opts = c('SAS Data' = 'SASData'),
			fn_ui_upload = UM_LoadSASDat_ui_upload,
			fn_ui_display = UM_LoadSASDat_ui_display,
			fn_svr = UM_LoadSASDat_svr
		),
		PKG = list(
			sI_Opts = c('From Packages' = 'DfFrPkg'),
			fn_ui_upload = UM_LoadDfFrPkg_ui_upload,
			fn_ui_display = UM_LoadDfFrPkg_ui_display,
			fn_svr = UM_LoadDfFrPkg_svr
		)
	)

	#050. Prepare the choices in the Data Type Selector
	tmpOpts <- lapply(uRV$Mod_Selector, function(m){ m$sI_Opts })
	#Below is to remove the first-level names of the elements
	names(tmpOpts) <- NULL
	uRV$DType_Choice <- unlist(tmpOpts)

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
		'padding: 6px;'
	)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			'.sva_Box {padding: 2px 15px 2px 15px;}',
			'.sva_fluidRow {padding: 2px 15px 2px 15px;}',
			'.sva_Column {',
				'padding: 0px;',
				'text-align: left;',
				'vertical-align: middle;',
			'}'
		)
	)

	#500. Observers
	#Important!!!: When using [shinyjs], ID should not be enclosed by [ns] function: [ns('uWg_pS_DHeader')]
	#Important!!!: It is literally unnecessary to call [ns] function during the nesting of modules
	#[Quote: http://shiny.rstudio.com/articles/modules.html ]
	#501. Flush the previously activated server
	#[Quote: https://github.com/rstudio/shiny/issues/2432 ]
	#The idea of flushing the unused reactive values is NOT successful.
	uRV$flush_mem <- shiny::observe(
		{
			#100. Take dependencies
			#[shiny::req] validates [NULL/''/0] values
			shiny::req(input$uWg_AB_DataType)
			shiny::req(uRV$AnlData_final)
			shiny::req(uRV$SelectedVar)

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[501][observe][IN][input$uWg_AB_DataType]:',input$uWg_AB_DataType)))
					message(ns(paste0('[501][observe][IN][uRV$AnlData_final]:',str(uRV$AnlData_final))))
					message(ns(paste0('[501][observe][IN][uRV$SelectedVar]:<',paste0(uRV$SelectedVar,collapse = '>,<'),'>')))
				}
				#010. Return if the condition is not valid

				#300. Assign the refreshed values
				shiny:::flushReact()
			#End of [isolate]
			})
		}
		,suspended = TRUE
		,label = ns('[501]Flush reactive values')
		,priority = 9999
	)

	#510. When user clicks upon the Data Type Selector
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_DataType

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[510][observe][IN][input$uWg_AB_DataType]:',input$uWg_AB_DataType)))
					message(ns(paste0('[510][observe][IN][input$uWg_sI_DataType]:',input$uWg_sI_DataType)))
				}
				#200. Skip if no Data Type is selected
				#Below two statements are bypassed, for we applied [shiny::req]
				if (is.null(input$uWg_AB_DataType)) return()
				if (input$uWg_AB_DataType == 0) return()
				if (is.null(input$uWg_sI_DataType)) return()

				#300. Assign value to the variables
				if (is.null(uRV$SelectedDType)) uRV$SelectedDType <- input$uWg_sI_DataType
				else {
					if (uRV$SelectedDType == input$uWg_sI_DataType) return()
					else uRV$SelectedDType <- input$uWg_sI_DataType
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[510]Whethere the selected Data Type is changed')
		# ,priority = 10
	)

	#515. When the Data Type is changed
	shiny::observe(
		{
			#100. Take dependencies
			uRV$SelectedDType

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[515][observe][IN][uRV$SelectedDType]:',uRV$SelectedDType)))
				}
				#010. Take dependencies
				if (is.null(uRV$SelectedDType)) return()

				#100. Hide all other UI
				shinyjs::hideElement(id = 'uBox_VSBG')
				shinyjs::hideElement(id = 'uBox_Vsvs')

				#500. Start over the server for data upload of the dedicated Data Type in new random [ns] ID
				set.seed(as.numeric(Sys.time()))
				uRV$ID_DataSel <- paste0('uMod_DUp','_',uRV$SelectedDType,floor(runif(1) * 10^6))
				cfg <- list()
				cfg$SelType <- uRV$SelectedDType
				uRV$AnlData <- shiny::callModule(
					uRV$Mod_Selector[[which(uRV$DType_Choice==uRV$SelectedDType)]]$fn_svr,
					uRV$ID_DataSel,
					fDebug = fDebug,
					inCfg = cfg
				)

				#510. Identify the active UI ID for frontend

				#800. Assign value to the variables
				uRV$AnlData_final <- NULL
				uRV$VarSel <- shiny::reactiveValues(
					CallCounter = shiny::reactiveVal(0),
					ActionDone = shiny::reactive({FALSE}),
					EnvVariables = shiny::reactive({NULL}),
					VarXName = shiny::reactive({NULL}),
					VarXType = shiny::reactive({NULL}),
					VarFName = shiny::reactive({NULL}),
					VarFType = shiny::reactive({NULL})
				)
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[515][observe][OUT][uRV$ID_DataSel]:',uRV$ID_DataSel)))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[515]Start a new server for the upload of new Data Type')
		# ,priority = 985
	)

	#520. When user completes the data upload
	#521. Check whether the Variable Selection module has been completed
	shiny::observe(
		{
			#100. Take dependencies
			uRV$AnlData$CallCounter()

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[521][observe][IN][uRV$AnlData$CallCounter()]:',uRV$AnlData$CallCounter())))
				}
				#010. Return if the condition is not valid

				#300. Assign the refreshed values
				if (is.null(uRV$AnlData_Counter)) uRV$AnlData_Counter <- uRV$AnlData$CallCounter()
				else {
					if (uRV$AnlData_Counter == uRV$AnlData$CallCounter()) return()
					else uRV$AnlData_Counter <- uRV$AnlData_Counter + 1
				}
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[521][observe][OUT][uRV$AnlData_Counter]:',uRV$AnlData_Counter)))
				}
			#End of [isolate]
			})
		}
		,label = ns(paste0('[521]Observe: uRV$AnlData$CallCounter()'))
		# ,priority = 590
	)

	#525. Check whether the times of each call of the modules has been increased
	shiny::observe(
		{
			#100. Take dependencies
			uRV$AnlData_Counter

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[525][observe][MID][uRV$AnlData_Counter]:',uRV$AnlData_Counter)))
					message(ns(paste0('[525][observe][MID][is.function(uRV$AnlData$outdat)]:',is.function(uRV$AnlData$outdat))))
				}
				#010. Take dependencies
				if (is.null(uRV$AnlData_Counter)) return()
				if (!is.function(uRV$AnlData$outdat)) return()
				if (is.null(uRV$AnlData$outdat())) return()

				#400. Determine the new data for analysis
				uRV$AnlData_final <- uRV$AnlData$outdat()
				uRV$outRef <- uRV$AnlData$EnvVariables()$OutCfg
				if (fDebug){
					message(ns(paste0('[525][observe][OUT][uRV$outRef]:',length(uRV$outRef))))
					message(ns(paste0('[525][observe][OUT][uRV$AnlData_final]:')))
					dplyr::glimpse(uRV$AnlData_final)
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns(paste0('[525]Observe: uRV$AnlData_Counter'))
		# ,priority = 580
	)

	#540. When the final data is settled
	#The reason why we cannot combine this observer to the above one is that [CallCounter] is reset to 0 when a new call of the module is conducted.
	shiny::observe(
		{
			#100. Take dependencies
			uRV$AnlData_final

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[540][observe][IN][uRV$AnlData_final]:',str(uRV$AnlData_final))))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$AnlData_final)) return()

				#300. Assign the refreshed values
				uRV$VarSel_VarXName <- NULL
				uRV$VarSel_VarXType <- NULL
				uRV$VarSel_VarFName <- NULL
				uRV$VarSel_VarFType <- NULL
				set.seed(as.numeric(Sys.time()))
				uRV$ID_VarSel <- paste0('uMod_VarSel',floor(runif(1) * 10^6))
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[540][observe][OUT][uRV$ID_VarSel]:',uRV$ID_VarSel)))
				}
			#End of [isolate]
			})
		}
		,label = ns('[540]Create ID for the module Variable Selection to be called')
		# ,priority = 690
	)

	#545. When the ID of the Variable Selection module is settled
	shiny::observe(
		{
			#100. Take dependencies
			uRV$ID_VarSel

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[545][observe][IN][uRV$ID_VarSel]:',uRV$ID_VarSel)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$ID_VarSel)) return()

				#900. Start the server
				#[Quote:[omniR$UsrShinyModules$Ops$UM_varSelectByGroup.r]]
				uRV$VarSel <- shiny::callModule(
					UM_varSelectByGroup_svr,
					uRV$ID_VarSel,
					fDebug = fDebug,
					indat = uRV$AnlData_final,
					jqueryCore = jqueryCore
				)

				#900. Change the UI for Variable Selection
				shinyjs::showElement(id = 'uBox_VSBG')
				shinyjs::hideElement(id = 'uBox_Vsvs')
			#End of [isolate]
			})
		}
		,label = ns('[545]Call module [UM_varSelectByGroup_svr]')
		# ,priority = 690
	)

	#550. Check whether the Variable Selection module has been completed
	shiny::observe(
		{
			#100. Take dependencies
			uRV$VarSel$CallCounter()

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[550][observe][IN][uRV$VarSel$CallCounter()]:',uRV$VarSel$CallCounter())))
				}
				#010. Return if the condition is not valid

				#300. Assign the refreshed values
				if (is.null(uRV$SelectedVar)) uRV$SelectedVar <- uRV$VarSel$CallCounter()
				else {
					if (uRV$SelectedVar == uRV$VarSel$CallCounter()) return()
					else uRV$SelectedVar <- uRV$SelectedVar + 1
				}
			#End of [isolate]
			})
		}
		,label = ns('[550]VarSel: Monitor module completion')
		# ,priority = 590
	)

	#560. When user confirms the variable selection
	shiny::observe(
		{
			#100. Take dependencies
			uRV$SelectedVar

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[560][observe][IN][uRV$SelectedVar]:',uRV$SelectedVar)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$SelectedVar)) return()
				if (uRV$SelectedVar == 0) return()
				if (!is.function(uRV$VarSel$VarXName)) return()
				if (is.null(uRV$VarSel$VarXName())) return()
				# message(uRV$VarSel$VarXName())
				# message(uRV$VarSel$VarXType())

				#300. Assign the refreshed values
				uRV$VarSel_VarXName <- uRV$VarSel$VarXName()
				uRV$VarSel_VarXType <- uRV$VarSel$VarXType()
				uRV$VarSel_VarFName <- uRV$VarSel$VarFName()
				uRV$VarSel_VarFType <- uRV$VarSel$VarFType()
				set.seed(as.numeric(Sys.time()))
				uRV$ID_SVS <- paste0('uMod_SVS',floor(runif(1) * 10^6))

				#600. Collapse the dedicated boxes to save space on the screen
				#[Quote: https://stackanswers.net/questions/r-shinyjs-shinydashboard-box-uncollapse-on-radionbuttons-input ]
				Collapsed_DUp <- F
				Collapsed_DDis <- F
				if (!is.null(input$uInput_Status_DUp)) Collapsed_DUp <- input$uInput_Status_DUp
				if (!is.null(input$uInput_Status_DDis)) Collapsed_DDis <- input$uInput_Status_DDis
				if (!Collapsed_DUp) shinyjs::js$collapse(ns("uBox_DUp"))
				if (!Collapsed_DDis) shinyjs::js$collapse(ns("uBox_DDis"))

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[560][observe][OUT][uRV$VarSel_VarXName]:<',paste0(uRV$VarSel_VarXName,collapse = '>,<'),'>')))
					message(ns(paste0('[560][observe][OUT][uRV$VarSel_VarXType]:<',paste0(uRV$VarSel_VarXType,collapse = '>,<'),'>')))
					message(ns(paste0('[560][observe][OUT][uRV$VarSel_VarFName]:<',paste0(uRV$VarSel_VarFName,collapse = '>,<'),'>')))
					message(ns(paste0('[560][observe][OUT][uRV$VarSel_VarFType]:<',paste0(uRV$VarSel_VarFType,collapse = '>,<'),'>')))
					message(ns(paste0('[560][observe][OUT][uRV$ID_SVS]:',uRV$ID_SVS)))
				}
			#End of [isolate]
			})
		}
		,label = ns('[560]VarSel_setvalues')
		# ,priority = 590
	)

	#590. Server for Stats analysis
	#591. Start server
	shiny::observe(
		{
			#100. Take dependencies
			uRV$ID_SVS

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[591][observe][IN][uRV$AnlData_final]:',str(uRV$AnlData_final))))
					message(ns(paste0('[591][observe][IN][uRV$VarSel_VarXName]:<',paste0(uRV$VarSel_VarXName,collapse = '>,<'),'>')))
					message(ns(paste0('[591][observe][IN][uRV$VarSel_VarXType]:<',paste0(uRV$VarSel_VarXType,collapse = '>,<'),'>')))
					message(ns(paste0('[591][observe][IN][uRV$VarSel_VarFName]:<',paste0(uRV$VarSel_VarFName,collapse = '>,<'),'>')))
					message(ns(paste0('[591][observe][IN][uRV$VarSel_VarFType]:<',paste0(uRV$VarSel_VarFType,collapse = '>,<'),'>')))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$ID_SVS)){
					shinyjs::hideElement(id = 'uBox_Vsvs')
					return()
				}

				#100. Change the UI for Variable Selection
				shinyjs::showElement(id = 'uBox_Vsvs')

				#300. Assign the refreshed values

				#900. Start the server
				#[Quote:[omniR$UsrShinyModules$Ops$UM_SingleVarStats.r]]
				uRV$SVS <- shiny::callModule(
					UM_SingleVarStats_svr,
					uRV$ID_SVS,
					fDebug = fDebug,
					indat = uRV$AnlData_final,
					invar = uRV$VarSel_VarXName,
					invartype = uRV$VarSel_VarXType,
					groupbyvar = uRV$VarSel_VarFName,
					groupbyvartype = uRV$VarSel_VarFType,
					themecolorset = themecolorset
				)
			#End of [isolate]
			})
		}
		,label = ns('[591]Launch new server of module [UM_SingleVarStats_svr]')
		# ,priority = 193
	)

	#595. Check whether the Single Variable Stats module has been completed
	shiny::observe(
		{
			#100. Take dependencies
			uRV$SVS$CallCounter()

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[595][observe][IN][uRV$SVS$CallCounter()]:',uRV$SVS$CallCounter())))
				}
				#010. Return if the condition is not valid

				#300. Assign the refreshed values
				if (is.null(uRV$SVS_Done)) uRV$SVS_Done <- uRV$SVS$CallCounter()
				else {
					if (uRV$SVS_Done == uRV$SVS$CallCounter()) return()
					else uRV$SVS_Done <- uRV$SVS_Done + 1
				}
			#End of [isolate]
			})
		}
		,label = ns('[595]SVS: Monitor module completion')
		# ,priority = 150
	)

	#597. When user confirms the output
	shiny::observe(
		{
			#100. Take dependencies
			uRV$SVS_Done

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[597][observe][IN][uRV$SVS_Done]:',uRV$SVS_Done)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$SVS_Done)) return()
				if (uRV$SVS_Done == 0) return()

				#300. Assign the refreshed values
				uRV$outFilter <- uRV$SVS$EnvVariables()$outFilter
				uRV$outRpt <- uRV$SVS$EnvVariables()$outRpt
				if (fDebug){
					message(ns(paste0('[597][observe][OUT][uRV$outFilter]:',length(uRV$outFilter))))
					message(ns(paste0('[597][observe][OUT][uRV$outRpt]:',length(uRV$outRpt))))
				}
			#End of [isolate]
			})
		}
		,label = ns('[597]Collect data for standalone report')
		# ,priority = 130
	)

	#700. Prepare dynamic UIs
	#720. Main UI for uploading
	output$uBox_DataUpload <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[720][renderUI][IN][uBox_DataUpload]:')))
		}

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			# [Quote:[omniR$Visualization$Input_boxCollapsed.r]]
			Input_boxCollapsed(inputId = ns("uInput_Status_DUp"), boxId = ns("uBox_DUp")),
			shinydashboardPlus::boxPlus(width = 12,
				class = 'sva_Box',
				collapsible = TRUE,
				id = ns('uBox_DUp'),
				title = 'Upload Data',
				solidHeader = FALSE,
				closable = FALSE,

				shiny::fluidRow(
					class = 'sva_fluidRow',
					shiny::fillRow(
						flex = c(1,NA),
						height = 34,
						shinyWidgets::pickerInput(ns('uWg_sI_DataType'),
							NULL,
							width = '100%',
							options = shinyWidgets::pickerOptions(
								# title = '(Choose one file)',
								liveSearch = TRUE,
								liveSearchNormalize = TRUE,
								liveSearchPlaceholder = 'Search...',
								mobile = TRUE
							),
							choices = uRV$DType_Choice
						),
						shiny::actionButton(ns('uWg_AB_DataType'), NULL,
							width = 34,
							class = 'btn-primary',
							style = uRV$btn_styles_AB,
							icon = shiny::icon('arrow-right')
						)
					#End of [fillRow]
					)
				#End of [fluidRow]
				),
				#Confirm selection
				shiny::uiOutput(ns('uDiv_DUpload'))
			#End of [box]
			)
		#End of [tagList]
		)
	#End of [renderUI] of [720]
	})

	#721. Create the UI for data upload
	output$uDiv_DUpload <- shiny::renderUI({
		#100. Take dependency
		uRV$ID_DataSel

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::isolate({
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[721][renderUI][IN][uDiv_DUpload]:')))
			}
			#010. Return if the condition is not valid
			if (is.null(uRV$ID_DataSel)) return(NULL)

			#500. Display the UI in terms of the user selection
			uRV$Mod_Selector[[which(uRV$DType_Choice==input$uWg_sI_DataType)]]$fn_ui_upload(ns(uRV$ID_DataSel))
		#End of [isolate]
		})
	#End of [renderUI] of [721]
	})

	#730. Main UI for displaying data details
	output$uBox_DataDisplay <- shiny::renderUI({
		#100. Take dependency
		uRV$ID_DataSel

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::isolate({
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[730][renderUI][IN][uBox_DataDisplay]:')))
			}
			#010. Return if the condition is not valid
			if (is.null(uRV$ID_DataSel)) return(NULL)

			#900. Create UI
			shiny::tagList(
				#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
				shiny::tags$style(
					type = 'text/css',
					uRV$styles_final
				),

				# [Quote:[omniR$Visualization$Input_boxCollapsed.r]]
				Input_boxCollapsed(inputId = ns("uInput_Status_DDis"), boxId = ns("uBox_DDis")),
				shinydashboardPlus::boxPlus(width = 12,
					class = 'sva_Box',
					collapsible = TRUE,
					id = ns('uBox_DDis'),
					title = 'Data Attributes',
					solidHeader = FALSE,
					closable = FALSE,

					uRV$Mod_Selector[[which(uRV$DType_Choice==input$uWg_sI_DataType)]]$fn_ui_display(ns(uRV$ID_DataSel))
				#End of [box]
				)
			#End of [tagList]
			)
		#End of [isolate]
		})
	#End of [renderUI] of [730]
	})

	#750. UI for variable selection
	output$uBox_VarSel <- shiny::renderUI({
		#100. Take dependency
		uRV$ID_VarSel

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[750][renderUI][IN][uBox_VarSel]:')))
		}
		#010. Return if the condition is not valid
		if (is.null(uRV$ID_VarSel)) return(NULL)

		#900. Create UI
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			shinydashboardPlus::boxPlus(width = 12,
				class = 'sva_Box',
				collapsible = TRUE,
				id = ns('uBox_VSBG'),
				title = 'Variable Selection',
				solidHeader = FALSE,
				closable = FALSE,

				UM_varSelectByGroup_ui(ns(uRV$ID_VarSel))
			#End of [box]
			)
		#End of [tagList]
		)
	#End of [renderUI] of [750]
	})

	#780. Create the UI once any variables are selected for analysis
	output$uBox_SVS <- shiny::renderUI({
		#100. Take dependency
		uRV$ID_SVS

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[780][renderUI][IN][uBox_SVS]:')))
		}
		#010. Return if the condition is not valid
		if (is.null(uRV$ID_SVS)) return(NULL)

		#900. Create UI
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			shinydashboardPlus::boxPlus(width = 12,
				class = 'sva_Box',
				collapsible = TRUE,
				id = ns('uBox_Vsvs'),
				title = paste0('Stats of Variables in respective boxes'),
				solidHeader = FALSE,
				closable = FALSE,
				enable_dropdown = TRUE,
				dropdown_menu = shinydashboardPlus::dropdownItemList(
					tippy::tippy_this(
						ns('uWg_AB_SaveReport'),
						'Save Snapshot as Report',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::actionButton(ns('uWg_AB_SaveReport'), 'Save Report',
						style = uRV$btn_styles_attr,
						icon = shiny::icon('print')
					),
					shiny::downloadButton(ns('Save'),'Download Report',
						style = uRV$btn_styles_attr,
						icon = shiny::icon('download')
					)
				),

				UM_SingleVarStats_ui(ns(uRV$ID_SVS))
			#End of [box]
			)
		#End of [tagList]
		)
	#End of [renderUI] of [780]
	})

	#800. Event Trigger
	#899. Determine the output value
	#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_SaveReport

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[899][observe][IN][input$uWg_AB_SaveReport]:',input$uWg_AB_SaveReport)))
					message(ns(paste0('[899][observe][IN][uRV$outRef]:',length(uRV$outRef))))
					message(ns(paste0('[899][observe][IN][uRV$outFilter]:',length(uRV$outFilter))))
					message(ns(paste0('[899][observe][IN][uRV$outRpt]:',length(uRV$outRpt))))
				}
				if (is.null(input$uWg_AB_SaveReport)) return()
				if (input$uWg_AB_SaveReport == 0) return()
				uRV_finish(input$uWg_AB_SaveReport)
				uRV$ActionDone <- TRUE

				#200. Collect data attributes
				if (is.null(uRV$outRpt)){
					shinyWidgets::confirmSweetAlert(session,"uWg_cSA_NoRpt",
						title = "请返回",
						text = "生成报告前请在图表页面点击（保存）按钮，或者为图表添加书签。",
						type = "question",
						html = TRUE,
						#Below option is only applied since [shinyWidgets:0.4.8.930]
						btn_colors = c(themecolorset$s07$p[[1]],themecolorset$s03$d),
						btn_labels = c("取消","确定")
					)
					return()
				}

				#900. Create the universal outputs
				uRV$knitr_params <- list(
					ref = uRV$outRef,
					flt = uRV$outFilter,
					rpt = uRV$outRpt
				)
				#[Quote: https://shiny.rstudio.com/articles/generating-reports.html ]
				output$Save <- shiny::downloadHandler(
					filename = 'SingleVariableAnalysis.html',
					content = function(file){
						tempReport <- file.path(tempdir(),'SVA.Rmd')
						file.copy(reportTpl, tempReport, overwrite = TRUE)
						params <- uRV$knitr_params
						rmarkdown::render(
							tempReport,
							output_file = file,
							params = params,
							envir = new.env(parent = globalenv())
						)
					}
				)
				# shinyjs::click('Save')
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
		lst_pkg <- c( 'tmcn' , 'dplyr' , 'readr' , 'RCurl' , "lubridate" ,
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' , 'shinyWidgets' , 'tippy' ,
			 'DT' , 'echarts4r'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		omniR <- 'D:\\R\\omniR'
		jqcore <- list.files( paste0(omniR,'\\Styles') , '^jquery-.+\\.js$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE , include.dirs = TRUE ) %>%
			normalizePath()
		omniR_Files <- list.files( omniR , '^.+\\.r$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE , include.dirs = TRUE ) %>%
			normalizePath()
		if (length(omniR_Files)>0){
			o_enc <- sapply(omniR_Files, function(x){guess_encoding(x)$encoding[1]})
			for (i in 1:length(omniR_Files)){source(omniR_Files[i],encoding = o_enc[i])}
		}
		source('D:\\R\\Project\\myApp\\Func\\UI\\theme_color_sets.r')

		ui <- shinydashboardPlus::dashboardPagePlus(
			header = shinydashboardPlus::dashboardHeaderPlus(),
			sidebar = shinydashboard::dashboardSidebar(),
			body = shinydashboard::dashboardBody(
				shinyjs::useShinyjs(),
				shinyjs::extendShinyjs(script = paste0(omniR,'\\UsrShinyModules\\shinyjsExtension.js')),
				shiny::fluidPage(
					UM_SingleVarAnalysis_ui('uMod_sva')
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$SVA <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL})
			)

			observe({
				modout$SVA <- shiny::callModule(
					UM_SingleVarAnalysis_svr,
					'uMod_sva',
					fDebug = FALSE,
					jqueryCore = jqcore,
					reportTpl = paste0(omniR,"\\UsrShinyModules\\SingleVarAnalysis.Rmd"),
					themecolorset = myApp_themecolorset
				)
			})
			shiny::observeEvent(modout$SVA$CallCounter(),{
				if (modout$SVA$CallCounter() == 0) return()
				message('[SVA$CallCounter()]:',modout$SVA$CallCounter())
				params_global <<- modout$SVA$EnvVariables()$knitr_params
			})
		}

		shinyApp(ui, server)
	}

}

if (FALSE){
	if (TRUE){
		reportTpl <- paste0(omniR,"\\UsrShinyModules\\SingleVarAnalysis.Rmd")
		tempReport <- file.path(tempdir(),'SVA.Rmd')
		file.copy(reportTpl, tempReport, overwrite = TRUE)
		rmarkdown::render(
			tempReport,
			output_file = 'E:\\uMod_sva-Save.html',
			params = params_global,
			envir = new.env(parent = globalenv())
		)
	}
}
