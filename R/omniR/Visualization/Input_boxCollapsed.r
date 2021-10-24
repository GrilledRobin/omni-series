#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create an invisible [input] widget to monitor the expanded/collapsed status of [shiny::box] and       #
#   | [shinydashboardPlus::boxPlus]                                                                                                     #
#   |Quote: https://stackoverflow.com/questions/45462614/how-to-see-if-a-shiny-dashboard-box-is-collapsed-from-the-server-side          #
#   |IMPORTANT!!!                                                                                                                       #
#   |It MUST be called AFTER the UI which triggers the JS function created by it!                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inputId    :   The ID of the input widget that triggers [shiny] event                                                              #
#   |                Enclose it by [shiny::NS] to create session-specific ID when creating a Module                                     #
#   |boxId      :   The ID of the box/boxPlus for which to monitor the status                                                           #
#   |                Enclose it by [shiny::NS] to create session-specific ID when creating a Module                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[boolean]  :   Whether the dedicated box/boxPlus is collapsed                                                                      #
#   |                [TRUE]  Collapsed                                                                                                  #
#   |                [FALSE] Expanded                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200311        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |shiny                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

Input_boxCollapsed <- function(inputId, boxId){
	shiny::tags$script(
		sprintf(
			"$('#%s').closest('.box').on('hidden.bs.collapse', function(){Shiny.onInputChange('%s', true);})",
			boxId, inputId
		),
		sprintf(
			"$('#%s').closest('.box').on('shown.bs.collapse', function(){Shiny.onInputChange('%s', false);})",
			boxId, inputId
		)
	)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		library(shiny)
		library(shinydashboard)
		library(shinyjs)

		testCollapse_ui <- function(id){
			#Set current Name Space
			ns <- NS(id)

			shiny::tagList(
				shiny::fluidRow(
					shiny::actionButton(ns("bt1"), "Collapse box1"),
					shiny::actionButton(ns("bt2"), "Collapse box2")
				),
				shiny::fluidRow(
					shinydashboard::box(id = ns("box1"), title = "Header 1", collapsible = TRUE, p("Box 1")),
					shinydashboard::box(id = ns("box2"), title = "Header 2", collapsible = TRUE, p("Box 2"))
				),
				shiny::fluidRow(
					shiny::verbatimTextOutput(outputId = ns("res"))
				)
				,
				# shiny::tags$div(
					Input_boxCollapsed(inputId = ns("iscollapsebox1"), boxId = ns("box1"))
				# )
			#End of [list]
			)
		}

		testCollapse_svr <- function(input,output,session){
			ns <- session$ns

			# [Quote:[omniR$Visualization$shinyjsExtension.js]]
			shiny::observeEvent(input$bt1, {
				shinyjs::js$collapse(ns("box1"))
			})
			shiny::observeEvent(input$bt2, {
				shinyjs::js$collapse(ns("box2"))
			})

			output$res <- shiny::renderPrint({
				paste0('Box 1 collapsed: ',input$iscollapsebox1)
			})
		}



		ui <- shinydashboard::dashboardPage(
			shinydashboard::dashboardHeader(),
			shinydashboard::dashboardSidebar(),
			shinydashboard::dashboardBody(
				shinyjs::useShinyjs(),
				shinyjs::extendShinyjs(script = "D:/R/omniR/Visualization/shinyjsExtension.js"),
				testCollapse_ui("test")
			)
		)

		server <- function(input, output) {
			shiny::observe({
				shiny::callModule(testCollapse_svr,'test')
			})
		}

		shinyApp(ui, server)

	}
}

