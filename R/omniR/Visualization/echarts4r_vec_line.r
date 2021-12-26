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
#   |                 [NOT-NULL    ]           All charts have the same scale at y-axis, which is usefull for parallel comparison       #
#   |y_max       :   Numeric as the maximum value of y-axis. It is useful to unify the y-axis of the charts                             #
#   |                 [NULL        ] <Default> Charts will have different scales at y-axis                                              #
#   |                 [NOT-NULL    ]           All charts have the same scale at y-axis, which is usefull for parallel comparison       #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |height      :   Integer of the chart height                                                                                        #
#   |                 [540         ] <Default>                                                                                          #
#   |width       :   Integer of the chart width                                                                                         #
#   |                 [960         ] <Default>                                                                                          #
#   |lineColor   :   Character as the CSS color of the line in current chart                                                            #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
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
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]                                                  #
#   |                 [14p       ] <Default> Common font size                                                                           #
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
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector]   :   A vector of HTML widgets represented as character strings                                                           #
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

echarts4r_vec_line <- function(
	vec_value
	,xAxis
	,y_min = NULL
	,y_max = NULL
	,html_id = NULL
	,height = 540
	,width = 960
	,lineColor = NULL
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
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (!all(class(xAxis) %in% c('Date'))) {
		stop('[',LfuncName,'][xAxis] must be an object of class [Date]!')
	}
	if (height <= 124) {
		stop('[',LfuncName,'][height] is too small!')
	}
	if (width <= 108) {
		stop('[',LfuncName,'][width] is too small!')
	}
	fontSize <- htmltools::validateCssUnit(fontSize)

	#012. Handle the parameter buffer
	if ((length(vec_value) == 0) | (length(xAxis) == 0)) return(character(0))
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
	zoom_height <- ifelse(xAxis.zoom, 16, 0)

	#100. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = transparent)
	tt_theme <- themeColors(theme, transparent = F)

	#200. Setup styles
	#201. Function to paste the attribute names with their respective values
	h_attr <- function(attr, atype, important = FALSE, theme = tt_theme) {
		imp <- ifelse(important, ' !important', '')
		paste0(paste0(attr, ': ', theme[[attr]][[atype]], imp, ';'), collapse = '')
	}

	#210. Create the styles of [tooltip] for this specific chart
	tooltip <- list(
		textStyle = list(
			fontFamily = fontFamily
			,fontSize = fontSize
			,color = tt_theme[['color']][['tooltip']]
		)
		,backgroundColor = tt_theme[['background-color']][['tooltip-light']]
		,borderColor = tt_theme[['border-color']][['tooltip']]
		,extraCssText = paste0(''
			,'box-shadow: ',tt_theme[['box-shadow']][['tooltip']]
		)
	)

	#220. Define button styles
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
			,'font-size: ',fontSize,';'
			,'background' %>% h_attr('btn-inact')
			,'border' %>% h_attr('btn-inact')
			,'color' %>% h_attr('btn-inact')
			,'font-weight: 100;'
			,'line-height: 1;'
			,'width:',btn_width,'px;'
		,'}'
		,'.dt_btn_as_tooltip:hover {'
			,'background' %>% h_attr('btn-inact-hover')
			,'border' %>% h_attr('btn-inact-hover')
			,'color' %>% h_attr('btn-inact-hover')
		,'}'
	)

	#250. Format the tooltip for current chart
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
							,'+ " : " + parseFloat(params.value[1]).',jsFmtFloat
						,');'
					#[IMPORTANT] We must place such remark to ensure [echarts4r.as.tooltip] can locate this function correctly
					,'/*EndFunc*/}'
				))
			)
		)
	}

	#300. Override the colors when required
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

	#500. Create the charting script
	ch_html <- eval(rlang::expr(
		data.frame(.ech.xaxis = xAxis, .ech.value = vec_value) %>%
		#[IMPORTANT] It is tested that the size of [canvas] is unexpected if we set [width] or [height] for [e_charts]
		echarts4r::e_charts(.ech.xaxis, elementId = html_id) %>%
		echarts4r::e_grid(
			index = 0
			, top = 40, right = 40, bottom = 40 + zoom_height, left = 56
			, height = height - 80 - zoom_height, width = width - 64
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
				color = col_line
				,width = 1
			)
			,markPoint = list(
				silent = TRUE
				,symbol = 'pin'
				#20211225 It is tested [symbolOffset] takes no effect on [echarts4r==0.4.2]
				,symbolOffset = c('0px','40px')
				,symbolSize = c(96,40)
				,symbolRotate = htmlwidgets::JS(paste0(''
					,'function(value,params){'
						,'var rotate = 0;'
						,'if (params.data.type == \'max\') {'
							,'rotate = 180;'
						,'} '
						,'return(rotate);'
					,'/*EndFunc*/}'
				))
				,label = list(
					fontFamily = fontFamily
					,fontSize = fontSize
					,color = coltheme[['color']][['chart-markpoint']]
					,formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'var placeholder = \'\';'
							,'if (params.data.type == \'max\') {'
								,'placeholder = \'\n\';'
							,'} '
							,'return('
								,'placeholder + parseFloat(params.value).',jsFmtFloat
							,');'
						,'/*EndFunc*/}'
					))
				)
				,itemStyle = list(
					color = rgba2rgb(col_line, alpha_in = 0.7)
					,borderColor = col_line
					,borderWidth = 1
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
				,fontSize = fontSize
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
					,fontSize = fontSize
					,formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'return('
								,'echarts.format.formatTime(\'yyyy-MM-dd\', params.value)'
							,');'
						,'/*EndFunc*/}'
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
				,fontSize = fontSize
				,formatter = htmlwidgets::JS(paste0(''
					,'function(value, index){'
						,'return('
							,'value.',jsFmtFloat
						,');'
					,'/*EndFunc*/}'
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
					,fontSize = fontSize
					,formatter = htmlwidgets::JS(paste0(''
						,'function(params){'
							,'return('
								,'parseFloat(params.value).',jsFmtFloat
							,');'
						,'/*EndFunc*/}'
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
				,fontSize = fontSize
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
					,'/*EndFunc*/}'
				))
				,textStyle = list(
					fontFamily = fontFamily
					,fontSize = fontSize
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
	h_contain <- function(html_tag){
		if (!xAxis.zoom) return(html_tag)
		paste0(''
			#Quote: https://www.cnblogs.com/zhuzhenwei918/p/6058457.html
			,'<div style=\'display:inline-block;margin:0;padding:0;font-size:0;width:',width,'px;height:',height,'px;\'>'
				,'<div style=\'display:inherit;font-size:',fontSize,';width:',width,'px;height:',height,'px;\'>'
					,html_tag
				,'</div>'
				,'<div style=\''
					,'position:absolute;'
					,'display:inline-block;'
					,'font-size:0;'
					,'top:12px;'
					,'right:20px;'
					,'white-space:nowrap;'
				,'\'>'
					,'<style type=\'text/css\'>'
						,styles_btn
					,'</style>'
					,paste0(
						sapply(
							zoom_cfg
							,function(x){
								js_callback <- paste0(''
									,'ttChart.dispatchAction({'
										#[IMPORTANT] We cannot use double quotes here, as there will be two consecutive calls
										#             of [shQuote] in the following steps (the other is in [echarts4r.as.tooltip]),
										#             which causes syntax error onmultiple double-quotes
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
						)
						,collapse = ''
					)
				,'</div>'
			,'</div>'
		)
	}

	#900. Convert the widget into tooltip
	ch_tooltip <- echarts4r.as.tooltip(ch_html, container = h_contain, ech_name = 'ttChart')

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
					,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
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
}
