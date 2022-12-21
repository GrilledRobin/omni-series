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
#   |[01] https://echarts.apache.org/zh/index.html                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This can be useful if one needs to render charts within [DT::datatable]                                                        #
#   |[2] Draw charts for groups of keys along a time series, such as fund price trend within 5 years                                    #
#   |[3] Draw charts within [echarts:tooltip] for another vectorized chart series                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec_value   :   Numeric vector to be used as [values] to draw the charts                                                           #
#   |xAxis       :   Vector to play as the role of x-axis on the charts, only one vector of class [Date] is allowed at present          #
#   |y_min       :   Numeric as the minimum value of y-axis. It is useful to unify the y-axis of the charts                             #
#   |                 [NULL        ] <Default> Charts will have different scales at y-axis                                              #
#   |                 [NOT-NULL    ]           All charts have the same scale at y-axis, which is useful for parallel comparison        #
#   |y_max       :   Numeric as the maximum value of y-axis. It is useful to unify the y-axis of the charts                             #
#   |                 [NULL        ] <Default> Charts will have different scales at y-axis                                              #
#   |                 [NOT-NULL    ]           All charts have the same scale at y-axis, which is useful for parallel comparison        #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |height      :   Integer of the chart height                                                                                        #
#   |                 [540         ] <Default>                                                                                          #
#   |width       :   Integer of the chart width                                                                                         #
#   |                 [960         ] <Default>                                                                                          #
#   |lineColor   :   Character as the CSS color of the line in current chart                                                            #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
#   |gradient    :   Whether to draw the line with gradient color effect                                                                #
#   |                 [TRUE        ] <Default> Draw the line with gradient color effect                                                 #
#   |                 [FALSE       ]           Draw the line with the provided color                                                    #
#   |symSize     :   Integer as the size of the markers in current chart                                                                #
#   |                 [4           ] <Default>                                                                                          #
#   |symColor    :   Character as the CSS color of the markers in current chart                                                         #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
#   |disp_min    :   Character as the name of the mark point on the minimum value                                                       #
#   |                 [Min         ] <Default> Minimum                                                                                  #
#   |disp_max    :   Character as the name of the mark point on the maximum value                                                       #
#   |                 [Max         ] <Default> Maximum                                                                                  #
#   |disp_sym    :   Character as the name showing in the tooltip on the marker                                                         #
#   |                 [Value       ] <Default> Value of current data point                                                              #
#   |title       :   Character as the title of current chart                                                                            #
#   |                 [Line        ] <Default> Name all charts with this one                                                            #
#   |titleSize   :   Integer of the font size of the chart title                                                                        #
#   |                 [18          ] <Default> Common font size                                                                         #
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |transparent :   Whether to set the background as transparent                                                                       #
#   |                 [TRUE        ] <Default> Set the alpha of background color as 0                                                   #
#   |                 [FALSE       ]           Use the theme color                                                                      #
#   |fontFamily  :   Character vector of font family to be translated to CSS syntax                                                     #
#   |                 [<vector>    ] <Default> See function definition                                                                  #
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]. It is highly recommended to provide integer or  #
#   |                 float numbers, since [echarts::textStyle.fontSize] cannot properly resolve other inputs in nested charts          #
#   |                 [14          ] <Default> Common font size                                                                         #
#   |jsFmtFloat  :   Character vector of the JS methods applied to JS:Float values (which means [vec_min], [vec_max] and [vec_sym] for  #
#   |                 this function) of each chart respectively                                                                         #
#   |                 [IMPORTANT] If [formatter] is provided in [tooltip], this option will no longer take effect                       #
#   |                 [toFixed(4)  ] <Default> Format all values into numbers with fixed decimals as 4                                  #
#   |fmtTTSym    :   Character as the formatter to tweak the [tooltip] for the markers of current chart                                 #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |xAxis.zoom  :   Whether to add zooming tools to x-axis                                                                             #
#   |                 [TRUE        ] <Default> Add data zoom for x-axis, and several buttons for quick zooming                          #
#   |                 [FALSE       ]           Only draw a plain chart                                                                  #
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
#   | Date |    20211218        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211223        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [xAxis.zoom] to allow adding zoom tools to x-axis                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220411        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [container] to enable user defined HTML tag container as future compatibility                  #
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
#   |      |[2] Add new argument [gradient] to provide gradient effect of the line                                                      #
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
#   |   |magrittr, rlang, echarts4r, htmlwidgets, htmltools, dplyr, scales                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |themeColors                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |as.character.htmlwidget                                                                                                    #
#   |   |   |echarts4r.as.tooltip                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, echarts4r, htmlwidgets, htmltools, dplyr, scales
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)
library(rlang)

