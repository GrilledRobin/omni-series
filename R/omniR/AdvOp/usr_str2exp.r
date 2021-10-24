usr_str2exp <- function(...){
	if (numeric_version(paste0(R.Version()$major,".",R.Version()$minor)) >= numeric_version("3.6.1")){
		str2expression(...)
	}
	else {
		parse(text = as.character(...) , keep.source = FALSE)
	}
}