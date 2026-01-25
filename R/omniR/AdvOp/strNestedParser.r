#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the nested structures surrounded by the provided boundaries, in terms of the concept of         #
#   | Balanced Group in Regular Expression (while NOT using that in RegExp as it would fail in many cases)                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/1099178/matching-nested-structures-with-regular-expressions-in-python                      #
#   |[2] Differences of pipe operators: https://zhuanlan.zhihu.com/p/1942366213322807149                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use [BeautifulSoup] instead)            #
#   |[2] Resolve the jinja-like expression such as: <f{g{a}}>, when <a> is a variable, <g{a}> is another, and so forth                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt               :   <chr     > Character vector from which to extract the substrings                                             #
#   |enclosers         :   <chr     > Mapping of enclosers with <names> as the left bound or opener, <value> as the right bound or      #
#   |                                  closer                                                                                           #
#   |                      [(see def.)          ] <Default> Use the default values as defined                                           #
#   |rx                :   <logical > Whether to treat the items in <enclosers> as Regular Expression                                   #
#   |                      [FALSE               ] <Default> Treat them as raw character strings                                         #
#   |                      [TRUE                ]           Treat them as regular expressions                                           #
#   |include           :   <logical > Whether to include the enclosers in the output structure. When there are multiple items inside    #
#   |                       the argument <enclosers>, this argument is ignored and forced to be TRUE                                    #
#   |                      [TRUE                ] <Default> Include the bounds as output                                                #
#   |                      [FALSE               ]           Exclude the bounds as output                                                #
#   |                       [IMPORTANT] Setting it as <FALSE> prevents the function to collect <META> information of <closers> and thus #
#   |                                    lead to unexpected result when requested. So it is suggested to set <include=TRUE> when you    #
#   |                                    also need <meta_=TRUE>, although it is not verified.                                           #
#   |strict_           :   <logical > Whether to avoid raising exception given the opener is missing for any among the closers, given   #
#   |                       the argument <include> is TRUE                                                                              #
#   |                      [FALSE               ] <Default> Avoid exception if any closer misses its opener and treat it as normal text #
#   |                      [TRUE                ]           Raise exception if any closer misses its opener                             #
#   |meta_             :   <logical > Whether to export the meta information during the matching and extraction                         #
#   |                      [FALSE               ] <Default> Do not collect meta information and keep high efficiency                    #
#   |                      [TRUE                ]           Collect meta information for debug or visualization purposes                #
#   |...               :   Options for <string::stri_opts_*> to compile a valid Regex parser                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>            :   List of lists along the input vector <txt>, each one of them is comprised of below separate lists            #
#   |                      [RESULT ] <list> of nested structures out of each pair of enclosers as a Balanced Group                      #
#   |                                [1] If the bounds do not exist in pairs, exception is raised. Special cases are as below           #
#   |                                    [1] When <include=TRUE>, <strict_=FALSE> and there are missing openers, exception is suppressed#
#   |                                [2] Standalone substrings, i.e. those not enclosed, are also included in the result                #
#   |                      [META   ] <list> of various <data.frame> holding the meta information during the extraction. Details are     #
#   |                                 as listed in below section <META details>                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |950.   META details.                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   nodes                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |A <node> is defined at an <opener> determined by <enclosers>, and starts with 0 as <root node>, meaning that the entire    #
#   |   |   | input string is a <node> at the ID of 0, also at the <depth> of 0. However,this table does not store the <root node>,     #
#   |   |   | hence the <node>s in it can only start with 1 and larger.                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |IMPORTANT                                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[1] A <node> with <unmatched==TRUE> status is stored in another table <nodes_unclosed>, as its <opener> is wrapped inside  #
#   |   |   |     another complete <node>, and lost its nature                                                                          #
#   |   |   |[2] Isolated <closer> does not form a <node> and is taken as free text                                                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |node_id         |int         |No       |ID of current <node>                                                               #
#   |   |   |parent_id       |int         |No       |ID of the parent <node> to current one                                             #
#   |   |   |depth           |int         |No       |How far current <node> is related to the <root node>, defined as being wrapped by  #
#   |   |   |                |            |         | how many <unclosed opener>s, except those identified as <unmatched> during parsing#
#   |   |   |pair_id         |int         |No       |ID of the <enclosers> as requested in the dedicated sequence at input. <N> pairs of#
#   |   |   |                |            |         | <enclosers> corresponds to the same number of <ID>s                               #
#   |   |   |opener_def      |chr         |No       |Definition of the <opener> as requested, may be the representation of RegExp       #
#   |   |   |closer_def      |chr         |No       |Definition of the <closer> as requested, may be the representation of RegExp       #
#   |   |   |opener_match    |chr         |No       |Identified <opener> text during parsing                                            #
#   |   |   |                |            |         | [1] same as <opener> when <rx=FALSE>                                              #
#   |   |   |                |            |         | [2] substring matching the <opener> when <rx=TRUE>                                #
#   |   |   |closer_match    |chr         |No       |Identified <closer> text during parsing                                            #
#   |   |   |                |            |         | [1] same as <closer> when <rx=FALSE>                                              #
#   |   |   |                |            |         | [2] substring matching the <closer> when <rx=TRUE>                                #
#   |   |   |opener_start    |int         |No       |start position of the identified <opener_match>                                    #
#   |   |   |opener_end      |int         |No       |end position of the identified <opener_match>, useful when <rx=TRUE>               #
#   |   |   |closer_start    |int         |No       |start position of the identified <closer_match>                                    #
#   |   |   |closer_end      |int         |No       |end position of the identified <closer_match>, useful when <rx=TRUE>               #
#   |   |   |span_start      |int         |No       |start position of the <span> covering the identified <opener_start>                #
#   |   |   |                |            |         | [NOTE] A <span> is only for a complete <node> with proper <closer>, hence it is   #
#   |   |   |                |            |         |         not defined for the <root node> or <nodes_unclosed>                       #
#   |   |   |span_end        |int         |No       |end position of the <span> covering the identified <closer_end>                    #
#   |   |   |inner_start     |int         |No       |start position of the wrapped content, excluding the identified <opener_match>     #
#   |   |   |                |            |         | [NOTE] <inner> is only for a complete <node> with proper <closer>, hence it is not#
#   |   |   |                |            |         |         defined for the <root node> or <nodes_unclosed>                           #
#   |   |   |inner_end       |int         |No       |end position of the wrapped content, excluding the identified <closer_match>       #
#   |   |   |closed          |logical     |No       |Whether current <node> is complete with proper <closer> during parsing, literally  #
#   |   |   |                |            |         | all <TRUE> in this table                                                          #
#   |   |   |unmatched       |logical     |No       |Whether current <opener> cannot match a proper <closer> and is wrapped inside      #
#   |   |   |                |            |         | another complete <node>, literally all <FALSE> in this table                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |150.   nodes_unclosed                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |All <opener>s that cannot match proper <closer>s and are wrapped inside other complete <node>s, will be deemed             #
#   |   |   | <unmatched>, since they are defined as a <node> at the meantime, they are stored in this table                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |IMPORTANT                                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[1] If <strict_=TRUE>, function raises exception when any <nodes_unclosed> is identified, hence there is no <META> for use #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |node_id         |int         |No       |ID of current <node>                                                               #
#   |   |   |parent_id       |int         |No       |ID of the parent <node> to current one                                             #
#   |   |   |depth           |int         |No       |How far current <node> is related to the <root node>, defined as being wrapped by  #
#   |   |   |                |            |         | how many <unclosed opener>s, except those identified as <unmatched> during parsing#
#   |   |   |pair_id         |int         |No       |ID of the <enclosers> as requested in the dedicated sequence at input. <N> pairs of#
#   |   |   |                |            |         | <enclosers> corresponds to the same number of <ID>s                               #
#   |   |   |opener_def      |chr         |No       |Definition of the <opener> as requested, may be the representation of RegExp       #
#   |   |   |closer_def      |chr         |No       |Definition of the <closer> as requested, may be the representation of RegExp       #
#   |   |   |opener_match    |chr         |No       |Identified <opener> text during parsing                                            #
#   |   |   |                |            |         | [1] same as <opener> when <rx=FALSE>                                              #
#   |   |   |                |            |         | [2] substring matching the <opener> when <rx=TRUE>                                #
#   |   |   |opener_start    |int         |No       |start position of the identified <opener_match>                                    #
#   |   |   |opener_end      |int         |No       |end position of the identified <opener_match>, useful when <rx=TRUE>               #
#   |   |   |closed          |logical     |No       |Whether current <node> is complete with proper <closer> during parsing, literally  #
#   |   |   |                |            |         | all <FALSE> in this table                                                         #
#   |   |   |unmatched       |logical     |No       |Whether current <opener> cannot match a proper <closer> and is wrapped inside      #
#   |   |   |                |            |         | another complete <node>, literally all <TRUE> in this table                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   segments                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |All substrings that are split by the <enclosers> are deemed as <segments>, so that it is useful to identify each piece of  #
#   |   |   | the raw string for investigation, visualization and other text analysis                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DEFINITION                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[1] All substrings excluding the <enclosers> are deemed as <segments>, taking their nearby whitespaces along with them,    #
#   |   |   |     since it is the way <re.split> is in use                                                                              #
#   |   |   |[2] All <node>s are deemed as <segments>, they may overlap the substrings defined at above step but it is OK, as they are  #
#   |   |   |     of different purposes                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |seg_id          |int         |No       |ID of current <segment>, starting from the primitive indexing number of <Python>   #
#   |   |   |parent_id       |int         |No       |ID of the parent <node>. Parent <node> for a <segment> is identified in below way: #
#   |   |   |                |            |         | [1] Looking behind current <segment> for the nearest <node> that is not <closed>  #
#   |   |   |                |            |         |      and not marked <unmatched> as well. Then this <segment> is tagged to it      #
#   |   |   |                |            |         | [2] If no such <node> is found, the <segment> is tagged to <root node>            #
#   |   |   |depth           |int         |No       |How far current <segment> is related to the <root node>, defined as wrapped by how #
#   |   |   |                |            |         | many <unclosed opener>s, except those identified as <unmatched> during parsing    #
#   |   |   |type            |chr         |No       |Type of the <segment>                                                              #
#   |   |   |                |            |         | [text] substring at current position                                              #
#   |   |   |                |            |         | [node] collection as a <node> holding many substrings                             #
#   |   |   |start           |int         |No       |start position. It covers the <enclosers> for a <segment> denoted by a <node>      #
#   |   |   |end             |int         |No       |end position. It covers the <enclosers> for a <segment> denoted by a <node>        #
#   |   |   |text            |chr         |No       |The substring denoted by <start> and <end>                                         #
#   |   |   |node_id         |int         |Yes      |ID of the <node> denoting current <segment>, can be <None> if it is not a <node>   #
#   |   |   |pair_id         |int         |Yes      |ID of the <enclosers> as requested in the dedicated sequence at input for the      #
#   |   |   |                |            |         | <node>. It can be <None> if current <segment> is not a <node>                     #
#   |   |   |unmatched       |logical     |Yes      |Whether current <node> is without a <closer> but wrapped inside another complete   #
#   |   |   |                |            |         | <node>. There could be several values in this table                               #
#   |   |   |                |            |         | [TRUE ] can only exist when <type> is <'node'>, while it is not complete          #
#   |   |   |                |            |         | [FALSE] can only exist when <type> is <'node'>, while it is complete              #
#   |   |   |                |            |         | [NA   ] for all the <segment>s with <type> as <'text'>                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |300.   edges                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |This table stores the relationship edges between the parent and child <node>s, excluding those marked <unmatched> as they  #
#   |   |   | are not complete <node>s                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |from_node       |int         |No       |From which <node> to expand the relationship tree                                  #
#   |   |   |to_node         |int         |No       |To which <node> to expand the relationship tree                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260114        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |glue, rlang, dplyr, tidyselect, tidyr                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isVEC                                                                                                                      #
#   |   |   |locSubstr                                                                                                                  #
#   |   |   |re.escape                                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	glue, rlang, dplyr, tidyselect, tidyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

