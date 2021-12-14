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
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec_min     :   Numeric vector of the minimum values of the bar                                                                    #
#   |vec_max     :   Numeric vector of the maximum values of the bar                                                                    #
#   |vec_sym     :   Numeric vector of the values that will be marked on the bar by a symbol, a.k.a marker                              #
#   |y_min       :   Numeric vector of the minimum values of y-axis. It is useful to unify the y-axis of the charts                     #
#   |                 [NULL        ] <Default> All bars have the same length, and thus cannot be differentiated by their scales         #
#   |                 [NOT-NULL    ]           Bars will have different scales at y-axis                                                #
#   |y_max       :   Numeric vector of the maximum values of y-axis. It is useful to unify the y-axis of the charts                     #
#   |                 [NULL        ] <Default> All bars have the same length, and thus cannot be differentiated by their scales         #
#   |                 [NOT-NULL    ]           Bars will have different scales at y-axis                                                #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |barHeight   :   Integer vector of the heights of each chart respectively                                                           #
#   |                 [8           ] <Default>                                                                                          #
#   |barWidth    :   Integer vector of the widths of each chart respectively                                                            #
#   |                 [64          ] <Default>                                                                                          #
#   |barColor    :   Character vector of the CSS colors of the bar in each chart respectively                                           #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
#   |symSize     :   Integer vector of the sizes of the markers in each chart respectively                                              #
#   |                 [12          ] <Default>                                                                                          #
#   |symColor    :   Character vector of the CSS colors of the markers in each chart respectively                                       #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
#   |disp_min    :   Character vector of the text that names the minimum values in the tooltips of each chart respectively              #
#   |                 [Min         ] <Default> Minimum                                                                                  #
#   |disp_max    :   Character vector of the text that names the maximum values in the tooltips of each chart respectively              #
#   |                 [Max         ] <Default> Maximum                                                                                  #
#   |disp_sym    :   Character vector of the text that names the marker values in the tooltips of each chart respectively               #
#   |                 [Close       ] <Default> Values at the closing time                                                               #
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |fontFamily  :   Character vector of font family to be translated to CSS syntax                                                     #
#   |                 [<vector>    ] <Default> See function definition                                                                  #
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]                                                  #
#   |                 [14px        ] <Default> Common font size                                                                         #
#   |jsFmtFloat  :   Character vector of the JS methods applied to JS:Float values (which means [vec_min], [vec_max] and [vec_sym] for  #
#   |                 this function) of each chart respectively                                                                         #
#   |                 [IMPORTANT] If [formatter] is provided in [tooltip], this option will no longer take effect                       #
#   |                 [toFixed(4)  ] <Default> Format all values into numbers with fixed decimals as 4                                  #
#   |fmtTTBar    :   Character vector of the formatter to tweak the [tooltip] for the bars of each chart respectively                   #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |fmtTTSym    :   Character vector of the formatter to tweak the [tooltip] for the markers of each chart respectively                #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector]   :   A vector of HTML widgets represented as character strings                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211211        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, rlang, grDevices, echarts4r, htmlwidgets                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |rgba2rgb                                                                                                                   #
#   |   |   |themePalette                                                                                                               #
#   |   |   |alphaToHex                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |as.character.htmlwidget                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, grDevices, echarts4r, htmlwidgets
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)
library(rlang)

