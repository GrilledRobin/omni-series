#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to add dependencies for the htmlwidget being used                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Quote]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] https://github.com/rstudio/DT/issues/410                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] This is the last among the required the helper functions that enables one to insert [htmlwidget] into cells of [DT::datatable]#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Method to insert htmlwidgets into datatable]                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[10] Convert htmlwidget into character version; using function [as.character.htmlwidget]                                           #
#   |[20] Make sure [escape = FALSE]                                                                                                    #
#   |[30] Add static render callback; using function [add_datatable_render_code]                                                        #
#   |[40] Add dependencies for the htmlwidget being used; using function [add_deps]                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dtbl        :   The [DT::datatable] object to which to attach the dependencies                                                     #
#   |name        :   The name of the widget (usually can be retrieved by [class(x)]) to be inserted into [dtbl].                        #
#   |                 See document for [htmlwidgets::getDependency]                                                                     #
#   |pkg         :   The package naming the widget (usually can be retrieved by [class(x)]) to be inserted into [dtbl].                 #
#   |                 See document for [htmlwidgets::getDependency]                                                                     #
#   |                 [name        ] <Default> The same as the widget name                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<tagList>   :   [shiny::tagList] object                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211208        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |shiny, htmlwidgets                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, htmlwidgets
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

add_deps <- function(dtbl, name, pkg = name) {
	shiny::tagList(
		dtbl
		,htmlwidgets::getDependency(name, pkg)
	)
}

#[Full Test Program;]
if (FALSE){
	#Real case test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare the [echarts4r] widget, which is essentially [htmlwidget]. Check its [class] for information
		ech_bar <- mtcars |>
			tibble::rownames_to_column('model') |>
			dplyr::mutate(total = mpg + qsec) |>
			dplyr::arrange(desc(total)) |>
			echarts4r::e_charts(model) |>
			echarts4r::e_bar(mpg, stack = 'grp') |>
			echarts4r::e_bar(qsec, stack = 'grp')

		#200. Convert it into html tags as character vector
		tag_bar <- ech_bar |>
			#Below function is from [omniR$Visualization]
			as.character.htmlwidget() |>
			add_deps('echarts4r', 'echarts4r')

	}
}
