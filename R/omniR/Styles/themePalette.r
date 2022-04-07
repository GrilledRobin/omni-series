#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create the color palette for specific themes                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>      :   A list of color names, which are respectively named lists with elements as below:                                  #
#   |                 [d] Character vector of Default color of current series                                                           #
#   |                 [p] Character vector of subsidiary Palette colors of current series, with length of 5 from lighter to darker      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211211        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |get_values                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |rgba2rgb                                                                                                                   #
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

themePalette <- function(theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	theme <- match.arg(theme, c('BlackGold', 'PBI', 'Inno', 'MSOffice'))

	#015. Function local variables
	alpha_def <- seq(0.1,1,length.out = 10)
	col_sel <- seq(1,9,2)

	#500. Define the palettes
	#MS PowerBI [Default] Theme Color Set
	PBI <- list(
		bgcolor = list(d = '#FFFFFF')
		,white = list(d = '#FFFFFF' , p = c('#E6E6E6' , '#CCCCCC' , '#B3B3B3' , '#808080' , '#666666'))
		,black = list(d = '#000000' , p = c('#999999' , '#666666' , '#333333' , '#1A1A1A' , '#000000'))
		,green = list(d = '#01B8AA' , p = c('#99E3DD' , '#67D4CC' , '#34C6BB' , '#018A80' , '#015C55'))
		,steel = list(d = '#374649' , p = c('#AFB5B6' , '#879092' , '#5F6B6D' , '#293537' , '#1C2325'))
		,red = list(d = '#FD625E' , p = c('#FEC0BF' , '#FEA19E' , '#FD817E' , '#BE4A47' , '#7F312F'))
		,yellow = list(d = '#F2C80F' , p = c('#FAE99F' , '#F7DE6F' , '#F5D33F' , '#B6960B' , '#796408'))
		,gray = list(d = '#5F6B6D' , p = c('#BFC4C5' , '#9FA6A7' , '#7F898A' , '#475052' , '#303637'))
		,blue = list(d = '#8AD4EB' , p = c('#D0EEF7' , '#B9E5F3' , '#A1DDEF' , '#689FB0' , '#456A76'))
		,orange = list(d = '#FE9666' , p = c('#FFD5C2' , '#FEC0A3' , '#FEAB85' , '#BF714D' , '#7F4B33'))
		,purple = list(d = '#A66999' , p = c('#DBC3D6' , '#CAA5C2' , '#B887AD' , '#7D4F73' , '#53354D'))
	)

	#MS PowerBI [Innovation] Theme Color Set
	Inno <- list(
		bgcolor = list(d = '#3A3A3A')
		,white = list(d = '#FFFFFF' , p = c('#E6E6E6' , '#CCCCCC' , '#B3B3B3' , '#808080' , '#666666'))
		,black = list(d = '#000000' , p = c('#999999' , '#666666' , '#333333' , '#1A1A1A' , '#000000'))
		,cyan = list(d = '#70B0E0' , p = c('#C6DFF3' , '#A9D0EC' , '#8DC0E6' , '#5484A8' , '#385870'))
		,yellow = list(d = '#FCB714' , p = c('#FEE2A1' , '#FDD472' , '#FDC543' , '#BD890F' , '#7E5C0A'))
		,blue = list(d = '#2878BD' , p = c('#A9C9E5' , '#7EAED7' , '#5393CA' , '#1E5A8E' , '#143C5F'))
		,aqua = list(d = '#0EB194' , p = c('#9FE0D4' , '#6ED0BF' , '#3EC1A9' , '#0B856F' , '#07594A'))
		,green = list(d = '#108372' , p = c('#9FCDC7' , '#70B5AA' , '#409C8E' , '#0C6256' , '#084239'))
		,bronze = list(d = '#AF916D' , p = c('#DFD3C5' , '#CFBDA7' , '#BFA78A' , '#836D52' , '#584937'))
		,khaki = list(d = '#C4B07B' , p = c('#E7DFCA' , '#DCD0B0' , '#D0C095' , '#93845C' , '#62583E'))
		,red = list(d = '#F15628' , p = c('#F9BBA9' , '#F79A7E' , '#F47853' , '#B5411E' , '#792B14'))
	)

	#MS Office 2016 [Default] Theme Color Set
	MSOffice <- list(
		bgcolor = list(d = '#FFFFFF')
		,white = list(d = '#FFFFFF' , p = c('#F2F2F2' , '#D9D9D9' , '#BFBFBF' , '#A6A6A6' , '#808080'))
		,black = list(d = '#000000' , p = c('#808080' , '#595959' , '#404040' , '#262626' , '#0D0D0D'))
		,gray = list(d = '#E7E6E6' , p = c('#D0CECE' , '#AEAAAA' , '#757171' , '#3A3838' , '#161616'))
		,indigo = list(d = '#44546A' , p = c('#D6DCE4' , '#ACB9CA' , '#8497B0' , '#333F4F' , '#222B35'))
		,azure = list(d = '#5B9BD5' , p = c('#DDEBF7' , '#BDD7EE' , '#9BC2E6' , '#2F75B5' , '#1F4E78'))
		,orange = list(d = '#ED7D31' , p = c('#FCE4D6' , '#F8CBAD' , '#F4B084' , '#C65911' , '#833C0C'))
		,darkgray = list(d = '#A5A5A5' , p = c('#EDEDED' , '#DBDBDB' , '#C9C9C9' , '#7B7B7B' , '#525252'))
		,gold = list(d = '#FFC000' , p = c('#FFF2CC' , '#FFE699' , '#FFD966' , '#BF8F00' , '#806000'))
		,blue = list(d = '#4472C4' , p = c('#D9E1F2' , '#B4C6E7' , '#8EA9DB' , '#305496' , '#203764'))
		,green = list(d = '#70AD47' , p = c('#E2EFDA' , '#C6E0B4' , '#A9D08E' , '#548235' , '#375623'))
	)

	#Black-Gold theme tweaked from [Innovation]
	bg_gold <- '#FFE8CB'
	bg_black <- '#202122'
	BlackGold <- Inno %>%
		modifyList(
			list(
				yellow = NULL
				,gold = list(
					d = bg_gold
					,p = c(
						rgba2rgb(bg_gold, alpha_in = 0.4, color_bg = '#FFFFFF')
						,rgba2rgb(bg_gold, alpha_in = 0.8, color_bg = '#FFFFFF')
						,rgba2rgb(bg_gold, alpha_in = 0.9, color_bg = bg_black)
						,rgba2rgb(bg_gold, alpha_in = 0.7, color_bg = bg_black)
						,rgba2rgb(bg_gold, alpha_in = 0.5, color_bg = bg_black)
					)
				)
				,black = list(
					d = bg_black
					,p = rgba2rgb( rep(bg_black, 10), alpha_in = alpha_def, color_bg = bg_gold )[col_sel]
				)
			)
		)

	#999. Return the list
	return( get_values(theme) )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare the palette for the color
		color_theme <- themePalette()

	}
}
