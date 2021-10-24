#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This module (Fund Comparison) is designed for below purposes:                                                                      #
#   |[1]Compare the historical customer cost to the fund NAV for the funds, given the customer currently holds their units              #
#   |[2]Compare the historical prices of the funds                                                                                      #
#   |[3]Compare the historical P&L (Profit & Loss) of the funds                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 客户经理协助客户在基金货架中筛选需要进行调仓的组合                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |FundForComp   :   The data.frame that contains the full data for charting, with at least below fields:                             #
#   |                   [d_data           ]    <variable>   The date field to act as x-axis of the charts                               #
#   |                   [FC_Holding       ]    <variable>   Whether current record represents the product the customer is holding unit  #
#   |                                                        [Y] The customer is holding such product at present                        #
#   |                                                        [N] The customer is not holding such product at present                    #
#   |                   [ProdName_<lang>  ]    <variables>  The series of fields that represent the product names in various languages  #
#   |                   [c_currency       ]    <variable>   Product currency to display in the tooltips of the charts                   #
#   |                   [bal_bcy          ]    <variable>   Product holding balance of the customer                                     #
#   |                   [Last7Day_PnL_pa  ]    <variable>   P&L within the latest 7 days for the product                                #
#   |                   [Cost             ]    <variable>   Customer cost on each record of the data.frame                              #
#   |                   [Price            ]    <variable>   Fund price on each record of the data.frame                                 #
#   |                   [<VarComp>        ]    <variables>  The fields used for comparison between the funds                            #
#   |VarComp       :   The named list/vector of variables/fields used to compare the funds                                              #
#   |                   ['name' = 'type'  ]    <vectors>    The field names as well as their respective types to format the charting    #
#   |                                                        'type' should be one of below values (case sensitive):                     #
#   |                                                        [price]   It will be formatted as: #,#00.0000                              #
#   |                                                        [percent] It will be formatted as: #00.00%                                 #
#   |lang_cfg      :   Language configuration for Customer Portfolio Management                                                         #
#   |color_cfg     :   Color configuration for this module                                                                              #
#   |lang_disp     :   Language to extract all items from within [lang_cfg], currently support below 2 languages:                       #
#   |                   [CN]<Default>                                                                                                   #
#   |                   [EN]                                                                                                            #
#   |font_disp     :   Font of all characters in all paragraphs                                                                         #
#   |                   [Quote: http://blog.sina.com.cn/s/blog_54be98b80102xm1w.html ]                                                  #
#   |                   [Microsoft YaHei]<Default>                                                                                      #
#   |                   [Helvetica]                                                                                                     #
#   |                   [sans-serif]                                                                                                    #
#   |                   [Arial]                                                                                                         #
#   |                   [宋体]                                                                                                          #
#   |observer_pfx  :   The naming prefix of the [observer]s to be destroyed as garbage collection                                       #
#   |                   [1] Naming convention of observers is: [ session$userData[[paste(ns(observer_pfx),'name',sep='_')]] ]           #
#   |                   [2] Following above naming convention, ensure the [observer]s in the [module] are stored in [session$userData]  #
#   |                   [3] 'uObs' is the default value of the parameter, representing: User-defined Observer                           #
#   |fDebug        :   Switch for debug mode                                                                                            #
#   |                   [FALSE]<Default> normal mode                                                                                    #
#   |                   [TRUE] debug mode                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |800.   Naming Convention.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CPD           :   Customer Portfolio Dashboard                                                                                     #
#   |uDiv          :   User defined HTML Tag as Division (similar names would be: [uRow], [uCol], etc.)                                 #
#   |uWg           :   User defined Widgets                                                                                             #
#   |uObs          :   User defined Observers                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CallCounter   :   The counter of completion of this module. Only meaningful when this module is called once                        #
#   |                   [0] starting value                                                                                              #
#   |ActionDone    :   Flag of whether the necessary action within the module is successfully taken                                     #
#   |                   [FALSE]<Default> turn to [TRUE] once the crucial action is observed to have been taken                          #
#   |EnvVariables  :   List of variables created within the module environment with their last values                                   #
#   |                   Value of any internal variable can be retrieved via the form: [EnvVariables()$varname], where [varname] is      #
#   |                    usually defined as [uRV$varname] inside the module program.                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200406        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200419        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add a parameter [color_cfg] to unify the color settings for all related modules                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200510        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [observer_pfx] to name the observers                                                                    #
#   |      |[2] Store all necessary observers into [session$userData] for garbage collection                                            #
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
#   |   |shiny, lubridate, dplyr, grDevices, htmlwidgets, tidyselect, shinydashboard, echarts4r                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Directory: [omniR$Styles]                                                                                                      #
#   |   |   |rgba2rgb                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, lubridate, dplyr, grDevices, htmlwidgets, tidyselect, shinydashboard, echarts4r
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

UM_FundCmp_ui_CostPnL <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_CostPnL'))
}

UM_FundCmp_ui_FundPrice <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_FundPrice'))
}

UM_FundCmp_ui_FundPnL <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_FundPnL'))
}

