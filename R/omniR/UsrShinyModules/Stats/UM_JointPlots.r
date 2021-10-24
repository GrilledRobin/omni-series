#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This [shiny module] is intended to draw a [Joint Plot] over two vectors [x] pairing [y], given their lengths are the same          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Interface:                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] [lower-left ] A scatter plot showing positions of the pairs [x,y] along both axes                                             #
#   |[02] [lower-left ] A [toolbox] to brush the scatter plot in massive ways, see [ECharts -> options -> toolbox]                      #
#   |[03] [upper-left ] A histogram showing the distribution of values along [x]-axis, with its bins cut in the same way as that of the #
#   |                    scatter plot                                                                                                   #
#   |[04] [lower-right] A histogram showing the distribution of values along [y]-axis, with its bins cut in the same way as that of the #
#   |                    scatter plot                                                                                                   #
#   |[05] [upper-right] A [toolbox] resembling the similar ones in [ECharts], to enable/disable the slicing and saving of the charts:   #
#   |                   [1] [Reset Slicers] Disable the slicers and reset the charts to their initial status                            #
#   |                   [2] [Show Slicers ] Show the slicers for [x] and [y] on the lower-left side of the entire html division         #
#   |                   [3] [Hide Slicers ] Hide the slicers for [x] and [y] and reset the charts to their initial status               #
#   |                   [4] [Save Chart   ] Save a snapshot of current status of all charts (including slicing status) and prepare for  #
#   |                                        output of a static html file                                                               #
#   |[11] [left edge  ] A mini-histogram showing the distribution of values along [y]-axis, with its bins cut in the same way as that   #
#   |                    of the initial scatter plot (i.e. not sliced), which demonstrates current slicing status of the input values   #
#   |[12] [lower edge ] A mini-histogram showing the distribution of values along [x]-axis, with its bins cut in the same way as that   #
#   |                    of the initial scatter plot (i.e. not sliced), which demonstrates current slicing status of the input values   #
#   |[21] [left edge  ] A double-ended slicer covering the mini-histogram of [y]-axis, which is to enable the charting values between   #
#   |                    [y]-min and [y]-max                                                                                            #
#   |[22] [lower edge ] A double-ended slicer covering the mini-histogram of [x]-axis, which is to enable the charting values between   #
#   |                    [x]-min and [x]-max                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Interactivity:                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] [click on scatters] Change the view in below ways:                                                                            #
#   |                         [1] Display pins as highlights on the points without further interactions                                 #
#   |                         [2] Display pins as highlights on the bars of both histograms as highlights without further interactions  #
#   |[02] [brush on scatters] Change the view in below ways:                                                                            #
#   |                         [1] Display pins as highlights on the points without further interactions                                 #
#   |                         [2] Display pins as highlights on the bars of both histograms as highlights without further interactions  #
#   |[11] [click on bars    ] Change the view in below ways:                                                                            #
#   |                         [1] Highlight the same range in the same color (with 50% transparency) along the same axis in the scatter #
#   |                              plot, without changing the effects of the points lying inside it                                     #
#   |                         [2] Filter the other axis with the values of the points covered by the area highlighted in the scatter    #
#   |                              plot, highlighting the filtered values while adding 50% transparency to its original values          #
#   |                         [3] Add special effects to those points on the scatter plot that lie in the crossing area of the          #
#   |                              highlighted ones on both axes in the scatter plot                                                    #
#   |[21] [slicing          ] Change the view in below ways:                                                                            #
#   |                         [1] Clear all highlights on all charts                                                                    #
#   |                         [2] Filter the values on the same axis for all charts, except the mini-histograms                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters except the default arguments of [shiny]                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |width      :   The width of the entire html container of the charting area                                                         #
#   |               [100%            ] <Default> Fill the width of the parent html container                                            #
#   |               [ <str>: <k>%    ]           Percent of width of its parent html container                                          #
#   |               [ <numeric>      ]           Number of pixels as width of the charting container                                    #
#   |               [ <str>: <k>px   ]           Alias of the [numeric] input                                                           #
#   |height     :   The height of the entire html container of the charting area                                                        #
#   |               [400             ] <Default> 400px as height (height of any html container cannot be set as percentage)             #
#   |               [ <numeric>      ]           Number of pixels as height of the charting container                                   #
#   |               [ <str>: <k>px   ]           Alias of the [numeric] input                                                           #
#   |x          :   Vector of non-missing numeric values for [x]-axis of the charts                                                     #
#   |y          :   Vector of non-missing numeric values for [y]-axis of the charts                                                     #
#   |xname      :   Character value to be displayed as the name of [x]-axis                                                             #
#   |               [x               ] <Default> Display on the charts where applicable                                                 #
#   |               [ <str>          ]           Only a single character value is accepted                                              #
#   |yname      :   Character value to be displayed as the name of [y]-axis                                                             #
#   |               [y               ] <Default> Display on the charts where applicable                                                 #
#   |               [ <str>          ]           Only a single character value is accepted                                              #
#   |breaks     :   Method to cut the values along the axes into bins for the charts                                                    #
#   |               [Sturges         ] <Default> The same method is applied to both scatter plots and the histograms                    #
#   |               [ <str>          ]           See available values of the same argument for [hist]                                   #
#   |colorset   :   Character vector of color names/values for painting the charts, rules are as below:                                 #
#	|               [length(v)==1    ]           All charts are in the same color as provided                                           #
#	|               [length(v)==2    ]           Color of points on the scatter plot is v[1], while that of other charts are v[2]       #
#	|               [length(v)>=3    ]           Color of points on the scatter plot is v[1], while that of [x]-axis is v[2] and that   #
#	|                                             of [y]-axis is v[3]; the rest elements of [v] are omitted                             #
#   |samples    :   Number of samples to extract from all pairs of [x]-[y], useful when the input data is too large                     #
#	|fDebug     :   The switch of Debug Mode. Valid values are [F] or [T].                                                              #
#	|               Default: [F]                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List that contains below elements (as call to functions since they are reactive):                                   #
#   |               [CallCounter()   ]           Counter of times clicking on the button [Save Chart]                                   #
#   |               [ActionDone()    ]           Flag of success as TRUE/FALSE after saving the snapshot of the charts                  #
#   |               [EnvVariables()  ]           The latest values of all reactive ones that are defined within the module. One can use #
#	|                                             the function [str(module$EnvVariables())] to find all available values.               #
#	|                                            The most important one is as below:                                                    #
#	|                                            [ module$EnvVariables()$module_charts[[1]] ] The last saved snapshot of the charts as  #
#	|                                             a complete html tag                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20191210        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210807        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Support the [echarts4r] version: [0.4.1]                                                                                    #
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
#   |   |magrittr, grDevices, dplyr, tmcn                                                                                               #
#   |   |,shiny, tippy, echarts4r, htmlwidgets, shinyWidgets, htmltools                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |scaleNum                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |noUiSliderInput_EchStyle                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#

# [Quote: 'RV': User defined Reactive Values]
# [Quote: 'uWg': User defined Widgets]
# [Quote: 'uC': User defined Charts]
# [Quote: 'SI': User defined sliderInput]

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, grDevices, dplyr, tmcn
	,shiny, tippy, echarts4r, htmlwidgets, shinyWidgets, htmltools
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

UM_JointPlots_ui <- function(id){
	#Set current Name Space
	ns <- shiny::NS(id)

	#Create a box as container of UI elements for the mainframe
	shiny::uiOutput(ns('jplt_main'))
}

