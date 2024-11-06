#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import types
import pandas as pd
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from functools import partial

def wrapAsGroupedFunc(
    fn : callable
    ,/
    ,*pos
    ,_wagf_df_ : str = 'df'
    ,**kw
) -> callable:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to wrap the provided function with extra argument, so that it can be impplemented in <pd.GroupBy.agg> and#
#   | <pd.pivot_table> to facilitate multi-variable aggregation in a multi-dimensional process                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The most popular usage is to enable Weighted Average calculation in a pivot table, see the examples for detailed usage         #
#   |[2] Extensive usage can be Conditional Aggregation using extra dimensions as companion input, e.g. resemble SUMIF in a pivot table #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Concept:                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] In order to make it available as a customized aggregation function in <pd.GroupBy.agg> or <pd.pivot_table>, you (previously)   #
#   |     need to define the function in below fashion                                                                                  #
#   |    [a] Setup a positional argument annotated as <pd.Series | pd.Index> at the very first position                                 #
#   |    [b] Make a <df.reindex> to slice the <df> before calculation                                                                   #
#   |    [c] During the call of <pd.GroupBy.agg> or <pd.pivot_table>, make it a partial function with all other arguments provided as   #
#   |         the dedicated values                                                                                                      #
#   |    [d] The return value must be a single scalar, repensenting a single cell in the pivot table                                    #
#   |[2] Now we wrap these functionalities for you, so that you do not need to think of the mechanism to realize it                     #
#   |[3] Your focus can be set on realizing the complex aggregation on an intact dataframe, so that the wrapper applies it to every     #
#   |     slice of the same dataframe given various grouping conditions                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Important:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Despite of its definition, the wrapper is NOT a decorator, but a high order function                                           #
#   |[2] The wrapper extends the entire signature of <fn>, so it is far beyond "decorating" it                                          #
#   |[3] This is proven by that it should be called every time by providing different arguments to enable different functionalities,    #
#   |     which are extended from the wrapped function                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fn          :   The callable to be wrapped / converted into a new one, which contains a new invisible positional argument at the   #
#   |                 first position of its signature                                                                                   #
#   |                [callable        ]           Only accept types.FunctionType, i.e. not implemented for Class Initializer            #
#   |pos         :   Various positional arguments to pass during the call of <fn> (rather than defined in <fn>)                         #
#   |_wagf_df_   :   Name of the argument defined in the signature of <fn>                                                              #
#   |                [df              ] <Default> Usually use this name as an argument in <fn>                                          #
#   |                [ <str>          ]           Actual name of the dedicated argument that represents an input dataframe in <fn>      #
#   |                                             [1] It is ignored if <df> is designed to be picked up in variant positional args      #
#   |                                             [2] It should be provided if <df> is designed to be picked up from variant keyword    #
#   |                                                  args using a different name as <df>                                              #
#   |kw          :   Various keyword arguments to pass during the call of <fn> (rather than defined in <fn>)                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>  :   Wrapped function with below feature                                                                                #
#   |                [1] One extra positional argument <_wagf_obj_> at the first position in signature. We make it relatively unique to #
#   |                     avoid conflict                                                                                                #
#   |                [2] Mutate any provision of argument named as <df> or named by <_wagf_df_> by <_wagf_obj_> before the call         #
#   |                    Primarily similar to <df.reindex(_wagf_obj_.index)> to subset <df>                                             #
#   |                [3] All other functionalities remain the same as <fn>                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241024        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |types, pandas, inspect, functools                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    if not isinstance(fn, types.FunctionType):
        raise NotImplementedError('__call__ method of Class initializer is not designed to be wrapped with extra arguments!')

    #100. Define the basic wrapper to mutate <df>
    #[ASSUMPTION]
    #[1] We cannot add the internal argument as positional one, for it confuses the wrapper during the call
    #[2] We will later correct his position
    def wrapper(*pos_inner, _wagf_obj_ : pd.Series | pd.DataFrame | pd.Index = None, **kw_inner):
        #010. Local environment
        pos_trans = list(pos_inner)
        if isinstance(_wagf_obj_, pd.Index):
            idx = _wagf_obj_
        else:
            idx = _wagf_obj_.index

        #050. Obtain the signature of the function
        #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
        sig_raw = signature(fn).parameters.values()

        #100. Obtain the names of all keyword arguments
        kw_raw = [
            s.name
            for s in sig_raw
            if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
        ]

        #130. Obtain the names of all positional-only arguments
        pos_raw = [
            s.name
            for s in sig_raw
            if s.kind in ( s.POSITIONAL_ONLY, )
        ]

        #150. Verify the existence of variant positional argument
        var_pos = [
            s.name
            for s in sig_raw
            if s.kind in ( s.VAR_POSITIONAL, )
        ]

        #170. Verify the existence of variant keyword argument
        var_kw = [
            s.name
            for s in sig_raw
            if s.kind in ( s.VAR_KEYWORD, )
        ]

        #190. Abort if there is no argument named as the required one
        if _wagf_df_ not in (kw_raw + pos_raw):
            if (len(var_pos) == 0) and (len(var_kw) == 0):
                raise RuntimeError(f'[{fn.__name__}]No argument <{_wagf_df_}> is defined!')

        #500. Differentiate the process
        #[ASSUMPTION]
        #[1] If the name of <df> is passed during the call, we mutate the dataframe without considering whether it is among <kw_raw>
        #     or <var_kw>
        if _wagf_df_ in kw_inner:
            kw_inner[_wagf_df_] = kw_inner[_wagf_df_].reindex(idx).copy(deep = True)
        else:
            #010. Abort if no <df> can be determined
            if len(pos_inner) == 0:
                raise RuntimeError(f'[{fn.__name__}]Invalid call without parameter <{_wagf_df_}> provided!')

            #100. Get the positional arguments of <fn>
            pos_any = [
                s.name
                for s in sig_raw
                if s.kind in ( s.POSITIONAL_ONLY, s.POSITIONAL_OR_KEYWORD )
            ]

            #300. Get the position of <df> in the argument list
            pos_arg = [i for i,v in enumerate(pos_any) if v == _wagf_df_]

            #800. Differentiate the process when the implied <df> is provided at different positions
            #[ASSUMPTION]
            #[1] If there is a specific name of <df> in the positional arguments, we search for its position
            #[2] The we mutate the object on that position
            #[3] Otherwise, we can only presume that <df> object is provided at the first position in variant positional args
            if len(pos_arg) == 1:
                pos_trans[pos_arg[0]] = pos_trans[pos_arg[0]].reindex(idx).copy(deep = True)
            else:
                #010. Abort if no <df> can be determined
                if len(pos_trans) <= len(pos_any):
                    raise RuntimeError(
                        f'[{fn.__name__}]No variant positional args are provided!'
                        + ' <{_wagf_df_}> cannot be determined!'
                    )

                pos_trans[len(pos_any)] = pos_trans[len(pos_any)].reindex(idx).copy(deep = True)

        #900. Execute the dedicated function with the mutated <df>
        return(fn(*pos_trans, **kw_inner))

    #500. Change the position of the newly introduced argument to the very first one (and the only one under many circumstances)
    tmpfunc = partial(wrapper, *pos, **kw)
    def rstFunc(_wagf_obj_ : pd.Series | pd.DataFrame | pd.Index, *pos, **kw):
        return(tmpfunc(*pos, _wagf_obj_ = _wagf_obj_, **kw))

    #999. Finalize the wrapper
    return(rstFunc)
