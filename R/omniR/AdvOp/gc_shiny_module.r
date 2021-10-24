#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to clean-up the remnants of the obselete call of a [shiny module], so called Garbage Collection          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Operation:                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Remove the [UI]s from the list of containers as provided                                                                       #
#   |[2] Remove the [input] elements from the namespaced [module ID] as provided                                                        #
#   |[3] Destroy the [observers] named in certain convention, preferrably prefixed by the namespaced [module ID]                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Scenarios:                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 某个module在当前app中被反复调用（通常为变换参数后重新调用）；如查看不同数据的summary                                           #
#   |[2] 同一个module在当前app中的不同区域分别调用；如封装好的作图组件在不同页面作不同的图                                              #
#   |[3] 防止页面刷新后原先module中的observers仍然有效运行                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Quotes & Conclusion:                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote: (Below article describes how to clean the inputs)                                                                           #
#   | https://roh.engineering/post/shiny-add-removing-modules-dynamically/                                                              #
#   |Quote: (Below article shows a full test program of this function)                                                                  #
#   | https://appsilon.com/how-to-safely-remove-a-dynamic-shiny-module/                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |module_id     :   The namespaced ID of the module, for which to clean-up the remnants                                              #
#   |.input        :   The list of [input]s from which to identify the elements to be removed, usually provided as [input]              #
#   |                   IMPORTANT: This must be provided as an [object] instead of a [character string]!                                #
#   |session       :   The session in which to conduct the clean-up, usually provided as current [session]                              #
#   |                   IMPORTANT: This must be provided as a [session object] instead of a [character string]!                         #
#   |UI_Selectors  :   The list of selectors from which to remove [UI]s                                                                 #
#   |                   [1] The selectors are available for [shiny::removeUI]. See documents for parameter convention.                  #
#   |                   [2] Each of the selector names will be prefixed by: ['#' + module_id] when [UI_namespaced==T]                   #
#   |                   [3] [NULL] is the default value of the parameter                                                                #
#   |UI_namespaced :   Whether or not is the [UI_Selectors] namespaced, useful for when the [UI] is created in the caller app           #
#   |                   [TRUE ]<default> Consider the [UI_Selectors] are namespaced when trying removal                                 #
#   |                   [FALSE]          Consider the [UI_Selectors] are not namespaced when trying removal                             #
#   |observer_pfx  :   The naming prefix of the [observer]s to be destroyed                                                             #
#   |                   [1] Naming convention of observers is: [ session$userData[[paste(ns(observer_pfx),'name',sep='_')]] ]           #
#   |                   [2] Following above naming convention, ensure the [observer]s in the [module] are stored in [session$userData]  #
#   |                   [3] 'uObs' is the default value of the parameter, representing: User-defined Observer                           #
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
#   |   |Directory: [omniR$AdvOp]                                                                                                       #
#   |   |   |rem_shiny_inputs                                                                                                           #
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

gc_shiny_module <- function(module_id, .input, session, UI_Selectors = NULL, UI_namespaced = T, observer_pfx = 'uObs'){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	#We must ensure the prefix of the observers exist, otherwise all the similar observers will be destroyed!
	if (length(observer_pfx) == 0) observer_pfx <- 'uObs'

	#100. Remove the UIs if any
	lapply(UI_Selectors, function(m) {
		#Prepend the [module_id] to the name in terms of the shiny convention
		if (UI_namespaced) m <- paste(module_id, m, sep = shiny::ns.sep)

		#UI removal
		shiny::removeUI(selector = paste0('#', m))
	})

	#400. Remove the input elements from the environment with the provided ID
	#Since [.input] is in the same environment as [session], there is no need to further namespace the [module_id].
	rem_shiny_inputs(module_id, .input, session)

	#700. Destroy the observers
	#710. Escape the backslashes in the prefix character string, for we will match them in regular expression soon
	#Since the naming convention is set as: [ session$userData[[paste(ns(observer_pfx),'name',sep='_')]] ],
	# names of all the observers defined within the module are prefixed by [shiny::NS].
	#Hence we also need to prefix the [module_id] in order to find the correct observers from the caller environment.
	obs_pfx <- paste(session$ns(module_id), gsub('\\\\', '\\\\\\\\', observer_pfx), sep = shiny::ns.sep)

	#740. Retrieve the available names in [session$userData]
	names_usrData <- names(session$userData)
	# print(names_usrData)
	# print(obs_pfx)

	#770. Try to destroy the obsersers as matching the naming convention
	#Keep silent when the object is NOT an observer, or the observer can no longer be destroyed
	lapply(names_usrData[grep(paste0('^', obs_pfx), names_usrData, perl = T)], function(m) {
		try(session$userData[[m]]$destroy(), silent = T)
	})
}

#[Full Test Program;]
if (FALSE){
	if (TRUE){
		library(shiny)

		clicksUI <- function(id) {
			ns <- shiny::NS(id)
			div(id = ns('module_content'),
				style = 'background-color: #c9d8f0; width: 200px; padding: 5px',
				actionButton(ns('local_counter'), 'I\'m inside the module'),
				textOutput(ns('local_clicks'))
			)
		}

		clicksModule <- function(input, output, session, local_clicks) {
			ns <- session$ns
			session$userData[[paste(ns('uObs'),'clicks',sep = '_')]] <- observeEvent(input$local_counter, {
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
				# removeUI(selector = '#module_content')
				shinyjs::disable('remove_module')
				shinyjs::enable('add_module')
				# rem_shiny_inputs('my_module', input)
				local_clicks(input[['my_module-local_counter']])
				# session$userData$clicks_observer$destroy()
				gc_shiny_module(
					'my_module'
					,input
					,session
					,UI_Selectors = 'module_content'
					,UI_namespaced = T
					,observer_pfx = 'uObs'
				)
			})
		}

		shinyApp(ui = ui, server = server)
	}
}
