#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to return a string of CSS style to draw a gradient background from bottom to top for any container       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |color_btm  :   The color code to draw at the bottom of the container                                                               #
#   |                It can be provided as below types of vector:                                                                       #
#   |                [#FFFFFF         ] The HEX value of the RGB color                                                                  #
#   |                [grDevices::rgb()] The RGB matrix translated by the [rgb] function                                                 #
#   |color_top  :   The color code to draw at the top of the container                                                                  #
#   |                It can be provided as below types of vector:                                                                       #
#   |                [#FFFFFF         ] The HEX value of the RGB color                                                                  #
#   |                [grDevices::rgb()] The RGB matrix translated by the [rgb] function                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector]   :   A character vector of CSS                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211205        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |grDevices                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	grDevices
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

bg_gradient <- function(color_btm, color_top){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (missing(color_btm)) return(NULL)
	if (missing(color_top)) return(NULL)

	#500. Prepare the CSS for all explorers
	outCSS <- paste0(''
		,'background: -webkit-gradient('
			,'linear'
			,',left bottom'
			,',left top'
			,',color-stop(0,',color_btm,')'
			,',color-stop(1,',color_top,')'
		,') !important;'
		,'background: -ms-linear-gradient('
			,'bottom'
			,',',color_btm
			,',',color_top
		,') !important;'
		,'background: -moz-linear-gradient('
			,'center bottom'
			,',',color_btm
			,',0'
			,',',color_top
			,',100%'
		,') !important;'
		,'background: -o-linear-gradient('
			#Note the reversed order of the arguments
			,',',color_top
			,',',color_btm
		,') !important;'
	)

	#999. Return the vector
	return(outCSS)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		source('D:\\R\\autoexec.r')
		col_primary <- '#002469'

		#100. Prepare the CSS
		#Below functions are from [omniR$Styles]
		color_bg <- bg_gradient( col_primary, rgba2rgb(col_primary, alpha_in = 0.7) )

	}
}
