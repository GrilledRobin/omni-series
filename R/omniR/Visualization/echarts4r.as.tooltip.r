#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to Convert the [echarts4r] widget into a JS function for <echarts.tooltip.formatter>, so that this       #
#   | widget can be rendered within the tooltip of an [echarts] object inside an HTML                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Due to character manipulation, one MUST place such remarks [/*EndFunc*/] right before the end of the function definition for any   #
#   | options that support function callback, such as [formatter] and [position], inside the echarts4r widget                           #
#   |[20220215] This restriction is removed by introducing new functions, to ensure a better flexibility of programming                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[QUOTE]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Insert Echarts inside tooltips] https://blog.csdn.net/u010022260/article/details/78131554                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |widget      :   The HTML widget to be converted, currently must be either a vector of [echarts4r] widget or characters translated  #
#   |                 by [as.character.htmlwidget] from [echarts4r] widgets                                                             #
#   |                 [NULL        ] <Default> Return a character vector in the length of 0                                             #
#   |container   :   Function that takes a single argument of character vector and returns a character vector indicating a series of    #
#   |                 nested HTML tags                                                                                                  #
#   |                 [<func>      ] <Default> Directly return the input vector without any mutation                                    #
#   |ech_name    :   Name of the global [echart] object upon which to dispatch actions via external JS                                  #
#   |                 [ttChart     ] <Default> One can change it to any valid JS variable name                                          #
#   |as.parts    :   Whether to convert the input into several parts that can be combined into customized HTML scripts                  #
#   |                 [FALSE       ] <Default> Only create a vector of complete JS functions, to represent single object inside each    #
#   |                                           <echarts:tooltip> respectively                                                          #
#   |                 [TRUE        ]           Output separate parts that can be combined with customization from outside this function #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<various>   :   The output depends on the argument [as.parts]                                                                      #
#   |                 [FALSE       ] <Default> Character vector in the same length as [widget], representing JS function to be invoked  #
#   |                 [TRUE        ]           data.frame with two columns: [js_func] and [html_tags], in the same length as [widget],  #
#   |                                           representing the function to create <echarts> object and the HTML tags that contain the #
#   |                                           object respectively. This is useful if one needs to combine multiple charts into one    #
#   |                                           tooltip of a separate <echarts> chart in a vectorized manner.                           #
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
#   | Log  |[1] Introduce a new argument [container] to allow containing the chart with other HTML tags                                 #
#   |      |[2] Introduce a new argument [ech_name] to allow dispatching actions upon the named chart via JS                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220215        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce new functions [strBalancedGroup] and [re.escape] to eliminate the unnecessary convention to define any JS     #
#   |      |     functions, to ensure a better flexibility of programming                                                               #
#   |      |[2] Known limitations: If there are any unmatched braces, either left or right ones, inside the JS functions of the         #
#   |      |     provided characterized html widgets (esp. when they are within JS character strings), this function fails to recognize #
#   |      |     the entire input string; hence the result is unexpected                                                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220219        | Version | 1.21        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the function [stringr::str_replace_all] to conduct multiple replacements, instead of using a single large     #
#   |      |     size of RegEx in [gsub], as the size of RegEx may exceed the maximum                                                   #
#   |      |[2] Known limitations: The size of each RegEx may still exceed the maximum when data for a single chart is extremely large  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220411        | Version | 1.22        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Corrected the conversion from JSON by setting [simplifyVector = FALSE], to avoid coercion of JS arrays into vectors,    #
#   |      |     when they only have one element respectively                                                                           #
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
#   |   |jsonlite, htmlwidgets, stringr, rlang, dplyr                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |getListNames                                                                                                               #
#   |   |   |re.escape                                                                                                                  #
#   |   |   |strBalancedGroup                                                                                                           #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |as.character.htmlwidget                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	jsonlite, htmlwidgets, stringr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#Enable big-bang <!!!> operator
library(rlang)

