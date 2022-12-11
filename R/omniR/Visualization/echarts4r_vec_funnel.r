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
#   |[01] https://echarts.apache.org/zh/option.html#series-funnel                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This can be useful if one needs to render charts within [DT::datatable]                                                        #
#   |[2] Draw charts for groups of keys split into several categories, such as conversion rates along a customer usage path             #
#   |[3] Draw charts within [echarts:tooltip] for another vectorized chart series                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec_cat     :   Vector by which to display the funnel                                                                              #
#   |vec_value   :   Numeric vector in the same length as [vec_cat] to be used as [values] to draw the charts                           #
#   |vec_valuecol:   Character vector as the CSS color to differ [vec_value] in current chart                                           #
#   |                 [NULL        ] <Default> Use the default colors from the default theme                                            #
#   |                 [<vec>       ]           Character vector in the same length as [vec_cat] representing color codes, to differ the #
#   |                                           colors one-by-one                                                                       #
#   |name_value  :   Name of [vec_value] on the labels and tooltips                                                                     #
#   |                 [Actual      ] <Default> Use this name for display                                                                #
#   |vec_base    :   Numeric vector to be used as the comparison base to [vec_value] to draw the charts                                 #
#   |                 [NULL        ] <Default> Do not create comparison                                                                 #
#   |vec_basecol :   Character vector as the CSS color to differ [vec_base] in current chart                                            #
#   |                 [NULL        ] <Default> Use the default colors from the default theme with certain opacity                       #
#   |                 [<vec>       ]           Character vector in the same length as [vec_cat] representing color codes, to differ the #
#   |                                           colors one-by-one                                                                       #
#   |name_base   :   Name of [vec_base] on the labels and tooltips                                                                      #
#   |                 [Expected    ] <Default> Use this name for display                                                                #
#   |gradient    :   Whether to draw the chart with gradient color effect                                                               #
#   |                 [TRUE        ] <Default> Draw the chart with gradient color effect                                                #
#   |                 [FALSE       ]           Draw the bar with the provided color [vec_valuecol] and/or [vec_basecol]                 #
#   |sortBy      :   Character vector to determine how to display the category sequence in specific order                               #
#   |                 [input       ] <Default> The order follows the input sequence of [vec_cat]                                        #
#   |                 [category    ]           Function sorts the input data by [vec_cat] in [sort] order and then draw the chart       #
#   |                 [value       ]           Function sorts the input data by [vec_value] in [sort] order and then draw the chart     #
#   |                 [base        ]           Function sorts the input data by [vec_base] in [sort] order and then draw the chart      #
#   |sort        :   Character vector to determine the sorting method over [sortBy], ignored when [sortBy==input]                       #
#   |                 [descending  ] <Default> Function sorts [sortBy] in descending order and then draw the chart                      #
#   |                 [ascending   ]           Function sorts [sortBy] in ascending order and then draw the chart                       #
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |height      :   Integer of the chart height                                                                                        #
#   |                 [540         ] <Default>                                                                                          #
#   |width       :   Integer of the chart width                                                                                         #
#   |                 [960         ] <Default>                                                                                          #
#   |orient      :   On which orient to display the funnel                                                                              #
#   |                 [vertical    ] <Default> See: https://echarts.apache.org/zh/option.html#series-funnel.orient                      #
#   |                 [horizontal  ]           See: https://echarts.apache.org/zh/option.html#series-funnel.orient                      #
#   |label_show  :   Whether to always show the label of [vec_cat]                                                                      #
#   |                [IMPORTANT] It is tested that the function definition resolves the arguments in a delayed manner, hence we can     #
#   |                             refer to any subprocesses in the function definition which are defined within this function.          #
#   |                 [FALSE       ] <Default> Do not show the labels                                                                   #
#   |                 [TRUE        ]           Always show the labels of [vec_cat]                                                      #
#   |label_pos   :   Character value that indicates the position of the labels                                                          #
#   |                 [outside     ] <Default> See: https://echarts.apache.org/zh/option.html#series-funnel.label.position              #
#   |title       :   Character as the title of current chart, taking the first value if the vector contains multiple values             #
#   |                 [Funnel      ] <Default> Name all charts with this one                                                            #
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
#   |fmtLbl_value:   Character as the formatter to tweak the [label] of [vec_value] in current chart                                    #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |fmtLbl_base :   Character as the formatter to tweak the [label] of [vec_base] in current chart                                     #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |fmtEmp_value:   Character as the formatter to tweak the [tooltip] of [vec_value] in current chart                                  #
#   |                 [NULL        ] <Default> Use the default [formatter], see function definition                                     #
#   |fmtEmp_base :   Character as the formatter to tweak the [tooltip] of [vec_base] in current chart                                   #
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
#   | Date |    20221210        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, echarts4r, jsonlite, htmlwidgets, htmltools, dplyr, rlang, stringr                                                   #
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
	magrittr, echarts4r, jsonlite, htmlwidgets, htmltools, dplyr, rlang, stringr
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

