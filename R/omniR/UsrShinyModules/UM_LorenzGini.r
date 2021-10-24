# User Defined Module: [Display Lorenz Curve & Gini Coefficient for Selected Variable in Data Frame]
# Required User-specified parameters:
# [usrdf_Lnz]: Data frame for Concentration Analysis
# [usrls_Lnz_BalSel]: Variables in the input data frame to select for Concentration Analysis

# [plotly] charts: https://plot.ly/r/#basic-charts
# [plotly] layout: https://plot.ly/r/reference

# [Quote:[~/Func/DataProc/transStatsData.r]]

UM_LorenzGini_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	#Add box which contains the plotting result for Lorenz Curve.
	shinydashboardPlus::boxPlus(collapsible = TRUE,width = 12,
		title = "Concentration Analysis for Single Variable",
		status = "primary",
		solidHeader = FALSE,
		closable = FALSE,
		enable_sidebar = TRUE,
		sidebar_width = 25,
		sidebar_start_open = TRUE,
		sidebar_content = shiny::tagList(
			shiny::selectInput(ns("uWg_pi_Lnz_Bal"),NULL,choices = get(usrls_Lnz_BalSel)),
			shinyWidgets::prettyToggle(
				inputId = ns("uWg_pt_Lnz_Bal0"),
				label_on = "Include 0 Balance Customers",
				label_off = "Exclude 0 Balance Customers",
				icon_on = shiny::icon("check"),
				status_on = "primary",
				icon_off = shiny::icon("remove"),
				status_off = "primary"
			),
			#Add the date range selection
			shiny::sliderInput(ns("uWg_SI_Lnz"), "Data Date",
				gv_dates_min, gv_dates_max, c(gv_dates_min,gv_dates_max)
			)
			#Add input box to resize the [barWidth] for histogram generated by [recharts::echartr]
			# numericInput(ns("uWg_NI_Lnz"), "Histogram Bar Width:", 40, min = 10, max = 60)
		),

		#Add a fluid row.
		shiny::fluidRow(
			#Add box which contains the plotting result for Lorenz Curve.
			shinydashboardPlus::boxPlus(
				title = "Lorenz Curve",
				# status = "primary",
				solidHeader = FALSE, collapsible = TRUE, width = 6,
				closable = FALSE,
				#Add the plot result
				echarts4r::echarts4rOutput(ns("up_Lnz_Lorenz"))
				# plotlyOutput(ns("up_Lnz_Lorenz"))
				# eChartOutput(ns("up_Lnz_Lorenz"))
				# plotOutput(ns("up_Lnz_Lorenz"), height = 400)
			#End of [box]
			),
			#Add box which contains the plotting result for Histogram.
			shinydashboardPlus::boxPlus(
				title = "Distribution Histogram",
				# status = "primary",
				solidHeader = FALSE, collapsible = TRUE, width = 6,
				closable = FALSE,
				#Add the plot result
				echarts4r::echarts4rOutput(ns("up_Lnz_Histo"))
				# plotlyOutput(ns("up_Lnz_Histo"))
				# eChartOutput(ns("up_Lnz_Histo"))
				# plotOutput(ns("up_Lnz_Histo"), height = 400)
			)
		#End of [fluidRow]
		),

		#Add a fluid row.
		shiny::fluidRow(
			#Add info box which contains the Gini Coefficient.
			shinydashboard::infoBox(
				"Gini Coefficient",
				shiny::uiOutput(ns("ut_Lnz_Gini")),
				shiny::uiOutput(ns("ut_Lnz_Var")),
				icon = shiny::icon("balance-scale"),
				color = "light-blue",
				fill = FALSE
			)
		#End of [fluidRow]
		)
	#End of [box]
	)
}

