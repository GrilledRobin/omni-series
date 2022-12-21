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
#   |html_id     :   Character vector of the html [id]s of each chart widget respectively, for reactive programming purpose             #
#   |                 [NULL        ] <Default> Chart ID will be generated randomly by [echarts4r]                                       #
#   |height      :   Integer of the chart height                                                                                        #
#   |                 [540         ] <Default>                                                                                          #
#   |width       :   Integer of the chart width                                                                                         #
#   |                 [960         ] <Default>                                                                                          #
#   |barWidth    :   Value of the bar width, can be integer or percentage; only the first is taken if multiple values are provided      #
#   |                Quote: https://echarts.apache.org/zh/option.html#series-bar.barWidth                                               #
#   |                 [NULL        ] <Default> Adaptive to the chart                                                                    #
#   |                 [<int>       ]           Absolute pixels as width                                                                 #
#   |                 [<chr>       ]           Character string as percent, representing the proportion of automatic width              #
#   |barColor    :   Character as the CSS color of the bars in current chart (there is no negative frequency count for histogram)       #
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
#   |breaks      :   Method to bin the input data, see official document for <hist>                                                     #
#   |                 [Sturges     ] <Default> see official document for <hist>                                                         #
#   |include.lowest                                                                                                                     #
#   |            :   Whether to include the lowest value for the first or last break, see official document for <hist>                  #
#   |                 [TRUE        ] <Default> see official document for <hist>                                                         #
#   |                 [FALSE       ]           see official document for <hist>                                                         #
#   |right       :   Whether to draw the histogram with right-closed intervals, see official document for <hist>                        #
#   |                 [TRUE        ] <Default> see official document for <hist>                                                         #
#   |                 [FALSE       ]           see official document for <hist>                                                         #
#   |density     :   Whether to add a density curve for the histogram                                                                   #
#   |                 [FALSE       ] <Default> Only draw the chart with columns                                                         #
#   |                 [TRUE        ]           Add a density curve to the column chart                                                  #
#   |lineColor   :   Character as the CSS color of the density curve in current chart                                                   #
#   |                 [NULL        ] <Default> Use the default color from the default theme                                             #
#   |                 [rgba()      ]           Can be provided in CSS syntax                                                            #
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
#   |jsFmtFreq   :   Character vector of the JS methods applied to JS:Float values of frequency count of each chart respectively        #
#   |                 Quote: https://www.techonthenet.com/js/number_tolocalestring.php                                                  #
#   |                 [<see def.>  ] <Default> Format all values into numbers with fixed decimals as 0, separated by comma              #
#   |jsFmtDens   :   Character vector of the JS methods applied to JS:Float values of density of each chart respectively                #
#   |                 Quote: https://www.techonthenet.com/js/number_tolocalestring.php                                                  #
#   |                 [<see def.>  ] <Default> Format all values into numbers with fixed decimals as 6, separated by comma if any       #
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
#   | Date |    20220418        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221117        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] It is tested that [echarts::textStyle.fontSize] cannot resolve text input, such as '14px', within the nested charts,    #
#   |      |     hence we suppress the text input from the beginning. Meanwhile, keep the parsed text [fontSize] for any CSS codes to   #
#   |      |     retain the compatibility.                                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221221        | Version | 1.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Enable multiple provision of most of the arguments (but only the first provision is accepted), to ensure more           #
#   |      |     flexibility of customization for each along the vectorized charts                                                      #
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
#   |   |magrittr, rlang, echarts4r, htmlwidgets, htmltools, purrr, jsonlite                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |themeColors                                                                                                                #
#   |   |   |alphaToHex                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |echarts4r_vec_bar                                                                                                          #
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