echarts4r_vec_funnel <- function(
	vec_cat
	,vec_value
	,vec_valuecol = NULL
	,name_value = 'Actual'
	,vec_base = NULL
	,vec_basecol = NULL
	,name_base = 'Expected'
	,gradient = TRUE
	,sortBy = c('input','category','value','base')
	,sort = c('descending','ascending')
	,html_id = NULL
	,height = 440
	,width = 640
	,orient = 'vertical'
	,label_show = FALSE
	,label_pos = 'outside'
	,title = 'Funnel'
	,titleSize = 18
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = TRUE
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	#Quote: https://blog.csdn.net/hjb2722404/article/details/110915893
	,jsFmtFloat = 'toLocaleString(\'en-US\', {style:\'percent\', minimumFractionDigits:2, maximumFractionDigits:2})'
	,fmtLbl_value = NULL
	,fmtLbl_base = NULL
	,fmtEmp_value = NULL
	,fmtEmp_base = NULL
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
	sortBy <- match.arg(sortBy)
	sort <- match.arg(sort)
	fontSize_css <- htmltools::validateCssUnit(fontSize)
	fontSize_ech <- fontSize_css %>% {gsub('^(((\\d+)?\\.)?\\d+).*$','\\1', .)} %>% as.numeric()

	#012. Handle the parameter buffer
	if (length(vec_value) != length(vec_cat)) {
		stop('[',LfuncName,'][vec_value] has different length [',length(vec_value),'] to [vec_cat] as [',length(vec_cat),']!')
	}
	if ((length(vec_value) == 0) | (length(vec_cat) == 0)) return(character(0))
	if (!is.null(vec_valuecol)) {
		if (length(vec_valuecol) != length(vec_cat)) {
			stop('[',LfuncName,'][vec_valuecol] has different length [',length(vec_valuecol),'] to [vec_cat] as [',length(vec_cat),']!')
		}
	}
	if (!is.null(vec_base)) {
		if (length(vec_base) != length(vec_cat)) {
			stop('[',LfuncName,'][vec_base] has different length [',length(vec_base),'] to [vec_cat] as [',length(vec_cat),']!')
		}
	}
	if (!is.null(vec_basecol)) {
		if (length(vec_basecol) != length(vec_cat)) {
			stop('[',LfuncName,'][vec_basecol] has different length [',length(vec_basecol),'] to [vec_cat] as [',length(vec_cat),']!')
		}
	}
	if (sortBy == 'base') {
		if (is.null(vec_base)) {
			stop('[',LfuncName,'][vec_base] is not provided for [sortBy] as [',sortBy,']!')
		}
	}

	#015. Function local variables
	len_data <- length(vec_value)
	k_grad <- 10
	#How to rescale array from range [in_min, in_max] to the range [out_min, out_max]
	#Quote: https://stackoverflow.com/questions/60673602
	js_rescale <- paste0(''
		,'function(num, in_min, in_max, out_min, out_max){'
			,'return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;'
		,'}'
	)
	#Quote: https://blog.csdn.net/weixin_33726318/article/details/94726577
	js_proto_toPct <- paste0(''
		,'Number.prototype.toPercent = function(kFrac){'
			,'return (Math.round(this * 10000)/100).toFixed(kFrac) + \'%\';'
		,'};'
	)
	if (sort == 'descending') {
		fn_sort <- dplyr::desc
	} else {
		fn_sort <- dplyr::asc
	}
	#Determine the gradient when [orient] is different
	#Quote: (0,1,0,0) => (right, bottom, left , top)
	if (orient == 'vertical') {
		dir_grad <- '0,0,0,1'
	} else {
		dir_grad <- '0,0,1,0'
	}

	#100. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = transparent)
	tt_theme <- themeColors(theme, transparent = F)

	#200. Helper functions
	#210. Function to calculate the color ramp on vectorized basis
	fn_colramp <- function(v_bgn,v_end,a_bgn,a_end,k = k_grad) {
		v_alphas <- seq(a_bgn,a_end,length.out = k)
		v_col <- rgba2rgb(v_bgn, alpha_in = v_alphas, color_bg = v_end)
		return(jsonlite::toJSON(v_col, auto_unbox = T) %>% {gsub('"','\'',.)})
	}

	#250. Function to generate color formatter
	js_col_fmt <- function(
		col_ramp
		,k_stops = k_grad
		,rescale = js_rescale
		,direction = dir_grad
	){
		paste0(''
			,'function(params){'
				#001. Parse the current data point
				,'var val_curr = parseFloat(params.value);'

				#009. Return nothing if current data point is equal to 0
				#Quote: https://blog.csdn.net/m0_48459838/article/details/113800137
				,'if ((val_curr == 0) || isNaN(val_curr) || (!isFinite(val_curr))) {'
					,'return;'
				,'};'

				#100. Define helper function
				,'var rescale = ',rescale,';'

				#300. Define local arrays
				#310. Color ramps
				,'var col_ramp = ',col_ramp,'[params.dataIndex];'

				#330. Color stops
				,'var k_stops = ',k_stops,';'
				#Quote: https://www.techiedelight.com/create-array-from-1-n-javascript/
				,'var col_stop = Array.from({length: k_stops}, (_, index) => index + 1);'
				,'col_stop = col_stop.map(num=>rescale(num, 1, k_stops, 0, 1));'

				#500. Create array of objects that can be referenced by <echarts.graphic.LinearGradient()>
				#Quote: 柱状图柱体颜色渐变（每个柱体不同渐变色）
				#Quote: https://blog.csdn.net/baidu_41327283/article/details/100114760
				,'var arr_stop = col_stop.map(function(v,i,arr){'
					,'return {offset:v, color:col_ramp[i]};'
				,'});'

				#900. Set the color for current data point
				,'return new echarts.graphic.LinearGradient(',dir_grad,',arr_stop,false);'
			,'}'
		)
	}

	#300. Setup styles
	#310. Create the styles of [tooltip] for this specific chart
	opt_tooltip <- list(
		trigger = 'item'
		,confine = TRUE
		,appendToBody = TRUE
		,enterable = FALSE
		,textStyle = list(
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

	#330. Format the label for current chart
	opt_lbl <- list(
		show = label_show
		,fontFamily = fontFamily
		,fontSize = fontSize_ech
		,color = coltheme[['color']][['default']]
		,borderWidth = 0
		,textBorderWidth = 0
	)
	if (length(fmtLbl_value) > 0) {
		fmt_value <- modifyList(opt_lbl, list(formatter = htmlwidgets::JS(fmtLbl_value)))
	} else {
		fmt_value <- modifyList(
			opt_lbl
			,list(
				formatter = htmlwidgets::JS(paste0(''
					,'function(params){'
						,'return('
							,'parseFloat(params.value).',jsFmtFloat
						,');'
					,'}'
				))
				,position = 'inside'
				,backgroundColor = tt_theme[['background-color']][['tooltip-inverse']]
			)
		)
	}
	if (length(fmtLbl_base) > 0) {
		fmt_base <- modifyList(opt_lbl, list(formatter = htmlwidgets::JS(fmtLbl_base)))
	} else {
		fmt_base <- modifyList(
			opt_lbl
			,list(
				formatter = htmlwidgets::JS(paste0(''
					,'function(params){'
						,'return('
							,'params.name + \': \' + parseFloat(params.value).',jsFmtFloat
						,');'
					,'}'
				))
				,position = label_pos
			)
		)
	}

	#350. Format the tooltip for current chart
	if (length(fmtEmp_value) > 0) {
		tooltip_value <- fmtEmp_value
	} else {
		tooltip_value <- paste0(''
			,'function(params){'
				,'return('
					#Quote: https://www.tutorialspoint.com/how-to-convert-a-value-to-a-string-in-javascript
					,'\'<strong>\' + String(params.name) + \'</strong>\''
					,'+ \'<br/>\' + \'',name_value,'\''
					,'+ \'<br/>\' + parseFloat(params.value).',jsFmtFloat
				,');'
			,'}'
		)
	}
	if (length(fmtEmp_base) > 0) {
		tooltip_base <- fmtEmp_base
	} else {
		tooltip_base <- paste0(''
			,'function(params){'
				,'return('
					,'\'<strong>\' + String(params.name) + \'</strong>\''
					,'+ \'<br/>\' + \'',name_base,'\''
					,'+ \'<br/>\' + parseFloat(params.value).',jsFmtFloat
				,');'
			,'}'
		)
	}

	#400. Prepare the internal data frame to pre-process the charting options
	#401. Prepare the entire data frame to ensure the ordering of vectors is simultaneous
	df_chart <- data.frame(.ech.cat = vec_cat, .ech.value = vec_value)
	if (length(vec_base) != 0) {
		df_chart$.ech.base <- vec_base
	} else {
		df_chart$.ech.base <- vec_value
	}
	if (length(vec_valuecol) == 0) {
		df_chart$.ech.value.col.bgn <- coltheme[['color']][['default']]
	} else {
		df_chart$.ech.value.col.bgn <- vec_valuecol
	}
	if (length(vec_basecol) == 0) {
		df_chart$.ech.base.col.bgn <- df_chart$.ech.value.col.bgn
	} else {
		df_chart$.ech.base.col.bgn <- vec_basecol
	}

	#410. Determine the display order of the chart
	if (sortBy == 'category') {
		df_chart %<>% dplyr::arrange(fn_sort(.ech.cat))
	} else if (sortBy == 'value') {
		df_chart %<>% dplyr::arrange(fn_sort(.ech.value))
	} else if (sortBy == 'base') {
		df_chart %<>% dplyr::arrange(fn_sort(.ech.base))
	}
	df_chart$.ech.seq <- seq_len(len_data)

	#470. Prepare default colors based on current theme
	#Since the data is to focus on [vec_value], we determine the default colors only for it
	k_alpha <- len_data + 1
	alphas <- seq(0.1,1,length.out = k_alpha)
	def_colors <- df_chart %>%
		dplyr::arrange(.ech.value, .ech.seq) %>%
		dplyr::mutate(
			alpha_bgn = alphas[-1]
		) %>%
		dplyr::arrange(.ech.seq) %>%
		dplyr::mutate(
			alpha_end = dplyr::lead(alpha_bgn, default = alphas[1])
		)

	#480. Determine the end colors of the items
	if (gradient) {
		#100. Color for [vec_value]
		if (length(vec_valuecol) == 0) {
			df_chart$.ech.value.col.ramp <- mapply(
				fn_colramp
				,df_chart$.ech.value.col.bgn
				,coltheme[['background-color']][['default']]
				,def_colors$alpha_bgn
				,def_colors$alpha_end
			)
		} else {
			df_chart %<>%
				dplyr::mutate(
					alpha_bgn = 1
					,alpha_end = c(rep_len(0,len_data - 1), 0.1)
					,.ech.value.col.end = dplyr::lead(.ech.value.col.bgn, default = coltheme[['background-color']][['default']])
				) %>%
				dplyr::mutate(
					.ech.value.col.ramp = mapply(
						fn_colramp
						,.ech.value.col.bgn
						,.ech.value.col.end
						,alpha_bgn
						,alpha_end
					)
				)
		}

		#500. Color for [vec_base]
		if (length(vec_basecol) == 0) {
			df_chart$.ech.base.col.ramp <- mapply(
				fn_colramp
				,df_chart$.ech.base.col.bgn
				,coltheme[['background-color']][['default']]
				,def_colors$alpha_bgn
				,def_colors$alpha_end
			)
		} else {
			df_chart %<>%
				dplyr::mutate(
					alpha_bgn = 1
					,alpha_end = c(rep_len(0,len_data - 1), 0.1)
					,.ech.base.col.end = dplyr::lead(.ech.base.col.bgn, default = coltheme[['background-color']][['default']])
				) %>%
				dplyr::mutate(
					.ech.base.col.ramp = mapply(
						fn_colramp
						,.ech.base.col.bgn
						,.ech.base.col.end
						,alpha_bgn
						,alpha_end
					)
				)
		}
	} else {
		#100. Color for [vec_value]
		if (length(vec_valuecol) == 0) {
			df_chart$.ech.value.col.ramp <- mapply(
				fn_colramp
				,df_chart$.ech.value.col.bgn
				,coltheme[['background-color']][['default']]
				,def_colors$alpha_bgn
				,def_colors$alpha_bgn
			)
		} else {
			df_chart$.ech.value.col.ramp <- mapply(
				fn_colramp
				,df_chart$.ech.value.col.bgn
				,coltheme[['background-color']][['default']]
				,1
				,1
			)
		}

		#500. Color for [vec_base]
		if (length(vec_basecol) == 0) {
			df_chart$.ech.base.col.ramp <- mapply(
				fn_colramp
				,df_chart$.ech.base.col.bgn
				,coltheme[['background-color']][['default']]
				,def_colors$alpha_bgn
				,def_colors$alpha_bgn
			)
		} else {
			df_chart$.ech.base.col.ramp <- mapply(
				fn_colramp
				,df_chart$.ech.base.col.bgn
				,coltheme[['background-color']][['default']]
				,1
				,1
			)
		}
	}

	#500. Override the colors when required
	#510. Determine the background color for interpolation
	if (as.tooltip) {
		col_bg <- coltheme[['background-color']][['tooltip']]
	} else {
		col_bg <- coltheme[['background-color']][['default']]
	}

	#600. Create the charting script
	#610. Calculate the parameter [maxSize]
	if (max(df_chart$.ech.value) < max(df_chart$.ech.base)) {
		column_max <- '.ech.base'
		column_min <- '.ech.value'
	} else {
		column_max <- '.ech.value'
		column_min <- '.ech.base'
	}
	val_max <- df_chart %>% dplyr::filter_at(column_max, ~. == max(.)) %>% dplyr::pull(column_max)
	val_min <- df_chart %>% dplyr::filter_at(column_min, ~. == max(.)) %>% dplyr::pull(column_min)
	act_size <- val_min / val_max
	if (max(df_chart$.ech.value) < max(df_chart$.ech.base)) {
		size_value <- paste0(floor(act_size * 100), '%')
		size_base <- '100%'
	} else {
		size_base <- paste0(floor(act_size * 100), '%')
		size_value <- '100%'
	}

	#650. Create the options
	#[ASSUMPTION]
	#[1] For [echarts4r<=0.4.3], [e_funnel] cannot produce a chart with 2 or more value vectors
	#[2] In the same version, [echarts.series.funnel.label] cannot be applied to [e_funnel]
	#[3] Hence we should leverage the direct patch [e_list] on the grid
	df_value <- df_chart %>% dplyr::select(c('.ech.cat','.ech.value'))
	names(df_value) <- c('name','value')
	df_base <- df_chart %>% dplyr::select(c('.ech.cat','.ech.base'))
	names(df_base) <- c('name','value')
	srs_opt <- list(
		list(
			name = name_value
			,type = 'funnel'
			,data = jsonlite::toJSON(df_value)
			,maxSize = size_value
			,sort = 'none'
			,orient = orient
			,itemStyle = list(
				color = htmlwidgets::JS(js_col_fmt(
					paste0('[',paste0(df_chart$.ech.value.col.ramp, collapse = ','),']')
				))
				,borderColor = coltheme[['background-color']][['stripe']]
				,borderWidth = 0.5
			)
			,label = fmt_value
			,emphasis = list(
				focus = 'self'
				,label = list(
					show = label_show
				)
			)
			,tooltip = list(
				formatter = htmlwidgets::JS(tooltip_value)
			)
			,z = 100
		)
	)
	if (length(vec_base) != 0) {
		srs_opt <- c(
			srs_opt
			,list(
				list(
					name = name_base
					,type = 'funnel'
					,data = jsonlite::toJSON(df_base)
					,sort = 'none'
					,orient = orient
					,itemStyle = list(
						color = htmlwidgets::JS(js_col_fmt(
							paste0('[',paste0(df_chart$.ech.value.col.ramp, collapse = ','),']')
						))
						,borderColor = coltheme[['background-color']][['stripe']]
						,borderWidth = 0.5
						,opacity = 0.7
					)
					,label = fmt_base
					,labelLine = list(
						lineStyle = list(
							color = coltheme[['color']][['chart-line']]
						)
					)
					,emphasis = list(
						focus = 'self'
						,label = list(
							show = label_show
						)
						,labelLine = list(
							lineStyle = list(
								color = coltheme[['color']][['chart-line']]
							)
						)
					)
					,tooltip = list(
						formatter = htmlwidgets::JS(tooltip_base)
					)
				)
			)
		)
	}
	opts_ech <- list(
		title = list(
			text = title
			,textStyle = list(
				fontFamily = fontFamily
				,fontSize = titleSize
				,color = coltheme[['color']][['default']]
			)
		)
		,tooltip = opt_tooltip
		,series = srs_opt
	)

	ch_html <- eval(rlang::expr(
		#[IMPORTANT] It is tested that the size of [canvas] is unexpected if we set [width] or [height] for [e_charts]
		echarts4r::e_charts(elementId = html_id) %>%
		echarts4r::e_grid(
			index = 0
			, top = 0, right = 0, bottom = 0, left = 0
			, height = height - 24, width = width - 16
			, containLabel = TRUE
		) %>%
		#800. Extra configurations
		#820. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#300. Draw the chart
		echarts4r::e_list(opts_ech)
	))

	#680. Convert the htmlwiget into character vector
	#681. Conversion
	ch_html %<>%
		#900. Convert to character vector
		as.character.htmlwidget()

	#683. Search for the HTML ID
	vfy_html_id <- stringr::str_extract_all(ch_html, '(?<=<div\\sid=("|\'))(.+?)(?=\\1)')[[1]][[1]]

	#689. Overwrite the original rect
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

	#690. Directly return if no need to convert it to tooltip
	if (!as.tooltip) return(ch_html)

	#800. Function as container for creating the tooltip out of current chart
	#[IMPORTANT]
	#[1] We must set the <echarts> object names BEFORE the definition of the container, as they are referenced inside the container
	#[2] Program will automatically search for the variable by stacks, hence there is no need to worry about the environment nesting
	ech_obj_name <- paste0('ttFunnel_', gsub('\\W', '_', vfy_html_id))
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
		ch_funnel <- data.frame(
			channels = rep(c('C1','C2','C3'), each = 5)
			,ch_names = rep(c('Channel1','Channel2','Channel3'), each = 5)
			,stage = rep.int(c('Show', 'Click', 'Visit', 'Inquiry', 'Order'), 3)
			,AUM = runif(15, max = 5000000)
			,expected = sample(c(100, 40, 20, 60, 80), size = 15, replace = T) / 100
		) %>%
			dplyr::mutate(
				actual = runif(length(expected), max = expected * 1.2)
			) %>%
			dplyr::group_by(channels) %>%
			dplyr::summarise(
				AUM = sum(AUM)
				,ech_funnel = echarts4r_vec_funnel(
					stage
					,vec_value = actual
					,vec_base = expected
					,sortBy = 'input'
					,sort = 'descending'
					,label_show = TRUE
					#20220413 It is tested that if we manually set [html_id], the chart may not display when hovering over,
					#          hence we should never (or under certain condition?) set it
					# ,html_id = paste0('test_tt_', dplyr::last(dplyr::row_number()))
					,title = 'Funnel by Channel'
					,theme = uRV$theme
					,as.tooltip = TRUE
				)
				,ech_funnel2 = echarts4r_vec_funnel(
					stage
					,vec_value = actual
					,vec_valuecol = c('#dd6b66','#759aa0','#e69d87','#8dc1a9','#ea7e53')
					,vec_base = expected
					,sortBy = 'input'
					,sort = 'descending'
					,orient = 'horizontal'
					# ,gradient = F
					,title = 'Funnel by Channel'
					,theme = uRV$theme
					,as.tooltip = FALSE
				)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				score_text = echarts4r_vec_text(
					AUM
					,width = 64
					,theme = uRV$theme
					,fmtTooltip = ech_funnel
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('channels', 'AUM', 'score_text', 'ech_funnel2')
		dt_funnel <- DT::datatable(
			ch_funnel %>% dplyr::select(tidyselect::all_of(cols))
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
		div_funnel <- shiny::fluidRow(
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
					,dt_funnel
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
						,dt_funnel
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}
}