echarts4r.as.tooltip <- function(
	widget = NULL
	,container = function(html_tag){html_tag}
	,ech_name = 'ttChart'
	,as.parts = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (length(widget) == 0) return(character(0))
	if (length(ech_name) == 1) {
		ech_name <- rlang::rep_along(widget, ech_name)
	} else if (length(ech_name) == 0) {
		ech_name <- rlang::rep_along(widget, NA)
	} else if (length(ech_name) != length(widget)) {
		stop('[',LfuncName,'][ech_name][',length(ech_name),'] has different length to [widget][',length(widget),']!')
	}
	if (!is.logical(as.parts)) as.parts <- FALSE

	#100. Mark the elements that need to be converted
	#[IMPORTANT] Please note the precise sequence of the comparison as we only need [echarts4r] widgets here
	mask_conv <- sapply(
		widget
		,function(v){all(c('echarts4r', 'htmlwidget') %in% class(v)) | all(class(v) %in% c('character'))}
	)

	#200. Helper functions
	#210. Conversion for each element in the provided vector
	h_conv <- function(v, v_name) {
		#100. Convert the raw widget into character vector
		if (all(c('echarts4r', 'htmlwidget') %in% class(v))) {
			v_chr <- as.character.htmlwidget(v)
		} else {
			v_chr <- v
		}

		#300. Retrieve the <division> and the <script> tags respectively
		#310. Identify the <script> tag
		#[ASSUMPTION]
		#[1] For vectorized process, below function only generates one single vector
		#[2] For [echarts4r] results, this vector only contains one <script> tag
		v_script <- strBalancedGroup(
			v_chr
			,lBound = '<script.*?>'
			,rBound = '</script>'
			,rx = TRUE
			,include = TRUE
		)[[1]]

		#330. Identify the <div> tag, which exists just before the <script> tag, as indicated by the source code of [echarts4r]
		#331. Remove the <script> tag from the source string, and leave the <div> tags for searching
		rx_rem_scr <- rep_along(v_script, '')
		names(rx_rem_scr) <- re.escape(v_script)
		v_divs <- stringr::str_replace_all(v_chr, rx_rem_scr)

		#335. Extract the balanced group of <div> tags
		div_all <- strBalancedGroup(
			v_divs
			,lBound = '<div.*?>'
			,rBound = '</div>'
			,rx = TRUE
			,include = TRUE
		)[[1]]

		#339. Only need the <div> tag that is just followed by above <script> tag
		usr_div <- stringr::str_extract_all(v_chr, paste0(div_all, '(?=\\s*', re.escape(v_script), ')'))

		#350. Identify the JSON data, which we will transform to create HTML tags at later steps
		json_pre <- strBalancedGroup(
			v_chr
			,lBound = '<script.*?>'
			,rBound = '</script>'
			,rx = TRUE
			,include = FALSE
		)[[1]]
		json_scr <- jsonlite::fromJSON(json_pre, simplifyVector = FALSE)
		json_opts <- json_scr$x$opts

		#400. Retrieve the HTML ID of the widget
		# html_id <- gsub('^.+\\bid=("|\')(.+?)\\1.+$', '\\2', usr_div, perl = T)
		html_id <- stringr::str_extract_all(usr_div, '(?<=<div\\sid=("|\'))(.+?)(?=\\1)')[[1]][[1]]

		#500. Convert the {options} part in the <script> tag into JSON that can be recognized by JS
		name_opts <- c(getListNames(json_opts), 'value')
		char_opts <- json_opts %>%
			#Quote: https://stackoverflow.com/questions/56053108/tojson-without-outer-square-brackets
			jsonlite::toJSON(auto_unbox = T) %>%
			{gsub(paste0('"(', paste0(name_opts, collapse = '|') , ')":'), '\\1:', ., perl = T)} %>%
			{gsub('"','\'', .)} %>%
			{gsub('\\\\\'','\'', .)}

		#700. Convert the [formatter] part, when a function is introduced rather than a character string
		# func_opts <- gsub(paste0('\'(function\\s*\\(.*?\\)\\s*{.+?/\\*EndFunc\\*/})\''), '\\1', char_opts, perl = T)
		#710. Extract all balanced groups of contents embraced by braces [{}]
		braces_opts <- strBalancedGroup(
			char_opts
			,lBound = '{'
			,rBound = '}'
			,rx = FALSE
			,include = TRUE
		)[[1]]

		#750. Prepare the regular expression for conversion
		#[ASSUMPTION]
		#[1] JS functions are defined in the convention: function(...){...}
		#[2] Parameters of Echarts JS functions can only contain: [\\w\\s,] characters
		#[3] In [char_opts] all the function definitions are quoted by single quotation marks
		# rx_func_opts <- paste0('\'(function\\s*\\(.*?\\)\\s*(', paste0(re.escape(braces_opts), collapse = '|'), '))\'')
		rx_func_opts <- rep_along(braces_opts, '\\1')
		names(rx_func_opts) <- paste0('\'(function\\s*\\([\\w\\s,]*?\\)\\s*', re.escape(braces_opts), ')\'')

		#790. Remove the outer-most single quotation marks from the JS function definitions
		#[ASSUMPTION]
		#[1] When the data for Echarts is relatively large, the RegEx may exceed the acceptable size in characters
		# func_opts <- gsub(rx_func_opts, '\\1', char_opts, perl = T)
		func_opts <- stringr::str_replace_all(char_opts, rx_func_opts)

		#900. Create the JS function as well as the HTML tags
		js_attr <- data.frame(
			js_func = paste0(
				'function(){'
					#[IMPORTANT] The chart object must be a global object for dispatching actions via external JS
					#Quote: https://www.cnblogs.com/journey-mk5/p/9746201.html
					,v_name,' = echarts.init(document.getElementById(\'',html_id,'\'));'
					,'var opts = ',func_opts,';'
					,v_name,'.setOption(opts);'
				,'}'
			)
			,html_tags = container(usr_div)
			,stringsAsFactors = F
		)
		#20220413 It is weird that the [names] of above data.frame is corrupted!
		names(js_attr) <- c('js_func','html_tags')

		#999. Return the object explicitly
		return(js_attr)
	}

	#250. Combine the JS functions and HTML tags into complete JS statements
	h_combine <- function(v_func, v_tags){
		paste0(
			'function(params){'
				,'genChart = ',v_func,';'
				,'setTimeout(function () {'
					,'genChart();'
				,'}, 500);'
				,'var tthtml = ',shQuote(v_tags),';'
				,'return(tthtml);'
			,'}'
		)
	}

	#500. Conversion upon the masked elements
	js_attrs <- mapply(h_conv, widget[mask_conv], ech_name[mask_conv], SIMPLIFY = FALSE) %>% dplyr::bind_rows()

	#900. Determine the output
	if (as.parts) {
		#100. Prepare a dummy output list as placeholder
		rstOut <- data.frame(
			js_func = rlang::rep_along(widget, character(0))
			,html_tags = rlang::rep_along(widget, character(0))
			,stringsAsFactors = F
		)

		#500. Replace the valid elements with the converted ones
		rstOut[mask_conv,] <- js_attrs
	} else {
		#100. Prepare the output value by ignoring the elements that are NOT [echarts4r] widgets
		rstOut <- widget

		#500. Combine the statements for the valid elements
		rstOut[mask_conv] <- h_combine(js_attrs$js_func, js_attrs$html_tags)
	}

	#999. Return the result explicitly
	return( rstOut )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare the widget
		id_tooltip <- 'test_ech_1'
		testtooltip <- data.frame(.ech.draw = 'id', .val.floor = -15, .val.ceil = 32, .val.sym = 17) %>%
			echarts4r::e_charts(.ech.draw) %>%
			echarts4r::e_grid(
				index = 0
				, top = 2, right = 0, bottom = 2, left = 8
				, height = 12, width = 64
			) %>%
			#100. Draw a floor bar that is merely transparent; which is to shift the visible data bar
			echarts4r::e_bar(
				.val.floor
				,x_index = 0
				,y_index = 0
				,stack = 'StackBar'
				,barWidth = 8
			) %>%
			#200. Draw the data bar
			echarts4r::e_bar(
				.val.ceil
				,x_index = 0
				,y_index = 0
				,stack = 'StackBar'
				,barWidth = 8
			) %>%
			#400. Draw a line with the symbol to resemble the [marker] on the capsule
			echarts4r::e_line(
				.val.sym
				,x_index = 0
				,y_index = 0
				,stack = 'StackLine'
				,symbol = 'circle'
				,symbolSize = 12
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
				,min = -20
				,max = 40
			) %>%
			#400. Setup the legend
			echarts4r::e_legend(show = FALSE) %>%
			#800. Extra configurations
			#810. Flip the coordinates
			echarts4r::e_flip_coords() %>%
			#820. Show a loading animation when the chart is re-drawn
			echarts4r::e_show_loading() %>%
			#900. Convert to character vector
			as.character.htmlwidget() %>%
			#920. Setup the shape of the canvas
			{gsub(
				'width:(\\d+%);height:(\\d+)px;'
				,paste0(''
					,'width:',64 + 16,'px !important;'
					,'height:',12 + 4,'px !important;'
				)
				,.
			)} %>%
			{gsub(
				'id="(htmlwidget-.+?)"'
				,paste0('id="',id_tooltip,'"')
				,.
			)} %>%
			{gsub(
				'data-for="(htmlwidget-.+?)"'
				,paste0('data-for="',id_tooltip,'"')
				,.
			)}

		#200. Convert it into JS function
		js_func <- echarts4r.as.tooltip(testtooltip)
	}
}