UM_JointPlots_svr <- function(input,output,session,fDebug = FALSE
	,width = '100%', height = 400
	,x = NULL, y = NULL, xname = 'x', yname = 'y', breaks = 'Sturges'
	,colorset = NULL, samples = NULL
){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	uRV$module_dt_bgn <- Sys.time()
	uRV$module_dt_end <- NULL
	uRV$module_texts <- list()
	uRV$module_tables <- list()
	uRV$module_charts <- list()
	uRV$module_inputs <- list()
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- shiny::reactiveVal(0)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message('[Module Call][UM_JointPlots]')
	}

	#010. Local parameters
	height <- max(height,150)
	uRV$height_charts <- height
	if (is.null(colorset)) {
		uRV$col_s <- 'primary'
		uRV$col_x <- 'primary'
		uRV$col_y <- 'primary'
	} else {
		uRV$col_s <- colorset[[min(length(colorset),1)]]
		uRV$col_x <- colorset[[min(length(colorset),2)]]
		uRV$col_y <- colorset[[min(length(colorset),3)]]
	}
	uRV$c_rgb_s <- grDevices::col2rgb(uRV$col_s)
	uRV$c_rgb_x <- grDevices::col2rgb(uRV$col_x)
	uRV$c_rgb_y <- grDevices::col2rgb(uRV$col_y)
	uRV$map_units <- c(kilo = 'K', million = 'M', billion = 'B', trillion = 'T', quintillion = 'Q')

	#100. Prepare the input data
	uRV$jp_df <- data.frame(x = x, y = y) %>% dplyr::mutate(clicked = FALSE , brushed = FALSE)
	if (!is.null(samples)) {
		uRV$jp_df <- dplyr::sample_n(uRV$jp_df,samples)
	}

	#120. General settings of styles for the output charts
	#121. Prepare the styles for the buttons
	uRV$btn_styles <- paste0(
		'text-align: center;'
		#Below defines the color with 0.5 alpha when the button is NOT hovered
		,'color: rgba(',paste0(uRV$c_rgb_s, collapse = ','),',0.5);'
		,'padding: 0;'
		,'margin: 0;'
		#Refer to documents of [echarts4r]
		,'font-size: 13px;'
		,'border: none;'
		,'background-color: rgba(0,0,0,0);'
	)
	#Leverage the package [tippy]
	#[Quote: https://atomiks.github.io/tippyjs/themes/ ]
	uRV$theme_tooltips <- paste0(
		'.tippy-tooltip.',gsub('\\W','_',ns('Ech'),perl = TRUE),'-theme {'
			,'background-color: rgba(0,0,0,0);'
			,'border: none;'
			,'color: rgba(',paste0(uRV$c_rgb_s, collapse = ','),',0.95);'
			,'font-family: sans-serif;'
			,'font-weight: 500;'
			,'font-size: 12px;'
		,'}'
		,'.tippy-tooltip.',gsub('\\W','_',ns('Ech'),perl = TRUE),'-theme .tippy-arrow {'
			,'background-color: rgba(0,0,0,0);'
			,'border: none;'
			,'color: rgba(0,0,0,0);'
		,'}'
	)
	btn_style_hover <- function(id){
		paste0(
			'[id="',id,'"]:hover {'
				#Below defines the color when the button is hovered
				,'color: ',uRV$col_s,';'
			,'}'
		)
	}

	#122. Styles for slicer on x-axis
	uRV$styles_slicer_x_div <- paste0(
		'width: 100%;'
		,'height: 30px;'
		#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
		,'position: relative;'
	)
	uRV$styles_slicer_x_chart <- paste0(
		'position: absolute;'
		,'z-index: 0;'
		,'top: 5px;'
		,'right: 22%;'
		,'left: 40px;'
	)
	uRV$grid_slicer_x_chart <- list(index = 0,height = '15px', top = '0', right = '0', left = '0')
	uRV$styles_slicer_x_slider <- paste0(
		'height: 100%;'
		,'position: absolute;'
		#Ensure this layer is above the mini chart
		,'z-index: 1;'
		,'right: 22%;'
		,'left: 40px;'
	)

	#123. Styles for slicer on y-axis
	uRV$styles_slicer_y_div <- paste0(
		'width: 30px;'
		,'height: 100%;'
		#Set the child content as [vertically centered]
		#[Quote: https://blog.csdn.net/weixin_37580235/article/details/82317240 ]
		# ,'display: -webkit-flex;'
		# ,'display: flex;'
		# ,'-webkit-justify-content: space-between;'
		# ,'justify-content: space-between;'

		#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
		,'position: relative;'
	)
	uRV$styles_slicer_y_chart <- paste0(
		'width: 100%;'
		,'bottom: 70px;'
		#Set the child content as [horizontally centered] (Align the settings to its parent)
		,'position: absolute;'
		,'top: ',ceiling((height-30)*0.22),'px;'
		,'z-index: 0;'
	)
	uRV$grid_slicer_y_chart <- list(index = 0, width = '15px', top = '0', right = '0')
	uRV$styles_slicer_y_slider <- paste0(
		'width: 100%;'
		#Set the child content as [horizontally centered] (Align the settings to its parent)
		,'position: absolute;'
		#Below is to fix the bug that stretches the page height via [iframe] with an unobservable division
		,'overflow: hidden;'
		# ,'right: 4px;'
		#The width of the handler of [noUiSliderInput] is [34px]
		,'height: ',ceiling((height-30)*0.78-40+34),'px;'
		,'top: ',ceiling((height-30)*0.22-17),'px;'
		#Ensure this layer is above the mini chart
		,'z-index: 1;'
	)

	#128. Grids for the major charts
	uRV$grid_x <- list(index = 0, top = '15px', right = '0', bottom = '0', left = '40px')
	uRV$grid_y <- list(index = 0, top = '0', right = '15px', bottom = '40px', left = '0')
	uRV$grid_xy <- list(index = 0, top = '0', right = '0', bottom = '40px', left = '40px')

	#129. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			#Add hover effects to the buttons
			'.btn>:hover {'
				,'color: ',uRV$col_s,';'
			,'}'
			# ,btn_style_hover(ns('uWg_AB_ShowSlicer'))
			# ,btn_style_hover(ns('uWg_AB_HideSlicer'))
			# ,btn_style_hover(ns('uWg_AB_ResetSlicer'))
			,uRV$theme_tooltips
			# ,uRV$style_tooltips_inject
			,'[id="',ns('uSI_slicer_x'),'"] {'
				,'background: rgba(10,10,10,0.05);'
				,'top: 5px;'
			,'}'
			,'[id="',ns('uSI_slicer_y'),'"] {'
				,'background: rgba(10,10,10,0.05);'
				#[Quote: https://stackoverflow.com/questions/15935837/how-to-display-a-range-input-slider-vertically ]
				# ,'transform: rotate(270deg);'
				# ,'-webkit-transform: rotate(270deg);'
				,'margin: 17px auto 17px !important;'
			,'}'
			,'[id="',ns('slicer_x_out'),'"] {'
				,'background: rgba(10,10,10,0.05);'
				,'top: 5px;'
			,'}'
			,'[id="',ns('slicer_y_out'),'"] {'
				,'background: rgba(10,10,10,0.05);'
				,'margin: 17px auto 17px !important;'
			,'}'
			,'.noUi-horizontal .noUi-handle {'
				,'border-color: rgba(',paste0(uRV$c_rgb_x, collapse = ','),',0.5);'
				,'background: rgba(255,255,255,0.5);'
			,'}'
			,'.noUi-vertical .noUi-handle {'
				,'border-color: rgba(',paste0(uRV$c_rgb_y, collapse = ','),',0.5);'
				,'background: rgba(255,255,255,0.5);'
			,'}'
		)
	)

	#140. Standardize the attributes of the elements inside the charts
	#141. Attributes for [tooltips]
	uRV$attr_tooltips <- list(
		textStyle = list(
			color = '#fff'
			,fontSize = 12
		)
		,backgroundColor = 'rgba(50,50,50,0.7)'
		,borderColor = 'rgba(50,50,50,0)'
	)

	#150. Define function to extract parameters from [base::hist]
	genHistInf <- function(df){
		rst <- list()

		#150. Prepare to scale the numbers on the labels of both axes for the scatter plot
		#151. x-axis
		rst$max_x0 <- max(abs(df$x), na.rm = TRUE)
		rst$logK_x0 <- log(rst$max_x0, base = 1000)
		numfmt_x0 <- scaleNum(rst$max_x0, 1000, map_units = uRV$map_units)
		rst$logK_x0_whole <- numfmt_x0$parts$k_exp %>% unlist()
		rst$nfrac_x0 <- numfmt_x0$parts$k_dec %>% unlist()
		rst$str_unit_x0 <- numfmt_x0$parts$c_sfx %>% unlist()

		#152. y-axis
		rst$max_y0 <- max(abs(df$y), na.rm = TRUE)
		rst$logK_y0 <- log(rst$max_y0, base = 1000)
		numfmt_y0 <- scaleNum(rst$max_y0, 1000, map_units = uRV$map_units)
		rst$logK_y0_whole <- numfmt_y0$parts$k_exp %>% unlist()
		rst$nfrac_y0 <- numfmt_y0$parts$k_dec %>% unlist()
		rst$str_unit_y0 <- numfmt_y0$parts$c_sfx %>% unlist()

		#200. Prepare the data for histograms
		#210. Extract the information for x-axis
		rst$jp_x_prep <- hist(df$x, plot = FALSE, breaks = breaks)
		rst$jp_x_prep_df <- data.frame(
			mids = rst$jp_x_prep$mids
			,mins = rst$jp_x_prep$breaks[-length(rst$jp_x_prep$breaks)]
			,maxs = rst$jp_x_prep$breaks[-1]
			,counts = rst$jp_x_prep$counts
			,density = rst$jp_x_prep$density
		) %>%
			dplyr::mutate(clicked = FALSE, itemColor = uRV$col_x, xAxis = dplyr::row_number()-1)
		rst$len_whole_x_axis <- max(nchar(gsub('^\\s*(-?\\d*)?((\\.)(\\d*))?$', '\\1', rst$jp_x_prep$mids,perl = TRUE)))
		rst$len_frac_x_axis <- max(nchar(gsub('^\\s*(-?\\d*)?((\\.)(\\d*))?$', '\\4', rst$jp_x_prep$mids,perl = TRUE)))
		rst$len_max_x_axis <- rst$len_whole_x_axis + rst$len_frac_x_axis + 1
		rst$fmtlen_x_axis <- min(rst$len_frac_x_axis, 2)
		rst$jp_x_prep_df <- rst$jp_x_prep_df %>%
			dplyr::mutate(
				c_mids = paste0(
					ifelse(mids<0, '-', '')
					,tmcn::strpad(as.character(abs(mids)), width = rst$len_max_x_axis, side = 'left', pad = '0')
				)
			)

		#220. Prepare the data for histogram on [y]
		rst$jp_y_prep <- hist(df$y, plot = FALSE, breaks = breaks)
		rst$jp_y_prep_df <- data.frame(
			mids = rst$jp_y_prep$mids
			,mins = rst$jp_y_prep$breaks[-length(rst$jp_y_prep$breaks)]
			,maxs = rst$jp_y_prep$breaks[-1]
			,counts = rst$jp_y_prep$counts
			,density = rst$jp_y_prep$density
		) %>%
			dplyr::mutate(clicked = FALSE, itemColor = uRV$col_y, yAxis = dplyr::row_number()-1)

		#230. Determine the number of characters of [mids] and the display format
		rst$len_whole_y_axis <- max(nchar(gsub('^\\s*(-?\\d*)?((\\.)(\\d*))?$', '\\1', rst$jp_y_prep$mids,perl = TRUE)))
		rst$len_frac_y_axis <- max(nchar(gsub('^\\s*(-?\\d*)?((\\.)(\\d*))?$', '\\4', rst$jp_y_prep$mids,perl = TRUE)))
		rst$len_max_y_axis <- rst$len_whole_y_axis + rst$len_frac_y_axis + 1
		rst$fmtlen_y_axis <- min(rst$len_frac_y_axis, 2)
		rst$jp_y_prep_df <- rst$jp_y_prep_df %>%
			dplyr::mutate(
				c_mids = paste0(
					ifelse(mids<0, '-', '')
					,tmcn::strpad(as.character(abs(mids)), width = rst$len_max_y_axis, side = 'left', pad = '0')
				)
			)

		#250. Prepare to scale the numbers on the labels of axes for the histograms
		#251. x-axis for y-histogram (index==1)
		rst$max_x1 <- max(rst$jp_x_prep$counts)
		rst$logK_x1 <- log(rst$max_x1,base = 1000)
		numfmt_x1 <- scaleNum(rst$max_x1, 1000, map_units = uRV$map_units)
		rst$logK_x1_whole <- numfmt_x1$parts$k_exp %>% unlist()
		rst$nfrac_x1 <- numfmt_x1$parts$k_dec %>% unlist()
		rst$str_unit_x1 <- numfmt_x1$parts$c_sfx %>% unlist()

		#252. y-axis for x-histogram (index==2)
		rst$max_y2 <- max(rst$jp_y_prep$counts)
		rst$logK_y2 <- log(rst$max_y2,base = 1000)
		numfmt_y2 <- scaleNum(rst$max_y2, 1000, map_units = uRV$map_units)
		rst$logK_y2_whole <- numfmt_y2$parts$k_exp %>% unlist()
		rst$nfrac_y2 <- numfmt_y2$parts$k_dec %>% unlist()
		rst$str_unit_y2 <- numfmt_y2$parts$c_sfx %>% unlist()

		#400. Correct the attributes of axes
		#410. Correct the attributes of y-axis in the scatter plot to align with the y-histogram
		#This only happens when the minimum of [y] is larger than 0 for certain amount
		#411. Calculate interval
		rst$ntvl_y_scatter <- (rst$jp_y_prep$mids[[1]] - rst$jp_y_prep$breaks[[1]]) * 2
		rst$min_y_scatter <- rst$jp_y_prep$breaks[[1]]
		rst$max_y_scatter <- rst$jp_y_prep$breaks[[length(rst$jp_y_prep$breaks)]]
		if (rst$min_y_scatter < 0 & min(df$y) > 0) rst$min_y_scatter <- 0

		#420. Correct the bar width of the x-histogram
		#This only happens when the minimum of [x] is larger than 0 for certain amount
		#421. Calculate interval
		rst$ntvl_x_scatter <- (rst$jp_x_prep$mids[[1]] - rst$jp_x_prep$breaks[[1]]) * 2
		rst$min_x_scatter <- rst$jp_x_prep$breaks[[1]]
		rst$max_x_scatter <- rst$jp_x_prep$breaks[[length(rst$jp_x_prep$breaks)]]
		if (rst$min_x_scatter < 0 & min(df$x) > 0) rst$min_x_scatter <- 0

		#422. Calculate the number of intervals it SHOULD be on x axis
		# k_ntvl_x_hist <- round(jp_x_prep$breaks[[length(jp_x_prep$breaks)]] / ntvl_x_scatter , digits = 0)

		#429. Correction
		# if (k_ntvl_x_hist > length(jp_x_prep$breaks)) {
		# 	barwidth_x_hist <- paste0(formatC(90 * length(jp_x_prep$mids) / k_ntvl_x_hist , digits = 0 , format = 'f'),'%')
		# } else {
		# 	barwidth_x_hist <- '90%'
		# }

		#990. Return values
		return(rst)
	}

	#300. Initialize the slicers
	#301. Retrieve the histogram information for the input data
	uRV$slicer_inf <- genHistInf(uRV$jp_df)

	#310. Buttons to control the display and actions of the slicers
	#311. [Show Slicers]
	uRV$btn_ShowSlicer <- shiny::tags$div(
		style = paste0(
			#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
			'position: absolute;'
			,'top: 5px;'
			,'right: 25px;'
		)
		,shiny::actionButton(ns('uWg_AB_ShowSlicer'), NULL
			,style = uRV$btn_styles
			,icon = shiny::icon('sliders')
		)
		,tippy::tippy_this(
			ns('uWg_AB_ShowSlicer')
			,'Show Slicers'
			,placement = 'top'
			,distance = 0
			,arrow = TRUE
			,theme = gsub('\\W','_',ns('Ech'),perl = TRUE)
		)
	)
	uRV$uDiv_ShowSlicer <- shiny::renderUI({uRV$btn_ShowSlicer})

	#312. [Hide Slicers]
	uRV$btn_HideSlicer <- shiny::tags$div(
		style = paste0(
			#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
			'position: absolute;'
			,'top: 5px;'
			,'right: 25px;'
		)
		,shiny::actionButton(ns('uWg_AB_HideSlicer'), NULL
			,style = uRV$btn_styles
			,icon = shiny::icon('bars')
		)
		,tippy::tippy_this(
			ns('uWg_AB_HideSlicer')
			,'Hide Slicers'
			,placement = 'top'
			,distance = 0
			,arrow = TRUE
			,theme = gsub('\\W','_',ns('Ech'),perl = TRUE)
		)
	)
	uRV$uDiv_HideSlicer <- NULL

	#313. [Reset Slicers]
	uRV$btn_ResetSlicer <- shiny::tags$div(
		style = paste0(
			#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
			'position: absolute;'
			,'top: 5px;'
			,'right: 45px;'
		)
		,shiny::actionButton(ns('uWg_AB_ResetSlicer'), NULL
			,style = uRV$btn_styles
			,icon = shiny::icon('refresh')
		)
		,tippy::tippy_this(
			ns('uWg_AB_ResetSlicer')
			,'Reset Slicers'
			,placement = 'top'
			,distance = 0
			,arrow = TRUE
			,theme = gsub('\\W','_',ns('Ech'),perl = TRUE)
		)
	)
	uRV$uDiv_ResetSlicer <- shiny::renderUI({uRV$btn_ResetSlicer})

	#319. [Save Charts]
	uRV$btn_SaveChart <- shiny::tags$div(
		style = paste0(
			#[position] of the container MUST be set as [relative] to ensure the child division has correct position.
			'position: absolute;'
			,'top: 5px;'
			,'right: 5px;'
		)
		,shiny::actionButton(ns('uWg_AB_Save'), NULL
			,style = uRV$btn_styles
			,icon = shiny::icon('download')
		)
		,tippy::tippy_this(
			ns('uWg_AB_Save')
			,'Save Chart'
			,placement = 'top'
			,distance = 0
			,arrow = TRUE
			,theme = gsub('\\W','_',ns('Ech'),perl = TRUE)
		)
	)
	uRV$uDiv_SaveChart <- shiny::renderUI({uRV$btn_SaveChart})

	#320. Slider inputs for filtering x and y
	#321. Mini chart on the slicer for x-axis
	uRV$slicer_x_chart <- echarts4r::e_charts() %>%
		# echarts4r::e_grid(index = 0,height = '15px', top = '0', right = '0', left = '0') %>%
		echarts4r::e_data(uRV$slicer_inf$jp_x_prep_df, c_mids) %>%
		echarts4r::e_bar(
			counts
			,legend = FALSE
			,barWidth = '98%'
			,itemStyle = list(
				opacity = .3
				,color = uRV$col_x
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>Overall</strong><br/>"'
								,'+ "<i>[" + echarts.format.addCommas(parseFloat(params.value[0]).toFixed('
										,uRV$slicer_inf$fmtlen_x_axis
									,')'
								,') + "]</i>"'
								,'+ " : " + echarts.format.addCommas(params.value[1])'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,show = FALSE
			,inverse = TRUE
		) %>%
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,show = FALSE
		) %>%
		echarts4r::e_tooltip(
			trigger = 'item'
			,confine = FALSE
			,position = list(
				right = '-64px'
				,top = '-32px'
			)
			,axisPointer = list(show = FALSE)
		)
	output$uC_slicer_x <- echarts4r::renderEcharts4r({
		#We pass a list here to sanitize the program
		#[Quote: https://stackoverflow.com/questions/9129673/passing-list-of-named-parameters-to-function ]
		do.call(echarts4r::e_grid
			,append(
				list(e = uRV$slicer_x_chart)
				,uRV$grid_slicer_x_chart
			)
		)
	})

	#322. Slicer for x-axis
	uRV$slicer_x <- shiny::tags$div(
		style = uRV$styles_slicer_x_div
		,shiny::tags$div(
			style = uRV$styles_slicer_x_chart
			#The height of the slider bar of [noUiSliderInput] is [20px]
			,echarts4r::echarts4rOutput(ns('uC_slicer_x'), width = '100%', height = '20px')
		)
		,shiny::tags$div(
			style = uRV$styles_slicer_x_slider
			# ,shinyWidgets::noUiSliderInput(
			,noUiSliderInput_EchStyle(
				inputId = ns('uSI_slicer_x')
				,min = uRV$slicer_inf$min_x_scatter, max = uRV$slicer_inf$max_x_scatter
				,value = c(uRV$slicer_inf$min_x_scatter, uRV$slicer_inf$max_x_scatter)
				,tooltips = FALSE
				,connect = c(TRUE, FALSE, TRUE)
				,color = paste0('rgba(', paste0(uRV$c_rgb_x, collapse = ','), ',0.5)')
				,width = '100%'
				,height = 20
			)
		)
	)
	uRV$uDiv_slicer_x <- NULL

	#325. Mini chart on the slicer for y-axis
	uRV$slicer_y_chart <- echarts4r::e_charts() %>%
		echarts4r::e_data(uRV$slicer_inf$jp_y_prep_df, counts) %>%
		echarts4r::e_bar(
			c_mids
			,legend = FALSE
			,barWidth = '98%'
			,itemStyle = list(
				opacity = .3
				,color = uRV$col_y
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>Overall</strong><br/>"'
								,'+ "<i>[" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed('
										,uRV$slicer_inf$fmtlen_y_axis
									,')'
								,') + "]</i>"'
								,'+ " : " + echarts.format.addCommas(params.value[0])'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,data = uRV$slicer_inf$jp_y_prep_df$c_mids
			,type = 'category'
			,show = FALSE
		) %>%
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,type = 'value'
			,show = FALSE
			,inverse = TRUE
		) %>%
		echarts4r::e_tooltip(
			trigger = 'item'
			,confine = FALSE
			,position = list(
				left = '0px'
				,top = '-53px'
			)
			,axisPointer = list(show = FALSE)
		)
	output$uC_slicer_y <- echarts4r::renderEcharts4r({
		#We pass a list here to sanitize the program
		do.call(echarts4r::e_grid
			,append(
				list(e = uRV$slicer_y_chart)
				,append(
					uRV$grid_slicer_y_chart
					,list(height = paste0(floor((height-30)*0.78-40), 'px'))
				)
			)
		)
	})

	#326. Slicer for y-axis
	uRV$slicer_y <- shiny::tags$div(
		style = uRV$styles_slicer_y_div
		,shiny::tags$div(
			style = uRV$styles_slicer_y_chart
			#The height of the slider bar of [noUiSliderInput] is [20px]
			,echarts4r::echarts4rOutput(ns('uC_slicer_y'), width = '20px', height = paste0(floor((height-30)*0.78-40),'px'))
		)
		,shiny::tags$div(
			style = uRV$styles_slicer_y_slider
			# ,shinyWidgets::noUiSliderInput(
			,noUiSliderInput_EchStyle(
				inputId = ns('uSI_slicer_y')
				,min = uRV$slicer_inf$min_y_scatter, max = uRV$slicer_inf$max_y_scatter
				,value = c(uRV$slicer_inf$min_y_scatter, uRV$slicer_inf$max_y_scatter)
				,tooltips = FALSE
				,connect = c(TRUE, FALSE, TRUE)
				,color = paste0('rgba(',paste0(uRV$c_rgb_y, collapse = ','), ',0.5)')
				,orientation = 'vertical'
				,direction = 'rtl'
				,width = 20
				,height = paste0(ceiling((height-30)*0.78-40), 'px')
			)
		)
	)
	uRV$uDiv_slicer_y <- NULL

	#500. Observers
	#501. Click on [Hide Slicers]
	shiny::observeEvent(input$uWg_AB_HideSlicer, {
		if (is.null(input$uWg_AB_HideSlicer)) return()
		if (input$uWg_AB_HideSlicer == 0) return()

		shiny::isolate({
			#100. Reset the slicers
			uRV$chart_x_min <- uRV$slicer_inf$min_x_scatter
			uRV$chart_x_max <- uRV$slicer_inf$max_x_scatter
			uRV$chart_y_min <- uRV$slicer_inf$min_y_scatter
			uRV$chart_y_max <- uRV$slicer_inf$max_y_scatter
			uRV$slicer_x_min <- uRV$slicer_inf$min_x_scatter
			uRV$slicer_x_max <- uRV$slicer_inf$max_x_scatter
			uRV$slicer_y_min <- uRV$slicer_inf$min_y_scatter
			uRV$slicer_y_max <- uRV$slicer_inf$max_y_scatter
			shinyWidgets::updateNoUiSliderInput(session, 'uSI_slicer_x'
				,value = c(uRV$slicer_inf$min_x_scatter, uRV$slicer_inf$max_x_scatter)
			)
			shinyWidgets::updateNoUiSliderInput(session, 'uSI_slicer_y'
				,value = c(uRV$slicer_inf$min_y_scatter, uRV$slicer_inf$max_y_scatter)
			)

			#200. Show other UI divisions
			uRV$uDiv_ShowSlicer <- shiny::renderUI({uRV$btn_ShowSlicer})

			#300. Change global values
			uRV$height_charts <- height
			uRV$xy_highlight_y <- FALSE
			uRV$xy_highlight_x <- FALSE
			uRV$x_dp <- NULL
			uRV$x_br <- NULL
			uRV$y_dp <- NULL
			uRV$y_br <- NULL

			#700. Hide related UI divisions
			# shinyBS::removeTooltip(session,ns('uWg_AB_HideSlicer'))
			uRV$uDiv_HideSlicer <- NULL
			# uRV$uDiv_ResetSlicer <- NULL
			uRV$uDiv_slicer_x <- NULL
			uRV$uDiv_slicer_y <- NULL
		})
	})

	#505. Click on [Reset Slicers]
	shiny::observeEvent(input$uWg_AB_ResetSlicer, {
		if (is.null(input$uWg_AB_ResetSlicer)) return()
		if (input$uWg_AB_ResetSlicer == 0) return()

		shiny::isolate({
			#100. Reset the slicers
			uRV$chart_x_min <- uRV$slicer_inf$min_x_scatter
			uRV$chart_x_max <- uRV$slicer_inf$max_x_scatter
			uRV$chart_y_min <- uRV$slicer_inf$min_y_scatter
			uRV$chart_y_max <- uRV$slicer_inf$max_y_scatter
			uRV$slicer_x_min <- uRV$slicer_inf$min_x_scatter
			uRV$slicer_x_max <- uRV$slicer_inf$max_x_scatter
			uRV$slicer_y_min <- uRV$slicer_inf$min_y_scatter
			uRV$slicer_y_max <- uRV$slicer_inf$max_y_scatter
			shinyWidgets::updateNoUiSliderInput(session, 'uSI_slicer_x'
				,value = c(uRV$slicer_inf$min_x_scatter, uRV$slicer_inf$max_x_scatter)
			)
			shinyWidgets::updateNoUiSliderInput(session, 'uSI_slicer_y'
				,value = c(uRV$slicer_inf$min_y_scatter, uRV$slicer_inf$max_y_scatter)
			)

			#300. Change global values
			uRV$xy_highlight_y <- FALSE
			uRV$xy_highlight_x <- FALSE
			uRV$x_dp <- NULL
			uRV$x_br <- NULL
			uRV$y_dp <- NULL
			uRV$y_br <- NULL

			#500. Remove the highlights
			#[Quote: https://stackoverflow.com/questions/59006251/r-shiny-setting-input-values-with-sessionsendcustommessage-inside-a-shiny-m ]
			# session$sendInputMessage(('chart_y_clicked_data_value'), list(character(0),character(0)))
		})
	})

	#507. Drag on the slicers
	shiny::observeEvent(input$uSI_slicer_x, {
		if (is.null(input$uSI_slicer_x)) return()
		if (length(input$uSI_slicer_x) == 0) return()

		shiny::isolate({
			#100. Update the filter values
			uRV$chart_x_min <- input$uSI_slicer_x[[1]]
			uRV$chart_x_max <- input$uSI_slicer_x[[2]]

			#300. Change global values
			uRV$xy_highlight_y <- FALSE
			uRV$xy_highlight_x <- FALSE
		})
	})
	shiny::observeEvent(input$uSI_slicer_y, {
		if (is.null(input$uSI_slicer_y)) return()
		if (length(input$uSI_slicer_y) == 0) return()

		shiny::isolate({
			#100. Update the filter values
			uRV$chart_y_min <- input$uSI_slicer_y[[1]]
			uRV$chart_y_max <- input$uSI_slicer_y[[2]]

			#300. Change global values
			uRV$xy_highlight_y <- FALSE
			uRV$xy_highlight_x <- FALSE
		})
	})

	#510. Click on [Show Slicers]
	shiny::observeEvent(input$uWg_AB_ShowSlicer, {
		if (is.null(input$uWg_AB_ShowSlicer)) return()
		if (input$uWg_AB_ShowSlicer == 0) return()

		shiny::isolate({
			#200. Show other UI divisions
			uRV$uDiv_HideSlicer <- shiny::renderUI({uRV$btn_HideSlicer})
			# uRV$uDiv_ResetSlicer <- shiny::renderUI({uRV$btn_ResetSlicer})
			uRV$uDiv_slicer_x <- shiny::renderUI({uRV$slicer_x})
			uRV$uDiv_slicer_y <- shiny::renderUI({uRV$slicer_y})

			#300. Change global values
			uRV$height_charts <- height - 30

			#700. Hide related UI divisions
			# shinyBS::removeTooltip(session,ns('uWg_AB_ShowSlicer'))
			uRV$uDiv_ShowSlicer <- NULL
		})
	})

	#520. Determine when to display the [Reset Slicers] button
	#Below observer seems to take weird effect hence cannot be implemented
	# shiny::observe(
	# 	{
	# 		#100. Take dependencies
	# 		uRV$inf_draw
	# 		uRV$jp_yh
	# 		uRV$jp_xh
	#
	# 		#900. Execute below block of codes only once upon the change of any one of above dependencies
	# 		shiny::isolate({
	# 			if (is.null(uRV$inf_draw)) return()
	# 			if (is.null(uRV$jp_yh)) return()
	# 			if (is.null(uRV$jp_xh)) return()
	# 			if (
	# 				!identical(uRV$slicer_inf, uRV$inf_draw)
	# 				| !identical(uRV$slicer_inf$jp_y_prep_df, uRV$jp_yh)
	# 				| !identical(uRV$slicer_inf$jp_x_prep_df, uRV$jp_xh)
	# 			) {
	# 				uRV$uDiv_ResetSlicer <- uRV$btn_ResetSlicer
	# 			} else {
	# 				uRV$uDiv_ResetSlicer <- NULL
	# 			}
	# 		})
	# 	}
	# 	,suspended = TRUE
	# 	# ,priority = 985
	# )


	#599. Determine the output value
	#Below counter is to ensure that the output of this module is a trackable event for other modules to observe
	shiny::observeEvent(input$uWg_AB_Save, {
		if (is.null(input$uWg_AB_Save)) return()
		if (input$uWg_AB_Save == 0) return()
		uRV_finish(uRV_finish() + 1)
		uRV$ActionDone <- TRUE

		#700. Prepare the slicers for output, which are disabled for user interactions
		#Please check the final section in this module for code descriptions
		#It is detected that under [echarts4r:0.2.3], the canvas height cannot exceed 600px,
		# otherwise part of the static chart (i.e. without being rendered by [renderEcharts4r]) will NOT show!
		#20200321 It is tested that we can set [height] option in the call of [echarts4r::e_charts] to ensure
		# correct height of the printed chart.
		# height_static <- min(600,height)
		height_static <- height
		if (
			uRV$inf_draw$min_x_scatter == uRV$slicer_inf$min_x_scatter
			& uRV$inf_draw$max_x_scatter == uRV$slicer_inf$max_x_scatter
			& uRV$inf_draw$min_y_scatter == uRV$slicer_inf$min_y_scatter
			& uRV$inf_draw$max_y_scatter == uRV$slicer_inf$max_y_scatter
		) {
			height_static_charts <- height_static
			out_slicer_x <- NULL
			out_slicer_y <- NULL
		} else {
			height_static_charts <- height_static - 30

			cover_x_len <- uRV$slicer_inf$max_x_scatter - uRV$slicer_inf$min_x_scatter
			cover_x_upper <- uRV$slicer_inf$max_x_scatter - ifelse(is.null(uRV$chart_x_max), uRV$slicer_inf$max_x_scatter, uRV$chart_x_max)
			cover_x_lower <- ifelse(is.null(uRV$chart_x_min), uRV$slicer_inf$min_x_scatter, uRV$chart_x_min) - uRV$slicer_inf$min_x_scatter
			out_slicer_x <- shiny::tags$div(
				style = paste0(''
					# ,'pointer-events: none;'
					# ,'cursor: default;'
					,uRV$styles_slicer_x_div
				)
				,shiny::tags$div(
					style = paste0(
						uRV$styles_slicer_x_chart
						#This MUST be placed below the universal style to overwrite the default one.
						,'z-index: 99;'
					)
					,shiny::tags$div(
						style = 'width: 100%; height: 20px;'
						,do.call(echarts4r::e_grid
							,append(
								list(e = uRV$slicer_x_chart)
								,uRV$grid_slicer_x_chart
							)
						)
					)
				)
				,shiny::tags$div(
					style = paste0(
						uRV$styles_slicer_x_slider
						,'height: 20px;'
						,'top: 5px;'
					)
					,shiny::fillRow(
						flex = c(
							round(100*cover_x_lower/cover_x_len, 2)
							,round(100*(cover_x_len - cover_x_upper - cover_x_lower)/cover_x_len, 2)
							,round(100*cover_x_upper/cover_x_len, 2)
						)
						,shiny::tags$div(
							style = paste0(
								'background-color: rgba(',paste0(uRV$c_rgb_x, collapse = ','),',0.5);'
								,'width: 100%;'
								,'height: 100%;'
								,'color: rgba(0,0,0,0);'
							)
						)
						,shiny::tags$div(
							style = paste0(
								'background-color: rgba(10,10,10,0.05);'
								,'width: 100%;'
								,'height: 100%;'
								,'color: rgba(0,0,0,0);'
							)
						)
						,shiny::tags$div(
							style = paste0(
								'background-color: rgba(',paste0(uRV$c_rgb_x, collapse = ','),',0.5);'
								,'width: 100%;'
								,'height: 100%;'
								,'color: rgba(0,0,0,0);'
							)
						)
					)
					# shinyWidgets::noUiSliderInput(
					# 	inputId = ns('slicer_x_out')
					# 	,min = uRV$slicer_inf$min_x_scatter, max = uRV$slicer_inf$max_x_scatter
					# 	,value = c(uRV$chart_x_min,uRV$chart_x_max)
					# 	,tooltips = FALSE
					# 	,connect = c(TRUE, FALSE, TRUE)
					# 	,color = paste0('rgba(',paste0(uRV$c_rgb_x, collapse = ','),',0.5)')
					# 	,width = '100%'
					# 	,height = 20
					# )
				)
			)

			cover_y_len <- uRV$slicer_inf$max_y_scatter - uRV$slicer_inf$min_y_scatter
			cover_y_upper <- uRV$slicer_inf$max_y_scatter - ifelse(is.null(uRV$chart_y_max), uRV$slicer_inf$max_y_scatter, uRV$chart_y_max)
			cover_y_lower <- ifelse(is.null(uRV$chart_y_min), uRV$slicer_inf$min_y_scatter, uRV$chart_y_min) - uRV$slicer_inf$min_y_scatter
			out_slicer_y <- shiny::tags$div(
				style = paste0(''
					#[Quote: https://stackoverflow.com/questions/2091168/how-to-disable-a-link-using-only-css ]
					# ,'pointer-events: none;'
					# ,'cursor: default;'
					# ,'overflow: hidden;'
					,uRV$styles_slicer_y_div
				)
				,shiny::tags$div(
					style = paste0(
						uRV$styles_slicer_y_chart
						,'top: ', ceiling(height_static_charts*0.22), 'px;'
						#This MUST be placed below the universal style to overwrite the default one.
						,'z-index: 99;'
					)
					,shiny::tags$div(
						style = paste0(
							'width: 20px;'
							,'height: ', floor(height_static_charts*0.78-40), 'px;'
						)
						,do.call(echarts4r::e_grid
							,append(
								list(e = uRV$slicer_y_chart)
								,append(
									uRV$grid_slicer_y_chart
									,list(height = paste0(floor(height_static_charts*0.78-40), 'px'))
								)
							)
						)
					)
				)
				,shiny::tags$div(
					style = paste0(
						uRV$styles_slicer_y_slider
						,'width: 20px;'
						,'right: 10px;'
						# ,'height: ',ceiling(height_static_charts*0.78-40+34),'px;'
						# ,'top: ',ceiling(height_static_charts*0.22-17),'px;'
						,'height: ', ceiling(height_static_charts*0.78-40), 'px;'
						,'top: ', ceiling(height_static_charts*0.22), 'px;'
					)
					,shiny::fillCol(
						flex = c(
							round(100*cover_y_upper/cover_y_len, 2)
							,round(100*(cover_y_len - cover_y_upper - cover_y_lower)/cover_y_len, 2)
							,round(100*cover_y_lower/cover_y_len, 2)
						)
						,shiny::tags$div(
							style = paste0(
								'background-color: rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.5);'
								,'width: 100%;'
								,'height: 100%;'
								,'color: rgba(0,0,0,0);'
							)
						)
						,shiny::tags$div(
							style = paste0(
								'background-color: rgba(10,10,10,0.05);'
								,'width: 100%;'
								,'height: 100%;'
								,'color: rgba(0,0,0,0);'
							)
						)
						,shiny::tags$div(
							style = paste0(
								'background-color: rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.5);'
								,'width: 100%;'
								,'height: 100%;'
								,'color: rgba(0,0,0,0);'
							)
						)
					)
					# shinyWidgets::noUiSliderInput(
					# 	inputId = ns('slicer_y_out')
					# 	,min = uRV$slicer_inf$min_y_scatter, max = uRV$slicer_inf$max_y_scatter
					# 	,value = c(uRV$chart_y_min,uRV$chart_y_max)
					# 	,tooltips = FALSE
					# 	,connect = c(TRUE, FALSE, TRUE)
					# 	,color = paste0('rgba(',paste0(uRV$c_rgb_y, collapse = ','),',0.5)')
					# 	,orientation = 'vertical'
					# 	,direction = 'rtl'
					# 	,width = 30
					# 	,height = paste0(ceiling(height_static_charts*0.78-40),'px')
					# )
				)
			)
		}

		#800. Update the grid height of the charts
		jp_x <- do.call(echarts4r::e_grid
			,append(
				list(e = uRV$jp_x)
				,append(
					uRV$grid_x
					,list(height = paste0(height_static_charts*0.22-15, 'px'))
				)
			)
		)
		jp_y <- do.call(echarts4r::e_grid
			,append(
				list(e = uRV$jp_y)
				,append(
					uRV$grid_y
					,list(height = paste0(height_static_charts*0.78-40, 'px'))
				)
			)
		)
		jp_xy <- do.call(echarts4r::e_grid
			,append(
				list(e = uRV$jp_xy)
				,append(
					uRV$grid_xy
					,list(height = paste0(height_static_charts*0.78-40, 'px'))
				)
			)
		)

		#900. Create the universal outputs
		uRV$module_dt_end <- Sys.time()
		uRV$module_charts[[1]] <- shiny::tagList(
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shiny::tags$div(
				style = paste0(
					'width: ', htmltools::validateCssUnit(width), ';'
					#It is weird that below style can only be applied at this point to take effect.
					,'overflow: hidden;'
				)
				,shiny::fillRow(
					flex = c(NA, 1)
					,height = htmltools::validateCssUnit(height_static)
					,out_slicer_y
					,shiny::fillCol(
						flex = c(1, NA)
						,shiny::fillCol(
							flex = c(22, 78)
							,shiny::fillRow(
								flex = c(78, 22)
								,shiny::tags$div(
									style = paste0('width: 100%; height: ', height_static_charts*0.22, 'px;')
									,jp_x
								)
								,shiny::tags$div(
									style = paste0(
										'position: relative;'
										,'width: 100%;'
										,'height: ', height_static_charts*0.22, 'px;'
									)
								)
							)
							,fillRow(
								flex = c(78, 22)
								,shiny::tags$div(
									style = paste0('width: 100%; height: ', height_static_charts*0.78, 'px;')
									,jp_xy
								)
								,shiny::tags$div(
									style = paste0('width: 100%; height: ', height_static_charts*0.78, 'px;')
									,jp_y
								)
							)
						)
						,out_slicer_x
					)
				)
			)
		)

		#950. Send a message to user
		#It is tested that in [shinyWidgets v0.5.0], this cannot popup in the internal browser.
		shinyWidgets::sendSweetAlert(
			session
			,title = 'Success!'
			,text = 'Snapshot has been saved to system!'
			,type = 'success'
			,btn_labels = 'OK'
			,btn_colors = uRV$col_s
			,html = FALSE
			,closeOnClickOutside = TRUE
			,showCloseButton = FALSE
			,width = NULL
		)
	})

	#700. Monitor the mouse actions upon the charts
	#701. Observe the source data change due to the slicers
	shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_HideSlicer
			input$uWg_AB_ResetSlicer
			uRV$chart_x_min
			uRV$chart_x_max
			uRV$chart_y_min
			uRV$chart_y_max

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				uRV$jp_df_draw <- uRV$jp_df
				if (!is.null(uRV$chart_x_min)){
					uRV$jp_df_draw <- uRV$jp_df_draw %>% dplyr::filter(x >= uRV$chart_x_min)
				}
				if (!is.null(uRV$chart_x_max)){
					uRV$jp_df_draw <- uRV$jp_df_draw %>% dplyr::filter(x <= uRV$chart_x_max)
				}
				if (!is.null(uRV$chart_y_min)){
					uRV$jp_df_draw <- uRV$jp_df_draw %>% dplyr::filter(y >= uRV$chart_y_min)
				}
				if (!is.null(uRV$chart_y_max)){
					uRV$jp_df_draw <- uRV$jp_df_draw %>% dplyr::filter(y <= uRV$chart_y_max)
				}
				uRV$inf_draw <- genHistInf(uRV$jp_df_draw)
				#Align the same option in the function [base::hist]
				uRV$jp_df_draw$mids_y <- cut(
					uRV$jp_df_draw$y
					,uRV$inf_draw$jp_y_prep$breaks
					,labels = uRV$inf_draw$jp_y_prep_df$c_mids
					,include.lowest = TRUE
				)
				uRV$jp_df_draw$mids_x <- cut(
					uRV$jp_df_draw$x
					,uRV$inf_draw$jp_x_prep$breaks
					,labels = uRV$inf_draw$jp_x_prep_df$c_mids
					,include.lowest = TRUE
				)
				uRV$jp_yh <- uRV$inf_draw$jp_y_prep_df
				uRV$jp_xh <- uRV$inf_draw$jp_x_prep_df
			})
		}
		# ,priority = 900
	)

	#710. Observe the highlights in response to the clicks/brush on the charts
	#The reason why not conbine this code block with above ones is that we DO NOT need to re-execute all above,
	# when we only need to re-execute this block in terms of certain events
	#The callback value can be found on the official website:
	#[Quote: https://echarts4r.john-coene.com/articles/shiny.html ]
	#711. Actions when the click on scatter plot
	shiny::observeEvent(input$chart_xy_clicked_data, {
		if (length(input$chart_xy_clicked_data) == 0) return()
		shiny::isolate({
			#100. Inverse the flag when current point is clicked
			uRV$jp_df_draw[
				which(
					uRV$jp_df_draw$x == input$chart_xy_clicked_data$value[[1]]
					& uRV$jp_df_draw$y == input$chart_xy_clicked_data$value[[2]]
				)
				,'clicked'
			] <- !uRV$jp_df_draw[
				which(
					uRV$jp_df_draw$x == input$chart_xy_clicked_data$value[[1]]
					& uRV$jp_df_draw$y == input$chart_xy_clicked_data$value[[2]]
				)
				,'clicked'
			]

			#999. Debug
			if (fDebug){
				message('Clicked: data=[', paste0(input$chart_xy_clicked_data$value, collapse = ','), ']')
			}
		})
	})

	#712. Actions when the click on y-histogram
	shiny::observeEvent(input$chart_y_clicked_data, {
		if (length(input$chart_y_clicked_data) == 0) return()
		shiny::isolate({
			uRV$jp_yh[
				which(uRV$jp_yh$c_mids == input$chart_y_clicked_data$value[[2]])
				,'clicked'
			] <- !uRV$jp_yh[
				which(uRV$jp_yh$c_mids == input$chart_y_clicked_data$value[[2]])
				,'clicked'
			]
			# uRV$y_click(uRV$y_click()+1)

			#999. Debug
			if (fDebug){
				message('Clicked: values=[', input$chart_y_clicked_data$value[[2]], ']')
				message('Clicked: clicked=[', paste0(uRV$jp_yh$clicked, collapse = '|'), ']')
			}
		})
	})

	#713. Actions when the click on x-histogram
	shiny::observeEvent(input$chart_x_clicked_data, {
		if (length(input$chart_x_clicked_data) == 0) return()
		shiny::isolate({
			uRV$jp_xh[
				which(uRV$jp_xh$c_mids == input$chart_x_clicked_data$value[[1]])
				,'clicked'
			] <- !uRV$jp_xh[
				which(uRV$jp_xh$c_mids == input$chart_x_clicked_data$value[[1]])
				,'clicked'
			]
			# uRV$x_click(uRV$x_click()+1)

			#999. Debug
			if (fDebug){
				message('Clicked: values=[', input$chart_x_clicked_data$value[[1]], ']')
				message('Clicked: clicked=[', paste0(uRV$jp_xh$clicked,collapse = '|'), ']')
			}
		})
	})

	#715. Actions when the brush on scatter plot is in effect
	shiny::observeEvent(input$chart_xy_brush, {
		if (length(input$chart_xy_brush) == 0) return()
		shiny::isolate({
			#100. Retrieve the brushed data indexes
			#Use function [str] to investigate the result
			#Below variable is converted to a [vector], while the default starting point in Echarts is 0
			#We add all indexes by 1 to facilitate the search in R
			#It is verified that the brush area counts the index from: [left] to [right], then [top] to [bottom]
			uRV$b_selected <- input$chart_xy_brush$batch$selected[[1]]$dataIndex %>% unlist() + 1
			# if (length(uRV$b_selected) == 0) return()

			#300. Sort the original data in the order: [left] to [right], then [top] to [bottom]
			b_df <- uRV$jp_df_draw %>%
				dplyr::select(x, y, brushed) %>%
				dplyr::arrange(x, desc(y)) %>%
				dplyr::mutate(krow = dplyr::row_number())
			# message(str(b_df))
			# message(str(uRV$b_selected))

			#500. Overwrite the flag of [brushed] as it already has a highlight effect
			b_df[b_df$krow %in% uRV$b_selected, 'brushed'] <- TRUE
			b_df[!(b_df$krow %in% uRV$b_selected), 'brushed'] <- FALSE

			#700. Update the original data for plotting
			uRV$jp_df_brush <- uRV$jp_df_draw %>%
				dplyr::select(x, y, mids_x, mids_y) %>%
				dplyr::inner_join(dplyr::select(b_df, -krow), by = c('x', 'y'))
			# message(str(uRV$jp_df_brush))

			#999. Debug
			if (fDebug){
				message(str(uRV$b_selected))
				message('Brushed: Selected=[', uRV$b_selected, ']')
			}
		})
	})

	#720. Prepare data after mouse clicks
	#721. Observe whether there are clicked points on scatter plot
	shiny::observe(
		{
			#100. Take dependencies
			uRV$jp_df_draw
			input$chart_xy_clicked_data

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#100. Handle the case when all/none of the data points are clicked
				if (all(uRV$jp_df_draw$clicked) | all(!uRV$jp_df_draw$clicked)) {
					#100. Skip the spotlights on scatter plot
					uRV$xy_mark <- NULL

					#500. Skip the spotlights on histograms
					uRV$x_dp <- NULL
					uRV$y_dp <- NULL
				} else {
					#100. Prepare the area spotlight on scatter plot
					xy_mark_click <- uRV$jp_df_draw %>% dplyr::filter(clicked)
					uRV$xy_mark <- lapply(1:nrow(xy_mark_click), function(i){
						list(#This list defines the first coordinate, which might be on the upper-right side
							itemStyle = list(
								color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
							)
							,coord = list(xy_mark_click$x[[i]], xy_mark_click$y[[i]])
						)
					})

					#500. Prepare the highlighted bars on histograms
					#510. Retrieve the markArea information in terms of the spotlighted points on the scatter plot
					x_dp <- uRV$jp_xh %>% dplyr::filter(c_mids %in% uRV$jp_df_draw$mids_x[which(uRV$jp_df_draw$clicked)])
					y_dp <- uRV$jp_yh %>% dplyr::filter(c_mids %in% uRV$jp_df_draw$mids_y[which(uRV$jp_df_draw$clicked)])

					#570. Create options to highlight on histograms
					uRV$x_dp <- lapply(1:nrow(x_dp), function(i){
						#Below list defines a set of coordinates
						list(
							#[Example: https://gallery.echartsjs.com/editor.html?c=xHy3vdauzm ]
							itemStyle = list(
								color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderColor = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderWidth = 0.2
							)
							# ,value = 'M'
							,xAxis = x_dp$xAxis[[i]]
							,yAxis = x_dp$counts[[i]]
						)
					})
					#Note: the coordinates on y-histogram have been flipped during drawing
					uRV$y_dp <- lapply(1:nrow(y_dp), function(i){
						#Below list defines a set of coordinates
						list(
							itemStyle = list(
								color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderColor = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderWidth = 0.2
							)
							# ,value = 'M'
							,yAxis = y_dp$yAxis[[i]]
							,xAxis = y_dp$counts[[i]]
						)
					})
				}
			})
		}
		# ,priority = 895
	)

	#722. Observe whether there are clicked points on y-histogram
	shiny::observe(
		{
			#100. Take dependencies
			uRV$jp_yh
			input$chart_y_clicked_data

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				uRV$jp_yf <- uRV$jp_yh

				#100. Handle the case when all/none of the data points are clicked
				if (all(uRV$jp_yh$clicked) | all(!uRV$jp_yh$clicked)) {
					#100. Skip the area highlight on scatter plot
					uRV$xy_highlight_y <- FALSE
					uRV$xy_highlight_y_min <- uRV$inf_draw$min_y_scatter
					uRV$xy_highlight_y_max <- uRV$inf_draw$max_y_scatter

					#500. Consider there is no filter to be applied upon the x-histogram
					uRV$x_highlight <- NULL
				} else {
					#100. Prepare the area highlight on scatter plot
					uRV$xy_highlight_y <- TRUE
					uRV$xy_highlight_y_min <- uRV$jp_yh$mins[which(uRV$jp_yh$clicked)]
					uRV$xy_highlight_y_max <- uRV$jp_yh$maxs[which(uRV$jp_yh$clicked)]

					#500. Prepare the highlighted bars on x-histogram
					#510. Retrieve the new histogram information in terms of the data points filtered by clicking on y-histogram
					xy_dp_x <- uRV$jp_df_draw %>%
						dplyr::filter(mids_y %in% uRV$jp_yh$c_mids[which(uRV$jp_yh$clicked)]) %>%
						dplyr::select(x) %>%
						unlist() %>%
						hist(plot = FALSE, breaks = uRV$inf_draw$jp_x_prep$breaks)

					#570. Create a separate data for highlighting
					uRV$x_highlight <- data.frame(
						mids = xy_dp_x$mids
						,mins = xy_dp_x$breaks[-length(xy_dp_x$breaks)]
						,maxs = xy_dp_x$breaks[-1]
						,counts = xy_dp_x$counts
						,density = xy_dp_x$density
					) %>%
						dplyr::mutate(itemColor = uRV$col_x)

					#590. Add the crucial x-axis for the new histogram
					#It is presumed that this one is identical to that in [uRV$jp_xh]
					uRV$x_highlight$c_mids <- tmcn::strpad(
						as.character(uRV$x_highlight$mids)
						, width = uRV$inf_draw$len_max_x_axis
						, side = 'left'
						, pad = '0'
					)
				}
			})
		}
		# ,priority = 895
	)

	#723. Observe whether there are clicked points on x-histogram
	shiny::observe(
		{
			#100. Take dependencies
			uRV$jp_xh
			input$chart_x_clicked_data

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				uRV$jp_xf <- uRV$jp_xh

				#100. Handle the case when all/none of the data points are clicked
				if (all(uRV$jp_xh$clicked) | all(!uRV$jp_xh$clicked)) {
					#100. Skip the area highlight on scatter plot
					uRV$xy_highlight_x <- FALSE
					uRV$xy_highlight_x_min <- uRV$inf_draw$min_x_scatter
					uRV$xy_highlight_x_max <- uRV$inf_draw$max_x_scatter

					#500. Consider there is no filter to be applied upon the y-histogram
					uRV$y_highlight <- NULL
				} else {
					#100. Prepare the area highlight on scatter plot
					uRV$xy_highlight_x <- TRUE
					uRV$xy_highlight_x_min <- uRV$jp_xh$mins[which(uRV$jp_xh$clicked)]
					uRV$xy_highlight_x_max <- uRV$jp_xh$maxs[which(uRV$jp_xh$clicked)]

					#500. Prepare the highlighted bars on y-histogram
					#510. Retrieve the new histogram information in terms of the data points filtered by clicking on y-histogram
					xy_dp_y <- uRV$jp_df_draw %>%
						dplyr::filter(mids_x %in% uRV$jp_xh$c_mids[which(uRV$jp_xh$clicked)]) %>%
						dplyr::select(y) %>%
						unlist() %>%
						hist(plot = FALSE, breaks = uRV$inf_draw$jp_y_prep$breaks)
					# message(uRV$jp_xh$c_mids[which(uRV$jp_xh$clicked)])
					# message(str(xy_dp_y))

					#570. Create a separate data for highlighting
					uRV$y_highlight <- data.frame(
						mids = xy_dp_y$mids
						,mins = xy_dp_y$breaks[-length(xy_dp_y$breaks)]
						,maxs = xy_dp_y$breaks[-1]
						,counts = xy_dp_y$counts
						,density = xy_dp_y$density
					) %>%
						dplyr::mutate(itemColor = uRV$col_y)

					#590. Add the crucial y-axis for the new histogram
					#It is presumed that this one is identical to that in [uRV$jp_yh]
					uRV$y_highlight$c_mids <- tmcn::strpad(
						as.character(uRV$y_highlight$mids)
						, width = uRV$inf_draw$len_max_y_axis
						, side = 'left'
						, pad = '0'
					)
				}
			})
		}
		# ,priority = 885
	)

	#725. Observe whether there are brushed points on scatter plot
	shiny::observe(
		{
			#100. Take dependencies
			uRV$jp_df_brush

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				if (is.null(uRV$jp_df_brush)) return()
				#100. Handle the case when all/none of the data points are clicked
				if (all(uRV$jp_df_brush$brushed) | all(!uRV$jp_df_brush$brushed)) {
					#500. Skip the spotlights on histograms
					uRV$x_br <- NULL
					uRV$y_br <- NULL
				} else {
					#500. Prepare the highlighted bars on histograms
					#510. Retrieve the markArea information in terms of the spotlighted points on the scatter plot
					x_br <- uRV$jp_xh %>% dplyr::filter(c_mids %in% uRV$jp_df_brush$mids_x[which(uRV$jp_df_brush$brushed)])
					y_br <- uRV$jp_yh %>% dplyr::filter(c_mids %in% uRV$jp_df_brush$mids_y[which(uRV$jp_df_brush$brushed)])

					#570. Create options to highlight on histograms
					uRV$x_br <- lapply(1:nrow(x_br), function(i){
						#Below list defines a set of coordinates
						list(
							#[Example: https://gallery.echartsjs.com/editor.html?c=xHy3vdauzm ]
							itemStyle = list(
								color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderColor = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderWidth = 0.2
							)
							# ,value = 'M'
							,xAxis = x_br$xAxis[[i]]
							,yAxis = x_br$counts[[i]]
						)
					})
					#Note: the coordinates on y-histogram have been flipped during drawing
					uRV$y_br <- lapply(1:nrow(y_br), function(i){
						#Below list defines a set of coordinates
						list(
							itemStyle = list(
								color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderColor = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
								,borderWidth = 0.2
							)
							# ,value = 'M'
							,yAxis = y_br$yAxis[[i]]
							,xAxis = y_br$counts[[i]]
						)
					})
					# message(str(uRV$x_br))
					# message(str(uRV$y_br))
				}
			})
		}
		# ,priority = 855
	)

	#750. Prepare data when there are highlighted parts on the charts
	#752. Observe whether there is highlighted data on y-histogram
	shiny::observe(
		{
			#100. Take dependencies
			uRV$y_highlight
			input$chart_y_clicked_data

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#900. Add 0.5 alpha to the rest of data points if any one is clicked
				if (is.null(uRV$y_highlight)) {
					#When there is no active highlight on y-histogram
					uRV$jp_yh$itemColor[uRV$jp_yh$clicked] <- uRV$col_y
					uRV$jp_yh$itemColor[!uRV$jp_yh$clicked] <- paste0('rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.5)')
					if (nrow(dplyr::filter(uRV$jp_yh, clicked))==0) uRV$jp_yh$itemColor <- uRV$col_y
				} else {
					#When there is any active highlight on x-histogram
					uRV$jp_yh$itemColor[uRV$jp_yh$clicked] <- paste0('rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.5)')
					uRV$jp_yh$itemColor[!uRV$jp_yh$clicked] <- paste0('rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.2)')
					if (nrow(dplyr::filter(uRV$jp_yh, clicked))==0)
						uRV$jp_yh$itemColor <- paste0('rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.5)')
				}

				#999. Debug
				if (fDebug){
					message('Highlighted: itemColor=[', paste0(uRV$jp_yh$itemColor, collapse = '|'), ']')
				}
			})
		}
		# ,priority = 875
	)

	#753. Observe whether there is highlighted data on x-histogram
	shiny::observe(
		{
			#100. Take dependencies
			uRV$x_highlight
			input$chart_x_clicked_data

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#900. Add 0.5 alpha to the rest of data points if any one is clicked
				if (is.null(uRV$x_highlight)) {
					#When there is no active highlight on y-histogram
					uRV$jp_xh$itemColor[uRV$jp_xh$clicked] <- uRV$col_x
					uRV$jp_xh$itemColor[!uRV$jp_xh$clicked] <- paste0('rgba(', paste0(uRV$c_rgb_x, collapse = ','), ',0.5)')
					if (nrow(dplyr::filter(uRV$jp_xh, clicked))==0) uRV$jp_xh$itemColor <- uRV$col_x
				} else {
					#When there is any active highlight on x-histogram
					uRV$jp_xh$itemColor[uRV$jp_xh$clicked] <- paste0('rgba(', paste0(uRV$c_rgb_x, collapse = ','), ',0.5)')
					uRV$jp_xh$itemColor[!uRV$jp_xh$clicked] <- paste0('rgba(', paste0(uRV$c_rgb_x, collapse = ','), ',0.2)')
					if (nrow(dplyr::filter(uRV$jp_xh, clicked))==0)
						uRV$jp_xh$itemColor <- paste0('rgba(',paste0(uRV$c_rgb_x, collapse = ','),',0.5)')
				}

				#999. Debug
				if (fDebug){
					message('Highlighted: itemColor=[', paste0(uRV$jp_xh$itemColor, collapse = '|'), ']')
				}
			})
		}
		# ,priority = 865
	)

	#770. Prepare statements/options for the highlighted parts
	#772. Set the coordinates to be highlighted on the y-axis scatter plot
	shiny::observe(
		{
			#100. Take dependencies
			uRV$xy_highlight_y
			uRV$xy_highlight_y_min
			uRV$xy_highlight_y_max

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#100. Create the set of coordinates in the scatter area
				if (!uRV$xy_highlight_y) {
					uRV$coord_y <- NULL
				} else {
					uRV$coord_y <- lapply(1:length(uRV$xy_highlight_y_min), function(i){
						#Below list defines a set of coordinates
						list(
							list(#This list defines the first coordinate, which might be on the upper-right side
								#[Example: https://gallery.echartsjs.com/editor.html?c=xHy3vdauzm ]
								itemStyle = list(
									color = paste0('rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.05)')
									,borderColor = paste0('rgba(', paste0(uRV$c_rgb_y, collapse = ','), ',0.05)')
									,borderWidth = 0.5
									,borderType = 'dashed'
								)
								,coord = list(uRV$inf_draw$min_x_scatter, uRV$xy_highlight_y_min[[i]])
							)
							,list(#This list defines the second coordinate, which might be on the lower-left side
								coord = list(uRV$inf_draw$max_x_scatter, uRV$xy_highlight_y_max[[i]])
							)
						)
					})
				}
			})
		}
		# ,priority = 790
	)

	#773. Set the coordinates to be highlighted on the x-axis scatter plot
	shiny::observe(
		{
			#100. Take dependencies
			uRV$xy_highlight_x
			uRV$xy_highlight_x_min
			uRV$xy_highlight_x_max

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#100. Create the set of coordinates in the scatter area
				if (!uRV$xy_highlight_x) {
					uRV$coord_x <- NULL
				} else {
					uRV$coord_x <- lapply(1:length(uRV$xy_highlight_x_min), function(i){
						#Below list defines a set of coordinates
						list(
							list(#This list defines the first coordinate, which might be on the upper-right side
								itemStyle = list(
									color = paste0('rgba(', paste0(uRV$c_rgb_x, collapse = ','), ',0.05)')
									,borderColor = paste0('rgba(', paste0(uRV$c_rgb_x, collapse = ','), ',0.05)')
									,borderWidth = 0.5
									,borderType = 'dashed'
								)
								,coord = list(uRV$xy_highlight_x_min[[i]], uRV$inf_draw$min_y_scatter)
							)
							,list(#This list defines the second coordinate, which might be on the lower-left side
								coord = list(uRV$xy_highlight_x_max[[i]], uRV$inf_draw$max_y_scatter)
							)
						)
					})
				}
				# message(str(uRV$coord_x))
			})
		}
		# ,priority = 740
	)

	#775. Prepare to mark the points if there is any [cross] when x and y histograms are both clicked somewhere at the same time
	shiny::observe(
		{
			#100. Take dependencies
			uRV$jp_xh
			uRV$jp_yh

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				if (all(uRV$jp_xh$clicked) | all(!uRV$jp_xh$clicked) | all(uRV$jp_yh$clicked) | all(!uRV$jp_yh$clicked)) {
					uRV$xy_mark_cross <- NULL
				} else {
					uRV$xy_mark_cross <- uRV$jp_df_draw %>%
						dplyr::filter(
							mids_x %in% uRV$jp_xh$c_mids[which(uRV$jp_xh$clicked)]
							, mids_y %in% uRV$jp_yh$c_mids[which(uRV$jp_yh$clicked)]
						)
				}
			})
		}
		# ,priority = 590
	)

	#800. Prepare the [echarts4r] object for output
	#880. Draw the initial charts based on filters and highlights
	#The reason why not conbine this code block with above ones is that we DO NOT need to re-execute all above,
	# when we only need to re-execute this block in terms of certain events
	#881. Scatter Plot
	shiny::observe(
		{
			#100. Take dependencies
			uRV$jp_df_draw
			uRV$inf_draw
			uRV$coord_y
			uRV$coord_x
			uRV$xy_mark
			uRV$xy_mark_cross

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#100. Create highlights if any
				# message(str(append(uRV$coord_y,uRV$coord_x)))
				#110. Mark area
				if (is.null(uRV$coord_y) & is.null(uRV$coord_x)) {
					xy_markArea <- NULL
				} else {
					xy_markArea <- list(
						silent = TRUE
						,data = append(uRV$coord_y, uRV$coord_x)
					)
				}

				#120. Mark points
				if (is.null(uRV$xy_mark)) {
					xy_markPoint <- NULL
				} else {
					xy_markPoint <- list(
						silent = TRUE
						,symbolSize = 40
						,emphasis = list(
							label = list(
								show = TRUE
							)
						)
						,data = uRV$xy_mark
					)
				}

				#300. Create scatter plot
				uRV$jp_xy <- uRV$jp_df_draw %>%
					echarts4r::e_charts(x, height = uRV$height_charts*0.78) %>%
					echarts4r::e_scatter(
						y
						,legend = FALSE
						,name = yname
						# ,itemStyle = list(opacity = .75)
						,symbolSize = 10
						,color = uRV$col_s
						,markArea = xy_markArea
						,markPoint = xy_markPoint
						#Since Echarts5.0 we can only define the features here WITHOUT the [trigger],
						# hence we leave [trigger] to [e_tooltip] at later steps
						,tooltip = modifyList(
							uRV$attr_tooltips
							,list(
								formatter = htmlwidgets::JS(paste0(
									'function(params){'
										,'return('
											,'"<strong>',yname,'</strong> : " + echarts.format.addCommas('
												,'params.value[1].toFixed('
													,uRV$inf_draw$fmtlen_y_axis
												,')'
											,') + "<br/>"'
											,'+ "<strong>',xname,'</strong> : " + echarts.format.addCommas('
												,'params.value[0].toFixed('
													,uRV$inf_draw$fmtlen_x_axis
												,')'
											,')'
										,');'
									,'}'
								))
							)
						)
						,x_index = 0
						,y_index = 0
					)

				#500. Draw a new scatter plot as highlight when x and y histograms are clicked at the same time
				if (!is.null(uRV$xy_mark_cross)){
					uRV$jp_xy <- uRV$jp_xy %>%
						echarts4r::e_data(uRV$xy_mark_cross, x) %>%
						echarts4r::e_effect_scatter(
							y
							,legend = FALSE
							,name = paste0(yname,'-CrossXY')
							,symbolSize = 10
							,color = uRV$col_s
							,tooltip = modifyList(
								uRV$attr_tooltips
								,list(
									formatter = htmlwidgets::JS(paste0(
										'function(params){'
											,'return('
												,'"<strong>[Cross]',yname,'</strong> : " + echarts.format.addCommas('
													,'params.value[1].toFixed('
														,uRV$inf_draw$fmtlen_y_axis
													,')'
												,') + "<br/>"'
												,'+ "<strong>[Cross]',xname,'</strong> : " + echarts.format.addCommas('
													,'params.value[0].toFixed('
														,uRV$inf_draw$fmtlen_x_axis
													,')'
												,')'
											,');'
										,'}'
									))
								)
							)
							,x_index = 0
							,y_index = 0
						)
				}

				#800. Add options for axes
				#We have to do this AFTER appending an [effectScatter] so that the axes will not be abnormally shifted!
				uRV$jp_xy <- uRV$jp_xy %>%
					echarts4r::e_y_axis(
						index = 0
						,gridIndex = 0
						,name = yname
						,min = uRV$inf_draw$min_y_scatter
						,max = uRV$inf_draw$max_y_scatter
						,interval = uRV$inf_draw$ntvl_y_scatter
						,show = TRUE
						,axisLabel = list(
							rotate = 90
							,formatter = htmlwidgets::JS(paste0(
								'function(value, index){'
									,'return('
										,'(value/',1000^uRV$inf_draw$logK_y0_whole,').toFixed(',uRV$inf_draw$nfrac_y0,')'
										,' + "',uRV$inf_draw$str_unit_y0,'"'
									,');'
								,'}'
							))
						)
						,splitLine = list(
							lineStyle = list(
								type = 'dashed'
							)
						)
						,nameGap = 20
						,nameLocation = 'center'
					) %>%
					echarts4r::e_x_axis(
						index = 0
						,gridIndex = 0
						,name = xname
						,min = uRV$inf_draw$min_x_scatter
						,max = uRV$inf_draw$max_x_scatter
						,interval = uRV$inf_draw$ntvl_x_scatter
						,show = TRUE
						,axisLabel = list(
							formatter = htmlwidgets::JS(paste0(
								'function(value, index){'
									,'return('
										,'(value/',1000^uRV$inf_draw$logK_x0_whole,').toFixed(',uRV$inf_draw$nfrac_x0,')'
										,' + "',uRV$inf_draw$str_unit_x0,'"'
									,');'
								,'}'
							))
						)
						,splitLine = list(
							lineStyle = list(
								type = 'dashed'
							)
						)
						,nameGap = 18
						,nameLocation = 'center'
					)

				#900. Add other gadgets
				uRV$jp_xy <- uRV$jp_xy %>%
					echarts4r::e_toolbox(
						feature = list(
							brush = list(
								type = list('clear', 'keep', 'polygon', 'rect')
							)
						)
						,iconStyle = list(
							color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
						)
						,emphasis = list(
							iconStyle = list(
								color = uRV$col_s
								,textPosition = 'top'
								,textAlign = 'left'
								,textFill = 'rgba(0,0,0,0.95)'
								,textBackgroundColor = 'rgba(255,255,255,0.95)'
							)
						)
						,left = 15
						,bottom = 0
					) %>%
					echarts4r::e_brush(
						#Ensure only the points on the primary grid can be brushed
						seriesIndex = 0
						# ,x_index = 0
						# ,y_index = 0
						,brushMode = 'multiple'
						,brushStyle = list(
							borderWidth = 0.5
							,color = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.2)')
							,borderColor = paste0('rgba(', paste0(uRV$c_rgb_s, collapse = ','), ',0.5)')
						)
						#Prevent the input values to be transmitted too frequently
						,throttleType = 'debounce'
						#In milliseconds
						,throttleDelay = 300
					) %>%
					echarts4r::e_show_loading() %>%
					#There is no need to capture below actions excessively
					# echarts4r::e_capture('click') %>%
					# echarts4r::e_capture('datarangeselected') %>%
					# echarts4r::e_capture('selectchanged') %>%
					# echarts4r::e_capture('brush') %>%
					echarts4r::e_tooltip(
						trigger = 'item'
						,axisPointer = list(
							type = 'cross'
							,label = uRV$attr_tooltips
						)
					)
			})
		}
		# ,priority = 190
	)

	#882. Histogram of y-axis
	shiny::observe(
		{
			#100. Take dependencies
			uRV$inf_draw
			uRV$jp_yf
			uRV$y_highlight
			uRV$y_dp
			uRV$y_br

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#100. Create options if any
				#110. Mark points
				if (is.null(uRV$y_dp) & is.null(uRV$y_br)) {
					y_markPoint <- NULL
				} else {
					y_markPoint <- list(
						silent = TRUE
						,symbolSize = 15
						,symbolRotate = -90
						,label = list(
							#This padding is BEFORE the flip!!!
							padding = list(0,0,5,4)
							,rotate = -90
							,fontSize = 6
						)
						,data = unique(append(uRV$y_dp, uRV$y_br))
					)
				}

				#700. Draw the chart
				uRV$jp_y <- uRV$jp_yf %>%
					echarts4r::e_charts(c_mids, height = uRV$height_charts*0.78) %>%
					echarts4r::e_bar(
						counts
						,legend = FALSE
						,name = yname
						,markPoint = y_markPoint
						,barWidth = '90%'
						#Inject the JS code to set different colors to all bars respectively
						#[Quote: https://www.php.cn/js-tutorial-409788.html ]
						,itemStyle = list(
							color = htmlwidgets::JS(paste0(
								'function(params){'
									,'var colorlst = ["',paste0(uRV$jp_yf$itemColor,collapse = '","'),'"];'
									,'return(colorlst[params.dataIndex]);'
								,'}'
							))
						)
						,tooltip = modifyList(
							uRV$attr_tooltips
							,list(
								formatter = htmlwidgets::JS(paste0(
									'function(params){'
										,'return('
											,'"<strong>',yname,'</strong><br/>"'
											,'+ "<i>[" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed('
													,uRV$inf_draw$fmtlen_y_axis
												,')'
											,') + "]</i>"'
											,'+ " : " + echarts.format.addCommas(params.value[0])'
										,');'
									,'}'
								))
							)
						)
						,x_index = 0
						,y_index = 0
					) %>%
					echarts4r::e_y_axis(
						index = 0
						,gridIndex = 0
						,show = TRUE
						,axisLabel = list(
							formatter = htmlwidgets::JS(paste0(
								'function(value, index){'
									# ,'if (index == 0 || index == 1){return '';}'
									,'if (index == 0){return "";}'
									,'return('
										,'(value/',1000^uRV$inf_draw$logK_x1_whole,').toFixed('
											,uRV$inf_draw$nfrac_x1
										,') + "',uRV$inf_draw$str_unit_x1,'"'
									,');'
								,'}'
							))
							,rotate = -90
						)
						,splitLine = list(
							lineStyle = list(
								type = 'dashed'
							)
						)
						,axisPointer = list(
							show = TRUE
							,triggerTooltip = FALSE
						)
					) %>%
					echarts4r::e_x_axis(
						index = 0
						,gridIndex = 0
						,show = FALSE
						,axisLabel = list(show = FALSE)
						,axisTick = list(show = FALSE)
						,axisPointer = list(show = FALSE)
					) %>%
					#900. Flip the coordinates
					echarts4r::e_flip_coords()

				#800. Draw a new histogram as highlight when x-histogram is clicked
				if (!is.null(uRV$y_highlight)){
					# message(glimpse(uRV$y_highlight))
					uRV$jp_y <- uRV$jp_y %>%
						echarts4r::e_data(uRV$y_highlight, counts) %>%
						echarts4r::e_bar(
							c_mids
							,legend = FALSE
							,name = paste0(yname,'-Filtered')
							,barWidth = '90%'
							#Inject the JS code to set different colors to all bars respectively
							#[Quote: https://www.php.cn/js-tutorial-409788.html ]
							,itemStyle = list(
								color = htmlwidgets::JS(paste0(
									'function(params){'
										,'var colorlst = ["',paste0(uRV$y_highlight$itemColor,collapse = '","'),'"];'
										,'return(colorlst[params.dataIndex]);'
									,'}'
								))
							)
							,tooltip = modifyList(
								uRV$attr_tooltips
								,list(
									formatter = htmlwidgets::JS(paste0(
										'function(params){'
											,'return('
												,'"<strong>',paste0(yname,'-Filtered'),'</strong><br/>"'
												,'+ "<i>[" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed('
														,uRV$inf_draw$fmtlen_y_axis
													,')'
												,') + "]</i>"'
												,'+ " : " + echarts.format.addCommas(params.value[0])'
											,');'
										,'}'
									))
								)
							)
							,x_index = 0
							,y_index = 1
						) %>%
						echarts4r::e_x_axis(
							index = 1
							,gridIndex = 0
							,show = TRUE
							,axisLabel = list(
								formatter = htmlwidgets::JS(paste0(
									'function(value, index){'
										# ,'if (index == 0 || index == 1){return '';}'
										,'if (index == 0){return "";}'
										,'return('
											,'(value/',1000^uRV$inf_draw$logK_x1_whole,').toFixed('
												,uRV$inf_draw$nfrac_x1
											,') + "',uRV$inf_draw$str_unit_x1,'"'
										,');'
									,'}'
								))
								,rotate = -90
							)
							,splitLine = list(
								lineStyle = list(
									type = 'dashed'
								)
							)
							,axisPointer = list(
								show = TRUE
								,triggerTooltip = FALSE
							)
						) %>%
						echarts4r::e_y_axis(
							index = 1
							,gridIndex = 0
							,show = FALSE
							,data = uRV$y_highlight$c_mids
							,type = 'category'
							,axisLabel = list(show = FALSE)
							,axisTick = list(show = FALSE)
							,axisPointer = list(show = FALSE)
						)
				}

				#900. Add other gadgets
				uRV$jp_y <- uRV$jp_y %>%
					echarts4r::e_show_loading() %>%
					echarts4r::e_tooltip(
						trigger = 'item'
						,axisPointer = list(
							type = 'line'
							,axis = 'x'
							,label = uRV$attr_tooltips
						)
					)
			})
		}
		# ,priority = 180
	)

	#883. Histogram of x-axis
	shiny::observe(
		{
			#100. Take dependencies
			uRV$inf_draw
			uRV$jp_xf
			uRV$x_highlight
			uRV$x_dp
			uRV$x_br

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#100. Create options if any
				#110. Mark points
				if (is.null(uRV$x_dp) & is.null(uRV$x_br)) {
					x_markPoint <- NULL
				} else {
					x_markPoint <- list(
						silent = TRUE
						,symbolSize = 15
						,label = list(
							# padding = list(0,0,5,4)
							fontSize = 6
						)
						,data = unique(append(uRV$x_dp, uRV$x_br))
					)
				}

				#700. Draw the chart
				uRV$jp_x <- uRV$jp_xf %>%
					echarts4r::e_charts(c_mids, height = uRV$height_charts*0.22) %>%
					echarts4r::e_bar(
						counts
						,legend = FALSE
						,name = xname
						,markPoint = x_markPoint
						,barWidth = '90%'
						,itemStyle = list(
							color = htmlwidgets::JS(paste0(
								'function(params){'
									,'var colorlst = ["',paste0(uRV$jp_xf$itemColor,collapse = '","'),'"];'
									,'return(colorlst[params.dataIndex]);'
								,'}'
							))
						)
						,tooltip = modifyList(
							uRV$attr_tooltips
							,list(
								formatter = htmlwidgets::JS(paste0(
									'function(params){'
										,'return('
											,'"<strong>',xname,'</strong><br/>"'
											,'+ "<i>[" + echarts.format.addCommas(parseFloat(params.value[0]).toFixed('
													,uRV$inf_draw$fmtlen_x_axis
												,')'
											,') + "]</i>"'
											,'+ " : " + echarts.format.addCommas(params.value[1])'
										,');'
									,'}'
								))
							)
						)
						,x_index = 0
						,y_index = 0
					) %>%
					echarts4r::e_y_axis(
						index = 0
						,gridIndex = 0
						,show = TRUE
						,axisLabel = list(
							formatter = htmlwidgets::JS(paste0(
								'function(value, index){'
									# ,'if (index == 0 || index == 1){return '';}'
									,'if (index == 0){return "";}'
									,'return('
										,'(value/',1000^uRV$inf_draw$logK_y2_whole,').toFixed('
											,uRV$inf_draw$nfrac_y2
										,') + "',uRV$inf_draw$str_unit_y2,'"'
									,');'
								,'}'
							))
						)
						,splitLine = list(
							lineStyle = list(
								type = 'dashed'
							)
						)
						,axisPointer = list(
							show = TRUE
							,triggerTooltip = FALSE
						)
					) %>%
					echarts4r::e_x_axis(
						index = 0
						,gridIndex = 0
						,show = FALSE
						,axisLabel = list(show = FALSE)
						,axisTick = list(show = FALSE)
						#We have to set [type=none] for unknown reason!!!
						,axisPointer = list(show = FALSE, type = 'none', label = list(show = FALSE))
					)

				#800. Draw a new histogram as highlight when y-histogram is clicked
				if (!is.null(uRV$x_highlight)) {
					uRV$jp_x <- uRV$jp_x %>%
						echarts4r::e_data(uRV$x_highlight, c_mids) %>%
						echarts4r::e_bar(
							counts
							,legend = FALSE
							,name = paste0(xname,'-Filtered')
							,barWidth = '90%'
							,itemStyle = list(
								color = htmlwidgets::JS(paste0(
									'function(params){'
										,'var colorlst = ["',paste0(uRV$x_highlight$itemColor,collapse = '","'),'"];'
										,'return(colorlst[params.dataIndex]);'
									,'}'
								))
							)
							,tooltip = modifyList(
								uRV$attr_tooltips
								,list(
									formatter = htmlwidgets::JS(paste0(
										'function(params){'
											,'return('
												,'"<strong>',paste0(xname,'-Filtered'),'</strong><br/>"'
												,'+ "<i>[" + echarts.format.addCommas(parseFloat(params.value[0]).toFixed('
														,uRV$inf_draw$fmtlen_x_axis
													,')'
												,') + "]</i>"'
												,'+ " : " + echarts.format.addCommas(params.value[1])'
											,');'
										,'}'
									))
								)
							)
							,x_index = 1
							,y_index = 0
						) %>%
						echarts4r::e_y_axis(
							index = 1
							,gridIndex = 0
							,show = TRUE
							,axisLabel = list(
								formatter = htmlwidgets::JS(paste0(
									'function(value, index){'
										# ,'if (index == 0 || index == 1){return '';}'
										,'if (index == 0){return "";}'
										,'return('
											,'(value/',1000^uRV$inf_draw$logK_y2_whole,').toFixed('
												,uRV$inf_draw$nfrac_y2
											,') + "',uRV$inf_draw$str_unit_y2,'"'
										,');'
									,'}'
								))
							)
							,splitLine = list(
								lineStyle = list(
									type = 'dashed'
								)
							)
							,axisPointer = list(
								show = TRUE
								,triggerTooltip = FALSE
							)
						) %>%
						echarts4r::e_x_axis(
							index = 1
							,gridIndex = 0
							,show = FALSE
							,axisLabel = list(show = FALSE)
							,axisTick = list(show = FALSE)
							#We have to set [type=none] for unknown reason!!!
							,axisPointer = list(show = FALSE, type = 'none', label = list(show = FALSE))
						)
				}

				#900. Add other gadgets
				uRV$jp_x <- uRV$jp_x %>%
					echarts4r::e_show_loading() %>%
					echarts4r::e_tooltip(
						trigger = 'item'
						,axisPointer = list(
							type = 'line'
							,axis = 'y'
							,label = uRV$attr_tooltips
						)
					)
			})
		}
		# ,priority = 170
	)

	#899. Draw the final charts
	#The reason why not conbine this code block with above ones is that we DO NOT need to re-execute all above,
	# when we only need to re-execute this block in terms of certain events
	#We put the grid options here so that we can place different options when we need to output static charts
	shiny::observeEvent(uRV$jp_x,{
		output$chart_x <- echarts4r::renderEcharts4r({
			#We pass a list here to sanitize the program
			do.call(echarts4r::e_grid
				,append(
					list(e = uRV$jp_x)
					,append(
						uRV$grid_x
						,list(height = paste0(uRV$height_charts*0.22-15, 'px'))
					)
				)
			)
		})
	})
	shiny::observeEvent(uRV$jp_y,{
		output$chart_y <- echarts4r::renderEcharts4r({
			do.call(echarts4r::e_grid
				,append(
					list(e = uRV$jp_y)
					,append(
						uRV$grid_y
						,list(height = paste0(uRV$height_charts*0.78-40, 'px'))
					)
				)
			)
		})
	})
	shiny::observeEvent(uRV$jp_xy,{
		output$chart_xy <- echarts4r::renderEcharts4r({
			do.call(echarts4r::e_grid
				,append(
					list(e = uRV$jp_xy)
					,append(
						uRV$grid_xy
						,list(height = paste0(uRV$height_charts*0.78-40, 'px'))
					)
				)
			)
		})
	})

	#990. Create the final UI
	output$jplt_main <- shiny::renderUI({
		shiny::tagList(
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shiny::tags$div(
				style = paste0(
					'width: ', htmltools::validateCssUnit(width), ';'
				)
				,shiny::fillRow(
					flex = c(NA, 1)
					,height = htmltools::validateCssUnit(height)

					#100. Put the y-axis slicer on the left with fixed width
					,uRV$uDiv_slicer_y

					#200. Put the combination of primary charts and x-axis slicer on the right filling the width
					,shiny::fillCol(
						flex = c(1, NA)

						#100. Put the primary charts on the top filling the height
						,shiny::fillCol(
							flex = c(22, 78)

							#100. Put the x-histogram and the buttons on the top part
							,shiny::fillRow(
								flex = c(78, 22)

								#100. Put the x-histogram on the left part
								,echarts4r::echarts4rOutput(ns('chart_x'), height = paste0(uRV$height_charts*0.22, 'px'))

								#200. Put the buttons on the right part
								,shiny::tags$div(
									style = paste0(
										#We treat this division as the container for the well-positioned buttons
										'position: relative;'
										,'width: 100%;'
										,'height: ', uRV$height_charts*0.22, 'px;'
									)
									,uRV$uDiv_SaveChart
									,uRV$uDiv_ShowSlicer
									,uRV$uDiv_HideSlicer
									,uRV$uDiv_ResetSlicer
								)
							#End of [fillRow]
							)

							#200. Put the scatter plot and y-histogram on the bottom part
							,fillRow(
								flex = c(78, 22)

								#100. Put the scatter plot on the left part
								,echarts4r::echarts4rOutput(ns('chart_xy'), height = paste0(uRV$height_charts*0.78, 'px'))

								#200. Put the y-histogram on the right part
								,echarts4r::echarts4rOutput(ns('chart_y'), height = paste0(uRV$height_charts*0.78, 'px'))
							)
						#End of [fillCol]
						)

						#200. Put the x-axis slicer on the bottom with fixed height
						,uRV$uDiv_slicer_x
					#End of [fillCol]
					)
				#End of [fillRow]
				)
				# ,shiny::fluidRow(shiny::verbatimTextOutput(ns('clickedvalues')))
			#End of [tags$div]
			)
		#End of [tagList]
		)
	})

	#999. Return the result
	#Next time I may try to append values as instructed below:
	#[Quote: https://community.rstudio.com/t/append-multiple-reactive-output-of-a-shiny-module-to-an-existing-reactivevalue-object-in-the-app/36985/2 ]
	return(
		list(
			CallCounter = shiny::reactive({uRV_finish()})
			,ActionDone = shiny::reactive({uRV$ActionDone})
			,EnvVariables = shiny::reactive({uRV})
		)
	)
}

