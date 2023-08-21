#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to evaluate the substrings surrounded by the provided boundaries, in terms of the concept of Balanced    #
#   | Group in Regular Expression (while NOT using RegExp as it would fail in many cases), and then replace their respective positions  #
#   | with their parsed values in current environment, i.e. treat them as variables in current session                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Resolve the jinja-like expression such as: f<g<a>>, when [a] is a variable, [g<a>] is another, and so forth                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt        :   Character string from which to extract the substrings                                                               #
#   |lBound     :   Left bound of the substring, can be provided with a string, which will be stripped and then treated as a whole      #
#   |               [(          ] <Default> A single left parenthesis                                                                   #
#   |rBound     :   Right bound of the substring, can be provided with a string, which will be stripped and then treated as a whole     #
#   |               [)          ] <Default> A single right parenthesis                                                                  #
#   |rx         :   Whether to treat the [lBound] and [rBound] as Regular Expression                                                    #
#   |               [FALSE      ] <Default> Treat them as raw character strings                                                         #
#   |               [TRUE       ]           Treat them as regular expressions                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<various>  :   The character vector with possible replacement at the positions of Balanced Group Expressions                       #
#   |               [1] Expressions such as : f<g<a>>, will be evaluated in recursion                                                   #
#   |               [2] Given that any expression, such as: <a>, is not a known variable in current session, it will be treated as      #
#   |                    plain text with the bounds removed in the output result                                                        #
#   |               [3] When all elements of the result are of the same internal type, i.e. <character>, the output result is flattened #
#   |                    as a vector, otherwise it is a list in the same length as the input vector                                     #
#   |               [Special Case] When the whole string is surrounded by the bounds and its evaluation is successful, the return value #
#   |                               will be the same as its referenced object, which may be of any type                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220212        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <sys.function> to complement the base <Recall> under certain circumstances                                    #
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
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |get_values                                                                                                                 #
#   |   |   |re.escape                                                                                                                  #
#   |   |   |locSubstr                                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#

