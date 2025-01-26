#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature, Parameter
from typing import Any
from collections import OrderedDict
from collections.abc import Iterable

def nameArgsByFormals(
    func : callable = lambda: None
    ,pos_ : Iterable = tuple()
    ,kw_ : dict[str, Any] = {}
    ,coerce_ : bool = True
    ,strict_ : bool = False
) -> tuple[tuple[Any], dict[str, Any]]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to try to assign proper names for the parameters provided BEFORE calling a function                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Coerce the POSITIONAL_OR_KEYWORD arguments provided for the dynamic call to functions                                          #
#   |[2] Remove the name of the keyword provision of a positional argument and place it at the correct position as final input          #
#   |[3] Enable provision in keyword format for POSITIONAL_ONLY arguments with a proper wrapping                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |func        :   <callable >Function from which to extract the formals for evaluation                                               #
#   |                [<see def.>  ] <Default> Simple function for testing                                                               #
#   |                [function    ]           Function that has various signatures                                                      #
#   |pos_        :   <tuple    >Positional parameters to be transformed for the call to <func>                                          #
#   |                [<see def.>  ] <Default> Empty tuple for processing                                                                #
#   |kw_         :   <dict     >Keyword parameters to be transformed for the call to <func>                                             #
#   |                [<see def.>  ] <Default> Empty dict for processing                                                                 #
#   |coerce_     :   Whether to try to remove excessive arguments silently (This is the only naming convention accepted by Python and R)#
#   |                [True        ] <Default> Remove excessive arguments                                                                #
#   |                [False       ]           Raise exceptions under certain situations                                                 #
#   |strict_     :   Whether to allow less inputs than those arguments without defaults                                                 #
#   |                [False       ] <Default> Allow less inputs than the arguments without defaults                                     #
#   |                [True        ]           Raise exception when less inputs are passed than required                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[tuple]     :   tuple[tuple, dict] of (preferably keyword) parameters for a correct syntax in the future function call. If <*pos>  #
#   |                 or <**kw> exists in the signature of <func>, extra positional/keyword parameters are also included                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250112        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, inspect, typing, collections                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer

    #020. Local environment
    #[ASSUMPTION]
    #[1] We may need to modify the containers of the input parameter, hence we make copies of them
    #[2] We avoid using <copy.copy()> as there could be unknow reference types
    #[3] Below statements safely create copies of the original objects
    pos_in = [ i for i in pos_ ]
    kw_in = { k:v for k,v in kw_.items() }
    arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']

    #100. Helper functions
    #110. Function to extract the parameters in a standard format
    def h_extract(
        sig : dict[str, dict[int, Parameter]]
        ,kind : str
        ,pos_ : list
        ,kw_ : dict
    ) -> tuple[int, dict[int, Parameter]]:
        #100. Verify the size of the containers
        len_sig = len(sig[kind])
        sig_reorder = { i:sig[kind].get(v) for i,v in enumerate(sorted(sig[kind].keys())) }
        len_pos = len(pos_)
        len_pos_trans = min(len_sig, len_pos)

        #200. Determine the positional parameters to be involved
        #[ASSUMPTION]
        #[1] Python allows slicing from an empty list
        pos_trans = { i : {'name' : sig_reorder.get(i).name, 'value' : v} for i,v in enumerate(pos_[:len_pos_trans]) }

        #300. Determine the keywords to be translated
        kw_trans = { i:{'name' : s.name, 'value' : kw_in[s.name]} for i,s in sig_reorder.items() if s.name in kw_in }

        #400. Identify the excessively provided parameters
        kw_extra = { k:v for k,v in kw_trans.items() if k in pos_trans }

        #490. Raise exception if not silent and there are excessive parameters passed
        if not coerce_:
            if kw_extra:
                plural = '' if len(kw_extra) == 1 else 's'
                err_msg = [ v['name'] for v in kw_extra.values() ]
                raise TypeError(f'[{LfuncName}]Multiple input for {kind} argument{plural}: {str(err_msg)}')

        #500. Prepare the candidates for translation
        cand_trans = { **pos_trans, **{ k:v for k,v in kw_trans.items() if k not in kw_extra } }

        #600. Identify the arguments without defaults and without inputs as well
        #[ASSUMPTION]
        #[1] Both POSITIONAL_OR_KEYWORD and KEYWORD_ONLY can have arguments WITH or WITHOUT defaults
        #[1] Within POSITIONAL_OR_KEYWORD, arguments WITHOUT defaults are always to the left of those WITH defaults
        #[1] Within KEYWORD_ONLY, arguments WITHOUT defaults can be to the right of those WITH defaults
        sig_no_default = { i:s for i,s in sig_reorder.items() if s.default is s.empty }

        #690. Raise exception if not all these arguments have inputs
        #[ASSUMPTION]
        #[1] It makes no sense to coerce the output as it is required to provide them all
        if strict_:
            if cand_miss:= [ s.name for i,s in sig_no_default.items() if i not in cand_trans ]:
                plural = '' if len(cand_miss) == 1 else 's'
                raise TypeError(f'[{LfuncName}]Missing input for {kind} argument{plural}: {str(cand_miss)}')

        #900. Sort the output
        #[ASSUMPTION]
        #[1] Since the length of the involved items inside <pos_> is required by other process, we need to export it
        #[2] To ensure the sequence of the parameters, we have to iterate in an ordinal way
        return(len_pos_trans, OrderedDict({ i:cand_trans.get(v) for i,v in enumerate(sorted(cand_trans.keys())) }))

    #200. Retrieve the signature of the callable
    #[ASSUMPTION]
    #[1] Python evaluates the parameters passed for the call of a function in the priority as listed in <arg_kind>
    sig_raw = signature(func).parameters.values()
    sig_bykind = {
        n : {
            i : s
            for i,s in enumerate(sig_raw)
            if s.kind == s.__getattribute__(n)
        }
        for n in arg_kind
    }
    #[ASSUMPTION]
    #[1] Actually there could only be at most 1 VAR_POSITIONAL argument in the signature of a callable, same as VAR_KEYWORD
    has_pos_var = len(sig_bykind['VAR_POSITIONAL']) == 1
    has_kw_var = len(sig_bykind['VAR_KEYWORD']) == 1

    #300. Prepare <POSITIONAL_ONLY> parameters
    #[ASSUMPTION]
    #[1] Look for the items inside <pos_in>
    #[2] If there are still some missing input, we look for them inside <kw_in>, and thus remove them from <kw_in>
    #[3] If there are 3 <POSITIONAL_ONLY> arguments <arg1,arg2,arg3>, while <pos_in> has 2 and <kw_in> has a name <arg2>, we will
    #     raise exception of multiple inputs for <arg2>, as we follow Python syntax to validate <pos_in> as top priority, similar
    #     as all the rest validations
    len_pos_only, out_pos_only = h_extract(sig_bykind, 'POSITIONAL_ONLY', pos_in, kw_in)

    #390. Remove these parameters from the input pool
    pos_in = pos_in[len_pos_only:]
    kw_in = { k:v for k,v in kw_in.items() if k not in [ v['name'] for v in out_pos_only.values() ] }

    #400. Handle POSITIONAL_OR_KEYWORD and VAR_POSITIONAL together
    len_pos_in = len(pos_in)
    len_pk_pos_in, out_pk_pre = h_extract(sig_bykind, 'POSITIONAL_OR_KEYWORD', pos_in, kw_in)

    #420. Reorder the POSITIONAL_OR_KEYWORD to match the internal process
    sig_pk_reorder = {
        i:sig_bykind['POSITIONAL_OR_KEYWORD'].get(v)
        for i,v in enumerate(sorted(sig_bykind['POSITIONAL_OR_KEYWORD'].keys()))
    }
    len_pk = len(sig_pk_reorder)

    #470. Differ the process
    #[ASSUMPTION]
    #[1] If and only if the updated <len_pos_in> is larger than <len_pk>, should we remove the names of POSITIONAL_OR_KEYWORD
    #     inputs (i.e. make them positional), to ensure the rest parameters fill in VAR_POSITIONAL
    #[2] In all other cases we ensure everyone input parameter have its correct name
    #[3] When the program comes here, all the required positional parameters already have their relative positions correctly ordered,
    #     although their sequence IDs may not be continuous
    out_pk_unnamed = {}
    out_pk_named = {}
    out_pos_var = {}
    if (len_pos_in > len_pk) and has_pos_var:
        #300. Identify the missing inputs for the POSITIONAL_OR_KEYWORD with defaults
        #[ASSUMPTION]
        #[1] In such case, all POSITIONAL_OR_KEYWORD should be provided in positional pattern, including those WITH defaults
        #[2] Actually below exception is never triggered
        if strict_:
            if pk_miss := [ s.name for i,s in sig_pk_reorder.items() if i not in out_pk_pre ]:
                plural = '' if len(pk_miss) == 1 else 's'
                raise TypeError(
                    f'[{LfuncName}]Missing input in positional pattern for POSITIONAL_OR_KEYWORD argument{plural}: {str(pk_miss)}'
                )

        #900. Output
        #[ASSUMPTION]
        #[1] Till this step, all the POSITIONAL_OR_KEYWORD have been provided with correct sequence
        out_pk_unnamed = out_pk_pre
        out_pos_var = { i : {'name' : 'pos', 'value' : v} for i,v in enumerate(pos_in[len_pk:]) }
    else:
        out_pk_named = out_pk_pre

    #490. Remove these parameters from the input pool
    pos_in = pos_in[len_pk_pos_in:][len(out_pos_var):]
    kw_in = { k:v for k,v in kw_in.items() if k not in [ v['name'] for v in out_pk_pre.values() ] }

    #600. Handle KEYWORD_ONLY cases
    #[ASSUMPTION]
    #[1] Till this step, <pos_in> may still have items, we fill them into KEYWORD_ONLY before we identify them in <kw_in>, following
    #     Python syntax
    len_pos_in = len(pos_in)
    len_kw_only_pos_in, out_kw_only = h_extract(sig_bykind, 'KEYWORD_ONLY', pos_in, kw_in)
    len_kw_only = len(out_kw_only)

    #609. Raise exception if not silent and there are excessive inputs
    if not coerce_:
        if (pos_err := (len_pos_in - len_kw_only)) > 0:
            plural = '' if pos_err == 1 else 's'
            raise TypeError(
                f'[{LfuncName}]{pos_err} excessive positional input{plural} for the function call!'
            )

    #690. Remove these parameters from the input pool
    pos_in = pos_in[len_kw_only_pos_in:]
    kw_in = { k:v for k,v in kw_in.items() if k not in [ v['name'] for v in out_kw_only.values() ] }

    #700. Handle VAR_KEYWORD case
    #710. Prepare the input in proper convention as above
    #[ASSUMPTION]
    #[1] Till this step, <pos_in> should be empty
    out_kw_var_pre = { i : {'name' : list(kw_in.keys())[i], 'value' : list(kw_in.values())[i]} for i in range(len(kw_in)) }

    #740. Identify the excessively provided parameters
    kw_extra = { k:v for k,v in out_kw_var_pre.items() if v['name'] not in [ s.name for s in sig_bykind['KEYWORD_ONLY'].values() ] }

    #780. Differentiate the process
    if has_kw_var:
        out_kw_var = out_kw_var_pre
    else:
        #009. Raise exception if not silent and there are excessive parameters passed
        if not coerce_:
            if (len_kw_extra := len(kw_extra)) > 0:
                plural = '' if len_kw_extra == 1 else 's'
                err_msg = [ v['name'] for v in kw_extra.values() ]
                raise TypeError(f'[{LfuncName}]{len_kw_extra} excessive keyword input{plural} for the function call: {str(err_msg)}')

        #500. Eliminate the excessive inputts
        out_kw_var = { k:v for k,v in out_kw_var_pre.items() if k not in kw_extra }

    #900. Combine the results
    #[ASSUMPTION]
    #[1] We cannot simply combine the results as they share common keys
    rst_pos = (
        tuple( s['value'] for s in out_pos_only.values() )
        + tuple( s['value'] for s in out_pk_unnamed.values() )
        + tuple( s['value'] for s in out_pos_var.values() )
    )
    rst_kw = {
        **{ s['name']:s['value'] for s in out_pk_named.values() }
        ,**{ s['name']:s['value'] for s in out_kw_only.values() }
        ,**{ s['name']:s['value'] for s in out_kw_var.values() }
    }

    return(rst_pos, rst_kw)
