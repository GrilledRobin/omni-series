#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is to render the character string as HTML, with each piece surrounded by pairing enclosers, e.g. parentheses and/or  #
#   | brackets, highlighted in different background colors.                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The argument <meta> should be provided with the one extracted by <AdvOp$strNestedParser> for the same <txt>                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt               :   <chr     > Character string to be rendered                                                                   #
#   |meta              :   <list    > Dedicated <META> information collection for rendering, should be <list[list[data.frame]]> as      #
#   |                                  extracted from <txt> via the core function <AdvOp$strNestedParser>, where the top level <list>   #
#   |                                  should be of the same length as <txt>                                                            #
#   |include           :   <logical > Whether to include the enclosers in the output result.                                            #
#   |                      [TRUE                ] <Default> Include the bounds as output                                                #
#   |                      [FALSE               ]           Exclude the bounds as output                                                #
#   |colorBy           :   <chr     > Render different colors for segments on which strategy                                            #
#   |                      [pair_id             ] <Default> Differ the color setting by <pair_id> as indicated in the meta information  #
#   |                      [depth               ]           Render different colors based on <depth> of each structure                  #
#   |palette           :   <chr     > Character vector of HEX color codes to render different <segment>s                                #
#   |                      [<see def.>          ] <Default> Use a series of colors to differ the <segment>s in the result               #
#   |                      [<chr>               ]           Vector of color codes                                                       #
#   |alpha             :   <num     > Transparency of the rendered background color, between 0 and 1                                    #
#   |                      [<see def.>          ] <Default> Set certain transparency for the highlighting                               #
#   |                      [<num>               ]           Other single <numeric> value that is between 0 and 1                        #
#   |alphaBorder       :   <num     > Transparency of the border for the <unmatched nodes> if any, between 0 and 1                      #
#   |                      [<see def.>          ] <Default> Set certain transparency for the highlighting                               #
#   |                      [<num>               ]           Other single <numeric> value that is between 0 and 1                        #
#   |collapsible       :   <logical > Whether to set the <node>s as collapsible with interactivity                                      #
#   |                      [TRUE                ] <Default> Set the <node>s as collapsible                                              #
#   |                      [FALSE               ]           Disable the collapse and only display the content                           #
#   |collapsed         :   <logical > Whether to display the <node>s as collapsed at the initial view, given <collapsible=TRUE>         #
#   |                      [FALSE               ] <Default> Fully expand all <node>s at initial view                                    #
#   |                      [TRUE                ]           Show all <node>s as collapsed at initial view                               #
#   |showTooltip       :   <logical > Whether to show a tooltip on hovering the <node>s with a bunch of stats for investigation         #
#   |                      [TRUE                ] <Default> Show tooltip when hover the mouse over the <node>s                          #
#   |                      [FALSE               ]           Suppress the tooltip                                                        #
#   |wrap              :   <chr     > How to generate the output result                                                                 #
#   |                      [all                 ] <Default> Create the result as a complete HTML with certain <CSS> and <JS> tools      #
#   |                      [fragment            ]           Only prepare the content and leave the <CSS> and <JS>. This is useful when  #
#   |                                                        rendering a list of strings while there is no need to attach <CSS> and <JS>#
#   |                                                        scripts for all of them                                                    #
#   |fromRoot          :   <int     > Starting from which <node> to its all child <node>s should the rendering be done                  #
#   |                      [int <0>             ] <Default> Render the entire <txt>, i.e. starting from <node_id=0>                     #
#   |                      [<int>               ]           Render the provided <node_id> and all its child <node>s                     #
#   |body_ids          :   <list    > List of integer/character vectors indicating the globally unique <body_id> of each colored section#
#   |                      [NULL                ] <Default> Do not provide this, so the function calculates for it                      #
#   |                      [<list[int/chr]>     ]           List of integer/character vectors matching all the sections to render       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |990.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<chr >            :   The result rendered into HTML string representation                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260121        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |glue, rlang, stringi, dplyr, tidyselect, tidyr                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isVEC                                                                                                                      #
#   |   |   |match.arg.x                                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	glue, rlang, stringi, dplyr, tidyselect, tidyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#[ASSUMPTION]
#[1] Native pipe ` |> ` does not support the operation INSIDE a defused statement, e.g. `dplyr::mutate(aa |> paste0('bb'))`
#[2] Therefore, we still need to introduce `magrittr` where necessary
library(magrittr)