echarts4r_vec_hist <- function(
	vec_value
	,html_id = NULL
	,height = 440
	,width = 640
	,barWidth = NULL
	,barColor = NULL
	,gradient = TRUE
	,disp_name = 'Value'
	,breaks = 'Sturges'
	,include.lowest = TRUE
	,right = TRUE
	,density = FALSE
	,lineColor = NULL
	,title = 'Bar'
	,titleSize = 18
	,theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = TRUE
	,fontFamily = 'Microsoft YaHei'
	,fontSize = 14
	,jsFmtFloat = 'toLocaleString(\'en-US\', {minimumFractionDigits:2, maximumFractionDigits:2})'
	,jsFmtFreq = 'toLocaleString(\'en-US\', {minimumFractionDigits:0, maximumFractionDigits:0})'
	,jsFmtDens = 'toFixed(6)'
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
	if (length(vec_value) == 0) return(character(0))
	height <- head(height,1)
	width <- head(width,1)
	barWidth <- head(barWidth,1)
	barColor <- head(barColor,1)
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
	breaks <- head(breaks,1)
	density <- head(density,1)
	if (!is.logical(density)) density <- FALSE
	lineColor <- head(lineColor,1)
	title <- head(title,1)
	titleSize <- head(titleSize,1)
	theme <- head(theme,1)
	transparent <- head(transparent,1)
	fontFamily <- head(fontFamily,1)
	fontSize <- head(fontSize,1)
	jsFmtFloat <- head(jsFmtFloat,1)
	jsFmtFreq <- head(jsFmtFreq,1)
	jsFmtDens <- head(jsFmtDens,1)
	fmtTTbar <- head(fmtTTbar,1)
	if (!is.function(container)) {
		container <- head(container,1)[[1]]
	}
	fontSize_css <- htmltools::validateCssUnit(fontSize)
	fontSize_ech <- fontSize_css %>% {gsub('^(((\\d+)?\\.)?\\d+).*$','\\1', .)} %>% as.numeric()

	#015. Function local variables

	#100. Setup styles
	#110. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent = transparent)
	tt_theme <- themeColors(theme, transparent = F)
	if (length(lineColor) == 0) {
		col_histline <- coltheme[['color']][['chart-line']]
	} else {
		col_histline <- lineColor
	}

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

	#160. Determine the background color for the symbol on the line
	if (as.tooltip) {
		col_bg <- coltheme[['background-color']][['tooltip']]
	} else {
		col_bg <- coltheme[['background-color']][['default']]
	}

	#200. Calculate the attributes for a histogram
	hist_inf <- hist(vec_value, plot = FALSE, breaks = breaks, include.lowest = include.lowest, right = right)
	df_chart <- data.frame(
		mids = hist_inf$mids
		,mins = hist_inf$breaks[-length(hist_inf$breaks)]
		,maxs = hist_inf$breaks[-1]
		,counts = hist_inf$counts
		,density = hist_inf$density
		,c_mids = as.character(hist_inf$mids)
	)

	#230. Define the default formatter for tooltips
	fmt_def <- function(jsFmt, name, val_id = 1) {
		paste0(''
			,'function(params){'
				#100. Define arrays for the boundaries to be formatted
				,'var mins = ',jsonlite::toJSON(df_chart$mins, auto_unbox = T),';'
				,'var maxs = ',jsonlite::toJSON(df_chart$maxs, auto_unbox = T),';'

				#300. Create a new array to store the formatted boundaries
				,'var names = new Array(mins.length);'
				,'for(var i=0; i<mins.length; i++){'
					,'txt_min = mins[i].',jsFmtFloat,';'
					,'names[i] = \'[\' + mins[i].',jsFmtFloat,' + \'] ~ [\' + maxs[i].',jsFmtFloat,' + \']\';'
				,'};'
				,'return('
					#Quote: https://www.tutorialspoint.com/how-to-convert-a-value-to-a-string-in-javascript
					,'\'<strong>\' + ',name,' + \'</strong>\''
					,'+ \'<br/>\' + names[params.dataIndex]'
					,'+ \'<br/>\' + parseFloat(params.value[',val_id,']).',jsFmt
				,');'
			,'}'
		)
	}

	#250. Format the tooltip for current chart
	if (length(fmtTTbar) > 0) {
		tooltip_bar <- fmtTTbar
	} else {
		tooltip_bar <- fmt_def(jsFmtFreq, name = paste0('String(\'',disp_name,'\')'))
	}

	#260. Format the tooltip for density curve
	tooltip_sym = modifyList(
		tooltip
		,list(
			formatter = htmlwidgets::JS(fmt_def(jsFmtDens, name = paste0('String(\'',disp_name,'\') + \' - \' + params.seriesName')))
		)
	)

	#300. Prepare scripts to draw additional line as density curve for the injection of [echarts4r_vec_bar]
	if (!density) {
		func_line <- function(ech, df, x, y){ech}
	} else {
		func_line <- function(ech, df, x, y){
			eval(rlang::expr(
				ech %>%
					echarts4r::e_data(df, !!rlang::sym(x)) %>%
					#100. Draw a line
					echarts4r::e_line(
						!!rlang::sym(y)
						,x_index = 0
						,y_index = 1
						,name = 'density'
						,tooltip = tooltip_sym
						,symbol = 'circle'
						#If we do not set [showSymbol], the tooltip also cannot display
						,showSymbol = TRUE
						,smooth = TRUE
						,smoothMonotone = 'x'
						,itemStyle = list(
							#This color results in the same in [legend]
							color = col_bg
							,borderColor = paste0(col_histline, alphaToHex(0.5))
							,borderWidth = 1
						)
						,lineStyle = list(
							#This color is different from that in [legend]
							color = paste0(col_histline, alphaToHex(0.5))
							,width = 1
						)
					) %>%
					echarts4r::e_y_axis(
						index = 1
						,gridIndex = 0
						,type = 'value'
						,splitLine = list(
							show = FALSE
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
										,'value.',jsFmtDens
									,');'
								,'}'
							))
						)
						,axisLine = list(
							lineStyle = list(
								color = col_histline
							)
						)
						,axisTick = list(
							lineStyle = list(
								color = col_histline
							)
						)
						,minorTick = list(
							lineStyle = list(
								color = col_histline
							)
						)
						,axisPointer = list(
							show = FALSE
							,triggerTooltip = FALSE
						)
					) %>%
					#[echarts4r ver=4.3] It is weird that we MUST set a new xAxis with [id=1] to ensure the chart is correctly drawn,
					# although our line chart belongs to xAxis=0
					echarts4r::e_x_axis(
						index = 1
						,gridIndex = 0
						,type = 'category'
						,axisLabel = list(
							fontFamily = fontFamily
							,fontSize = fontSize_ech
							,hideOverlap = TRUE
						)
						,axisLine = list(
							lineStyle = list(
								color = col_histline
							)
						)
						,axisTick = list(
							lineStyle = list(
								color = col_histline
							)
						)
						,minorTick = list(
							lineStyle = list(
								color = col_histline
							)
						)
						,axisPointer = list(
							show = FALSE
							,triggerTooltip = FALSE
						)
					)
			))
		}
	}

	#500. Create the charting script
	ch_html <- echarts4r_vec_bar(
		df_chart$counts
		,df_chart$c_mids
		,y_min = NULL
		,y_max = NULL
		,sortBy = 'input'
		,html_id = html_id
		,height = height
		,width = width
		,direction = 'column'
		,barWidth = barWidth
		,barColPos = barColor
		,barColNeg = NULL
		,gradient = gradient
		,disp_name = disp_name
		,func_add = purrr::partial(func_line, df = df_chart, x = 'c_mids', y = 'density')
		,stack = 'Bar'
		,title = title
		,titleSize = titleSize
		,theme = theme
		,transparent = transparent
		,fontFamily = fontFamily
		,fontSize = fontSize_ech
		,jsFmtFloat = jsFmtFreq
		,fmtTTbar = tooltip_bar
		,as.tooltip = as.tooltip
		,container = container
		,as.parts = as.parts
	)

	#999. Return the vector
	return(ch_html)
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
		ch_iris <- iris %>%
			dplyr::group_by(Species) %>%
			dplyr::summarise(
				avg_Sepal = mean(Sepal.Length, na.rm = T)
				,ech_hist = echarts4r_vec_hist(
					Sepal.Length
					,gradient = TRUE
					# ,direction = 'bar'
					,disp_name = 'Sepal.Length'
					,density = TRUE
					,title = 'Distribution by Species'
					,theme = uRV$theme
					,as.tooltip = TRUE
				)
				,ech_hist2 = echarts4r_vec_hist(
					Sepal.Length
					,gradient = TRUE
					# ,direction = 'bar'
					,disp_name = 'Sepal.Length'
					,title = 'Distribution by Species'
					,theme = uRV$theme
					,as.tooltip = FALSE
				)
				,.groups = 'keep'
			) %>%
			dplyr::ungroup() %>%
			dplyr::mutate(
				avg_Sepal_text = echarts4r_vec_text(
					avg_Sepal
					,width = 64
					,theme = uRV$theme
					,fmtTooltip = ech_hist
				)
			)

		#200. Create a [DT::datatable]
		cols <- c('Species', 'avg_Sepal', 'avg_Sepal_text', 'ech_hist2')
		dt_iris <- DT::datatable(
			ch_iris %>% dplyr::select(tidyselect::all_of(cols))
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
		div_iris <- shiny::fluidRow(
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
					,dt_iris
				)
			)
		)

		path_rpt <- dirname(thisfile())
		rpt_tpl <- file.path(path_rpt, 'echarts4r_vec_line.Rmd')
		rpt_out <- file.path(path_rpt, 'SepalLengthDistribution.html')
		rmarkdown::render(
			rpt_tpl
			,output_file = rpt_out
			,params = list(
				dt = div_iris
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
						,dt_iris
					)
				})
			}

			shiny::shinyApp(ui, server)
		}
	}
}
