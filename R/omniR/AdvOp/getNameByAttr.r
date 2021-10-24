#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the names by provided attributes from any object that can be visited by methods of both       #
#   | [names()] and [attr(el,req.attr)], while output them in the same sequence as the requested labels                                 #
#   |This is useful for extration of column names by provided column labels respectvely.                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 当一个data frame同时有[字段名]和它们对应的[属性]（如：label），可用此function通过提供[label]来获取对应的[name]                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |obj        :   Any object that can be visited by both methods of [names()] and [attr(,req.attr)], such as a [data.frame]           #
#   |req.attr   :   One specific attribute that will be used to access the object and extract respective [names]                        #
#   |               [label           ] <Default> Try to access the attribute by [attr(,'label')]                                        #
#   |               [<chr. string>   ]           Single string of characters as attribute of the element of [obj]                       #
#   |req.val    :   Vector or list of requested values for the [req.attr]                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector]   :   Any of the [names] that are extracted from the [obj] by accessing its [attr]                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210128        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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

getNameByAttr <- function(obj, req.attr = 'label', req.val = NULL){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(names(obj))) stop('[',LfuncName,']','There is no way to access [obj] by [names()]!')
	if (is.null(req.attr)) req.attr <- 'label'
	if (length(req.attr)>1) {
		warning('[',LfuncName,']','[req.attr] is provided more than one, only the first will be extracted!')
		req.attr <- req.attr[[1]]
	}
	if (length(req.val)==0) stop('[',LfuncName,']','[req.val] is not provided for extraction!')
	req.val <- unname(unlist(req.val))

	#100. Extract the requested attribute for each element in the provided [obj]
	obj_attrs <- sapply( obj, function(e){ attr(e, req.attr) } )
	obj_names <- names(obj)

	#500. Extract the positions of the requested [req.val]
	req_match <- match(req.val,obj_attrs)
	req_pos <- Filter(Negate(is.na), req_match)
	req_miss <- req.val[unlist(Map(is.na, req_match))]

	#999. Extract the positional values in terms of the requested [req.val]
	if (length(req_pos)==0) {
		message('[',LfuncName,']','None of [req.val] is found in the requested attribute [',req.attr,'].')
		print(req_miss)
		return(NULL)
	} else {
		#100. Print the log for all requested values that are NOT found in the requested attribute
		if (length(req_miss)!=0) {
			message('[',LfuncName,']','Below values are not found in the attribute [',req.attr,'] for [obj]:')
			print(req_miss)
		}

		#999. Only output the items that are found
		out_names <- obj_names[req_pos]
		names(out_names) <- obj_attrs[req_pos]
		return(out_names)
	}
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Create object with both [names] and [attr]
		test_var <- list('aa' = 1, 'bb' = 2, 'ccc' = 3)
		lbls <- c('lbl1', 'label2', 'lbl3')
		for (i in seq_along(test_var)) {
			attr(test_var[[i]], 'label') <- lbls[[i]]
		}

		#200. Test to extract names by 2 labels
		getItem1 <- getNameByAttr(test_var, req.attr = 'label', req.val = c('lbl3','lbl1'))

		#300. Test to extract names by 1 label
		getItem2 <- getNameByAttr(test_var, req.attr = 'label', req.val = c('lbl1'))

		#400. Test to extract names by a non-existing label
		getItem3 <- getNameByAttr(test_var, req.attr = 'label', req.val = list('lbl4','lbl3'))

		#500. Test to extract names by a non-existing attribute
		getItem4 <- getNameByAttr(test_var, req.attr = 'method', req.val = c('lbl1'))

	}
}