strNestedRenderer <- function(
	txt
	,meta
	,include = TRUE
	,colorBy = c('pair_id', 'depth')
	,palette = c('#fff3b0', '#cce5ff', '#d4edda', '#f8d7da', '#e2d6f9', '#d1ecf1')
	,alpha = 0.55
	,alphaBorder = 0.95
	,collapsible = TRUE
	,collapsed = FALSE
	,showTooltip = TRUE
	,wrap = c('all', 'fragment')
	,fromRoot = 0
	,body_ids = NULL
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
	if (!isVEC(include) || !is.logical(include)){
		stop(glue::glue('[{LfuncName}]<include>:<{typeof(include)}> must be provided a logical vector!'))
	}
	colorBy_choices <- formals(sys.function())[['colorBy']] |> eval()
	if (missing(colorBy)) {
		colorBy <- match.arg(colorBy)
	} else {
		colorBy <- sapply(colorBy, match.arg.x, choices = colorBy_choices, arg.func = function(s){tolower(s)})
	}
	if (!isVEC(alpha) || !is.numeric(alpha)){
		stop(glue::glue('[{LfuncName}]<alpha>:<{typeof(alpha)}> must be provided a numeric vector!'))
	}
	if (!isVEC(alphaBorder) || !is.numeric(alphaBorder)){
		stop(glue::glue('[{LfuncName}]<alphaBorder>:<{typeof(alphaBorder)}> must be provided a numeric vector!'))
	}
	if (!isVEC(collapsible) || !is.logical(collapsible)){
		stop(glue::glue('[{LfuncName}]<collapsible>:<{typeof(collapsible)}> must be provided a logical vector!'))
	}
	if (!isVEC(collapsed) || !is.logical(collapsed)){
		stop(glue::glue('[{LfuncName}]<collapsed>:<{typeof(collapsed)}> must be provided a logical vector!'))
	}
	if (!isVEC(showTooltip) || !is.logical(showTooltip)){
		stop(glue::glue('[{LfuncName}]<showTooltip>:<{typeof(showTooltip)}> must be provided a logical vector!'))
	}
	wrap_choices <- formals(sys.function())[['wrap']] |> eval()
	if (missing(wrap)) {
		wrap <- match.arg(wrap)
	} else {
		wrap <- sapply(wrap, match.arg.x, choices = wrap_choices, arg.func = function(s){tolower(s)})
	}
	if (!isVEC(fromRoot) || !is.numeric(fromRoot)){
		stop(glue::glue('[{LfuncName}]<fromRoot>:<{typeof(fromRoot)}> must be provided a integer vector!'))
	}
	fromRoot <- as.integer(fromRoot)
	has_body_id <- !missing(body_ids)
	if (has_body_id) {
		if (length(body_ids) != length(txt)){
			stop(glue::glue('[{LfuncName}]<body_ids>:<{length(body_ids)}> should be of the same length as <txt>:<{length(txt)}>!'))
		}
	} else {
		ids_end <- meta |>
			sapply(
				function(m){
					k_ids <- m[['segments']] |>
						dplyr::filter(!!rlang::sym('type') == 'node') |>
						nrow()
					if (k_ids == 0) return(1L)
					else return(k_ids |> as.integer())
				}
				,simplify = T
				,USE.NAMES = T
			) |>
			cumsum()
		ids_bgn <- ids_end |>
			dplyr::lag() |>
			tidyr::replace_na(0L) |>
			add(1L) |>
			rlang::set_names(names(ids_end))
		body_ids <- mapply(
			seq
			,ids_bgn
			,ids_end
			,SIMPLIFY = F
			,USE.NAMES = T
		)
	}
	palette_ <- palette

	#050. Prepare necessary styles for the output
	css <- paste0(''
		,'<style>'
		,'.ec-root{font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, '
		,'"Liberation Mono", "Courier New", monospace;'
		,'font-size:12px; line-height:1.6; white-space:pre-wrap; word-break:break-word;}'
		,'.ec-node{box-decoration-break:clone; -webkit-box-decoration-break:clone;}'
		,'.ec-summary{cursor:pointer; user-select:none; font-weight:700; padding:0 2px;}'
		,'.ec-preview{opacity:0.65;}'
		,'.ec-ellipsis{padding:0 1px;}'
		,'.ec-body{white-space:pre-wrap;}'
		,'.ec-unknown{background:rgba(200,200,200,0.35); border:1px dashed rgba(120,120,120,0.8);'
		,'border-radius:4px; padding:0px 2px;}'
		,'</style>'
	)
	js <- paste0(''
		,'<script>'
		,'function ecToggle(id, el){'
		,'  var body=document.getElementById(id); if (!body) return;'
		,'  var isHidden=(body.style.display==="none");'
		,'  body.style.display=isHidden?"inline":"none";'
		,'  if(el){el.innerHTML=isHidden?"&#9662;":"&#9656;";}'
		,'}'
		,'</script>'
	)

	#200. Define helper functions
	#210. Function to convert the HEX color codes into representation of JS function call <rgba()>
	h_js_rgba <- function(hex_color, alpha){
		#[ARGUMENTS]
		#[hex_color] <chr> vector as `#FFFFFF`, case insensitive
		#[alpha    ] <num> vector as float
		# col_clean <- stringi::stri_replace_all_regex(hex_color, '^\\s*#([0-9a-f]+)\\s*$', '$1')
		col_clean <- gsub('^\\s*#([0-9a-f]+)\\s*$', '\\1', hex_color, ignore.case = T, perl = T)
		col_clean[nchar(col_clean) != 6 | is.na(col_clean)] <- 'c8c8c8'
		sprintf(
			'rgba(%d, %d, %d, %.3f)'
			,col_clean |> substring(1,2) |> strtoi(16L)
			,col_clean |> substring(3,4) |> strtoi(16L)
			,col_clean |> substring(5,6) |> strtoi(16L)
			,alpha
		)
	}

	#230. Function to escape the special characters in HTML
	html.escape <- function(x){
		#100. Define the special characters in HTML
		sp_chars <- c(
			'&' = '&amp;'
			,'<' = '&lt;'
			,'>' = '&gt;'
			,'"' = '&quot;'
			,'\'' = '&#39;'
		)
		stringi::stri_replace_all_fixed(
			x
			,names(sp_chars)
			,sp_chars
			,vectorize_all = F
		)
	}

	#500. Define the main function to process one item at each iteration
	h_proc_one <- function(
		txt_
		,meta_
		,include_
		,colorBy_
		,alpha_
		,alphaBorder_
		,collapsible_
		,collapsed_
		,showTooltip_
		,wrap_
		,fromRoot_
		,body_id_
	){
		#100. Collect information of all <node>s
		nodes_all <- dplyr::bind_rows(meta_[names(meta_) %in% c('nodes','nodes_unclosed')])

		#110. Customize the <body_id> as required by <JS>
		n_nodes <- nrow(nodes_all)
		if (n_nodes > 0){
			if (length(body_id_) != n_nodes){
				stop(glue::glue(
					'[{LfuncName}]<body_id_>:<{length(body_id_)}> should match the rows in <nodes_all>:<{n_nodes}>!'
				))
			}
			nodes_all[['provided_id']] <- body_id_ |> unlist() |> as.character()
		} else {
			if (length(body_id_) != 1){
				err_body_id <- paste0(body_id_, collapse = ',')
				stop(glue::glue(
					'[{LfuncName}]<body_id_>:<{err_body_id}> for <txt> without node should be a single integer!'
				))
			}
			nodes_all[['provided_id']] <- character(0)
		}

		#200. Define helper functions
		#270. Function to render the result in recursion
		h_render <- function(pid, store){
			if (!(pid %in% names(store))) return('')
			grp <- store[[as.character(pid)]] |>
				dplyr::mutate(
					!!rlang::sym('inner') := sapply(!!rlang::sym('node_id'), h_render, store = store)
				) |>
				dplyr::mutate(
					!!rlang::sym('rst') := paste0(
						!!rlang::sym('span_open')
						,!!rlang::sym('part_summary')
						,!!rlang::sym('part_preview')
						,!!rlang::sym('part_collapsible')
						,!!rlang::sym('opener')
						,!!rlang::sym('inner')
						,!!rlang::sym('closer')
						,!!rlang::sym('part_collapsible_close')
						,!!rlang::sym('span_close')
					) %>%
						{\(x) ifelse(!!rlang::sym('is_node') == F, !!rlang::sym('text'), x)}() %>%
						{\(x) ifelse(
							!!rlang::sym('is_unknown') == F
							,x
							,paste0(
								'<span class="ec-unknown">'
								,(
									substring(txt_, !!rlang::sym('start'), !!rlang::sym('end')) %>%
										tidyr::replace_na('') %>%
										html.escape()
								)
								,'</span>'
							)
						)}()
				)

			return(paste0(grp |> dplyr::pull('rst'), collapse = ''))
		}

		#300. Prepare colors for the <node>s
		node_css <- nodes_all |>
			dplyr::select(dplyr::all_of(c('node_id','pair_id','depth','provided_id'))) |>
			dplyr::mutate(
				!!rlang::sym('body_id') := paste0(
					'ec_body_'
					, !!rlang::sym('provided_id')
				)
				,!!rlang::sym('color') := palette_[!!rlang::sym(colorBy_) %% length(palette_) + 1L]
				,!!rlang::sym('leftw') := pmin(!!rlang::sym('depth'), 4L) + 1L
			) |>
			dplyr::mutate(
				!!rlang::sym('bg') := h_js_rgba(!!rlang::sym('color'), alpha_)
				#[ASSUMPTION]
				#[1] Below is a demo showing that the customized function does not support the native pipe at such case
				,!!rlang::sym('bd') :=  !!rlang::sym('color') %>% h_js_rgba(alphaBorder_)
			) |>
			dplyr::mutate(
				!!rlang::sym('node_CSS') := paste0(
					'background: ', !!rlang::sym('bg'), ';'
					, 'border: 1px solid ', !!rlang::sym('bd'), ';'
					, 'border-left-width: ', !!rlang::sym('leftw'), 'px;'
					, 'border-radius: 4px;'
					, 'padding: 0px 2px;'
					, 'margin: 0px 1px;'
					, 'white-space: pre-wrap;'
				)
			)

		#500. Prepare the segments data for render
		seg_for_render <- meta_[['segments']] |>
			dplyr::mutate(
				!!rlang::sym('include') := include_
				,!!rlang::sym('colorBy') := colorBy_
				,!!rlang::sym('showTooltip') := showTooltip_
				,!!rlang::sym('collapsible') := collapsible_
				,!!rlang::sym('collapsed') := collapsed_
				,!!rlang::sym('has_nodes') := n_nodes > 0
			) |>
			dplyr::left_join(
				node_css |>
					dplyr::select(dplyr::all_of(c('node_id','node_CSS','body_id')))
				,by = 'node_id'
			) |>
			dplyr::mutate(
				!!rlang::sym('body_id') := ifelse(
					!!rlang::sym('has_nodes') == T
					, !!rlang::sym('body_id')
					, paste0('ec_body_', body_id_)
				)
			) |>
			dplyr::left_join(
				nodes_all |>
					dplyr::select(dplyr::all_of(c('node_id','opener_match','closer_match','span_start','span_end','closed')))
				,by = 'node_id'
			) |>
			dplyr::mutate(
				!!rlang::sym('is_node') := !(!!rlang::sym('type') %in% c('text'))
			) |>
			dplyr::mutate(
				!!rlang::sym('is_collapsible_node') := !!rlang::sym('is_node') & !!rlang::sym('collapsible') & !!rlang::sym('closed')
				,!!rlang::sym('is_unknown') := !(
					!!rlang::sym('type') %in% c('text')
					| !!rlang::sym('node_id') %in% meta_[['nodes']][['node_id']]
				)
			) |>
			#[ASSUMPTION]
			#[1] All below statements do not support the native pipes, as they are already inside a defused expression
			dplyr::mutate(
				!!rlang::sym('opener') := !!rlang::sym('opener_match') %>%
					html.escape() %>%
					{\(x) ifelse(!!rlang::sym('include') == F, '', x)}() %>%
					tidyr::replace_na('')
				,!!rlang::sym('closer') := !!rlang::sym('closer_match') %>%
					html.escape() %>%
					{\(x) ifelse(!!rlang::sym('include') == F, '', x)}() %>%
					tidyr::replace_na('')
			) |>
			dplyr::mutate(
				!!rlang::sym('tooltip') := paste0(
					'title="node=', !!rlang::sym('node_id'), ' '
					, 'parent=', !!rlang::sym('parent_id'), ' '
					, 'depth=', !!rlang::sym('depth'), ' '
					, 'pair=', !!rlang::sym('pair_id'), ' '
					, 'closed=', !!rlang::sym('closed'), ' '
					, 'colorBy=', !!rlang::sym('colorBy'), ' '
					, '[', !!rlang::sym('span_start'), ', ', !!rlang::sym('span_end'), ']'
					, '"'
				) |>
					{\(x) ifelse(!!rlang::sym('is_node') == F, '', x)}()
			) |>
			dplyr::mutate(
				!!rlang::sym('marker') := c('&#9662;','&#9656;')[as.integer(!!rlang::sym('collapsed')) + 1L]
				,!!rlang::sym('body_disp') := c('inline','none')[as.integer(!!rlang::sym('collapsed')) + 1L]
				,!!rlang::sym('preview') := paste0(
					!!rlang::sym('opener') %>% tidyr::replace_na('')
					, '<span class="ec-ellipsis">…</span>'
					, !!rlang::sym('closer') %>% tidyr::replace_na('')
				) %>%
					{\(x) ifelse(!!rlang::sym('include') == F, '<span class="ec-ellipsis">…</span>', x)}() %>%
					{\(x) ifelse(!!rlang::sym('is_node') == F, '', x)}()
				,!!rlang::sym('span_open') := paste0(
					'<span class="ec-node', c('',' ec-collapsible')[as.integer(!!rlang::sym('collapsible')) + 1L]
					, ' ', 'ec-depth-', !!rlang::sym('depth')
					, ' ', 'ec-pair-', !!rlang::sym('pair_id')
					, '"'
					, ' ', !!rlang::sym('tooltip')
					, ' ', 'data-node="', !!rlang::sym('node_id'), '"'
					, ' ', 'data-parent="', !!rlang::sym('parent_id'), '"'
					, ' ', 'data-depth="', !!rlang::sym('depth'), '"'
					, ' ', 'data-pair="', !!rlang::sym('pair_id'), '"'
					, ' ', 'style="', !!rlang::sym('node_CSS'), '"'
					, '>'
				) %>%
					{\(x) ifelse(!!rlang::sym('is_node') == F, '', x)}()
				,!!rlang::sym('span_close') := c('','</span>')[as.integer(!!rlang::sym('is_node')) + 1L]
			) |>
			dplyr::mutate(
				!!rlang::sym('part_summary') := paste0(
					'<span class="ec-summary" onclick="ecToggle(\'', !!rlang::sym('body_id'), '\', this)">'
					, !!rlang::sym('marker')
					, '</span>'
				) %>%
					{\(x) ifelse(!!rlang::sym('is_collapsible_node') == F, '', x)}()
				,!!rlang::sym('part_preview') := paste0(
					'<span class="ec-preview">', !!rlang::sym('preview'), '</span>'
				) %>%
					{\(x) ifelse(!!rlang::sym('is_collapsible_node') == F, '', x)}()
				,!!rlang::sym('part_collapsible') := paste0(
					'<span id="', !!rlang::sym('body_id'), '"'
					, ' ', 'class="ec-body" style="display:', !!rlang::sym('body_disp'), ';">'
				) %>%
					{\(x) ifelse(!!rlang::sym('is_collapsible_node') == F, '', x)}()
				,!!rlang::sym('part_collapsible_close') := c('','</span>')[as.integer(!!rlang::sym('is_collapsible_node')) + 1L]
			)

		#600. Render
		#610. Split the <segments> by <parent_id>, as a necessity for recursive calculation
		segs_pre <- seg_for_render |> dplyr::group_by_at('parent_id')
		segs_names <- segs_pre |> dplyr::group_keys()
		segs_by_parent <- segs_pre |>
			dplyr::group_split() |>
			stats::setNames(segs_names |> dplyr::pull('parent_id') |> as.character())

		#680. Conduct the calculation in terms of the request
		rstOut <- h_render(fromRoot_, store = segs_by_parent)

		#690. Return the body as requested
		if (wrap_ == 'fragment') return(paste0('<div class="ec-root">', rstOut, '</div>'))

		#990. Return full HTML
		return(paste0(css, js, '<div class="ec-root">', rstOut, '</div>'))
	}

	#990. Apply to all items
	return(mapply(
		h_proc_one
		,txt
		,meta
		,include
		,colorBy
		,alpha
		,alphaBorder
		,collapsible
		,collapsed
		,showTooltip
		,wrap
		,fromRoot
		,body_ids
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
		#[REQUIREMENT]
		# AdvOp
		#   strNestedParser
		# Styles
		#   nestedFormatter

		out_html <- 'D:/Temp/nestedEnclosers.html'

		h_to_file <- function(txt_, file_){
			#100. Create a new file
			if (file.exists(file_)) file.remove(file_)
			file.create(file_, showWarnings = F)
			fileconn <- file(file_)

			#500. Write the lines
			writeLines(txt_ |> paste0(collapse = '\n'), fileconn, sep = '\n')

			#900. Close the file
			close(fileconn)

			invisible(NULL)
		}

		#100. Collect <META> information
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
		unmatch_parsed_meta <- unmatch_parsed |>
			sapply(
				function(x){x[['META']]}
				,simplify = F
				,USE.NAMES = T
			)

		#200. Test the render result
		unmatch_rendered <- strNestedRenderer(
			unmatch_but_closable
			,meta = unmatch_parsed_meta
			,colorBy = 'pair_id'
		)
		h_to_file(unmatch_rendered, out_html)

		#300. Test the color by <depth>
		unmatch_by_depth <- strNestedRenderer(
			unmatch_but_closable
			,meta = unmatch_parsed_meta
			,colorBy = 'depth'
		)
		h_to_file(unmatch_by_depth, out_html)

		#400. Only render the first valid <node>
		unmatch_node1 <- strNestedRenderer(
			unmatch_but_closable
			,meta = unmatch_parsed_meta
			,fromRoot = 1
		)
		h_to_file(unmatch_node1, out_html)

		#500. Render a plain text without any enclosers
		#[ASSUMPTION]
		#[1] The result is plain text without highlighting
		txt_parsed <- strNestedParser(
			'abc'
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,strict_ = FALSE
			,meta_ = TRUE
		)
		txt_parsed_meta <- txt_parsed |>
			sapply(
				function(x){x[['META']]}
				,simplify = F
				,USE.NAMES = T
			)
		txt_rendered <- strNestedRenderer(
			'abc'
			,meta = txt_parsed_meta
			,colorBy = 'pair_id'
		)
		h_to_file(txt_rendered, out_html)

		#700. Render a series of texts
		#[ASSUMPTION]
		#[1] We need them to be rendered in one HTML file, so the <CSS> and <JS> scripts should only be exported once
		#[2] <body_id> of all the nodes should be globally unique
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

		#730. Parse the vector
		vec_parsed <- strNestedParser(
			testvec
			,enclosers = c('(' = ')', '{' = '}', '[' = ']')
			,rx = FALSE
			,strict_ = FALSE
			,meta_ = TRUE
		)
		vec_parsed_meta <- vec_parsed |>
			sapply(
				function(x){x[['META']]}
				,simplify = F
				,USE.NAMES = T
			)

		#750. Prepare correct parameters
		wrap_mod <- rlang::rep_along(testvec, 'fragment')
		wrap_mod[[1]] <- 'all'

		#[ASSUMPTION]
		#[1] This is to demonstrate how to prepare the globally unique <body_id> out of the META information table
		#[2] You can choose to provide it for the renderer to see the result, actually the same as the default behavior
		#     of the function
		k_ids <- 0L
		body_ids <- vec_parsed |>
			sapply(
				function(x){
					k_this <- x[['META']][['segments']] |>
						dplyr::filter(!!rlang::sym('type') == 'node') |>
						nrow() |>
						as.integer()
					# At least add 1, as there is one string to render, even without grouping
					if (k_this == 0) k_this <- 1
					seq_this <- seq(k_ids + 1, k_ids + k_this)
					k_ids <<- k_ids + k_this
					return(seq_this)
				}
				,simplify = F
				,USE.NAMES = T
			)

		#780. Render
		vec_rendered <- strNestedRenderer(
			testvec
			,meta = vec_parsed_meta
			,colorBy = 'pair_id'
			,wrap = wrap_mod
			# ,body_ids = body_ids
		) |>
			paste0(collapse = '<br />')

		#790. Export
		h_to_file(vec_rendered, out_html)

		#990. Garbage collection
		if (file.exists(out_html)) file.remove(out_html)
	}
}
