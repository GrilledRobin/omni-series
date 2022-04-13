#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create a character vector that represents a series of [echarts4r] widgets that can be rendered by     #
#   | [shinyApp]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Quote]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] https://echarts.apache.org/zh/index.html                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This can be useful if one needs to render charts within [DT::datatable]                                                        #
#   |[2] Draw pseudo charts with the labels displayed as the formatted values of the input, to enable tooltips on mouse hovering        #
#   |[3] Display charts within [echarts:tooltip] for another vectorized chart series                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec_value   :   Vector to be used as [labels] to draw the charts, literally accepts any type                                       #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |width       :   Integer vector of the widths of each chart respectively                                                            #
#   |                 [64          ] <Default>                                                                                          #
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |fontFamily  :   Character vector of font family to be translated to CSS syntax                                                     #
#   |                 [<vector>    ] <Default> See function definition                                                                  #
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]                                                  #
#   |                 [14        ] <Default> Common font size                                                                           #
#   |fontColor   :   Character vector of the CSS colors of the labels in each chart respectively                                        #
#   |                 [NULL        ] <Default> Use the default font color from the default theme                                        #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
#   |position    :   Character vector indicating how to place the text inside the cell                                                  #
#   |                 Quote: https://echarts.apache.org/zh/option.html#series-bar.label.position                                        #
#   |                 [insideRight ] <Default> Place the formatted text to the right edge of the cell (within the pseudo bar)           #
#   |                 [see def.    ]           Please see above link to check the other available options                               #
#   |fmtTooltip  :   Character vector of the formatter to tweak the [tooltip] for each chart respectively, this is where to place the   #
#   |                 vectorized charts as [tooltip] for current cell in the datatable                                                  #
#   |                 [IMPORTANT] MUST NOT provide a string of class [htmlwidgets::JS]                                                  #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |jsFmtFloat  :   Character vector of the JS methods applied to JS:Float values (which means [vec_value] for this function) of each  #
#   |                 chart respectively                                                                                                #
#   |                 Quote: https://www.techonthenet.com/js/number_tolocalestring.php                                                  #
#   |                 [<see def.>  ] <Default> Format all values into numbers with fixed decimals as 2, separated by comma              #
#   |as.tooltip  :   Whether to convert the chart into the JS function as formatter of the tooltip of a hosting chart, i.e. this chart  #
#   |                 will become an html element inside the tooltip of another chart                                                   #
#   |                 [FALSE       ] <Default> Output as characterized widget, useful for inline charting in [DT::datatable]            #
#   |                 [TRUE        ]           Convert as tooltip, as this is the most common usage of vectorized charts                #
#   |container   :   Function that takes a single argument of character vector and returns a character vector indicating a series of    #
#   |                 nested HTML tags                                                                                                  #
#   |                 [<func>      ] <Default> Directly return the input vector without any mutation                                    #
#   |as.parts    :   Whether to convert the input into several parts that can be combined into customized HTML scripts                  #
#   |                 [FALSE       ] <Default> Only create a vector of complete JS functions, to represent single object inside each    #
#   |                                           <echarts:tooltip> respectively                                                          #
#   |                 [TRUE        ]           Output separate parts that can be combined with customization from outside this function #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<various>   :   The result is determined by below arguments                                                                        #
#   |                [1] [as.tooltip = FALSE]                                                                                           #
#   |                    A vector of HTML widgets represented as character strings                                                      #
#   |                [2] [as.tooltip = TRUE], the output further depends on the argument [as.parts]                                     #
#   |                    [1] [as.parts = FALSE]                                                                                         #
#   |                        A vector of JS functions to be invoked inside the <tooltip> of anther <echarts> object                     #
#   |                    [2] [as.parts = TRUE]                                                                                          #
#   |                        A data.frame with two columns [js_func] and [html_tags] for customization of HTML scripts                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220406        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220411        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [container] to enable user defined HTML tag container as future compatibility                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220413        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [as.parts] to indicate whether to transform the input vector into separate parts of HTML       #
#   |      |     widgets, as components to be combined into one [echarts:tooltip], see [omniR$Visualization$echarts4r.merge.tooltips]   #
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
#   |   |magrittr, rlang, echarts4r, htmlwidgets, htmltools, dplyr                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |themeColors                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |as.character.htmlwidget                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, echarts4r, htmlwidgets, htmltools, dplyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)
library(rlang)

