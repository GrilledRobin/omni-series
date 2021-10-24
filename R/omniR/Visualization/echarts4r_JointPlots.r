#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create an [echarts4r] object: [JointPlots], to display the [scatter plot]+[histograms for x and y] on #
#   | both x-axis and y-axis within the same canvas.                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x          :   The input list or vector to be plotted on x-axis                                                                    #
#   |y          :   The input list or vector to be plotted on y-axis                                                                    #
#   |xname      :   The name of x-axis                                                                                                  #
#   |               [Default] [x]                                                                                                       #
#   |yname      :   The name of y-axis                                                                                                  #
#   |               [Default] [y]                                                                                                       #
#   |title      :   The title of the plot                                                                                               #
#   |               [Default] [NULL]                                                                                                    #
#   |breaks     :   The same parameter as in the function [base::hist]. Please check the official document for details.                 #
#   |               [Default] [Sturges]                                                                                                 #
#   |colorset   :   The list or vector of colors to be used to display the elements                                                     #
#   |               [Default] [NULL]                                                                                                    #
#   |samples    :   The number of samples to be extracted from the input data, useful for large data but lack some accuracy             #
#   |               [NULL    ] Draw all points to the scatter plot, which consumes large system resources on large input data           #
#   |               [integers] Extract this number of samples from the input for plotting                                               #
#   |               [Default] [NULL]                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[echarts]  :   The [echarts4r] object which can be used to plot directly in RStudio or rendered in Shiny                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20191207        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |echarts4r, dplyr, tmcn, htmlwidgets                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	echarts4r, dplyr, tmcn, htmlwidgets
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

