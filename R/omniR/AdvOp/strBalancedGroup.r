#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the substrings surrounded by the provided boundaries, in terms of the concept of Balanced     #
#   | Group in Regular Expression (while NOT using RegExp as it would fail in many cases)                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Signature Expansion]                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Signature of this function is expanded from <strNestedParser>, see its documents for detailed argument list                    #
#   |[2] With the Signature Expansion functionality, one can obtain the correct signature of this function at runtime in below way      #
#   |    [1] Type <args(func)> in the console to see its full argument list expanded from those retained from the ancestors             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use <BeautifulSoup> instead)            #
#   |[2] Resolve the jinja-like expression such as: <f{g{a}}>, when <a> is a variable, <g{a}> is another, and so forth                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The argument <include=FALSE> for this function has different meaning to its source function, as it only excludes the enclosers #
#   |     at the top level of each Balanced Group, for it has to resemble a direct <substring>                                          #
#   |[2] There is no convenient way to only exclude the top level enclosers in a recursive calculation                                  #
#   |[3] For above reasons, the function falls back to the extraction using META information table <nodes>, when <include=FALSE>, which #
#   |     drastically slows down the process as it introduces many extra stack operations                                               #
#   |[4] For other cases, it uses recursive string concatenation out of the nested structure as parsed internally, which is fast        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Should there be any <opener> in the input vector that matches no <closer>, and yet is marked as <unmatched> as it is enclosed  #
#   |     inside another complete <node>, this function recognizes it as a <Balanced Group> when <precise=FALSE>. If you need to avoid  #
#   |     such situation, set <precise=TRUE> to ensure fallback to META extraction but suffer great addition of time consumption.       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...               :   All arguments taken from the source function                                                                 #
#   |precise           :   <logical> Whether to force the function to fall back to extraction from META table <nodes>. This will result #
#   |                       in great addition of time consumption but can recognize <unmatched> groups, so choose it wisely.            #
#   |                      [FALSE               ] <Default> Fast solution with no recognition of <unmatched> groups                     #
#   |                      [TRUE                ]           Recognize <unmatched> groups at cost of great addition of time consumption, #
#   |                                                        but is safe for most of cases. Use this if your data is not clean.         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>            :   List of substrings out of each pair of boundaries as a Balanced Group. Exceptions are raised in the same way #
#   |                       as the dependent function                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments                                            #
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
#   |   |rlang, glue, dplyr                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |strNestedParser                                                                                                            #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, glue, dplyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

