#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to switch the input [Pixel] value(s) into the length [MM], i.e. millimeter value(s) in terms of the      #
#   | provided resolution [PPI], which represents Pixels per Inch                                                                       #
#   |Quote: https://www.cnblogs.com/ChineseMoonGod/p/3685703.html                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] MS PowerPoint uses length (CM) to define the height and width of the shapes, while Power BI uses pixels.                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |pixels     :   The provided vector as pixels to be translated                                                                      #
#   |PPI        :   The Pixel per Inch standard to conduct the translation                                                              #
#   |                [  96  ] <Default> This value can be used during the translation from MS PPT to MS PowerBI                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector]   :   A vector of translated lengths in [MM], i.e. millimeters                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210102        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |base                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

PixelToMM <- function(pixels, PPI = 96){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(pixels)) return()
	if (length(pixels) == 0) return()
	if (is.null(PPI)) PPI <- 96
	if (length(PPI) == 0) PPI <- 96

	#999. Return the values
	return( pixels / PPI * 25.4 )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		pixels_def <- c(496,312)

		#100. Prepare the palette for the color
		pixels_to_mm <- PixelToMM( pixels_def )

	}
}