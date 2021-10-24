# User Defined Module: [Load a sheet from an EXCEL file and display the related properties]
# Required User-specified parameters:

# [Quote: 'lxs': User defined Module: Load EXCEL Sheet]
# [Quote: 'RV': User defined Reactive Values]
# [Quote: 'uWg': User defined Widgets]
# [Quote: 'sI': User defined selectInput/pickerInput]
# [Quote: 'AB': User defined actionButton]
# [Quote: 'FB': User defined shinyFiles::shinyFilesButton]
# [Quote: 'pS': User defined shinyWidgets::prettySwitch]
# [Quote: 'rT': User defined renderTable]

# Required User-specified functions:
# [Quote:[omniR$AdvOp$scaleNum.r]]

UM_LoadXlSheet_ui_upload <- function(id){
	#Set current Name Space
	ns <- NS(id)

	uiOutput(ns('lxs_up'))
}
UM_LoadXlSheet_ui_display <- function(id){
	#Set current Name Space
	ns <- NS(id)

	uiOutput(ns('lxs_dis'))
}

UM_LoadXlSheet_svr <- function(input,output,session,fDebug = FALSE,inCfg = NULL){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	uRV$AnlData <- NULL
	uRV$OutCfg <- list()
	uRV$ActionDone <- FALSE
	uRV_finish <- reactiveVal(0)
	if (is.null(inCfg) | is.null(inCfg$SelType) | !isTRUE(unlist(inCfg$SelType) == 'XLSXFile')) return(
		list(
			CallCounter = shiny::reactive({uRV_finish()}),
			ActionDone = shiny::reactive({uRV$ActionDone}),
			EnvVariables = shiny::reactive({uRV}),
			outdat = shiny::reactive({NULL})
		)
	)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns('[Module Call][UM_LoadXlSheet]'))
	}

	#010. Prepare mapping table of variables
	uRV$map_filetypes <- c('xlsx','xlsm')
	uRV$map_units <- c(kilo = 'K', mega = 'M', giga = 'G', tera = 'T', peta = 'P', exa = 'E', zetta = 'Z')

	#099. Print parameters in Debug Mode
	shinyjs::reset('uWg_pS_DHeader')

	#200. General settings of styles for the output UI
	#201. Prepare the styles for the buttons indicating file attributes
	uRV$btn_styles_attr <- paste0(
		'width: 100%;',
		'text-align: left;',
		'vertical-align: middle;',
		'padding-left: 4px;',
		'padding-right: inherit;',
		'background-color: rgba(0,0,0,0);',
		'overflow: hidden;',
		'border: none;'
	)

	#205. Prepare the styles for the buttons recording user actions
	uRV$btn_styles_AB <- paste0(
		'text-align: center;',
		'vertical-align: middle;',
		'color: white;',
		'padding: 6px;'
	)

	#206. Prepare the styles for the shinyFileButton
	uRV$btn_styles_FB <- paste0(
		'width: 100%;',
		'text-align: left;',
		'vertical-align: middle;',
		'padding: 6px;'
	)

	#220. Text area for dataframe attributes
	uRV$txt_styles_attr <- paste0(
		'padding-left: 10px;',
		'padding-top: 6px;',
		# 'word-wrap: break-word;',
		'text-overflow: ellipsis;',
		'overflow: hidden;'
	)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			'.lxs_fluidRow {padding: 2px 15px 2px 15px;}',
			'.lxs_Column {',
				'padding: 0px;',
				'text-align: left;',
				'vertical-align: middle;',
			'}'
		)
	)

	#500. Observers
	#Important!!!: When using [shinyjs], ID should not be enclosed by [ns] function: [ns('uWg_pS_DHeader')]
	#502. Observe whether the user has choosen another set of files
	volumes <- c(CurrentDir = getwd(), Home = fs::path_home(), 'R Installation' = R.home(), shinyFiles::getVolumes()())
	#Important!!!: below ID should not be enclosed by [ns] function: [ns('uWg_FB_FileBrowse')]
	shinyFiles::shinyFileChoose(
		input,
		'uWg_FB_FileBrowse',
		roots = volumes,
		filetypes = uRV$map_filetypes
	)
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_FB_FileBrowse

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[502][observe][IN][input$uWg_FB_FileBrowse]:',input$uWg_FB_FileBrowse)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_FB_FileBrowse)) return()
				if (is.integer(input$uWg_FB_FileBrowse)) return()

				#500. Collect the selected file names
				#Below input result is a tibble
				uRV$inFiles <- as.data.frame(shinyFiles::parseFilePaths(volumes, input$uWg_FB_FileBrowse))
				uRV$kFiles <- nrow(uRV$inFiles)
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[502][observe][OUT][uRV$inFiles]:')))
					glimpse(uRV$inFiles)
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[502]Retrieve the list of selected files from a popup window')
		# ,priority = 997
	)

	#505. Hide the sheet selector once user tries to select another data file
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_sI_SelFile

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[505][observe][IN][input$uWg_sI_SelFile]:',input$uWg_sI_SelFile)))
				}
				#100. Disable the confirm button if none of the files is selected
				if (is.null(input$uWg_sI_SelFile)){
					shinyjs::disable(id = 'uWg_AB_ConfirmFile')
				} else {
					shinyjs::enable(id = 'uWg_AB_ConfirmFile')
				}

				#300. Hide the encoding selector
				shinyjs::hide(id = 'uRow_SelSh')

				#500. Disable the encoding selector
				shinyjs::disable(id = 'uWg_AB_ConfirmSh')
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[505]Hide/disable some widgets during selecting files')
		# ,priority = 990
	)

	#510. Show the sheet selector once a data file is confirmed for selection
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ConfirmFile

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[510][observe][IN][input$uWg_AB_ConfirmFile]:',input$uWg_AB_ConfirmFile)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfirmFile)) return()
				if (input$uWg_AB_ConfirmFile == 0) return()
				if (is.null(input$uWg_sI_SelFile)) return()

				#100. Show the encoding selector
				shinyjs::show(id = 'uRow_SelSh')

				#500. Retrieve the confirmed file
				uRV$inFile <- normalizePath(input$uWg_sI_SelFile)
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[510]Show some widgets when the dedicated file is confirmed to load')
		# ,priority = 980
	)

	#515. Calculate internal values if the file is changed
	shiny::observe(
		{
			#100. Take dependencies
			uRV$inFile

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[515][observe][IN][uRV$inFile]:',uRV$inFile)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$inFile)) return()

				#300. Reset the necessary values so that additional panels are hidden
				uRV$inShName <- NULL
				uRV$df_kRows <- NULL
				uRV$df_kCols <- NULL

				#500. Load the sheet names from the confirmed file
				uRV$inFInfo <- file.info(uRV$inFile)
				uRV$inFSize <- uRV$inFInfo$size %>% unlist() %>% as.vector()
				uRV$inFmdate <- uRV$inFInfo$mtime %>% lubridate::date() %>% unlist() %>% as.Date()
				uRV$inFcdate <- uRV$inFInfo$ctime %>% lubridate::date() %>% unlist() %>% as.Date()
				uRV$inFadate <- uRV$inFInfo$atime %>% lubridate::date() %>% unlist() %>% as.Date()
				uRV$ShNames <- openxlsx::getSheetNames(uRV$inFile)

				#700. Scale the numbers for display
				#710. Data size
				#Since the input of function [scaleNum] is a single-element vector, its output [$values] is of the same shape.
				#[Quote:[omniR$AdvOp$scaleNum.r]]
				uRV$df_sizeC <- paste0( scaleNum(uRV$inFSize,1024,map_units=uRV$map_units)$values , 'Byte(s)' )

				#900. Update the values for the sheet selector
				shinyWidgets::updatePickerInput(
					session,
					'uWg_sI_SelSh',
					choices = uRV$ShNames
				)
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[515][observe][OUT][uRV$inFSize]:',uRV$inFSize)))
					message(ns(paste0('[515][observe][OUT][uRV$df_sizeC]:',uRV$df_sizeC)))
					message(ns(paste0('[515][observe][OUT][uRV$inFmdate]:',strftime(uRV$inFmdate,format = '%Y-%m-%d',tz = Sys.getenv('TZ')))))
					message(ns(paste0('[515][observe][OUT][uRV$inFcdate]:',strftime(uRV$inFcdate,format = '%Y-%m-%d',tz = Sys.getenv('TZ')))))
					message(ns(paste0('[515][observe][OUT][uRV$inFadate]:',strftime(uRV$inFadate,format = '%Y-%m-%d',tz = Sys.getenv('TZ')))))
					message(ns(paste0('[515][observe][OUT][uRV$ShNames]:<',paste0(uRV$ShNames,collapse = '>,<'),'>')))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[515]Preload the file and calculate necessary attributes')
		# ,priority = 950
	)

	#517. Hide the sheet name in the details panel when necessary
	#Below seems no effect!
	shiny::observe(
		{
			#100. Take dependencies
			uRV$inShName

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[517][observe][IN][uRV$inShName]:',uRV$inShName)))
				}
				#100. Hide the UI
				if (is.null(uRV$inShName)){
					shinyjs::hide(id = 'uCol_ShName')
				} else {
					shinyjs::show(id = 'uCol_ShName')
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[517]Toggle whether to show the sheet name in the details')
		# ,priority = 930
	)

	#520. Toggle the state of the confirm button for loading of the selected sheet, when picking among the list
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_sI_SelSh

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[520][observe][IN][input$uWg_sI_SelSh]:',input$uWg_sI_SelSh)))
				}
				#100. Disable the confirm button if none of the dataframes is selected
				if (is.null(input$uWg_sI_SelSh)){
					shinyjs::disable(id = 'uWg_AB_ConfirmSh')
				} else {
					shinyjs::enable(id = 'uWg_AB_ConfirmSh')
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[520]Enable/disable the button for confirmation of sheet selection')
		# ,priority = 890
	)

	#530. Set the names when a specific sheet is confirmed to load
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ConfirmSh

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[530][observe][IN][input$uWg_AB_ConfirmSh]:',input$uWg_AB_ConfirmSh)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfirmSh)) return()
				if (input$uWg_AB_ConfirmSh == 0) return()

				#100. Retrieve the necessary information of the dataframe
				uRV$inShName <- input$uWg_sI_SelSh
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[530][observe][OUT][uRV$inShName]:',uRV$inShName)))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[530]Determine the dedicated sheet for loading')
		# ,priority = 790
	)

	#540. Load the dedicated dataframe once changed
	#We do not combine this step with the above one, as the confirmed result may not change.
	shiny::observe(
		{
			#100. Take dependencies
			uRV$inFile
			uRV$inShName

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[540][observe][IN][uRV$inFile]:',uRV$inFile)))
					message(ns(paste0('[540][observe][IN][uRV$inShName]:',uRV$inShName)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$inFile)) return()
				if (is.null(uRV$inShName)) return()

				#100. Load the dataframe
				uRV$AnlData <- openxlsx::readWorkbook(
					uRV$inFile,
					sheet = uRV$inShName,
					detectDates = TRUE,
					fillMergedCells = TRUE
				)

				#020. Retrieve the information of the selected file
				uRV$df_kRows <- nrow(uRV$AnlData)
				uRV$df_kCols <- ncol(uRV$AnlData)

				#600. Determine output configuration
				uRV$OutCfg[['Data Source']] <- uRV$inFile
				uRV$OutCfg[['Sheet Name']] <- uRV$inShName
				uRV$OutCfg[['File Size on Harddisk']] <- uRV$df_sizeC
				uRV$OutCfg[['Total # Rows']] <- uRV$df_kRows
				uRV$OutCfg[['Total # Columns']] <- uRV$df_kCols
				uRV$OutCfg[['Creation Date']] <- strftime(uRV$inFcdate,format = '%Y-%m-%d',tz = Sys.getenv('TZ'))
				uRV$OutCfg[['Last Modified Date']] <- strftime(uRV$inFmdate,format = '%Y-%m-%d',tz = Sys.getenv('TZ'))

				#700. Toggle the state of the table display
				shinyWidgets::updatePrettySwitch(
					session,
					'uWg_pS_DHeader',
					value = FALSE
				)
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[540][observe][OUT][uRV$AnlData]:',str(uRV$AnlData))))
					message(ns(paste0('[540][observe][OUT][uRV$df_kRows]:',uRV$df_kRows)))
					message(ns(paste0('[540][observe][OUT][uRV$df_kCols]:',uRV$df_kCols)))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[540]Load the sheet and calculate necessary attributes')
		# ,priority = 690
	)

	#550. Toggle the display of the Data Table when required
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_pS_DHeader

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[550][observe][IN][input$uWg_pS_DHeader]:',input$uWg_pS_DHeader)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_pS_DHeader)) return()

				#500. Reset the UI
				shinyjs::toggleElement('DHeader', anim = TRUE, condition = input$uWg_pS_DHeader)
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[550]Toggle whether to show the table preview when clicking on the switch')
		# ,priority = 590
	)

	#700. Prepare dynamic UIs
	#701. The UI for file upload
	output$lxs_up <- shiny::renderUI({
		#100. Take dependency

		#200. Return if there is no available data

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[701][renderUI][IN][output$lxs_up]: UI for data uploading')))
		}
		#900. Create the UI
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			#File collector (User to collect the files from a browser in a popup window)
			shiny::fluidRow(
				class = 'lxs_fluidRow',
				shiny::fillRow(
					flex = 1,
					height = 34,
					shinyFiles::shinyFilesButton(ns('uWg_FB_FileBrowse'),
						'Browse...',
						'Please choose file(s) to upload',
						multiple = TRUE,
						style = uRV$btn_styles_FB,
						icon = shiny::icon('folder-open')
					)
				#End of [fillRow]
				)
			#End of [fluidRow]
			),

			#File selector
			shiny::uiOutput(ns('uRow_FSelector'))
		#End of [box]
		)
	#End of [renderUI] of [701]
	})

	#710. The file selector
	output$uRow_FSelector <- shiny::renderUI({
		#100. Take dependency
		uRV$inFiles
		uRV$kFiles

		#200. Return if there is no available data
		if (is.null(uRV$kFiles)) return(NULL)
		else {
			if (uRV$kFiles == 0){
				return(
					#Package selector
					shiny::fluidRow(
						class = 'lxs_fluidRow',
						'(No File)'
					#End of [fluidRow]
					)
				)
			}
		}

		#400. Create the named list of files as choices
		ch_files <- uRV$inFiles$datapath
		names(ch_files) <- uRV$inFiles$name

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[710][renderDT][IN][output$uRow_FSelector]: File Selector')))
		}
		#900. Create the UI
		shiny::tagList(
			#File selector
			shiny::fluidRow(
				class = 'lxs_fluidRow',
				shiny::fillRow(
					flex = c(1,NA),
					height = 34,
					shinyWidgets::pickerInput(ns('uWg_sI_SelFile'),
						NULL,
						width = '100%',
						options = shinyWidgets::pickerOptions(
							# title = '(Choose one file)',
							liveSearch = TRUE,
							liveSearchNormalize = TRUE,
							liveSearchPlaceholder = 'Search...',
							mobile = TRUE
						),
						choices = ch_files
					),
					shiny::actionButton(ns('uWg_AB_ConfirmFile'), NULL,
						width = 34,
						class = 'btn-primary',
						style = uRV$btn_styles_AB,
						icon = shiny::icon('arrow-right')
					)
				#End of [fillRow]
				)
			#End of [fluidRow]
			),

			#Sheet selector
			shiny::fluidRow(
				id = ns('uRow_SelSh'),
				class = 'lxs_fluidRow',
				shiny::fillRow(
					flex = c(1,NA),
					height = 34,
					shinyWidgets::pickerInput(ns('uWg_sI_SelSh'),
						NULL,
						width = '100%',
						options = shinyWidgets::pickerOptions(
							# title = '(Choose one sheet)',
							liveSearch = TRUE,
							liveSearchNormalize = TRUE,
							liveSearchPlaceholder = 'Search...',
							mobile = TRUE
						),
						choices = NULL
					),
					shiny::actionButton(ns('uWg_AB_ConfirmSh'), NULL,
						width = 34,
						class = 'btn-primary',
						style = uRV$btn_styles_AB,
						icon = shiny::icon('upload')
					) %>%
						shinyjs::disabled()
				#End of [fillRow]
				)
			#End of [fluidRow]
			) %>%
				shinyjs::hidden()
		#End of [box]
		)
	#End of [renderUI] of [710]
	})

	#720. Add box to display file specifications.
	#721. Diaplay the header of the loaded data
	output$urT_DHeader <- DT::renderDT({
		#100. Take dependency from below action (without using its value):
		uRV$AnlData

		#200. Return if there is no available data
		if (is.null(uRV$AnlData)) return(NULL)

		#Render UI
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[721][renderDT][IN][output$urT_DHeader]: Create Datatable')))
		}
		#We do not [isolate] this table here, as we need the system to render the table immediately when
		# we select a new sheet to upload; to reduce the presure on dynamic UI side at later steps.
		# if (is.null(uRV$AnlData()) | input$uWg_pS_DHeader == FALSE) return(NULL)
		DT::datatable(
			uRV$AnlData,
			#IMPORTANT!!! We cannot add the option [filter] if we also need to used [echarts4r]! It will conflict JS from that package!
			# filter = 'top',
			#Next time I may try use '90vw' to represent '90% of viewport width'
			#[Quote: https://spartanideas.msu.edu/2015/07/25/shiny-hack-vertical-scrollbar/ ]
			# width = '90%',
			#[Quote: https://rstudio.github.io/DT/options.html ]
			options = list(
				serverSide = TRUE,
				processing = TRUE,
				stateSave = FALSE,
				#[Show N entries] on top left
				pageLength = 5,
				lengthMenu = c(5, 10, 15, 20),
				#Control whether to show a scroll bar if the sum width of columns exceeds the page width
				scrollX = TRUE
			#End of [options]
			)
		#End of [datatable]
		)
	#End of [renderDataTable] of [721]
	})

	#725. Decide whether to display the glimpse of the loaded table.
	output$uDT_TblGlimpse <- shiny::renderUI({
		#100. Take dependency from below action (without using its value):

		#200. Return if the condition is not fulfilled

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[725][renderUI][IN][output$uDT_TblGlimpse]: UI for Datatable')))
		}
		#900. Create the UI
		shiny::fluidRow(
			class = 'lxs_fluidRow',
			id = ns('DHeader'),
			shiny::tags$div(
				shiny::br(),
				DT::DTOutput(ns('urT_DHeader'))
			#End of [div]
			)
		#End of [fluidRow]
		) %>%
			shinyjs::hidden()
	#End of [renderUI] of [725]
	})

	#740. Display [# rows], [# columns] and [Table Preview]
	output$uRow_DatStats <- shiny::renderUI({
		#100. Take dependency from below action (without using its value):
		uRV$df_kRows
		uRV$df_kCols

		#200. Return if the condition is not fulfilled
		if (is.null(uRV$df_kRows)) return(NULL)
		if (is.null(uRV$df_kCols)) return(NULL)

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[740][renderUI][IN][output$uRow_DatStats]: UI for Attributes display')))
			message(ns(paste0('[740][renderUI][IN][uRV$df_kRows]:',uRV$df_kRows)))
			message(ns(paste0('[740][renderUI][IN][uRV$df_kCols]:',uRV$df_kCols)))
		}
		#900. Create the UI
		shiny::fluidRow(
			class = 'lxs_fluidRow',
			#Group 4: Display the number of rows
			shiny::column(width = 4,
				class = 'lxs_Column',
				tippy::tippy_this(
					ns('uWg_AB_Fnrow'),
					'# Rows of the Loaded Table',
					placement = 'top',
					distance = 2,
					arrow = FALSE
				),
				shiny::fillRow(
					flex = c(1,3),
					height = 34,
					shiny::actionButton(ns('uWg_AB_Fnrow'), '# Rows',
						style = uRV$btn_styles_attr,
						icon = shiny::icon('th-list')
					),
					shiny::tags$div(
						style = uRV$txt_styles_attr,
						prettyNum(uRV$df_kRows,big.mark=',')
					)
				#End of [fillRow]
				)
			#End of [column]
			),
			#Group 5: Display the number of columns
			shiny::column(width = 4,
				class = 'lxs_Column',
				tippy::tippy_this(
					ns('uWg_AB_Fncol'),
					'# Columns of the Loaded Table',
					placement = 'top',
					distance = 2,
					arrow = FALSE
				),
				shiny::fillRow(
					flex = c(1,3),
					height = 34,
					shiny::actionButton(ns('uWg_AB_Fncol'), '# Cols',
						style = uRV$btn_styles_attr,
						icon = shiny::icon('columns')
					),
					shiny::tags$div(
						style = uRV$txt_styles_attr,
						prettyNum(uRV$df_kCols,big.mark=',')
					)
				#End of [fillRow]
				)
			#End of [column]
			),
			#Group 6: Control whether to display the header of the loaded data
			shiny::column(width = 4,
				class = 'lxs_Column',
				tippy::tippy_this(
					ns('uWg_AB_FInfo'),
					'View Table',
					placement = 'top',
					distance = 2,
					arrow = FALSE
				),
				shiny::fillRow(
					flex = c(1,3),
					height = 34,
					shiny::actionButton(ns('uWg_AB_FInfo'), 'Detail',
						style = uRV$btn_styles_attr,
						icon = shiny::icon('table')
					),
					shiny::tags$div(
						style = uRV$txt_styles_attr,
						shinyWidgets::prettySwitch(ns('uWg_pS_DHeader'), NULL,
							fill = FALSE,
							slim = TRUE
						)
					)
				#End of [fillRow]
				)
			#End of [column]
			)
		#End of [fluidRow]
		)
	#End of [renderUI] of [740]
	})

	#790. Create the box with file details.
	output$lxs_dis <- shiny::renderUI({
		#100. Take dependency from below action (without using its value):
		uRV$inFile
		uRV$inShName
		uRV$df_sizeC
		uRV$inFcdate
		uRV$inFmdate
		uRV$inFadate

		#200. Return if any of the conditions are not fulfilled
		if (is.null(uRV$inFile)) return(NULL)

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[790][renderUI][IN][output$lxs_dis]: UI for Attributes display')))
		}
		#900. Render UI
		shiny::tags$div(
			id = ns('uDiv_DfDetails'),
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			shiny::fluidRow(
				class = 'lxs_fluidRow',
				#Group 1: Display the file name
				shiny::column(width = 4,
					class = 'lxs_Column',
					tippy::tippy_this(
						ns('uDiv_FName'),
						uRV$inFile,
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					tippy::tippy_this(
						ns('uWg_AB_FName'),
						'File Name',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_FName'), 'Name',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('file-excel-o')
						),
						shiny::tags$div(
							id = ns('uDiv_FName'),
							style = uRV$txt_styles_attr,
							uRV$inFile
						)
					#End of [fillRow]
					)
				#End of [column]
				),
				#Group 2: Display the file size
				shiny::column(width = 4,
					class = 'lxs_Column',
					tippy::tippy_this(
						ns('uWg_AB_FSize'),
						'File Size',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_FSize'), 'Size',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('hdd-o')
						),
						shiny::tags$div(
							style = uRV$txt_styles_attr,
							uRV$df_sizeC
						)
					#End of [fillRow]
					)
				#End of [column]
				),
				#Group 3: Display the uploaded sheet name
				shiny::column(width = 4,
					id = ns('uCol_ShName'),
					class = 'lxs_Column',
					tippy::tippy_this(
						ns('uDiv_ShName'),
						uRV$inShName,
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					tippy::tippy_this(
						ns('uWg_AB_ShName'),
						'Sheet Name',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_ShName'), 'Sheet',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('th')
						),
						shiny::tags$div(
							id = ns('uDiv_ShName'),
							style = uRV$txt_styles_attr,
							uRV$inShName
						)
					#End of [fillRow]
					)
				#End of [column]
				)
			#End of [fluidRow]
			),
			shiny::fluidRow(
				class = 'lxs_fluidRow',
				#Group 4: Display the file creation date
				shiny::column(width = 4,
					class = 'lxs_Column',
					tippy::tippy_this(
						ns('uWg_AB_Fcdate'),
						'File Creation Date',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_Fcdate'), 'CDate',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('calendar-plus-o')
						),
						shiny::tags$div(
							style = uRV$txt_styles_attr,
							strftime(uRV$inFcdate,format = '%Y-%m-%d',tz = Sys.getenv('TZ'))
						)
					#End of [fillRow]
					)
				#End of [column]
				),
				#Group 5: Display the last modification date of the file
				shiny::column(width = 4,
					class = 'lxs_Column',
					tippy::tippy_this(
						ns('uWg_AB_Fmdate'),
						'Last Modified Date',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_Fmdate'), 'MDate',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('calendar-check-o')
						),
						shiny::tags$div(
							style = uRV$txt_styles_attr,
							strftime(uRV$inFmdate,format = '%Y-%m-%d',tz = Sys.getenv('TZ'))
						)
					#End of [fillRow]
					)
				#End of [column]
				),
				#Group 6: Display the last access date of the file
				shiny::column(width = 4,
					class = 'lxs_Column',
					tippy::tippy_this(
						ns('uWg_AB_Fadate'),
						'Last Accessed Date',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_Fadate'), 'ADate',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('calendar')
						),
						shiny::tags$div(
							style = uRV$txt_styles_attr,
							strftime(uRV$inFadate,format = '%Y-%m-%d',tz = Sys.getenv('TZ'))
						)
					#End of [fillRow]
					)
				#End of [column]
				)
			#End of [fluidRow]
			),
			shiny::uiOutput(ns('uRow_DatStats')),
			#Print the header of the loaded data in the entire row
			shiny::uiOutput(ns('uDT_TblGlimpse'))
		#End of [div]
		)
	#End of [renderUI] of [790]
	})

	#899. Determine the output value
	#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
	shiny::observeEvent(input$uWg_AB_ConfirmSh,{
		if (input$uWg_AB_ConfirmSh == 0) return()
		uRV_finish(input$uWg_AB_ConfirmSh)
		uRV$ActionDone <- TRUE
	})

	#999. Return the result
	#Next time I may try to append values as instructed below:
	#[Quote: https://community.rstudio.com/t/append-multiple-reactive-output-of-a-shiny-module-to-an-existing-reactivevalue-object-in-the-app/36985/2 ]
	return(
		list(
			CallCounter = shiny::reactive({uRV_finish()}),
			ActionDone = shiny::reactive({uRV$ActionDone}),
			EnvVariables = shiny::reactive({uRV}),
			outdat = shiny::reactive({uRV$AnlData})
		)
	)