echarts4r_Capsule <- function(
	vec_min
	,vec_max
	,vec_sym
	,y_min = NULL
	,y_max = NULL
	,html_id = NULL
	,barHeight = 8
	,barWidth = 64
	,barColor = NULL
	,symSize = 12
	,symColor = NULL
	,disp_min = 'Min'
	,disp_max = 'Max'
	,disp_sym = 'Close'
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	,jsFmtFloat = 'toFixed(4)'
	,fmtTTBar = NULL
	,fmtTTSym = NULL
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	theme <- match.arg(theme, c('BlackGold', 'PBI', 'Inno', 'MSOffice'))
	fontSize <- htmltools::validateCssUnit(fontSize)

	#012. Handle the parameter buffer
	if ((length(vec_min) == 0) | (length(vec_max) == 0) | (length(vec_sym) == 0)) return(character(0))
	if (length(y_min) == 0) y_min <- NA
	if (length(y_max) == 0) y_max <- NA
	if (length(html_id) == 0) html_id <- NA

	#015. Function local variables
	cache_BlackGold <- themePalette('BlackGold')
	cache_Inno <- themePalette('Inno')
	cache_PBI <- themePalette('PBI')
	cache_MSOffice <- themePalette('MSOffice')
	barBorderRadius <- max(1, floor(barHeight / 2))
	cfg_shadow <- list(
		#We set the same black shadow for all bars
		shadowColor = paste0('rgba(',paste0(grDevices::col2rgb(cache_BlackGold$black$d), collapse = ','),',0.5)')
		,shadowBlur = 1
	)

	#100. Create colors
	coltheme <- list(
		'BlackGold' = list(
			'backgroundColor' = list(
				'tooltip' = paste0(
					rgba2rgb(cache_BlackGold$black$d, alpha_in = 0.9, color_bg = cache_BlackGold$gold$d)
					,alphaToHex(0.95)
				)
			)
			,'borderColor' = list(
				'tooltip' = paste0(
					rgba2rgb(cache_BlackGold$black$d, alpha_in = 0.7, color_bg = cache_BlackGold$gold$d)
					,alphaToHex(0.95)
				)
			)
			,'color' = list(
				'bar' = cache_BlackGold$gold$d
				,'sym' = rgba2rgb(cache_BlackGold$black$d, alpha_in = 0.7, color_bg = cache_BlackGold$gold$d)
				,'tooltip' = cache_BlackGold$gold$d
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_BlackGold$black$d, alphaToHex(0.3), ';')
			)
		)
		,'Inno' = list(
			'backgroundColor' = list(
				'tooltip' = paste0(
					cache_Inno$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'borderColor' = list(
				'tooltip' = paste0(
					cache_Inno$white$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'color' = list(
				'bar' = cache_Inno$yellow$d
				,'sym' = rgba2rgb(cache_Inno$black$p[[4]], alpha_in = 0.7, color_bg = cache_Inno$white$p[[1]])
				,'tooltip' = cache_Inno$white$p[[1]]
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_Inno$black$p[[4]], alphaToHex(0.3), ';')
			)
		)
		,'PBI' = list(
			'backgroundColor' = list(
				'tooltip' = paste0(
					cache_PBI$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'borderColor' = list(
				'tooltip' = paste0(
					cache_PBI$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'color' = list(
				'bar' = cache_PBI$black$p[[4]]
				,'sym' = cache_PBI$white$p[[1]]
				,'tooltip' = cache_PBI$white$p[[1]]
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_PBI$black$p[[4]], alphaToHex(0.3), ';')
			)
		)
		,'MSOffice' = list(
			'backgroundColor' = list(
				'tooltip' = paste0(
					cache_MSOffice$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'borderColor' = list(
				'tooltip' = paste0(
					cache_MSOffice$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'color' = list(
				'bar' = cache_MSOffice$black$p[[4]]
				,'sym' = cache_MSOffice$white$p[[1]]
				,'tooltip' = cache_MSOffice$white$p[[1]]
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_MSOffice$black$p[[4]], alphaToHex(0.3), ';')
			)
		)
	)

	#200. Create the styles of [tooltip]
	tooltip <- list(
		confine = FALSE
		,appendToBody = TRUE
		,textStyle = list(
			fontFamily = fontFamily
			,fontSize = fontSize
			,color = coltheme[[theme]][['color']][['tooltip']]
		)
		,backgroundColor = coltheme[[theme]][['backgroundColor']][['tooltip']]
		,borderColor = coltheme[[theme]][['borderColor']][['tooltip']]
		,extraCssText = paste0(''
			,'box-shadow: ',coltheme[[theme]][['box-shadow']][['tooltip']]
		)
	)

	#300. Override the colors when required
	if (length(barColor) == 0) {
		col_bar <- coltheme[[theme]][['color']][['bar']]
	} else {
		col_bar <- barColor
	}
	if (length(symColor) == 0) {
		col_sym <- coltheme[[theme]][['color']][['sym']]
	} else {
		col_sym <- symColor
	}
	col_grad <- rgba2rgb(col_bar, alpha_in = 0.3)

	#700. Define helper functions
	#710. Function to apply to all vectors
	h_charts <- function(
		v_min,v_max,v_sym,y_amin,y_amax
		,v_barheight,v_barwidth,v_barBRadius,v_bar_col,v_bar_col_gr
		,v_symsize,v_sym_col
		,v_d_min,v_d_max,v_d_sym
		,v_float
		,v_html_id
	){
		#015. Function local variables
		if (is.na(y_amin)) {
			yaxis_min <- v_min
		} else {
			yaxis_min <- y_amin
		}
		if (is.na(y_amax)) {
			yaxis_max <- v_max
		} else {
			yaxis_max <- y_amax
		}
		disp_itemStyle <- rlang::list2(
			color = list(
				type = 'linear'
				,x = 0, y = 0.2, x2 = 0, y2 = 0.7
				,colorStops = list(
					list(offset = 0, color = v_bar_col_gr)
					,list(offset = 1, color = v_bar_col)
				)
			)
			,borderColor = paste0(v_bar_col, alphaToHex(0.5))
			,borderRadius = v_barBRadius
			,!!!cfg_shadow
		)
		if (length(fmtTTBar) > 0) {
			disp_tooltip_bar <- modifyList(tooltip, list(formatter = fmtTTBar))
		} else {
			disp_tooltip_bar <- modifyList(
				tooltip
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>',v_d_min,'</strong>"'
								,'+ " : " + parseFloat(',v_min,').',v_float
								,'+ "<br/>" + "<strong>',v_d_max,'</strong>"'
								,'+ " : " + parseFloat(',v_max,').',v_float
							,');'
						,'}'
					))
				)
			)
		}
		if (length(fmtTTSym) > 0) {
			tooltip_sym <- modifyList(tooltip, list(formatter = fmtTTSym))
		} else {
			tooltip_sym <- modifyList(
				tooltip
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>',v_d_sym,'</strong>"'
								,'+ " : " + parseFloat(params.value[0]).',v_float
							,');'
						,'}'
					))
				)
			)
		}

		#100. Calculate the floor and ceiling values based on the minimum and maximum values
		if (sign(v_min) != sign(v_max)) {
			#100. Boundary values
			v_ceil <- v_max
			v_floor <- v_min

			#500. Show the data bar
			ceil_itemStyle <- modifyList(
				disp_itemStyle
				,list(
					borderRadius = list(0, v_barBRadius, v_barBRadius, 0)
				)
			)
			tooltip_ceil <- disp_tooltip_bar

			#900. Copy the similar style from the data bar to the fake bar, except the border radius
			floor_itemStyle <- modifyList(
				disp_itemStyle
				,list(
					borderRadius = list(v_barBRadius, 0, 0, v_barBRadius)
				)
			)
			tooltip_floor <- disp_tooltip_bar
		} else {
			#100. Boundary values
			if (sign(v_max) >= 0) {
				v_ceil <- v_max - v_min
				v_floor <- v_min
			} else {
				#[IMPORTANT] When both values are negative, they have to be drawn in the opposite order
				v_floor <- v_max
				v_ceil <- v_min - v_max
			}

			#500. Show the ceiling bar
			ceil_itemStyle <- disp_itemStyle
			tooltip_ceil <- disp_tooltip_bar

			#900. Suppress the floor bar
			floor_itemStyle <- list(opacity = 0)
			tooltip_floor <- list(show = FALSE)
		}

		#600. Create a tiny data.frame to follow the syntax of [echarts4r]
		df <- data.frame(.ech.draw = 'id', .val.floor = v_floor, .val.ceil = v_ceil, .val.sym = v_sym)

		#900. Create the HTML widget
		#We use [rlang::expr] to enable the big-bang(!!!) operator
		#910. Initialize the chart
		ch_html <- eval(rlang::expr(
			df %>%
				echarts4r::e_charts(.ech.draw) %>%
				echarts4r::e_grid(
					index = 0
					, top = 2, right = 0, bottom = 2, left = 8
					, height = v_symsize, width = v_barwidth
				) %>%
				#100. Draw a floor bar that is merely transparent; which is to shift the visible data bar
				echarts4r::e_bar(
					.val.floor
					,x_index = 0
					,y_index = 0
					,stack = 'StackBar'
					,barWidth = v_barheight
					,tooltip = tooltip_floor
					,itemStyle = floor_itemStyle
				) %>%
				#200. Draw the data bar
				echarts4r::e_bar(
					.val.ceil
					,x_index = 0
					,y_index = 0
					,stack = 'StackBar'
					,barWidth = v_barheight
					,tooltip = tooltip_ceil
					,itemStyle = ceil_itemStyle
				) %>%
				#400. Draw a line with the symbol to resemble the [marker] on the capsule
				echarts4r::e_line(
					.val.sym
					,x_index = 0
					,y_index = 0
					,stack = 'StackLine'
					,symbol = 'circle'
					,symbolSize = v_symsize
					,tooltip = tooltip_sym
					,itemStyle = list(
						color = v_sym_col
						,borderColor = v_bar_col
						,borderWidth = max(1, v_barheight %/% 8)
						,!!!cfg_shadow
					)
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
					,min = yaxis_min
					,max = yaxis_max
				) %>%
				#400. Setup the legend
				echarts4r::e_legend(show = FALSE) %>%
				#800. Extra configurations
				#810. Flip the coordinates
				echarts4r::e_flip_coords() %>%
				#820. Show a loading animation when the chart is re-drawn
				echarts4r::e_show_loading() %>%
				#880. Enable the tooltip triggered by mouse over the bars
				echarts4r::e_tooltip(
					trigger = 'item'
					,axisPointer = list(
						show = FALSE
					)
				) %>%
				#900. Convert to character vector
				as.character.htmlwidget() %>%
				#920. Setup the shape of the canvas
				{gsub(
					'width:(\\d+%);height:(\\d+)px;'
					,paste0(''
						,'width:',v_barwidth + 16,'px !important;'
						,'height:',v_symsize + 4,'px !important;'
					)
					,.
				)}
		))

		#950. Change the HTML ID
		if (!is.na(v_html_id)) {
			ch_html <- eval(rlang::expr(
				ch_html %>%
					{gsub(
						'id="(htmlwidget-.+?)"'
						,paste0('id="',v_html_id,'"')
						,.
					)} %>%
					{gsub(
						'data-for="(htmlwidget-.+?)"'
						,paste0('data-for="',v_html_id,'"')
						,.
					)}
			))
		}

		#999. Make the return value explicit
		return(ch_html)
	}

	#999. Return the vector
	mapply(
		h_charts
		, vec_min, vec_max, vec_sym, y_min, y_max
		, barHeight, barWidth, barBorderRadius, col_bar, col_grad
		, symSize, col_sym
		, disp_min, disp_max, disp_sym
		, jsFmtFloat
		, html_id
		, SIMPLIFY = TRUE
	)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#050. Choose theme
		rpt_theme <- 'BlackGold'
		if (rpt_theme == 'BlackGold') {
			rpt_bgcol <- themePalette(rpt_theme)$black$d
		} else if (rpt_theme == 'Inno') {
			rpt_bgcol <- themePalette(rpt_theme)$black$p[[4]]
		} else if (rpt_theme == 'PBI') {
			rpt_bgcol <- themePalette(rpt_theme)$white$d
		} else if (rpt_theme == 'MSOffice') {
			rpt_bgcol <- themePalette(rpt_theme)$white$d
		}

		#100. Create sample data
		ch_mtcar <- mtcars %>%
			tibble::rownames_to_column('brand') %>%
			dplyr::group_by(cyl) %>%
			dplyr::summarise(
				brand = dplyr::last(brand)
				,hp_min = min(hp)
				,hp_max = max(hp)
				,hp_curr = dplyr::last(hp)
				,hp_mean = mean(hp)
				,qsec_min = min(qsec)
				,qsec_max = max(qsec)
				,qsec_curr = dplyr::last(qsec)
				,qsec_mean = mean(qsec)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				hp_ymin = min(mtcars$hp)
				,hp_ymax = max(mtcars$hp)
				,hp_color = ifelse(
					hp_curr * 0.7 >= hp_mean
					, themePalette('Inno')$green$p[[2]]
					, themePalette('Inno')$red$p[[2]]
				)
				,qsec_color = ifelse(
					qsec_curr * 1.1 >= qsec_mean
					, themePalette('PBI')$blue$d
					, themePalette('PBI')$orange$d
				)
			) %>%
			dplyr::mutate(
				hp_ech = echarts4r_Capsule(
					hp_min
					,hp_max
					,hp_curr
					,y_min = hp_ymin
					,y_max = hp_ymax
					,barColor = hp_color
					,symColor = themePalette('BlackGold')$gold$d
					,disp_min = '最小值'
					,disp_max = '最大值'
					,disp_sym = brand
					,theme = rpt_theme
					,fontFamily = c('宋体')
					,jsFmtFloat = 'toFixed(0)'
				)
				,qsec_ech = echarts4r_Capsule(
					qsec_min
					,qsec_max
					,qsec_curr
					,html_id = paste0('ech_widget_qsec_', dplyr::row_number())
					,barColor = qsec_color
					,symColor = '#FFFFFF'
					,disp_min = '最小值'
					,disp_max = '最大值'
					,disp_sym = brand
					,fontFamily = c('Microsoft YaHei')
					,jsFmtFloat = 'toFixed(2)'
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('cyl','hp_ech','qsec_ech')
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
									,'background-color: ',rpt_bgcol,' !important;'
								,'}'
								,'.main-sidebar {'
									,'background-color: ',rpt_bgcol,' !important;'
								,'}'
								,'.content-wrapper {'
									,'background-color: ',rpt_bgcol,' !important;'
								,'}'
							)
						)
						,shinydashboardPlus::box(
							width = 12
							,shiny::tags$style(
								type = 'text/css'
								,paste0(''
									,'.box {'
										,'background-color: ',rpt_bgcol,' !important;'
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
						theme_datatable(theme = rpt_theme, transparent = T)
						,dt_mtcar
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}
}
