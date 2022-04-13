#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create a character vector that represents a series of [echarts4r] widgets that can be rendered by     #
#   | [shinyApp], via vectorized calculation process, which enables the vectorized charting by groups in a data.frame                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |It is always recommended to use single quotes, instead of double quotes, during the character string manipulation, as [shQuote] is #
#   | called to convert these strings into HTML or JS scripts for at least once                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Quote]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] https://echarts.apache.org/zh/option.html#series-pie                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This can be useful if one needs to render charts within [DT::datatable]                                                        #
#   |[2] Draw charts for groups of keys split into several categories, such as distribution of Product Holdings of customer AUM         #
#   |[3] Draw charts within [echarts:tooltip] for another vectorized chart series                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec_value   :   Numeric vector to be used as [values] to draw the charts                                                           #
#   |vec_cat     :   Vector by which to slice the pie                                                                                   #
#   |sortBy      :   Character vector to determine how to display the slices in specific order                                          #
#   |                 [input       ] <Default> The order follows the input sequence of [vec_cat]                                        #
#   |                 [category    ]           Function sorts the input data by [vec_cat] in ASCENDING order and then draw the chart    #
#   |                 [value       ]           Function sorts the input data by [vec_value] in DESCENDING order and then draw the chart #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |height      :   Integer of the chart height                                                                                        #
#   |                 [540         ] <Default>                                                                                          #
#   |width       :   Integer of the chart width                                                                                         #
#   |                 [960         ] <Default>                                                                                          #
#   |sliceColor  :   Character as the CSS color of the slices in current chart                                                          #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
#   |roseType    :   Logical or character vector of whether or how to display the pie in rose type                                      #
#   |                Quote: https://echarts.apache.org/zh/option.html#series-pie.roseType                                               #
#   |                 [FALSE       ] <Default> Display the chart in normal pie form                                                     #
#   |avoidLabelOverlap : Whether to avoid the overlap of the labels of slices                                                           #
#   |                 [FALSE       ] <Default> Allow overlap of the data labels, as all labels are displayed in the center of the chart #
#   |                 [TRUE        ]           Move the labels given any are overlapped                                                 #
#   |label_show  :   Whether to always show the label of the slices                                                                     #
#   |                 [FALSE       ] <Default> Only show the label when hovering on any slice                                           #
#   |                 [TRUE        ]           Always show the labels of all slices                                                     #
#   |label_pos   :   Character value that indicates the position of the labels of the slices                                            #
#   |                 [center      ] <Default> Display the label at the center of the ring                                              #
#   |rad_inner   :   Character or numeric vector as the radius of the inner circle of the pie                                           #
#   |                 [0           ] <Default> Draw a classic pie instead of a ring chart                                               #
#   |rad_outer   :   Character or numeric vector as the radius of the outer circle of the pie                                           #
#   |                 [75%         ] <Default> Default proportion to the smaller among the rects of the container for the chart         #
#   |title       :   Character as the title of current chart, taking the first value if the vector contains multiple values             #
#   |                 [Pie         ] <Default> Name all charts with this one                                                            #
#   |titleSize   :   Integer of the font size of the chart title                                                                        #
#   |                 [18          ] <Default> Common font size                                                                         #
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |transparent :   Whether to set the background as transparent                                                                       #
#   |                 [TRUE        ] <Default> Set the alpha of background color as 0                                                   #
#   |                 [FALSE       ]           Use the theme color                                                                      #
#   |fontFamily  :   Character vector of font family to be translated to CSS syntax                                                     #
#   |                 [<vector>    ] <Default> See function definition                                                                  #
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]                                                  #
#   |                 [14          ] <Default> Common font size                                                                         #
#   |jsFmtFloat  :   Character vector of the JS methods applied to JS:Float values (which means [vec_value] for this function) of each  #
#   |                 chart respectively                                                                                                #
#   |                 Quote: https://www.techonthenet.com/js/number_tolocalestring.php                                                  #
#   |                 [<see def.>  ] <Default> Format all values into numbers with fixed decimals as 2, separated by comma              #
#   |fmtLabel    :   Character as the formatter to tweak the [label] for the highlighted categories of current chart                    #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |as.tooltip  :   Whether to convert the chart into the JS function as formatter of the tooltip of a hosting chart, i.e. this chart  #
#   |                 will become an html element inside the tooltip of another chart                                                   #
#   |                 [TRUE        ] <Default> Convert as tooltip, as this is the most common usage of vectorized charts                #
#   |                 [FALSE       ]           Output as characterized widget, useful for inline charting in [DT::datatable]            #
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
#   | Date |    20220405        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |   |rgba2rgb                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |as.character.htmlwidget                                                                                                    #
#   |   |   |echarts4r.as.tooltip                                                                                                       #
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