#End of [Server]
}

#[Full Test Program;]
if (FALSE){
	if (interactive()){
		lst_pkg <- c( 'tmcn' , 'openxlsx' , 'dplyr' , 'DT' ,
			'shiny' , 'shinyjs' , 'shinydashboard' , 'shinydashboardPlus' , 'shinyWidgets' , 'shinyFiles' , 'tippy'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		source(paste0(omniR,'\\AdvOp\\scaleNum.r'), encoding = 'utf-8')

		ui <- shinydashboardPlus::dashboardPagePlus(
			shinyjs::useShinyjs(),
			header = shinydashboardPlus::dashboardHeaderPlus(),
			sidebar = shinydashboard::dashboardSidebar(),
			body = shinydashboard::dashboardBody(
				shiny::fluidPage(
					shiny::column(width = 3,
						shinydashboardPlus::boxPlus(collapsible = TRUE,width = 12,
							title = 'Data Loader',
							solidHeader = FALSE,
							closable = FALSE,
							enable_sidebar = FALSE,
							sidebar_width = 25,
							sidebar_start_open = FALSE,
							UM_LoadXlSheet_ui_upload('uMod_LoadXlSheet')
						)
					),

					shiny::column(width = 9,
						shinydashboardPlus::boxPlus(collapsible = TRUE,width = 12,
							title = 'Data Details',
							solidHeader = FALSE,
							closable = FALSE,
							enable_sidebar = FALSE,
							sidebar_width = 25,
							sidebar_start_open = FALSE,
							UM_LoadXlSheet_ui_display('uMod_LoadXlSheet')
						)
					)
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$AnlData <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL}),
				outdat = shiny::reactive({NULL})
			)

			cfg <- list()
			cfg$SelType <- 'XLSXFile'
			# cfg$inFiles <- data.frame(
			# 	name = 'TestData.xlsx',
			# 	size = 100000,
			# 	datapath = 'D:/R/Project/myApp/Data/TestData.xlsx',
			# 	stringsAsFactors = FALSE
			# )

			observe({
				modout$AnlData <- shiny::callModule(
					UM_LoadXlSheet_svr,
					'uMod_LoadXlSheet',
					fDebug = FALSE,
					inCfg = cfg
				)
			})
			shiny::observeEvent(modout$AnlData$CallCounter(),{
				if (modout$AnlData$CallCounter() == 0) return()
				message('[AnlData$CallCounter()]:',modout$AnlData$CallCounter())
				message('[AnlData$ActionDone()]:',modout$AnlData$ActionDone())
				message('[AnlData$EnvVariables]:')
				message('[AnlData$EnvVariables()$inFile]:',modout$AnlData$EnvVariables()$inFile)
				message('[AnlData$outdat()]:')
				glimpse(modout$AnlData$outdat())
			})
		}

		shinyApp(ui, server)
	}

}
