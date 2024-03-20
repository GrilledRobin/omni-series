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
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]. It is highly recommended to provide integer or  #
#   |                 float numbers, since [echarts::textStyle.fontSize] cannot properly resolve other inputs in nested charts          #
#   |                 [14          ] <Default> Common font size                                                                         #
#   |jsFmtFloat  :   Character vector of the JS methods applied to JS:Float values (which means [vec_min], [vec_max] and [vec_sym] for  #
#   |                 this function) of each chart respectively                                                                         #
#   |                 [IMPORTANT] If [formatter] is provided in [tooltip], this option will no longer take effect                       #
#   |                 [toFixed(4)  ] <Default> Format all values into numbers with fixed decimals as 4                                  #
#   |fmtTTBar    :   Character vector of the formatter to tweak the [tooltip] for the bars of each chart respectively                   #
#   |                 [IMPORTANT] MUST NOT provide a string of class [htmlwidgets::JS]                                                  #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |fmtTTSym    :   Character vector of the formatter to tweak the [tooltip] for the markers of each chart respectively                #
#   |                 [IMPORTANT] MUST NOT provide a string of class [htmlwidgets::JS]                                                  #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |barShowBG   :   Whether to show a semi-transparent background of bars, indicating the full range covering the present values       #
#   |                 [IMPORTANT] It is ignored if neither [y_min] nor [y_max] is provided                                              #
#   |                 [FALSE       ] <Default> Do not show the background of bars                                                       #
#   |                 [TRUE        ]           Show the background of bars, useful for comparison of scales between charts              #
#   |gradient    :   Whether to draw the bar with gradient color effect                                                                 #
#   |                 [FALSE       ] <Default> Draw the bar with the provided color [barColor]                                          #
#   |                 [TRUE        ]           Draw a bar with gradient color effect. In such case, [barColor] plays as the last among  #
#   |                                           the color choices (which is desirably the color on the right-most side of the bar),     #
#   |                                           while those listed in [...] plays as the first till the second last one in the sequence #
#   |                                           as when they are provided                                                               #
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
#   |...         :   The rest of the color series to fill the bar with gradient effect. The provided colors play as the first till the  #
#   |                  second last colors on the visual map, while [barColor] always plays as the last one on it                        #
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
#   | Date |    20211211        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211218        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new function [themeColors] to standardize the theme selection                                               #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211224        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Corrected the logic to retrieve the width and height from the script                                                    #
#   |      |[2] Leverage the original [elementID] in [echarts4r::e_charts()] to assign the HTML ID                                      #
#   |      |[3] Introduce a new argument [gradient] to allow passing various colors to create a bar with gradient color effect          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220115        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [barShowBG] to enable showing background of bars for comparison between charts                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220411        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [as.tooltip] to allow the charts to be displayed inside a tooltip of another chart             #
#   |      |[2] Introduce a new argument [container] to enable user defined HTML tag container as future compatibility                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220413        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [as.parts] to indicate whether to transform the input vector into separate parts of HTML       #
#   |      |     widgets, as components to be combined into one [echarts:tooltip], see [omniR$Visualization$echarts4r.merge.tooltips]   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221117        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] It is tested that [echarts::textStyle.fontSize] cannot resolve text input, such as '14px', within the nested charts,    #
#   |      |     hence we suppress the text input from the beginning. Meanwhile, keep the parsed text [fontSize] for any CSS codes to   #
#   |      |     retain the compatibility.                                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221221        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Enable multiple provision of most of the arguments (but only the first provision is accepted), to ensure more           #
#   |      |     flexibility of customization for each along the vectorized charts                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 2.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments                                            #
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
#   |   |magrittr, rlang, echarts4r, htmlwidgets, htmltools, stringr, scales                                                            #
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
	magrittr, rlang, echarts4r, htmlwidgets, htmltools, stringr, scales
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
	,barShowBG = FALSE
	,gradient = FALSE
	,as.tooltip = FALSE
	,container = function(html_tag){html_tag}
	,as.parts = FALSE
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	fontSize_css <- htmltools::validateCssUnit(fontSize)
	fontSize_ech <- fontSize_css %>% {gsub('^(((\\d+)?\\.)?\\d+).*$','\\1', .)} %>% as.numeric()

	#012. Handle the parameter buffer
	if ((length(vec_min) == 0) | (length(vec_max) == 0) | (length(vec_sym) == 0)) return(character(0))
	if (length(y_min) == 0) y_min <- NA
	if (length(y_max) == 0) y_max <- NA
	if (length(html_id) == 0) html_id <- NA
	if (length(fmtTTBar) == 0) fmtTTBar <- NA
	if (length(fmtTTSym) == 0) fmtTTSym <- NA
	y_min <- head(y_min,1)
	y_max <- head(y_max,1)
	barHeight <- head(barHeight,1)
	barWidth <- head(barWidth,1)
	symSize <- head(symSize,1)
	disp_min <- head(disp_min,1)
	disp_max <- head(disp_max,1)
	disp_sym <- head(disp_sym,1)
	theme <- head(theme,1)
	fontFamily <- head(fontFamily,1)
	fontSize <- head(fontSize,1)
	jsFmtFloat <- head(jsFmtFloat,1)
	fmtTTBar <- head(fmtTTBar,1)
	fmtTTSym <- head(fmtTTSym,1)
	barShowBG <- head(barShowBG,1)
	gradient <- head(gradient,1)
	if (!is.logical(gradient)) {
		stop('[',LfuncName,'][gradient] must be logical!')
	}
	if (!is.function(container)) {
		container <- head(container,1)[[1]]
	}

	#015. Function local variables
	barBorderRadius <- max(1, floor(barHeight / 2))
	cfg_shadow <- list(
		#We set the same black shadow for all bars [rgba(#202122, 0.5)]
		shadowColor = '#2021227F'
		,shadowBlur = 1
	)

	#100. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = F)

	#200. Create the styles of [tooltip]
	tooltip <- list(
		confine = FALSE
		,appendToBody = TRUE
		,textStyle = list(
			fontFamily = fontFamily
			,fontSize = fontSize_ech
			,color = coltheme[['color']][['tooltip']]
		)
		,backgroundColor = coltheme[['background-color']][['tooltip']]
		,borderColor = coltheme[['border-color']][['tooltip']]
		,extraCssText = paste0(''
			,'box-shadow: ',coltheme[['box-shadow']][['tooltip']]
		)
	)

	#300. Override the colors when required
	if (length(barColor) == 0) {
		col_bar <- coltheme[['color']][['chart-bar']]
	} else {
		col_bar <- barColor
	}
	if (length(symColor) == 0) {
		col_sym <- coltheme[['color']][['chart-sym']]
	} else {
		col_sym <- symColor
	}
	col_grad <- rgba2rgb(col_bar, alpha_in = 0.3)

	#500. Define helper functions
	#510. Function to apply to all vectors
	h_charts <- function(
		v_min,v_max,v_sym,y_amin,y_amax
		,v_barheight,v_barwidth,v_barBRadius,v_bar_col,v_bar_col_gr
		,v_symsize,v_sym_col
		,v_d_min,v_d_max,v_d_sym
		,v_float
		,v_html_id
		,v_fmtTTbar,v_fmtTTsym
		, v_barShowBG, v_gradient
		,...
	){
		#015. Function local variables
		colors_buff <- rlang::list2(...) %>% unname() %>% unlist()
		colors_ramp <- scales::colour_ramp(c(colors_buff, v_bar_col))
		#We cut the color palette into 20 pieces, which is enough for gradient of a short bar
		colors_len <- 20
		colors_offset <- seq(0, 1, length = colors_len)
		colors_grad <- colors_ramp(colors_offset)
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

		#050. Setup default styles for the bar
		disp_itemStyle <- rlang::list2(
			#Quote: https://blog.csdn.net/qq_30351747/article/details/119254014
			color = list(
				type = 'linear'
				,x = 0, y = 0.2, x2 = 0, y2 = 0.7
				,colorStops = list(
					list(offset = 0, color = v_bar_col_gr)
					,list(offset = 1, color = v_bar_col)
				)
			)
			,borderWidth = 0
			,borderColor = paste0(v_bar_col, alphaToHex(0.5))
			,borderRadius = v_barBRadius
			,!!!cfg_shadow
		)
		if (v_barShowBG & !(is.na(y_amin) & is.na(y_amax))) {
			bar_showBG <- list(
				showBackground = TRUE
				,backgroundStyle = list(
					color = coltheme[['color']][['default']]
					,borderWidth = 0
					,borderRadius = v_barBRadius
					,opacity = 0.07
				)
			)
		} else {
			bar_showBG <- list(
				showBackground = FALSE
			)
		}

		#070. Setup tooltip styles
		if (!is.na(v_fmtTTbar)) {
			disp_tooltip_bar <- modifyList(tooltip, list(formatter = htmlwidgets::JS(v_fmtTTbar)))
		} else {
			disp_tooltip_bar <- modifyList(
				tooltip
				,list(
					formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'return('
								,'\'<strong>',v_d_min,'</strong>\''
								,'+ \' : \' + parseFloat(',v_min,').',v_float
								,'+ \'<br/>\' + \'<strong>',v_d_max,'</strong>\''
								,'+ \' : \' + parseFloat(',v_max,').',v_float
							,');'
						,'}'
					))
				)
			)
		}
		if (as.tooltip) {
			tooltip_sym_base <- tooltip
		} else {
			tooltip_sym_base <- modifyList(
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
		if (!is.na(v_fmtTTsym)) {
			tooltip_sym <- modifyList(
				tooltip_sym_base
				,list(
					formatter = htmlwidgets::JS(v_fmtTTsym)
				)
			)
		} else {
			tooltip_sym <- modifyList(
				tooltip_sym_base
				,list(
					formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'return('
								,'\'<strong>',v_d_sym,'</strong>\''
								,'+ \' : \' + parseFloat(params.value[0]).',v_float
							,');'
						,'}'
					))
				)
			)
		}

		#100. Calculate the floor and ceiling values based on the minimum and maximum values
		v_all <- yaxis_max - yaxis_min
		if (sign(v_min) == -sign(v_max)) {
			#100. Boundary values
			v_ceil <- v_max
			v_floor <- v_min

			#300. Show the data bar
			ceil_itemStyle <- modifyList(
				disp_itemStyle
				,list(
					borderRadius = list(0, v_barBRadius, v_barBRadius, 0)
				)
			)
			tooltip_ceil <- disp_tooltip_bar

			#500. Copy the similar style from the data bar to the fake bar, except the border radius
			floor_itemStyle <- modifyList(
				disp_itemStyle
				,list(
					borderRadius = list(v_barBRadius, 0, 0, v_barBRadius)
				)
			)
			tooltip_floor <- disp_tooltip_bar

			#700. Add a visual map to make the gradient color effect to the bar
			if (v_gradient & (v_all != 0)) {
				#100. Calculate the index of the 3 points among 20 interpolated points between [min] and [max]
				i_interp <- round(scales::rescale(
					20 * (c(v_floor, 0, v_ceil) - yaxis_min) / v_all
					, to = c(1,20)
					, from = range(0,20)
				))

				#300. Prepare the color offsets for floor bar
				k_off_floor <- i_interp[[2]] - i_interp[[1]] + 1
				offsets_floor <- seq(0, 1, length = k_off_floor)
				stops_floor <- lapply(
					seq_len(k_off_floor)
					,function(i){list(offset = offsets_floor[[i]], color = colors_grad[[i_interp[[1]] + i - 1]])}
				)
				floor_itemStyle %<>%
					#We must set the value of [color] as [NULL], otherwise the process would fail
					modifyList(list(color = NULL)) %>%
					modifyList(
						list(
							color = list(
								type = 'linear'
								,x = 0, y = 0, x2 = 1, y2 = 0
								,colorStops = stops_floor
							)
						)
					)

				#500. Prepare the color offsets for ceiling bar
				k_off_ceil <- i_interp[[3]] - i_interp[[2]] + 1
				offsets_ceil <- seq(0, 1, length = k_off_ceil)
				stops_ceil <- lapply(
					seq_len(k_off_ceil)
					,function(i){list(offset = offsets_ceil[[i]], color = colors_grad[[i_interp[[2]] + i - 1]])}
				)
				ceil_itemStyle %<>%
					#We must set the value of [color] as [NULL], otherwise the process would fail
					modifyList(list(color = NULL)) %>%
					modifyList(
						list(
							color = list(
								type = 'linear'
								,x = 0, y = 0, x2 = 1, y2 = 0
								,colorStops = stops_ceil
							)
						)
					)
			}
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

			#300. Show the ceiling bar
			ceil_itemStyle <- disp_itemStyle
			tooltip_ceil <- disp_tooltip_bar

			#500. Suppress the floor bar
			floor_itemStyle <- list(opacity = 0)
			tooltip_floor <- list(show = FALSE)

			#700. Add a visual map to make the gradient color effect to the bar
			if (v_gradient & (v_all != 0)) {
				#100. Calculate the index of the 2 points among 20 interpolated points between [min] and [max]
				i_interp <- round(scales::rescale(
					20 * (c(v_min, v_max) - yaxis_min) / v_all
					, to = c(1,20)
					, from = range(0,20)
				))

				#500. Prepare the color offsets for ceiling bar
				k_off_ceil <- i_interp[[2]] - i_interp[[1]] + 1
				offsets_ceil <- seq(0, 1, length = k_off_ceil)
				stops_ceil <- lapply(
					seq_len(k_off_ceil)
					,function(i){list(offset = offsets_ceil[[i]], color = colors_grad[[i_interp[[1]] + i - 1]])}
				)
				ceil_itemStyle %<>%
					#We must set the value of [color] as [NULL], otherwise the process would fail
					modifyList(list(color = NULL)) %>%
					modifyList(
						list(
							color = list(
								type = 'linear'
								,x = 0, y = 0, x2 = 1, y2 = 0
								,colorStops = stops_ceil
							)
						)
					)
			}
		}

		#600. Create a tiny data.frame to follow the syntax of [echarts4r]
		df <- data.frame(.ech.draw = 'id', .val.floor = v_floor, .val.ceil = v_ceil, .val.sym = v_sym)

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
					,!!!bar_showBG
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
					,!!!bar_showBG
				) %>%
				#300. Draw a line with the symbol to resemble the [marker] on the capsule
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
						,borderWidth = max(0.5, v_barheight %/% 8)
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
					# ,!!!tooltip_sym
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
					,'height:',v_symsize + 4,'px !important;'
				)
				,.
				,perl = T
			)}

		#999. Make the return value explicit
		return(ch_html)
	}

	#600. Generate the charts
	ch_html <- mapply(
		h_charts
		, vec_min, vec_max, vec_sym, y_min, y_max
		, barHeight, barWidth, barBorderRadius, col_bar, col_grad
		, symSize, col_sym
		, disp_min, disp_max, disp_sym
		, jsFmtFloat
		, html_id
		, fmtTTBar, fmtTTSym
		, barShowBG, gradient
		, ...
		, SIMPLIFY = TRUE
	)

	#700. Directly return if no need to convert it to tooltip
	if (!as.tooltip) return(ch_html)

	#800. Function as container for creating the tooltip out of current chart
	#[IMPORTANT]
	#[1] We must set the <echarts> object names BEFORE the definition of the container, as they are referenced inside the container
	#[2] Program will automatically search for the variable by stacks, hence there is no need to worry about the environment nesting
	ech_obj_name <- paste0('ttCapsule_', as.integer(runif(length(ch_html)) * 10^7))
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
				hp_ech = echarts4r_Capsule(
					hp_min
					,hp_max
					,hp_curr
					,y_min = hp_ymin
					,y_max = hp_ymax
					,barColor = hp_color
					,symColor = uRV$coltheme[['color']][['chart-sym-light']]
					,disp_min = '最小值'
					,disp_max = '最大值'
					,disp_sym = brand
					,theme = uRV$theme
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

	#Weather forecast
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#020. Simulate the private environment of Shiny App, to generalize the usage of this function
		uRV <- list()

		#050. Choose theme
		uRV$theme <- 'BlackGold'
		uRV$coltheme <- themeColors(uRV$theme)

		#100. Create sample data
		#[气象图例配色原则]:
		#Quote: http://www.doczj.com/doc/75c8d8232e3f5727a4e9626b-7.html
		crColor <- function(r,g,b){grDevices::rgb(r / 255, g / 255, b / 255)}
		color_cuts <- function(x){
			cut(
				x
				,breaks = c(-Inf,seq(-32, 32, by = 4), Inf)
				,labels = c(
					crColor(0,0,50)
					,crColor(0,0,150)
					,crColor(0,0,255)
					,crColor(0,75,255)
					,crColor(0,150,255)
					,crColor(0,200,255)
					,crColor(50,255,255)
					,crColor(150,255,255)
					,crColor(200,255,255)
					,crColor(255,255,150)
					,crColor(255,255,50)
					,crColor(255,200,0)
					,crColor(255,150,100)
					,crColor(255,150,50)
					,crColor(255,100,0)
					,crColor(230,0,0)
					,crColor(150,0,0)
					,crColor(100,0,0)
				)
			) %>% as.character()
		}
		# scales::show_col(crColor(200,255,255))

		ch_weather <- data.frame(
			d_data = seq.Date(asDates('20211225'), asDates('20220103'), by = 1)
			,t_min = c(0,-2,-4,-1,1,0,1,1,1,2)
			,t_max = c(7,3,5,10,12,11,8,9,12,9)
		) %>%
			#Quote: https://stackoverflow.com/questions/52809757/runif-on-rnorm-generated-data-per-row
			dplyr::rowwise() %>%
			dplyr::mutate(
				t_now = runif(1, min = t_min, max = t_max)
			) %>%
			#[rowwise] implicitly groups the data, hence we remove it for vectorized calculation at later steps
			#Quote: https://stackoverflow.com/questions/29762393/how-does-one-stop-using-rowwise-in-dplyr
			dplyr::ungroup() %>%
			dplyr::mutate(
				t_now = ifelse(dplyr::row_number() == 1, t_now, NA)
				,t_ymin = min(t_min)
				,t_ymax = max(t_max)
			) %>%
			dplyr::mutate(
				t_ech = echarts4r_Capsule(
					t_min
					,t_max
					,t_now
					,y_min = t_ymin
					,y_max = t_ymax
					,barHeight = 4
					,barWidth = 120
					# ,barColor = color_cuts(t_ymax)
					,barColor = '#FFFF96'
					,symSize = 6
					# ,symColor = uRV$coltheme[['color']][['chart-sym']]
					,symColor = '#FFFFFF'
					,disp_min = '最低温'
					,disp_max = '最高温'
					,disp_sym = '当前气温'
					,theme = uRV$theme
					,jsFmtFloat = 'toFixed(0)'
					,barShowBG = T
					,gradient = T
					# ,col_bottom = color_cuts(t_ymin)
					,col_bottom = '#0096FF'
					,col1 = '#00C8FF'
					,col2 = '#32FFFF'
					,col3 = '#96FFFF'
					,col4 = '#C8FFFF'
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('d_data','t_min','t_max','t_ech')
		dt_weather <- DT::datatable(
			ch_weather %>% dplyr::select(tidyselect::all_of(cols))
			#Only determine the columns to be displayed, rather than the columns to extract from the input data
			,colnames = cols
			,width = '100%'
			,class = 'compact display'
			,fillContainer = TRUE
			,escape = FALSE
			,options = list(
				#Setup the styles for the table header
				initComplete = htmlwidgets::JS(paste0(
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
						,dt_weather
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}
}