#Require [echarts4r >= 0.4.3]

echarts4r_vec_pie <- function(
	vec_value
	,vec_cat
	,sortBy = c('input','category','value')
	,html_id = NULL
	,height = 440
	,width = 640
	,sliceColor = NULL
	,roseType = FALSE
	,avoidLabelOverlap = FALSE
	,label_show = FALSE
	,label_pos = 'center'
	,rad_inner = 144
	,rad_outer = 184
	,title = 'Pie'
	,titleSize = 18
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = TRUE
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	,jsFmtFloat = 'toLocaleString(\'en-US\', {style:\'currency\', currency:\'CNY\', minimumFractionDigits:2, maximumFractionDigits:2})'
	,fmtLabel = NULL
	,as.tooltip = TRUE
	,container = function(html_tag){html_tag}
	,as.parts = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (height <= 124) {
		stop('[',LfuncName,'][height] is too small!')
	}
	if (width <= 108) {
		stop('[',LfuncName,'][width] is too small!')
	}
	sortBy <- match.arg(sortBy, c('input','category','value'))
	fontSize <- htmltools::validateCssUnit(fontSize)

	#012. Handle the parameter buffer
	if (length(vec_value) != length(vec_cat)) {
		stop('[',LfuncName,'][vec_value] has different length [',length(vec_value),'] to [vec_cat] as [',length(vec_cat),']!')
	}
	if ((length(vec_value) == 0) | (length(vec_cat) == 0)) return(character(0))
	if (!(length(sliceColor) %in% c(0,1,length(vec_cat)))) {
		stop('[',LfuncName,'][sliceColor] has length [',length(sliceColor),'], which is different to the input data!')
	}
	len_data <- length(vec_value)

	#015. Function local variables
	v_roseType <- head(roseType, 1)
	v_avoidLabelOverlap <- head(avoidLabelOverlap, 1)
	v_label_show <- head(label_show, 1)
	v_label_pos <- head(label_pos, 1)

	#100. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = transparent)
	tt_theme <- themeColors(theme, transparent = F)

	#200. Setup styles
	#210. Create the styles of [tooltip] for this specific chart
	tooltip <- list(
		textStyle = list(
			fontFamily = fontFamily
			,fontSize = fontSize
			,color = tt_theme[['color']][['tooltip']]
		)
		,backgroundColor = tt_theme[['background-color']][['tooltip-inverse']]
		,borderColor = tt_theme[['border-color']][['tooltip']]
		,extraCssText = paste0(''
			,'box-shadow: ',tt_theme[['box-shadow']][['tooltip']]
		)
	)

	#250. Format the tooltip for current chart
	if (length(fmtLabel) > 0) {
		tooltip_sym <- modifyList(tooltip, list(formatter = htmlwidgets::JS(fmtLabel)))
	} else {
		tooltip_sym <- modifyList(
			tooltip
			,list(
				formatter = htmlwidgets::JS(paste0(''
					,'function(params){'
						,'return('
							#Quote: https://www.tutorialspoint.com/how-to-convert-a-value-to-a-string-in-javascript
							,'\'<strong>\' + String(params.name) + \'</strong>\''
							,'+ \'<br/>\' + parseFloat(params.value).',jsFmtFloat
						,');'
					,'}'
				))
			)
		)
	}

	#300. Prepare the internal data frame to pre-process the charting options
	df_chart <- data.frame(.ech.cat = vec_cat, .ech.value = vec_value)
	if (length(sliceColor) != 0) {
		df_chart$.ech.col <- sliceColor
	}

	#310. Determine the display order of the slices
	if (sortBy == 'category') {
		df_chart %<>% dplyr::arrange(.ech.cat)
	} else if (sortBy == 'value') {
		df_chart %<>% dplyr::arrange(dplyr::desc(.ech.value))
	}

	#400. Override the colors when required
	#410. Determine the background color for interpolation
	if (as.tooltip) {
		col_bg <- coltheme[['background-color']][['tooltip']]
	} else {
		col_bg <- coltheme[['background-color']][['default']]
	}

	#450. Determine the colors of the slices
	if (length(sliceColor) == len_data) {
		col_slice <- df_chart$.ech.col
	} else {
		#100. Determine the base color to create a series of colors that cover all the input categories
		if (length(sliceColor) == 0) {
			col_base <- coltheme[['color']][['chart-pie']]
		} else {
			col_base <- sliceColor
		}

		#300. Prepare the interpolation of alpha between 0.07 (the least effective value) and 1
		alpha_interp <- round(1 - (seq_len(len_data) - 1) * (1 - 0.07) / (len_data - 1), 2)

		#900. Create the colors based on the interpolation
		col_slice <- rgba2rgb(col_base, alpha_in = alpha_interp, color_bg = col_bg)
	}

	#500. Create the charting script
	ch_html <- eval(rlang::expr(
		data.frame(.ech.cat = vec_cat, .ech.value = vec_value) %>%
		#[IMPORTANT] It is tested that the size of [canvas] is unexpected if we set [width] or [height] for [e_charts]
		echarts4r::e_charts(.ech.cat, elementId = html_id) %>%
		echarts4r::e_grid(
			index = 0
			, top = 0, right = 0, bottom = 0, left = 0
			, height = height - 24, width = width - 16
			, containLabel = TRUE
		) %>%
		#300. Draw the chart
		echarts4r::e_pie(
			.ech.value
			,roseType = v_roseType
			,avoidLabelOverlap = v_avoidLabelOverlap
			,name = 'Pie'
			,left = 16
			,top = 24
			,legend = list(
				show = TRUE
			)
			,showEmptyCircle = TRUE
			,emptyCircleStyle = list(
				color = rgba2rgb(coltheme[['color']][['chart-pie']], alpha_in = 0.07, color_bg = col_bg)
				,borderWidth = 0
			)
			,label = list(
				show = v_label_show
				,position = v_label_pos
				,fontFamily = fontFamily
				,fontSize = titleSize
				,color = coltheme[['color']][['header']]
				,borderWidth = 0
				,formatter = htmlwidgets::JS(paste0(''
					,'function(params){'
						,'var placeholder = \'\';'
						,'return('
							,'placeholder + parseFloat(params.value).',jsFmtFloat
						,');'
					,'}'
				))
			)
			,labelLine = list(
				show = !v_label_show
				,lineStyle = list(
					color = rgba2rgb(coltheme[['color']][['chart-pie']], alpha_in = 0.5, color_bg = col_bg)
					,width = 1
				)
			)
			,itemStyle = list(
				#Obtain the color from the global color palette [echarts4r::e_color()]
				borderWidth = 0
			)
			,center = list('30%', '50%')
			,radius = list(rad_inner, rad_outer)
			,emphasis = list(
				label = list(
					show = TRUE
				)
			)
		) %>%
		#500. Setup the title
		echarts4r::e_title(
			text = title
			,left = 8
			,top = 4
			,textStyle = list(
				fontFamily = fontFamily
				,fontSize = titleSize
				,color = coltheme[['color']][['header']]
			)
		) %>%
		#700. Setup the legend
		echarts4r::e_legend(
			show = TRUE
			,right = '10%'
			,top = 'center'
			,orient = 'vertical'
			,textStyle = list(
				fontFamily = fontFamily
				,fontSize = fontSize
				,color = coltheme[['color']][['header']]
			)
		) %>%
		#800. Extra configurations
		#810. Prepare the color palette
		echarts4r::e_color(color = col_slice) %>%
		#820. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#880. Enable the tooltip triggered by mouse over the bars
		echarts4r::e_tooltip(
			trigger = 'item'
			,confine = TRUE
			,appendToBody = TRUE
			,enterable = FALSE
			,!!!tooltip_sym
		)
	))

	#580. Convert the htmlwiget into character vector
	#581. Conversion
	ch_html %<>%
		#900. Convert to character vector
		as.character.htmlwidget()

	#583. Search for the HTML ID
	vfy_html_id <- stringr::str_extract_all(ch_html, '(?<=<div\\sid=("|\'))(.+?)(?=\\1)')[[1]][[1]]

	#589. Overwrite the original rect
	ch_html %<>%
		#920. Setup the shape of the canvas
		{gsub(
			paste0('(?<=<div\\sid=("|\')',vfy_html_id,'\\1\\sstyle=("|\'))width:(\\d+(%|px));\\s*height:(\\d+(%|px));')
			,paste0(''
				,'width:',width,'px !important;'
				,'height:',height,'px !important;'
			)
			,.
			,perl = T
		)}

	#590. Directly return if no need to convert it to tooltip
	if (!as.tooltip) return(ch_html)

	#800. Function as container for creating the tooltip out of current chart
	#[IMPORTANT]
	#[1] We must set the <echarts> object names BEFORE the definition of the container, as they are referenced inside the container
	#[2] Program will automatically search for the variable by stacks, hence there is no need to worry about the environment nesting
	ech_obj_name <- paste0('ttPie_', gsub('\\W', '_', vfy_html_id))
	h_contain <- function(html_tag){html_tag}

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
		ch_scoring <- lubridate::lakers %>%
			dplyr::group_by(opponent, period) %>%
			dplyr::summarise(
				points = sum(points, na.rm = T)
				,.groups = 'keep'
			) %>%
			dplyr::group_by(opponent) %>%
			dplyr::summarise(
				score = sum(points, na.rm = T)
				,ech_pie = echarts4r_vec_pie(
					points
					,vec_cat = period
					,sortBy = 'input'
					#20220413 It is tested that if we manually set [html_id], the chart may not display when hovering over,
					#          hence we should never (or under certain condition?) set it
					# ,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
					,title = 'Distribution by Period'
					,theme = uRV$theme
					# ,jsFmtFloat = 'toFixed(4)'
					,fmtLabel = NULL
					,as.tooltip = TRUE
				)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				ech_score = echarts4r_Capsule(
					score
					,score
					,score
					,symColor = uRV$coltheme[['color']][['chart-sym-light']]
					,theme = uRV$theme
					,fmtTTSym = ech_pie
				)
				,score_text = echarts4r_vec_text(
					score
					,width = 64
					,theme = uRV$theme
					,fmtTooltip = ech_pie
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('opponent', 'score', 'ech_score', 'score_text')
		dt_scoring <- DT::datatable(
			ch_scoring %>% dplyr::select(tidyselect::all_of(cols))
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

		#500. Export a standalone HTML file
		div_scoring <- shiny::fluidRow(
			shinydashboardPlus::box(
				width = 12
				,shiny::tags$style(
					type = 'text/css'
					,paste0(''
						,'.box {'
							,'background-color: ',uRV$coltheme[['background-color']][['default']],' !important;'
						,'}'
					)
				)
				,shiny::tagList(
					theme_datatable(theme = uRV$theme, transparent = T)
					,dt_scoring
				)
			)
		)

		path_rpt <- dirname(thisfile())
		rpt_tpl <- file.path(path_rpt, 'echarts4r_vec_pie.Rmd')
		rpt_out <- file.path(path_rpt, 'ScoreDistribution.html')
		rmarkdown::render(
			rpt_tpl
			,output_file = rpt_out
			,params = list(
				dt = div_scoring
			)
			,envir = new.env(parent = globalenv())
		)

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
						,dt_scoring
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}
}