echarts4r_vec_line <- function(
	vec_value
	,xAxis
	,y_min = NULL
	,y_max = NULL
	,html_id = NULL
	,height = 540
	,width = 960
	,lineColor = NULL
	,gradient = TRUE
	,symSize = 4
	,symColor = NULL
	,disp_min = 'Min'
	,disp_max = 'Max'
	,disp_sym = 'Value'
	,title = 'Line'
	,titleSize = 18
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = TRUE
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	,jsFmtFloat = 'toFixed(4)'
	,fmtTTSym = NULL
	,xAxis.zoom = TRUE
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
	if ((length(vec_value) == 0) | (length(xAxis) == 0)) return(character(0))
	if (!all(class(xAxis) %in% c('Date'))) {
		stop('[',LfuncName,'][xAxis] must be an object of class [Date]!')
	}
	y_min <- head(y_min,1)
	y_max <- head(y_max,1)
	height <- head(height,1)
	width <- head(width,1)
	if (height <= 124) {
		stop('[',LfuncName,'][height] is too small!')
	}
	if (width <= 108) {
		stop('[',LfuncName,'][width] is too small!')
	}
	lineColor <- head(lineColor,1)
	gradient <- head(gradient,1)
	if (!is.logical(gradient)) {
		stop('[',LfuncName,'][gradient] must be logical!')
	}
	symSize <- head(symSize,1)
	symColor <- head(symColor,1)
	disp_min <- head(disp_min,1)
	disp_max <- head(disp_max,1)
	disp_sym <- head(disp_sym,1)
	title <- head(title,1)
	titleSize <- head(titleSize,1)
	theme <- head(theme,1)
	transparent <- head(transparent,1)
	fontFamily <- head(fontFamily,1)
	fontSize <- head(fontSize,1)
	jsFmtFloat <- head(jsFmtFloat,1)
	fmtTTSym <- head(fmtTTSym,1)
	xAxis.zoom <- head(xAxis.zoom,1)
	if (!is.function(container)) {
		container <- head(container,1)[[1]]
	}
	fontSize_css <- htmltools::validateCssUnit(fontSize)
	fontSize_ech <- fontSize_css %>% {gsub('^(((\\d+)?\\.)?\\d+).*$','\\1', .)} %>% as.numeric()

	#012. Handle the parameter buffer
	if (length(y_min) == 0) y_min <- 'dataMin'
	if (length(y_max) == 0) y_max <- 'dataMax'

	#015. Function local variables
	pct_7D <- length(xAxis[xAxis >= max(xAxis, na.rm = T) - as.difftime(7, units = 'days')]) / length(xAxis)
	pct_30D <- length(xAxis[xAxis >= max(xAxis, na.rm = T) - as.difftime(30, units = 'days')]) / length(xAxis)
	pct_180D <- length(xAxis[xAxis >= max(xAxis, na.rm = T) - as.difftime(180, units = 'days')]) / length(xAxis)
	pct_1Y <- length(xAxis[xAxis >= max(xAxis, na.rm = T) - as.difftime(365, units = 'days')]) / length(xAxis)
	pct_5Y <- length(xAxis[xAxis >= max(xAxis, na.rm = T) - as.difftime(1875, units = 'days')]) / length(xAxis)
	zoom_cfg <- list(
		'7D' = list(
			'id' = '7D'
			,'name' = '7D'
			,'min' = round((1 - pct_7D) * 100, 4)
			,'max' = 100
		)
		,'30D' = list(
			'id' = '30D'
			,'name' = '30D'
			,'min' = round((1 - pct_30D) * 100, 4)
			,'max' = 100
		)
		,'180D' = list(
			'id' = '180D'
			,'name' = '180D'
			,'min' = round((1 - pct_180D) * 100, 4)
			,'max' = 100
		)
		,'1Y' = list(
			'id' = '1Y'
			,'name' = '1Y'
			,'min' = round((1 - pct_1Y) * 100, 4)
			,'max' = 100
		)
		,'5Y' = list(
			'id' = '5Y'
			,'name' = '5Y'
			,'min' = round((1 - pct_5Y) * 100, 4)
			,'max' = 100
		)
	)
	btn_width <- ifelse(xAxis.zoom, 48, 0)
	zoom_height <- ifelse(xAxis.zoom, 32, 0)
	k_grad <- 20

	#100. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = transparent)
	tt_theme <- themeColors(theme, transparent = F)

	#200. Helper functions
	#210. Function to calculate the color ramp on vectorized basis
	fn_colramp <- function(v_bgn,v_end,a_bgn,a_end,k = k_grad) {
		v_alphas <- seq(a_bgn,a_end,length.out = k)
		v_col <- rgba2rgb(v_bgn, alpha_in = v_alphas, color_bg = v_end)
		js_stop <- round(scales::rescale(seq_len(k), from = c(1,k), to = c(a_bgn,a_end)), 2)
		v_col_stop <- mapply(
			function(o,c){list(offset = o, color = c)}
			,js_stop,v_col
			,SIMPLIFY = F
		)
		rstOut <- jsonlite::toJSON(v_col_stop, auto_unbox = T) %>%
			{gsub(paste0('"(\\w+)":'), '\\1:', ., perl = T)} %>%
			{gsub('"','\'',.)}
		return(rstOut)
	}

	#230. Function to paste the attribute names with their respective values
	h_attr <- function(attr, atype, important = FALSE, theme = tt_theme) {
		imp <- ifelse(important, ' !important', '')
		paste0(paste0(attr, ': ', theme[[attr]][[atype]], imp, ';'), collapse = '')
	}

	#300. Setup styles
	#301. Override the colors when required
	if (length(lineColor) == 0) {
		col_line <- coltheme[['color']][['chart-line']]
	} else {
		col_line <- lineColor
	}
	if (length(symColor) == 0) {
		col_sym <- coltheme[['color']][['chart-sym']]
	} else {
		col_sym <- symColor
	}

	#310. Create the styles of [tooltip] for this specific chart
	tooltip <- list(
		textStyle = list(
			fontFamily = fontFamily
			,fontSize = fontSize_ech
			,color = tt_theme[['color']][['tooltip']]
		)
		,backgroundColor = tt_theme[['background-color']][['tooltip-inverse']]
		,borderColor = tt_theme[['border-color']][['tooltip']]
		,extraCssText = paste0(''
			,'box-shadow: ',tt_theme[['box-shadow']][['tooltip']]
		)
	)

	#320. Define button styles
	fontFamily_css <- paste0(
		sapply(fontFamily, function(m){if (length(grep('\\W',m,perl = T))>0) paste0('\'',m,'\'') else m})
		,collapse = ','
	)
	styles_btn <- paste0(''
		,'.dt_btn_as_tooltip {'
			,'box-sizing: border-box;'
			,'padding: .5em 0;'
			,'margin-left: 2px;'
			,'text-align: center;'
			,'align-items: center;'
			,'text-decoration: none;'
			,'cursor: pointer;'
			,'border-radius: 2px;'
			,'font-family: ',fontFamily_css,';'
			,'font-size: ',fontSize_css,';'
			,'background' %>% h_attr('btn-inact')
			,'border' %>% h_attr('btn-inact')
			,'color' %>% h_attr('btn-inact')
			,'font-weight: 100;'
			,'line-height: 1;'
			,'width:',btn_width,'px !important;'
		,'}'
		,'.dt_btn_as_tooltip:hover {'
			,'background' %>% h_attr('btn-inact-hover')
			,'border' %>% h_attr('btn-inact-hover')
			,'color' %>% h_attr('btn-inact-hover')
		,'}'
	)

	#330. Line color
	#Quote: https://blog.csdn.net/qq_27387133/article/details/104775683
	if (!gradient) {
		lineStyle_color <- col_line
	} else {
		col_ramp <- fn_colramp(
			col_line
			,coltheme[['background-color']][['default']]
			,0.1
			,1
			,k_grad
		)
		#20221221 It is tested for [echarts <= 5.4.1], lineStyle.color only accepts Function Call, instead of Function Definition
		lineStyle_color <- paste0(''
			,'new echarts.graphic.LinearGradient(0,1,0,0,',col_ramp,')'
		)
	}

	#350. Format the tooltip for current chart
	if (length(fmtTTSym) > 0) {
		tooltip_sym <- modifyList(tooltip, list(formatter = htmlwidgets::JS(fmtTTSym)))
	} else {
		tooltip_sym <- modifyList(
			tooltip
			,list(
				formatter = htmlwidgets::JS(paste0(''
					,'function(params){'
						,'return('
							,'\'<strong>',disp_sym,'</strong>\''
							,'+ \' : \' + parseFloat(params.value[1]).',jsFmtFloat
						,');'
					,'}'
				))
			)
		)
	}

	#500. Create the charting script
	ch_html <- eval(rlang::expr(
		data.frame(.ech.xaxis = xAxis, .ech.value = vec_value) %>%
		#[IMPORTANT] It is tested that the size of [canvas] is unexpected if we set [width] or [height] for [e_charts]
		echarts4r::e_charts(.ech.xaxis, elementId = html_id) %>%
		echarts4r::e_grid(
			index = 0
			, top = 40, right = 40, bottom = 40 + zoom_height, left = 0
			, height = height - 48 - zoom_height, width = width - 8
			, containLabel = TRUE
		) %>%
		#300. Draw a line with the symbol
		echarts4r::e_line(
			.ech.value
			,x_index = 0
			,y_index = 0
			,name = disp_sym
			# ,tooltip = tooltip_sym
			,symbol = 'circle'
			,symbolSize = symSize
			,showSymbol = TRUE
			,itemStyle = list(
				#This color results in the same in [legend]
				color = col_sym
				,borderColor = col_line
				,borderWidth = 0.5
			)
			,lineStyle = list(
				#This color is different from that in [legend]
				color = lineStyle_color
				,width = 1
			)
			,markPoint = list(
				silent = TRUE
				,symbol = 'pin'
				#20211225 It is tested [symbolOffset] takes no effect on [echarts4r==0.4.2]
				# ,symbolOffset = c('0px','40px')
				,symbolSize = 48
				,symbolRotate = htmlwidgets::JS(paste0(''
					,'function(value,params){'
						,'var rotate = 0;'
						,'if (params.data.type == \'max\') {'
							,'rotate = 180;'
						,'} '
						,'return(rotate);'
					,'}'
				))
				,label = list(
					fontFamily = fontFamily
					,fontSize = fontSize_ech
					,color = coltheme[['color']][['chart-markpoint']]
					,backgroundColor = rgba2rgb(col_line, alpha_in = 0.7)
					,borderColor = col_line
					,borderWidth = 1
					,borderRadius = 2
					,padding = 4
					,offset = c(0,4)
					,position = 'inside'
					,formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'var placeholder = \'\';'
							,'return('
								,'placeholder + parseFloat(params.value).',jsFmtFloat
							,');'
						,'}'
					))
				)
				,itemStyle = list(
					color = paste0(col_line, '00')
					,borderColor = paste0(col_line, '00')
					,borderWidth = 0
				)
				,data = list(
					list(
						name = disp_min
						,type = 'min'
					)
					,list(
						name = disp_max
						,type = 'max'
					)
				)
			)
		) %>%
		#400. Setup the axes
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,type = 'time'
			,axisLabel = list(
				fontFamily = fontFamily
				,fontSize = fontSize_ech
				,formatter = '{yyyy}-{MM}-{dd}'
				,hideOverlap = TRUE
			)
			,axisLine = list(
				lineStyle = list(
					color = col_line
				)
			)
			,axisTick = list(
				lineStyle = list(
					color = col_line
				)
			)
			,minorTick = list(
				lineStyle = list(
					color = col_line
				)
			)
			,axisPointer = list(
				show = TRUE
				,triggerTooltip = FALSE
				,label = list(
					fontFamily = fontFamily
					,fontSize = fontSize_ech
					,formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'return('
								,'echarts.format.formatTime(\'yyyy-MM-dd\', params.value)'
							,');'
						,'}'
					))
					,color = coltheme[['color']][['chart-markpoint']]
					,borderColor = rgba2rgb(col_line, alpha_in = 0.7)
					,backgroundColor = rgba2rgb(col_line, alpha_in = 0.7)
				)
				,lineStyle = list(
					color = paste0(col_line, alphaToHex(0.1))
					,type = 'dotted'
				)
			)
		) %>%
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,type = 'value'
			,min = y_min
			,max = y_max
			,splitLine = list(
				lineStyle = list(
					color = paste0(col_line, alphaToHex(0.1))
					,type = 'dotted'
				)
			)
			,minorSplitLine = list(
				show = FALSE
			)
			,axisLabel = list(
				fontFamily = fontFamily
				,fontSize = fontSize_ech
				,formatter = htmlwidgets::JS(paste0(''
					,'function(value, index){'
						,'return('
							,'value.',jsFmtFloat
						,');'
					,'}'
				))
			)
			,axisLine = list(
				lineStyle = list(
					color = col_line
				)
			)
			,axisTick = list(
				lineStyle = list(
					color = col_line
				)
			)
			,minorTick = list(
				lineStyle = list(
					color = col_line
				)
			)
			,axisPointer = list(
				show = TRUE
				,triggerTooltip = FALSE
				,label = list(
					fontFamily = fontFamily
					,fontSize = fontSize_ech
					,formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'return('
								,'parseFloat(params.value).',jsFmtFloat
							,');'
						,'}'
					))
					,color = coltheme[['color']][['chart-markpoint']]
					,borderColor = rgba2rgb(col_line, alpha_in = 0.7)
					,backgroundColor = rgba2rgb(col_line, alpha_in = 0.7)
				)
				,lineStyle = list(
					color = paste0(col_line, alphaToHex(0.1))
					,type = 'dotted'
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
			show = FALSE
			,textStyle = list(
				fontFamily = fontFamily
				,fontSize = fontSize_ech
				,color = coltheme[['color']][['header']]
			)
		) %>%
		#800. Extra configurations
		#820. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#880. Enable the tooltip triggered by mouse over the bars
		echarts4r::e_tooltip(
			trigger = 'item'
			,confine = TRUE
			,appendToBody = TRUE
			,enterable = FALSE
			,axisPointer = list(
				show = TRUE
				,z = 9999
			)
			,!!!tooltip_sym
		)
	))

	#520. Add zooming bar if required
	if (xAxis.zoom) {
		ch_html %<>%
			echarts4r::e_datazoom(
				x_index = 0
				,bottom = 4
				,toolbox = F
				,type = 'slider'
				,filterMode = 'filter'
				,backgroundColor = tt_theme[['background-color']][[ifelse(as.tooltip, 'tooltip', 'default')]]
				,dataBackground = list(
					lineStyle = list(
						type = 'dotted'
						,color = col_line
						,opacity = 0.2
						,width = 0.5
					)
					,areaStyle = list(
						opacity = 0.1
						,color = col_line
					)
				)
				,selectedDataBackground = list(
					lineStyle = list(
						type = 'solid'
						,color = col_line
						,opacity = 0.2
						,width = 0.5
					)
					,areaStyle = list(
						opacity = 0.2
						,color = col_line
					)
				)
				,fillerColor = paste0(col_line, alphaToHex(0.1))
				,borderColor = paste0(col_line, alphaToHex(0.1))
				,handleStyle = list(
					color = col_line
					,borderColor = col_line
				)
				,moveHandleStyle = list(
					color = col_line
					,opacity = 0.2
					,borderColor = paste0(col_line, alphaToHex(0.2))
				)
				,labelFormatter = htmlwidgets::JS(paste0(''
					,'function(value){'
						,'return('
							,'echarts.format.formatTime(\'yyyy-MM-dd\', value)'
						,');'
					,'}'
				))
				,textStyle = list(
					fontFamily = fontFamily
					,fontSize = fontSize_ech
					,color = col_line
				)
				,brushStyle = list(
					color = col_line
					,opacity = 0.1
					,borderColor = paste0(col_line, alphaToHex(0.2))
				)
				,emphasis = list(
					handleStyle = list(
						color = col_line
						,borderColor = col_line
					)
					,moveHandleStyle = list(
						color = col_line
						,opacity = 0.3
						,borderColor = paste0(col_line, alphaToHex(0.2))
					)
				)
			)
	}

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
	ech_obj_name <- paste0('ttLine_', gsub('\\W', '_', vfy_html_id))
	h_contain <- function(html_tag){
		if (!xAxis.zoom) return(html_tag)
		paste0(''
			#Quote: https://www.cnblogs.com/zhuzhenwei918/p/6058457.html
			,'<div style=\''
				,'position:relative;'
				,'display:inline-block;'
				,'margin:0;'
				,'padding:0;'
				,'font-size:0;'
				,'width:',width,'px;'
				,'height:',height,'px;'
			,'\'>'
				,'<div style=\'display:inherit;font-size:',fontSize_css,';width:',width,'px;height:',height,'px;\'>'
					,html_tag
				,'</div>'
				,'<div style=\''
					,'position:absolute;'
					,'display:inline-block;'
					,'font-size:0;'
					,'top:8px;'
					,'right:20px;'
					,'white-space:nowrap;'
				,'\'>'
					,'<style type=\'text/css\'>'
						,styles_btn
					,'</style>'
					,paste0(
						mapply(
							function(x,x_name){
								js_callback <- paste0(''
									,x_name,'.dispatchAction({'
										#[IMPORTANT] We cannot use double quotes here, as there will be two consecutive calls
										#             of [shQuote] in the following steps (the other is in [echarts4r.as.tooltip]),
										#             which causes syntax error on multiple double-quotes
										,'type: \'dataZoom\''
										,',dataZoomIndex: 0'
										,',start: ',x[['min']]
										,',end: ',x[['max']]
									,'})'
								)
								paste0(
									'<button id=\'',vfy_html_id,'_',x[['id']],'\''
										,' class=\'dt_btn_as_tooltip\''
										,' onclick=',shQuote(js_callback)
									,'>'
										,x[['name']]
									,'</button>'
								)
							}
							,zoom_cfg
							,ech_obj_name
						)
						,collapse = ''
					)
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

		#070. Load the raw data
		myenv <- new.env()
		load(file.path(getOption('path.omniR'), 'Visualization', 'prodprice.rdata'), envir = myenv)
		# View(myenv$ProdPrice)

		#100. Create sample data
		ch_fundprice <- myenv$ProdPrice %>%
			dplyr::group_by(ProdName_CN) %>%
			dplyr::arrange(d_data) %>%
			dplyr::summarise(
				c_currency = dplyr::last(c_currency)
				,pr_min = min(Price, na.rm = T)
				,pr_max = max(Price, na.rm = T)
				,pr_curr = dplyr::last(Price)
				,pr_mean = mean(Price, na.rm = T)
				,ech_line = echarts4r_vec_line(
					Price
					,xAxis = d_data
					#20220413 It is tested that if we manually set [html_id], the chart may not display when hovering over,
					#          hence we should never (or under certain condition?) set it
					# ,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
					,disp_min = '历史最低'
					,disp_max = '历史最高'
					,disp_sym = '当日净值'
					,title = '净值走势'
					,theme = uRV$theme
					,jsFmtFloat = 'toFixed(4)'
					,fmtTTSym = NULL
					,as.tooltip = TRUE
				)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				pr_color = ifelse(
					pr_curr >= pr_mean
					, uRV$coltheme[['color']][['chart-bar-incr']]
					, uRV$coltheme[['color']][['chart-bar-decr']]
				)
			) %>%
			dplyr::mutate(
				pr_ech = echarts4r_Capsule(
					pr_min
					,pr_max
					,pr_curr
					,barColor = pr_color
					,symColor = uRV$coltheme[['color']][['chart-sym-light']]
					,disp_min = '历史最低'
					,disp_max = '历史最高'
					,disp_sym = '最新净值'
					,theme = uRV$theme
					,fmtTTSym = ech_line
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('ProdName_CN','c_currency','pr_curr','pr_ech')
		dt_fundprice <- DT::datatable(
			ch_fundprice %>% dplyr::select(tidyselect::all_of(cols))
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
		div_funcprice <- shiny::fluidRow(
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
					,dt_fundprice
				)
			)
		)

		path_rpt <- dirname(thisfile())
		rpt_tpl <- file.path(path_rpt, 'echarts4r_vec_line.Rmd')
		rpt_out <- file.path(path_rpt, 'FundPrice.html')
		rmarkdown::render(
			rpt_tpl
			,output_file = rpt_out
			,params = list(
				dt = div_funcprice
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
						,dt_fundprice
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}

	#Test [dplyr::mutate] when enabling [as.parts]
	if (TRUE) {
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#020. Simulate the private environment of Shiny App, to generalize the usage of this function
		uRV <- list()

		#050. Choose theme
		uRV$theme <- 'BlackGold'
		uRV$coltheme <- themeColors(uRV$theme)

		#070. Load the raw data
		myenv <- new.env()
		load(file.path(getOption('path.omniR'), 'Visualization', 'prodprice.rdata'), envir = myenv)
		# View(myenv$ProdPrice)

		#100. Create sample data
		ch_fundprice <- myenv$ProdPrice %>%
			dplyr::group_by(ProdName_CN) %>%
			dplyr::arrange(d_data) %>%
			dplyr::summarise(
				c_currency = dplyr::last(c_currency)
				,pr_min = min(Price, na.rm = T)
				,pr_max = max(Price, na.rm = T)
				,pr_curr = dplyr::last(Price)
				,pr_mean = mean(Price, na.rm = T)
				,ech_line = echarts4r_vec_line(
					Price
					,xAxis = d_data
					,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
					,disp_min = '历史最低'
					,disp_max = '历史最高'
					,disp_sym = '当日净值'
					,title = '净值走势'
					,theme = uRV$theme
					,jsFmtFloat = 'toFixed(4)'
					,fmtTTSym = NULL
					,as.tooltip = TRUE
					,as.parts = TRUE
				)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup()

		View(ch_fundprice$ech_line)
		class(ch_fundprice$ech_line)
		#[ASSUMPTION]
		#[1] [ch_fundprice$ech_line] is a data.frame when created by this function using [dplyr::mutate]
		#[2] Columns of it show as [ech_line.xxx] when using [View], but they cannot be referenced in such name
		#[3] The way to reference these columns should still be [ch_fundprice$ech_line$xxx]
	}
}