UM_FundCompare_svr <- function(input,output,session
	,FundForComp = NULL,ObsDate = NULL,VarComp = NULL
	,lang_cfg = NULL,color_cfg = NULL
	,lang_disp = 'CN',font_disp = 'Microsoft YaHei'
	,observer_pfx = 'uObs'
	,fDebug = FALSE){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	if (is.null(ObsDate)) ObsDate <- FundForComp$d_data %>% max(na.rm = T)
	if (!lubridate::is.Date(ObsDate)) stop(ns('[Module][UM_FundCompare][ObsDate] must be provided a date value!'))
	VarComp <- unlist(VarComp)
	uRV$Var_Names <- names(VarComp)
	uRV$Var_Types <- VarComp
	if (is.null(uRV$Var_Names) | length(uRV$Var_Names) != length(VarComp))
		stop(ns('[Module][UM_FundCompare][VarComp] must be provided a fully named vector!'))
	lang_disp <- match.arg(lang_disp,c('CN','EN'))
	uRV$font_list <- c('Microsoft YaHei','Helvetica','sans-serif','Arial','宋体')
	uRV$font_list_css <- paste0(
		sapply(uRV$font_list, function(m){if (length(grep('\\W',m,perl = T))>0) paste0('"',m,'"') else m})
		,collapse = ','
	)
	font_disp <- match.arg(font_disp,uRV$font_list)

	uRV$df_CostPnL <- FundForComp %>% dplyr::filter(FC_Holding == 'Yes')
	pnllst <- uRV$df_CostPnL[[paste0('ProdName_',lang_disp)]] %>% unique()
	#Below is the list of important stages to trigger the increment of initial progress bar
	uRV$pb_k <- list(
		#[1] Loading data
		load = 0
		#[2] Drawing charts
		#There are only 3 UIs to be created sequentially
		,chart = 3
	)
	uRV$pb_k_all <- length(uRV$pb_k)
	uRV$pb_cnt_chart <- 0
	#We observe the status of the progress bar every 1sec, and destroy it after is it reaches the end
	uRV$k_ms_invld <- 1000
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- shiny::reactiveVal(0)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[Module Call][UM_FundCompare]')))
	}

	#005. Check parameters
	#We do not return values to break the chain of the subsequent processes.
	if (is.null(FundForComp)) stop(ns(paste0('[005]Crucial input data [FundForComp] is not provided!')))
	if (!is.data.frame(FundForComp)) stop(ns(paste0('[005]Crucial input data [FundForComp] is not a data.frame!')))

	#200. General settings of styles for the output UI
	uRV$ch_handle_color_rgb <- grDevices::col2rgb(color_cfg$CustAct)
	uRV$ch_bg_color_rgb <- grDevices::col2rgb(color_cfg$ech_dz_AreaBg)

	#212. Font Size of chart items
	uRV$styles_ch_FontSize_title <- 14
	uRV$styles_ch_FontSize_item <- 10

	#240. Prepare the color series to differentiate the bars in the chart by [ProdType]

	#265. Determine the styles of the datatables inside the [tabBox]
	uRV$uTB_width <- 12
	uRV$styles_tabBox_font <- paste0(''
		,'font-family: ',font_disp,';'
		,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
	)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(''
			#Set the paddings of the [tabBox]
			# '[class^=col-][class$=',uRV$uTB_width,'] {'
			,'.col-sm-',uRV$uTB_width,' {'
				,'padding: 0px;'
			,'}'
			#Add styles to the navigation buttons
			,'.uAB-nav-xs {'
				,'text-align: center;'
				,'padding: 0px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'background-color: rgba(0,0,0,0);'
				,uRV$styles_tabBox_font
			,'}'
			#Add hover effect to the navigation buttons
			,'.uAB-nav-xs.hover, .uAB-nav-xs:focus, .uAB-nav-xs:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			#Add styles to the action buttons
			,'.uAB-theme-xs {'
				,'text-align: center;'
				,'padding: 0px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$CustAct,';'
				,uRV$styles_tabBox_font
			,'}'
			#Add hover effect to the action buttons
			,'.uAB-theme-xs.hover, .uAB-theme-xs:focus, .uAB-theme-xs:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			#Set the color of the top-border of active tabs inside the [tabBox]
			,'.nav-tabs-custom>.nav-tabs>li.active {'
				,'border-top-color: ',color_cfg$tabBox,';'
			,'}'
			,'.fe_fluidRow {padding: 2px 15px 2px 15px;}'
			,'.fe_Column {'
				,'padding: 0px;'
			,'}'
		)
	)

	#400. Prepare the HTML elements
	#401. Function to draw the charts regarding the comparison of customer cost against the product price
	drawCH_CostPnL <- function(FundName){
		#001. Handle parameters
		if (is.null(FundName)) stop('Fund Name is not provided!')
		val_item <- list(
			axisLabel = 'value'
			,axisPointer = 'params.value'
			,tooltip = 'item.value[1]'
		)
		val_disp <- lapply(val_item, function(m){paste0('parseFloat(',m,').toFixed(4)')})
		names(val_disp) <- names(val_item)
		df <- uRV$df_CostPnL %>%  dplyr::filter_at(paste0('ProdName_',lang_disp),~. == FundName)

		#100. Initialize the chart
		ch_out <- echarts4r::e_charts(df, d_data, width = '100%', height = 320) %>%
			#100. Add series to the chart
			#110. Add fund price
			echarts4r::e_line(
				Price
				,name = lang_cfg[[lang_disp]][['tblvars']][['Fund_Explorer']][['Price']]
				,itemStyle = list(
					color = color_cfg$CustAct
				)
				,lineStyle = list(
					color = color_cfg$CustAct
				)
				,x_index = 0
				,y_index = 0
			) %>%
			#130. Add customer cost
			echarts4r::e_line(
				AvgCost
				,name = lang_cfg[[lang_disp]][['tblvars']][['Fund_Explorer']][['AvgCost']]
				,itemStyle = list(
					color = color_cfg$Advise
				)
				,lineStyle = list(
					color = color_cfg$Advise
				)
				,x_index = 0
				,y_index = 0
			) %>%
			#300. Setup the axes
			echarts4r::e_y_axis(
				index = 0
				,gridIndex = 0
				,show = TRUE
				,min = 'dataMin'
				,max = 'dataMax'
				,splitLine = list(
					lineStyle = list(
						type = 'dashed'
					)
				)
				,axisLabel = list(
					formatter = htmlwidgets::JS(paste0(
						'function(value,index){'
							,'return('
								,'index != 0 ? ',val_disp$axisLabel,' : ""'
							,');'
						,'}'
					))
					,interval = 0
					,fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
					,color = '#000'
					,margin = 4
				)
				#Define the [axisPointer] on the axis to format the display
				,axisPointer = list(
					show = TRUE
					,label = list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'return('
									,val_disp$axisPointer
								,');'
							,'}'
						))
						,fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
				,axisTick = list(show = TRUE)
			) %>%
			echarts4r::e_x_axis(
				#We ensure the date series cover the entire product table
				data = uRV$FundBase$d_data %>% unique() %>% sort()
				,index = 0
				,gridIndex = 0
				,show = TRUE
				,splitLine = list(
					show = FALSE
				)
				,axisLabel = list(
					formatter = htmlwidgets::JS(paste0(
						'function(value,index){'
							,'return('
								,'echarts.format.formatTime("yyyy-MM-dd",value)'
							,');'
						,'}'
					))
					,interval = 0
					,fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
					,color = '#000'
					,margin = 4
				)
				#Define the [axisPointer] on the axis to format the display
				,axisPointer = list(
					show = TRUE
					,label = list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'return('
									,'echarts.format.formatTime("yyyy-MM-dd",params.value)'
								,');'
							,'}'
						))
						,precision = 4
						,fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
				,axisTick = list(show = TRUE)
			) %>%
			#400. Setup the legend
			echarts4r::e_legend(
				type = 'scroll'
				,pageButtonItemGap = 8
				,pageButtonGap = 8
				,pageIconColor = color_cfg$CustAct
				,pageIconSize = c(12,8)
				,pageTextStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,right = 4
				,top = 48
				,itemWidth = 8
				,itemHeight = 8
				,itemGap = 8
				,formatter = htmlwidgets::JS(paste0(
					'function(name){'
						,'return('
							,'echarts.format.truncateText(name,64,"',uRV$styles_ch_FontSize_item,'px ',font_disp,'","...")'
						,');'
					,'}'
				))
				# ,icon = rep('none',nrow(uRV$colors_ProdCTT))
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,orient = 'vertical'
				,tooltip = list(
					show = TRUE
					,textStyle = list(
						fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
			) %>%
			#500. Setup the title as per input
			echarts4r::e_title(
				text = paste(lang_cfg[[lang_disp]][['charttitle']][['CostPnL']], FundName, sep = ' - ')
				,left = 24
				,top = 4
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_title
				)
			) %>%
			#600. Add an area to declare the colors used in current chart
			echarts4r::e_graphic_g(
				elements = list(
					#IMPORTANT!!! Ensure the [color] of the last element in this list is [#000],
					#              as the colors on the axes will be overwritten by it!
					#IMPORTANT!!! Ensure the [color] of the last element in this list is [#000],
					#              as the colors on the axes will be overwritten by it!
					list(
						type = 'group'
						,right = 8
						,top = 12
						,width = 8
						,height = 8
						,children = list(
							list(
								type = 'circle'
								,id = 'circle1'
								,top = 0
								,left = 'center'
								,shape = list(
									r = 4
								)
								,style = list(
									fill = '#000'
									,lineWidth = 0
								)
							)
						)
					)
					,list(
						type = 'text'
						,id = 'text1'
						,right = 24
						,top = 12
						,style = list(
							text = lang_cfg[[lang_disp]][['charttitle_sub']][['CostPnL']]
							,textAlign = 'right'
							,font = paste0(uRV$styles_ch_FontSize_item,'px ',uRV$font_list_css)
							# ,color = '#000'
						)
					)
				)
			) %>%
			#800. Add zoom to chart
			echarts4r::e_datazoom(
				x_index = 0
				,id = 'dataZoomX'
				,type = 'slider'
				,filterMode = 'filter'
				,bottom = 8
				,borderColor = color_cfg$ech_dz_Border
				,backgroundColor = paste0('rgba(',paste0(uRV$ch_bg_color_rgb,collapse = ','),',0)')
				,dataBackground = list(
					lineStyle = list(
						color = color_cfg$ech_dz_Border
					)
					,areaStyle = list(
						color = paste0('rgba(',paste0(uRV$ch_handle_color_rgb,collapse = ','),',0.3)')
					)
				)
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,labelFormatter = htmlwidgets::JS(paste0(
					'function(value){'
						,'return('
							,'echarts.format.formatTime("yyyy-MM-dd",value)'
						,');'
					,'}'
				))
				,handleStyle = list(
					color = color_cfg$ech_dz_Handle
					,fillerColor = paste0('rgba(',paste0(uRV$ch_handle_color_rgb,collapse = ','),',0.4)')
				)
			) %>%
			#Zoon on Y-axis is just to ensure the lines keep showing in the range [dataMin,dataMax]
			echarts4r::e_datazoom(
				y_index = 0
				,id = 'dataZoomY'
				,type = 'slider'
				#This MUST be set as [empty]!
				,filterMode = 'empty'
				,right = 56
				,show = FALSE
			) %>%
			#[dataZoom] will automatically cause the [toolbox] to show up, we will close it here.
			echarts4r::e_toolbox(
				show = FALSE
			) %>%
			#920. Show a loading animation when the chart is re-drawn
			echarts4r::e_show_loading() %>%
			#980. Enable the tooltip triggered by mouse over the bars
			echarts4r::e_tooltip(
				trigger = 'axis'
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,formatter = htmlwidgets::JS(paste0(
					'function(params){'
						,'var result = "";'
						,'params.forEach(function (item,index) {'
							#[Quote: https://segmentfault.com/q/1010000008101623 ]
							#[marker] is an un-documented attribute of [echarts.series]
							,'result += "<br/>" + item.marker + " " + item.seriesName;'
							,'result += " " + ',val_disp$tooltip,';'
						,'});'
						,'return('
							,'"<strong>" + params[0].value[0] + "</strong>"'
							,' + result'
						,');'
					,'}'
				))
				#Define the [axisPointer] on the tooltip to show the pointer, otherwise it will never show
				,axisPointer = list(
					type = 'cross'
					,label = list(
						precision = 4
						,fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
			)

		#Set proper grid
		grid_ch <- list(index = 0, top = 40, right = 88, bottom = 56, left = 48)
		ch_out <- do.call(echarts4r::e_grid
			,append(
				list(e = ch_out)
				,append(
					grid_ch,
					list(height = 224)
				)
			)
		)
	}

	#405. Prepare the function to draw the charts that compare the funds by specific KPIs
	drawCH_FundPrice <- function(field,charttitle,fmt = c('price','percent')){
		#001. Handle parameters
		if (is.null(charttitle)) stop('Chart Title is not provided!')
		fmt <- match.arg(fmt,c('price','percent'))
		val_item <- list(
			axisLabel = 'value'
			,axisPointer = 'params.value'
			,tooltip = 'item.value[1]'
		)
		if (fmt == 'price') {
			val_disp <- lapply(val_item, function(m){paste0('parseFloat(',m,').toFixed(4)')})
		} else {
			val_disp <- lapply(val_item, function(m){paste0('(parseFloat(',m,') * 100).toFixed(2) + "%"')})
		}
		names(val_disp) <- names(val_item)

		#100. Initialize the chart
		ch_out <- echarts4r::e_charts(width = '100%', height = 320)

		#200. Add series by product name
		for (m in uRV$ch_legend_seq){
			#100. Extract a subset of the product data for current product
			df <- uRV$FundBase_wColor %>%
				dplyr::select_at(c(paste0('ProdName_',lang_disp),'d_data','item_color','c_currency',field)) %>%
				dplyr::filter_at(paste0('ProdName_',lang_disp),~. == m)
			# f_ccy <- df$c_currency %>% unique() %>% .[[1]]
			f_color <- df$item_color %>% unique() %>% .[[1]]

			#200. Add current serie to the chart
			ch_out <- ch_out %>%
				echarts4r::e_data(df,d_data) %>%
				#100. Draw the line
				echarts4r::e_line_(
					field
					,name = m
					,itemStyle = list(
						color = htmlwidgets::JS(paste0(
							'function(params){'
								,'var colorlst = ["',paste0(df$item_color,collapse = '","'),'"];'
								,'return(colorlst[params.dataIndex]);'
							,'}'
						))
					)
					,lineStyle = list(
						color = f_color
					)
					,x_index = 0
					,y_index = 0
				)
		}

		#300. Define the parameters of the chart
		ch_out <- ch_out %>%
			#300. Setup the axes
			echarts4r::e_y_axis(
				index = 0
				,gridIndex = 0
				,show = TRUE
				,min = 'dataMin'
				,max = 'dataMax'
				,splitLine = list(
					lineStyle = list(
						type = 'dashed'
					)
				)
				,axisLabel = list(
					formatter = htmlwidgets::JS(paste0(
						'function(value,index){'
							,'return('
								,'index != 0 ? ',val_disp$axisLabel,' : ""'
							,');'
						,'}'
					))
					,interval = 0
					,fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
					,color = '#000'
					,margin = 4
				)
				#Define the [axisPointer] on the axis to format the display
				,axisPointer = list(
					show = TRUE
					,label = list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'return('
									,val_disp$axisPointer
								,');'
							,'}'
						))
						,fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
				,axisTick = list(show = TRUE)
			) %>%
			echarts4r::e_x_axis(
				#We ensure the date series cover the entire product table
				data = uRV$FundBase$d_data %>% unique() %>% sort()
				,index = 0
				,gridIndex = 0
				,show = TRUE
				,splitLine = list(
					show = FALSE
				)
				,axisLabel = list(
					formatter = htmlwidgets::JS(paste0(
						'function(value,index){'
							,'return('
								,'echarts.format.formatTime("yyyy-MM-dd",value)'
							,');'
						,'}'
					))
					,interval = 0
					,fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
					,color = '#000'
					,margin = 4
				)
				#Define the [axisPointer] on the axis to format the display
				,axisPointer = list(
					show = TRUE
					,label = list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'return('
									,'echarts.format.formatTime("yyyy-MM-dd",params.value)'
								,');'
							,'}'
						))
						,precision = 4
						,fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
				,axisTick = list(show = TRUE)
			) %>%
			#400. Setup the legend
			echarts4r::e_legend(
				type = 'scroll'
				,pageButtonItemGap = 8
				,pageButtonGap = 8
				,pageIconColor = color_cfg$CustAct
				,pageIconSize = c(12,8)
				,pageTextStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,right = 4
				,top = 48
				,itemWidth = 8
				,itemHeight = 8
				,itemGap = 8
				,formatter = htmlwidgets::JS(paste0(
					'function(name){'
						,'return('
							,'echarts.format.truncateText(name,64,"',uRV$styles_ch_FontSize_item,'px ',font_disp,'","...")'
						,');'
					,'}'
				))
				# ,icon = rep('none',nrow(uRV$colors_ProdCTT))
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,orient = 'vertical'
				,tooltip = list(
					show = TRUE
					,textStyle = list(
						fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
			) %>%
			#500. Setup the title as per input
			echarts4r::e_title(
				text = lang_cfg[[lang_disp]][['charttitle']][[charttitle]]
				,left = 24
				,top = 4
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_title
				)
			) %>%
			#600. Add an area to declare the colors used in current chart
			echarts4r::e_graphic_g(
				elements = list(
					#IMPORTANT!!! Ensure the [color] of the last element in this list is [#000],
					#              as the colors on the axes will be overwritten by it!
					list(
						type = 'group'
						,right = 8
						,top = 8
						,width = 8
						,height = 18
						,children = list(
							list(
								type = 'circle'
								,id = 'circle1'
								,top = 0
								,left = 'center'
								,shape = list(
									r = 4
								)
								,style = list(
									fill = color_cfg$CustAct
									,lineWidth = 0
								)
							)
							,list(
								type = 'circle'
								,id = 'circle2'
								,top = 10
								,left = 'center'
								,shape = list(
									r = 4
								)
								,style = list(
									fill = color_cfg$Advise
									,lineWidth = 0
								)
							)
						)
					)
					,list(
						type = 'text'
						,id = 'text1'
						,right = 24
						,top = 8
						,style = list(
							text = lang_cfg[[lang_disp]][['charttitle_sub']][['FundPrice']]
							,textAlign = 'right'
							,font = paste0(uRV$styles_ch_FontSize_item,'px ',uRV$font_list_css)
							,color = '#000'
						)
					)
				)
			) %>%
			#800. Add zoom to chart
			echarts4r::e_datazoom(
				x_index = 0
				,id = 'dataZoomX'
				,type = 'slider'
				,filterMode = 'filter'
				,bottom = 8
				,borderColor = color_cfg$ech_dz_Border
				,backgroundColor = paste0('rgba(',paste0(uRV$ch_bg_color_rgb,collapse = ','),',0)')
				,dataBackground = list(
					lineStyle = list(
						color = color_cfg$ech_dz_Border
					)
					,areaStyle = list(
						color = paste0('rgba(',paste0(uRV$ch_handle_color_rgb,collapse = ','),',0.3)')
					)
				)
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,labelFormatter = htmlwidgets::JS(paste0(
					'function(value){'
						,'return('
							,'echarts.format.formatTime("yyyy-MM-dd",value)'
						,');'
					,'}'
				))
				,handleStyle = list(
					color = color_cfg$ech_dz_Handle
					,fillerColor = paste0('rgba(',paste0(uRV$ch_handle_color_rgb,collapse = ','),',0.4)')
				)
			) %>%
			#Zoon on Y-axis is just to ensure the lines keep showing in the range [dataMin,dataMax]
			echarts4r::e_datazoom(
				y_index = 0
				,id = 'dataZoomY'
				,type = 'slider'
				#This MUST be set as [empty]!
				,filterMode = 'empty'
				,right = 56
				,show = FALSE
			) %>%
			#[dataZoom] will automatically cause the [toolbox] to show up, we will close it here.
			echarts4r::e_toolbox(
				show = FALSE
			) %>%
			#920. Show a loading animation when the chart is re-drawn
			echarts4r::e_show_loading() %>%
			#980. Enable the tooltip triggered by mouse over the bars
			echarts4r::e_tooltip(
				trigger = 'axis'
				,textStyle = list(
					fontFamily = font_disp
					,fontSize = uRV$styles_ch_FontSize_item
				)
				,formatter = htmlwidgets::JS(paste0(
					'function(params){'
						#We have to prepare the arrays in JS to look for the respective currencies,
						# otherwise JS would collapse when any items among the legend are hidden by clicking.
						,'var lstfund = ["',paste0(uRV$ch_legend_seq,collapse = '","'),'"];'
						,'var lstccy = ["',paste0(uRV$ch_ccy_seq,collapse = '","'),'"];'
						,'var result = "";'
						,'params.forEach(function (item,index) {'
							#[Quote: https://segmentfault.com/q/1010000008101623 ]
							#[marker] is an un-documented attribute of [echarts.series]
							,'result += "<br/>" + item.marker + " " + item.seriesName;'
							#Add currency to the tooltip
							,'result += " : " + lstccy[lstfund.indexOf(item.seriesName)];'
							,'result += " " + ',val_disp$tooltip,';'
						,'});'
						,'return('
							,'"<strong>" + params[0].value[0] + "</strong>"'
							,' + result'
						,');'
					,'}'
				))
				#Define the [axisPointer] on the tooltip to show the pointer, otherwise it will never show
				,axisPointer = list(
					type = 'cross'
					,label = list(
						precision = 4
						,fontFamily = font_disp
						,fontSize = uRV$styles_ch_FontSize_item
					)
				)
			)

		#Set proper grid
		grid_ch <- list(index = 0, top = 40, right = 88, bottom = 56, left = 48)
		ch_out <- do.call(echarts4r::e_grid
			,append(
				list(e = ch_out)
				,append(
					grid_ch,
					list(height = 224)
				)
			)
		)
	}

	#410. Draw the Cost vs. P&L charts for all the product names as provided
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Draw charts][IN][Cost vs. P&L]')))
	}
	uRV$CostPnL <- list()
	uRV$Ech_CostPnL <- seq_along(pnllst)
	#[for] loop cannot create the output value!
	sapply(uRV$Ech_CostPnL,function(i){
		uRV$CostPnL[[i]] <- drawCH_CostPnL(pnllst[[i]])
		output[[paste0('EchOut_CostPnL',i)]] <- echarts4r::renderEcharts4r({uRV$CostPnL[[i]]})
	})
	names(uRV$CostPnL) <- pnllst
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Draw charts][OUT][Cost vs. P&L]')))
	}

	#430. Prepare the data for the next steps
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[430][Prepare data for more charts][IN][colors and currencies]')))
	}

	#431. Prepare the colors in descending alpha by the product holding amount as well as product P&L
	#Color starts from dark (higher holding) to light (lower holding), then by descending product P&L
	uRV$df_color_Holding <- FundForComp %>%
		dplyr::filter(FC_Holding == 'Yes', d_data == ObsDate) %>%
		dplyr::arrange(desc(bal_bcy),desc(Last7Day_PnL_pa)) %>%
		dplyr::select_at(paste0('ProdName_',lang_disp))
	uRV$df_color_Holding$item_color <- rgba2rgb(
		rep(color_cfg$CustAct,nrow(uRV$df_color_Holding))
		,alpha_in = seq(1,0.2,length.out = nrow(uRV$df_color_Holding))
	)
	#Color starts from dark (higher product P&L) to light (lower product P&L)
	uRV$df_color_NonHold <- FundForComp %>%
		dplyr::filter(FC_Holding == 'No', d_data == ObsDate) %>%
		dplyr::arrange(desc(Last7Day_PnL_pa)) %>%
		dplyr::select_at(paste0('ProdName_',lang_disp))
	uRV$df_color_NonHold$item_color <- rgba2rgb(
		rep(color_cfg$Advise,nrow(uRV$df_color_NonHold))
		,alpha_in = seq(1,0.2,length.out = nrow(uRV$df_color_NonHold))
	)

	uRV$FundBase_wColor <- FundForComp %>%
		dplyr::left_join(
			uRV$df_color_Holding
			,by = paste0('ProdName_',lang_disp)
			,suffix = c('', '.hold')
		) %>%
		dplyr::left_join(
			uRV$df_color_NonHold
			,by = paste0('ProdName_',lang_disp)
			,suffix = c('', '.nhold')
		) %>%
		dplyr::mutate(item_color = ifelse(is.na(item_color),item_color.nhold,item_color)) %>%
		dplyr::select(-tidyselect::ends_with('.nhold'))

	#435. Order the products in the charts, by the customer holding amount and then the product P&L
	#IMPORTANT!!! This sequence also determines the sequence of the items listed in the [legend].
	uRV$ch_legend_seq <- uRV$FundBase_wColor %>%
		dplyr::arrange(desc(bal_bcy),desc(Last7Day_PnL_pa)) %>%
		dplyr::select_at(paste0('ProdName_',lang_disp)) %>%
		unique() %>%
		unlist()
	names(uRV$ch_legend_seq) <- NULL

	#436. Below is to create the tooltip on the chart
	uRV$ch_ccy_seq <- uRV$FundBase_wColor %>%
		dplyr::arrange(desc(bal_bcy),desc(Last7Day_PnL_pa)) %>%
		dplyr::select_at(c(paste0('ProdName_',lang_disp),'c_currency')) %>%
		unique() %>%
		dplyr::select_at('c_currency') %>%
		unlist()
	names(uRV$ch_ccy_seq) <- NULL
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[430][Prepare data for more charts][out][colors and currencies]')))
	}

	#440. Draw the chart of Product Price
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[440][Draw charts][IN][Product prices]')))
	}
	uRV$ch_FundPrice <- drawCH_FundPrice('Price','FundPrice',fmt = 'price')
	output$EchOut_FundPrice <- echarts4r::renderEcharts4r({uRV$ch_FundPrice})
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[440][Draw charts][OUT][Product prices]')))
	}

	#470. Draw the Product P&L charts
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[470][Draw charts][IN][Product P&L]')))
	}
	uRV$ProdPnL <- list()
	uRV$Ech_ProdPnL <- seq_along(uRV$Var_Names)
	#[for] loop cannot create the output value!
	sapply(uRV$Ech_ProdPnL,function(i){
		uRV$ProdPnL[[i]] <- drawCH_FundPrice(uRV$Var_Names[[i]],uRV$Var_Names[[i]],fmt = uRV$Var_Types[[i]])
		output[[paste0('EchOut_ProdPnL',i)]] <- echarts4r::renderEcharts4r({uRV$ProdPnL[[i]]})
	})
	names(uRV$ProdPnL) <- uRV$Var_Names
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[470][Draw charts][OUT][Product P&L]')))
	}

	#595. Increment the progress when necessary
	#[Quote: https://stackoverflow.com/questions/44367004/r-shiny-destroy-observeevent ]
	#We suspend the observer once the progress bar is closed
	session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]] <- shiny::observeEvent(
		uRV$pb_cnt_chart
		,{
			if (is.null(uRV$pb_chart)) return()
			#Close the progress bar as long as its value reaches 100%
			# shiny::invalidateLater(uRV$k_ms_invld,session)
			if (!is.environment(uRV$pb_chart$.__enclos_env__$private)) return()
			if (uRV$pb_cnt_chart >= uRV$pb_k$chart){
				if (!uRV$pb_chart$.__enclos_env__$private$closed) try(uRV$pb_chart$close(), silent = T)
				uRV$pb_cnt_chart <- 0
				session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]]$destroy()
			}
		}
		# ,suspended = T
	)

	#700. Create UI

	#790. Final UI
	#791. [tabBox] that contains the charts of [Cost vs. P&L] by products
	output$uDiv_CostPnL <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[791][renderUI][IN][output$uDiv_CostPnL]')))
		}
		#008. Create a progress bar to notify the user when a large dataset is being loaded for chart drawing
		uRV$pb_chart <- shiny::Progress$new(session, min = 0, max = uRV$pb_k$chart)

		#009. Start to display the progress bar
		uRV$pb_chart$set(message = paste0('Fund Comparison [2/',uRV$pb_k_all,']'), value = 0)

		#Take dependency from below action (without using its value):

		#Increment the progress bar
		#[Quote: https://nathaneastwood.github.io/2017/08/13/accessing-private-methods-from-an-r6-class/ ]
		#[Quote: https://github.com/rstudio/shiny/blob/master/R/progress.R ]
		if (is.environment(uRV$pb_chart$.__enclos_env__$private)) if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Cost vs. P&L'))
			uRV$pb_cnt_chart <- shiny::isolate(uRV$pb_cnt_chart) + 1
		}

		#Render UI
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			#Below is a weird solution, but it works!
			#[Quote: https://stackoverflow.com/questions/56410385/how-to-use-lapply-or-another-higher-order-function-when-calling-tabpanel-in-r-sh ]
			,do.call(
				function(...){
					shinydashboard::tabBox(
						title = shiny::tags$span(
							style = uRV$styles_tabBox_font
							,lang_cfg[[lang_disp]][['tabboxnames']][['CostPnL']]
						#End of [span]
						)
						# The id lets us use input$tabset1 on the server to find the current tab
						,id = ns('uTB_CostPnL')
						,width = uRV$uTB_width
						,...
					)
				}
				,mapply(
					function(title, plotid){
						shiny::tabPanel(
							shiny::tags$span(
								style = uRV$styles_tabBox_font
								,title
							#End of [span]
							)
							,echarts4r::echarts4rOutput(ns(paste0('EchOut_CostPnL',plotid)), height = 320)
						)
					}
					,pnllst
					,uRV$Ech_CostPnL
					,SIMPLIFY = FALSE
					,USE.NAMES = FALSE
				)
			)
		#End of [tagList]
		)
	#End of [renderUI] of [791]
	})

	#793. Product prices
	crTag_FundPrice <- function(el){
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shinydashboard::tabBox(
				title = shiny::tags$span(
					style = uRV$styles_tabBox_font
					,lang_cfg[[lang_disp]][['tabboxnames']][['FundPrice']]
				#End of [span]
				)
				# The id lets us use input$tabset1 on the server to find the current tab
				,id = ns('uTB_FundPrice')
				,width = uRV$uTB_width
				,shiny::tabPanel(
					shiny::tags$span(
						style = uRV$styles_tabBox_font
						,lang_cfg[[lang_disp]][['tabnames']][['FundPricePrime']]
					#End of [span]
					)
					,el
				)
			)
		#End of [tagList]
		)
	}
	uRV$print_FundPrice <- uRV$ch_FundPrice
	output$uDiv_FundPrice <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[793][renderUI][IN][output$uDiv_FundPrice]')))
		}
		#Increment the progress bar
		if (is.environment(uRV$pb_chart$.__enclos_env__$private)) if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Fund Prices'))
			uRV$pb_cnt_chart <- shiny::isolate(uRV$pb_cnt_chart) + 1
		}

		crTag_FundPrice(echarts4r::echarts4rOutput(ns(paste0('EchOut_FundPrice')), height = 320))
	#End of [renderUI] of [793]
	})

	#795. [tabBox] that contains the charts of [Cost vs. P&L] by products
	output$uDiv_FundPnL <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[795][renderUI][IN][output$uDiv_FundPnL]')))
		}
		#Increment the progress bar
		if (is.environment(uRV$pb_chart$.__enclos_env__$private)) if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Fund P&L'))
			uRV$pb_cnt_chart <- shiny::isolate(uRV$pb_cnt_chart) + 1
		}
		# on.exit(try(uRV$pb_chart$close(), silent = T))

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			#Below is a weird solution, but it works!
			#[Quote: https://stackoverflow.com/questions/56410385/how-to-use-lapply-or-another-higher-order-function-when-calling-tabpanel-in-r-sh ]
			,do.call(
				function(...){
					shinydashboard::tabBox(
						title = shiny::tags$span(
							style = uRV$styles_tabBox_font
							,lang_cfg[[lang_disp]][['tabboxnames']][['FundPnL']]
						#End of [span]
						)
						# The id lets us use input$tabset1 on the server to find the current tab
						,id = ns('uTB_FundPnL')
						,width = uRV$uTB_width
						,...
					)
				}
				,mapply(
					function(title, plotid){
						shiny::tabPanel(
							shiny::tags$span(
								style = uRV$styles_tabBox_font
								,lang_cfg[[lang_disp]][['tabnames']][[title]]
							#End of [span]
							)
							,echarts4r::echarts4rOutput(ns(paste0('EchOut_ProdPnL',plotid)), height = 320)
						)
					}
					,uRV$Var_Names
					,uRV$Ech_ProdPnL
					,SIMPLIFY = FALSE
					,USE.NAMES = FALSE
				)
			)
		#End of [tagList]
		)
	#End of [renderUI] of [795]
	})
	uRV$knitr_params <- list(
		print_CostPnL = uRV$CostPnL
		,print_FundPrice = uRV$print_FundPrice
		,print_FundPnL = uRV$ProdPnL
	)

	#999. Return the result
	#Next time I may try to append values as instructed below:
	#[Quote: https://community.rstudio.com/t/append-multiple-reactive-output-of-a-shiny-module-to-an-existing-reactivevalue-object-in-the-app/36985/2 ]
	return(
		list(
			CallCounter = shiny::reactive({uRV_finish()})
			,ActionDone = shiny::reactive({uRV$ActionDone()})
			,EnvVariables = shiny::reactive({uRV})
		)
	)
}

