#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to switch the input [RGBA] color value(s) into the actual [HEX] value(s) in terms of the provided        #
#   | background color, which translates the [alpha] channel                                                                            #
#   |Quote: http://marcodiiga.github.io/rgba-to-rgb-conversion                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 有些主题色的调色板是用[RGBA]的值体现，最终的效果带有透明度。因此需要用到这个方法消除透明度                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |color_in   :   The color codes of [RGB] part extracted from the dedicated [RGBA] color                                             #
#   |                It can be provided as below types of vectors:                                                                      #
#   |                [#FFFFFF]          The HEX value of the RGB color                                                                  #
#   |                [grDevices::rgb()] The RGB matrix translated by the [rgb] function                                                 #
#   |alpha_in   :   The alpha value representing the opacity of the color, values from 0 (transparent) to 1                             #
#   |color_bg   :   The background color to translate the [alpha] channel as attenuation                                                #
#   |                [#FFFFFF]<Default> It can also be provided in [HEX] or [RGB] values                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector]   :   A vector of translated colors in [HEX] values                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200325        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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

rgba2rgb <- function(color_in, alpha_in = 1, color_bg = grDevices::col2rgb('#FFFFFF')){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(color_in)) return()
	if (length(color_in) == 0) return()
	if (is.null(alpha_in)) alpha_in <- 1
	if (length(alpha_in) == 0) alpha_in <- 1
	stopifnot( alpha_in >= 0, alpha_in <= 1 )
	if (is.null(color_bg)) color_bg <- grDevices::col2rgb('#FFFFFF')
	if (length(color_bg) == 0) color_bg <- grDevices::col2rgb('#FFFFFF')
	if (is.character(color_in)) rgb_src <- grDevices::col2rgb(color_in) else rgb_src <- color_in
	if (is.character(color_bg)) color_bg <- grDevices::col2rgb(color_bg)

	#500. Calculate the color values
	out_r <- ( 1 - alpha_in ) * color_bg['red',] + alpha_in * rgb_src['red',]
	out_g <- ( 1 - alpha_in ) * color_bg['green',] + alpha_in * rgb_src['green',]
	out_b <- ( 1 - alpha_in ) * color_bg['blue',] + alpha_in * rgb_src['blue',]

	#999. Return the list
	return( grDevices::rgb(out_r, out_g, out_b, maxColorValue = 255) )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		alpha_def <- seq(0.1,1,length.out = 10)
		color_def <- '#002469'

		#100. Prepare the palette for the color
		color_sticker <- rgba2rgb( rep(color_def, 10), alpha_in = alpha_def )

	}
}
