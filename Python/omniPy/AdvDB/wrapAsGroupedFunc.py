#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import types
import pandas as pd
from functools import partial
from omniPy.AdvOp import ExpandSignature, modifyDict

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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250623        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the entire process to simplify the wrapping logic                                                               #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |types, pandas, functools                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |   |modifyDict                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    if not isinstance(fn, types.FunctionType):
        raise NotImplementedError('__call__ method of Class initializer is not designed to be wrapped with extra arguments!')

    #100. Define the basic wrapper to mutate <df>
    #[ASSUMPTION]
    #[1] We cannot add the internal argument as positional one, for it confuses the wrapper during the call
    #[2] We will later correct its position
    @(eSig := ExpandSignature(fn))
    def wrapper_(*pos, _wagf_obj_ : pd.Series | pd.DataFrame | pd.Index = None, **kw):
        #010. Local environment
        if isinstance(_wagf_obj_, pd.Index):
            idx = _wagf_obj_
        else:
            idx = _wagf_obj_.index

        args_share = {}
        eSig.vfyConflict(args_share)
        if len(sig_vp := eSig.sig_src_bykind['VAR_POSITIONAL']) > 0:
            pos_vp = list(sig_vp.keys())[0]

        #100. Reshape input parameters
        pos_in, kw_in = eSig.insParams(args_share, pos, kw)

        #300. Identify the <pandas> object for slicing
        #[ASSUMPTION]
        #[1] Lookup in the signature of the input function and locate it by standard method
        #[2] If otherwise it is located in <**kw>, it must be among <VAR_KEYWORD>
        #[3] If otherwise it is located in <*pos>, it must be among <VAR_POSITIONAL>, and thus <pos_in> must contain all the
        #     positional arguments in terms of Python syntax; so we only obtain the first input among <VAR_POSITIONAL>
        #[4] If it still cannot be located, an exception will be raised
        if _wagf_df_ in eSig.args_src:
            _wagf_df_in_ = eSig.getParam(_wagf_df_, pos_in, kw_in)
        elif _wagf_df_ in kw:
            _wagf_df_in_ = kw.get(_wagf_df_)
        elif len(sig_vp) > 0:
            _wagf_df_in_ = pos_in[pos_vp]
        else:
            raise ValueError(f'[{fn.__name__}]No argument <{_wagf_df_}> is defined!')

        #500. Main process to muttate the input <pandas> object
        _wagf_df_out_ = _wagf_df_in_.reindex(idx)

        #700. Insert the mutated object into the correct position of input parameters
        #[ASSUMPTION]
        #[1] Directly update it into the parameters if <_wagf_df_> is in the signature of the wrapped function
        #[2] If otherwise it is located in <**kw>, we only translate the <**kw> part of the input parameters
        #[3] If otherwise it is located in <*pos>, we translate <pos_in> and leave <kw_in> untouched
        #[4] An exception has been raised in earlier step if otherwise, hence there is no need for further handling
        if _wagf_df_ in eSig.args_src:
            pos_fnl, kw_fnl = eSig.updParams({_wagf_df_ : _wagf_df_out_}, pos_in, kw_in)
        elif _wagf_df_ in kw:
            pos_fnl, kw_fnl = eSig.insParams(args_share, pos, modifyDict(kw, {_wagf_df_ : _wagf_df_out_}))
        elif len(sig_vp) > 0:
            pos_fnl, kw_fnl = eSig.insParams(args_share, pos_in[:pos_vp] + (_wagf_df_out_,) + pos_in[(pos_vp + 1):], kw_in)

        #900. Call the input function with mutated <pandas> object
        return(eSig.src(*pos_fnl, **kw_fnl))

    #500. Change the position of the newly introduced argument to the very first one (and the only one under many circumstances)
    tmpfunc = partial(wrapper_, *pos, **kw)
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
    import numpy as np
    import pandas as pd
    from collections.abc import Iterable
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

    #800. Conduct rolling period comparison
    #[ASSUMPTION]
    #[1] Facilitate rolling period comparison, including YoY, MoM, etc.
    #[2] Mark the data of different periods in below convention
    #[3] Return a scalar and leave the stratified aggregation method to be wrapped later
    def pctRollPeriod(df : pd.DataFrame, col_val : str = 'A_KPI_VAL', col_prd : str = 'rpt_prd'):
        val_prev = round(df.loc[lambda x: x[col_prd].eq('prev')][col_val].sum(), 2)
        val_curr = round(df.loc[lambda x: x[col_prd].eq('curr')][col_val].sum(), 2)
        rstOut = np.sign(val_curr) if val_prev == 0.0 else ((val_curr - val_prev) / abs(val_prev))
        return(rstOut)

    df_roll = (
        pd.DataFrame(
            {
                'rpt_prd': ['prev', 'prev', 'prev', 'prev', 'curr','curr', 'curr', 'curr', 'curr'],
                'cat': ['one', 'one', 'two', 'two', 'one','one', 'one', 'two', 'two'],
                'class': ['A', 'A', 'A', 'B', 'A','A', 'A', 'A', 'B'],
                'A_KPI_VAL': [1, 2, 3, 4, -5, -6, -7, 8, 9]
            }
        )
        .astype({'A_KPI_VAL' : float})
    )

    pvt_roll = pd.pivot_table(
        df_roll
        ,values = ['A_KPI_VAL']
        ,index = ['cat']
        ,columns = ['class']
        ,aggfunc = wrapAsGroupedFunc(pctRollPeriod, df = df_roll)
        ,fill_value = 0
    )
    #       A_KPI_VAL
    # class         A     B
    # cat
    # one   -7.000000  0.00
    # two    1.666667  1.25

    #900. Calculate the Percentage of the Parent Subtotal at column level of the pivot table, i.e. ColPctSum
    #[ASSUMPTION]
    #[1] This aggregation should be based on the provided level, as the program never knows the aggregation strategy
    def colPctSum(
        df : pd.DataFrame
        ,df_base : pd.DataFrame
        ,col_val : str = 'A_KPI_VAL'
        ,agg_lvl : str = 'rpt_lvl1'
        ,to_lvl : Iterable = 'rpt_lvl2'
        ,all_lvls : Iterable = [f'rpt_lvl{i}' for i in range(3, 0, -1)]
    ):
        #005. Local environment
        if isinstance(to_lvl, str):
            to_lvl = [to_lvl]
        else:
            to_lvl = to_lvl[:]

        #100. Direct aggregation of current level
        val_curr = df[col_val].sum()

        #300. Identify the parent levels (in the <columns> specification of the pivot table)
        lvls_parent = [v for v in all_lvls[:all_lvls.index(agg_lvl)] if v not in to_lvl]
        if not lvls_parent:
            return(1.0 if val_curr != 0.0 else 0.0)

        #500. Aggregate the values in the parent level (i.e. groupby all parent levels)
        df_parent = (
            df_base
            .loc[lambda x: pd.MultiIndex.from_frame(x[lvls_parent]).isin(pd.MultiIndex.from_frame(df[lvls_parent]))]
            .loc[lambda x: x[agg_lvl].isin(df[agg_lvl])]
        )
        val_base = df_parent[col_val].sum()

        #700. Calculate percentage
        rstOut = 0.0 if val_base == 0.0 else (val_curr / val_base)

        return(rstOut)

    df_pctsum = (
        pd.DataFrame(
            {
                'rpt_lvl3': ['A', 'A', 'A', 'A', 'A','B', 'B', 'B', 'B'],
                'rpt_lvl2': ['one', 'one', 'two', 'two', 'three','one', 'two', 'three', 'three'],
                'rpt_lvl1': ['a', 'b', 'a', 'b', 'a','a', 'b', 'a', 'b'],
                'A_KPI_VAL': [1, 2, 3, 4, 5, 6, 7, 8, 9]
            }
        )
        .astype({'A_KPI_VAL' : float})
    )

    #[ASSUMPTION]
    #[1] 以<rpt_lvl3>分组，在每个<rpt_lvl2>值向下，计算各个<rpt_lvl1>对于当前<rpt_lvl2>值下总数的占比
    pvt_pctsum = pd.pivot_table(
        df_pctsum
        ,values = ['A_KPI_VAL']
        ,index = [f'rpt_lvl{i}' for i in range(3, 0, -1)]
        ,aggfunc = wrapAsGroupedFunc(
            colPctSum
            ,df = df_pctsum
            ,df_base = df_pctsum
            ,agg_lvl = 'rpt_lvl2'
            ,to_lvl = ['rpt_lvl1']
        )
        ,fill_value = 0
    )
    #                             A_KPI_VAL
    # rpt_lvl3 rpt_lvl2 rpt_lvl1
    # A        one      a          0.333333
    #                   b          0.666667
    #          three    a          1.000000
    #          two      a          0.428571
    #                   b          0.571429
    # B        one      a          1.000000
    #          three    a          0.470588
    #                   b          0.529412
    #          two      b          1.000000

#-Notes- -End-
'''
