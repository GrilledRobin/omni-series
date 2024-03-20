#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create or assign values to multiple variables at the same time within current frame/environment       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 当一个function有很多参数且用户需要调试它的[部分]功能时，可用此function以[等价于调用它的方式]对它的参数一次性赋值，参见示例     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...        :   Various named parameters, whose [names] will be used to create variables while [values] will be assigned to them    #
#   |frame      :   <frame> object in which to create the variables                                                                     #
#   |               [see def.   ] <Default> Create the variables in the caller frame                                                    #
#   |               [frame      ]           Dedicated <frame> in which to create the variables                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[NULL]     :   This function does not return values                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210125        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240203        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <frame> to enable subtle control on the destination of created variables                             #
#   |      |[2] In <R == 4.1.1>, <rlang::flatten_if> issues warning message even if the argument <predicate> returns FALSE, hence we set#
#   |      |     the verification ahead of it to suppress the warning                                                                   #
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
#   |   |rlang, purrr, vctrs, glue                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, purrr, vctrs, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

gen_locals <- function(..., frame = sys.frame()){
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
	if (is_flattenable(dots)) dots <- rlang::flatten_if(dots, is_flattenable)
	dots <- purrr::discard(dots, is.null)
	in_names <- names(dots)

	#500. Batch create variables in the caller frame
	sapply(
		seq_along(dots)
		,function(i){
			#Here [sys.frame()] represents the frame of the caller program.
			assign( in_names[[i]], dots[[i]], pos = frame )
		}
	)

	#999. Return NULL and prevent the log to print a [NULL] result
	invisible()
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Test a list for variable creation
		v_dict <- list(
			aa = '1'
			,bb = 2
		)
		gen_locals( v_dict )
		message(glue::glue('aa={aa}'))
		# aa=1

		gen_locals(cc=3)
		message(glue::glue('cc={cc}'))
		# cc=3

		myfunc <- function(){
			curr_frame <- sys.frame()

			func1 <- function(){
				gen_locals(dd=4, frame = curr_frame)
			}
			func1()

			message(glue::glue('dd={dd}'))

			func2 <- function(){
				message(glue::glue('dd+1={dd+1}'))

				#Create variable in the top-most frame
				ifr <- 1
				while (T) {
					frame <- parent.frame(ifr)
					if (environmentName(frame) == 'R_GlobalEnv') break
					ifr <- ifr + 1
				}
				gen_locals(ee=6, frame = frame)
			}
			func2()
		}
		myfunc()

		#Test result: all assignments in the lower call stacks have been recycled
		message(glue::glue('dd={dd}'))
		# dd=4

		#Find the variable created in the highest stack
		message(get_values('ee'))
		# 6

		#800. Assign values to below variables
		#It is the same method to call the functions you designed, so just copy all the parameters here
		# to enable the partial test of the internal scripts in your function.
		#[IMPORTANT] Remember to add names to all positional parameters before you call this function.
		gen_locals(
			keyvar = c('nc_cifno','nc_acct_no')
			,SetAsBase = 'k'
			,fImp.opt = list(
				SAS = list(
					encoding = 'GB2312'
				)
			)
			,.parallel = T
			,cores = 4
			,fDebug = F
		)

		typeof(fImp.opt)

	}
}
