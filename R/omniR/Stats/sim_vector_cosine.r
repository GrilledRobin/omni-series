sim_vector_cosine <- function(x,y,adj=F){
	#010. Check parameters
	if (!is.vector(x)) return(NULL)
	if (!is.vector(y)) return(NULL)

	#100. Make adjustment if required
	#[Quote: https://blog.csdn.net/ifnoelse/article/details/7766123 ]
	if (!is.null(adj)) {
		if (adj) {
			x <- x - mean(x,na.rm = T)
			y <- y - mean(x,na.rm = T)
		}
	}

	#900. Calculation
	#[Quote: https://bgstieber.github.io/post/recommending-songs-using-cosine-similarity-in-r/ ]
	crossprod(x,y)/sqrt(crossprod(x)*crossprod(y))
}
