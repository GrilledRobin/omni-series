# User Defined Module: [Display a timeline of Movies, with linkages to launch the media player to watch the selected movie]
# Required User-specified parameters:
# [usrdf_Mov]: Data frame as Movie list
# [usrdf_Mov_PhsSel]: Data frame for Phase Selection
# [usrdf_Mov_SrsSel]: Data frame for Series Selection
# [gv_Movies_PhID]: Column Name of Phase ID
# [gv_Movies_PhNM]: Column Name of Phase Name
# [gv_Movies_SrNM]: Column Name of Series Name
# [gv_Movies_Date]: Column Name of Movie Publish Date
# [gv_Movies_MNM]: Column Name of Movie Name in original language
# [gv_Movies_MNMCN]: Column Name of Movie Name in Chinese
# [gv_Movies_MDesc]: Column Name of Movie Description to be shown on the startup UI
# [gv_Movies_MPicLoc]: Column Name of Picture location in current App (inside [.\www] folder)
# [gv_Movies_MPicNm]: Column Name of Picture Name
# [gv_Movies_MFilLoc]: Column Name of Video clip file location
# [gv_Movies_MFilNm]: Column Name of Video clip name
# [gv_Movies_Modal]: Column Name of description content to be shown in the popup modal

# [Quote:[~/Func/DataProc/transMovieList.r]]
# [Quote: "uTLB": User defined Timeline Block]
# [Quote: "AB": Action Button]
# [Quote: "cbI": Check Box Input]
# [Quote: "uWg": User defined Widgets]

UM_MovieTimeTable_observe <- function(){
	ustr_df_func <- get(usrdf_Mov) %>% arrange(desc(.[[gv_Movies_Date]]))
	sapply(1:nrow(ustr_df_func), FUN = function(i){
		shiny::observe({
			shinyjs::onclick(paste0("uAB_Mov_",usrdf_Mov,"_",ustr_df_func$ActionID)[[i]],{
				shiny::showModal(
					shiny::modalDialog(
						title = paste0('This movie is ',ustr_df_func[[gv_Movies_MNM]][[i]],'!'),
						ustr_df_func[[gv_Movies_Modal]][[i]]
					)
				)
				shell.exec(normalizePath(paste0(ustr_df_func[[gv_Movies_MFilLoc]][[i]],"\\\\",ustr_df_func[[gv_Movies_MFilNm]][[i]])))
			})
		})
	})
}

UM_MovieTimeTable_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	#Add box which contains the plotting result for Lorenz Curve.
	shinydashboardPlus::boxPlus(collapsible = TRUE,width = 12,
		title = "Movie Time Table",
		status = "primary",
		solidHeader = TRUE,
		closable = FALSE,
		enable_sidebar = TRUE,
		sidebar_width = 25,
		sidebar_start_open = TRUE,
		sidebar_content = shiny::tagList(
			#Add a buttion to reset all the filters when necessary.
			#Hide the button if there is no active filter.
			shiny::uiOutput(ns("uBtn_ResetFilter")),
			#Add checkbox selector for Movie Publish Years
			# shinyWidgets::pickerInput(ns("uWg_pI_Mov_Yrs"), "上映年份：",
			# 	multiple = TRUE,
			# 	choices = usrls_Mov_YrsSel,
			# 	options = pickerOptions(
			# 		actionsBox = TRUE,
			# 		noneSelectedText = "未选择",
			# 		selectAllText = "全选",
			# 		deselectAllText = "清除已选"
			# 	)
			# ),
			shiny::sliderInput(ns("uWg_sI_Mov_Yrs"), "上映年份：",
				min = min(usrls_Mov_YrsSel),
				max = max(usrls_Mov_YrsSel),
				value = c(min(usrls_Mov_YrsSel),max(usrls_Mov_YrsSel))
			),
			#Add checkbox selector for Movie Phases
			shinyWidgets::prettyCheckboxGroup(ns("uWg_cbI_Mov_Phs"), "阶段筛选器：",
				# style = "color: light-blue;",
				thick = TRUE,
				animation = "pulse",
				status = "info",
				choiceNames = usrdf_Mov_PhsSel$PhaseVis,
				choiceValues = usrdf_Mov_PhsSel[[gv_Movies_PhID]]
			),
			#Add checkbox selector for Movie Series
			shinyWidgets::prettyCheckboxGroup(ns("uWg_cbI_Mov_Srs"), "按电影系列筛选：",
				thick = TRUE,
				animation = "pulse",
				status = "success",
				choiceNames = usrdf_Mov_SrsSel[[gv_Movies_SrNM]],
				choiceValues = usrdf_Mov_SrsSel[[gv_Movies_SrNM]]
			)
		),

		#Add a dynamic Time Table.
		shinyWidgets::addSpinner(shiny::uiOutput(ns("uTLB_Mov")), spin = "bounce", color = myApp_themecolorset$s08$d)
		# uiOutput(ns("uTLB_Mov"))
	#End of [box]
	)
}

