AdminLTE_colors <- function(){
	#Set the AdminLTE colors
	#[Quote:[library$shinydashboardPlus$shinydashboardPlus-(ver.)$css$AdminLTE.css]]
	AdminLTE_color_default <<- '#d2d6de'
	AdminLTE_color_primary <<- '#3c8dbc'
	AdminLTE_color_info <<- '#00c0ef'
	AdminLTE_color_warning <<- '#f39c12'
	AdminLTE_color_danger <<- '#dd4b39'
	AdminLTE_color_success <<- '#00a65a'
	AdminLTE_color_navy <<- '#001f3f'
	AdminLTE_color_teal <<- '#39cccc'
	AdminLTE_color_purple <<- '#605ca8'
	AdminLTE_color_orange <<- '#ff851b'
	AdminLTE_color_maroon <<- '#d81b60'
	AdminLTE_color_black <<- '#111111'
}
#Ensure the function is called once 'SOURCE'd
AdminLTE_colors()