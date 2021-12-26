#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to Convert the [echarts4r] widget into a JS function for [echarts.tooltip.formatter], so that this       #
#   | widget can be rendered within the tooltip of an [echarts] object inside an HTML                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Due to character manipulation, one MUST place such remarks [/*EndFunc*/] right before the end of the function definition for any   #
#   | options that support function callback, such as [formatter] and [position], inside the echarts4r widget                           #
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
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<vec>       :   Character vector of the JS scripts                                                                                 #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |jsonlite, htmlwidgets, stringr                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |getListNames                                                                                                               #
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

echarts4r.as.tooltip <- function(
	widget = NULL
	,container = function(html_tag){html_tag}
	,ech_name = 'ttChart'
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (length(widget) == 0) return(character(0))

	#100. Mark the elements that need to be converted
	#[IMPORTANT] Please note the precise sequence of the comparison as we only need [echarts4r] widgets here
	mask_conv <- sapply(
		widget
		,function(v){all(c('echarts4r', 'htmlwidget') %in% class(v)) | all(class(v) %in% c('character'))}
	)

	#200. Helper functions
	#210. Conversion for each element in the provided vector
	h_conv <- function(v) {
		#100. Convert the raw widget into character vector
		if (all(c('echarts4r', 'htmlwidget') %in% class(v))) {
			v_chr <- as.character.htmlwidget(v)
		} else {
			v_chr <- v
		}

		#300. Retrieve the <division> and the <script> tags respectively
		usr_div <- gsub('\\s*<script\\b.+$', '', v_chr, perl = T)
		json_pre <- gsub('(?ismx)^.+\\s*<script.*?>(.+)</script>', '\\1', v_chr, perl = T)
		json_scr <- jsonlite::fromJSON(json_pre)
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
		func_opts <- gsub(paste0('\'(function\\(.*?\\)\\s*{.+?/\\*EndFunc\\*/})\''), '\\1', char_opts, perl = T)

		#900. Create the JS function
		js_func <- paste0(
			'function(params){'
				,'function genChart(){'
					#[IMPORTANT] The chart object must be a global object for dispatching actions via external JS
					#Quote: https://www.cnblogs.com/journey-mk5/p/9746201.html
					,ech_name,' = echarts.init(document.getElementById(\'',html_id,'\'));'
					,'var opts = ',func_opts,';'
					,ech_name,'.setOption(opts);'
				,'} '
				,'setTimeout(function () {'
					,'genChart();'
				,'}, 500);'
				,'var tthtml = ',shQuote(container(usr_div)),';'
				,'return(tthtml);'
			,'}'
		)

		#999. Return the object explicitly
		return(js_func)
	}

	#500. Conversion upon the masked elements
	rstOut <- widget
	rstOut[mask_conv] <- sapply(rstOut[mask_conv], h_conv)

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
