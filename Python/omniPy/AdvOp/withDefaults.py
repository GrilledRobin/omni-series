#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
# from inspect import signature
from functools import wraps
from omniPy.AdvOp import nameArgsByFormals, modifyDict, simplifyDeco

@simplifyDeco
def withDefaults(
    f__ : callable
    ,*pos_
    ,**kw_
) -> callable:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to set default values of all kinds of arguments for the dedicated callable, so that the caller program   #
#   | can only provide the necessary parameters during the call                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When the same defaults exist in both <pos_> (will be identified by position) and <kw_>, the one in <pos_> will be used,        #
#   |     following Python syntax at parameter interpretation                                                                           #
#   |[2] If any positional argument is required to set default value, all arguments before its position should have defaults as well or #
#   |     provided during the function call, otherwise the call fails due to missing input for positional argument (instead of missing  #
#   |     default value, following Python syntax)                                                                                       #
#   |[3] Priority of final input for any POSITIONAL_ONLY argument is as below, from high to low:                                        #
#   |    [1] Value passed in <pos> for the call of <f__>                                                                                #
#   |    [2] Value passed in <kw> for the call of <f__>                                                                                 #
#   |    [3] Default value set in <pos_> at the wrapping stage of <f__>                                                                 #
#   |    [4] Default value set in <kw_> at the wrapping stage of <f__>                                                                  #
#   |[4] Other kinds of arguments have the same priority levels, after <f__> is wrapped.                                                #
#   |[5] In this way, the wrapped <f__> accepts all kinds of parameter input, e.g. only provide <**kw> during the call                  #
#   |[6] If any positional argument is provided a default value by this function, all those on the right side to this one               #
#   |     without-defaults-in-signature must be provided in KEYWORD pattern, when <f__> should be called with the default value of this #
#   |     one, otherwise it is never used as indicated by Python syntax                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Standardized call of a series of callables or APIs with default values set for certain group of arguments                      #
#   |[2] Wrap the callable to enable default value provision and keyword input for POSITIONAL_ONLY arguments, without having to change  #
#   |     the internal code of the original one                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |f__         :   <callable >callable to be wrapped                                                                                  #
#   |pos_        :   <tuple    >VAR_POSITIONAL inputs to set the defaults of the positional arguments for <f__>                         #
#   |kw_         :   <dict     >VAR_KEYWORD inputs to set the defaults of the keyword arguments for <f__>                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>  :   The wrapped callable which accepts all kinds of parameter input during the call                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250115        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |functools                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |nameArgsByFormals                                                                                                          #
#   |   |   |simplifyDeco                                                                                                               #
#   |   |   |modifyDict                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #020. Local environment
    # arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']

    #050. Retrieve the signature of the callable
    #[ASSUMPTION]
    #[1] Python evaluates the parameters passed for the call of a function in the priority as listed in <arg_kind>
    #[2] If <VAR_POSITIONAL> exists in the signature:
    #    [1] Given no extra positional parameter is passed, the <POSITIONAL_OR_KEYWORD> arguments before <VAR_POSITIONAL> can be
    #         passed in a keyword format
    # sig_raw = signature(f__).parameters.values()
    # sig_bykind = {
    #     n : {
    #         i : s
    #         for i,s in enumerate(sig_raw)
    #         if s.kind == s.__getattribute__(n)
    #     }
    #     for n in arg_kind
    # }

    #100. Identify arguments on different purposes
    #110. Identify the arguments that can be assigned defaults in positional pattern
    #[ASSUMPTION]
    #[1] We have to match the defaults with the positions as provided, hence the precise sequence of arguments that accept positional
    #     inputs will be deemed as candidates for our manipulation
    # sig_def_pos = (
    #     sig_bykind['POSITIONAL_ONLY']
    #     | sig_bykind['POSITIONAL_OR_KEYWORD']
    # )
    # len_sig_pos = len(sig_def_pos)

    #120. Identify the arguments that can be assigned defaults in keyword pattern
    # sig_def_kw = (
    #     sig_bykind['POSITIONAL_ONLY']
    #     | sig_bykind['POSITIONAL_OR_KEYWORD']
    #     | sig_bykind['KEYWORD_ONLY']
    # )
    # names_kw = [ s.name for s in sig_def_kw.values() ]

    #500. Reshape the defaults to fill the respective holes in the signature
    def_pos, def_kw = nameArgsByFormals(f__, pos_, kw_, coerce_ = True, strict_ = False)
    len_def_pos = len(def_pos)

    #800. Define the wrapper to translate the call
    @wraps(f__)
    def wrapper(*pos, **kw):
        #100. Reshape the inputs to fill the respective holes in the signature
        pos_in, kw_in = nameArgsByFormals(f__, pos, kw, coerce_ = True, strict_ = False)
        len_pos_in = len(pos_in)

        #300. Determine the final positional inputs
        #[ASSUMPTION]
        #[1] Till this step, only those defaults and inputs that cannot be translated into keywords are gathered
        #[2] Following Python syntax, these inputs should fill the holes from left to right with no skip
        #[3] We simply need to match them by position and determine the priority
        len_pos_new = min(len_pos_in, len_def_pos)
        pos_new = pos_in[:len_pos_new] + (pos_in if len_pos_in > len_def_pos else def_pos)[len_pos_new:]

        #350. Restrict the input logic
        #[ASSUMPTION]
        #[1] Some ideas indicate that if no extra positional parameter is passed to <pos>, we could skip the entire <pos> input,
        #     regardless of whether there are defaults set for items in <pos>
        #[2] We do not satisfy such indication and leave the decision to the caller program
        #[3] That is, if any defaults are set for <pos>, we assume that the caller needs to use them on intention; otherwise
        #     there is no reason to set them in the first place
        # if len_pos_in <= len_sig_pos:
        #     pos_new = pos_new[:len_sig_pos]

        #500. Determine the final keyword inputs
        #[ASSUMPTION]
        #[1] For the same reason as above, we do not make complicated logic
        kw_new = modifyDict(def_kw, kw_in)
        # kw_extra = { k:v for k,v in kw_in.items() if k not in names_kw }
        # if kw_extra:
        #     kw_new = modifyDict(def_kw, kw_in)
        # else:
        #     kw_new = modifyDict({ k:v for k,v in def_kw.items() if k in names_kw }, kw_in)

        #800. Reshape the inputs again to validate whether there are still arguments without inputs where required
        pos_rst, kw_rst = nameArgsByFormals(f__, pos_new, kw_new, coerce_ = True, strict_ = True)

        return(f__(*pos_rst, **kw_rst))

    return(wrapper)