#[Full Test Program;]
if (FALSE){
	if (interactive()){
		#010. Create envionment.
		#Below program provides the most initial environment and system options for best usage of [omniR]
		source('D:\\R\\autoexec.r')

		omniR <- file.path('D:','R','omniR')
		source(file.path('D:','R','Project','myApp','Func','UI','theme_color_sets.r'),encoding = 'utf-8')
		# source(file.path(omniR,'UsrShinyModules','Stats','UM_JointPlots.r'),encoding = 'utf-8')
		# source(file.path(omniR,'Visualization','noUiSliderInput_EchStyle.r'),encoding = 'utf-8')
		# source(file.path(omniR,'AdvOp','scaleNum.r'),encoding = 'utf-8')

		req_pkg <- deparse(substitute(c(
			shiny, shinyjs, shinydashboard, shinydashboardPlus
			, rmarkdown
		)))
		#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
		req_pkg <- gsub('[[:space:]]', '', req_pkg, perl = T)
		req_pkg <- gsub('^c\\((.+)\\)', '\\1', req_pkg, perl = T)
		req_pkg <- unlist(strsplit(req_pkg, ',', perl = T))

		ui <- shinydashboardPlus::dashboardPage(
			header = shinydashboardPlus::dashboardHeader()
			,sidebar = shinydashboardPlus::dashboardSidebar(
				shinydashboard::sidebarMenu(id = 'left_sidebar'
					#[Icons are from the official page: https://adminlte.io/themes/AdminLTE/pages/UI/icons.html ]
					,shinydashboard::menuItem(
						'Stats Practice'
						,tabName = 'uMI_StatsPr'
						,icon = shiny::icon('bar-chart')
					)
					,shinydashboard::menuItem(
						'Stats Display'
						,tabName = 'uMI_StatsDis'
						,icon = shiny::icon('bar-chart')
					)
				)
			)
			,body = shinydashboard::dashboardBody(
				shinyjs::useShinyjs()
				,shiny::fluidPage(
					#Add identical number of [tabItems] corresponding to the [tabName]s identified in [sidebar]
					shinydashboard::tabItems(
						#Add one [tabItem]
						shinydashboard::tabItem(tabName = 'uMI_StatsPr'
							,shiny::column(width = 8
								,UM_JointPlots_ui('uMod_jplt')
							)
						#End of [tabItem]
						)
						#Add one [tabItem]
						,shinydashboard::tabItem(tabName = 'uMI_StatsDis'
							,shiny::column(width = 12
								,shiny::fluidRow(shiny::uiOutput('showchart'))
								,shiny::fluidRow(shiny::downloadButton('Save','Download Report'))
							)
						#End of [tabItem]
						)
					#End of [tabItems]
					)
				)
			)
			,controlbar = shinydashboardPlus::dashboardControlbar(id = 'controlbar')
			,footer = shinydashboardPlus::dashboardFooter(
				left = 'By Robin Lu Bin'
				,right = 'Shanghai, 2021'
			)
			,title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$jplt <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0)
				,ActionDone = shiny::reactive({FALSE})
				,EnvVariables = shiny::reactive({NULL})
			)

			shiny::observe({
				modout$jplt <- shiny::callModule(
					UM_JointPlots_svr
					,'uMod_jplt'
					,fDebug = FALSE
					,height = 800
					,x = USArrests$UrbanPop
					,y = USArrests$Rape
					,xname = 'UrbanPop'
					,yname = 'Rape'
					,breaks = 'Sturges'
					,colorset = c(
						myApp_themecolorset$s08$p[[length(myApp_themecolorset$s08$p)]]
						,myApp_themecolorset$s03$p[[length(myApp_themecolorset$s03$p)]]
						,myApp_themecolorset$s09$p[[length(myApp_themecolorset$s09$p)]]
					)
				)
			})
			shiny::observeEvent(modout$jplt$CallCounter(),{
				if (modout$jplt$CallCounter() == 0) return()
				message('[jplt$CallCounter()]:',modout$jplt$CallCounter())
				message('[jplt$ActionDone()]:',modout$jplt$ActionDone())
				message('[jplt$EnvVariables]:')
				output$showchart <- shiny::renderUI({modout$jplt$EnvVariables()$module_charts[[1]]})
				#[Quote: https://shiny.rstudio.com/articles/generating-reports.html ]
				output$Save <- shiny::downloadHandler(
					filename = 'JointPlots.html'
					,content = function(file){
						tempReport <- file.path(tempdir(),'JointPlots.Rmd')
						file.copy(file.path(omniR,'UsrShinyModules','Stats','PlotsTpl.Rmd'), tempReport, overwrite = TRUE)
						params <- list(
							module = 'UM_JointPlots'
							,dat = 'USArrests'
							,x = 'UrbanPop'
							,y = 'Rape'
							,charts = modout$jplt$EnvVariables()$module_charts[[1]]
						)
						rmarkdown::render(
							tempReport
							,output_file = file
							,params = params
							,envir = new.env(parent = globalenv())
						)
					}
				)
			})
		}

		shiny::shinyApp(ui, server)
	}

}