echarts4r_JointPlots <- function(x, y,
		xname = 'x', yname = 'y', title = NULL, breaks = "Sturges",
		colorset = NULL, samples = NULL
	){
	#010. Parameters
	if (is.null(colorset)) {
		col_s <- NULL
		col_x <- NULL
		col_y <- NULL
	} else {
		col_s <- colorset[[min(length(colorset),1)]]
		col_x <- colorset[[min(length(colorset),2)]]
		col_y <- colorset[[min(length(colorset),3)]]
	}
	map_units <- c(kilo = "K", million = "M", billion = "B", trillion = "T", quintillion = "Q")
	# map_bargap <- c("96%" = 5, "95%" = 6, "65%" = 7, "70%" = 8, "75%" = 9, "80%" = 10, "85%" = 11, "90%" = 12, "95%" = 13)

	#100. Prepare the input data
	jp_df <- data.frame(x = x, y = y)
	if (!is.null(samples)) {
		jp_df <- dplyr::sample_n(jp_df,samples)
	}

	#150. Prepare to scale the numbers on the labels of both axes for the scatter plot
	#151. x-axis
	max_x0 <- max(abs(jp_df$x))
	logK_x0 <- log(max_x0,base = 1000)
	logK_x0_whole <- floor(logK_x0)
	q_x0_len_whole <- nchar(floor(max_x0/1000^logK_x0_whole))
	if (logK_x0_whole < 1) {
		str_unit_x0 <- character(0)
	} else {
		str_unit_x0 <- map_units[[logK_x0_whole]]
	}
	nfrac_x0 <- 3 - q_x0_len_whole

	#152. y-axis
	max_y0 <- max(abs(jp_df$y))
	logK_y0 <- log(max_y0,base = 1000)
	logK_y0_whole <- floor(logK_y0)
	q_y0_len_whole <- nchar(floor(max_y0/1000^logK_y0_whole))
	if (logK_y0_whole < 1) {
		str_unit_y0 <- character(0)
	} else {
		str_unit_y0 <- map_units[[logK_y0_whole]]
	}
	nfrac_y0 <- 3 - q_y0_len_whole

	#200. Prepare the data for histograms
	#210. Only need to extract the information for x-axis rather than draw the histogram separately
	jp_x_prep <- hist(jp_df$x, plot = FALSE, breaks = breaks)
	jp_x_prep_df <- data.frame(
		mids = jp_x_prep$mids,
		counts = jp_x_prep$counts,
		density = jp_x_prep$density
	)
	len_whole_x_axis <- max(nchar(gsub('^\\s*(\\d*)?((\\.)(\\d*))?$','\\1',jp_x_prep$mids,perl = TRUE)))
	len_frac_x_axis <- max(nchar(gsub('^\\s*(\\d*)?((\\.)(\\d*))?$','\\4',jp_x_prep$mids,perl = TRUE)))
	len_max_x_axis <- len_whole_x_axis + len_frac_x_axis + 1
	fmtlen_x_axis <- min(len_frac_x_axis,2)
	jp_x_prep_df$c_mids <- tmcn::right(paste0(paste0(rep('0',len_max_x_axis),collapse = ''),jp_x_prep_df$mids),len_max_x_axis)

	#220. Prepare the data for histogram on [y]
	jp_y_prep <- hist(jp_df$y, plot = FALSE, breaks = breaks)
	jp_y_prep_df <- data.frame(
		mids = jp_y_prep$mids,
		counts = jp_y_prep$counts,
		density = jp_y_prep$density
	)

	#230. Determine the number of characters of [mids] and the display format
	len_whole_y_axis <- max(nchar(gsub('^\\s*(\\d*)?((\\.)(\\d*))?$','\\1',jp_y_prep$mids,perl = TRUE)))
	len_frac_y_axis <- max(nchar(gsub('^\\s*(\\d*)?((\\.)(\\d*))?$','\\4',jp_y_prep$mids,perl = TRUE)))
	len_max_y_axis <- len_whole_y_axis + len_frac_y_axis + 1
	fmtlen_y_axis <- min(len_frac_y_axis,2)
	jp_y_prep_df$c_mids <- tmcn::right(paste0(paste0(rep('0',len_max_y_axis),collapse = ''),jp_y_prep_df$mids),len_max_y_axis)

	#250. Prepare to scale the numbers on the labels of axes for the histograms
	#251. x-axis for y-histogram (index==1)
	max_x1 <- max(jp_x_prep$counts)
	logK_x1 <- log(max_x1,base = 1000)
	logK_x1_whole <- floor(logK_x1)
	q_x1_len_whole <- nchar(floor(max_x1/1000^logK_x1_whole))
	if (logK_x1_whole < 1) {
		str_unit_x1 <- character(0)
	} else {
		str_unit_x1 <- map_units[[logK_x1_whole]]
	}
	if (logK_x1_whole == 0) {
		nfrac_x1 <- 0
	} else {
		nfrac_x1 <- 3 - q_x1_len_whole
	}

	#252. y-axis for x-histogram (index==2)
	max_y2 <- max(jp_y_prep$counts)
	logK_y2 <- log(max_y2,base = 1000)
	logK_y2_whole <- floor(logK_y2)
	q_y2_len_whole <- nchar(floor(max_y2/1000^logK_y2_whole))
	if (logK_y2_whole < 1) {
		str_unit_y2 <- character(0)
	} else {
		str_unit_y2 <- map_units[[logK_y2_whole]]
	}
	if (logK_y2_whole == 0) {
		nfrac_y2 <- 0
	} else {
		nfrac_y2 <- 3 - q_y2_len_whole
	}

	#300. Prepare the data for plotting
	jp_df <- jp_df %>%
		dplyr::mutate(
			mids = cut(
				y,
				jp_y_prep$breaks,
				labels = jp_y_prep$mids,
				#Align the same option in the function [base::hist]
				include.lowest = TRUE
			),
			c_mids = tmcn::right(paste0(paste0(rep('0',len_max_y_axis),collapse = ''),mids),len_max_y_axis)
		)
	jp_df$counts <- sapply(jp_df$mids,function(e){jp_y_prep$counts[which(jp_y_prep$mids==e)]})
	jp_df$density <- sapply(jp_df$mids,function(e){jp_y_prep$density[which(jp_y_prep$mids==e)]})

	#400. Correct the attributes of axes
	#410. Correct the attributes of y-axis in the scatter plot to align with the y-histogram
	#This only happens when the minimum of [y] is larger than 0 for certain amount
	#411. Calculate interval
	ntvl_y_scatter <- (jp_y_prep$mids[[1]] - jp_y_prep$breaks[[1]]) * 2
	min_y_scatter <- jp_y_prep$breaks[[1]]
	if (min_y_scatter < 0 & min(jp_df$y) > 0) min_y_scatter <- 0

	#420. Correct the bar width of the x-histogram
	#This only happens when the minimum of [x] is larger than 0 for certain amount
	#421. Calculate interval
	ntvl_x_scatter <- (jp_x_prep$mids[[1]] - jp_x_prep$breaks[[1]]) * 2
	min_x_scatter <- jp_x_prep$breaks[[1]]
	if (min_x_scatter < 0 & min(jp_df$x) > 0) min_x_scatter <- 0

	#422. Calculate the number of intervals it SHOULD be on x axis
	# k_ntvl_x_hist <- round(jp_x_prep$breaks[[length(jp_x_prep$breaks)]] / ntvl_x_scatter , digits = 0)

	#429. Correction
	# if (k_ntvl_x_hist > length(jp_x_prep$breaks)) {
	# 	barwidth_x_hist <- paste0(formatC(90 * length(jp_x_prep$mids) / k_ntvl_x_hist , digits = 0 , format = 'f'),'%')
	# } else {
	# 	barwidth_x_hist <- '90%'
	# }

	#600. Prepare the [echarts4r] object for output
	#[Quote: https://echarts4r.john-coene.com/articles/grid.html ]
	jp <- jp_df %>%
		echarts4r::e_charts(x) %>%

		#100. Draw the scatter plot on the grid at the bottom left corner
		echarts4r::e_grid(index = 0, top = "22%", right = "22%", bottom = "40px", left = "40px") %>%
		echarts4r::e_scatter(
			y,
			legend = FALSE,
			name = yname,
			# itemStyle = list(opacity = .75),
			symbol_size = 10,
			color = col_s,
			#[Quote: https://stackoverflow.com/questions/50361947/how-to-format-tooltip-in-echarts4r ]
			#[Quote: https://github.com/JohnCoene/echarts4r/blob/master/vignettes/tooltip.Rmd ]
			tooltip = list(
				formatter = htmlwidgets::JS(paste0(
					"function(params){",
						"return(",
							"'<strong>",yname,"</strong> : ' + echarts.format.addCommas(params.value[1].toFixed(",fmtlen_y_axis,")) + '<br/>'",
							"+ '<strong>",xname,"</strong> : ' + echarts.format.addCommas(params.value[0].toFixed(",fmtlen_x_axis,"))",
						");",
					"}"
				))
			),
			x_index = 0,
			y_index = 0
		) %>%

		#400. Draw the histogram on the grid at the bottom right corner
		#[IMPORTANT!!!]
		#[1] Neither can the histogram on right side be placed beneath that one on top of the canvas,
		#[2] Nor can it be placed on a grid with index larger than 1.
		echarts4r::e_grid(index = 1, top = "22%", right = "15px", bottom = "40px", left = "78%") %>%
		echarts4r::e_data(jp_df,counts) %>%
		echarts4r::e_bar(
			c_mids,
			legend = FALSE,
			name = yname,
			barWidth = "90%",
			# itemStyle = list(opacity = .75),
			color = col_y,
			tooltip = list(
				formatter = htmlwidgets::JS(paste0(
					"function(params){",
						"return(",
							"'<strong>",yname,"</strong><br/>'",
							"+ '<i>[' + echarts.format.addCommas(parseFloat(params.value[1]).toFixed(",fmtlen_y_axis,")) + ']</i>'",
							"+ ' : ' + echarts.format.addCommas(params.value[0])",
						");",
					"}"
				))
			),
			x_index = 1,
			y_index = 1
		) %>%
		echarts4r::e_y_axis(
			index = 1,
			gridIndex = 1,
			data = jp_y_prep_df$c_mids,
			type = 'category',
			show = FALSE,
			axisLabel = list(show = FALSE),
			axisTick = list(show = FALSE),
			axisPointer = list(
				label = list(
					formatter = htmlwidgets::JS(paste0(
						"function(params){",
							"return(",
								"echarts.format.addCommas(parseFloat(params.value).toFixed(",fmtlen_y_axis,"))",
							");",
						"}"
					))
				)
			)
		) %>%
		echarts4r::e_x_axis(
			index = 1,
			gridIndex = 1,
			type = 'value',
			show = TRUE,
			axisLabel = list(
				rotate = -90,
				formatter = htmlwidgets::JS(paste0(
					"function(value, index){",
						"if (index == 0 || index == 1){return '';}",
						"return(",
							"(value/",1000^logK_x1_whole,").toFixed(",nfrac_x1,") + '",str_unit_x1,"'",
						");",
					"}"
				))
			),
			splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			)
		) %>%

		#700. Draw the histogram on the grid at the top left corner
		echarts4r::e_grid(index = 2, top = "15px", right = "22%", bottom = "78%", left = "40px") %>%
		echarts4r::e_histogram(
			x,
			legend = FALSE,
			name = xname,
			breaks = breaks,
			bar_width = '90%',
			# itemStyle = list(opacity = .75),
			color = col_x,
			tooltip = list(
				formatter = htmlwidgets::JS(paste0(
					"function(params){",
						"return(",
							"'<strong>",xname,"</strong><br/>'",
							"+ '<i>[' + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(",fmtlen_x_axis,")) + ']</i>'",
							"+ ' : ' + echarts.format.addCommas(params.value[1])",
						");",
					"}"
				))
			),
			x_index = 2,
			y_index = 2
		) %>%
		echarts4r::e_y_axis(
			index = 2,
			gridIndex = 2,
			show = TRUE,
			axisLabel = list(
				formatter = htmlwidgets::JS(paste0(
					"function(value, index){",
						"if (index == 0 || index == 1){return '';}",
						"return(",
							"(value/",1000^logK_y2_whole,").toFixed(",nfrac_y2,") + '",str_unit_y2,"'",
						");",
					"}"
				))
			),
			splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			)
		) %>%
		echarts4r::e_x_axis(
			index = 2,
			gridIndex = 2,
			show = FALSE,
			min = min_x_scatter,
			interval = ntvl_x_scatter
		) %>%

		#800. Add styles
		#810. Add links to the axis pointers
		#[Quote: https://echarts.apache.org/zh/option.html#axisPointer ]
		# echarts4r::e_axis_pointer(
		# 	link = list(
		# 		list(
		# 			xAxisIndex = list(0,2)
		# 		)
		# 	)
		# ) %>%

		#900. Post process
		#970. Set the visible axis names
		#[IMPORTANT!!!]
		#[1] Place the primary axes at the last of the statements to prevent them being overwritten by different grids
		echarts4r::e_y_axis(
			index = 0,
			gridIndex = 0,
			name = yname,
			min = min_y_scatter,
			interval = ntvl_y_scatter,
			show = TRUE,
			axisLabel = list(
				rotate = 90,
				formatter = htmlwidgets::JS(paste0(
					"function(value, index){",
						"return(",
							"(value/",1000^logK_y0_whole,").toFixed(",nfrac_y0,") + '",str_unit_y0,"'",
						");",
					"}"
				))
			),
			splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			),
			nameGap = 20,
			nameLocation = "center"
		) %>%
		echarts4r::e_x_axis(
			index = 0,
			gridIndex = 0,
			name = xname,
			min = min_x_scatter,
			interval = ntvl_x_scatter,
			show = TRUE,
			axisLabel = list(
				formatter = htmlwidgets::JS(paste0(
					"function(value, index){",
						"return(",
							"(value/",1000^logK_x0_whole,").toFixed(",nfrac_x0,") + '",str_unit_x0,"'",
						");",
					"}"
				))
			),
			splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			),
			nameGap = 18,
			nameLocation = "center"
		) %>%

		#990. Gadgets
		echarts4r::e_toolbox() %>%
		echarts4r::e_toolbox_feature(
			feature = 'saveAsImage'
		) %>%
		# echarts4r::e_brush(
		# 	xAxisIndex = c(0,2),
		# 	yAxisIndex = c(0,1)
		# ) %>%
		echarts4r::e_show_loading() %>%
		echarts4r::e_tooltip(
			trigger = "item",
			axisPointer = list(
				type = "cross"
			)
		)

	#900. Add title if any
	if (!is.null(title)) {
		jp <- jp %>%
			echarts4r::e_title(
				title,
				paste0(
					'x: ',xname,'\n',
					'y: ',yname
				),
				itemGap = 7,
				textAlign = 'left',
				top = '5%',
				right = 'right'
			)
	}

	#999. Return the [echarts4r] object
	return(jp)
}