#End nameArgsByFormals

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    from inspect import signature
    from functools import wraps
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import nameArgsByFormals, modifyDict, simplifyDeco

    #050. Define a universal function to print the private environment
    def printEnv():
        frame = sys._getframe(1)
        getvar = frame.f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print('[{0}]=[{1}]'.format(v,str(frame.f_locals.get(v))))

    #100. Define the function with all kinds of arguments
    def testf_fullargs(arg1, arg2, /, arg3, arg4 = 4, *pos, arg6, arg7 = 7, **kw):
        printEnv()

    #110. Function without VAR_POSITIONAL
    def testf_no_varpos(arg6, arg7 = 7, **kw):
        printEnv()

    #130. Function only with keywords
    def testf_kw_only(*, arg6, arg7 = 7, **kw):
        printEnv()

    #140. Function without VAR_KEYWORD
    def testf_no_varkw(*, arg6, arg7 = 7):
        printEnv()

    #200. Test by coercing the possible errors
    #201. Provide less parameters than required
    #[ASSUMPTION]
    #[1] By default <strict_ == False>, hence less inputs are allowed
    nameArgsByFormals(testf_fullargs, (1,), coerce_ = True)
    # ((1,), {})

    #[ASSUMPTION]
    #[1] Provision of (5,6) are captured by <*pos>
    nameArgsByFormals(testf_fullargs, (1,2,3,4,5,6), coerce_ = True)
    # ((1, 2, 3, 4, 5, 6), {})

    #210. Provide sufficient parameters with multiple inputs
    #[ASSUMPTION]
    #[1] Do not have to provide input for those with defaults
    #[2] When there is no VAR_POSITIONAL or no extra positional parameters are provided for it, we can provide input for
    #     POSITIONAL_OR_KEYWORD in a keyword pattern
    #[3] We can directly use the output result as the inputs for the function call
    prov1 = nameArgsByFormals(testf_fullargs, (1,2,3), {'arg1' : 10, 'arg6' : 6}, coerce_ = True)
    # ((1, 2), {'arg3': 3, 'arg6': 6})
    testf_fullargs(*prov1[0], **prov1[1])
    # [arg1]=[1]
    # [arg2]=[2]
    # [arg3]=[3]
    # [arg4]=[4]
    # [arg6]=[6]
    # [arg7]=[7]
    # [pos]=[()]
    # [kw]=[{}]

    #215. Provide all required parameters in keyword pattern
    #[ASSUMPTION]
    #[1] In this way, we can set defaults for all kinds of arguments in a keyword pattern
    prov1_1 = nameArgsByFormals(testf_fullargs, kw_ = {'arg3' : 3, 'arg2' : 2, 'arg1' : 10, 'arg6' : 6}, coerce_ = True)
    # ((10, 2), {'arg3': 3, 'arg6': 6})

    #220. Provide excessive parameters given there is no VAR_POSITIONAL
    #[ASSUMPTION]
    #[1] All parameters are translated into keyword pattern
    #[2] Excessive positional parameters are eliminated in silence
    #[3] If the same argument is passed multiple times, the one in <pos_> is taken for top priority
    prov2 = nameArgsByFormals(testf_no_varpos, (6,7,8), {'arg1' : 1, 'arg6' : 10}, coerce_ = True)
    # ((), {'arg6': 6, 'arg7': 7, 'arg1': 1})

    #230. Provide excessive parameters given there is KEYWORD_ONLY while no VAR_POSITIONAL
    #[ASSUMPTION]
    #[1] All parameters except POSITIONAL_ONLY are translated into keyword pattern
    prov3 = nameArgsByFormals(testf_kw_only, (6,7,8), coerce_ = True)
    # ((), {'arg6': 6, 'arg7': 7})

    #300. Examples to enable various fashions of function call
    #310. Simulate <forceAndCall> in R with more flexibility, i.e. we can force arguments at every position or keyword
    @simplifyDeco
    def forceArgs(fn : callable, *pos_, **kw_):
        arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']
        sig_raw = signature(fn).parameters.values()
        sig_bykind = {
            n : {
                i : s
                for i,s in enumerate(sig_raw)
                if s.kind == s.__getattribute__(n)
            }
            for n in arg_kind
        }

        #[ASSUMPTION]
        #[1] If <pos_> is provided, its elements should fill the holes from left to right
        #[2] Hence we also extract arguments in the same sequence from the signature for replacement
        sig_def_pos = (
            sig_bykind['POSITIONAL_ONLY']
            | sig_bykind['POSITIONAL_OR_KEYWORD']
        )
        len_sig_pos = len(sig_def_pos)

        sig_def_kw = (
            sig_bykind['POSITIONAL_ONLY']
            | sig_bykind['POSITIONAL_OR_KEYWORD']
            | sig_bykind['KEYWORD_ONLY']
        )
        names_kw = [ s.name for s in sig_def_kw.values() ]

        def_pos, def_kw = nameArgsByFormals(fn, pos_, kw_, coerce_ = True, strict_ = False)
        len_def_pos = len(def_pos)

        @wraps(fn)
        def wrapper(*pos, **kw):
            pos_in, kw_in = nameArgsByFormals(fn, pos, kw, coerce_ = True, strict_ = False)
            len_pos_in = len(pos_in)

            #[ASSUMPTION]
            #[1] We only set the default values for VAR_POSITIONAL when there is extra inputs during the function call
            len_pos_new = min(len_pos_in, len_def_pos)
            pos_new = def_pos[:len_pos_new] + (pos_in if len_pos_in > len_def_pos else def_pos)[len_pos_new:]
            if len_pos_in <= len_sig_pos:
                pos_new = pos_new[:len_sig_pos]

            #[ASSUMPTION]
            #[1] We only set the default values for VAR_KEYWORD when there is extra inputs during the function call
            kw_extra = { k:v for k,v in kw_in.items() if k not in names_kw }
            if kw_extra:
                kw_new = modifyDict(kw_in, def_kw)
            else:
                kw_new = modifyDict(kw_in, { k:v for k,v in def_kw.items() if k in names_kw })

            pos_rst, kw_rst = nameArgsByFormals(fn, pos_new, kw_new, coerce_ = True, strict_ = True)

            return(fn(*pos_rst, **kw_rst))

        return(wrapper)

    #320. Define a function with several arguments forced
    @forceArgs(99,98,97,96,arg3 = 95,arg5 = 94)
    def testf_force(arg1, /, arg2, *pos, arg3, arg4, **kw):
        printEnv()

    #321. Call the function with some inputs
    #[ASSUMPTION]
    #[1] <arg3> is KEYWORD_ONLY and yet we do not have to provide it, as it has a forced value
    #[2] Since there is no extra input, <pos> and <kw> are both empty, even if there are forced items as we defined
    testf_force(1,2,arg4 = 4)
    # [arg1]=[99]
    # [arg2]=[98]
    # [arg3]=[95]
    # [arg4]=[4]
    # [pos]=[()]
    # [kw]=[{}]

    #322. Call the function with even less inputs
    #[ASSUMPTION]
    #[1] When provided as keywords, the sequence does not matter
    testf_force(arg4 = 4, arg2 = 2)
    # [arg1]=[99]
    # [arg2]=[98]
    # [arg3]=[95]
    # [arg4]=[4]
    # [pos]=[()]
    # [kw]=[{}]

    #323. Call the function with excessive inputs
    #[ASSUMPTION]
    #[1] If at least one <pos> is provided, all the defaults for it will be extracted, unless the provision is more
    testf_force(1,2,3,arg4 = 4,arg5 = 5)
    # [arg1]=[99]
    # [arg2]=[98]
    # [arg3]=[95]
    # [arg4]=[4]
    # [pos]=[(97, 96)]
    # [kw]=[{'arg5': 94}]

    testf_force(1,2,3,4,5,arg4 = 4)
    # [arg1]=[99]
    # [arg2]=[98]
    # [arg3]=[95]
    # [arg4]=[4]
    # [pos]=[(97, 96, 5)]
    # [kw]=[{}]

    #324. Do not provide <arg4> while there is no default value for it
    testf_force(1,2,3,4,5)
    # TypeError: [nameArgsByFormals]Missing input for KEYWORD_ONLY argument: ['arg4']

    #400. Test of POSITIONAL_ONLY
    #410. Provide less parameters than required and verify in a strict way
    #[ASSUMPTION]
    #[1] Exceptions will be raised if missing input for any argument without defaults
    #[2] Such exceptions will not be ignored given <strict_ == True>
    nameArgsByFormals(testf_fullargs, (1,), coerce_ = False, strict_ = True)
    # TypeError: [nameArgsByFormals]Missing input for POSITIONAL_ONLY argument: ['arg2']

    #420. Provide <arg1> in positional pattern, and <arg2> in keyword pattern
    #[ASSUMPTION]
    #[1] <kw_> are used to look for the missing inputs in <pos_> in advance
    nameArgsByFormals(testf_fullargs, (1,), {'arg2' : 2}, coerce_ = False, strict_ = True)
    # TypeError: [nameArgsByFormals]Missing input for POSITIONAL_OR_KEYWORD argument: ['arg3']

    #430. Provide multiple values for the same arguments
    #[ASSUMPTION]
    #[1] POSITIONAL_ONLY is verified at the earliest, hence even when <arg3> has multiple inputs, we only raise exception for <arg2>
    nameArgsByFormals(testf_fullargs, (1,2,3), {'arg3' : 30, 'arg2' : 20}, coerce_ = False)
    # TypeError: [nameArgsByFormals]Multiple input for POSITIONAL_ONLY argument: ['arg2']

    #600. Test of VAR_POSITIONAL
    #630. Provide extra positional inputs given there is no VAR_POSITIONAL
    nameArgsByFormals(testf_no_varpos, (6,7,8), {'arg1' : 1}, coerce_ = False)
    # TypeError: [nameArgsByFormals]1 excessive positional input for the function call!

    #800. Test of VAR_KEYWORD
    #830. Provide extra positional inputs given there is no VAR_KEYWORD
    nameArgsByFormals(testf_no_varkw, (6,), {'arg1' : 1}, coerce_ = False)
    # TypeError: [nameArgsByFormals]1 excessive keyword input for the function call: ['arg1']
#-Notes- -End-
'''