strBalancedGroupEval <- function(
	txt
	,lBound = '('
	,rBound = ')'
	,rx = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	recall <- sys.function()

	#012. Parameter buffer
	if (!is.character(txt)) stop('[',LfuncName,'][txt]:[', typeof(txt), '] must be provided a character vector!')
	if (any(lBound == rBound)) stop('[',LfuncName,'][lBound]:[', lBound, '] and [rBound]:[', rBound, '] must be different strings!')
	if (!is.logical(rx)) stop('[',LfuncName,'][rx]:[', typeof(rx), '] must be provided a logical value!')
	if (!rx) {
		lBound_i <- re.escape(lBound)
		rBound_i <- re.escape(rBound)
	} else {
		lBound_i <- lBound
		rBound_i <- rBound
	}

	#100. Compare the occurrences of both bounds and stop if they do not match
	#Return value of below function is a list of matrices comprised of start and end positions
	posLB <- locSubstr(lBound_i, txt, overlap = FALSE)
	posRB <- locSubstr(rBound_i, txt, overlap = FALSE)

	#200. Define helper functions
	#210. Function to count the occurrences of bounds
	h_cnt_bound <- function(x){length(Filter(Negate(is.na), x[,'start']))}

	#250. Function to identify the bounds of string extraction
	h_ext_bound <- function(mat, rowid, method){
		#100. Identify the starts and ends of current group
		submat <- mat[rownames(mat) == rowid,]
		rownames(submat) <- NULL
		rowBgn <- rowEnd <- seq_len(nrow(submat))
		rowEnd <- rowEnd[rowEnd %% 2 == 0]
		rowBgn <- rowBgn[!(rowBgn %in% rowEnd)]

		#300. Determine the bound name to extract
		if (method == 'get') {
			strBgn <- 'end'
			strEnd <- 'start'
		} else {
			strBgn <- 'start'
			strEnd <- 'end'
		}

		#500. Extraction
		posBgn <- submat[rowBgn, strBgn]
		posEnd <- submat[rowEnd, strEnd]

		#700. Adjust the positions
		if (method == 'get') {
			posBgn <- posBgn + 1
			posEnd <- posEnd - 1
		}

		#800. Form a new matrix and reset its rownames
		rstOut <- cbind(posBgn, posEnd)
		rownames(rstOut) <- NULL

		#900. Return a new matrix
		return(rstOut)
	}

	#290. Function to replace substrings of each element of the input vector in recursion
	replstr <- function(i){
		#100. Combine the positions of both bounds and arrange them from left to right
		posLB_i <- posLB[[i]]
		posRB_i <- posRB[[i]]
		pos_all <- rbind(posLB_i, posRB_i)
		pos_all <- pos_all[order(pos_all[,'start'], decreasing = F),]

		#200. Prepare the adjuster of the Balanced Group
		pos_adj <- as.integer(pos_all[,'start'] %in% posRB_i[,'start'])

		#300. Add 1 on group ID if we encounter the left bound, or subtract by 1 if we encounter the round bound
		pos_cnt <- cumsum((pos_all[,'start'] %in% posLB_i[,'start']) - (pos_all[,'start'] %in% posRB_i[,'start'])) + pos_adj

		#500. Set the rowname of the combined positions, for later string replacement in recursion
		rownames(pos_all) <- pos_cnt

		#600. Replace the group with the largest ID (aka the inner-most group) with its parsed value
		#610. Identify the ID of the inner-most groups
		max_grp <- max(pos_cnt)
		#Retrieve the first among the IDs as initiation
		idx_grp <- match(max_grp, pos_cnt)
		#The same Group ID always exists in pairs
		k_grp <- as.integer(length(pos_cnt[pos_cnt == max_grp]) / 2)

		#620. Determine the replacement of each identified group
		idx_get <- h_ext_bound(pos_all, max_grp, 'get')
		idx_rep <- h_ext_bound(pos_all, max_grp, 'rep')

		#650. Try to get the value of the variables represented by the embraced substrings
		val <- get_values(as.list(trimws(substring(txt[[i]], idx_get[,'posBgn'], idx_get[,'posEnd']))), inplace = T)

		#670. Identify whether the whole string is to be replaced
		#[IMPORTANT]
		#[1] There can only be 0 or 1 group that matches such rule
		#[2] If there is 1 group that matches the rule, it is the only one, i.e. [k_grp == 1]
		pos_whole <- idx_rep[idx_rep[,'posBgn'] == 1 & idx_rep[,'posEnd'] == nchar(txt[[i]]),'posBgn']
		if (length(pos_whole) == 1) return(val)

		#680. Prepare the loop to replace the substrings
		#[IMPORTANT]
		#[1] Conduct replacement from right to left, which is safe
		if (length(val) > 1) {
			bgn_rep <- rev(idx_rep[,'posBgn'])
			end_rep <- rev(idx_rep[,'posEnd'])
			val <- rev(val)
		} else {
			bgn_rep <- idx_rep[,'posBgn']
			end_rep <- idx_rep[,'posEnd']
		}

		#690. Conduct the replacement
		rstMid <- txt[[i]]
		for (j in seq_along(bgn_rep)) {
			rstMid <- paste0(
				substring(rstMid, 1, bgn_rep[[j]] - 1)
				,val[[j]]
				,substring(rstMid, end_rep[[j]] + 1)
			)
		}

		#700. Process the new string by the provided bounds in recursion
		rstOut <- recall(
			txt = rstMid
			,lBound = lBound
			,rBound = rBound
			,rx = rx
		)

		#999. Return
		return(rstOut)
	}

	#500. Count the occurrences of both bounds
	kLB <- sapply(posLB, h_cnt_bound)
	kRB <- sapply(posRB, h_cnt_bound)

	#700. Calculation
	seq_loop <- seq_along(txt)
	calc_loop <- seq_loop[(kLB != 0) & (kLB == kRB) & sapply(txt, is.character)]
	rstOut <- txt

	#750. Vectorize the translation if all of the results are of the same value type
	if (length(calc_loop) > 0) {
		#100. Element-wise calculation
		rstTmp <- lapply(calc_loop, replstr)

		#500. Flatten the result when all of the results are of the same value type
		vec_internal <- c('logical','integer','double','complex','character','raw')
		rstType <- unique(sapply(rstTmp, typeof))
		if ((length(rstType) == 1) & all(rstType %in% vec_internal)) rstTmp <- unlist(rstTmp)

		#900. Overwrite the values for certain elements
		if (length(calc_loop) == length(rstOut)) {
			rstOut <- rstTmp
		} else {
			rstOut[calc_loop] <- rstTmp
		}
	}

	#800. Flatten if there is only one element of the input vector
	if (length(rstOut) == 1) rstOut <- rstOut[[1]]

	#999. Return
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare strings
		fill_a <- 'bb'
		fill_bb <- 5
		fill_cc <- 10
		fill_dd <- data.frame(x = 1)
		fill_ee <- data.frame(x = 2)
		teststr <- c('(gg (fill_(fill_a))) aa (ee (ff))', '(fill_bb)', 'fill_a', 'aa(b')
		teststr2 <- c('(fill_bb)', '(fill_cc)')
		testjinja <- '{{ fill_{{ fill_a }} }}'
		testjinja2 <- '{{ fill_dd }}'
		testjinja3 <- c('{{ fill_dd }}', '{{ fill_ee }}')

		#200. Evaluation
		#Return a list as the parsed results are of different value types
		eval_str <- strBalancedGroupEval(
			teststr
			,lBound = '('
			,rBound = ')'
			,rx = FALSE
		)

		#Return a numeric vector as the parsed results are of the same internal type
		eval_str2 <- strBalancedGroupEval(
			teststr2
			,lBound = '('
			,rBound = ')'
			,rx = FALSE
		)

		#Recursion
		eval_jinja <- strBalancedGroupEval(
			testjinja
			,lBound = '{{'
			,rBound = '}}'
			,rx = FALSE
		)

		#Return a data.frame as the input vector has the length of 1
		eval_jinja2 <- strBalancedGroupEval(
			testjinja2
			,lBound = '{{'
			,rBound = '}}'
			,rx = FALSE
		)
		class(eval_jinja2)

		#Return a list of [data.frame]s
		eval_jinja3 <- strBalancedGroupEval(
			testjinja3
			,lBound = '{{'
			,rBound = '}}'
			,rx = FALSE
		)
		sapply(eval_jinja3, class)
	}
}