#[Full Test Program;]
if (FALSE){
	if (interactive()){
		lst_pkg <- c( 'tmcn'
			, 'shiny', 'lubridate', 'dplyr', 'grDevices', 'htmlwidgets', 'tidyselect', 'shinydashboard', 'echarts4r'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		omniR <- 'D:\\R\\omniR'
		source(normalizePath(file.path(omniR,'Styles','rgba2rgb.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','rem_shiny_inputs.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','gc_shiny_module.r')),encoding = 'utf-8')

		#Load necessary data
		myProj <- 'D:\\R\\Project'
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','theme_color_sets.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Data','Test_PortMgmt_LoadData.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','lang_PortMgmt.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','color_PortMgmt.r')), encoding = 'utf-8')

		ui <- shinydashboardPlus::dashboardPagePlus(
			header = shinydashboardPlus::dashboardHeaderPlus()
			,sidebar = shinydashboard::dashboardSidebar(
				shinydashboard::sidebarMenu(id = 'left_sidebar'
					#[Icons are from the official page: https://adminlte.io/themes/AdminLTE/pages/UI/icons.html ]
					,shinydashboard::menuItem(
						'Portfolio Management'
						,tabName = 'uMI_PortMgmt'
						,icon = shiny::icon('bar-chart')
					)
					,shinydashboard::menuItem(
						'Print Report'
						,tabName = 'uMI_PrintRpt'
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
						shinydashboard::tabItem(tabName = 'uMI_PortMgmt'
							,shiny::column(width = 3
							,shinyWidgets::prettyToggle(inputId = 'toggle'
								,label_on = 'CN'
								,status_on = 'default'
								,icon_on = icon('ok-circle', lib = 'glyphicon')
								,label_off = 'EN'
								,status_off = 'default'
								,icon_off = icon('remove-circle', lib = 'glyphicon')
								,plain = TRUE
								,inline = TRUE
							)
							)
							,shiny::column(width = 9
								,shiny::fluidRow(shiny::uiOutput('modUI1'))
								,shiny::fluidRow(shiny::uiOutput('modUI2'))
								,shiny::fluidRow(shiny::uiOutput('modUI3'))

							)
						#End of [tabItem]
						)
						#Add one [tabItem]
						,shinydashboard::tabItem(tabName = 'uMI_PrintRpt'
							,shiny::column(width = 9
								,shiny::fluidRow(shiny::downloadButton('Save','Download Report'))
							)
						#End of [tabItem]
						)
					#End of [tabItems]
					)
				)
			)
			,rightsidebar = shinydashboardPlus::rightSidebar()
			,title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$mFC <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0)
				,ActionDone = shiny::reactive({FALSE})
				,EnvVariables = shiny::reactive({NULL})
			)

			CustData <- uRV$PM_rpt

			output$modUI1 <- shiny::renderUI({UM_FundCmp_ui_CostPnL(modout$ID_Mod)})
			output$modUI2 <- shiny::renderUI({UM_FundCmp_ui_FundPrice(modout$ID_Mod)})
			output$modUI3 <- shiny::renderUI({UM_FundCmp_ui_FundPnL(modout$ID_Mod)})

			shiny::observe(
				{
					#100. Take dependencies
					input$toggle

					#900. Execute below block of codes only once upon the change of any one of above dependencies
					shiny::isolate({
						if (is.null(input$toggle)) return()

						if (input$toggle) lang_disp <- 'CN'
						else lang_disp <- 'EN'

						fundlst <- CustData$Fund_Sel %>%
							dplyr::filter(d_data <= CustData$CurrDate) %>%
							dplyr::select_at(paste0('ProdName_',lang_disp)) %>%
							unique() %>%
							as.data.frame() %>%
							dplyr::mutate_if(is.factor,as.character)
						names(fundlst) <- paste0('ProdName_',lang_disp)

						suppressMessages(
							FundBase <- CustData$Fund_Sel %>%
								dplyr::filter(d_data <= CustData$CurrDate) %>%
								dplyr::inner_join(fundlst,suffix = c('', '.flt'))
						)

						var_DrawCH <- c(
							'Last7Day_PnL_pa' = 'percent'
							,'PnLPredict_3m_pa' = 'percent'
							,'PnLPredict_6m_pa' = 'percent'
							,'PnLPredict_12m_pa' = 'percent'
						)

						#IMPORTANT!!! We always have to create a new ID for the module!
						#The internal observers from the previous call of this module cannot be omitted by [shiny] mechanism!
						# modout$ID_Mod <- paste0('FC','_',floor(runif(1) * 10^6))
						modout$ID_Mod <- paste0('FC','_',1)

						#Garbage collection of the previous call
						#[Quote: [omniR$AdvOp$gc_shiny_module]]
						gc_shiny_module(
							modout$ID_Mod
							,input
							,session
							,UI_Selectors = NULL
							,UI_namespaced = T
							,observer_pfx = 'uObs'
						)

						modout$mFC <- shiny::callModule(
							UM_FundCompare_svr
							,modout$ID_Mod
							,FundForComp = FundBase
							,ObsDate = CustData$CurrDate
							,VarComp = var_DrawCH
							,lang_cfg = lang_CPM
							,color_cfg = color_CPM
							,lang_disp = lang_disp
							,font_disp = 'Microsoft YaHei'
							,observer_pfx = 'uObs'
							,fDebug = FALSE
						)

						modout$params <- modout$mFC$EnvVariables()$knitr_params
					#End of [isolate]
					})
				}
				,label = '[500]Monitor the status of the module call'
			)
			shiny::observeEvent(modout$params,{
				if (is.null(modout$params)) return()
				params_global <<- modout$params
				#[Quote: https://shiny.rstudio.com/articles/generating-reports.html ]
				output$Save <- shiny::downloadHandler(
					filename = 'PortMgmt.html'
					,content = function(file){
						tempReport <- file.path(tempdir(),'JointPlots.Rmd')
						file.copy(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortMgmt.Rmd')), tempReport, overwrite = TRUE)
						rmarkdown::render(
							tempReport
							,output_file = file
							,params = modout$params
							,envir = new.env(parent = globalenv())
						)
					}
				)
			})
			shiny::observeEvent(modout$mFC$CallCounter(),{
				if (modout$mFC$CallCounter() == 0) return()
				message('[mFC$CallCounter()]:',modout$mFC$CallCounter())
			})
		}

		shinyApp(ui, server)
	}

}

