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
#   |[10] Different gradient colors of different bars: https://blog.csdn.net/kimbing/article/details/109769527                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This can be useful if one needs to render charts within [DT::datatable]                                                        #
#   |[2] Draw charts for groups of keys distributed by several categories, such as customer number distribution by AUM category         #
#   |[3] Draw charts within [echarts:tooltip] for another vectorized chart series                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec_value   :   Numeric vector to be used as [values] to draw the charts                                                           #
#   |vec_cat     :   Vector by which to draw the bars                                                                                   #
#   |                [IMPORTANT] Program will coerce this vector as character anyway, for the chart can only recognize the axis value   #
#   |                             as well as the tooltip value when they are all character strings, it is weird on echarts ver.=5.3.2   #
#   |y_min       :   Numeric as the minimum value of y-axis. It is useful to unify the y-axis of the charts                             #
#   |                 [NULL        ] <Default> Charts will have different scales at y-axis                                              #
#   |                 [NOT-NULL    ]           All charts have the same scale at y-axis, which is useful for parallel comparison        #
#   |y_max       :   Numeric as the maximum value of y-axis. It is useful to unify the y-axis of the charts                             #
#   |                 [NULL        ] <Default> Charts will have different scales at y-axis                                              #
#   |                 [NOT-NULL    ]           All charts have the same scale at y-axis, which is useful for parallel comparison        #
#   |sortBy      :   Character vector to determine how to display the bars in specific order                                            #
#   |                 [input       ] <Default> The order follows the input sequence of [vec_cat]                                        #
#   |                 [category    ]           Function sorts the input data by [vec_cat] in ASCENDING order and then draw the chart    #
#   |                 [value       ]           Function sorts the input data by [vec_value] in DESCENDING order and then draw the chart #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |height      :   Integer of the chart height                                                                                        #
#   |                 [540         ] <Default>                                                                                          #
#   |width       :   Integer of the chart width                                                                                         #
#   |                 [960         ] <Default>                                                                                          #
#   |direction   :   Character vector to determine the direction of the bar                                                             #
#   |                 [column      ] <Default> Draw the column chart                                                                    #
#   |                 [bar         ]           Draw the bar chart, in such case, the order of the bars as indicated by [sortBy] will be #
#   |                                           changed into below result:                                                              #
#   |                                          [input       ] The first record is at the closest point to the category axis             #
#   |                                          [category    ] The first among the sorted categories is at the top of the chart          #
#   |                                          [value       ] The largest among the sorted values is at the top of the chart            #
#   |barWidth    :   Value of the bar width, can be integer or percentage; only the first is taken if multiple values are provided      #
#   |                Quote: https://echarts.apache.org/zh/option.html#series-bar.barWidth                                               #
#   |                 [NULL        ] <Default> Adaptive to the chart                                                                    #
#   |                 [<int>       ]           Absolute pixels as width                                                                 #
#   |                 [<chr>       ]           Character string as percent, representing the proportion of automatic width              #
#   |barColPos   :   Character as the CSS color of the bars with positive values in current chart                                       #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax for all the bars, or the tallest one if [gradient=all]     #
#   |                 [<vec>       ]           Character vector in the same length as [vec_cat] representing color codes, to differ the #
#   |                                           colors of bars one-by-one                                                               #
#   |barColNeg   :   Character as the CSS color of the bars with negative values in current chart                                       #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax for all the bars, or the tallest one if [gradient=all]     #
#   |                 [<vec>       ]           Character vector in the same length as [vec_cat] representing color codes, to differ the #
#   |                                           colors of bars one-by-one                                                               #
#   |gradient    :   Whether to draw the bar with gradient color effect                                                                 #
#   |                 [TRUE|all    ] <Default> Draw the bar with gradient color effect. In such case, [barColor] plays as the color on  #
#   |                                           the top of the longest bar and fades gradually to the closest to bg-color               #
#   |                 [FALSE|none  ]           Draw the bar with the provided color [barColor]                                          #
#   |                 [respective  ]           Draw the bar with gradient color effect. In such case, [barColor] plays as the color on  #
#   |                                           the top of each bar and fades gradually to the closest to bg-color                      #
#   |disp_name   :   Character as the name showing in the tooltip on the bar                                                            #
#   |                 [Value       ] <Default> Value of current data point                                                              #
#   |func_add    :   Function that takes <echarts4r> object as the first argument, as direct injection to the charting scripts. It can  #
#   |                 enable charting for multiple series, such as histogram with density or pareto chart.                              #
#   |                [IMPORTANT] Be cautious to use this as it can lead to unexpected result!                                           #
#   |                 [<see def.>  ] <Default> No program injection                                                                     #
#   |stack       :   Character as the name of stack when multiple series require stacking                                               #
#   |                 [Bar         ] <Default> Use this as the name of current stack                                                    #
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
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]. It is highly recommended to provide integer or  #
#   |                 float numbers, since [echarts::textStyle.fontSize] cannot properly resolve other inputs in nested charts          #
#   |                 [14          ] <Default> Common font size                                                                         #
#   |jsFmtFloat  :   Character vector of the JS methods applied to JS:Float values (which means [vec_value] for this function) of each  #
#   |                 chart respectively                                                                                                #
#   |                 Quote: https://www.techonthenet.com/js/number_tolocalestring.php                                                  #
#   |                 [<see def.>  ] <Default> Format all values into numbers with fixed decimals as 2, separated by comma              #
#   |fmtTTbar    :   Character as the formatter to tweak the [tooltip] for when mouse hovering on the bars of current chart             #
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
#   | Date |    20220415        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220416        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new argument [func_add] to enable direct injection of programs to tweak the chart, such as adding series    #
#   |      |     for the chart, or adding effects. Be cautious to use this as it can lead to unexpected result.                         #
#   |      |[2] Introduce a new argument [stack] to enable stacking of series, effective when [func_add] is in use                      #
#   |      |[3] 20220416 [echarts=5.3.0] It is tested that function is accepted for <bar.itemStyle.color>                               #
#   |      |     but NOT accepted for <bar.emphasis.itemStyle.color> (while it regards <func()> as valid, with no parameter given)      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220419        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Corrected the error to fail the drawing when the data point is zero or infinite or NaN, as the gradient color cannot be #
#   |      |     calculated based on erroneous index                                                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221117        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] It is tested that [echarts::textStyle.fontSize] cannot resolve text input, such as '14px', within the nested charts,    #
#   |      |     hence we suppress the text input from the beginning. Meanwhile, keep the parsed text [fontSize] for any CSS codes to   #
#   |      |     retain the compatibility.                                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221211        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Leverage the default behavior of [match.arg] to simplify the function definition                                        #
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
#   |   |magrittr, rlang, echarts4r, htmlwidgets, htmltools, dplyr, scales, jsonlite                                                    #
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
	magrittr, rlang, echarts4r, htmlwidgets, htmltools, dplyr, scales, jsonlite
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

