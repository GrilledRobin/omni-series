#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve available data.frames in the dedicated packages/libraries                                    #
#   |[Quote: https://stackoverflow.com/questions/27709936/get-a-list-of-the-data-sets-in-a-particular-package ]                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |pkgs       :   The vector that defines all packages to retrieve available data.frames                                              #
#   |dfclass    :   The vector that defines the required [class] of the data.frames                                                     #
#   |                [Default: NULL] Use the pre-defined list of classes as filtration                                                  #
#   |allpkgs    :   Whether to search in all available packages in current session, which overwrites the parameter [pkgs]               #
#   |                [Default: T] Force to search all available packates                                                                #
#   |fDebug     :   Debug mode                                                                                                          #
#   |                [Default: FALSE] Change this to TRUE if you need to identify required classes from existing environment            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[out_dfs]  :   A data.frame that stores the sames of the available data.frames as found                                            #
#   |                [$pkg]  The name of the package within which the data.frame is found                                               #
#   |                [$name] Name of the data.frame                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200226        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200304        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Change the output result into data.frame for more compatibility                                                             #
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

getDFinPKG <- function(pkgs,dfclass=NULL,allpkgs=T,fDebug=FALSE){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (allpkgs) pkgs <- setdiff(.packages(TRUE),c('base','stats'))
	if (is.null(dfclass)){
		dfclass <- c(
			'data.frame' , 'tbl_df' , 'tbl'
			, 'groupedData' , 'nfnGroupedData' , 'nfGroupedData' , 'nmGroupedData' , 'nffGroupedData'
			, 'table' , 'tbl_cube' , 'spec_tbl_df'
		)
	}
	if (is.null(pkgs)) return()
	pkgs <- unlist(pkgs)
	dfclass <- unlist(dfclass)

	#100. Retrieve all names of possible data.frames
	#Option [envir = environment()] prevents the data to be loaded to the global frame/environment
	list_pkgs <- data( package = pkgs , envir = environment() )
	dfs_pkgs <- list_pkgs$results[,'Package']
	dfs_name <- list_pkgs$results[,'Item']

	#150. Only keep the valid part of the names
	dfs_name <- gsub('^([\\w\\.]+).*$','\\1',dfs_name,perl = TRUE)

	#200. Remove the names if they cannot be referenced by the grammar: [pkg::name]
	dfs_class <- sapply(
		paste0(dfs_pkgs,'::',dfs_name),
		function(df){ try( class( eval( parse( text = df ) ) ) , silent = TRUE ) }
	)

	#250. Retrieve the unique names of classes
	#Only necessary when one needs to identify newly added classes
	if (fDebug){
		clss <- dfs_class[-grep('^Error',dfs_class,perl = TRUE)]
		clss_uniq <- NULL
		for (i in clss){
			for (j in i){
				clss_uniq <- c(clss_uniq,j)
			}
		}
		clss_uniq <- unique(clss_uniq)
		message('[',LfuncName,']Below is the list of all available classes for data.frame identification:')
		print(clss_uniq)
	}

	#300. Only need the classes that are required by the user
	vld_class <- sapply( dfs_class , function(x){ any( dfclass %in% x ) } )

	#800. Create the output result
	#810. Prepare the output structure
	out_pkgs <- unique( dfs_pkgs[vld_class] )
	out_lst_dfs <- lapply( out_pkgs , function(x){ unique( dfs_name[ vld_class & dfs_pkgs == x ] ) } )
	names(out_lst_dfs) <- out_pkgs
	out_lst_pkg <- lapply(seq_along(out_lst_dfs), function(i){ rep(names(out_lst_dfs)[[i]],length(out_lst_dfs[[i]])) })

	#890. Create an empty data.frame in case nothing is found
	#[Quote: https://stackoverflow.com/questions/10689055/create-an-empty-data-frame ]
	out_dfs <- data.frame(
		pkg = character(),
		name = character(),
		stringsAsFactors = F
	)

	#891. Fill the data.frame with results
	if (length(out_lst_dfs) > 0){
		out_dfs <- data.frame(
			pkg = Reduce(append,out_lst_pkg),
			name = Reduce(append,out_lst_dfs),
			stringsAsFactors = F
		)
	}

	#999. Return the list
	return(out_dfs)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		usrdfs <- getDFinPKG(fDebug=TRUE)

		#Number of packages that have available data.frames
		length(unique(usrdfs$pkg))

		#Take a look at the data.frames in a certain package
		usrdfs$name[usrdfs$pkg == 'countrycode']

		#Retrieve one of the members as found
		usrdf <- eval( parse( text = paste0( usrdfs[1,'pkg'] , '::' , usrdfs[1,'name'] ) ) )
		View(usrdf)

	}
}
