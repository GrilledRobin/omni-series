#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to map the values within the provided list or vector into another set of values by the given dictionary  #
#   | a.k.a. the similar function as [Format Procedure] in SAS.                                                                         #
#   |It also acts as a helper function to conduct value mapping in a data.frame via [mutate] function from [dplyr] package, see below   #
#   | examples.                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec         :   List or vector of values to be mapped into another set of values (also accept a column in a data.frame when used   #
#   |                 in [mutate] function of [dplyr] package)                                                                          #
#   |                [IMPORTANT] It will be converted by [as.character()] during the mapping process                                    #
#   |dict_map    :   List or vector of value mapping within which: [names] represent the values to be mapped from the [vec]; [values]   #
#   |                 represent the new values as mapping result                                                                        #
#   |                [IMPORTANT] Unlike FORMAT Procedure in SAS, the same name cannot exist twice in an R list/vector; hence we cannot  #
#   |                             define the process for a multiple match                                                               #
#   |preserve    :   Logical value indicating whether to preserve the input values if they cannot be mapped in the given dictionary     #
#   |                 [TRUE        ]  <Default> Preserve the original values if there is mo mapping for them                            #
#   |                 [FALSE       ]             Discard the input values and output an [NA] in place if there is no mapping for them   #
#   |placeholder :   The placeholder for output if the length (i.e. number of elements) of the entire input vector is 0                 #
#   |                 [TRUE        ]  <Default> Output a zero-length placeholder in the same type as the values in [dict_map]           #
#   |                 [FALSE       ]            Do not output a placeholder                                                             #
#   |force_mark  :   The name in the [dict_map] with value to force output when there is no mapping result for the input value while    #
#   |                 the parameter [preserve] is set FALSE.                                                                            #
#   |                 [...         ]  <Default> Output the value in the name of '...' in the [dict_map] when condition is fulfilled     #
#   |                 [(char. str) ]            Output the value in the name of '(char. str)' in the [dict_map] when condition is       #
#   |                                            fulfilled                                                                              #
#   |fPartial    :   Whether to partially replace the input values by the mapping dictionary                                            #
#   |                 [FALSE       ]  <Default> Replace the entire string if it matches any name in the dictionary, i.e. DO NOT keep    #
#   |                                            the rest of the the input [vec] given they are not matched in the dictionary           #
#   |                 [TRUE        ]            Replace the matching part of the string with the value in the dictionary                #
#   |out_first   :   Whether to output the first or last matching result given [fPartial==FALSE]                                        #
#   |                 [TRUE        ]  <Default> When there is any match, output the first result in [dict_map]                          #
#   |                 [FALSE       ]            When there is any match, output the last result in [dict_map]                           #
#   |PRX         :   Whether to use Perl Regular Expression to conduct the replacement                                                  #
#   |                 [FALSE       ]  <Default> Match the string without Perl Regular Expression, i.e. no special character patterns    #
#   |                 [TRUE        ]            Match the string with Perl Regular Expression                                           #
#   |full.match  :   Whether to match the entire input string within [vec]                                                              #
#   |                 [TRUE        ]  <Default> The match is valid ONLY WHEN the first match is on the first character AND its length   #
#   |                                            is the same as the number of characters of the input [vec]                             #
#   |                 [FALSE       ]            Any sub-string in [vec] that matches anyone in the dictionary will suffice the rule     #
#   |ignore.case :   Same as that in the official document for [gregexpr]                                                               #
#   |                 [FALSE       ]  <Default> Do not ignore case during the match                                                     #
#   |                 [TRUE        ]            Ignore case during the match                                                            #
#   |...         :   Any other parameters that are required by [stringi::stri_opts_fixed], or [stringi::stri_opts_regex], except        #
#   |                 [case_insensitive] as it is already used. Please check the documents for those functions                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vec/list]  :   The mapped result stored in a vector or list, as indicated by [vec]                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200721        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200729        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [placeholder] to ensure a dedicated type of output if the input vector has no element.                  #
#   |      | This is useful when a data.frame has no row but we still need to create a new column by the pre-defined mapping. In such   #
#   |      |  case, when we only use [sapply/lapply] to the input, the corresponding output is NULL, hence the new column cannot be     #
#   |      |  created. That is when we will set a placeholder to ensure this column with the dedicated data type is still created.      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200804        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [force_mark] to ensure a user-defined replacement of value can be output when there is no mapping       #
#   |      |     result for the input while the parameter [preserve] is set as [FALSE].                                                 #
#   |      |[2] Enable mapping results in different data types when the output is a list as indicated by [func=='lapply'].              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210123        | Version | 4.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [fPartial] to Indicate whether to partially replace the values instead of wholy replace                 #
#   |      |[2] Add a parameter [PRX] to Indicate whether to use perl regular expression during value replacement                       #
#   |      |[3] Add a parameter [full.match] to Indicate whether to match the entire string BEFORE replacing                            #
#   |      |[2] Add other parameters that are same as in [gregexpr] for diversification                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210131        | Version | 4.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fix the bug on [PRX] by adding pointer to each matched RegExp in the mapping dictionary so that each logical value in   #
#   |      |     [PRX] can now be applied to the function [gsub] correctly                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210613        | Version | 5.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the entire function by eliminating [for] loops, which improves the efficiency by 3 times                        #
#   |      |[2] No longer handle numeric values, while focus on character strings, to purify the function                               #
#   |      |[3] Introduce [stringi] functions to replace [gregexpr], also to improve the overall efficiency                             #
#   |      |[4] New argument [out_first] indicates whether the first or last matching result to be output for each element when         #
#   |      |     [fPartial==FALSE]                                                                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210624        | Version | 6.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the entire function by fully applying [stringi] functions, which improves the efficiency by 50 times in line    #
#   |      |[2] Remove the argument [out_first] as there is no API in [stringi] to handle this situation                                #
#   |      |[3] Known limitation: '\$', '\\$' and '\\\$' cannot be differentiated for [full.match] when preparing proper [regex]        #
#   |      |    Solution for this: avoid to provide '$' to indicate a line-end in [dict_map], as it is handled in the function          #
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
#   |   |rlang, stringi                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, stringi
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

