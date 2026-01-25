#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to evaluate the substrings surrounded by the provided boundaries, in terms of the concept of Balanced    #
#   | Group in Regular Expression (while NOT using RegExp as it would fail in many cases), and then replace their respective positions  #
#   | with their parsed values in current environment, i.e. treat them as variables in current session                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Signature Expansion]                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Signature of this function is expanded from <strNestedParser>, see its documents for detailed argument list                    #
#   |[2] With the Signature Expansion functionality, one can obtain the correct signature of this function at runtime in below way      #
#   |    [1] Type <args(func)> in the console to see its full argument list expanded from those retained from the ancestors             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Resolve the jinja-like expression such as: <f{g{a}}>, when <a> is a variable, <g{a}> is another, and so forth                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...               :   All arguments taken from the source function                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>            :   List of character vectors with possible replacement at the positions of Balanced Group Expressions           #
#   |                      [1] Expressions such as : <f{g{a}}>, will be evaluated in recursion                                          #
#   |                      [2] Given that any expression, such as: <{a}>, is not a known variable in current session, it will be treated#
#   |                           as plain text with the bounds removed in the output result                                              #
#   |                      [3] The whole concatenated substring between the boundaries (exclusive of them) is stripped for object lookup#
#   |                      [4] When the whole string is enclosed by the bounds and its evaluation is successful, the return value       #
#   |                           will be the same as its referenced object, which may be of any type                                     #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20260120        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |      |[2] Now behave in the same way as the source function                                                                       #
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
#   |   |rlang, glue                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |get_values                                                                                                                 #
#   |   |   |strNestedParser                                                                                                            #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