UM_LorenzGini_svr <- function(input,output,session){
	#Filter the data frame reactively from user selection
	ur_Lorenz_df <- shiny::reactive({
		df <- get(usrdf_Lnz) %>%
			filter(.,
				.[[gv_dates_var]] >= min(input$uWg_SI_Lnz) ,
				.[[gv_dates_var]] <= max(input$uWg_SI_Lnz)
			)
		if (input$uWg_pt_Lnz_Bal0 == FALSE) df <- df %>% filter(.,.[[input$uWg_pi_Lnz_Bal]] > 0)
		colpos <- which(sapply(names(df), function(x){x==input$uWg_pi_Lnz_Bal}))
		df <- df %>% select(colpos)
		names(df)[1] <- "eval_var"
		return(df)
	})
	#Prepare data from for Lorenz Curve
	ur_Lorenz_cv <- shiny::reactive({
		tmplc <- ur_Lorenz_df() %>% unlist() %>% as.vector() %>%  ineq::Lc()
		df_out <- data.frame(x = tmplc$p , y = tmplc$L)
	})
	#Calculate the Gini Coefficient
	ur_Gini <- shiny::reactive({
		ur_Lorenz_df() %>% unlist() %>% as.vector() %>% ineq::Gini()
	})

	#Render the Lorenz Curve
	#[Quote:[echarts4r]]
	output$up_Lnz_Lorenz <- echarts4r::renderEcharts4r(
		ur_Lorenz_cv() %>%
			e_charts(x,timeline = FALSE) %>%
			e_area(y,areaStyle = list(opacity = .75)) %>%
			e_datazoom(x_index = 0) %>%
			e_legend(FALSE) %>%
			e_theme_custom(paste0('{"color":["',myApp_themecolorset$s08$p[[length(myApp_themecolorset$s08$p)-1]],'"]}')) %>%
			e_tooltip(
				trigger = "item",
				axisPointer = list(
					type = "cross"
				)
			)
	)
	#[Quote:[plotly]]
	# output$up_Lnz_Lorenz <- renderPlotly(
	# 	plot_ly(ur_Lorenz_cv() , x = ~x , y = ~y , type = "scatter", mode = 'lines', fill = 'tozeroy') %>%
	# 		layout(xaxis = list(title = "% Count") , yaxis = list(title = "% Sum"))
	# )
	#[Quote:[recharts]]
	# output$up_Lnz_Lorenz <- renderEChart(
	# 	echartr(ur_Lorenz_cv(), x, y, type='wave') %>%
	# 	    setTitle(paste0("Lorenz Curve for Variable: [",input$uWg_pi_Lnz_Bal,"]")) %>%
	# 		setXAxis(min = 0 , max = 1) %>%
	# 		setYAxis(min = 0 , max = 1) %>%
	# 	    setSymbols('none')
	# )
	#[Quote:[ggplot2]]
	# output$up_Lnz_Lorenz <- renderPlot({
	# 	ggplot(ur_Lorenz_cv(),aes(x,y,colour = "red")) +
	# 		geom_line() +
	# 		geom_abline() +
	# 		ggtitle(paste0("Lorenz Curve for Variable: [",input$uWg_pi_Lnz_Bal,"]"))
	# })

	#Render the Histogram
	#[Quote:[echarts4r]]
	output$up_Lnz_Histo <- echarts4r::renderEcharts4r(
		ur_Lorenz_df() %>%
			e_charts(eval_var,timeline = FALSE) %>%
			e_histogram(eval_var,bar_width = "90%",itemStyle = list(opacity = .75)) %>%
			e_density(eval_var,areaStyle = list(opacity = .1),y_index = 1) %>%
			e_datazoom(x_index = 0) %>%
			e_legend(FALSE) %>%
			e_theme_custom(
				paste0('{"color":[',
					'"',myApp_themecolorset$s08$p[[length(myApp_themecolorset$s08$p)-1]],'",',
					'"',myApp_themecolorset$s06$p[[1]],'"',
					']}'
				)
			) %>%
			e_tooltip(
				trigger = "item",
				axisPointer = list(
					type = "cross"
				)
			)
	)
	#[Quote:[plotly]]
	# output$up_Lnz_Histo <- renderPlotly(
	# 	plot_ly(ur_Lorenz_df() , x = ~eval_var , type = "histogram" , alpha = 0.6) %>%
	# 		layout(bargap = 0.1) %>%
	# 		layout(xaxis = list(title = input$uWg_pi_Lnz_Bal) , yaxis = list(title = "# Cust."))
	# )
	#[Quote:[recharts]]
	# output$up_Lnz_Histo <- renderEChart(
	# 	echartr(ur_Lorenz_df(),eval_var,type='hist', subtype='freq') %>%
	# 	    setTitle(paste0("Histogram for Variable: [",input$uWg_pi_Lnz_Bal,"]")) %>%
	# 		setYAxis(name="Density") %>%
	# 	    setTooltip(formatter='none') %>%
	# 		setSeries(1, barWidth=input$uWg_NI_Lnz)
	# )
	#[Quote:[base]]
	# output$up_Lnz_Histo <- renderPlot({
	# 	ur_Lorenz_df() %>% unlist() %>% as.vector() %>% hist()
	# })

	#Print the Gini Coefficient
	output$ut_Lnz_Gini <- shiny::renderText({
		prettyNum(as.numeric(ur_Gini()))
	})
	#Additional text messages
	output$ut_Lnz_Var <- shiny::renderText({
		paste0("Concentration of Variable [",input$uWg_pi_Lnz_Bal,"]")
	})
}