#[Test Rmarkdown]
if (FALSE){
	reportTpl <- normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortMgmt.Rmd'))
	rpt_html <- normalizePath(file.path(omniR,'UsrShinyModules','Ops','PortMgmt.html'))
	rpt_pdf <- normalizePath(file.path(omniR,'UsrShinyModules','Ops','PortMgmt.pdf'))
	tempReport <- file.path(tempdir(),'custPortMgmt.Rmd')
	file.copy(reportTpl, tempReport, overwrite = TRUE)
	rmarkdown::render(
		tempReport
		,output_file = rpt_html
		,params = params_global
		,envir = new.env(parent = globalenv())
	)

}

#[Partial Test Program;]
if (FALSE){
	source(normalizePath(file.path(myProj,'Analytics','Func','UI','theme_color_sets.r')), encoding = 'utf-8')
	source(normalizePath(file.path(myProj,'Analytics','Data','Test_PortMgmt_LoadData.r')), encoding = 'utf-8')
	source(normalizePath(file.path(myProj,'Analytics','Func','UI','lang_PortMgmt.r')), encoding = 'utf-8')
	source(normalizePath(file.path(myProj,'Analytics','Func','UI','color_PortMgmt.r')), encoding = 'utf-8')
	uRV$chb <- uRV$PM_rpt
	CustData <- uRV$chb
	lang_cfg <- lang_CPM
	lang_disp <- 'CN'

	#Below please paste related code snippets and execute

}