#End withDefaults

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import withDefaults

    #050. Define a universal function to print the private environment
    def printEnv():
        frame = sys._getframe(1)
        getvar = frame.f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print('[{0}]=[{1}]'.format(v,str(frame.f_locals.get(v))))

    #100. Define the function with all kinds of arguments
    @withDefaults(99, arg2 = 98, arg6 = 94, arg8 = 92, arg9 = 91)
    def testf_fullargs(arg1, arg2, /, arg3, arg4 = 4, *pos, arg6, arg7 = 7, **kw):
        printEnv()

    #110. Function with VAR_POSITIONAL
    @withDefaults(99,98,97,96,95,94)
    def testf_varpos(arg1, arg2, /, arg3, arg4 = 4, *pos, arg6):
        printEnv()

    #130. Function only with POSITIONAL_ONLY
    #[ASSUMPTION]
    #[1] This decorator is decorated by <simplifyDeco>, which makes it a parametric decorator, although it does not look like
    #     a double-wrapper
    #[2] Normal way to call a parametric decorator (i.e. accepting arguments) is: f2 = withDefaults(*pos,**kw)(f1)
    @withDefaults
    def testf_pos_only(arg1, arg2, /):
        printEnv()

    #200. Test the default values
    #210. Provide less parameters than required
    #[ASSUMPTION]
    #[1] <arg1> has default value, but it is never used unless we provide ALL the rest arguments in keyword pattern
    #[2] We have to provide <arg3> in keyword pattern, otherwise the value will be filled into <arg2> position and thus lead to
    #     the exception of missing input for <arg3>
    testf_fullargs(1, arg3 = 3)
    # [arg1]=[1]
    # [arg2]=[98]
    # [arg3]=[3]
    # [arg4]=[4]
    # [arg6]=[94]
    # [arg7]=[7]
    # [pos]=[()]
    # [kw]=[{'arg8': 92, 'arg9': 91}]

    #220. Missing necessary inputs
    testf_fullargs()
    # TypeError: [nameArgsByFormals]Missing input for POSITIONAL_OR_KEYWORD argument: ['arg3']

    #230. Provide extra keywords
    testf_fullargs(arg3 = 3, arg9 = 9)
    # [arg1]=[99]
    # [arg2]=[98]
    # [arg3]=[3]
    # [arg4]=[4]
    # [arg6]=[94]
    # [arg7]=[7]
    # [pos]=[()]
    # [kw]=[{'arg8': 92, 'arg9': 9}]

    #250. Provide extra positional parameters
    testf_varpos(1, 2, 3, 4, 5, arg6 = 6)
    # [arg1]=[1]
    # [arg2]=[2]
    # [arg3]=[3]
    # [arg4]=[4]
    # [arg6]=[6]
    # [pos]=[(5, 94)]

    #300. Enable keyword inputts for POSITIONAL_ONLY function
    testf_pos_only(arg2 = 2, arg1 = 1)
    # [arg1]=[1]
    # [arg2]=[2]
#-Notes- -End-
'''
