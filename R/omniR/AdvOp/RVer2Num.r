RVer2Num <- function(){
	R_Ver.txt <- paste0(R.Version()$major,".",R.Version()$minor)
	R_Ver.rev <- rev(strsplit(txt,"\\.")[[1]])
	R_Ver.num <- 0
	for (i in 1:length(R_Ver.rev)){
		R_Ver.num <- R_Ver.num + as.numeric(R_Ver.rev[[i]]) * 100^(i - 1)
	}
	return(R_Ver.num)
}