#[Full Test Program;]
if (FALSE){
	#Real case test
	if (TRUE){
		lst_pkg <- c( "tmcn" , "dplyr" , "echarts4r" , "htmlwidgets" ,
			"shiny" , "shinydashboard" , "shinydashboardPlus"
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		omniR <- "D:\\R\\omniR"
		source("D:\\R\\Project\\myApp\\Func\\UI\\theme_color_sets.r")

		# Create the [echarts4r] object
		ech_JointPlots <- echarts4r_JointPlots(
			USArrests$UrbanPop,
			USArrests$Rape,
			xname = 'UrbanPop',
			yname = 'Rape',
			breaks = "Sturges",
			colorset = myApp_themecolorset$s08$p[[length(myApp_themecolorset$s08$p)]],
			samples = NULL
		)

		test_df <- openxlsx::readWorkbook(
			"D:\\R\\Project\\myApp\\Data\\TestData.xlsx",
			sheet = "Dual",
			detectDates = TRUE,
			fillMergedCells = TRUE
		)

		# Create the [echarts4r] object
		ech_AUM <- echarts4r_JointPlots(
			test_df$a_aum_T1,
			test_df$a_aum_T2,
			xname = 'a_aum_T1',
			yname = 'a_aum_T2',
			title = 'Joint Plots',
			breaks = "Scott",
			colorset = c('red','green'),
			samples = NULL
		)

	}
}
