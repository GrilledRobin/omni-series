# User Defined Module: [Load a dataframe from installed packages and display the related properties]
# Required User-specified parameters:

# [Quote: 'ldfs': User defined Module: Load dataframes]
# [Quote: 'RV': User defined Reactive Values]
# [Quote: 'uWg': User defined Widgets]
# [Quote: 'sI': User defined selectInput/pickerInput]
# [Quote: 'pS': User defined shinyWidgets::prettySwitch]
# [Quote: 'rT': User defined renderTable]

# Required User-specified functions:
# [Quote:[omniR$FileSystem$getDFinPKG.r]]
# [Quote:[omniR$AdvOp$scaleNum.r]]

UM_LoadDfFrPkg_ui_upload <- function(id){
	#Set current Name Space
	ns <- NS(id)

	uiOutput(ns('ldfs_up'))
}
UM_LoadDfFrPkg_ui_display <- function(id){
	#Set current Name Space
	ns <- NS(id)

	uiOutput(ns('ldfs_dis'))
}

UM_LoadDfFrPkg_svr <- function(input,output,session,fDebug = FALSE,inCfg = NULL){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- reactiveValues()
	uRV$AnlData <- NULL
	uRV$OutCfg <- list()
	uRV$ActionDone <- FALSE
	uRV_finish <- reactiveVal(0)
	if (is.null(inCfg) | is.null(inCfg$SelType) | !isTRUE(unlist(inCfg$SelType) == 'DfFrPkg')) return(
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
		message(ns('[Module Call][UM_LoadDfFrPkg]'))
	}

	#010. Prepare mapping table of variables
	uRV$map_units <- c(kilo = 'K', mega = 'M', giga = 'G', tera = 'T', peta = 'P', exa = 'E', zetta = 'Z')

	#020. Retrieve the list of available dataframes in current environment
	#[Quote:[omniR$FileSystem$getDFinPKG.r]]
	uRV$DfFrPkg <- getDFinPKG(fDebug=fDebug)
	uRV$Pkgs <- unique(uRV$DfFrPkg$pkg)
	uRV$kPkgs <- length(uRV$Pkgs)
	uRV$kDfs <- nrow(uRV$DfFrPkg)
	shinyjs::reset('uWg_pS_DHeader')

	#099. Print parameters in Debug Mode
	if (fDebug){
		message(ns(paste0('[099][Params][# Libraries with Dataframes]:[',uRV$kPkgs,']')))
		message(ns(paste0('[099][Params][# Dataframes found]:[',uRV$kDfs,']')))
	}

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
			'.ldfs_fluidRow {padding: 2px 15px 2px 15px;}',
			'.ldfs_Column {',
				'padding: 0px;',
				'text-align: left;',
				'vertical-align: middle;',
			'}'
		)
	)

	#500. Observers
	#Important!!!: When using [shinyjs], ID should not be enclosed by [ns] function: [ns('uWg_pS_DHeader')]
	#505. Hide the dataframe selector once user tries to select another package
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_sI_SelPkg

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[505][observe][IN][input$uWg_sI_SelPkg]:',input$uWg_sI_SelPkg)))
				}
				#100. Disable the confirm button if none of the packages is selected
				if (is.null(input$uWg_sI_SelPkg)){
					shinyjs::disable(id = 'uWg_AB_ConfirmPkg')
				} else {
					shinyjs::enable(id = 'uWg_AB_ConfirmPkg')
				}

				#300. Hide the dataframe selector
				shinyjs::hide(id = 'uRow_SelDf')

				#500. Disable the dataframe selector
				shinyjs::disable(id = 'uWg_AB_ConfirmDf')

				#900. Update the values for the dataframe selector
				if (is.null(input$uWg_sI_SelPkg)) return()
				shinyWidgets::updatePickerInput(
					session,
					'uWg_sI_SelDf',
					choices = uRV$DfFrPkg$name[uRV$DfFrPkg$pkg %in% input$uWg_sI_SelPkg]
				)
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[505]Hide/disable some widgets during selecting packages')
		# ,priority = 990
	)

	#510. Show the dataframe selector once a package is confirmed for selection
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ConfirmPkg

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[510][observe][IN][input$uWg_AB_ConfirmPkg]:',input$uWg_AB_ConfirmPkg)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfirmPkg)) return()
				if (input$uWg_AB_ConfirmPkg == 0) return()

				#100. Show the dataframe selector
				shinyjs::show(id = 'uRow_SelDf')
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[510]Show some widgets when confirming one package to search for datasets')
		# ,priority = 980
	)

	#520. Toggle the state of the confirm button for loading of the selected dataframe, when picking among the list
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_sI_SelDf

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[520][observe][IN][input$uWg_sI_SelDf]:',input$uWg_sI_SelDf)))
				}
				#100. Disable the confirm button if none of the dataframes is selected
				if (is.null(input$uWg_sI_SelDf)){
					shinyjs::disable(id = 'uWg_AB_ConfirmDf')
				} else {
					shinyjs::enable(id = 'uWg_AB_ConfirmDf')
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[520]Hide/disable some widgets during selecting datasets')
		# ,priority = 890
	)

	#530. Set the names when a specific dataframe is confirmed to load
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ConfirmDf

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[530][observe][IN][input$uWg_AB_ConfirmDf]:',input$uWg_AB_ConfirmDf)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfirmDf)) return()
				if (input$uWg_AB_ConfirmDf == 0) return()

				#100. Retrieve the necessary information of the dataframe
				uRV$df_pkg <- input$uWg_sI_SelPkg
				uRV$df_name <- input$uWg_sI_SelDf
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[530][observe][OUT][uRV$df_pkg]:',uRV$df_pkg)))
					message(ns(paste0('[530][observe][OUT][uRV$df_name]:',uRV$df_name)))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[530]Determine the dedicated package and dataset for loading')
		# ,priority = 790
	)

	#540. Load the dedicated dataframe once changed
	#We do not combine this step with the above one, as the confirmed result may not change.
	shiny::observe(
		{
			#100. Take dependencies
			uRV$df_pkg
			uRV$df_name

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[540][observe][IN][uRV$df_pkg]:',uRV$df_pkg)))
					message(ns(paste0('[540][observe][IN][uRV$df_name]:',uRV$df_name)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$df_pkg)) return()
				if (is.null(uRV$df_name)) return()

				#100. Load the dataframe
				uRV$AnlData <- eval(parse(text = paste0(uRV$df_pkg,'::',uRV$df_name)))
				if (!is.data.frame(uRV$AnlData)) uRV$AnlData <- uRV$AnlData %>% as.data.frame()

				#200. Retrieve the attributes of the dataframe
				uRV$df_size <- pryr::object_size(uRV$AnlData)
				uRV$df_kRows <- nrow(uRV$AnlData)
				uRV$df_kCols <- ncol(uRV$AnlData)

				#300. Scale the numbers for display
				#310. Data size
				#Since the input of function [scaleNum] is a single-element vector, its output [$values] is of the same shape.
				#[Quote:[omniR$AdvOp$scaleNum.r]]
				uRV$df_sizeC <- paste0( scaleNum(uRV$df_size,1024,map_units=uRV$map_units)$values , 'Byte(s)' )

				#600. Determine output configuration
				uRV$OutCfg[['Data Source - R Package']] <- uRV$df_pkg
				uRV$OutCfg[['Data File Name']] <- uRV$df_name
				uRV$OutCfg[['File Size in RAM']] <- uRV$df_sizeC
				uRV$OutCfg[['Total # Rows']] <- uRV$df_kRows
				uRV$OutCfg[['Total # Columns']] <- uRV$df_kCols

				#700. Toggle the state of the table display
				shinyWidgets::updatePrettySwitch(
					session,
					'uWg_pS_DHeader',
					value = FALSE
				)
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[540][observe][OUT][uRV$AnlData]:',str(uRV$AnlData))))
					message(ns(paste0('[540][observe][OUT][uRV$df_size]:',uRV$df_size)))
					message(ns(paste0('[540][observe][OUT][uRV$df_sizeC]:',uRV$df_sizeC)))
					message(ns(paste0('[540][observe][OUT][uRV$df_kRows]:',uRV$df_kRows)))
					message(ns(paste0('[540][observe][OUT][uRV$df_kCols]:',uRV$df_kCols)))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[540]Load the data and calculate necessary attributes')
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
	#710. The UI for dataframe selection
	output$ldfs_up <- shiny::renderUI({
		#100. Take dependency
		uRV$Pkgs
		uRV$kPkgs

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[710][renderUI][IN][output$ldfs_up]: UI for data uploading')))
		}
		#200. Return if there is no available data
		if (uRV$kPkgs == 0){
			return(
				shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css',
						uRV$styles_final
					),

					#Package selector
					shiny::fluidRow(
						class = 'ldfs_fluidRow',
						'(N/A)'
					#End of [fluidRow]
					)
				#End of [tagList]
				)
			)
		}

		#900. Create the UI
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css',
				uRV$styles_final
			),

			#Package selector
			shiny::fluidRow(
				class = 'ldfs_fluidRow',
				shiny::fillRow(
					flex = c(1,NA),
					height = 34,
					shinyWidgets::pickerInput(ns('uWg_sI_SelPkg'),
						NULL,
						width = '100%',
						options = shinyWidgets::pickerOptions(
							# title = '(Choose one packge)',
							liveSearch = TRUE,
							liveSearchNormalize = TRUE,
							liveSearchPlaceholder = 'Search...',
							mobile = TRUE
						),
						choices = uRV$Pkgs
					),
					shiny::actionButton(ns('uWg_AB_ConfirmPkg'), NULL,
						width = 34,
						class = 'btn-primary',
						style = uRV$btn_styles_AB,
						icon = shiny::icon('search')
					)
				#End of [fillRow]
				)
			#End of [fluidRow]
			),

			#Dataframe selector
			shiny::fluidRow(
				id = ns('uRow_SelDf'),
				class = 'ldfs_fluidRow',
				shiny::fillRow(
					flex = c(1,NA),
					height = 34,
					shinyWidgets::pickerInput(ns('uWg_sI_SelDf'),
						NULL,
						width = '100%',
						options = shinyWidgets::pickerOptions(
							# title = '(Choose one table)',
							liveSearch = TRUE,
							liveSearchNormalize = TRUE,
							liveSearchPlaceholder = 'Search...',
							mobile = TRUE
						),
						choices = NULL
					),
					shiny::actionButton(ns('uWg_AB_ConfirmDf'), NULL,
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
		#End of [tagList]
		)
	#End of [renderUI] of [710]
	})

	#720. Add box to display file specifications.
	#721. Display the header of the loaded data
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
		# we select a new dataframe to upload; to reduce the presure on dynamic UI side at later steps.
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
			class = 'ldfs_fluidRow',
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

	#790. Create the box with file details.
	output$ldfs_dis <- shiny::renderUI({
		#100. Take dependency from below action (without using its value):
		uRV$df_pkg
		uRV$df_name
		uRV$df_sizeC
		uRV$df_kRows
		uRV$df_kCols

		#200. Return if any of the conditions are not fulfilled
		if (all(is.null(uRV$df_name) , is.null(uRV$df_pkg) , is.null(uRV$kRows) , is.null(uRV$kCols))) return(NULL)

		#Debug Mode
		if (fDebug){
			message(ns(paste0('[790][renderUI][IN][output$ldfs_dis]: UI for Attributes display')))
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
				class = 'ldfs_fluidRow',
				#Group 1: Display the package name
				shiny::column(width = 4,
					class = 'ldfs_Column',
					tippy::tippy_this(
						ns('uDiv_DfPkg'),
						uRV$df_pkg,
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					tippy::tippy_this(
						ns('uWg_AB_DfPkg'),
						'Package Name',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_DfPkg'), 'Package',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('database')
						),
						shiny::tags$div(
							id = ns('uDiv_DfPkg'),
							style = uRV$txt_styles_attr,
							uRV$df_pkg
						)
					#End of [fillRow]
					)
				#End of [column]
				),
				#Group 2: Display the dataframe name
				shiny::column(width = 4,
					class = 'ldfs_Column',
					tippy::tippy_this(
						ns('uDiv_DfName'),
						uRV$df_name,
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					tippy::tippy_this(
						ns('uWg_AB_DfName'),
						'Dataframe Name',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_DfName'), 'Name',
							style = uRV$btn_styles_attr,
							icon = shiny::icon('file')
						),
						shiny::tags$div(
							id = ns('uDiv_DfName'),
							style = uRV$txt_styles_attr,
							uRV$df_name
						)
					#End of [fillRow]
					)
				#End of [column]
				),
				#Group 3: Display the dataframe size
				shiny::column(width = 4,
					class = 'ldfs_Column',
					tippy::tippy_this(
						ns('uWg_AB_DfSize'),
						'RAM Size',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_DfSize'), 'Size',
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
				)
			#End of [fluidRow]
			),
			shiny::fluidRow(
				class = 'ldfs_fluidRow',
				#Group 4: Display the number of rows
				shiny::column(width = 4,
					class = 'ldfs_Column',
					tippy::tippy_this(
						ns('uWg_AB_Dfnrow'),
						'# Rows of the Loaded Table',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_Dfnrow'), '# Rows',
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
					class = 'ldfs_Column',
					tippy::tippy_this(
						ns('uWg_AB_Dfncol'),
						'# Columns of the Loaded Table',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_Dfncol'), '# Cols',
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
					class = 'ldfs_Column',
					tippy::tippy_this(
						ns('uWg_AB_DfInfo'),
						'View Table',
						placement = 'top',
						distance = 2,
						arrow = FALSE
					),
					shiny::fillRow(
						flex = c(1,3),
						height = 34,
						shiny::actionButton(ns('uWg_AB_DfInfo'), 'Detail',
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
			),
			#Print the header of the loaded data in the entire row
			shiny::uiOutput(ns('uDT_TblGlimpse'))
		#End of [div]
		)
	#End of [renderUI] of [790]
	})

	#899. Determine the output value
	#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
	shiny::observeEvent(input$uWg_AB_ConfirmDf,{
		if (input$uWg_AB_ConfirmDf == 0) return()
		uRV_finish(input$uWg_AB_ConfirmDf)
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
		lst_pkg <- c( 'tmcn' , 'pryr' , 'dplyr' , 'DT' ,
			'shiny' , 'shinyjs' , 'shinydashboard' , 'shinydashboardPlus' , 'shinyWidgets' , 'tippy'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		source(paste0(omniR,'\\FileSystem\\getDFinPKG.r'))
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
							UM_LoadDfFrPkg_ui_upload('uMod_LoadDfFrPkg')
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
							UM_LoadDfFrPkg_ui_display('uMod_LoadDfFrPkg')
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

			cfg <- list(NULL)
			cfg$SelType <- 'DfFrPkg'

			observe({
				modout$AnlData <- shiny::callModule(
					UM_LoadDfFrPkg_svr,
					'uMod_LoadDfFrPkg',
					fDebug = FALSE,
					inCfg = cfg
				)
			})
			shiny::observeEvent(modout$AnlData$CallCounter(),{
				if (modout$AnlData$CallCounter() == 0) return()
				message('[AnlData$CallCounter()]:',modout$AnlData$CallCounter())
				message('[AnlData$ActionDone()]:',modout$AnlData$ActionDone())
				message('[AnlData$EnvVariables]:')
				message('[AnlData$EnvVariables()$df_pkg]:',modout$AnlData$EnvVariables()$df_pkg)
				message('[AnlData$EnvVariables()$df_name]:',modout$AnlData$EnvVariables()$df_name)
				message('[AnlData$EnvVariables()$OutCfg]:',modout$AnlData$EnvVariables()$OutCfg)
				message('[AnlData$outdat()]:')
				glimpse(modout$AnlData$outdat())
			})
		}

		shinyApp(ui, server)
	}

}
