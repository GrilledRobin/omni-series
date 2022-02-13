#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the substrings surrounded by the provided boundaries, in terms of the concept of Balanced     #
#   | Group in Regular Expression (while NOT using RegExp as it would fail in many cases)                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use [BeautifulSoup] instead)            #
#   |[2] Resolve the jinja-like expression such as: f<g<a>>, when [a] is a variable, [g<a>] is another, and so forth                    #
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
#   |include    :   Whether to include the bounding characters in the output substrings                                                 #
#   |               [TRUE       ] <Default> Include the bounds as output                                                                #
#   |               [FALSE      ]           Exclude the bounds as output                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List of substrings out of each pair of boundaries as a Balanced Group                                               #
#   |               [IMPORTANT]                                                                                                         #
#   |               [1] If the bounds do not exist in pairs, NA is returned                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |rlang                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |locSubstr                                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

strBalancedGroup <- function(
	txt
	,lBound = '('
	,rBound = ')'
	,rx = FALSE
	,include = TRUE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	if (!is.character(txt)) stop('[',LfuncName,'][txt]:[', typeof(txt), '] must be provided a character vector!')
	if (any(lBound == rBound)) stop('[',LfuncName,'][lBound]:[', lBound, '] and [rBound]:[', rBound, '] must be different strings!')
	if (!is.logical(rx)) stop('[',LfuncName,'][rx]:[', typeof(rx), '] must be provided a logical value!')
	if (!is.logical(include)) stop('[',LfuncName,'][include]:[', typeof(include), '] must be provided a logical value!')
	if (!rx) {
		lBound <- re.escape(lBound)
		rBound <- re.escape(rBound)
	}

	#100. Compare the occurrences of both bounds and stop if they do not match
	#Return value of below function is a list of matrices comprised of start and end positions
	posLB <- locSubstr(lBound, txt, overlap = FALSE)
	posRB <- locSubstr(rBound, txt, overlap = FALSE)

	#200. Define helper functions
	#210. Function to count the occurrences of bounds
	h_cnt_bound <- function(x){length(Filter(Negate(is.na), x[,'start']))}

	#250. Function to extract substrings from each element of the input vector
	getstr <- function(i){
		#100. Combine the positions of both bounds and arrange them from left to right
		posLB_i <- posLB[[i]]
		posRB_i <- posRB[[i]]
		pos_all <- rbind(posLB_i, posRB_i)
		pos_all <- pos_all[order(pos_all[,'start'], decreasing = F),]

		#200. Prepare the adjuster of the Balanced Group
		pos_adj <- as.integer(pos_all[,'start'] %in% posRB_i[,'start'])

		#300. Add 1 on group ID if we encounter the left bound, or subtract by 1 if we encounter the round bound
		pos_cnt <- cumsum((pos_all[,'start'] %in% posLB_i[,'start']) - (pos_all[,'start'] %in% posRB_i[,'start'])) + pos_adj

		#500. Set the rowname of the combined positions, for later extraction from the matrix
		rownames(pos_all) <- pos_cnt

		#700. Identify the start and end positions to extract for each group
		pos_ext <- sapply(
			unique(pos_cnt)
			,function(rowid){
				#100. Identify the starts and ends of current group
				submat <- pos_all[rownames(pos_all) == rowid,]
				rownames(submat) <- NULL
				rowBgn <- rowEnd <- seq_len(nrow(submat))
				rowEnd <- rowEnd[rowEnd %% 2 == 0]
				rowBgn <- rowBgn[!(rowBgn %in% rowEnd)]

				#300. Determine the bound name to extract
				if (include) {
					strBgn <- 'start'
					strEnd <- 'end'
				} else {
					strBgn <- 'end'
					strEnd <- 'start'
				}

				#500. Extraction
				posBgn <- submat[rowBgn, strBgn]
				posEnd <- submat[rowEnd, strEnd]

				#700. Adjust the positions
				if (!include) {
					posBgn <- posBgn + 1
					posEnd <- posEnd - 1
				}

				#900. Return a new matrix
				return(cbind(posBgn, posEnd))
			}
			,simplify = F
		)
		pos_ext <- eval(rlang::expr(rbind(!!!pos_ext)))

		#750. Reset the rownames
		rownames(pos_ext) <- NULL

		#800. Extract the substrings
		str_ext <- substring(txt[[i]], pos_ext[,1], pos_ext[,2])

		#999. Return the extracted values
		return(str_ext)
	}

	#500. Count the occurrences of both bounds
	kLB <- sapply(posLB, h_cnt_bound)
	kRB <- sapply(posRB, h_cnt_bound)

	#700. Calculation
	seq_loop <- seq_len(length(kLB))
	rstOut <- lapply(seq_loop, function(x){NA})
	rstOut[seq_loop[kLB == kRB]] <- lapply(seq_loop[kLB == kRB], getstr)

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
		teststr <- c('(bb (cc (dd))) aa (ee (ff))', 'a (b', 'ddef')
		testjinja <- '{{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
		testhtml <- '<div a="1"><div id="2"></div><div id="3"></div></div>'

		#200. Extraction
		ext_parens <- strBalancedGroup(
			teststr
			,lBound = '('
			,rBound = ')'
			,rx = FALSE
			,include = TRUE
		)

		ext_jinja <- lapply(
			strBalancedGroup(
				testjinja
				,lBound = '{{'
				,rBound = '}}'
				,rx = FALSE
				,include = FALSE
			)
			,trimws
		)

		ext_html <- lapply(
			strBalancedGroup(
				testhtml
				,lBound = '<div.*?>'
				,rBound = '</div>'
				,rx = TRUE
				,include = TRUE
			)
			,trimws
		)
	}
}
