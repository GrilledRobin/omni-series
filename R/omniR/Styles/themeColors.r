#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to prepare color sets for different themes                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |transparent :   Whether to set the background as transparent                                                                       #
#   |                 [FALSE       ] <Default> Use the theme color                                                                      #
#   |                 [TRUE        ]           Set the alpha of background color as 0                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>      :   List of colors in various categories for the provided theme                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211218        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220405        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add color configurations for [chart-area] and [chart-pie]                                                               #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220414        | Version | 1.11        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add color configurations for [chart-bar-inverse]                                                                        #
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
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |rgba2rgb                                                                                                                   #
#   |   |   |themePalette                                                                                                               #
#   |   |   |alphaToHex                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#

themeColors <- function(
	theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	theme <- match.arg(theme, c('BlackGold', 'PBI', 'Inno', 'MSOffice'))

	#015. Function local variables
	cache_BlackGold <- themePalette('BlackGold')
	cache_Inno <- themePalette('Inno')
	cache_PBI <- themePalette('PBI')
	cache_MSOffice <- themePalette('MSOffice')
	alpha_trans <- ifelse(transparent, '00', '')

	#100. Function to define the [gradient] styles
	#Quote: https://blog.csdn.net/qq_38990521/article/details/80588232
	#Quote: https://webkit.org/blog/1424/css3-gradients/
	h_grad <- function(col, bg, from, to) {
		c(
			paste0('-webkit-gradient('
				,'linear'
				,', left ',from
				,', left ',to
				,', color-stop(0%, ',rgba2rgb(col, alpha_in = 0.1, color_bg = bg),')'
				,', color-stop(100%, ',rgba2rgb(col, alpha_in = 0.3, color_bg = bg),')'
			,')')
			,paste0('-',c('webkit','moz','ms','o'),'-linear-gradient('
				,from
				,', ',rgba2rgb(col, alpha_in = 0.1, color_bg = bg),' 0%'
				,', ',rgba2rgb(col, alpha_in = 0.3, color_bg = bg),' 100%'
			,')')
			,paste0('linear-gradient('
				,'to ',to
				,', ',rgba2rgb(col, alpha_in = 0.1, color_bg = bg),' 0%'
				,', ',rgba2rgb(col, alpha_in = 0.3, color_bg = bg),' 100%'
			,')')
		)
	}

	#500. Create colors
	coltheme <- list(
		'BlackGold' = list(
			'background-color' = list(
				'default' = paste0(cache_BlackGold$black$d, alpha_trans)
				,'stripe' = paste0(cache_BlackGold$gold$d, alphaToHex(0.1))
				,'stripe-odd' = paste0(cache_BlackGold$black$d, alpha_trans)
				,'header' = paste0(cache_BlackGold$gold$d, alphaToHex(0.2))
				,'accessory' = rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.2)
				,'chart-bar-incr' = paste0(cache_BlackGold$black$d, alphaToHex(0.1))
				,'chart-bar-decr' = paste0(cache_BlackGold$black$d, alphaToHex(0.1))
				,'tooltip' = paste0(
					rgba2rgb(cache_BlackGold$black$d, alpha_in = 0.9, color_bg = cache_BlackGold$gold$d)
					,alphaToHex(0.95)
				)
				,'tooltip-inverse' = paste0(
					rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.2, color_bg = cache_BlackGold$black$d)
					,alphaToHex(0.95)
				)
			)
			,'background' = list(
				'btn-act' = h_grad(cache_BlackGold$black$d, rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.3), 'top', 'bottom')
				,'btn-act-hover' = h_grad(cache_BlackGold$black$d, rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.3), 'bottom', 'top')
				,'btn-inact' = rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.2, color_bg = cache_BlackGold$black$d)
				,'btn-inact-hover' = h_grad(cache_BlackGold$black$d, rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.3), 'bottom', 'top')
			)
			,'color' = list(
				'default' = cache_BlackGold$gold$d
				,'header' = cache_BlackGold$gold$d
				,'body' = rgba2rgb(cache_BlackGold$gold$d, alpha_in = 0.1)
				,'accessory' = cache_BlackGold$black$d
				,'btn-act' = cache_BlackGold$black$d
				,'btn-act-hover' = cache_BlackGold$black$d
				,'btn-inact' = cache_BlackGold$gold$d
				,'btn-inact-hover' = cache_BlackGold$black$d
				,'chart-bar' = cache_BlackGold$gold$d
				,'chart-bar-inverse' = cache_BlackGold$gold$p[[5]]
				,'chart-line' = cache_BlackGold$gold$d
				,'chart-area' = cache_BlackGold$gold$d
				,'chart-pie' = cache_BlackGold$gold$d
				,'chart-sym' = rgba2rgb(cache_BlackGold$black$d, alpha_in = 0.7, color_bg = cache_BlackGold$gold$d)
				#[红灯] or [上涨]
				,'chart-bar-incr' = cache_BlackGold$red$p[[2]]
				#[绿灯] or [下跌]
				,'chart-bar-decr' = cache_BlackGold$green$p[[2]]
				,'chart-sym-light' = cache_BlackGold$gold$d
				,'chart-markpoint' = cache_BlackGold$black$d
				,'tooltip' = cache_BlackGold$gold$d
			)
			,'border' = list(
				'btn-act' = paste0(cache_BlackGold$gold$d, alphaToHex(0.2))
				,'btn-act-hover' = paste0(cache_BlackGold$gold$d, alphaToHex(0.3))
				,'btn-inact' = paste0(cache_BlackGold$gold$d, alphaToHex(0.2))
				,'btn-inact-hover' = paste0(cache_BlackGold$gold$d, alphaToHex(0.3))
			)
			,'border-color' = list(
				'tooltip' = paste0(
					rgba2rgb(cache_BlackGold$black$d, alpha_in = 0.7, color_bg = cache_BlackGold$gold$d)
					,alphaToHex(0.95)
				)
			)
			,'border-top' = list(
				'default' = paste0('1px solid ', cache_BlackGold$gold$d, alphaToHex(0.3))
			)
			,'border-bottom' = list(
				'default' = paste0('1px solid ', cache_BlackGold$gold$d, alphaToHex(0.3))
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_BlackGold$black$d, alphaToHex(0.3), ';')
			)
		)
		,'Inno' = list(
			'background-color' = list(
				'default' = paste0(cache_Inno$black$p[[4]], alpha_trans)
				,'stripe' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.1))
				,'stripe-odd' = paste0(cache_Inno$black$p[[4]], alpha_trans)
				,'header' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.3))
				,'accessory' = rgba2rgb(cache_Inno$white$p[[4]], alpha_in = 0.3)
				,'chart-bar-incr' = paste0(cache_Inno$black$p[[4]], alphaToHex(0.1))
				,'chart-bar-decr' = paste0(cache_Inno$black$p[[4]], alphaToHex(0.1))
				,'tooltip' = paste0(
					cache_Inno$black$p[[4]]
					,alphaToHex(0.95)
				)
				,'tooltip-inverse' = paste0(
					rgba2rgb(cache_Inno$white$p[[1]], alpha_in = 0.2, color_bg = cache_Inno$black$p[[4]])
					,alphaToHex(0.95)
				)
			)
			,'background' = list(
				'btn-act' = h_grad(cache_Inno$black$p[[4]], rgba2rgb(cache_Inno$white$p[[2]], alpha_in = 0.3), 'top', 'bottom')
				,'btn-act-hover' = h_grad(cache_Inno$black$p[[4]], rgba2rgb(cache_Inno$white$p[[2]], alpha_in = 0.3), 'bottom', 'top')
				,'btn-inact' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.3))
				,'btn-inact-hover' = h_grad(cache_Inno$black$p[[4]], rgba2rgb(cache_Inno$white$p[[2]], alpha_in = 0.3), 'bottom', 'top')
			)
			,'color' = list(
				'default' = cache_Inno$white$p[[2]]
				,'header' = cache_Inno$white$p[[2]]
				,'body' = cache_Inno$white$p[[2]]
				,'accessory' = cache_Inno$black$p[[4]]
				,'btn-act' = cache_Inno$black$p[[4]]
				,'btn-act-hover' = cache_Inno$black$p[[4]]
				,'btn-inact' = cache_Inno$white$p[[2]]
				,'btn-inact-hover' = cache_Inno$black$p[[4]]
				,'chart-bar' = cache_Inno$yellow$p[[1]]
				,'chart-bar-inverse' = cache_Inno$yellow$p[[5]]
				,'chart-line' = cache_Inno$yellow$p[[1]]
				,'chart-area' = cache_Inno$yellow$p[[1]]
				,'chart-pie' = cache_Inno$yellow$p[[1]]
				,'chart-sym' = rgba2rgb(cache_Inno$black$p[[4]], alpha_in = 0.7, color_bg = cache_Inno$white$p[[1]])
				,'chart-bar-incr' = cache_Inno$red$p[[2]]
				,'chart-bar-decr' = cache_Inno$green$p[[2]]
				,'chart-sym-light' = cache_Inno$white$p[[1]]
				,'chart-markpoint' = cache_Inno$black$p[[4]]
				,'tooltip' = cache_Inno$white$p[[1]]
			)
			,'border' = list(
				'btn-act' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.2))
				,'btn-act-hover' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.3))
				,'btn-inact' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.2))
				,'btn-inact-hover' = paste0(cache_Inno$white$p[[4]], alphaToHex(0.3))
			)
			,'border-color' = list(
				'tooltip' = paste0(
					cache_Inno$black$p[[2]]
					,alphaToHex(0.95)
				)
			)
			,'border-top' = list(
				'default' = paste0('1px solid ', cache_Inno$white$p[[2]], alphaToHex(0.3))
			)
			,'border-bottom' = list(
				'default' = paste0('1px solid ', cache_Inno$white$p[[2]], alphaToHex(0.3))
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_Inno$black$p[[4]], alphaToHex(0.3), ';')
			)
		)
		,'PBI' = list(
			'background-color' = list(
				'default' = paste0(cache_PBI$white$d, alpha_trans)
				,'stripe' = paste0(cache_PBI$black$p[[4]], alphaToHex(0.07))
				,'stripe-odd' = paste0(cache_PBI$black$p[[4]], alphaToHex(0.07))
				,'header' = paste0(cache_PBI$white$d, alpha_trans)
				,'accessory' = paste0(cache_PBI$black$p[[4]], alphaToHex(0.07))
				,'chart-bar-incr' = paste0(cache_PBI$black$p[[4]], alphaToHex(0.1))
				,'chart-bar-decr' = paste0(cache_PBI$black$p[[4]], alphaToHex(0.1))
				,'tooltip' = paste0(
					cache_PBI$black$p[[4]]
					,alphaToHex(0.95)
				)
				,'tooltip-inverse' = paste0(
					rgba2rgb(cache_PBI$white$p[[1]], alpha_in = 0.1, color_bg = cache_PBI$black$p[[4]])
					,alphaToHex(0.95)
				)
			)
			,'background' = list(
				'btn-act' = h_grad(cache_PBI$white$d, rgba2rgb(cache_PBI$black$p[[4]], alpha_in = 0.3), 'top', 'bottom')
				,'btn-act-hover' = h_grad(cache_PBI$white$d, rgba2rgb(cache_PBI$black$p[[4]], alpha_in = 0.3), 'bottom', 'top')
				,'btn-inact' = h_grad(cache_PBI$black$p[[4]], rgba2rgb(cache_PBI$black$p[[4]], alpha_in = 0.3), 'bottom', 'top')
				,'btn-inact-hover' = h_grad(cache_PBI$white$d, rgba2rgb(cache_PBI$black$p[[4]], alpha_in = 0.3), 'bottom', 'top')
			)
			,'color' = list(
				'default' = cache_PBI$black$p[[4]]
				,'header' = cache_PBI$black$p[[4]]
				,'body' = cache_PBI$black$p[[4]]
				,'accessory' = cache_PBI$black$p[[4]]
				,'btn-act' = cache_PBI$white$black$p[[4]]
				,'btn-act-hover' = cache_PBI$black$p[[4]]
				,'btn-inact' = cache_PBI$white$d
				,'btn-inact-hover' = cache_PBI$black$p[[4]]
				,'chart-bar' = cache_PBI$yellow$p[[1]]
				,'chart-bar-inverse' = cache_PBI$yellow$p[[5]]
				,'chart-line' = cache_PBI$yellow$p[[1]]
				,'chart-area' = cache_PBI$yellow$p[[1]]
				,'chart-pie' = cache_PBI$yellow$p[[1]]
				,'chart-sym' = cache_PBI$white$p[[1]]
				,'chart-bar-incr' = cache_PBI$red$d
				,'chart-bar-decr' = cache_PBI$green$d
				,'chart-sym-light' = cache_PBI$white$d
				,'chart-markpoint' = cache_PBI$black$p[[4]]
				,'tooltip' = cache_PBI$white$p[[1]]
			)
			,'border' = list(
				'btn-act' = paste0(cache_PBI$white$p[[1]], alphaToHex(0.2))
				,'btn-act-hover' = paste0(cache_PBI$white$p[[1]], alphaToHex(0.3))
				,'btn-inact' = paste0(cache_PBI$white$p[[1]], alphaToHex(0.2))
				,'btn-inact-hover' = paste0(cache_PBI$white$p[[1]], alphaToHex(0.3))
			)
			,'border-color' = list(
				'tooltip' = paste0(
					cache_PBI$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'border-top' = list(
				'default' = paste0('1px solid ', cache_PBI$black$p[[4]], alphaToHex(0.2))
			)
			,'border-bottom' = list(
				'default' = paste0('1px solid ', cache_PBI$black$p[[4]], alphaToHex(0.2))
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_PBI$black$p[[4]], alphaToHex(0.3), ';')
			)
		)
		,'MSOffice' = list(
			'background-color' = list(
				'default' = paste0(cache_MSOffice$white$d, alpha_trans)
				,'stripe' = paste0(cache_MSOffice$black$p[[4]], alphaToHex(0.07))
				,'stripe-odd' = paste0(cache_MSOffice$black$p[[4]], alphaToHex(0.07))
				,'header' = paste0(cache_MSOffice$white$d, alpha_trans)
				,'accessory' = paste0(cache_MSOffice$black$p[[4]], alphaToHex(0.07))
				,'chart-bar-incr' = paste0(cache_MSOffice$black$p[[4]], alphaToHex(0.1))
				,'chart-bar-decr' = paste0(cache_MSOffice$black$p[[4]], alphaToHex(0.1))
				,'tooltip' = paste0(
					cache_MSOffice$black$p[[4]]
					,alphaToHex(0.95)
				)
				,'tooltip-inverse' = paste0(
					rgba2rgb(cache_MSOffice$white$p[[1]], alpha_in = 0.1, color_bg = cache_MSOffice$black$p[[4]])
					,alphaToHex(0.95)
				)
			)
			,'background' = list(
				'btn-act' = h_grad(
					cache_MSOffice$white$d
					, rgba2rgb(cache_MSOffice$black$p[[4]], alpha_in = 0.3)
					, 'top'
					, 'bottom'
				)
				,'btn-act-hover' = h_grad(
					cache_MSOffice$white$d
					, rgba2rgb(cache_MSOffice$black$p[[4]], alpha_in = 0.3)
					, 'bottom'
					, 'top'
				)
				,'btn-inact' = h_grad(
					cache_MSOffice$black$p[[4]]
					, rgba2rgb(cache_MSOffice$black$p[[4]], alpha_in = 0.3)
					, 'bottom'
					, 'top'
				)
				,'btn-inact-hover' = h_grad(
					cache_MSOffice$white$d
					, rgba2rgb(cache_MSOffice$black$p[[4]], alpha_in = 0.3)
					, 'top'
					, 'bottom'
				)
			)
			,'color' = list(
				'default' = cache_MSOffice$black$p[[4]]
				,'header' = cache_MSOffice$black$p[[4]]
				,'body' = cache_MSOffice$black$p[[4]]
				,'accessory' = cache_MSOffice$black$p[[4]]
				,'btn-act' = cache_MSOffice$white$black$p[[4]]
				,'btn-act-hover' = cache_MSOffice$black$p[[4]]
				,'btn-inact' = cache_MSOffice$white$d
				,'btn-inact-hover' = cache_MSOffice$black$p[[4]]
				,'chart-bar' = cache_MSOffice$gold$p[[1]]
				,'chart-bar-inverse' = cache_MSOffice$gold$p[[5]]
				,'chart-line' = cache_MSOffice$gold$p[[1]]
				,'chart-area' = cache_MSOffice$gold$p[[1]]
				,'chart-pie' = cache_MSOffice$gold$p[[1]]
				,'chart-sym' = cache_MSOffice$white$p[[1]]
				,'chart-bar-incr' = cache_MSOffice$orange$d
				,'chart-bar-decr' = cache_MSOffice$green$d
				,'chart-sym-light' = cache_MSOffice$white$d
				,'chart-markpoint' = cache_PBI$black$p[[4]]
				,'tooltip' = cache_MSOffice$white$p[[1]]
			)
			,'border' = list(
				'btn-act' = paste0(cache_MSOffice$white$p[[1]], alphaToHex(0.2))
				,'btn-act-hover' = paste0(cache_MSOffice$white$p[[1]], alphaToHex(0.3))
				,'btn-inact' = paste0(cache_MSOffice$white$p[[1]], alphaToHex(0.2))
				,'btn-inact-hover' = paste0(cache_MSOffice$white$p[[1]], alphaToHex(0.3))
			)
			,'border-color' = list(
				'tooltip' = paste0(
					cache_MSOffice$black$p[[4]]
					,alphaToHex(0.95)
				)
			)
			,'border-top' = list(
				'default' = paste0('1px solid ', cache_MSOffice$black$p[[4]], alphaToHex(0.2))
			)
			,'border-bottom' = list(
				'default' = paste0('1px solid ', cache_MSOffice$black$p[[4]], alphaToHex(0.2))
			)
			,'box-shadow' = list(
				'tooltip' = paste0('0 0 2px ', cache_MSOffice$black$p[[4]], alphaToHex(0.3), ';')
			)
		)
	)

	#999. Return the result
	return( coltheme[[theme]] )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare the palette for the color
		usr_color <- themeColors()

	}
}
