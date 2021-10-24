#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create a [shinyWidgets::noUiSliderInput] with [handles] in the same style as [Echarts]                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |handleStyle :   Choose from the preset handles for output                                                                          #
#   |                 [circle  ]<Default> See also: [omniR$Visualization$slider-handle-inuse.svg]                                       #
#   |                 [rect    ]          See also: [omniR$Visualization$slider-handle-default.svg]                                     #
#   |handleScale :   How many times the handle is larger than the bar-width of the sliderInput, MUST be larger than 0                   #
#   |                 [1       ]<Default> The handle size is exactly the same as the bar-width                                          #
#   |...         :   Same parameters as [shinyWidgets::noUiSliderInput]                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Widget]   :   The same widget as [shinyWidgets::noUiSliderInput] for [shiny] environment                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200311        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200329        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add [handleStyle] and [handleScale] to further imitate the handle styles in [echarts]                                       #
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
#   |   |shiny, shinyWidgets, RCurl                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, shinyWidgets, RCurl
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

noUiSliderInput_EchStyle <- function(handleStyle = c('circle','rect'),handleScale = 1, ...){
	#010. Collect related parameters
	handleStyle <- match.arg(handleStyle,c('circle','rect'))
	def_ori <- c('horizontal', 'vertical')
	def_dir <- c('ltr', 'rtl')
	params <- list(...)
	params$orientation <- match.arg(params$orientation,def_ori)
	params$direction <- match.arg(params$direction,def_dir)
	params$height <- shiny::validateCssUnit(params$height)
	params$width <- shiny::validateCssUnit(params$width)

	#100. Prepare the icon of the handles
	#Guide to create the SVG icon:
	#[Quote: https://blog.csdn.net/lihefei_coder/article/details/81536429 ]
	#[10] 找一个SVG文件，或者一串[path]的路径并且贴进已有的SVG文件中。例如：[omniR$Visualization$slider-handle-inuse.svg]
	#[20] 在SVG文件里调整width和height，使预览的大小符合当前project
	#[21] 在SVG文件里调整其它属性，如颜色和阴影 [Quote: http://www.svgbasics.com/filters3.html ]
	#[29] 注意：CSS也可以用[filter: drop-shadow(h-shadow v-shadow blur spread color);]实现元素的阴影 [Quote: https://www.cnblogs.com/kaidarwang/p/9239438.html ]
	#[30] 使用[utils::URLencode]将SVG文件进行编码，或者：
	#[31] 打开网站: https://tool.oschina.net/encode?type=4
	#[32] 将修改后的SVG内容全部贴进网站并点击[URL编码]
	#[90] 将生成的编码复制并赋值给以下变量：
	#Below handle style comes from below official site:
	#[Quote: https://www.echartsjs.com/zh/option.html#dataZoom-slider ]
	handle_icons <- list(
		#Below handle style comes from below official site:
		#[Quote: https://www.echartsjs.com/examples/en/editor.html?c=area-simple ]
		#[Quote: [omniR$Visualization$slider-handle-inuse.svg]]
		circle = 'PD94bWwgdmVyc2lvbj0iMS4wIiA/PjwhRE9DVFlQRSBzdmcgIFBVQkxJQyAiLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4iICAiaHR0cDovL3d3dy53My5vcmcvR3JhcGhpY3MvU1ZHLzEuMS9EVEQvc3ZnMTEuZHRkIj48c3ZnIGhlaWdodD0iMjAiIGlkPSJMYXllcl8xIiB2ZXJzaW9uPSIxLjEiIHZpZXdCb3g9IjAgMTAgMjQgMjQiIHdpZHRoPSIxNCIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayI+CTxmaWx0ZXIgaWQgPSAiaS1oYW5kbGUiIHdpZHRoID0gIjE1MCUiIGhlaWdodCA9ICIxNTAlIj4JCTxmZU9mZnNldCByZXN1bHQgPSAib2ZmT3V0IiBpbiA9ICJTb3VyY2VBbHBoYSIgZHggPSAiMSIgZHkgPSAiMiIvPgkJPGZlR2F1c3NpYW5CbHVyIHJlc3VsdCA9ICJibHVyT3V0IiBpbiA9ICJvZmZPdXQiIHN0ZERldmlhdGlvbiA9ICIyIi8+CQk8ZmVCbGVuZCBpbiA9ICJTb3VyY2VHcmFwaGljIiBpbjIgPSAiYmx1ck91dCIgbW9kZSA9ICJub3JtYWwiLz4JPC9maWx0ZXI+CTxkZWZzPgkJPHN0eWxlIHR5cGU9InRleHQvY3NzIj4uc3ZnY2xzLWhhbmRsZSB7ZmlsbDpyZ2JhKDI1NSwyNTUsMjU1LDAuNyk7fTwvc3R5bGU+CTwvZGVmcz4JPHBhdGggY2xhc3M9InN2Z2Nscy1oYW5kbGUiIGZpbHRlciA9ICJ1cmwoI2ktaGFuZGxlKSIgZD0iTTEwLjcsMTEuOXYtMS4zSDkuM3YxLjNjLTQuOSwwLjMtOC44LDQuNC04LjgsOS40YzAsNSwzLjksOS4xLDguOCw5LjR2MS4zaDEuM3YtMS4zYzQuOS0wLjMsOC44LTQuNCw4LjgtOS40QzE5LjUsMTYuMywxNS42LDEyLjIsMTAuNywxMS45eiBNMTMuMywyNC40SDYuN1YyM2g2LjZWMjQuNHogTTEzLjMsMTkuNkg2Ljd2LTEuNGg2LjZWMTkuNnoiLz48L3N2Zz4='
		#Below handle style comes from below official site ([echarts] default handle style):
		#[Quote: https://www.echartsjs.com/zh/option.html#dataZoom-slider ]
		#[Quote: [omniR$Visualization$slider-handle-default.svg]]
		,rect = 'PD94bWwgdmVyc2lvbj0iMS4wIiA/PjwhRE9DVFlQRSBzdmcgIFBVQkxJQyAiLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4iICAiaHR0cDovL3d3dy53My5vcmcvR3JhcGhpY3MvU1ZHLzEuMS9EVEQvc3ZnMTEuZHRkIj48IS0tIEhvdyB0byBjcmVhdGUgcmVtYXJrcyBpbiBYTUw6IGh0dHBzOi8vYmxvZy5jc2RuLm5ldC95aW5ib3dlbi9hcnRpY2xlL2RldGFpbHMvNDQ1NDY3OCAtLT48IS0tIFVuZGVyc3RhbmQgdGhlIFhNTCBhdHRyaWJ1dGVzLCBzdWNoIGFzIHZpZXdwb3J0L3ZpZXdCb3ggOiBodHRwczovL3d3dy56aGFuZ3hpbnh1LmNvbS93b3JkcHJlc3MvMjAxNC8wOC9zdmctdmlld3BvcnQtdmlld2JveC1wcmVzZXJ2ZWFzcGVjdHJhdGlvLyAtLT48c3ZnIGhlaWdodD0iMjAiIGlkPSJMYXllcl8xIiB2ZXJzaW9uPSIxLjEiIHZpZXdCb3g9IjAgMTAgMjQgMjQiIHdpZHRoPSIxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayI+CTxmaWx0ZXIgaWQgPSAiaS1oYW5kbGUiIHdpZHRoID0gIjE1MCUiIGhlaWdodCA9ICIxNTAlIj4JCTxmZU9mZnNldCByZXN1bHQgPSAib2ZmT3V0IiBpbiA9ICJTb3VyY2VBbHBoYSIgZHggPSAiMSIgZHkgPSAiMiIvPgkJPGZlR2F1c3NpYW5CbHVyIHJlc3VsdCA9ICJibHVyT3V0IiBpbiA9ICJvZmZPdXQiIHN0ZERldmlhdGlvbiA9ICIyIi8+CQk8ZmVCbGVuZCBpbiA9ICJTb3VyY2VHcmFwaGljIiBpbjIgPSAiYmx1ck91dCIgbW9kZSA9ICJub3JtYWwiLz4JPC9maWx0ZXI+CTxkZWZzPgkJPHN0eWxlIHR5cGU9InRleHQvY3NzIj4uc3ZnY2xzLWhhbmRsZSB7ZmlsbDpyZ2JhKDI1NSwyNTUsMjU1LDAuNSk7fTwvc3R5bGU+CTwvZGVmcz4JPHBhdGggY2xhc3M9InN2Z2Nscy1oYW5kbGUiIGZpbHRlciA9ICJ1cmwoI2ktaGFuZGxlKSIgZD0iTTguMiwxMy42VjMuOUg2LjN2OS43SDMuMXYxNC45aDMuM3Y5LjdoMS44di05LjdoMy4zVjEzLjZIOC4yeiBNOS43LDI0LjRINC44di0xLjRoNC45VjI0LjR6IE05LjcsMTkuMUg0Ljh2LTEuNGg0LjlWMTkuMXoiLz48L3N2Zz4='
	)
	handle_icon <- handle_icons[which(names(handle_icons) == handleStyle)]
	#Debug mode
	if (FALSE){
		svgfile <- file(paste0(omniR,'\\Visualization\\slider-handle-inuse.svg'),'rt')
		svgcode <- readLines(svgfile)
		close(svgfile)
		# handle_icon <- utils::URLencode(paste0(svgcode,collapse = ''))
		handle_icon <- RCurl::base64Encode(paste0(svgcode,collapse = ''))
	}

	#500. Prepare the styles for the handles
	#How to use CSS [calc] function: https://www.runoob.com/cssref/func-calc.html
	#Note that when [orientation=horizontal], the value of [height] must be set to actual number of pixels,
	# while [orientation=vertical], the value of [width] must be set to actual number of pixels.
	if (params$orientation == 'horizontal') {
		height_calc <- as.numeric(gsub('^\\s*(\\d+(\\.\\d+)?).*$','\\1',params$height,perl = TRUE))
		width_calc <- 0
	} else {
		width_calc <- as.numeric(gsub('^\\s*(\\d+(\\.\\d+)?).*$','\\1',params$width,perl = TRUE))
		height_calc <- 0
	}
	CSSstyles <- list()

	#510. Calculate the width of the handle in CSS syntax
	if (params$orientation == 'horizontal') {
		height_handle <- height_calc * handleScale
		pos_top <- floor( 0.5 * ( height_calc - height_handle ) ) - 1
		pos_left <- 0
	} else {
		height_handle <- width_calc * handleScale
		pos_left <- floor( 0.5 * ( width_calc - height_handle ) ) - 1
		pos_top <- 0
	}
	if (handleStyle == 'circle'){
		img_type <- 'svg+xml'
		width_handle <- height_handle
		#Check the element position in its parent SVG for below percentage
		offset_right <- 0 - width_handle * 0.6
		offset_top <- 0 - width_handle * 0.4
	}
	if (handleStyle == 'rect'){
		img_type <- 'svg+xml'
		width_handle <- height_handle
		#Check the element position in its parent SVG for below percentage
		offset_right <- 0 - width_handle * 0.7
		offset_top <- 0 - width_handle * 0.3
	}

	#550. Horizontal handles
	CSSstyles[['horizontal']] <- shiny::HTML(
		paste0(
			'html:not([dir=rtl]) .noUi-horizontal .noUi-handle {'
				,'right: ',shiny::validateCssUnit(offset_right),';'
			,'}'
			,'.noUi-horizontal .noUi-handle {'
				,'text-shadow: 0 1px 1px #EBEBEB;'
				,'box-shadow: none;'
				,'border: none;'
				,'background: rgba(255,255,255,0);'
				,'height: ',shiny::validateCssUnit(height_handle),';'
				,'width: ',shiny::validateCssUnit(width_handle),';'
				# ,'top: calc(0px - ',pos_top,');'
				,'top: ',shiny::validateCssUnit(pos_top),';'
				,'vertical-align: middle;'
				#It is tested that only [base64] encoding method can be adapted by the latest version of [Chrome]
				#[Quote: https://www.cnblogs.com/OpenCoder/p/7127256.html ]
				,'content: url("data:image/svg+xml;base64,',handle_icon,'");'
				# ,'content: url("data:image/svg+xml;%20charset=utf8,',handle_icon,'");'
				# ,'filter: drop-shadow(0 1px 1px #000);'
				# ,'-webkit-filter: drop-shadow(0 1px 1px #000);'
				# ,'-moz-filter: drop-shadow(0 1px 1px #000);'
			,'}'
			,'.noUi-handle:before .noUi-handle:after {'
				,'border: none;'
				,'content: none;'
			,'}'
			,'.noUi-connects {'
				,'border-radius: 0px;'
			,'}'
		)
	)

	#570. Horizontal handles
	CSSstyles[['vertical']] <- shiny::HTML(
		paste0(
			'.noUi-vertical .noUi-handle {'
				,'text-shadow: 0 1px 1px #EBEBEB;'
				,'box-shadow: none;'
				,'border: none;'
				,'background: rgba(255,255,255,0);'
				,'height: ',shiny::validateCssUnit(height_handle),';'
				,'width: ',shiny::validateCssUnit(width_handle),';'
				,'top: ',shiny::validateCssUnit(offset_top),';'
				,'left: ',shiny::validateCssUnit(pos_left),';'
				,'content: url("data:image/',img_type,';base64,',handle_icon,'");'
				,'transform: rotate(90deg);'
				,'-webkit-transform: rotate(90deg);'
				,'-moz-transform: rotate(90deg);'
				,'filter: drop-shadow(0 1px 1px #fff);'
				,'-webkit-filter: drop-shadow(0 1px 1px #fff);'
				,'-moz-filter: drop-shadow(0 1px 1px #fff);'
			,'}'
			,'.noUi-handle:before .noUi-handle:after {'
				,'border: none;'
				,'content: none;'
			,'}'
			,'.noUi-vertical {'
				,'width: ',params$width,';'
			,'}'
			,'.noUi-connects {'
				,'border-radius: 0px;'
			,'}'
		)
	)

	#800. Create the widget
	out_tags <- shiny::tagList(
		shiny::tags$style(
			type = 'text/css'
			,CSSstyles[[params$orientation]]
		)
		#[Quote: https://stackoverflow.com/questions/6496811/how-to-pass-a-list-to-a-function-in-r ]
		,do.call( shinyWidgets::noUiSliderInput , params )
	)

	#999. Return the result
	return(out_tags)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		library(tmcn)
		library(shiny)
		library(shinydashboard)
		library(shinyjs)

		tmcn::setchs(rev=F)
		omniR <- "D:\\R\\omniR"
		source("D:\\R\\Project\\myApp\\Func\\UI\\theme_color_sets.r")

		themecolorset <- myApp_themecolorset
		if (is.null(themecolorset)) {
			chartitem_color <- AdminLTE_color_primary
		} else {
			chartitem_color <- themecolorset$s08$p[[length(themecolorset$s08$p)]]
		}
		chartitem_rgb <- grDevices::col2rgb(chartitem_color)

		testSlider_ui <- function(id){
			#Set current Name Space
			ns <- NS(id)

			shiny::tagList(
				shiny::fluidRow(
					style = 'width: 90%; height: 60px; padding-left: 40px;'
					,noUiSliderInput_EchStyle(
						handleStyle = 'circle'
						,handleScale = 0.8
						,inputId = ns('uWg_SI_Hori')
						,min = 0, max = 100
						,value = c(0,100)
						,tooltips = FALSE
						,connect = c(TRUE, FALSE, TRUE)
						,color = paste0('rgba(',paste0(chartitem_rgb, collapse = ','),',0.5)')
						,width = '100%'
						,height = 30
						,direction = 'rtl'
					)
				)
				,shiny::fluidRow(
					style = 'width: 60px; height: 400px; padding-left: 20px;'
					,noUiSliderInput_EchStyle(
						handleStyle = 'rect'
						,handleScale = 2
						,inputId = ns('uWg_SI_Vert')
						,min = 0, max = 100
						,value = c(0,100)
						,tooltips = FALSE
						,connect = c(TRUE, FALSE, TRUE)
						,color = paste0('rgba(',paste0(chartitem_rgb, collapse = ','),',0.5)')
						,width = 40
						,height = 400
						,orientation = 'vertical'
						,direction = 'ltr'
					)
				)
			)
		}

		testSlider_svr <- function(input,output,session){
			ns <- session$ns
		}



		ui <- shinydashboard::dashboardPage(
			shinydashboard::dashboardHeader()
			,shinydashboard::dashboardSidebar()
			,shinydashboard::dashboardBody(
				shinyjs::useShinyjs()
				,testSlider_ui("test")
			)
		)

		server <- function(input, output) {
			shiny::observe({
				shiny::callModule(testSlider_svr,'test')
			})
		}

		shinyApp(ui, server)

	}
}

