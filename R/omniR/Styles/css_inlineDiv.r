css_inlineDiv <- function(name = "inlineDiv",direction = c("row","column","row-reverse","column-reverse")){
	#This function is to generate a plain text in the grammar of CSS
	#Grant capability to the [DIV] tag to align all items in-line within [bootstrap] framework
	#[Quote: https://www.runoob.com/css3/css3-flexbox.html ]
	direction <- match.arg(direction)
	paste0(
		'.',name,' {',
			'display: -webkit-flex;',
			'display: flex;',
			'-webkit-flex-direction: ',direction,';',
			'flex-direction: ',direction,';',
			'width: 100%;',
			#Below height value is the default one for most widgets in [shiny]
			# 'height: 34px;',
			'height: auto;',
			'-webkit-justify-content: space-between;',
			'justify-content: space-between;',
			'-webkit-align-items: stretch;',
			'align-items: stretch;',
			# '-webkit-align-content: stretch;',
			# 'align-content: stretch;',
		'}'
	)
}