echarts4r_vec_text <- function(
	vec_value
	,html_id = NULL
	,width = 64
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	,fontColor = NULL
	,position = 'insideRight'
	,fmtTooltip = NULL
	,jsFmtFloat = 'toLocaleString(\'en-US\', {style:\'currency\', currency:\'CNY\', minimumFractionDigits:2, maximumFractionDigits:2})'
	,as.tooltip = FALSE
	,container = function(html_tag){html_tag}
	,as.parts = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	fontHeight <- fontSize
	fontSize <- htmltools::validateCssUnit(fontSize)

	#012. Handle the parameter buffer
	if (length(vec_value) == 0) return(character(0))
	if (length(html_id) == 0) html_id <- NA
	if (length(fmtTooltip) == 0) fmtTooltip <- NA

	#015. Function local variables
	height <- fontHeight + 4

	#100. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = F)

	#200. Create the styles of [tooltip]
	tooltip <- list(
		confine = FALSE
		,appendToBody = TRUE
		,textStyle = list(
			fontFamily = fontFamily
			,fontSize = fontSize
			,color = coltheme[['color']][['tooltip']]
		)
		,backgroundColor = coltheme[['background-color']][['tooltip']]
		,borderColor = coltheme[['border-color']][['tooltip']]
		,extraCssText = paste0(''
			,'box-shadow: ',coltheme[['box-shadow']][['tooltip']]
		)
	)

	#300. Override the colors when required
	if (length(fontColor) == 0) {
		col_font <- coltheme[['color']][['default']]
	} else {
		col_font <- fontColor
	}

	#500. Define helper functions
	#510. Function to apply to all vectors
	h_charts <- function(
		v_val
		,v_barwidth
		,v_float
		,v_html_id
		,v_fmtTT
	){
		#070. Setup tooltip styles
		if (as.tooltip) {
			tooltip_base <- tooltip
		} else {
			tooltip_base <- modifyList(
				tooltip
				,list(
					position = htmlwidgets::JS(paste0(''
						,'function (point, params, dom, rect, size){'
							#鼠标在左侧时 tooltip 显示到右侧，鼠标在右侧时 tooltip 显示到左侧。
							# ,'var obj = {top: 60};'
							# ,'obj[[\'left\', \'right\'][+(pos[0] < size.viewSize[0] / 2)]] = 8;'
							#[IMPORTANT]
							#[1] We cannot locate [iframe] in shinydashboard, hence we have to prefer right side to place the tooltip
							#[2] We apply the same rule to the vertical alignment of the tooltip
							#010. Declare the positions
							,'var x = 0;'
							,'var y = 0;'

							#100. Obtain the relative position from the mouse to the parent node of current DOM
							#[1] Current DOM is the tooltip
							#[2] The parent node of current DOM is the chart
							,'var mouseLeft = point[0];'
							,'var mouseTop = point[1];'

							#200. Obtain the size of current DOM
							,'var boxWidth = size.contentSize[0];'
							,'var boxHeight = size.contentSize[1];'

							#300. Obtain the inner size of current window
							,'var winWidth = window.innerWidth;'
							,'var winHeight = window.innerHeight;'

							#400. Obtain the position of the parent node (i.e. the chart) of current DOM
							#[1] Here the Left and Top are relative to the inner bound of current window
							#[2] Quote: https://blog.csdn.net/mj404/article/details/51246433
							,'var chart = dom.parentNode;'
							,'var chartLeft = chart.getBoundingClientRect().left;'
							,'var chartTop = chart.getBoundingClientRect().top;'

							#500. Calculate the distance from current mouse position to the bottom and right side of the window
							#[1] Quote: https://www.cnblogs.com/jiangxiaobo/p/6593584.html
							#[2] Quote: https://www.cnblogs.com/qixinbo/p/7052808.html
							,'var mouseToRight = winWidth - chartLeft - chart.clientLeft - mouseLeft;'
							,'var mouseToBottom = winHeight - chartTop - chart.clientTop - mouseTop;'

							#600. Calculate the horizontal alignment
							#[1] Place the DOM on the right side as long as there is enough distance
							#[2] Place it to the left side regardless of the space, if above position is unavailable
							,'if (boxWidth <= mouseToRight) {'
								,'x = mouseLeft + Math.min(4, mouseToRight - boxWidth);'
							,'} else {'
								,'x = mouseLeft - boxWidth - 4;'
							,'} '

							#700. Calculate the vertical alignment
							#[1] Always place the DOM 8 pixels right above the bottom edge of the window, to ensure the border is seen
							#[2] Place the DOM 4 pixels down the mouse position where there is enough height
							,'y = mouseTop + Math.min(4, mouseToBottom - boxHeight - 8);'

							#900. Set the position of the DOM
							#[1] All return values here only refer to the relative position from the top-left of its parent node
							,'return [x,y];'
						,'}'
					))
				)
			)
		}
		if (!is.na(v_fmtTT)) {
			tooltip_final <- modifyList(
				tooltip_base
				,list(
					formatter = htmlwidgets::JS(v_fmtTT)
				)
			)
		} else {
			tooltip_final <- modifyList(
				tooltip_base
				,list(
					show = FALSE
				)
			)
		}

		#080. Setup the formatter for the data label, which is to be displayed by default
		if (is.numeric(v_val)) {
			fmt_label <- htmlwidgets::JS(paste0(''
				,'function(params){'
					,'return('
						,'parseFloat(params.value[1]).',v_float
					,');'
				,'}'
			))
		} else {
			fmt_label <- '{b}'
		}

		#600. Create a tiny data.frame to follow the syntax of [echarts4r]
		df <- data.frame(.ech.draw = v_val, .ech.val = 1)

		#900. Create the HTML widget
		#901. Reset the HTML ID if it is provided an invalid one
		if (is.na(v_html_id)) v_html_id <- NULL

		#We use [rlang::expr] to enable the big-bang(!!!) operator
		#910. Initialize the chart
		ch_html <- eval(rlang::expr(
			df %>%
				#[IMPORTANT] It is tested that the size of [canvas] is unexpected if we set [width] or [height] for [e_charts]
				echarts4r::e_charts(.ech.draw, elementId = v_html_id) %>%
				echarts4r::e_grid(
					index = 0
					, top = 2, right = 0, bottom = 0, left = 0
					, height = fontHeight, width = v_barwidth
				) %>%
				#100. Draw a pseudo bar that is transparent as a placeholder to display the label
				echarts4r::e_bar(
					.ech.val
					,x_index = 0
					,y_index = 0
					,label = list(
						show = TRUE
						,distance = 0
						,rotate = 0
						,color = col_font
						,fontFamily = fontFamily
						,fontSize = fontSize
						# ,align = 'left'
						# ,verticalAlign = 'top'
						,borderWidth = 0
						,position = position
						,formatter = fmt_label
					)
					,barWidth = fontHeight
					,tooltip = tooltip_final
					,itemStyle = list(
						color = 'rgba(255,255,255,0)'
					)
					,showBackground = FALSE
				) %>%
				#400. Setup the axes
				echarts4r::e_x_axis(
					index = 0
					,gridIndex = 0
					,show = FALSE
				) %>%
				echarts4r::e_y_axis(
					index = 0
					,gridIndex = 0
					,show = FALSE
					,type = 'value'
					,min = 0
					,max = 1
				) %>%
				#700. Setup the legend
				echarts4r::e_legend(show = FALSE) %>%
				#800. Extra configurations
				#820. Show a loading animation when the chart is re-drawn
				echarts4r::e_show_loading() %>%
				#880. Enable the tooltip triggered by mouse over the bars
				echarts4r::e_tooltip(
					trigger = 'item'
					,enterable = TRUE
					,axisPointer = list(
						show = FALSE
					)
					# ,!!!tooltip_final
				)
		))

		#970. Flip the coordinates
		ch_html %<>%
			echarts4r::e_flip_coords()

		#980. Overwrite the automatically generated size
		#981. Conversion
		ch_html %<>%
			#900. Convert to character vector
			as.character.htmlwidget()

		#983. Search for the HTML ID
		vfy_html_id <- stringr::str_extract_all(ch_html, '(?<=<div\\sid=("|\'))(.+?)(?=\\1)')[[1]][[1]]

		#989. Overwrite the original rect
		ch_html %<>%
			#920. Setup the shape of the canvas
			{gsub(
				paste0('(?<=<div\\sid=("|\')',vfy_html_id,'\\1\\sstyle=("|\'))width:(\\d+(%|px));\\s*height:(\\d+(%|px));')
				,paste0(''
					,'width:',v_barwidth + 16,'px !important;'
					,'height:',height,'px !important;'
				)
				,.
				,perl = T
			)}

		#999. Make the return value explicit
		return(ch_html)
	}

	#600. Generate the charts
	ch_html <- eval(rlang::expr(mapply(
		h_charts
		, vec_value
		, width
		, jsFmtFloat
		, html_id
		, fmtTooltip
		, SIMPLIFY = TRUE
	)))

	#700. Directly return if no need to convert it to tooltip
	if (!as.tooltip) return(ch_html)

	#800. Function as container for creating the tooltip out of current chart
	#[IMPORTANT]
	#[1] We must set the <echarts> object names BEFORE the definition of the container, as they are referenced inside the container
	#[2] Program will automatically search for the variable by stacks, hence there is no need to worry about the environment nesting
	ech_obj_name <- paste0('ttText_', as.integer(runif(length(ch_html)) * 10^7))
	h_contain <- function(html_tag){
		paste0(''
			#Quote: https://www.cnblogs.com/zhuzhenwei918/p/6058457.html
			,'<div style=\'display:inline-block;margin:0;padding:0;font-size:0;width:',width,'px;height:',height,'px;\'>'
				,'<div style=\'display:inherit;font-size:',fontSize,';width:',width,'px;height:',height,'px;\'>'
					,html_tag
				,'</div>'
			,'</div>'
		)
	}

	#890. Nest the containers when necessary
	if (is.function(container)) {
		container_multi <- function(html_tag){ h_contain(html_tag) %>% container() }
	} else {
		container_multi <- h_contain
	}

	#900. Convert the widget into tooltip
	ch_tooltip <- echarts4r.as.tooltip(ch_html, container = container_multi, ech_name = ech_obj_name, as.parts = as.parts)

	#999. Return the vector
	return(ch_tooltip)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#020. Simulate the private environment of Shiny App, to generalize the usage of this function
		uRV <- list()

		#050. Choose theme
		uRV$theme <- 'BlackGold'
		uRV$coltheme <- themeColors(uRV$theme)

		#100. Create sample data
		ch_mtcar <- mtcars %>%
			tibble::rownames_to_column('brand') %>%
			dplyr::group_by(cyl) %>%
			dplyr::summarise(
				brand = dplyr::last(brand)
				,hp_min = min(hp, na.rm = T)
				,hp_max = max(hp, na.rm = T)
				,hp_curr = dplyr::last(hp)
				,hp_mean = mean(hp, na.rm = T)
				,qsec_min = min(qsec, na.rm = T)
				,qsec_max = max(qsec, na.rm = T)
				,qsec_curr = dplyr::last(qsec)
				,qsec_mean = mean(qsec, na.rm = T)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				hp_ymin = min(mtcars$hp, na.rm = T)
				,hp_ymax = max(mtcars$hp, na.rm = T)
				,hp_color = ifelse(
					hp_curr * 0.7 >= hp_mean
					, uRV$coltheme[['color']][['chart-bar-incr']]
					, uRV$coltheme[['color']][['chart-bar-decr']]
				)
				,qsec_color = ifelse(
					qsec_curr * 1.1 >= qsec_mean
					, themePalette('PBI')$blue$d
					, themePalette('PBI')$orange$d
				)
			) %>%
			dplyr::mutate(
				hp_text = echarts4r_vec_text(
					hp_curr
					,width = 32
					,theme = uRV$theme
					,fontFamily = c('宋体')
					,jsFmtFloat = 'toFixed(0)'
				)
				,hp_text2 = echarts4r_vec_text(
					qsec_mean
					,width = 64
					,theme = uRV$theme
				)
				,brand_text = echarts4r_vec_text(
					brand
					,width = 100
					,theme = uRV$theme
					,fontFamily = c('Microsoft YaHei')
					,position = 'insideLeft'
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('cyl','hp_text', 'hp_text2','brand_text')
		dt_mtcar <- DT::datatable(
			ch_mtcar %>% dplyr::select(tidyselect::all_of(cols))
			#Only determine the columns to be displayed, rather than the columns to extract from the input data
			,colnames = cols
			,width = '100%'
			,class = 'compact display'
			,fillContainer = TRUE
			,escape = FALSE
			,options = list(
				#Setup the styles for the table header
				initComplete = htmlwidgets::JS(paste0(
					# 'function(settings, json){'
					# 	,'$(this.api().table().header()).css({'
					# 		,'"background-color": "#625C54"'
					# 		,',"color": "#FFE8CB"'
					# 		,',"font-family": "\'sans-serif\',\'Microsoft YaHei\'"'
					# 		,',"font-size": "10px"'
					# 	,'});'
					# ,'}'
				))
				#We have to set the [stateSave=F], otherwise the table cannot be displayed completely!!
				,stateSave = FALSE
				,ordering = FALSE
				,scrollX = FALSE
				#[Show N entries] on top left
				,pageLength = 2
				,lengthMenu = c(2,4,10,-1)
			)
		) %>%
			add_datatable_render_code() %>%
			add_deps('echarts4r', 'echarts4r') %>%
			#Below is useful for debugging from console
			htmltools::browsable()

		#900. Create [shinyApp] to render the table
		if (interactive()) {
			library(shiny)

			ui <- shinydashboardPlus::dashboardPage(
				header = shinydashboardPlus::dashboardHeader()
				,sidebar = shinydashboardPlus::dashboardSidebar()
				,body = shinydashboard::dashboardBody(
					shinyjs::useShinyjs()
					,shiny::fluidPage(
						shiny::tags$style(
							type = 'text/css'
							,paste0(''
								,'.main-header .navbar, .main-header .logo {'
									,'background-color: ',uRV$coltheme[['background-color']][['default']],' !important;'
								,'}'
								,'.main-sidebar {'
									,'background-color: ',uRV$coltheme[['background-color']][['default']],' !important;'
								,'}'
								,'.content-wrapper {'
									,'background-color: ',uRV$coltheme[['background-color']][['default']],' !important;'
								,'}'
							)
						)
						,shinydashboardPlus::box(
							width = 12
							,shiny::tags$style(
								type = 'text/css'
								,paste0(''
									,'.box {'
										,'background-color: ',uRV$coltheme[['background-color']][['default']],' !important;'
									,'}'
								)
							)
							,shiny::uiOutput('uDiv_DashTables')
						)
					)
				)
				,controlbar = shinydashboardPlus::dashboardControlbar()
				,title = 'DashboardPage'
			)
			server <- function(input, output, session) {
				output$uDiv_DashTables <- shiny::renderUI({

					shiny::tagList(
						theme_datatable(theme = uRV$theme, transparent = T)
						,dt_mtcar
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}
}
