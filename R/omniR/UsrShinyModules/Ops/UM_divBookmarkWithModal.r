# User Defined Module: [Add a bookmark to the parent division with modal for user to input text]
# Required User-specified parameters:

# [Quote: 'SVA': Single Variable Analysis]
# [Quote: 'uDiv': User defined Division]
# [Quote: 'uWg': User defined Widgets]
# [Quote: 'PO': User defined shinyBS:bsPopover]
# [Quote: 'tAI': User defined textAreaInput]

# Required User-specified modules:

# Required User-specified functions:
# [Quote:[omniR$Styles$AdminLTE_colors.r]]

UM_divBookmarkWithModal_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_BM'))
}

UM_divBookmarkWithModal_svr <- function(input,output,session,
	fDebug = FALSE,text_in = NULL,btn_styles = NULL,themecolorset = NULL,...){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	uRV$text_out <- text_in
	uRV$placeholder <- 'Click to add remarks'
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- shiny::reactiveVal(0)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[Module Call][UM_divBookmarkWithModal]')))
	}

	#010. Initialize the icon of the bookmark
	if (isTRUE(nchar(paste0(text_in,''))==0)) {
		uRV$BMicon <- shiny::icon('bookmark-o')
		uRV$content <- uRV$placeholder
	} else {
		uRV$BMicon <- shiny::icon('bookmark')
		#Trim the characters when the content is longer than 520 bytes
		if (nchar(text_in,type = 'bytes')>520) {
			uRV$content <- shiny::HTML(
				paste0(
					substr(text_in,1,200),
					'...<br/>',
					'(Click to see more)'
				)
			)
		} else {
			uRV$content <- shiny::HTML(text_in)
		}
	}

	#200. General settings of styles for the output charts
	#201. Prepare the styles for the buttons
	if (isTRUE(nchar(paste0(btn_styles,''))==0)) {
		uRV$btn_styles <- paste0(
			'text-align: center;',
			'color: ',ifelse(is.null(themecolorset),AdminLTE_color_primary,themecolorset$s08$p[[length(themecolorset$s08$p)]]),';',
			'padding: 0;',
			'margin: 0;',
			#Refer to documents of [echarts4r]
			'font-size: 13px;',
			'border: none;',
			'background-color: rgba(0,0,0,0);'
		)
	} else {
		uRV$btn_styles <- btn_styles
	}

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			#[Quote: https://www.w3school.com.cn/cssref/pr_dim_max-width.asp ]
			#Below size can hold 520 bytes or 260 Chinese characters at maximum
			'.popover {',
				'max-width: 400px;',
				'max-height: 250px;',
			'}',
			#[Quote: https://www.w3cschool.cn/cssref/css3-pr-word-wrap.html ]
			'.popover-content {',
				'word-wrap: break-word;',
			'}'
		)
	)

	#400. Prepare the contents
	#410. Monitor the change upon the content
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_Save

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[410][observe][IN][input$uWg_AB_Save]:',input$uWg_AB_Save)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_Save)) return()
				if (input$uWg_AB_Save == 0) return()

				#100. Overwrite the output result
				uRV$text_out <- input$uWg_tAI_UsrText

				#500. Check whether the new character string is different from the original one
				if (isTRUE(nchar(paste0(uRV$text_out,''))==0)) {
					uRV$BMicon <- shiny::icon('bookmark-o')
					uRV$content <- uRV$placeholder
				} else {
					uRV$BMicon <- shiny::icon('bookmark')
					#Trim the characters when the content is longer than 520 bytes
					if (nchar(uRV$text_out,type = 'bytes')>520) {
						uRV$content <- shiny::HTML(
							paste0(
								substr(uRV$text_out,1,200),
								'...<br/>',
								'(Click to see more)'
							)
						)
					} else {
						uRV$content <- shiny::HTML(uRV$text_out)
					}
				}

				#700. Close the modal
				shiny::removeModal()

				#900. Mark the completion
				#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
				uRV_finish(uRV_finish() + 1)
				uRV$ActionDone <- TRUE
			#End of [isolate]
			})
		}
		,label = ns('[410]Update the output text if the input has changed')
	)

	#450. Form the modal
	shiny::observe(
		{
			#100. Take dependencies
			uRV$text_out

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[450][observe][IN][uRV$text_out]:<',uRV$text_out,'>')))
				}

				#900. Create a new modal
				uRV$BMmodal <- shiny::modalDialog(
					shiny::textAreaInput(ns('uWg_tAI_UsrText'),NULL,
						value = uRV$text_out,
						width = '570px',
						height = '200px',
						resize = 'vertical'
					),
					title = 'Notes',
					footer = shiny::tagList(
						shiny::modalButton('Cancel'),
						shiny::actionButton(ns('uWg_AB_Save'), 'Save')
					)
				)
			#End of [isolate]
			})
		}
		,label = ns('[450]Create a modal with the updated content')
	)

	#490. Pop out the modal when clicking on the bookmark
	shiny::observeEvent(input$uWg_AB_OpenModal,
		{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[460][observeEvent][IN][input$uWg_AB_OpenModal]:',input$uWg_AB_OpenModal)))
			}
			shiny::showModal(uRV$BMmodal)
		}
		,label = ns('[460]Popup the modal once clicking on the bookmark')
	)

	#700. Prepare UIs
	#710. Add a bookmark icon to the parent division
	output$uDiv_BM <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[710][renderUI][IN][output$uDiv_BM]:')))
		}

		#100. Take dependencies
		#Even if the icon is changed, we do not render this UI for another time, for we have already changed the icon by JS.
		uRV$styles_final
		uRV$btn_styles
		uRV$BMicon
		#We put the popover as the last dependency so that it can display correctly.
		uRV$content

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::isolate({
			shiny::tagList(
				#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
				shiny::tags$style(
					type = 'text/css',
					uRV$styles_final
				),

				shiny::tags$div(...,

					#Create the bookmark
					shiny::actionButton(ns('uWg_AB_OpenModal'), NULL,
						style = uRV$btn_styles,
						icon = uRV$BMicon
					) %>%
						shinyBS::popify (
							'<em>Notes Preview</em>',
							content = uRV$content,
							placement = 'bottom',
							#[Quote: https://getbootstrap.com/docs/4.3/components/tooltips/ ]
							options = list(
								container = 'body',
								html = TRUE,
								boundary = 'viewport'
							)
						#End of [bsPopover]
						)
				#End of [box]
				)

			)
		})
	#End of [renderUI] of [710]
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
		lst_pkg <- c( 'tmcn' , 'readr' , 'dplyr' ,
			'shiny' , 'shinyjs' , 'V8' , 'shinydashboard' , 'shinydashboardPlus' , 'shinyBS'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		omniR <- 'D:\\R\\omniR'
		source('D:\\R\\Project\\myApp\\Func\\UI\\theme_color_sets.r')

		ui <- shinydashboardPlus::dashboardPagePlus(
			header = shinydashboardPlus::dashboardHeaderPlus(),
			sidebar = shinydashboard::dashboardSidebar(),
			body = shinydashboard::dashboardBody(
				shinyjs::useShinyjs(),
				shinyjs::extendShinyjs(script = 'D:/R/Project/myApp/www/script/shinyjsExtension.js'),
				shiny::fluidPage(
					shiny::column(width = 3,
						UM_divBookmarkWithModal_ui('bmwm'),
						shiny::tags$div(
							style = 'border: solid;',
							'Test bookmark'
						)
					)
				)
			),
			rightsidebar = shinydashboardPlus::rightSidebar(),
			title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$bmwm <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0),
				ActionDone = shiny::reactive({FALSE}),
				EnvVariables = shiny::reactive({NULL})
			)

			shiny::observe(
				{
					#100. Take dependencies

					#900. Execute below block of codes only once upon the change of any one of above dependencies
					# shiny::isolate({
						modout$dbmwm <- shiny::callModule(
							UM_divBookmarkWithModal_svr,
							'bmwm',
							fDebug = FALSE,
							text_in = NULL,
							themecolorset = myApp_themecolorset,
							style = paste0(
								'position: absolute;',
								'right: 20%;',
								'top: 0;'
							)
						)
					#End of [isolate]
					# })
				}
				,label = '[500]Monitor the status of the module call'
			)
			shiny::observeEvent(modout$dbmwm$CallCounter(),{
				if (modout$dbmwm$CallCounter() == 0) return()
				message('[dbmwm$CallCounter()]:',modout$dbmwm$CallCounter())
				message('[dbmwm$EnvVariables()$text_out]:',modout$dbmwm$EnvVariables()$text_out)
			})
		}

		shinyApp(ui, server)
	}

}
