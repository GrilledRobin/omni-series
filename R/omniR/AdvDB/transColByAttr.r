#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to translate the column names, as well as one of their attributes (such as 'label'), to those in the     #
#   | Model [table], given their requested attribute (for this case, 'label') are well mapped by the provided list                      #
#   |This is useful before binding rows of different data frames, by translating their columns to the same names.                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |tbl          :   The table for which the columns are to be translated                                                              #
#   |Model_tbl    :   The table with columns in terms of which the columns in [tbl] are to be renamed                                   #
#   |                 [NULL            ] <Default> If there is no model table provided, only [req.attr] of the columns will be replaced #
#   |                 [data.frame      ]           The columns with their respective attribute [req.attr] are modeled for translation   #
#   |req.attr     :   The attribute of the columns to be used for translation in [tbl], and to be modeled in [Model_tbl]                #
#   |                 [label           ] <Default> Try to access the attribute by [attr(,'label')]                                      #
#   |                 [<chr. string>   ]           Single string of characters as attribute of the columns in both [obj] and [Model_tbl]#
#   |map.attr     :   The mapping list/vector to be used for translation; [name] represents the [req.attr] in [tbl] as to be translated,#
#   |                  while [value] represents the [req.attr] in [Model_tbl] used for translation                                      #
#   |                 [NULL            ] <Default> No translation is requested. Return the copy of [tbl] with a warning                 #
#   |                 [<list/vec>      ]           Named list/vector in above definition                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[data.frame] :   The data frame within which the requested columns are renamed to those in [Model_tbl], together with the values   #
#   |                  of their respective [req.attr]                                                                                   #
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
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |getNameByAttr                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
lst_pkg <- NULL
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

transColByAttr <- function(tbl, Model_tbl = NULL, req.attr = 'label', map.attr = NULL){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(Model_tbl)) {
		if (length(map.attr)==0) {
			warning('[',LfuncName,']','No translation is requested to perform!')
			return(tbl)
		}
	}
	if (is.null(req.attr)) req.attr <- 'label'
	if (length(req.attr)>1) {
		warning('[',LfuncName,']','[req.attr] is provided more than one, only the first will be extracted!')
		req.attr <- req.attr[[1]]
	}
	map.attr <- unlist(map.attr)

	#100. Extract the values of the requested attribute in [tbl]
	tbl_attrs <- getNameByAttr(tbl, req.attr = req.attr, req.val = names(map.attr))

	#109. Abort the process if there is nothing retrieved by the requested attribute
	if (length(tbl_attrs)==0) {
		stop('[',LfuncName,']','Requsted attribute [',req.attr,'] is not found in [tbl]!')
	}

	#150. Extract the values of the requested attribute in [Model_tbl]
	if (!is.null(Model_tbl)) mdl_attrs <- getNameByAttr(Model_tbl, req.attr = req.attr, req.val = map.attr)
	else mdl_attrs <- NULL

	#200. Output the same table as [tbl] with the [req.attr] translated as per requested, if [Model_tbl] is not usable
	if (is.null(Model_tbl) | length(mdl_attrs)==0) {
		#100. Print the log
		message('[',LfuncName,']','Attribute [',req.attr,'] is translated by [map.attr] as [Model_tbl] is not usable.')

		#300. Replicate the input data
		out_dat <- tbl

		#500. Translate the attribute
		for (i in seq_along(tbl_attrs)) {
			#[IMPORTANT] The statement <attr(out_dat[[...]]> must use double brackets here,
			#            as <out_dat> is a list instead of a vector!
			attr(out_dat[[match(tbl_attrs[[i]], names(out_dat))]], req.attr) <- map.attr[match(names(tbl_attrs)[[i]], names(map.attr))]
		}

		#999. Return the translated data
		return(out_dat)
	}

	#500. Prepare the final mapping list as there could be some columns not referred to or not existing in either table
	map_fnl <- map.attr[match(names(tbl_attrs), names(map.attr))]
	map_fnl <- Filter(Negate(is.na), map_fnl)
	map_fnl <- map_fnl[match(names(mdl_attrs), map_fnl)]
	map_fnl <- Filter(Negate(is.na), map_fnl)

	#599. Return the original table if no column among the requested ones match in either of the tables
	if (length(map_fnl)==0) {
		#100. Print the log
		message('[',LfuncName,']','There is no common value of attribute [',req.attr,'] between the input tables.')
		message('[',LfuncName,']','No translation is performed.')

		#999. Return the input data
		return(tbl)
	}

	#800. Conduct the translation
	#801. Create a copy of the input data
	out_dat <- tbl
	out_lbl <- sapply( out_dat, function(e){ attr(e, req.attr) } )

	#810. Rename the columns in [out_dat] in terms of those in [Model_tbl] given their attribute [req.attr] is mapped by [map_fnl]
	names(out_dat)[match(names(map_fnl), out_lbl)] <- mdl_attrs[match(map_fnl, names(mdl_attrs))]

	#850. Translate the attribute
	for (i in seq_along(map_fnl)) {
		#[IMPORTANT] The statement <attr(out_dat[[...]]> must use double brackets here,
		#            as <out_dat> is a list instead of a vector!
		attr(out_dat[[match(names(map_fnl)[[i]], out_lbl)]], req.attr) <- map_fnl[[i]]
	}

	#999. Return the translated data
	return(out_dat)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Create data frames with both [names] and [attr]
		df_a <- data.frame(
			a_col1 = character(0)
			,a_col2 = integer(0)
			,a_col3 = character(0)
			,stringsAsFactors = F
		)
		attr(df_a$a_col1, 'label') <- 'ID'
		attr(df_a$a_col2, 'label') <- 'Txn Amt'
		attr(df_a$a_col3, 'label') <- 'Txn Date'

		df_b <- data.frame(
			b_col1 = character(0)
			,b_col2 = integer(0)
			,b_col3 = character(0)
			,stringsAsFactors = F
		)
		attr(df_b$b_col1, 'label') <- 'ID'
		attr(df_b$b_col2, 'label') <- 'Sales Amt'
		attr(df_b$b_col3, 'label') <- 'Sales Date'

		#200. Test to translate 1 column in [df_a]
		df_a1 <- transColByAttr(df_a, Model_tbl = df_b, req.attr = 'label', map.attr = c('Txn Amt'='Sales Amt'))
		View(df_a1)

		#300. Test to translate 3 columns, but only one in common
		df_a2 <- transColByAttr(
			df_a
			, Model_tbl = df_b
			, req.attr = 'label'
			, map.attr = list(
				'Txn Amt'='Sales Amt'
				,'ID' = 'ID2'
				,'Order Date' = 'Sales Date'
			)
		)
		View(df_a2)

		#400. Test to translate without [Model_tbl]
		df_a3 <- transColByAttr(df_a, req.attr = 'label', map.attr = c('Txn Amt'='Sales Amt'))
		View(df_a3)

		#500. Test to translate some columns that do not exist in either tables
		df_a4 <- transColByAttr(
			df_a
			, Model_tbl = df_b
			, req.attr = 'label'
			, map.attr = list(
				'Txn Date'='new dates'
				,'ID3' = 'ID4'
				,'city' = 'branch city'
			)
		)
		View(df_a4)

	}
}
