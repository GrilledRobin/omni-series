#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to remove the [input] elements from the environment with the provided [id] as clean-up of the remnants   #
#   | of the obselete call of a [shiny module]                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Quotes & Conclusion:                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote: (Below article describes how to clean the inputs and this function is extracted from it)                                    #
#   | https://roh.engineering/post/shiny-add-removing-modules-dynamically/                                                              #
#   |Quote: (Below article shows a full test program of this function)                                                                  #
#   | https://appsilon.com/how-to-safely-remove-a-dynamic-shiny-module/                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |id            :   The id of the [shiny module] from which to remove the [input] elements                                           #
#   |                   IMPORTANT: This must be provided with a namespaced id, otherwise there could be unexpected elements removed!    #
#   |.input        :   The list of [input]s from which to identify the elements to be removed, usually provided as [input]              #
#   |                   IMPORTANT: This must be provided as an [object] instead of a [character string]!                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[NULL]     :   (This function does not return values)                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200509        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200510        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [session] to indicate that the clean-up is to be conducted within a namespace                           #
#   |      |[2] Replace [remove(i)] with [remove(session$ns(i))] to remove values for namespaced inputs                                 #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Packages                                                                                                          #
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

rem_shiny_inputs <- function(id, .input, session){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#100. Remove the input elements from the environment with the provided ID
	#[Quote: [.subset2(.input, 'impl')] is an R6 class of [ReactiveValues]]
	#[Quote: [.subset2(.input, 'impl')$.values] is an R6 class of [Map]]
	invisible(
		lapply(grep(id, names(.input), value = TRUE), function(i) {
			# print(paste0(i,': ',.subset2(.input, 'impl')$.values$get(session$ns(i))))
			.subset2(.input, 'impl')$.values$remove(session$ns(i))
			# print(paste0(i,': ',.subset2(.input, 'impl')$.values$get(session$ns(i))))
		})
	)
}

#[Full Test Program;]
if (FALSE){
	if (TRUE){
		library(shiny)

		clicksUI <- function(id) {
			ns <- shiny::NS(id)
			div(id = 'module_content',
				style = 'background-color: #c9d8f0; width: 200px; padding: 5px',
				actionButton(ns('local_counter'), 'I\'m inside the module'),
				textOutput(ns('local_clicks'))
			)
		}

		clicksModule <- function(input, output, session, local_clicks) {
			session$userData$clicks_observer <- observeEvent(input$local_counter, {
				print(paste('Clicked', input$local_counter))
				local_clicks(input$local_counter)
			}, ignoreNULL = FALSE, ignoreInit = TRUE)

			output$local_clicks <- renderText({
				ns <- session$ns
				paste('Clicks (local view):', input$local_counter)
			})
		}

		ui <- fluidPage(
			shinyjs::useShinyjs(),
			div(
				style = 'background-color: #ffebf3; width: 200px; padding: 5px',
				actionButton('add_module', '', icon = icon('plus-circle')),
				actionButton('remove_module', '', icon = icon('trash'), class = 'disabled'),
				textOutput('local_clicks_out')
			),
			tags$div(
				id = 'container'
			)
		)

		server <- function(input, output, session) {
			local_clicks <- reactiveVal(NULL)

			output$local_clicks_out <- renderText({
				clicks <- 0
				module_clicks <- local_clicks()
				if (!is.null(module_clicks)) {
					clicks <- module_clicks
				}
				paste('Clicks (global view):', clicks)
			})

			observeEvent(input$add_module, {
				insertUI(
					selector = '#container',
					where = 'beforeEnd',
					ui = clicksUI('my_module')
				)

				shinyjs::disable('add_module')
				shinyjs::enable('remove_module')
				callModule(clicksModule, 'my_module', local_clicks)
			})

			observeEvent(input$remove_module, {
				removeUI(selector = '#module_content')
				shinyjs::disable('remove_module')
				shinyjs::enable('add_module')
				rem_shiny_inputs('my_module', input, session)
				local_clicks(input[['my_module-local_counter']])
				session$userData$clicks_observer$destroy()
			})
		}

		shinyApp(ui = ui, server = server)
	}
}