strBalancedGroupEval <- local({
deco <- ExpandSignature$new(strNestedParser, instance = 'eSig')
myfunc <- deco$wrap(function(
	...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#050. Local parameters
	dots <- rlang::list2(...)
	args_share <- list('include' = FALSE)
	eSig$vfyConflict(args_share)
	args_in <- eSig$updParams(args_share, dots)

	#060. Ensure no extra effort
	meta_ <- eSig$getParam('meta_', args_in, inc_default = T) |> eval()
	if (meta_){
		message(glue::glue('[{LfuncName}]<meta_> is set as FALSE as this function does not require extra effort.'))
	}
	args_out <- eSig$updParams(list('meta_' = FALSE), args_in)

	#100. Parse the nested structure out of the input string
	nest_struct <- do.call(eSig$src, args_out) |>
		sapply(
			function(s){s[['RESULT']]}
			,simplify = F
			,USE.NAMES = T
		)

	#200. Define helper functions
	#210. Function to join the nested structures into strings respectively, then evaluate the strings into new ones, with recursion
	h_conj_str <- function(struct){
		#[ASSUMPTION]
		#[1] Input structure always has the form: [<string | nested struct>]
		#[2] <nested struct> will be further processed by this function itself,
		#     with its evaluation result MUST BE able to convert to a string using <as.character()>
		#[3] All the evaluated items will be concatenated and then stripped, and then evaluated at current layer
		#100. Initialize
		str_struct <- ''

		#500. Loop over the nested structure
		for (m in struct){
			if (!is.character(m)) {
				str_struct <- paste0(str_struct, as.character(Recall(m)))
			} else {
				str_struct <- paste0(str_struct, m)
			}
		}

		#999. Purge
		return(get_values(trimws(str_struct), inplace = T))
	}

	#230. Function to differ the approaches for conversion
	#[ASSUMPTION]
	#[1] Given any substring that is not enclosed by the boundaries, we mark it as <S>
	#[2] According to the feature of the nested structure, if <S> exists in the top layer, we do separate concatenation WITHOUT
	#     further evaluation, as the top layer is never enclosed by boundaries
	#[3] According to the feature of the nested structure, every sub-layer <nested struct> is processed in recursion
	#[4] If <nest_struct> is empty, we export an empty string
	#[5] If <nest_struct> has only one <nested struct>, we honor its evaluated result type
	#[6] Otherwise we export a concatenated string
	h_conv <- function(struct){
		len_struct <- length(struct)
		if (len_struct == 0) {
			return('')
		} else if (len_struct == 1) {
			return(h_conj_str(struct[[1]]))
		} else {
			val <- sapply(
				struct
				,function(s){
					if (is.list(s)) return(as.character(h_conj_str(s)))
					else return(s)
				}
			)
			return(paste0(val, collapse = ''))
		}
	}

	#500. Differentiate the result
	return(sapply(
		nest_struct
		,h_conv
		,simplify = F
		,USE.NAMES = T
	))
})
return(myfunc)
})

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		# Toy function <nestedFormatter> is from <Styles>

		#100. Prepare strings
		fill_a <- 'bb'
		fill_bb <- 5
		fill_cc <- 10
		fill_dd <- data.frame(x = 1)
		fill_ee <- data.frame(x = 2)
		teststr <- c('(gg (fill_(fill_a))) aa (ee (ff))', '(fill_bb)', 'fill_a')
		teststr2 <- c('(fill_bb)', '(fill_cc)')
		testjinja <- '{{ fill_{{ fill_a }} }}'
		testjinja2 <- '{{ fill_dd }}'
		testjinja3 <- c('{{ fill_dd }}', '{{ fill_ee }}')

		#200. Evaluation
		#Return a list as the parsed results are of different value types
		eval_str <- strBalancedGroupEval(
			teststr
			,enclosers = c('(' = ')')
			,rx = FALSE
		)
		nestedFormatter(eval_str)
		# list(
		#   $`(gg (fill_(fill_a))) aa (ee (ff))` : chr. ("gg 5 aa ee ff")
		#   $`(fill_bb)` : double (5)
		#   $`fill_a` : chr. ("bb")
		# )

		#[ASSUMPTION]
		#[1] Since there could be different types of resolved objects in the output, we do not simplify the result into a vector
		eval_str2 <- strBalancedGroupEval(
			teststr2
			,enclosers = c('(' = ')')
			,rx = FALSE
		)
		nestedFormatter(eval_str2)
		# list(
		#   $`(fill_bb)` : double (5)
		#   $`(fill_cc)` : double (10)
		# )

		#Recursion
		eval_jinja <- strBalancedGroupEval(
			testjinja
			,enclosers = c('{{' = '}}')
			,rx = FALSE
		)
		nestedFormatter(eval_jinja)
		# list(
		#   $`{{ fill_{{ fill_a }} }}` : double (5)
		# )

		#Return a data.frame as the input vector has the length of 1
		eval_jinja2 <- strBalancedGroupEval(
			testjinja2
			,enclosers = c('{{' = '}}')
			,rx = FALSE
		)
		nestedFormatter(eval_jinja2)
		# list(
		#   $`{{ fill_dd }}` : Object of class: (data.frame)
		# )

		#Return a list of [data.frame]s
		eval_jinja3 <- strBalancedGroupEval(
			testjinja3
			,enclosers = c('{{' = '}}')
			,rx = FALSE
		)
		nestedFormatter(eval_jinja3)
		# list(
		#   $`{{ fill_dd }}` : Object of class: (data.frame)
		#   $`{{ fill_ee }}` : Object of class: (data.frame)
		# )

		#300. Special cases
		#[ASSUMPTION]
		#[1] We export a placeholder
		nestedFormatter(strBalancedGroupEval(''))
		# list(
		#   chr. ("")
		# )

		nestedFormatter(strBalancedGroupEval('()'))
		# list(
		#   $`()` : chr. ("")
		# )

		#[ASSUMPTION]
		#[1] The name is retained as the output value, since it does not denote a variable in current environment
		nestedFormatter(strBalancedGroupEval('a'))
		# list(
		#   $`a` : chr. ("a")
		# )

		#[ASSUMPTION]
		#[1] All the content inside the enclosers is treated as a whole, so it cannot denote a valid variable
		nestedFormatter(strBalancedGroupEval('(a fill_a)'))
		# list(
		#   $`(a fill_a)` : chr. ("a fill_a")
		# )

		nestedFormatter(strBalancedGroupEval('a (fill_a)'))
		# list(
		#   $`a (fill_a)` : chr. ("a bb")
		# )

		nestedFormatter(strBalancedGroupEval('(fill_bb) b'))
		# list(
		#   $`(fill_bb) b` : chr. ("5 b")
		# )

		nestedFormatter(strBalancedGroupEval('(a) fill_bb'))
		# list(
		#   $`(a) fill_bb` : chr. ("a fill_bb")
		# )

		# [CPU] Intel Core i9-14900K 8-Core 5.00GHz
		# [RAM] 128GB DDR5 4800MHz
		#900. Test timing
		#[ASSUMPTION]
		#[1] Due to below features, this function is 300 times slower than its counterpart in <Python> branch
		#    [1] There are 5 more stacks to store necessary information during calculation
		#    [2] Calculation upon stacks is actually <copy> + <modify> + <overwrite>, as there is no immutable design
		#    [3] There are a lot of evaluation steps over the fabricated scripts during the loop, the parsing of these steps
		#         takes up around 1/3 of the time complexity. This is primarily due to the lack of methods to modify the
		#         elements inside a list with many nesting levels in a parametric way.
		#910. Large string for RegExp
		str_large <- strrep(teststr, 10000)
		t_overall <- 0.0
		t1 <- lubridate::now()
		eval_large <- strBalancedGroupEval(str_large)
		t2 <- lubridate::now()
		t_overall <<- t_overall + t2 - t1
		print(t_overall)
		# Time difference of 36.31147 secs
	}
}