echarts4r_vec_bar <- function(
	vec_value
	,vec_cat
	,y_min = NULL
	,y_max = NULL
	,sortBy = c('input','category','value')
	,html_id = NULL
	,height = 440
	,width = 640
	,direction = c('column','bar')
	,barWidth = NULL
	,barColPos = NULL
	,barColNeg = NULL
	,gradient = TRUE
	,disp_name = 'Value'
	,func_add = function(obj_echarts){obj_echarts}
	,stack = 'Bar'
	,title = 'Bar'
	,titleSize = 18
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = TRUE
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	,jsFmtFloat = 'toLocaleString(\'en-US\', {minimumFractionDigits:2, maximumFractionDigits:2})'
	,fmtTTbar = NULL
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

	#012. Handle the parameter buffer
	if (length(vec_value) != length(vec_cat)) {
		stop('[',LfuncName,'][vec_value] has different length [',length(vec_value),'] to [vec_cat] as [',length(vec_cat),']!')
	}
	if ((length(vec_value) == 0) | (length(vec_cat) == 0)) return(character(0))
	if (length(y_min) == 0) y_min <- NULL
	if (length(y_max) == 0) y_max <- NULL
	sortBy <- match.arg(sortBy)
	direction <- match.arg(direction)
	barWidth <- head(barWidth,1)
	if (!(length(barColPos) %in% c(0,1,length(vec_cat)))) {
		stop('[',LfuncName,'][barColPos] has length [',length(barColPos),'], which is different to the input data!')
	}
	if (!(length(barColNeg) %in% c(0,1,length(vec_cat)))) {
		stop('[',LfuncName,'][barColNeg] has length [',length(barColNeg),'], which is different to the input data!')
	}
	choice_gradient <- c('none', 'all', 'respective')
	gradient <- head(gradient,1)
	if (is.character(gradient)) {
		gradient <- match.arg(gradient, choice_gradient)
	} else if (is.logical(gradient)) {
		if (gradient) {
			gradient <- 'all'
		} else {
			gradient <- 'none'
		}
	} else {
		stop('[',LfuncName,'][gradient] should be logical or one of: [',paste0(choice_gradient, collapse = ']['),']!')
	}
	disp_name <- head(disp_name,1)
	fontSize_css <- htmltools::validateCssUnit(fontSize)
	fontSize_ech <- fontSize_css %>% {gsub('^(((\\d+)?\\.)?\\d+).*$','\\1', .)} %>% as.numeric()

	#015. Function local variables
	if (direction == 'column') {
		val_axis <- '1'
	} else {
		val_axis <- '0'
	}

	#100. Setup styles
	#110. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = transparent)
	tt_theme <- themeColors(theme, transparent = F)
	col_line <- coltheme[['color']][['chart-line']]

	#120. Create the styles of [tooltip] for this specific chart
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

	#150. Format the tooltip for current chart
	if (length(fmtTTbar) > 0) {
		tooltip_bar <- modifyList(tooltip, list(formatter = htmlwidgets::JS(fmtTTbar)))
	} else {
		tooltip_bar <- modifyList(
			tooltip
			,list(
				formatter = htmlwidgets::JS(paste0(''
					,'function(params){'
						,'return('
							#Quote: https://www.tutorialspoint.com/how-to-convert-a-value-to-a-string-in-javascript
							,'\'<strong>\' + String(\'',disp_name,'\') + \'</strong>\''
							,'+ \'<br/>\' + parseFloat(params.value[',val_axis,']).',jsFmtFloat
						,');'
					,'}'
				))
			)
		)
	}

	#160. Determine the background color for interpolation
	if (as.tooltip) {
		col_bg <- coltheme[['background-color']][['tooltip']]
	} else {
		col_bg <- coltheme[['background-color']][['default']]
	}

	#170. Determine the number of checkpoints on the color ramp
	#We cut the color palette into these <k> pieces, which is enough for gradient of a bar
	k_colors <- 50

	#175. Prepare the interpolation of alpha between 0.07 (the least effective value) and 1
	alpha_interp <- round(scales::rescale(seq_len(k_colors), from = c(1,k_colors), to = c(0.07,1)), 2)

	#180. Define the colors at the extreme points
	if (length(barColPos) == 0) {
		barColPos <- coltheme[['color']][['chart-bar']]
	}
	if (length(barColPos) == 1) {
		barColPos <- rlang::rep_along(vec_cat, barColPos)
	}
	if (length(barColNeg) == 0) {
		barColNeg <- coltheme[['color']][['chart-bar-inverse']]
	}
	if (length(barColNeg) == 1) {
		barColNeg <- rlang::rep_along(vec_cat, barColNeg)
	}

	#300. Prepare the internal data frame to pre-process the charting options
	df_chart <- data.frame(.ech.cat = as.character(vec_cat), .ech.value = vec_value, stringsAsFactors = F)

	#307. Calculate the extreme values of the input data
	extreme_pos <- max(df_chart$.ech.value, na.rm = T)
	extreme_neg <- min(df_chart$.ech.value, na.rm = T)

	#310. Assign the end-point colors to respective categories
	df_chart$.ech.col <- barColPos
	df_chart$.ech.col[df_chart$.ech.value < 0] <- barColNeg[df_chart$.ech.value < 0]

	#330. Determine the display order of the bars
	if (sortBy == 'category') {
		if (direction == 'column') {
			df_chart %<>% dplyr::arrange(.ech.cat)
		} else {
			df_chart %<>% dplyr::arrange(dplyr::desc(.ech.cat))
		}
	} else if (sortBy == 'value') {
		if (direction == 'column') {
			df_chart %<>% dplyr::arrange(dplyr::desc(.ech.value))
		} else {
			df_chart %<>% dplyr::arrange(.ech.value)
		}
	}

	#350. Calculate the quantile of each value by regarding the extreme values as <k_colors>
	df_chart$.tiles <- NA
	df_chart$.tiles[!(df_chart$.ech.value < 0)] <- round(scales::rescale(
		df_chart$.ech.value[!(df_chart$.ech.value < 0)]
		, to = c(1,k_colors)
		, from = c(0,extreme_pos)
	))
	df_chart$.tiles[df_chart$.ech.value < 0] <- round(scales::rescale(
		df_chart$.ech.value[df_chart$.ech.value < 0]
		, to = c(1,k_colors)
		, from = c(0,extreme_neg)
	))

	#400. Override the colors when required
	#410. Define JS helper functions
	#How to rescale array from range [in_min, in_max] to the range [out_min, out_max]
	#Quote: https://stackoverflow.com/questions/60673602
	js_rescale <- paste0(''
		,'function(num, in_min, in_max, out_min, out_max){'
			,'return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;'
		,'}'
	)

	#430. Determine the gradient when [direction] is different
	#Quote: (0,1,0,0) => (right, bottom, left , top)
	if (direction == 'column') {
		dir_grad <- '0,1,0,0'
	} else {
		dir_grad <- '0,0,1,0'
	}

	#450. Helper function to generate JS statements
	js_formatter <- function(
		col_ramp_pos
		,col_ramp_neg
		,k_stops
		,rescale = js_rescale
		,col_ramp_dim0 = ''
	){
		paste0(''
			,'function(params){'
				#001. Parse the current data point
				,'var val_curr = parseFloat(params.value[',val_axis,']);'

				#009. Return nothing if current data point is equal to 0
				#Quote: https://blog.csdn.net/m0_48459838/article/details/113800137
				,'if ((val_curr == 0) || isNaN(val_curr) || (!isFinite(val_curr))) {'
					,'return;'
				,'};'

				#100. Define helper function
				,'var rescale = ',rescale,';'

				#300. Define local arrays
				#310. Color ramps
				,'var col_ramp_pos = ',col_ramp_pos,';'
				,'var col_ramp_neg = ',col_ramp_neg,';'

				#330. Color stops
				,k_stops
				,'var col_stop = new Array(k_stops);'
				,'for(var i=0; i<col_stop.length; i++){col_stop[i] = i + 1;};'
				,'col_stop = col_stop.map(num=>rescale(num, 1, k_stops, 0, 1));'

				#500. Create array of objects that can be referenced by <echarts.graphic.LinearGradient()>
				#Quote: 柱状图柱体颜色渐变（每个柱体不同渐变色）
				#Quote: https://blog.csdn.net/baidu_41327283/article/details/100114760
				,'var col_ramp = [];'
				,'if (val_curr < 0) {'
					,'col_ramp = col_ramp_neg;'
				,'} else {'
					,'col_ramp = col_ramp_pos;'
				,'};'
				,'var arr_stop = col_stop.map(function(v,i,arr){'
					,'return {offset:v, color:col_ramp',col_ramp_dim0,'[i]};'
				,'});'

				#900. Set the color for current data point
				,'return new echarts.graphic.LinearGradient(',dir_grad,',arr_stop,false);'
			,'}'
		)
	}

	#490. Prepare the color formatters
	if (gradient == 'all') {
		#100. Retrieve the color for the maximum value in the data
		col_base_pos <- df_chart$.ech.col[df_chart$.ech.value == max(df_chart$.ech.value, na.rm = T)]
		col_base_neg <- df_chart$.ech.col[df_chart$.ech.value == min(df_chart$.ech.value, na.rm = T)]

		#500. Create the colors based on the interpolation
		#Gradient: closer to the bg-color -> closer to the requested color
		col_grad_pos <- rgba2rgb(col_base_pos, alpha_in = alpha_interp, color_bg = col_bg)
		col_grad_neg <- rgba2rgb(col_base_neg, alpha_in = alpha_interp, color_bg = col_bg) %>% rev()

		#700. Prepare the JS function for <echarts:formatter>
		col_formatter <- js_formatter(
			jsonlite::toJSON(col_grad_pos, auto_unbox = T) %>% {gsub('"','\'',.)}
			,jsonlite::toJSON(col_grad_neg, auto_unbox = T) %>% {gsub('"','\'',.)}
			,paste0(''
				,'var col_tile = [',paste0(df_chart$.tiles, collapse = ','),'];'
				,'var k_stops = col_tile[params.dataIndex];'
			)
			,col_ramp_dim0 = ''
		)
		em_formatter <- list(
			itemStyle = list(
				color = htmlwidgets::JS(
					js_formatter(
						jsonlite::toJSON(col_grad_pos %>% rev(), auto_unbox = T) %>% {gsub('"','\'',.)}
						,jsonlite::toJSON(col_grad_neg %>% rev(), auto_unbox = T) %>% {gsub('"','\'',.)}
						,paste0(''
							,'var col_tile = [',paste0(df_chart$.tiles, collapse = ','),'];'
							,'var k_stops = col_tile[params.dataIndex];'
						)
						,col_ramp_dim0 = ''
					)
				)
			)
		)
	} else if (gradient == 'respective') {
		#500. Create the colors based on the interpolation
		#Gradient: closer to the bg-color -> closer to the requested color
		col_grad_pos <- lapply(df_chart$.ech.col, rgba2rgb, alpha_in = alpha_interp, color_bg = col_bg)
		col_grad_neg <- col_grad_pos %>% lapply(rev)

		#700. Prepare the JS function for <echarts:formatter>
		col_formatter <- js_formatter(
			jsonlite::toJSON(col_grad_pos, auto_unbox = T) %>% {gsub('"','\'',.)}
			,jsonlite::toJSON(col_grad_neg, auto_unbox = T) %>% {gsub('"','\'',.)}
			,paste0(''
				,'var k_stops = ',k_colors,';'
			)
			,col_ramp_dim0 = '[params.dataIndex]'
		)
		em_formatter <- list(
			itemStyle = list(
				color = htmlwidgets::JS(
					js_formatter(
						jsonlite::toJSON(col_grad_pos %>% lapply(rev), auto_unbox = T) %>% {gsub('"','\'',.)}
						,jsonlite::toJSON(col_grad_neg %>% lapply(rev), auto_unbox = T) %>% {gsub('"','\'',.)}
						,paste0(''
							,'var k_stops = ',k_colors,';'
						)
						,col_ramp_dim0 = '[params.dataIndex]'
					)
				)
			)
		)
	} else {
		col_formatter <- paste0(''
			,'function(params){'
				#300. Define local arrays
				#350. Color choices
				,'var col_choice = ',jsonlite::toJSON(df_chart$.ech.col, auto_unbox = T) %>% {gsub('"','\'',.)},';'

				#900. Set the color for current data point
				,'return col_choice[params.dataIndex];'
			,'}'
		)
		em_formatter <- list()
	}

	#500. Create the charting script
	ch_html <- eval(rlang::expr(
		df_chart %>%
		#[IMPORTANT] It is tested that the size of [canvas] is unexpected if we set [width] or [height] for [e_charts]
		echarts4r::e_charts(.ech.cat, elementId = html_id) %>%
		echarts4r::e_grid(
			index = 0
			, top = 40, right = 8, bottom = 40, left = 8
			, height = height - 48, width = width - 16
			, containLabel = TRUE
		) %>%
		#300. Draw the chart
		echarts4r::e_bar(
			.ech.value
			,x_index = 0
			,y_index = 0
			,stack = stack
			,name = disp_name
			,barWidth = barWidth
			,legend = list(
				show = FALSE
			)
			,label = list(
				show = FALSE
				# ,position = 'top'
				,fontFamily = fontFamily
				,fontSize = fontSize_ech
				,borderWidth = 0
				,color = coltheme[['color']][['header']]
			)
			,itemStyle = list(
				borderWidth = 0
				#We must use [htmlwidgets::JS()] to embrace the character string for it to take effect, when [as.tooltip=FALSE]
				,color = htmlwidgets::JS(col_formatter)
			)
			,emphasis = list(
				label = list(
					show = FALSE
				)
				# ,!!!em_formatter
				# ,itemStyle = list(
				# 	color = 'auto'
				# )
			)
		) %>%
		#400. Setup the axes
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,type = 'category'
			,data = df_chart$.ech.cat
			,axisLabel = list(
				fontFamily = fontFamily
				,fontSize = fontSize_ech
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
				show = FALSE
				,triggerTooltip = FALSE
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
				show = FALSE
				,triggerTooltip = FALSE
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
				show = FALSE
			)
			,!!!tooltip_bar
		)
	))

	#509. Conduct program injection
	ch_html %<>% func_add()

	#520. Flip the coordinates
	if (direction == 'bar') {
		ch_html %<>%
			echarts4r::e_flip_coords()
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
	ech_obj_name <- paste0('ttBar_', gsub('\\W', '_', vfy_html_id))
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
			dplyr::mutate(col_period = ifelse(period == 3, '#FF0000', uRV$coltheme[['color']][['default']])) %>%
			dplyr::group_by(opponent, period) %>%
			dplyr::summarise(
				points = sum(points, na.rm = T)
				,col_period = dplyr::first(col_period)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(points = ifelse(period==2, -points, points)) %>%
			dplyr::group_by(opponent) %>%
			dplyr::summarise(
				score = sum(points, na.rm = T)
				,ech_bar = echarts4r_vec_bar(
					points
					,vec_cat = period
					,sortBy = 'input'
					#20220413 It is tested that if we manually set [html_id], the chart may not display when hovering over,
					#          hence we should never (or under certain condition?) set it
					# ,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
					,barColPos = col_period
					,gradient = TRUE
					# ,direction = 'bar'
					,disp_name = 'Total Score'
					,title = 'Distribution by Period'
					,theme = uRV$theme
					# ,jsFmtFloat = 'toFixed(4)'
					,as.tooltip = TRUE
				)
				,ech_bar2 = echarts4r_vec_bar(
					points
					,vec_cat = period
					,sortBy = 'input'
					#20220413 It is tested that if we manually set [html_id], the chart may not display when hovering over,
					#          hence we should never (or under certain condition?) set it
					# ,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
					,barColPos = col_period
					,gradient = 'respective'
					# ,direction = 'bar'
					,disp_name = 'Total Score'
					,title = 'Distribution by Period'
					,theme = uRV$theme
					# ,jsFmtFloat = 'toFixed(4)'
					,as.tooltip = FALSE
				)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				score_text = echarts4r_vec_text(
					score
					,width = 64
					,theme = uRV$theme
					,fmtTooltip = ech_bar
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('opponent', 'score', 'score_text', 'ech_bar2')
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