strNestedParser <- function(
	txt
	,enclosers = c('(' = ')')
	,rx = FALSE
	,include = TRUE
	,strict_ = FALSE
	,meta_ = FALSE
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	if (!is.character(txt)){
		stop(glue::glue('[{LfuncName}]<txt>:<{typeof(txt)}> must be provided a character vector!'))
	}
	if (!isVEC(rx)){
		stop(glue::glue('[{LfuncName}]<rx>:<{typeof(rx)}> must be provided a logical vector!'))
	}
	if (!is.logical(rx)){
		stop(glue::glue('[{LfuncName}]<rx>:<{typeof(rx)}> must be provided a logical vector!'))
	}
	if (!isVEC(include)){
		stop(glue::glue('[{LfuncName}]<include>:<{typeof(include)}> must be provided a logical vector!'))
	}
	if (!is.logical(include)){
		stop(glue::glue('[{LfuncName}]<include>:<{typeof(include)}> must be provided a logical vector!'))
	}
	if (length(enclosers) > 1){
		if (!include){
			message(glue::glue('[{LfuncName}]Multiple enclosers are requested, <include> is set to TRUE anyway.'))
		}
		include <- T
	}
	if (!isVEC(strict_)){
		stop(glue::glue('[{LfuncName}]<strict_>:<{typeof(strict_)}> must be provided a logical vector!'))
	}
	if (!is.logical(strict_)){
		stop(glue::glue('[{LfuncName}]<strict_>:<{typeof(strict_)}> must be provided a logical vector!'))
	}
	if (!isVEC(meta_)){
		stop(glue::glue('[{LfuncName}]<meta_>:<{typeof(meta_)}> must be provided a logical vector!'))
	}
	if (!is.logical(meta_)){
		stop(glue::glue('[{LfuncName}]<meta_>:<{typeof(meta_)}> must be provided a logical vector!'))
	}

	#050. Local parameters
	kw <- rlang::list2(...)
	enclosers_id <- seq_len(length(enclosers) * 2)
	names(enclosers_id) <- c(names(enclosers), unname(enclosers))
	ptn_lBound <- seq_along(enclosers)
	names(ptn_lBound) <- names(enclosers)
	ptn_rBound <- ptn_lBound
	names(ptn_rBound) <- unname(enclosers)
	enclosers_pair <- ptn_lBound
	names(enclosers_pair) <- match(names(ptn_rBound), names(enclosers_id))
	enclosers_id_to_type <- c(rlang::rep_along(enclosers, 'opener'), rlang::rep_along(enclosers, 'closer'))
	names(enclosers_id_to_type) <- unname(enclosers_id)
	enclosers_id_to_pair <- c(seq_along(enclosers), seq_along(enclosers))
	names(enclosers_id_to_pair) <- unname(enclosers_id)
	enclosers_ord <- enclosers_id[rev(order(nchar(names(enclosers_id))))]

	#100. Setup Regex options
	#110. Retrieve the keyword arguments
	params_i_coll <- formalArgs(stringi::stri_opts_collator)
	params_i_rx <- formalArgs(stringi::stri_opts_regex)
	params_i_br <- formalArgs(stringi::stri_opts_brkiter)

	#130. Obtain all defaults of keyword arguments of the function
	kw_raw <- c(
		params_i_coll
		,params_i_rx
		,params_i_br
	) |>
		{\(x) x[!x %in% c('...')]}()

	#150. Create the final keyword arguments for calling the function
	kw_final <- kw[names(kw) %in% kw_raw]

	#200. Define helper functions
	#201. Function to determine the type of the <encloser>
	h_encloser_mapper <- function(ptn_id, mapper_, type_func){
		sapply(
			ptn_id
			,function(x){
				if (is.na(x)) return(type_func(NA))
				if (!(x %in% as.integer(names(mapper_)))) {
					return(type_func(NA))
				}
				return(type_func(mapper_[[x]]))
			}
			,USE.NAMES = F
		)
	}

	#210. Function to determine the ID of the enclosers in the candidates
	#[ASSUMPTION]
	#[1] We could match the pattern against the store of all enclosers and find the index of the match, but it consumes more
	#     system effort, hence we loop the store, return the matching ID and quit the loop immediately
	#[2] Argument <e> stands for <element>; argument <p> stands for <pattern>
	h_encloser_id <- function(e, store){
		if (rx) {
			ptn <- paste0('((?:',names(store),'))')
		} else {
			ptn <- paste0('((?:',re.escape(names(store)),'))')
		}
		sapply(
			e
			,function(e_){
				for (i in seq_along(ptn)){
					matched <- do.call(stringi::stri_detect_regex, list(e_, ptn[[i]]) |> append(kw_final))
					if (!is.na(matched)) if (matched) {
						return(store[[i]])
					}
				}
				return(NA_integer_)
			}
			,USE.NAMES = F
			,simplify = T
		)
	}

	#500. Define the main function to process one item at each iteration
	h_proc_one <- function(
		str_this
		,idx_this
		,rx_this
		,include_this
		,strict_this
		,meta_this
	){
		#012. Parameter buffer
		if (rx_this) {
			ptn_bound <- paste0('((?:',paste0(names(enclosers_ord), collapse = '|'),'))')
		} else {
			ptn_bound <- paste0('((?:',paste0(re.escape(names(enclosers_ord)), collapse = '|'),'))')
		}

		#050. Local parameters
		#[ASSUMPTION]
		#[1] All the <ID>s, as well as those in the <names> of the vectors, represent <node_id>, which should be integers
		stack_id <- integer(0)
		stack_pair <- integer(0)
		stack_parent <- integer(0)
		stack_closed <- logical(0)
		stack_unmatch <- logical(0)
		stack_open <- list()
		stack_nodes <- list()
		stack_segs <- list()
		rstOut <- list()
		enc_id <- 0
		node_id <- 0
		seg_id <- 0

		#100. Prepare universal output structure for <META>
		if (meta_this){
			#100. Prepare field type mappers
			field_types <- list(
				#100. For <nodes>
				'node_id' = as.integer
				,'parent_id' = as.integer
				,'depth' = as.integer
				,'pair_id' = as.integer
				,'opener_start' = as.integer
				,'opener_end' = as.integer
				,'closer_start' = as.integer
				,'closer_end' = as.integer
				,'span_start' = as.integer
				,'span_end' = as.integer
				,'inner_start' = as.integer
				,'inner_end' = as.integer
				,'closed' = as.logical
				,'unmatched' = as.logical
				,'opener_def' = as.character
				,'closer_def' = as.character
				,'opener_match' = as.character
				,'closer_match' = as.character

				#200. For <segments>
				,'seg_id' = as.integer
				,'type' = as.character
				,'start' = as.integer
				,'end' = as.integer
				,'text' = as.character

				#300. For <edges>
				,'from_node' = as.integer
				,'to_node' = as.integer
			)

			#300. Define the output columns
			col_nodes <- c(
				'node_id'
				,'parent_id'
				,'depth'
				,'pair_id'
				,'opener_def'
				,'closer_def'
				,'opener_match'
				,'closer_match'
				,'opener_start'
				,'opener_end'
				,'closer_start'
				,'closer_end'
				,'span_start'
				,'span_end'
				,'inner_start'
				,'inner_end'
				,'closed'
				,'unmatched'
			)
			col_nodes_unclosed <- c(
				'node_id'
				,'parent_id'
				,'depth'
				,'pair_id'
				,'opener_def'
				,'closer_def'
				,'opener_match'
				,'opener_start'
				,'opener_end'
				,'closed'
				,'unmatched'
			)
			col_segs <- c(
				'seg_id'
				,'parent_id'
				,'depth'
				,'type'
				,'start'
				,'end'
				,'text'
				,'node_id'
				,'pair_id'
				,'unmatched'
			)
			col_edges <- c(
				'from_node'
				,'to_node'
			)

			#500. Prepare empty <META> tables
			meta_trans <- list(
				'nodes' = col_nodes
				,'nodes_unclosed' = col_nodes_unclosed
				,'segments' = col_segs
				,'edges' = col_edges
			)

			meta <- meta_trans |>
				sapply(
					function(t){
						trans <- field_types[names(field_types) %in% t]
						rlang::rep_named(t, NA) |>
							as.list() |>
							as.data.frame() |>
							dplyr::filter_all(Negate(is.na)) |>
							dplyr::mutate(
								dplyr::across(dplyr::all_of(names(trans)), ~trans[[dplyr::cur_column()]](.))
							)
					}
					,simplify = FALSE
					,USE.NAMES = TRUE
				)
		}

		#200. Define helper functions that require above local environment
		#220. Function to modify the certain item within a nested list
		h_recursive_modify <- function(name_, val_, ...) {
			#100. Retrieve the path
			#[ASSUMPTION]
			#[1] It is designed to modify the item in terms of <index slicing> or <named slicing>, hence integers are allowed
			#[2] Therefor, we do not <unlist()> it, as this will convert all items into the same type which is what we try to avoid
			dots <- rlang::list2(...)

			#300. Directly modify the element
			if (length(dots) == 0) {
				stack_open[[name_]] <<- val_
			}

			#500. Create the expression of chained subset assignment
			#[ASSUMPTION]
			#[2] Argument <p> stands for <parameter>
			slicers <- lapply(
				dots
				,function(p){
					if (is.numeric(p)) {
						paste0('[[', as.integer(p), ']]')
					} else {
						paste0('[["', p, '"]]')
					}
				}
			)
			if (is.numeric(name_)) {
				slicer_name <- paste0('[[', as.integer(name_), ']]')
			} else {
				slicer_name <- paste0('[["', name_, '"]]')
			}

			expr <- paste0(
				'stack_open'
				, paste0(slicers, collapse = '')
				, slicer_name, ' <<- val_'
			)

			##800. Evaluate the process
			eval(parse(text = expr), envir = environment())
			# 740000 recs, 60001 iters, Time difference of 9.065209 secs
		}

		#230. Function to get the <length> of the sub-list in recursion
		h_recursive_length <- function(...) {
			#100. Retrieve the path
			#[ASSUMPTION]
			#[1] It is designed to calculate in terms of <index slicing> or <named slicing>, hence integers are allowed
			#[2] Therefor, we do not <unlist()> it, as this will convert all items into the same type which is what we try to avoid
			#[3] For the same reason, we do not replace it with a single argument as there will be more processes to handle it
			#    [1] We have to convert its value into a list by taking care of <vector> and <list> at the same time
			#    [2] We also have to handle the different value types, such as <integer>, numeric-like <character>, or else
			dots <- rlang::list2(...)

			#300. Directly modify the element
			if (length(dots) == 0) {
				return(length(stack_open))
			}

			#500. Create the expression of chained subset assignment
			#[ASSUMPTION]
			#[2] Argument <p> stands for <parameter>
			slicers <- lapply(
				dots
				,function(p){
					if (is.numeric(p)) {
						paste0('[[', as.integer(p), ']]')
					} else {
						paste0('[["', p, '"]]')
					}
				}
			)

			expr <- paste0(
				'length(stack_open'
				, paste0(slicers, collapse = '')
				,')'
			)

			##800. Evaluate the process
			rst <- eval(parse(text = expr), envir = environment())

			return(rst)
		}

		#240. Function to find all ancestor <node>s in recursion
		#[ASSUMPTION]
		#[1] <h_recursive_modify> uses <character> to match the <name> of the substructures
		h_parent_path <- function(node_this, parent_tree){
			rstOut <- character(0)
			if (length(node_this) == 0) return(rstOut)
			while (node_this > 0) {
				rstOut <- c(rstOut, as.character(node_this))
				node_this <- parent_tree[as.character(node_this)]
			}
			return(rstOut)
		}

		#280. Function to append a new element to the stack
		h_push <- function(name_, value_){
			#[1] Arguments
			#    [name_         ] The name of the element to be appended, literally for a <list>
			#    [value_        ] The element to be appended, literally a <character> or <list> in this function

			#300. Determine <ID> of current <node> that is open at this step
			current_open <- tail(stack_id[!stack_closed & !stack_unmatch], 1)

			#400. Calculate the path along the parenting tree
			#[ASSUMPTION]
			#[1] Below value is empty if there is no <current_open>
			#[2] Therefore, the <parent_id> of <value_> is just the root node
			parent_path <- h_parent_path(current_open, stack_parent) |> rev()
			depth <- length(parent_path)
			if (depth == 0) {
				parent_id <- 0
			} else {
				parent_id <- parent_path |> tail(1) |> as.integer()
			}

			#500. Determine the position of current item to be appended
			#[ASSUMPTION]
			#[1] Below value is <length(stack_open)> if there is no <current_open>
			this_pos <- do.call(h_recursive_length, parent_path |> as.list()) + 1
			if (!missing(name_)){
				this_pos <- name_
				depth <- depth + 1
			}

			#500. Append the content
			do.call(
				h_recursive_modify
				,c(
					list(
						name_ = this_pos
						,val_ = value_
					)
					,parent_path |> as.list()
				)
			)

			return(list(
				'parent_id' = parent_id
				,'depth' = depth
			))
		}

		#290. Function to process at rows in a <data.frame>
		h_row_proc <- function(
			b_start
			,b_end
			,start
			,end
			,x_ptn_id
			,x
			,x_before
			,row_id
			,pair_id
		){
			#100. Append the free text into the stack
			#[ASSUMPTION]
			#[1] We append the content to the last <enc_id> which is not closed and not marked <unmatched> at the same time
			#[2] If there is no such <enc_id>, we append the content directly to the end of the <stack> of result
			if (nchar(x_before) > 0) {
				if (length(stack_open) == 0) {
					rstOut[[length(rstOut) + 1]] <<- x_before
					val_push <- list(
						'parent_id' = 0
						,'depth' = 0
					)
				} else {
					val_push <- h_push(
						value_ = x_before
					)
				}
				# 740000 recs, 60001 iters, Time difference of 17.35144 secs

				#900. Collect meta information
				if (meta_this){
					seg_id <<- seg_id + 1
					stack_segs[[seg_id]] <<- list(
						'seg_id' = seg_id
						,'parent_id' = val_push[['parent_id']]
						,'depth' = val_push[['depth']]
						,'start' = b_start
						,'end' = b_end
						,'type' = 'text'
						,'text' = x_before
					)
				}
			}

			#400. Process if x is opener
			#[ASSUMPTION]
			#[1] Unlike the counterpart in <Python>, <enclosers_pair> is a named vector with the names as the <closer> and the values
			#     as the <opener>. Hence the comparison is inverse.
			if (x_ptn_id %in% enclosers_pair) {
				#100. Resister meta information
				node_id <<- node_id + 1
				if (meta_this){
					seg_id <<- seg_id + 1
				}

				#800. Nest a new list inside the current stack
				if (include_this) {
					val_this <- list(x)
				} else {
					val_this <- list()
				}
				val_push <- h_push(
					name_ = as.character(node_id)
					,value_ = val_this
				)
				# 740000 recs, 60001 iters, Time difference of 8.011248 secs

				#500. Append to all <ID> related stacks
				this_parent <- val_push[['parent_id']]
				names(this_parent) <- node_id
				len_uni_upd <- length(stack_id) + 1
				stack_id[[len_uni_upd]] <<- node_id
				stack_pair[[len_uni_upd]] <<- pair_id
				stack_parent <<- c(stack_parent, this_parent)
				stack_closed[[len_uni_upd]] <<- FALSE
				stack_unmatch[[len_uni_upd]] <<- FALSE
				# 740000 recs, 60001 iters, Time difference of 4.506796 secs

				#900. Collect meta information
				if (meta_this){
					#100. Update current node
					stack_nodes[[node_id]] <<- list(
						'node_id' = node_id
						,'parent_id' = val_push[['parent_id']]
						,'depth' = val_push[['depth']]
						,'pair_id' = pair_id
						,'opener_def' = names(enclosers_id)[[x_ptn_id]]
						,'closer_def' = names(ptn_rBound)[[x_ptn_id]]
						,'opener_match' = x
						,'opener_start' = start
						,'opener_end' = end
					)

					#200. Register current segment
					#[ASSUMPTION]
					#[1] At this point, we only know the <start> of it, hence will update its <end> afterwards
					stack_segs[[seg_id]] <<- list(
						'seg_id' = seg_id
						,'parent_id' = val_push[['parent_id']]
						,'depth' = val_push[['depth']]
						,'start' = start
						,'type' = 'node'
						,'node_id' = node_id
						,'pair_id' = pair_id
						,'text' = NA
						,'unmatched' = FALSE
					)
				}
			} else if (x_ptn_id %in% enclosers_id) {
				# Process if x is closer
				#100. Register meta information
				at_pos <- ''
				if (meta_this){
					#900. Logging
					at_pos <- paste0(' at position: <',start,'>')
				}

				#200. Look backwards to find the nearest substructure with the corresponding opener
				target_pos <- seq_along(stack_id)[!stack_closed & !stack_unmatch & (stack_pair == pair_id)] |> tail(1)
				found <- length(target_pos) > 0
				# 740000 recs, 60001 iters, Time difference of 3.020321 secs

				#300. Update all the <node> related stacks
				if (found) {
					target_node <- stack_id[[target_pos]]
					stack_closed[target_pos] <<- TRUE
					len_nodes <- length(stack_id)
					for (i in len_nodes:target_pos){
						#300. Mark that <node> as unmatched, as it is wrapped by a complete pair of enclosers
						if (i > target_pos) if (!stack_closed[[i]]){
							stack_unmatch[[i]] <<- TRUE
						}
					}
				}
				# 740000 recs, 60001 iters, Time difference of 0.3832436 secs

				#400. Shrink the Auxiliary Space when it is not requested to include the closers
				if (!include_this){
					#100. Raise exception if there is no matching <opener> as located
					if (!found){
						stop(glue::glue('[{LfuncName}][item: {idx_this}]Group opener is missing for closer: `{x}`{at_pos}'))
					}

					#990. Recycle the auxiliary space occupied by the temporary stacks
					if (target_node == head(stack_id, 1)){
						rstOut <<- c(rstOut, stack_open)
						stack_open <<- list()
						stack_id <<- integer(0)
						stack_pair <<- integer(0)
						stack_parent <<- integer(0)
						stack_closed <<- logical(0)
						stack_unmatch <<- logical(0)
					}

					#900. Go to the next token as there is no other need
					return(-1)
				}

				#500. Complete this substructure with current closer
				if (found) {
					#100. Calculate the path along the parenting tree
					#[ASSUMPTION]
					#[1] Below value is empty if <target_node> is the direct child to the root node
					parent_path <- h_parent_path(target_node, stack_parent) |> rev()

					#200. Determine the position of current item to be appended
					this_pos <- do.call(h_recursive_length, parent_path |> as.list()) + 1

					#300. Update current <node>
					do.call(
						h_recursive_modify
						,c(
							list(
								name_ = this_pos
								,val_ = x
							)
							,parent_path
						)
					)
					# 740000 recs, 60001 iters, Time difference of 7.878726 secs

					#900. Collect meta information
					if (meta_this){
						#100. Update all the <segment> related stacks
						for (i in len_nodes:target_pos){
							#100. Locate the segment to be updated
							#[ASSUMPTION]
							#[1] The last segment (i.e. <target_node>) that is located inside this loop will also be updated
							#     outside the loop
							#[2] For each <node_id> along the stack <stack_id>, there should have been a correspondent one
							#     inside the stack of <stack_segs>; hence the slicing using <[[1]]> is safe and necessary
							#[3] <seg_id> is just the same as the number of items inside <stack_segs> as designed, hence it
							#     is easier for slicing at later steps
							seg_this <- Filter(
								function(ele_){
									if ('node_id' %in% names(ele_)) if (ele_[['node_id']] == stack_id[[i]]){
										return(T)
									}
									return(F)
								}
								,stack_segs
							)[[1]][['seg_id']]

							#400. Update the dedicated segment
							#[ASSUMPTION]
							#[1] We do not correct the <parent_id> for any of the <segments> until the pairing <node_id>.
							#    [1] For extensive usage of <META>, we could extract/highlight the <unmatched nodes> from
							#         inside the raw string, together with all text <segments> tagged to them. So if we correct
							#         these <segments>, it is difficult to identify them again. See [Full Test Program] #500 for
							#         the related demonstration.
							#[2] In case of many <unmatched nodes> are in between, we set the <end> of them to the same
							if (stack_unmatch[[i]]){
								stack_segs[[seg_this]][['end']] <<- start - 1
								stack_segs[[seg_this]][['unmatched']] <<- TRUE
							}
						}

						#500. Only complete the <node> when it is not marked as <unmatched>
						if (!stack_unmatch[[target_pos]]){
							#100. Update current node
							stack_nodes[[target_node]] <<- stack_nodes[[target_node]] |>
								c(list(
									'closer_start' = start
									,'closer_end' = end
									,'closer_match' = x
									,'span_start' = stack_nodes[[target_node]][['opener_start']]
									,'span_end' = end
									,'inner_start' = stack_nodes[[target_node]][['opener_end']] + 1
									,'inner_end' = start - 1
								))

							#200. Update the dedicated segment
							stack_segs[[seg_this]][['end']] <<- end
						}
					}

					#990. Recycle the auxiliary space occupied by the temporary stacks
					if (target_node == head(stack_id, 1)){
						rstOut <<- c(rstOut, stack_open)
						stack_open <<- list()
						stack_id <<- integer(0)
						stack_pair <<- integer(0)
						stack_parent <<- integer(0)
						stack_closed <<- logical(0)
						stack_unmatch <<- logical(0)
					}
				} else if (strict_this) {
					stop(glue::glue('[{LfuncName}][item: {idx_this}]Group opener is missing for closer: `{x}`{at_pos}'))
				} else {
					#100. Make it a normal text segment to the nearest open <node> that is not marked as <unmatched>
					if (length(stack_open) == 0) {
						rstOut[[length(rstOut) + 1]] <<- x
						val_push <- list(
							'parent_id' = 0
							,'depth' = 0
						)
					} else {
						val_push <- h_push(
							value_ = x
						)
					}

					#900. Collect meta information
					if (meta_this){
						seg_id <<- seg_id + 1
						stack_segs[[seg_id]] <<- list(
							'seg_id' = seg_id
							,'parent_id' = val_push[['parent_id']]
							,'depth' = val_push[['depth']]
							,'start' = start
							,'end' = end
							,'type' = 'text'
							,'text' = x
						)
					}
				}
			}

			#999. Set a valid return value to prevent NULL output
			return(integer(1))
		}

		#100. Extract the basic stats from the string
		token_stats <- do.call(
			locSubstr
			,list(ptn_bound, str_this, overlap = F) |> append(kw_final)
		)[[1]] |>
			as.data.frame() |>
			dplyr::mutate(
				!!rlang::sym('b_start') := (dplyr::lag(!!rlang::sym('end'), n = 1) |> tidyr::replace_na(0) + 1) |> as.integer()
			) |>
			dplyr::mutate(
				!!rlang::sym('b_end') := (!!rlang::sym('start') - 1) |> as.integer()
				,!!rlang::sym('token_match') := substring(str_this, !!rlang::sym('start'), !!rlang::sym('end'))
			) |>
			dplyr::mutate(
				!!rlang::sym('ptn_id') := h_encloser_id(!!rlang::sym('token_match'), enclosers_id)
			) |>
			dplyr::mutate(
				!!rlang::sym('type') := h_encloser_mapper(
					!!rlang::sym('ptn_id')
					,mapper_ = enclosers_id_to_type
					,type_func = as.character
				)
				,!!rlang::sym('pair_id') := h_encloser_mapper(
					!!rlang::sym('ptn_id')
					,mapper_ = enclosers_id_to_pair
					,type_func = as.integer
				)
			) |>
			dplyr::mutate(
				!!rlang::sym('x_before') := substring(str_this, !!rlang::sym('b_start'), !!rlang::sym('b_end'))
				,!!rlang::sym('row_id') := seq_along(!!rlang::sym('start'))
			)

		nil_match <- F
		if (nrow(token_stats) == 0) {
			nil_match <- T
		} else if (nrow(token_stats) == 1) {
			if (is.na(token_stats[1, 'start'])) {
				nil_match <- T
			}
		}

		#500. Extract the nested structure
		#501. Direct return if none among the enclosers is identified
		if (nil_match){
			nchar_this <- nchar(str_this)
			if (!is.na(str_this) && (nchar_this > 0)) {
				if (meta_this) {
					seg_id <- seg_id + 1
					stack_segs[[seg_id]] <- list(
						'seg_id' = seg_id
						,'parent_id' = 0
						,'depth' = 0
						,'start' = 1
						,'end' = nchar_this
						,'type' = 'text'
						,'text' = str_this
						,'node_id' = NA_integer_
						,'pair_id' = NA_integer_
						,'unmatched' = NA
					)
					trans_segs <- field_types[names(field_types) %in% col_segs]
					meta[['segments']] <- dplyr::bind_rows(stack_segs) |>
						dplyr::select(dplyr::all_of(col_segs)) |>
						dplyr::mutate(
							dplyr::across(
								dplyr::all_of(names(trans_segs))
								,~trans_segs[[dplyr::cur_column()]](.)
							)
						)
					return(list('RESULT' = list(str_this), 'META' = meta))
				} else {
					return(list('RESULT' = list(str_this)))
				}
			} else {
				if (meta_this) {
					return(list('RESULT' = list(), 'META' = meta))
				} else {
					return(list('RESULT' = list()))
				}
			}
		}

		#550. Main process
		rc <- token_stats |>
			dplyr::mutate(
				!!rlang::sym('rc') := mapply(
					h_row_proc
					,!!rlang::sym('b_start')
					,!!rlang::sym('b_end')
					,!!rlang::sym('start')
					,!!rlang::sym('end')
					,!!rlang::sym('ptn_id')
					,!!rlang::sym('token_match')
					,!!rlang::sym('x_before')
					,!!rlang::sym('row_id')
					,!!rlang::sym('pair_id')
				)
			) |>
			dplyr::pull('rc')

		#559. Raise if the numbers of left boundaries and right boundaries do not match
		first_unclosed <- stack_id[!stack_closed & !stack_unmatch] |> head(1)
		if (length(first_unclosed) > 0){
			at_pos <- ''
			if (meta_this){
				at_pos <- paste0(
					' for opener: `', stack_nodes[[first_unclosed]][['opener_match']]
					, '` at position: <', stack_nodes[[first_unclosed]][['opener_start']], '>'
				)
			}
			stop(glue::glue('[{LfuncName}][item: {idx_this}]Group closer is missing{at_pos}'))
		}

		#560. Append the last item as free text if any
		a_start <- token_stats[nrow(token_stats), 'end'] + 1
		# a_start <- tail(token_stats, 1)[['end']] + 1
		a_end <- nchar(str_this)
		x_after <- substring(str_this, a_start, a_end)
		if (!nil_match) if (nchar(x_after) > 0){
			#100. Append the free text into the stack
			if (length(stack_open) == 0) {
				rstOut[[length(rstOut) + 1]] <- x_after
				val_push <- list(
					'parent_id' = 0
					,'depth' = 0
				)
			}

			#900. Collect meta information
			if (meta_this){
				#200. Register current segment
				#[ASSUMPTION]
				#[1] Under this condition, <enc_id> has not been incremented, which means current segment of free text
				#     is AFTER the dedicated <enc_id>
				#[2] We only need to calculate the beginning of current segment out of the <end> of that <enc_id>
				seg_id <- seg_id + 1
				stack_segs[[seg_id]] <- list(
					'seg_id' = seg_id
					,'parent_id' = 0
					,'depth' = 0
					,'start' = a_start
					,'end' = a_end
					,'type' = 'text'
					,'text' = x_after
				)
			}
		}

		#600. Emit the updated structure
		if (!meta_this){
			return(list('RESULT' = rstOut))
		}

		#700. Collect the meta information
		#710. Determine <segments>
		segs <- dplyr::bind_rows(stack_segs)

		#720. Determine <nodes>
		nodes <- dplyr::bind_rows(stack_nodes) |>
			dplyr::mutate(
				!!rlang::sym('unmatched') := !!rlang::sym('node_id') %in% (
					segs |>
						dplyr::filter_at('unmatched', ~.) |>
						dplyr::pull('node_id')
				)
			) |>
			dplyr::mutate(
				!!rlang::sym('closed') := !(!!rlang::sym('unmatched'))
			)


		#730. Determine <edges>
		edges <- nodes |>
			dplyr::filter_at('unmatched', ~!.) |>
			dplyr::select_at(dplyr::all_of(c('parent_id', 'node_id'))) |>
			dplyr::mutate(
				!!rlang::sym('from_node') := !!rlang::sym('parent_id')
				,!!rlang::sym('to_node') := !!rlang::sym('node_id')
			)

		#989. Form the final <meta> collection
		type_trans <- meta_trans |>
			sapply(
				function(t){
					field_types[names(field_types) %in% t]
				}
				,simplify = FALSE
				,USE.NAMES = TRUE
			)
		meta <- list(
			'nodes' = nodes |>
				dplyr::filter_at('unmatched', ~!.) |>
				dplyr::select(dplyr::all_of(col_nodes)) |>
				dplyr::mutate(
					dplyr::across(
						dplyr::all_of(names(type_trans[['nodes']]))
						,~type_trans[['nodes']][[dplyr::cur_column()]](.)
					)
				)
			,'nodes_unclosed' = nodes |>
				dplyr::filter_at('unmatched', ~.) |>
				dplyr::select(dplyr::all_of(col_nodes_unclosed)) |>
				dplyr::mutate(
					dplyr::across(
						dplyr::all_of(names(type_trans[['nodes_unclosed']]))
						,~type_trans[['nodes_unclosed']][[dplyr::cur_column()]](.)
					)
				)
			,'segments' = segs |>
				dplyr::select(dplyr::all_of(col_segs)) |>
				dplyr::mutate(
					dplyr::across(
						dplyr::all_of(names(type_trans[['segments']]))
						,~type_trans[['segments']][[dplyr::cur_column()]](.)
					)
				)
			,'edges' = edges |>
				dplyr::select(dplyr::all_of(col_edges)) |>
				dplyr::mutate(
					dplyr::across(
						dplyr::all_of(names(type_trans[['edges']]))
						,~type_trans[['edges']][[dplyr::cur_column()]](.)
					)
				)
		)

		return(list('RESULT' = rstOut, 'META' = meta))
	}

	#990. Apply to all items
	return(mapply(
		h_proc_one
		,txt
		,seq_along(txt)
		,rx
		,include
		,strict_
		,meta_
		,SIMPLIFY = F
		,USE.NAMES = T
	))
}

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
		ext_parens <- strNestedParser(
			teststr
			,enclosers = c('(' = ')')
			,rx = FALSE
		)
		nestedFormatter(ext_parens[[1]][['RESULT']])
		# list(
		#   chr. ("-- ")
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("bb ")
		#     $`2` : list(
		#       chr. ("(")
		#       chr. ("cc ")
		#       $`3` : list(
		#         chr. ("(")
		#         chr. ("dd")
		#         chr. (")")
		#       )
		#       chr. (")")
		#     )
		#     chr. (")")
		#   )
		#   chr. (" aa ")
		#   $`4` : list(
		#     chr. ("(")
		#     chr. ("ee ")
		#     $`5` : list(
		#       chr. ("(")
		#       chr. ("ff")
		#       chr. (")")
		#     )
		#     chr. (")")
		#   )
		#   chr. (" ~~")
		# )

		ext_jinja <- strNestedParser(
			testjinja
			,enclosers = c('{{' = '}}')
			,rx = FALSE
			,include = FALSE
		)
		nestedFormatter(ext_jinja[[1]][['RESULT']])
		# list(
		#   chr. ("-- ")
		#   $`1` : list(
		#     chr. (" bb ")
		#     $`2` : list(
		#       chr. (" cc")
		#       $`3` : list(
		#         chr. (" dd ")
		#       )
		#       chr. (" ")
		#     )
		#     chr. (" ")
		#   )
		#   chr. (" aa")
		#   $`4` : list(
		#     chr. (" ee ")
		#     $`5` : list(
		#       chr. (" ff ")
		#     )
		#     chr. (" ")
		#   )
		# )

		ext_html <- strNestedParser(
			testhtml
			,enclosers = c('<div.*?>' = '</div>')
			,rx = TRUE
			,case_insensitive = TRUE
		)
		nestedFormatter(ext_html[[1]][['RESULT']])
		# list(
		#   $`1` : list(
		#     chr. ("<div a=\"1\">")
		#     chr. ("bbb")
		#     $`2` : list(
		#       chr. ("<div id=\"2\">")
		#       chr. (" ccc")
		#       chr. ("</div>")
		#     )
		#     chr. ("ddd ")
		#     $`3` : list(
		#       chr. ("<div id=\"3\">")
		#       chr. ("eee")
		#       chr. ("</div>")
		#     )
		#     chr. ("fff")
		#     chr. ("</div>")
		#   )
		#   chr. (" ggg")
		# )

		#300. Special cases
		nestedFormatter(strNestedParser('')[[1]][['RESULT']])
		# list(
		# )

		nestedFormatter(strNestedParser('a')[[1]][['RESULT']])
		# list(
		#   chr. ("a")
		# )

		nestedFormatter(strNestedParser('(a b)')[[1]][['RESULT']])
		# list(
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("a b")
		#     chr. (")")
		#   )
		# )

		nestedFormatter(strNestedParser('a (b)')[[1]][['RESULT']])
		# list(
		#   chr. ("a ")
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("b")
		#     chr. (")")
		#   )
		# )

		nestedFormatter(strNestedParser('(a) b')[[1]][['RESULT']])
		# list(
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("a")
		#     chr. (")")
		#   )
		#   chr. (" b")
		# )

		nestedFormatter(strNestedParser('(a ((b) c (d))) e (f (g))')[[1]][['RESULT']])
		# list(
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("a ")
		#     $`2` : list(
		#       chr. ("(")
		#       $`3` : list(
		#         chr. ("(")
		#         chr. ("b")
		#         chr. (")")
		#       )
		#       chr. (" c ")
		#       $`4` : list(
		#         chr. ("(")
		#         chr. ("d")
		#         chr. (")")
		#       )
		#       chr. (")")
		#     )
		#     chr. (")")
		#   )
		#   chr. (" e ")
		#   $`5` : list(
		#     chr. ("(")
		#     chr. ("f ")
		#     $`6` : list(
		#       chr. ("(")
		#       chr. ("g")
		#       chr. (")")
		#     )
		#     chr. (")")
		#   )
		# )

		nestedFormatter(strNestedParser('(a ((b) c (d))) e (f (g))', include = F)[[1]][['RESULT']])
		# list(
		#   $`1` : list(
		#     chr. ("a ")
		#     $`2` : list(
		#       $`3` : list(
		#         chr. ("b")
		#       )
		#       chr. (" c ")
		#       $`4` : list(
		#         chr. ("d")
		#       )
		#     )
		#   )
		#   chr. (" e ")
		#   $`5` : list(
		#     chr. ("f ")
		#     $`6` : list(
		#       chr. ("g")
		#     )
		#   )
		# )

		#330. Multiple enclosers
		txt <- '-- (bb [cc (dd)]) aa {ee (ff)} ~~'

		#[ASSUMPTION]
		#[1] There are multiple enclosers to identify, hence the output result should include all enclosers
		#[2] <include> is forced to be True regardless of user request
		nestedFormatter(strNestedParser(
			txt
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,include = FALSE
		)[[1]][['RESULT']])
		# [strNestedParser]Multiple enclosers are requested, <include> is set to TRUE anyway.
		# list(
		#   chr. ("-- ")
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("bb ")
		#     $`2` : list(
		#       chr. ("[")
		#       chr. ("cc ")
		#       $`3` : list(
		#         chr. ("(")
		#         chr. ("dd")
		#         chr. (")")
		#       )
		#       chr. ("]")
		#     )
		#     chr. (")")
		#   )
		#   chr. (" aa ")
		#   $`4` : list(
		#     chr. ("{")
		#     chr. ("ee ")
		#     $`5` : list(
		#       chr. ("(")
		#       chr. ("ff")
		#       chr. (")")
		#     )
		#     chr. ("}")
		#   )
		#   chr. (" ~~")
		# )

		#340. Unmatched enclosers
		txt2 <- 'a [(b { c) [ (d} e) f ] g'

		nestedFormatter(strNestedParser(
			txt2
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group closer is missing

		# Turn on <meta_> to see detailed exception
		nestedFormatter(strNestedParser(
			txt2
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,meta_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group closer is missing for opener: `[` at position: <3>

		txt3 <- 'a (b { c) [ (d} e) f ] g'

		#[ASSUMPTION]
		#[1] The first opening '{' holds an open <node> without <closer>
		nestedFormatter(strNestedParser(
			txt3
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
		)[[1]][['RESULT']])
		# list(
		#   chr. ("a ")
		#   $`1` : list(
		#     chr. ("(")
		#     chr. ("b ")
		#     $`2` : list(
		#       chr. ("{")
		#       chr. (" c")
		#     )
		#     chr. (")")
		#   )
		#   chr. (" ")
		#   $`3` : list(
		#     chr. ("[")
		#     chr. (" ")
		#     $`4` : list(
		#       chr. ("(")
		#       chr. ("d")
		#       chr. ("}")
		#       chr. (" e")
		#       chr. (")")
		#     )
		#     chr. (" f ")
		#     chr. ("]")
		#   )
		#   chr. (" g")
		# )

		txt4 <- 'a [b] c ]'

		#[ASSUMPTION]
		#[1] When <include = TRUE> and <strict_ = FALSE>, all enclosers are included in the result
		#[2] Hence if any closer misses its corresponding opener, it will be treated as a normal text
		nestedFormatter(strNestedParser(
			txt4
			,enclosers = c('[' = ']')
			,rx = FALSE
			,include = TRUE
			,strict_ = FALSE
		)[[1]][['RESULT']])
		# list(
		#   chr. ("a ")
		#   $`1` : list(
		#     chr. ("[")
		#     chr. ("b")
		#     chr. ("]")
		#   )
		#   chr. (" c ")
		#   chr. ("]")
		# )

		#[ASSUMPTION]
		#[1] When <strict_ = True>, if any closer misses its corresponding opener, exception will be raised
		nestedFormatter(strNestedParser(
			txt4
			,enclosers = c('[' = ']')
			,rx = FALSE
			,include = TRUE
			,strict_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group opener is missing for closer: `]`

		# Turn on <meta_> to see detailed exception
		nestedFormatter(strNestedParser(
			txt4
			,enclosers = c('[' = ']')
			,rx = FALSE
			,include = TRUE
			,strict_ = TRUE
			,meta_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group opener is missing for closer: `]` at position: <9>

		#[ASSUMPTION]
		#[1] When <include = FALSE>, all enclosers are excluded from the result
		#[2] Hence if any closer misses its corresponding opener, exception will be raised
		#[3] In such case, <strict_> is ignored
		nestedFormatter(strNestedParser(
			txt4
			,enclosers = c('[' = ']')
			,rx = FALSE
			,include = FALSE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group opener is missing for closer: `]`

		# Turn on <meta_> to see detailed exception
		nestedFormatter(strNestedParser(
			txt4
			,enclosers = c('[' = ']')
			,rx = FALSE
			,include = FALSE
			,meta_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group opener is missing for closer: `]` at position: <9>

		txt5 <- 'a {b'

		#[ASSUMPTION]
		#[1] When the string is not closed by encloser, exception will be raised anyway
		#[2] Both <include> and <strict_> take no effect
		nestedFormatter(strNestedParser(
			txt5
			,enclosers = c('{' = '}')
			,rx = FALSE
			,include = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group closer is missing

		nestedFormatter(strNestedParser(
			txt5
			,enclosers = c('{' = '}')
			,rx = FALSE
			,include = FALSE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group closer is missing

		# Turn on <meta_> to see detailed exception
		#[ASSUMPTION]
		#[1] Above two scenarios lead to the same detailed exception as below
		nestedFormatter(strNestedParser(
			txt5
			,enclosers = c('{' = '}')
			,rx = FALSE
			,meta_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group closer is missing for opener: `{` at position: <3>

		#360. Crossing enclosers
		cross1 <- '[{aaa]}'

		nestedFormatter(strNestedParser(
			cross1
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
		)[[1]][['RESULT']])
		# list(
		#   $`1` : list(
		#     chr. ("[")
		#     $`2` : list(
		#       chr. ("{")
		#       chr. ("aaa")
		#     )
		#     chr. ("]")
		#   )
		#   chr. ("}")
		# )

		nestedFormatter(strNestedParser(
			cross1
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,strict_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group opener is missing for closer: `}`

		# Turn on <meta_> to see detailed exception
		nestedFormatter(strNestedParser(
			cross1
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,strict_ = TRUE
			,meta_ = TRUE
		)[[1]][['RESULT']])
		# [strNestedParser][item: 1]Group opener is missing for closer: `}` at position: <7>

		#500. Collect <META> information
		#501. Parse the string
		#[ASSUMPTION]
		#[1] the second opener `{` in below case can be wrapped by a complete pair of enclosers, so we set <strict_=FALSE>
		unmatch_but_closable <- 'a (b { c) [ (d} e) f ] g'
		unmatch_parsed <- strNestedParser(
			unmatch_but_closable
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,strict_ = FALSE
			,meta_ = TRUE
		)

		#510. Calculate the parenting path
		parent_of <- unmatch_parsed[[1]][['META']][['edges']][['from_node']]
		names(parent_of) <- unmatch_parsed[[1]][['META']][['edges']][['to_node']] |> as.character()
		h_get_path <- function(target_id, parents, path_sep = '/'){
			if (is.na(target_id) || target_id == 0) return('0')
			chain <- integer(0)
			cur <- as.integer(target_id)
			guard <- 0
			while (!is.na(cur) && cur != 0){
				chain <- c(cur, chain)
				nxt <- parents[as.character(cur)]
				if (is.null(nxt) || is.na(nxt)) break
				cur <- as.integer(nxt)
				guard <- guard + 1
				if (guard > 10000) break
			}
			paste(c(0, chain), collapse = path_sep)
		}

		#[ASSUMPTION]
		#[1] <seg_id> 4 denotes the <unmatched node> '{...' at position 6. We use ellipsis as it does not know where to end
		#[2] <seg_id> 5 denotes the free text <segment> ' c', and its <parent_id> is 2 which is just the above <unmatched node>
		#[3] Glad that we did not update the <parent_id> of this text <segment> in the function to its corrected-parent, and now
		#     we have a chance to find its parent-to-be during the text segment highlighting for debug purpose
		paths <- unmatch_parsed[[1]][['META']][['segments']] |>
			dplyr::mutate(
				!!rlang::sym('id_for_path') := ifelse(
					!!rlang::sym('type') == 'node'
					,!!rlang::sym('node_id')
					,!!rlang::sym('parent_id')
				)
			) |>
			dplyr::mutate(
				!!rlang::sym('parent_path') := sapply(
					!!rlang::sym('id_for_path')
					,h_get_path
					,parents = parent_of
				)
			)
		paths |> dplyr::select('parent_path')
		# A tibble: 14 x 1
		#    parent_path
		#    <chr>
		#  1 0
		#  2 0/1
		#  3 0/1
		#  4 0/2
		#  5 0/2
		#  6 0
		#  7 0/3
		#  8 0/3
		#  9 0/3/4
		# 10 0/3/4
		# 11 0/3/4
		# 12 0/3/4
		# 13 0/3
		# 14 0

		#520. See <Styles$strNestedRenderer> for full test program of how to render the nested structure in HTML

		#600. Test vectorized functionality
		ext_vec <- strNestedParser(
			testvec
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,strict_ = FALSE
			,meta_ = TRUE
		)

		ext_vec_segs <- ext_vec |>
			sapply(
				function(m){nrow(m[['META']][['segments']])}
				,simplify = F
				,USE.NAMES = T
			)
		nestedFormatter(ext_vec_segs)
		# list(
		#   $`normal` : integer (13)
		#   $`plain` : integer (1)
		#   $`enclosed` : integer (2)
		#   $`hijacked` : integer (14)
		#   $`unmatched` : integer (5)
		#   $`crossing` : integer (4)
		#   $`empty` : integer (0)
		#   $`NA` : integer (0)
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
		str_large <- strrep(testhtml, 10000)
		t_overall <- 0.0
		t1 <- lubridate::now()
		ext_large <- strNestedParser(str_large, enclosers = c('<div.*?>' = '</div>'), rx = T)
		t2 <- lubridate::now()
		t_overall <<- t_overall + t2 - t1
		print(t_overall)
		# Time difference of 12.37448 secs

		#930. Large string for plain enclosers
		str_large2 <- strrep(txt, 10000)
		t1 <- lubridate::now()
		ext_large2 <- strNestedParser(str_large2, enclosers = c('(' = ')', '{' = '}', '[' = ']'), rx = F)
		t2 <- lubridate::now()
		print(t2 - t1)
		# Time difference of 25.20156 secs
	}
}

#[TERMINOLOGY]
if (FALSE){'
G-5-nano-0807
### 前提定义
- 记文本长度为 n = len(txt)。
- enclosers 的大小为 m = len(enclosers)。
- 通过 ptn_bound.split(txt) 得到的 token 数量记为 t。显然 t <= n + 1，且多数情况下 t = O(n)。
- 其他辅助结构的规模在常量级别或与 m 相关：ptn_lBound 和 ptn_rBound 各包含大约 m 个正则对象。

### 推导过程
1. 预处理与正则构造
- 将 enclosers 转换为转义后的键值对（当 rx 为 False 时），以及构造 ptn_bound（一个用于分割 txt 的正则）。
- 这一步的时间开销大致与 enclosers 的大小和字符长度相关，通常记作 O(sum(len(k) + len(v)) + m)，在实际使用中通常是 O(m)。
- 空间也为 O(m) 用于存放编译后的正则对象及中间字符串。
- ptn_bound.split(txt) 的代价是遍历并在匹配处分割，时间大致为 O(n)；产生的 token 数量为 t，空间为 O(t)（以及输出的 token 本身所需的额外空间）。
- 为每个 encloser 的双边界分别编译正则，这共需要 O(m) 次编译，单次编译成本与模式长度相关，记作 O(sum(len(k) + len(v)))，通常为 O(m)；空间为 O(m)。

2. 主循环对每个 token 的处理
- 对每个 x in tokens（共 t 个，长度为 Lx，且 ∑ Lx = O(n)）执行两次线性搜索：
  - 左边界检测：遍历 ptn_lBound 的 m 个模式，逐一执行 ptn.match(x)。最坏情况要对每个模式都尝试一次且每次的匹配代价与 Lx 成正比
    - 因此这步最坏时间为 O(m * Lx)。
    - 对全部 token 的总和为 O(m * ∑ Lx) = O(m * n)。
  - 右边界检测：同理，O(m * n)。
- 其余的栈操作为常数时间的 append / pop；但在遇到左界后可能会执行 del stack[(i+1):] 等切片删除操作。该操作的成本与要删除的深度相关，
  - 最坏情况下可能达到 O(depth) 而 depth 最多为 m（嵌套深度的上界）。在极端情况下，这些切片操作对每个左界都可能触发一次，总体可被把控在 O(n * m) 级别。

#### 综合主循环的时间复杂度：
- 最坏情况的时间上界可以近似写成 O(n * m)，其中 n 为文本长度，m 为 enclosers 的个数。若 m 与 n 同阶，即 m = Θ(n)，则最坏时间复杂度为 O(n^2)。

#### 需要强调的点：
- 实际运行时的常数因子很大程度取决于实际文本的分割情况、嵌套深度以及匹配是否能较早命中某个模式（这会降低常数项）。
- 该实现的最关键瓶颈在于“对所有左边界模式和所有右边界模式的逐个逐个匹配”，以及在深嵌套时的切片删除成本。

3. 空间复杂度
- 输出结果的尺寸等同于最终 return 的 stack（经处理后弹出的最终列表）。在最坏情况下，输出大小为 O(n)。
- 主循环中维护的栈 stack 与 stack_lb 的最大深度取决于嵌套层数，深度 upper bound 为 m；
- 因此这两者的额外空间开销为 O(n)（用于存放当前未闭合的 tokens，总和不超过文本中 token 的总数）加上 O(m) 的正则对象引用。
- 其他辅助结构，如 ptn_bound、ptn_lBound、ptn_rBound、以及局部变量等，合计为 O(m)。
- 综上，整体空间复杂度为 O(n + m)。

### 结论
- **Time Complexity**：在一般记号下，最坏情况大致为 O(n * m)。若 m 与 n 同量级（如 m = Θ(n)），则最坏情况下是 O(n^2)。
- **Auxiliary Space**：O(n + m)。

### 额外的注意与优化建议（可选）
- 该实现的主要时间成本来自对 m 个左边界模式和 m 个右边界模式的逐个匹配。若 enclosers 规模较大，可以考虑：
  - 将多模式匹配合并成一个单一的正则（若可行）或者使用一个字典结构将左边界字符快速定位到候选索引，减少不必要的正则匹配次数。
  - 采用堆栈结构的替代实现，避免对深度较大时的切片删除操作带来的 O(depth) 代价（例如通过维护一个指针/区间来表示当前层级，而非对列表进行切片删减）。
  - 若对嵌套深度有控制需求，可以在文档中约束 m 的上限，或对极端输入进行特殊处理（如提前抛错、改写为流式解析）。

### `path` of `segments` 规则
- 路径使用 `"/"` 连接节点 id，固定以根 `0` 开头，例如： `"0/3/4"`
- 对 `type = "text"` ：路径定位到其 **父容器**： `0/.../parent_id`
- 对 `type = "node"` ：路径定位到该 **节点自身**： `0/.../node_id`

## 推荐用法：四表联动
- **构树/分析层级**： `nodes + edges`
- **高亮/截取/覆盖统计**： `nodes + spans`
- **渲染/复原结构**： `segments` （递归按 `parent_id` 渲染）
- **BI 聚合**：按 `path` of `segments` 分组统计（如每条路径的文本长度/节点数量/深度分布）
'}
