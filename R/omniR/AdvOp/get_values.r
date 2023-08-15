#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the values of the provided [values] (by regarding them as variable names) from the closest   #
#   | call stack, which could possibly be [global], if they are defined more than once in different frames                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Map the values of variables as they are provided [character strings]                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...          :   Various arguments in either form as below, that indicates a list of objects to be validated                       #
#   |                 [1] Name parameters just as calling other functions with [...] as parameter                                       #
#   |                 [2] A list with named members, similar as above, but provided in a combined list                                  #
#   |inplace      :   Whether to keep the output the same as the input values if any cannot be found as [object names] from the frames  #
#   |                 [TRUE       ] <Default> Keep the input values as output if they cannot be identified as [object names]            #
#   |                 [FALSE      ]           Output [NA] for those which cannot be identified as [object names]                        #
#   |mode         :   The mode or type of object sought, see definition of [mget]                                                       #
#   |                 [any        ] <Default> Seek out for any type of values for the input                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>    :   This function output different values in below convention:                                                        #
#   |                 [1] If [...] is provided with at least two elements or a [is_flattenable] list with at least two elements, return #
#   |                      a [list] of the respective values retrieved from current session, with their respective [names] if any       #
#   |                     [names ] the respective input names, or [''] for positional arguments                                         #
#   |                     [values] when NOT found:                                                                                      #
#   |                              [NA            ] if [inplace==FALSE]                                                                 #
#   |                              [input values  ] if [inplace==TRUE]                                                                  #
#   |                 [2] If there is only one positional argument provided, return its value                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210829        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <isVEC> to correct the verification of vectors                                                                #
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
#   |   |rlang, vctrs                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isVEC                                                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, vctrs
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

get_values <- function(..., inplace = TRUE, mode = 'any'){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	#Below statements are copied from [dplyr::bind_rows]
	dots <- rlang::list2(...)
	is_flattenable <- function(x) vctrs::vec_is_list(x) && !rlang::is_named(x)
	if (length(dots) == 1 && rlang::is_bare_list(dots[[1]])) {
		dots <- dots[[1]]
	}
	dots <- rlang::flatten_if(dots, is_flattenable)
	in_names <- names(dots)
	if (!is.logical(inplace)) inplace <- TRUE
	if (length(mode) == 0) mode <- 'any'

	#500. Try to retrieve the values of the indicated objects
	rstOut <- lapply(
		dots
		,function(x) {
			#100. Search for all elements if [x] is a vector with length more than 1
			v_out <- sapply(
				x
				,function(m) {
					#100. Initialize the interim variables
					vals <- NULL
					ifr <- 1

					#400. Try to get the value of current object from the parent frames
					#[1] Failed to use [get(m, pos = -1)] as it will always look up in the out-most frame of this call
					while (T) {
						#100. Retrieve the content of the parent frame to the previous one
						#[Quote: https://stackoverflow.com/questions/11885207/get-all-parameters-as-list ]
						pframe <- parent.frame(ifr)
						parent_vars <- evalq(as.list(environment()), envir = pframe)

						#300. Identify current element in above list
						vals <- parent_vars[[m]]

						#500. Verify the [mode]
						if ((mode != 'any') & !is.null(vals)) {
							vals_mode <- c(typeof(vals), mode(vals))
							if (!(mode %in% vals_mode)) vals <- NULL
						}

						#700. Break the loop if its value is found in any of the frames for the first time
						if (!is.null(vals)) break

						#800. Stop the loop if current frame is the global environment
						#Quote: https://www.r-bloggers.com/2011/06/environments-in-r/
						if (environmentName(pframe) == 'R_GlobalEnv') break

						#900. Increment the counter of parent frames
						ifr <- ifr + 1
					}

					#700. Set the NULL values to NA for identification at later steps
					if (is.null(vals)) vals <- NA

					#999. Return the result
					return(vals)
				}
				,USE.NAMES = F
				,simplify = F
			)

			#400. Verify whether all results are vectors (primarily for exclusion of data.frame and lists)
			chk_vec <- all(sapply(v_out, function(x){isVEC(x) & (length(x) == 1)}))

			#600. Assign the placeholder when requested
			if (inplace) {
				#100. Identify [NA] values for assigning placeholders
				v_na <- mapply(
					function(vec, is_vec){
						if (is_vec) return(is.na(vec))
						else return(F)
					}
					,v_out
					,chk_vec
				)

				#500. Replace the NA results with the placeholder
				v_out[v_na] <- x[v_na]
			}

			#700. Extract the first one from above list created by [sapply]
			#[1] In case [x] is a vector with more than 1 element and the result is a list of vectors, we flatten the result
			#[2] We cannot use [unlist] to flatten it as its values may be of some [list-like] classes, which will be
			#     [unlist]ed in addition even when [recursive = FALSE]. Tested on [R 4.0.2]
			#[3] There is another expression for this: {v_out <- eval(rlang::expr(c(!!!v_out)))}, but it is less primitive
			#     or efficient
			if (length(x) != 1) {
				if (all(chk_vec)) v_out <- do.call(c, v_out)
			}
			else {
				v_out <- v_out[[1]]
			}

			#999. Determine the output
			return(v_out)
		}
	)

	#700. Assign the names to the result
	names(rstOut) <- in_names

	#800. Return a single value if the input only has one element
	if ((length(dots) == 1) & is.null(in_names)) return(rstOut[[1]])

	#999. Return the data frame
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Execute a script with a simple process
		aa <- 1
		bb <- 3
		v_dict <- list('testvar1' = 'aa' , 'testvar2' = 'ee')
		v_list <- list('ff', 'bb')
		gg <- data.frame(a=1)

		testf <- function(){
			aa <- 2
			v_rst2 <- get_values(c(v_list, v_dict), inplace = F)
			print(get('aa', mode = 'any'))
			print(v_rst2)
		}
		testg <- function(){
			bb <- 7
			testf()
		}
		testg()
		testf()

		#300. Test output with only one input value
		print( get_values('aa') )
		print( get_values('testprint1' = 'gg') )

		#400. Test output with only positional arguments
		print( get_values(v_list) )

		#700. Test real case
		fTrans <- list(
			'&c_date\\.' = 'G_d_curr'
			,'&L_curdate\\.' = 'G_d_curr'
			,'&L_curMon\\.' = 'G_m_curr'
			,'&L_prevMon\\.' = 'G_m_prev'
		)
		G_d_curr <- '20160310'
		G_m_curr <- substr(G_d_curr,1,6)

		get_list_val <- get_values(fTrans)
		print(get_list_val)

		#800. Test when the variable names are stored in a data.frame
		v_df <- data.frame(vars = c('aa', 'ee'), stringsAsFactors = F)
		testseries <- get_values(v_df[['vars']])
		testseries2 <- get_values(v_df[['vars']], inplace = F)

	}
}
