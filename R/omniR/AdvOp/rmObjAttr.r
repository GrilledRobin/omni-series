#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to remove the dedicated attribute(s) or all attributes from the provided object, while leaving [names]   #
#   | untouched                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 对两个data frame执行[*join]时，若使用的[key]字段分别有不同的[attributes]，会报warning；用这个function作预处理即可              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |obj        :   Any object that can be visited by both methods of [names()] and [attr(,in_attr)], such as a [data.frame]            #
#   |req.attr   :   The attribute(s) of the provided object to be removed                                                               #
#   |               [NULL            ] <Default> Remove all attributes if any                                                           #
#   |               [<chr. vec/list> ]           Attributes to be removed if any                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[obj   ]   :   The same object as the input one, without the requested attribute(s)                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210129        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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

rmObjAttr <- function(obj, req.attr = NULL){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	req.attr <- unname(unlist(req.attr))

	#100. Retrieve the list of attributes of [obj]
	obj_attrs <- names(attributes(obj))

	#200. Indicate to remove all attributes if not required
	if (length(req.attr)==0) req.attr <- obj_attrs

	#300. Match the requested attributes to those existing ones
	req_match <- match(req.attr, obj_attrs)
	req_match <- Filter(Negate(is.na), req_match)

	#500. Remove the matched attributes one by one
	#If there is no attribute of [obj] we have to skip below step, otherwise [obj] is removed if it is an element in a list!
	if (length(obj_attrs)>0 & length(req_match)>0) {
		for (a in obj_attrs[req_match]) {
			# message(a)
			# message(attr(obj, a))
			attr(obj, a) <- NULL
		}
	}

	#999. Return the possibly modified object
	return(obj)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Create object with both [names] and [attr]
		test_var <- list('aa' = 1, 'bb' = 2, 'ccc' = 3)
		lbls <- c('lbl1', 'label2', 'lbl3')
		fmts <- c('$', 'yymmdd10.', 'best12.')
		for (i in seq_along(test_var)) {
			attr(test_var[[i]], 'label') <- lbls[[i]]
			attr(test_var[[i]], 'format.sas') <- fmts[[i]]
		}
		df_a <- data.frame(
			a_col1 = character(0)
			,a_col2 = integer(0)
			,a_col3 = character(0)
			,stringsAsFactors = F
		)
		attr(df_a$a_col1, 'label') <- 'ID'
		attr(df_a$a_col2, 'label') <- 'Txn Amt'
		attr(df_a$a_col3, 'label') <- 'Txn Date'

		#200. Test to remove all attributes
		rmAttr1 <- lapply(test_var, rmObjAttr)

		#300. Test to remove one specific attribute
		rmAttr2 <- lapply(test_var, rmObjAttr, req.attr = 'label')

		#400. Test to apply the function inside [dplyr::mutate]
		rmAttr3 <- dplyr::mutate_at( df_a, 'a_col2', rmObjAttr, req.attr = 'label' )
		View(rmAttr3)

		#500. Another test on data.frame
		rmAttr4 <- dplyr::mutate( df_a, a_col2 = rmObjAttr(a_col2) )
		View(rmAttr4)

	}
}