strBalancedGroup <- local({
deco <- ExpandSignature$new(strNestedParser, instance = 'eSig')
myfunc <- deco$wrap(function(
	...
	,precise = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	if (!is.logical(precise)){
		stop(glue::glue('[{LfuncName}]<precise>:<{typeof(precise)}> must be provided a logical vector!'))
	}
	precise <- head(precise, 1)

	#050. Local parameters
	dots <- rlang::list2(...)
	args_share <- list()
	eSig$vfyConflict(args_share)
	args_in <- eSig$updParams(args_share, dots)
	include <- eSig$getParam('include', args_in, inc_default = T) |> eval()

	#200. Define helper functions
	#210. Function to join the nested structures into strings respectively with recursion
	h_conj_str <- function(struct){
		#[ASSUMPTION]
		#[1] Input structure always has the form: [<lBound,> <string | nested struct>, <rBound>], where
		#    [a] <lBound> and <rBound> exist or miss at the same time
		#    [b] When both boundaries are missing given <include is True>, the middle part must be a <nested struct>
		#[2] Hence there is no need to match the boundaries any more, we just need to join all strings directly.
		#100. Initialize
		rstOut <- list()
		str_struct <- ''

		#500. Loop over the nested structure
		for (m in struct){
			if (!is.character(m)) {
				#100. Further process the structure of the next layer
				next_struct <- Recall(m)

				#500. Extend the final result
				# rstOut <- c(rstOut, next_struct)
				rstOut <- append(rstOut, next_struct)

				#900. Extend the string for the structure of current layer
				str_struct <- paste0(str_struct, next_struct[[1]])
			} else {
				str_struct <- paste0(str_struct, m)
			}
		}

		#800. Append the string of current structure to the final result
		rstOut <- unlist(c(str_struct, rstOut))

		#999. Purge
		return(rstOut)
	}

	#400. Fall back to the extraction via META information table
	#[ASSUMPTION]
	#[1] There is no convenient way of recursion to only exclude the enclosers at the top level
	if (!include || precise){
		#100. Parse the text with META extracted as well
		#[ASSUMPTION]
		#[1] We do not remove the enclosers in the first place, otherwise it is difficult to add them back when required
		#[2] For any nested structures, we only need to remove the enclosers of the top one given <include=F>, which matches
		#     the direct substring extraction from the text
		txt <- eSig$getParam('txt', args_in, inc_default = T) |> eval()
		args_upd <- list(
			'include' = T
			,'meta_' = T
		)
		args_out <- eSig$updParams(args_upd, args_in)
		nest_struct <- do.call(eSig$src, args_out)

		#900. Collect the meta information for all complete <nodes>
		return(mapply(
			function(struct, rawstr){
				nodes <- struct[['META']][['nodes']]
				if (nrow(nodes) == 0) return(NA_character_)
				if (!include) {
					return(substring(rawstr, nodes[['inner_start']], nodes[['inner_end']]))
				} else {
					return(substring(rawstr, nodes[['span_start']], nodes[['span_end']]))
				}
			}
			,nest_struct
			,txt
			,SIMPLIFY = F
			,USE.NAMES = T
		))
	}

	#600. Parse the nested structure out of the input string
	#[ASSUMPTION]
	#[1] Given any substring that is not enclosed by the boundaries, we mark it as <S>
	#[2] According to the feature of the nested structure, <S> can only exist as L[[1]] or L[[length(L)]] in the top layer
	#[3] According to the feature of the nested structure, neither of the boundaries can exist in the top layer
	#[4] <S> in the top layer is not included in the output result of this function as designed
	nest_struct <- do.call(eSig$src, args_in) |>
		sapply(
			function(s){Filter(is.list, s[['RESULT']])}
			,simplify = F
			,USE.NAMES = T
		)

	#900. Export
	return(sapply(
		nest_struct
		,function(s){
			rst <- unname(unlist(
				sapply(
					s
					,h_conj_str
					,simplify = T
					,USE.NAMES = F
				)
				,recursive = F
			))
			if (is.null(rst)) return(NA_character_)
			else return(rst)
		}
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
		testvec <- c(
			'normal' = '-- (bb [cc (dd)]) aa {ee (ff)} ~~'
			,'plain' = 'ab'
			,'enclosed' = '(a b)'
			,'hijacked' = 'a (b { c) [ (d} e) f ] g'
			,'unmatched' = 'a [b] c ]'
			,'crossing' = '[{aaa]}'
			,'empty' = ''
			,'NA' = NA_character_
		)
		teststr <- '-- (bb (cc (dd))) aa (ee (ff)) ~~'
		testjinja <- '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
		testhtml <- '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg'

		#200. Extraction
		bg_parens <- strBalancedGroup(
			teststr
			,enclosers = c('(' = ')')
			,rx = FALSE
			,include = TRUE
		)
		nestedFormatter(bg_parens)
		# list(
		#   $`-- (bb (cc (dd))) aa (ee (ff)) ~~` : chr. (
		#     "(bb (cc (dd)))"
		#     ,"(cc (dd))"
		#     ,"(dd)"
		#     ,"(ee (ff))"
		#     ,"(ff)"
		#   )
		# )

		#[ASSUMPTION]
		#[1] This is weigh much slower than <include=TRUE> as it falls back to the extraction using META information, which
		#     consumes lots of calculation effort of extra stacks
		bg_jinja <- strBalancedGroup(
			testjinja
			,enclosers = c('{{' = '}}')
			,rx = FALSE
			,include = FALSE
		) |>
			sapply(
				function(s){
					s |>
						sapply(
							trimws
							,simplify = T
							,USE.NAMES = F
						)
				}
				,simplify = F
				,USE.NAMES = T
			)
		nestedFormatter(bg_jinja)
		# list(
		#   $`-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}` : chr. (
		#     "bb {{ cc{{ dd }} }}"
		#     ,"cc{{ dd }}"
		#     ,"dd"
		#     ,"ee {{ ff }}"
		#     ,"ff"
		#   )
		# )

		bg_html <- strBalancedGroup(
			testhtml
			,enclosers = c('<div.*?>' = '</div>')
			,rx = TRUE
			,include = TRUE
		) |>
			sapply(
				function(s){
					s |>
						sapply(
							trimws
							,simplify = T
							,USE.NAMES = F
						)
				}
				,simplify = F
				,USE.NAMES = T
			)
		nestedFormatter(bg_html)
		# list(
		#   $`<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg` : chr. (
		#     "<div a=\"1\">bbb<div id=\"2\"> ccc</div>ddd <div id=\"3\">eee</div>fff</div>"
		#     ,"<div id=\"2\"> ccc</div>"
		#     ,"<div id=\"3\">eee</div>"
		#   )
		# )

		#300. Special cases
		chkstr <- '-- <div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg <div id="4"> hhh </div> ~~'
		chkrst <- strBalancedGroup(chkstr, enclosers = list('<div.*?>' = '</div>'), rx = T)
		nestedFormatter(chkrst)
		# list(
		#   $`-- <div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg <div id="4"> hhh </div> ~~` : chr. (
		#     "<div a=\"1\">bbb<div id=\"2\"> ccc</div>ddd <div id=\"3\">eee</div>fff</div>"
		#     ,"<div id=\"2\"> ccc</div>"
		#     ,"<div id=\"3\">eee</div>"
		#     ,"<div id=\"4\"> hhh </div>"
		#   )
		# )

		#[ASSUMPTION]
		#[1] In case of the extraction from HTML, we need all tags inside the top level enclosers to remain intact
		chkrst2 <- strBalancedGroup(chkstr, enclosers = list('<div.*?>' = '</div>'), rx = T, include = F)
		nestedFormatter(chkrst2)
		# list(
		#   $`-- <div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg <div id="4"> hhh </div> ~~` : chr. (
		#     "bbb<div id=\"2\"> ccc</div>ddd <div id=\"3\">eee</div>fff"
		#     ," ccc"
		#     ,"eee"
		#     ," hhh "
		#   )
		# )

		#[ASSUMPTION]
		#[1] The result is always a list of character vectors along the input vector
		#[2] Hence if one element of the input vector does not contain Balanced Group, <NA_character_> is extracted as placeholder
		nestedFormatter(strBalancedGroup(''))
		# list(
		#   chr. (NA)
		# )

		#[ASSUMPTION]
		#[1] Save as above, while it has a non-empty name
		nestedFormatter(strBalancedGroup('a'))
		# list(
		#   $`a` : chr. (NA)
		# )

		nestedFormatter(strBalancedGroup('(a b)'))
		# list(
		#   $`(a b)` : chr. ("(a b)")
		# )

		nestedFormatter(strBalancedGroup('a (b)'))
		# list(
		#   $`a (b)` : chr. ("(b)")
		# )

		nestedFormatter(strBalancedGroup('(a) b'))
		# list(
		#   $`(a) b` : chr. ("(a)")
		# )

		nestedFormatter(strBalancedGroup('(a ((b) c (d))) e (f (g))'))
		# list(
		#   $`(a ((b) c (d))) e (f (g))` : chr. (
		#     "(a ((b) c (d)))"
		#     ,"((b) c (d))"
		#     ,"(b)"
		#     ,"(d)"
		#     ,"(f (g))"
		#     ,"(g)"
		#   )
		# )

		nestedFormatter(strBalancedGroup('(a ((b) c (d))) e (f (g))', include = F))
		# list(
		#   $`(a ((b) c (d))) e (f (g))` : chr. (
		#     "a ((b) c (d))"
		#     ,"(b) c (d)"
		#     ,"b"
		#     ,"d"
		#     ,"f (g)"
		#     ,"g"
		#   )
		# )

		#600. Test vectorized functionality
		#[ASSUMPTION]
		#[1] In the cases like `hijacked` below, any <opener> that is marked <unmatched> cannot trigger as an error in terms of
		#     the design of the source function <strNestedParser>
		bg_vec <- strBalancedGroup(
			testvec
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,include = TRUE
			,strict_ = FALSE
		)
		nestedFormatter(bg_vec)
		# list(
		#   $`normal` : chr. (
		#     "(bb [cc (dd)])"
		#     ,"[cc (dd)]"
		#     ,"(dd)"
		#     ,"{ee (ff)}"
		#     ,"(ff)"
		#   )
		#   $`plain` : chr. (NA)
		#   $`enclosed` : chr. ("(a b)")
		#   $`hijacked` : chr. (
		#     "(b { c)"
		#     ,"{ c"
		#     ,"[ (d} e) f ]"
		#     ,"(d} e)"
		#   )
		#   $`unmatched` : chr. ("[b]")
		#   $`crossing` : chr. ("[{aaa]","{aaa")
		#   $`empty` : chr. (NA)
		#   $`NA` : chr. (NA)
		# )

		#615. Set <precise=TRUE> to recognize and eliminate <unmatched> groups
		#[ASSUMPTION]
		#[1] As you can see, the <unmatched> groups in `hijacked` and `crossing` are now eliminated
		#[2] The same elimination is also led by <include=FALSE>, which makes the logic consistent. Note that in such case the
		#     argument <precise> is omitted as the function already falls back to META extraction.
		nestedFormatter(strBalancedGroup(
			testvec
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,include = TRUE
			,precise = TRUE
		))
		# list(
		#   $`normal` : chr. (
		#     "(bb [cc (dd)])"
		#     ,"[cc (dd)]"
		#     ,"(dd)"
		#     ,"{ee (ff)}"
		#     ,"(ff)"
		#   )
		#   $`plain` : chr. (NA)
		#   $`enclosed` : chr. ("(a b)")
		#   $`hijacked` : chr. (
		#     "(b { c)"
		#     ,"[ (d} e) f ]"
		#     ,"(d} e)"
		#   )
		#   $`unmatched` : chr. ("[b]")
		#   $`crossing` : chr. ("[{aaa]")
		#   $`empty` : chr. (NA)
		#   $`NA` : chr. (NA)
		# )

		#356. Set <include=FALSE>
		nestedFormatter(strBalancedGroup(
			testvec
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,include = FALSE
		))
		# list(
		#   $`normal` : chr. (
		#     "bb [cc (dd)]"
		#     ,"cc (dd)"
		#     ,"dd"
		#     ,"ee (ff)"
		#     ,"ff"
		#   )
		#   $`plain` : chr. (NA)
		#   $`enclosed` : chr. ("a b")
		#   $`hijacked` : chr. (
		#     "b { c"
		#     ," (d} e) f "
		#     ,"d} e"
		#   )
		#   $`unmatched` : chr. ("b")
		#   $`crossing` : chr. ("{aaa")
		#   $`empty` : chr. (NA)
		#   $`NA` : chr. (NA)
		# )

		# [CPU] Intel Core i9-14900K 8-Core 5.00GHz
		# [RAM] 128GB DDR5 4800MHz
		#900. Test timing
		#910. Large string for RegExp
		str_large <- strrep(testhtml, 10000)
		t_overall <- 0.0
		t1 <- lubridate::now()
		bg_large <- strBalancedGroup(str_large, enclosers = c('<div.*?>' = '</div>'), rx = T)
		t2 <- lubridate::now()
		t_overall <<- t_overall + t2 - t1
		print(t_overall)
		# Time difference of 12.96306 secs
	}
}