#End wrapAsGroupedFunc

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import pandas as pd
    from functools import partial
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import wrapAsGroupedFunc

    #100. Prepare the environment
    udf = pd.DataFrame(
        {
            'A': ['foo', 'foo', 'foo', 'foo', 'foo','bar', 'bar', 'bar', 'bar'],
            'B': ['one', 'one', 'one', 'two', 'two','one', 'one', 'two', 'two'],
            'C': ['small', 'large', 'large', 'small','small', 'large', 'small', 'small','large'],
            'D': [1, 2, 2, 3, 3, 4, 5, 6, 7],
            'E': [2, 4, 5, 5, 6, 6, 8, 9, 9]
        }
    )

    #200. Make the correct pivot result for comparison
    #[ASSUMPTION]
    #[1] In order to make it available as a customized aggregation function in <pd.GroupBy.agg> or <pd.pivot_table>, you (previously)
    #     need to define the function in this fashion
    #    [a] Setup a positional argument annotated as <pd.Series | pd.Index> at the very first position
    #    [b] Make a <df.reindex> to slice the <df> before calculation
    #    [c] During the call of <pd.GroupBy.agg> or <pd.pivot_table>, make it a partial function with all other arguments provided as
    #         the dedicated values
    #    [d] The return value must be a single scalar, repensenting a single cell in the pivot table
    #[2] Here we simulate the behavior of a Weighted Average calculation
    def wgtAvg_base(srs : pd.Series, df : pd.DataFrame, col : str, wgt : str):
        df = df.reindex(srs.index).copy(deep = True)
        sum_wgted = df[col].sum()
        sum_wgt = df[wgt].sum()
        return(sum_wgted / sum_wgt)

    upvt_base = pd.pivot_table(
        udf
        ,values = ['D']
        ,index = ['A','B']
        ,columns = ['C']
        ,aggfunc = partial(wgtAvg_base, df = udf, col = 'D', wgt = 'E')
        ,fill_value = 0
    )

    #300. Define a function with <df> as the first positional argument
    #[ASSUMPTION]
    #[1] With the new wrapper, you can ignore all the prerequisites, but only focus on the calculation logic for a <df> as an entire
    #     group. The wrapper handles the patching.
    #[2] The caveat is that the wrapper works like <functools.partial>.
    #[3] In this case, you can simply replace <partial> with <wrapAsGroupedFunc> and keep all else the same
    def wgtAvg1(df : pd.DataFrame, col : str, wgt : str):
        sum_wgted = df[col].sum()
        sum_wgt = df[wgt].sum()
        return(sum_wgted / sum_wgt)

    upvt1 = pd.pivot_table(
        udf
        ,values = ['D']
        ,index = ['A','B']
        ,columns = ['C']
        ,aggfunc = wrapAsGroupedFunc(wgtAvg1, df = udf, col = 'D', wgt = 'E')
        ,fill_value = 0
    )

    assert upvt_base.eq(upvt1).all(axis = None)

    #400. Define a function with <df> as the positional-or-keyword argument in other positions
    #[ASSUMPTION]
    #[1] There is no need to provide ALL of the arguments during the wrapping, given there are keyword args with defaults
    #[2] The wrapper recognizes the position of the provided <df>, as long as it is in the signature of the function
    def wgtAvg2(col : str, df : pd.DataFrame, wgt : str = 'E'):
        sum_wgted = df[col].sum()
        sum_wgt = df[wgt].sum()
        return(sum_wgted / sum_wgt)

    upvt2 = pd.pivot_table(
        udf
        ,values = ['D']
        ,index = ['A','B']
        ,columns = ['C']
        ,aggfunc = wrapAsGroupedFunc(wgtAvg2, 'D', udf)
        ,fill_value = 0
    )

    assert upvt_base.eq(upvt2).all(axis = None)

    #500. Define a function without <df>, but rather it is taken as the first variant positional argument
    #[ASSUMPTION]
    #[1] It should not be defined to pick up <df> from other positions in <*pos>, as the wrapper cannot derive the logic
    def wgtAvg3(col : str, *pos, wgt : str = 'E'):
        df = pos[0]
        sum_wgted = df[col].sum()
        sum_wgt = df[wgt].sum()
        return(sum_wgted / sum_wgt)

    upvt3 = pd.pivot_table(
        udf
        ,values = ['D']
        ,index = ['A','B']
        ,columns = ['C']
        ,aggfunc = wrapAsGroupedFunc(wgtAvg3, 'D', udf)
        ,fill_value = 0
    )

    assert upvt_base.eq(upvt3).all(axis = None)

    #600. Define a function without <df>, but rather it is taken from the variant keyword argument
    #[ASSUMPTION]
    #[1] If the name of <df> is different, just define it during the wrapping using the internal keyword <_wagf_df_>
    def wgtAvg4(col : str, wgt : str = 'E', **kw):
        df = kw['df_in']
        sum_wgted = df[col].sum()
        sum_wgt = df[wgt].sum()
        return(sum_wgted / sum_wgt)

    upvt4 = pd.pivot_table(
        udf
        ,values = ['D']
        ,index = ['A','B']
        ,columns = ['C']
        ,aggfunc = wrapAsGroupedFunc(wgtAvg4, 'D', df_in = udf, _wagf_df_ = 'df_in')
        ,fill_value = 0
    )

    assert upvt_base.eq(upvt4).all(axis = None)

    #700. Define a function resembling SUMIF in MS EXCEL
    def sumif(df : pd.DataFrame, col : str, cond : str):
        return(
            df[col]
            .where(df[cond].mod(2).eq(1), 0)
            .sum()
        )

    #[ASSUMPTION]
    #[1] <'D'> as the key in <agg()> call should exist in the dataframe, as it is used to slice the dataframe in <pandas>
    #[2] Actually it is not limited to aggregate on <'D'>, but anyone else. Providing <'D'> as key only makes use of its index
    ugrp = (
        udf
        .groupby(['A','B'])
        .agg({
            'D' : wrapAsGroupedFunc(sumif, udf, 'D', 'E')
        })
    )
    #           D
    # A   B
    # bar one   0
    #     two  13
    # foo one   2
    #     two   3
#-Notes- -End-
'''