UM_MovieTimeTable_svr <- function(input,output,session){
	# Below statement ensures that the function [ns] can be called at server side rendering.
	ns <- session$ns
	#Control the reset button activity
	output$uBtn_ResetFilter <- shiny::renderUI({
		if (nrow(ur_Movies_df())!=nrow(get(usrdf_Mov))){
				shiny::div(id = ns("uDiv_ActBtn_Mov_ResetFilter"),
					shiny::actionButton(ns("uWg_AB_Mov_ResetFilter"), "重置",
						class = "btn-primary",
						style = "color: white;",
						icon = shiny::icon("refresh")
					)
				)
		}
		else NULL
	})
	shiny::observe({
		#Important!!!: below ID should not be enclosed by [ns] function: [ns("uWg_AB_Mov_ResetFilter")]
		#Make the button unable to click (can be remarked as it is overridden by hiding the entire division)
		shinyjs::toggleState("uWg_AB_Mov_ResetFilter",
			condition = (nrow(ur_Movies_df())!=nrow(get(usrdf_Mov)))
		)
	})
	#Below function is NOT a reactive one
	usraction_resetfilter <- function(){
		shiny::updateSliderInput(session,"uWg_sI_Mov_Yrs",
			min = min(usrls_Mov_YrsSel),
			max = max(usrls_Mov_YrsSel),
			value = c(min(usrls_Mov_YrsSel),max(usrls_Mov_YrsSel))
		)
		shinyWidgets::updatePrettyCheckboxGroup(session,"uWg_cbI_Mov_Phs",
			selected = NULL,
			prettyOptions = list(animation = "pulse",thick = TRUE,status = "info"),
			choiceNames = usrdf_Mov_PhsSel$PhaseVis,
			choiceValues = usrdf_Mov_PhsSel[[gv_Movies_PhID]]
		)
		shinyWidgets::updatePrettyCheckboxGroup(session,"uWg_cbI_Mov_Srs",
			selected = NULL,
			prettyOptions = list(animation = "pulse",thick = TRUE,status = "success"),
			choiceNames = usrdf_Mov_SrsSel[[gv_Movies_SrNM]],
			choiceValues = usrdf_Mov_SrsSel[[gv_Movies_SrNM]]
		)
	}
	#Once click the reset button, initialize the filters
	#I may use [shinyjs::js$refresh()] or [shinyjs::reset("id")] to realize this in the future
	#[Quote: https://stackoverflow.com/questions/30852356/add-a-page-refresh-button-by-using-r-shiny ]
	shiny::observeEvent(input$uWg_AB_Mov_ResetFilter,{usraction_resetfilter()})

	#Filter the data frame reactively from user selection
	ur_Movies_df <- shiny::reactive({
		df <- get(usrdf_Mov)
		if (length(input$uWg_sI_Mov_Yrs)>0){
			df <- df %>%
				filter(.,(
					year(.[[gv_Movies_Date]]) >= min(input$uWg_sI_Mov_Yrs) &
					year(.[[gv_Movies_Date]]) <= max(input$uWg_sI_Mov_Yrs)
				)
			)
		}
		if (length(input$uWg_cbI_Mov_Phs)>0) df <- df %>% filter(.,.[[gv_Movies_PhID]] %in% input$uWg_cbI_Mov_Phs)
		if (length(input$uWg_cbI_Mov_Srs)>0) df <- df %>% filter(.,.[[gv_Movies_SrNM]] %in% input$uWg_cbI_Mov_Srs)
		# if (nrow(df)==0){
		# 	return(get(usrdf_Mov))
		# }
		return(df)
	})
	#Once there is no movie matching the filter rule, initialize the filters
	shiny::observe({
		if (nrow(ur_Movies_df())==0){
			shinyWidgets::sendSweetAlert(session,
				title = "搜索结果为空",
				text = "未搜索到符合条件的影片，已为您返回全部影片列表",
				type = "info",
				btn_labels = "返回"
			)
			usraction_resetfilter()
		}
	})
	ustr_tl_ui <- shiny::reactive({
		#Return the full list if the filters make it blank
		ui_df <- ur_Movies_df()
		if (nrow(ui_df)==0) ui_df <- get(usrdf_Mov)
		#Prepare the statements to render a dynamic UI
		ustr_df_ui <- ui_df %>% arrange(desc(.[[gv_Movies_Date]])) %>%
			mutate(
				outtxt = paste0(
					"shinydashboardPlus::timelineItem(",
						"title = '",.[[gv_Movies_MNMCN]],"',",
						"icon = 'file-movie-o',",
						"color = 'olive',",
						"time = shinydashboardPlus::dashboardLabel(",
							"style = 'default',",
							"status = 'warning',",
							"'",.[[gv_Movies_Date]],"'",
						"),",
						"footer = '",.[[gv_Movies_MDesc]],"',",
						"shiny::actionButton(",
							"'uAB_Mov_",usrdf_Mov,"_",.$ActionID,"',",
							"'Play Movie',",
							"icon = shiny::icon('play-circle-o')",
						"),",
						"br(),",
						"shinydashboardPlus::timelineItemMedia(src = '",gsub("\\\\","\\\\\\\\",.[[gv_Movies_MPicLoc]]),"\\\\",gsub("\\\\","\\\\\\\\",.[[gv_Movies_MPicNm]]),"')",
					")",
					ifelse(
						MarkBgn!="",
						paste0(",shinydashboardPlus::timelineLabel('",MarkBgn,"',color = 'navy')"),
						""
					)
				)
			)
		ustr_forparse <- paste0(
			"shinydashboardPlus::timelineBlock(reversed = TRUE,",
				"shinydashboardPlus::timelineEnd(color = 'orange'),",
				paste0(ustr_df_ui$outtxt,collapse=","),
				",shinydashboardPlus::timelineStart(color = 'gray')",
			")"
		)
		# print(ustr_forparse)
		eval(usr_str2exp(ustr_forparse))
	})

	#Create a dynamic UI to show the Time Table.
	output$uTLB_Mov <- shiny::renderUI({
		ustr_tl_ui()

		# Below statements cannot be applied, for [tagAppendAttributes] requires an input ID [tag], which we do not have.
		# ustr_df_ui <- ur_Movies_df() %>% arrange(desc(.[[gv_Movies_Date]]))
		# u_names <- ustr_df_ui[[gv_Movies_MNMCN]]
		# u_dates <- ustr_df_ui[[gv_Movies_Date]]
		# u_mdesc <- ustr_df_ui[[gv_Movies_MDesc]]
		# u_actid <- ustr_df_ui$ActionID
		# u_picloc <- ustr_df_ui[[gv_Movies_MPicLoc]]
		# u_picnm <- ustr_df_ui[[gv_Movies_MPicNm]]
		# u_mkbgn <- ustr_df_ui$MarkBgn
		# timelineBlock(reversed = TRUE,
		# 	timelineEnd(color = 'orange'),
		# 	br(),
		# 	lapply(1:nrow(ustr_df_ui), function(i){
		# 		tagAppendAttributes(
		# 			timelineItem(
		# 				title = u_names[[i]],
		# 				icon = 'file-movie-o',
		# 				color = 'olive',
		# 				time = dashboardLabel(
		# 					style = 'default',
		# 					status = 'warning',
		# 					u_dates[[i]]
		# 				),
		# 				footer = u_mdesc[[i]],
		# 				actionButton(
		# 					paste0("uAB_Mov_",usrdf_Mov,"_",u_actid[[i]]),
		# 					'Play Movie',
		# 					icon = icon('play-circle-o')
		# 				),
		# 				br(),
		# 				timelineItemMedia(src = paste0(u_picloc[[i]],"\\\\",u_picnm[[i]]))
		# 			),
		# 			align = "middle"
		# 		)
		# 		if (u_mkbgn[[i]]!=""){
		# 			tagAppendAttributes(
		# 				timelineLabel(
		# 					u_mkbgn[[i]],
		# 					color = 'navy'
		# 				)
		# 			)
		# 		}
		# 		else {NULL}
		# 	}),
		# 	br(),
		# 	timelineStart(color = 'gray')
		# )
	})
}