apply_MapVal <- function(
	vec
	,dict_map
	,preserve = T
	,placeholder = T
	,force_mark = '...'
	,fPartial = F
	,PRX = F
	,full.match = T
	,ignore.case = F
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (!is.logical(preserve)) preserve <- F
	if (!is.logical(placeholder)) placeholder <- F
	if (!is.logical(fPartial)) fPartial <- F
	if (!is.logical(PRX)) PRX <- F
	if (!is.logical(full.match)) full.match <- F
	if (!is.logical(ignore.case)) ignore.case <- F
	#Below statements are copied from [dplyr::bind_rows]
	dots <- rlang::list2(...)
	dots <- dots[names(dots) != 'case_insensitive']

	#009. Directly return if the input vector has zero length
	if (length(vec) == 0) {
		if (placeholder) return(character(0))
		else return(NULL)
	}

	#050. Local environment
	#051. Ensure all values are in the class of [character] for string processing
	vec <- as.character(unlist(vec))
	interim_map <- as.character(names(dict_map))
	dict_map <- unlist(as.character(dict_map))
	names(dict_map) <- interim_map

	#100. Translate [dict_map] on different scenarios
	#110. Extract the special mapping value [force_mark] as it has nothing to do with the substitution in general
	if (force_mark %in% names(dict_map)) {
		#100. Extract the value to replace all input ones that satisfy the conditions to force output
		#We do not need its [name] attribute in this function, hence double brackets are used.
		map_force <- dict_map[[force_mark]]

		#900. Exclude the mapping for [force_mark] for general mapping process
		#We do need the [name] attribute for [dict_map], hence single brackets are used.
		dict_map <- dict_map[names(dict_map) != force_mark]
	} else {
		map_force <- NULL
	}

	#130. Expand the RegEx when it is requested to replace the entire input string given any part of it matches the pattern
	#[ASSUMPTION]
	#[1] It is tested that [stri_replace_all] will conduct substitution for each pair of [pattern -> replacement] respectively
	if (PRX & !fPartial) {
		names(dict_map) <- paste0(
			'.*'
			,stringi::stri_replace_all(
				names(dict_map)
				,c('','')
				#Remove all possible leading [^] and trailing [$] (without preceding [\] as an escape)
				#However, if there are [\] in an odd number times preceding [$] program fails to detect!
				#This is a known limitation
				,regex = c('^\\^*','(?<!\\\\)\\$*$')
				#Prevent the input vector from being replicated over all patterns in [regex]
				,vectorize_all = F
			)
			,'.*'
		)
	}

	#150. Expand the RegEx when it is requested to match the entire input string by any pattern
	#[ASSUMPTION]
	#[1] Ensure all patterns begins with [^] and ends with [$] to restrict the matching
	#[2] This rule is independent to the one above, hence both rules could be applied to the pattern
	#[3] Due to rule [2], we have to conduct this step AFTER all similar rules set in this function to ensure correctness
	if (PRX & full.match) {
		names(dict_map) <- paste0(
			'^'
			,stringi::stri_replace_all(
				names(dict_map)
				,c('','')
				,regex = c('^\\^*','(?<!\\\\)\\$*$')
				,vectorize_all = F
			)
			,'$'
		)
	}

	#170. Combine all patterns into one, using [|] to indicate [any] during the matching
	dict_comb <- paste0(names(dict_map), collapse = '|')

	#300. Determine whether the function conducts the substitution by [regex] or [fixed]
	#[ASSUMPTION]
	#[1] There is no similar function as [re.escape] in Python, hence we have to prepare separate ways to handle them
	if (PRX) type_repl <- 'regex'
	else type_repl <- 'fixed'

	#500. Conduct the substitution while getting the status of whether there is a match for each element
	if (full.match & !PRX) {
		#This scenario is for a plain text comparison
		v_match <- match(vec, names(dict_map))
		outRst <- unname(dict_map[v_match])
	} else {
		#100. Detect whether there is a match to any among the patterns
		v_match <- do.call(
			stringi::stri_detect
			,c(
				rlang::list2(
					str = vec
					,!!type_repl := dict_comb
					,case_insensitive = ignore.case
				)
				,dots
			)
		)

		#500. Conduct the substitution by pairs of [pattern -> replacement]
		outRst <- do.call(
			stringi::stri_replace_all
			,c(
				rlang::list2(
					str = vec
					,!!type_repl := names(dict_map)
					,case_insensitive = ignore.case
					,replacement = dict_map
					,vectorize_all = F
				)
				,dots
			)
		)
	}

	#800. Set values for those among [vec], which has no match in any of the patterns in [dict_map]
	if (any(is.na(v_match))) {
		if (!preserve & !is.null(map_force)) {
			outRst[is.na(v_match)] <- map_force
		} else if (!preserve) {
			outRst[is.na(v_match)] <- NA
		} else {
			outRst[is.na(v_match)] <- vec[is.na(v_match)]
		}
	}

	#999. Return the result
	return(outRst)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		library(dplyr)
		mydict <- list(
			'a' = 'old'
			,'b' = 'new'
			,'c' = 'unknown'
		)
		usr_val <- c('a','b')
		usr_df <- data.frame(old = c('a','b','d'), stringsAsFactors = F)

		#100. Map the values in a vector
		map_val <- apply_MapVal(usr_val, mydict)

		#200. Map the values in a data.frame
		map_df <- usr_df %>%
			dplyr::mutate(
				new_var = apply_MapVal(old, mydict)
			)

		View(map_df)

		#300. Test upon an empty data.frame
		#[Quote: https://stackoverflow.com/questions/10689055/create-an-empty-data-frame ]
		empty_df <- data.frame(
			x = character()
			,stringsAsFactors = F
		)
		empty_map <- empty_df %>%
			dplyr::mutate(
				new_var = apply_MapVal(x, mydict)
			)

		glimpse(empty_map)

		#400. Test placeholder
		mydict3 <- c(
			'a' = 1
			,'b' = 2
			,'c' = 3
		)

		aa <- iris
		bb <- aa %>% filter(Sepal.Length == 100)
		bb <- bb %>% mutate(test = apply_MapVal(Sepal.Length, mydict3))
		typeof(bb$test)

		#500. Test different value types in the mapping dictionary
		mydict4 <- list(
			`3` = '6.5'
			,`4` = 7
			#The name of below item should match that in the parameter [force_mark]
			,'...' = 10
		)
		chkval <- c(4,3,5)

		map2_vec <- apply_MapVal(chkval, mydict4)

		map2_withDefault <- apply_MapVal(chkval, mydict4, preserve = F, force_mark = '...')

		#600. Test to partially replace a number
		mydict5 <- list(
			`3.5` = 6.5
			,`4` = 7
			#The name of below item should match that in the parameter [force_mark]
			,'...' = 10
		)
		chkval2 <- c(4,13.5,5)

		#Below cases has the same effect, as [fPartial] can only be applied to [regex]
		map3_vec <- apply_MapVal(chkval2, mydict5, fPartial = T, full.match = F)
		map3_vec2 <- apply_MapVal(chkval2, mydict5, fPartial = F, full.match = F)

		#650. Test [fPartial] for [regex]
		dict_part <- c('a.+b' = 'cc')
		chkval3 <- 'a456bdd'
		map4_vec <- apply_MapVal(chkval3, dict_part, fPartial = T, full.match = F, PRX = T)
		map4_vec2 <- apply_MapVal(chkval3, dict_part, fPartial = F, full.match = F, PRX = T)

		#700. Test multiple occurrences in one string
		fTrans <- list(
			'&c_date\\.' = 'G_d_curr'
			,'&L_curdate\\.' = 'G_d_curr'
			,'&L_curMon\\.' = 'G_m_curr'
			,'&L_prevMon\\.' = 'G_m_prev'
		)
		G_d_curr <- '20160310'
		G_m_curr <- substr(G_d_curr,1,6)
		test_sample <- paste(
			c(
				'rpt_&L_curMon._&c_date._&c_date.'
				,'rpt_&L_curMon.'
				,'rpt'
				,'rpt_aa_&c_date.'
				,'ttt&c_date.__bb'
				,'ccc&L_curdate.__'
			)
			,'sas7bdat'
			,sep = '.'
		)
		ttt <- sample(test_sample, 100000, replace = T)

		get_list_val <- list()
		for (i in seq_along(fTrans)) {
			get_list_val[[i]] <- mget(fTrans[[i]], inherits = T, ifnotfound = NA)[[1]]
			if(is.na(get_list_val[[i]])) get_list_val[[i]] <- names(fTrans)[[i]]
		}
		names(get_list_val) <- names(fTrans)

		start_time <- Sys.time()
		test_result <- apply_MapVal(
			ttt
			,dict_map = get_list_val
			,preserve = T
			,placeholder = T
			,force_mark = '...'
			,fPartial = T
			,PRX = T
			,full.match = F
			,ignore.case = T
		)
		end_time <- Sys.time()
		message(end_time - start_time)
		#0.27 s (5 times faster than the same function in Python, as that one in Python is not based on C/C++)
		#15.80 s when using [mapply]
		#1.39 m when using [gregexpr] with [for] loops

		head(test_result)

	}
}
