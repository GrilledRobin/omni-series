#[Quote: https://stackoverflow.com/questions/11885207/get-all-parameters-as-list ]

allargs <- function(orig_values = FALSE) {
	# get formals for parent function
	parent_formals <- formals(sys.function(sys.parent(n = 1)))

	# Get names of implied arguments
	fnames <- names(parent_formals)

	# Remove '...' from list of parameter names if it exists
	fnames <- fnames[-which(fnames == '...')]

	# Get currently set values for named variables in the parent frame
	args <- evalq(as.list(environment()), envir = parent.frame())

	# Get the list of variables defined in '...'
	args <- c(args[fnames], evalq(list(...), envir = parent.frame()))


	if(orig_values) {
		# get default values
		defargs <- as.list(parent_formals)
		defargs <- defargs[unlist(lapply(defargs, FUN = function(x) class(x) != "name"))]
		args[names(defargs)] <- defargs
		setargs <- evalq(as.list(match.call())[-1], envir = parent.frame())
		args[names(setargs)] <- setargs
	}
	return(args)
}

if (F) {
	tempf <- function(a, b = 2, ...) {
		d <- 5
		b <- 3

		cat("Currently set values defined in call or formals\n")
		print(allargs())
		cat("Values as defined at the time of the call\n")
		print(allargs(T))
	}

	tempf()
}
