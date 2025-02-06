#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import types
import inspect
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature, Parameter
from functools import partial
from omniPy.AdvOp import nameArgsByFormals

class ExpandSignature:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to merge the signatures of <src> to the wrapped callable <dst> by expanding the <*pos> and <**kw> defined   #
#   | in <dst>, similar to <functools.wraps> but applied to extended argument list in high order functions                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] One can extend the arguments of <src> with certain high order function, and merge the signature of <src> into the wrapper, also#
#   |     for the caller to inspect the new signature wrapped by that high order function                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |RATIONALE                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Without this class, when you need to call the traditionally wrapped callable, you need to do <dst(arg1,*pos,**kw)>, where      #
#   |     all these arguments are from the definition of <dst>. This indicates <*pos> holds all positional arguments of <src>           #
#   |[2] We follow this rule, but further expand <*pos> and <**kw> by filling the respective holes with those in <src>                  #
#   |[3] By doing this, we hold the proper argument sequence and expansion rules                                                        #
#   |[4] Since this class requires <src> and <dst> to provide at every call, decoration magics as <simplifyDeco> no longer validate,    #
#   |     we would create a class decorator to enable parametric decoration                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SEQUENCE                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] All arguments of the same <kind> in <dst> prepend those in <src>                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |EXPANSION                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] VAR_POSITIONAL in <dst> will be expanded (and thus disappears in the wrapped result) if any among POSITIONAL_ONLY, as well as  #
#   |     POSITIONAL_OR_KEYWORD given VAR_POSITIONAL exists in <src>, in <src> are not covered by the signature of POSITIONAL_ONLY or   #
#   |     POSITIONAL_OR_KEYWORD in <dst>                                                                                                #
#   |[2] VAR_POSITIONAL in <src> will be retained anyway                                                                                #
#   |[3] VAR_KEYWORD in <dst> will be expanded (and thus disappears in the wrapped result) if any among KEYWORD_ONLY, as well as        #
#   |     POSITIONAL_OR_KEYWORD given VAR_POSITIONAL exists in <src>, in <src> are not covered by the signature of KEYWORD_ONLY or      #
#   |     POSITIONAL_OR_KEYWORD in <dst>                                                                                                #
#   |[4] VAR_KEYWORD in <src> will be retained anyway                                                                                   #
#   |[5] Expansion is always done so <src> without argument will lead <dst> to output without VAR_POSITIONAL and VAR_KEYWORD            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CODE OBJECT ATTRIBUTES                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The majority of attributes are retained from <dst>, indicating the wrapped functionality                                       #
#   |[2] <co_argcount>, <co_kwonlyargcount>, <co_posonlyargcount>, <co_varnames> are merged from <src> to <dst>                         #
#   |[3] <co_nlocals> is merged in below way                                                                                            #
#   |    [1] Number of arguments in <src> (rather than <co_nlocals> in <src> as we do not need its other local variables)               #
#   |    [2] Number of arguments in <dst> eliminating VAR_POSITIONAL and VAR_KEYWORD                                                    #
#   |[4] <co_flags> is the bitwise OR of <src> and (<dst>.<co_flags> - CO_VARARGS - CO_VARKEYWORDS). E.g. if <src> is not a generator   #
#   |     while <dst> is one, then the wrapped callable is still a generator                                                            #
#   |    see: https://docs.python.org/3/library/inspect.html#inspect-module-co-flags                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |INSTANCE ATTRIBUTES                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] <__annotations__> is merged as it is to (only) describe the arguments, with <dst> prior to <src>                               #
#   |[2] <__defaults__> is merged as it only contains the default values of POSITIONAL_OR_KEYWORD, from left to right with no skip      #
#   |[3] <__kwdefaults__> is merged as it only contains the default values of KEYWORD_ONLY                                              #
#   |[4] <__doc__> is merged if either has one, or None if neither has one                                                              #
#   |[5] <__name__>, <__qualname__>, <__module__> are taken from <dst>                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This wrapper is designed to modify the signature rather than to bring it along, so it is not recommended to use together with  #
#   |    <functools.wraps> unless with intention under certain cases, see examples for the reason and conclusion                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://chriswarrick.com/blog/2018/09/20/python-hackery-merging-signatures-of-two-python-functions/                            #
#   |[2] https://github.com/Kwpolska/merge_args                                                                                         #
#   |[3] https://docs.python.org/3/reference/datamodel.html                                                                             #
#   |[4] https://www.goldsborough.me/python/low-level/2016/10/04/00-31-30-disassembling_python_bytecode/                                #
#   |[5] https://www.cnblogs.com/traditional/p/13507329.html                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__init__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate the container of data input-output methods                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |src               :   <callable >Function as source to extract the signature and take place of the expanded holes in <dst> #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   Only for initialization                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__call__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to make the instance a decorator by a simple call to the internal wrapper of itself            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |dst               :   <callable >Function to be wrapped                                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The decorated result                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[getParam]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to identify the input value inside the parameters consisted of tuple of <pos> and dict of <kw> #
#   |   |   |   | by argument name, in terms of the signature of <src>                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |arg               :   <str     > Name of the argument in <src> to extract the input value from the parameters as passed to #
#   |   |   |                       the potential call of <src>                                                                         #
#   |   |   |pos_src           :   <tuple   > Parameters passed to the positional arguments for the call to <src>                       #
#   |   |   |kw_src            :   <dict    > Parameters passed to the keyword arguments for the call to <src>                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<any>             :   Any possible type of value passed for <arg>                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[insParams]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to insert the dedicated input parameters and validate the call to <src> in terms of the        #
#   |   |   |   | signature of <src>                                                                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |args_ins          :   <dict    > dict[name, value] to be inserted into the parameters for the call to <src>                #
#   |   |   |pos_src           :   <tuple   > Parameters passed to the positional arguments for the call to <src>                       #
#   |   |   |kw_src            :   <dict    > Parameters passed to the keyword arguments for the call to <src>                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |tuple[tuple,dict] :   The same result returned from <nameArgsByFormals>                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[updParams]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to update the dedicated input parameters and validate the call to <src> in terms of the        #
#   |   |   |   | signature of <src>                                                                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |args_upd          :   <dict    > dict[name, value] to be updated inside the parameters for the call to <src>               #
#   |   |   |pos_src           :   <tuple   > Parameters passed to the positional arguments for the call to <src>                       #
#   |   |   |kw_src            :   <dict    > Parameters passed to the keyword arguments for the call to <src>                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |tuple[tuple,dict] :   The same result returned from <nameArgsByFormals>                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_hasFlag]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to check whether <co_flags> contains certain flag                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |flags             :   <co_flags> extracted from any Code Object                                                            #
#   |   |   |flag              :   Certain flag to check                                                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<bool>            :   True if <flags> contain the dedicated <flag>, False if otherwise                                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_nullfn]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to fabricate the simplest callable to take over the merged signature, for the wrapped result   #
#   |   |   |   | to be able to investigate via <inspect.Signature>                                                                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |flags             :   <co_flags> extracted from any Code Object, to determine which type of callable to create             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The callable determined by <flags>                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_getType]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to identify the container for object instantiation                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |flags             :   <co_flags> extracted from any Code Object, to determine which type of callable to create             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The callable determined by <flags>                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_wrapper]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to create the decorator to merge the signature of <src> to <dst>                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |dst               :   <callable >Function to expand signature with that of <src>                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The decorated result                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250126        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |types, functools, inspect                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |nameArgsByFormals                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #015. Protect the private environment
    __slots__ = (
        'src','arg_kind'
        ,'sig_src','sig_src_bykind','sig_patch'
        ,'args_src','named_src','defaulted_src','po_src','pk_src_wo_def','pk_src_w_def','pos_src','ko_src','ko_src_w_def','kw_src'
        ,'doc_src','flags_src'
    )

    #100. Initialize by extracting the signature of the ancestor
    def __init__(self, src : callable):
        #020. Local environment
        self.src = src
        self.arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']

        #200. Retrieve the signature of the callable
        #[ASSUMPTION]
        #[1] Python evaluates the parameters passed for the call of a function in the priority as listed in <arg_kind>
        self.sig_src = signature(src).parameters.values()
        self.sig_src_bykind = {
            n : {
                i : s
                for i,s in enumerate(self.sig_src)
                if s.kind == s.__getattribute__(n)
            }
            for n in self.arg_kind
        }

        #210. Define the signature to patch when the positional arguments passed to the wrapped call are insufficient
        #[ASSUMPTION]
        #[1] When the list of parsed positional parameters (e.g. reshaped by <nameArgsByFormals>) is not empty, all the
        #     positional arguments should be provided inputs in a positional pattern, and it also leaves some holes to fill
        #[2] We need all the locations of the positional arguments in <src> to determine which holes to fill
        self.sig_patch = {
            i : s
            for i,s in enumerate(self.sig_src)
            if s.kind in (Parameter.POSITIONAL_ONLY, Parameter.POSITIONAL_OR_KEYWORD)
        }

        #300. Identify specific arguments
        #301. All arguments
        #[1] We do all below processes assuming that <dict> in Python >= 3.7 is ordered
        #    https://www.geeksforgeeks.org/are-python-dictionaries-ordered/
        self.args_src = {s.name : s.default for s in self.sig_src}

        #305. Named arguments
        self.named_src = {s.name : s.default for s in self.sig_src if s.kind not in [s.VAR_POSITIONAL,s.VAR_KEYWORD]}

        #307. Arguments with default values
        self.defaulted_src = {s.name : s.default for s in self.sig_src if s.default is not s.empty}

        #310. POSITIONAL_ONLY
        self.po_src = {s.name : s.default for s in self.sig_src_bykind['POSITIONAL_ONLY'].values()}

        #330. POSITIONAL_OR_KEYWORD
        self.pk_src_wo_def = {
            s.name : s.default
            for s in self.sig_src_bykind['POSITIONAL_OR_KEYWORD'].values()
            if s.default is s.empty
        }
        self.pk_src_w_def = {
            s.name : s.default
            for s in self.sig_src_bykind['POSITIONAL_OR_KEYWORD'].values()
            if s.default is not s.empty
        }

        #360. All positional arguments
        self.pos_src = (
            self.sig_src_bykind['POSITIONAL_ONLY']
            | self.sig_src_bykind['POSITIONAL_OR_KEYWORD']
            | self.sig_src_bykind['VAR_POSITIONAL']
        )

        #370. KEYWORD_ONLY
        self.ko_src = {s.name : s.default for s in self.sig_src_bykind['KEYWORD_ONLY'].values()}
        self.ko_src_w_def = {
            s.name : s.default
            for s in self.sig_src_bykind['KEYWORD_ONLY'].values()
            if s.default is not s.empty
        }

        #395. All keyword arguments
        self.kw_src = self.sig_src_bykind['KEYWORD_ONLY'] | self.sig_src_bykind['VAR_KEYWORD']

        #500. Identify specific attributes
        #510. Docstring
        self.doc_src = src.__doc__ or ''

        #520. Code Object Flags
        #[ASSUMPTION]
        #[1] It is tested that <co_varnames> is also matched against the indication in <co_flags>
        #[2] Failure on the matching will lead to below exception
        #    ValueError: code: co_varnames is too small
        #[3] <co_flags> cannot be updated using <.replace()> method, so if the wrapper has <*pos>, CO_VARARGS is set to the
        #     wrapped result anyway, same as CO_VARKEYWORDS
        #[4] Hence, when we need to chain the expansion of signatures with many functions, direct search in
        #     <src.__code__.co_flags> fails to indicate the correct flags of <*pos> and <**kw> when <src> is already expanded
        #     with signatures of other functions
        #[5] As a workaround, as as what <functools.wraps> does, we always prioritize the search for the flags in the newly
        #     created attribute <__wrapped__> and do not provide alternatives like <follow_wrapped = False>, because it never
        #     works for a nested expansion
        if hasattr(src, '__wrapped__'):
            self.flags_src = src.__wrapped__.__code__.co_flags
        else:
            self.flags_src = src.__code__.co_flags

    #200. Helper functions
    #110. Function to detect whether a Code Object Bit Flag is included in <co_flags>
    #[ASSUMPTION]
    #[1] <co_flags> are bitmaps so they are unique as binaries
    #[2] We exclude the tested flag from the <flags> using subtraction (see binary operation)
    #[3] If the rest flags do not match the tested flag and any binary position, the tested flag must have been included in <flags>
    #[4] If otherwise, the tested flag is not in <flags>
    #[5] Same as <(flags - flag) & flag == 0>
    #[6] Simple method is as below
    #Quote: https://docs.python.org/3/library/inspect.html#inspect-module-co-flags
    def _hasFlag(self, flags : int, flag : int) -> bool:
        return((flags & flag) == flag)

    #130. Null function to take over the merged signature
    def _nullfn(self, flags : int) -> callable:
        if self._hasFlag(flags, inspect.CO_GENERATOR):
            def rst():
                yield 1
        elif self._hasFlag(flags, inspect.CO_COROUTINE) or self._hasFlag(flags, inspect.CO_ITERABLE_COROUTINE):
            async def rst(): pass
        elif self._hasFlag(flags, inspect.CO_ASYNC_GENERATOR):
            async def rst():
                yield
        else:
            def rst(): pass

        return(rst)

    #150. Function to identify the container for object instantiation
    def _getType(self, flags: int):
        if self._hasFlag(flags, inspect.CO_GENERATOR):
            rst = types.GeneratorType
        elif self._hasFlag(flags, inspect.CO_COROUTINE) or self._hasFlag(flags, inspect.CO_ITERABLE_COROUTINE):
            rst = types.CoroutineType
        elif self._hasFlag(flags, inspect.CO_ASYNC_GENERATOR):
            rst = types.AsyncGeneratorType
        else:
            rst = partial(types.FunctionType, globals = globals())

        return(rst)

    #300. Create the decorator
    def _wrapper(self, dst : callable) -> callable:
        #100. Retrieve the signature of the callable
        sig_dst = signature(dst).parameters.values()
        sig_dst_bykind = {
            n : {
                i : s
                for i,s in enumerate(sig_dst)
                if s.kind == s.__getattribute__(n)
            }
            for n in self.arg_kind
        }
        has_vp_dst = len(sig_dst_bykind['VAR_POSITIONAL']) == 1
        has_vk_dst = len(sig_dst_bykind['VAR_KEYWORD']) == 1
        rest_src = {**self.named_src}

        #200. Identify specific arguments
        #201. All arguments
        args_dst = {s.name : s.default for s in sig_dst}

        #210. POSITIONAL_ONLY
        po_dst = {s.name : s.default for s in sig_dst_bykind['POSITIONAL_ONLY'].values()}
        len_po_dst = len(po_dst)

        #230. POSITIONAL_OR_KEYWORD
        pk_dst_wo_def = {s.name : s.default for s in sig_dst_bykind['POSITIONAL_OR_KEYWORD'].values() if s.default is s.empty}
        pk_dst_w_def = {s.name : s.default for s in sig_dst_bykind['POSITIONAL_OR_KEYWORD'].values() if s.default is not s.empty}
        len_pk_dst_wo_def = len(pk_dst_wo_def)
        len_pk_dst_w_def = len(pk_dst_w_def)

        #250. VAR_POSITIONAL

        #270. KEYWORD_ONLY
        ko_dst = {s.name : s.default for s in sig_dst_bykind['KEYWORD_ONLY'].values()}
        ko_dst_w_def = {s.name : s.default for s in sig_dst_bykind['KEYWORD_ONLY'].values() if s.default is not s.empty}

        #290. VAR_KEYWORD

        if (not has_vp_dst) and (not has_vk_dst):
            raise TypeError(
                f'[{dst.__name__}]No expansion of VAR_POSITIONAL or VAR_KEYWORD can be conducted for <{self.src.__name__}>!'
            )

        if self.args_src:
            if not has_vp_dst:
                if self.pos_src:
                    raise TypeError(f'[{dst.__name__}]Missing VAR_POSITIONAL to expand for <{self.src.__name__}>!')

            if not has_vk_dst:
                if self.kw_src:
                    raise TypeError(f'[{dst.__name__}]Missing VAR_KEYWORD to expand for <{self.src.__name__}>!')

        #300. Identify specific attributes
        #310. Docstring
        doc_dst = dst.__doc__ or ''

        #320. Code Object Flags
        flags_dst = dst.__code__.co_flags
        flags_upd = flags_dst

        #400. Merge arguments
        #410. POSITIONAL_ONLY
        #[ASSUMPTION]
        #[1] At this step, there may be arguments of other <kind> in <src> changed into this <kind> in <dst>
        #[2] We should honor this change by prioritize the <kind> in <dst>, similar for all the rest process
        po_fr_src = {k:v for k,v in self.po_src.items() if k in rest_src and k not in args_dst}
        po = po_dst | po_fr_src
        len_po = len(po)
        rest_src = {k:v for k,v in rest_src.items() if k not in po}

        #430. POSITIONAL_OR_KEYWORD
        #[ASSUMPTION]
        #[1] In this <kind>, arguments without defaults are always to the left of those with defaults
        #[2] There are two scenarios given <src> has <arg1, arg2 = 2>
        #    [1] If <dst> has <arg3 = 3>, we should put <arg3> between <arg1> and <arg2>, i.e. before the first one with default value
        #    [2] If <dst> has <arg3> (i.e. without default), we should put <arg3> before <arg1>
        pk_wo_def_fr_src = {k:v for k,v in self.pk_src_wo_def.items() if k in rest_src and k not in args_dst}
        pk_wo_def = pk_dst_wo_def | pk_wo_def_fr_src
        len_pk_wo_def = len(pk_wo_def)
        rest_src = {k:v for k,v in rest_src.items() if k not in pk_wo_def}

        pk_w_def_fr_src = {k:v for k,v in self.pk_src_w_def.items() if k in rest_src and k not in args_dst}
        pk_w_def = pk_dst_w_def | pk_w_def_fr_src
        len_pk_w_def = len(pk_w_def)
        rest_src = {k:v for k,v in rest_src.items() if k not in pk_w_def}

        #450. VAR_POSITIONAL
        vp = {s.name : s.default for s in self.sig_src_bykind['VAR_POSITIONAL'].values()}

        #470. KEYWORD_ONLY
        #[ASSUMPTION]
        #[1] Sequence (even with or without defaults) does not matter for this <kind> of arguments
        #[2] After this step, <rest_src> must have been empty, so there is no need for verification
        ko_fr_src = {k:v for k,v in self.ko_src.items() if k in rest_src and k not in args_dst}
        ko = ko_dst | ko_fr_src
        rest_src = {k:v for k,v in rest_src.items() if k not in ko}

        #490. VAR_KEYWORD
        vk = {s.name : s.default for s in self.sig_src_bykind['VAR_KEYWORD'].values()}

        #500. Prepare final attributes for Code Object
        #510. Full arguments
        args_full = po | pk_wo_def | pk_w_def | vp | ko | vk
        len_args = len(args_full)

        #520. Basic Code Object is from the wrapped callable
        co_base = {k:getattr(dst.__code__, k) for k in dir(dst.__code__) if k.startswith('co_')}

        #530. Prepare merged flags
        if self._hasFlag(flags_dst, inspect.CO_VARARGS):
            flags_upd -= inspect.CO_VARARGS
        if self._hasFlag(flags_dst, inspect.CO_VARKEYWORDS):
            flags_upd -= inspect.CO_VARKEYWORDS

        flags = self.flags_src | flags_upd

        #540. Prepare the null callable
        nullfn = self._nullfn(flags)

        #550. Prepare the local variable names
        # var_local = tuple(set(co_base['co_varnames']) - set(args_dst.keys()))

        #580. Update the Code Object with merged attributes
        #[ASSUMPTION]
        #[1] Looking into the source code of <inspect.signature> (Lib/inspect.py), <co_varnames> is a dynamically created tuple
        #    [1] Inside function definition, it only refers to the total arguments
        #    [2] At runtime (during the call), it is also appended by the local variables defined in the function body
        #    [3] [IMPORTANT] It is a strict sequence where VAR_POSITIONAL and KEYWORD_ONLY exchange their positions
        #[2] Hence, we only identify the arguments for this decorator, as it is now at function definition stage
        co = (
            co_base
            | {
                'co_argcount' : len_po + len(pk_wo_def) + len(pk_w_def)
                ,'co_posonlyargcount' : len_po
                ,'co_kwonlyargcount' : len(ko)
                # ,'co_nlocals' : co_base['co_nlocals'] - len(sig_dst) + len_args + 1
                ,'co_nlocals' : len_args
                ,'co_flags' : flags
                ,'co_varnames' : tuple((po | pk_wo_def | pk_w_def | ko | vp | vk).keys())
            }
        )

        #[ASSUMPTION]
        #[1] <co_lines>, <co_lnotab>, <co_positions> are immutable so we cannot update them
        #[2] <co_freevars> would fail to be tuple if this decorator is called inside a nested closure (function inside a function),
        #     hence we prevent it from updated. The related exception is as below
        #     TypeError: arg 5 (closure) must be tuple
        co_wrap = {
            k:v
            for k,v in co.items()
            if k not in ['co_lines','co_lnotab','co_positions','co_freevars']
        }

        co_deco = {
            k:v
            for k,v in co.items()
            if k in [
                'co_filename','co_name','co_qualname'
                ,'co_varnames','co_nlocals','co_argcount','co_posonlyargcount','co_kwonlyargcount'
                ,'co_flags','co_linetable','co_exceptiontable'
            ]
        }

        #700. Prepare the null function
        passer = self._getType(flags)(nullfn.__code__.replace(**co_wrap))
        passer.__name__ = dst.__name__
        passer.__qualname__ = dst.__qualname__
        passer.__module__ = dst.__module__
        passer.__defaults__ = tuple(pk_w_def.values())
        passer.__kwdefaults__ = {k:v for k,v in ko.items() if v is not inspect._empty}
        passer.__annotations__ = self.src.__annotations__ | dst.__annotations__
        passer.__doc__ = (
            (f'{doc_dst}\n\n' if doc_dst else '')
            + (f'Expanded from: {self.src.__name__}\n{self.doc_src}' if self.doc_src else '')
        )
        if not passer.__doc__:
            setattr(passer, '__doc__', None)

        #800. Reshape the call
        #[ASSUMPTION]
        #[1] Before this step, we transmuted the arguments; at this step, we translate the parameters passed during the call
        #[2] When <__doc__> is None, Python will automatically look up the consecutive comments just above the function declaration
        #     and replace it with them
        #[3] That is why we skip an empty line to ensure this block of comments is not taken as the nil <__doc__>

        def deco(*pos, **kw):
            #005. Patch the inputs where necessary
            pos_ = pos[:]
            #[ASSUMPTION]
            #[1] We pretend that the defaults for POSITIONAL_OR_KEYWORD-with-defaults and KEYWORD_ONLY-with-defaults are always
            #     set in <kw>, in case there are no explicit inputs for them
            #[2] Only by doing so, can we set the additional provision during the expansion of <dst>, for it to fill the
            #     respective holes in <src>
            #[3] Input value recognition priority is as below
            #    [1] If the argument is provided in <pos>, it is programmatically taken prior to the same provision in <kw>
            #    [2] If it is provided in <kw>, we take it prior to any of its default values in either <src> or <dst>
            #    [3] If the same argument exists in both callables, we still take the default value in <dst> prior to <src>
            kw_ = self.pk_src_w_def | pk_dst_w_def | self.ko_src_w_def | ko_dst_w_def | kw

            #010. Translate the parameters in terms of the merged signature
            #[ASSUMPTION]
            #[1] In order to make a valid call, we do not accept insufficient parameters passed
            #[2] However, we allow excessive parameters, i.e. multiple inputs, for we allow the patching at above steps
            in_pos, in_kw = nameArgsByFormals(passer, pos_ = pos_, kw_ = kw_, coerce_ = True, strict_ = True)

            #100. Split positional parameters
            #[ASSUMPTION]
            #[1] To fulfill the arguments for <src> and <dst> separately, we need to split the parameters according to their
            #     respective signatures
            #[2] That is, we identify the parameters specifically for <dst> and put the rest into <*pos> of the signature of <dst>
            #[3] Since <*pos> is after POSITIONAL_ONLY and POSITIONAL_OR_KEYWORD, we handle these <kind>s together
            #[4] We do the same for the rest <kind> of parameters as well
            in_po_dst = in_pos[:len_po_dst]
            in_po_src = in_pos[len_po_dst:len_po]
            in_pk_wo_def_dst = in_pos[len_po:(len_po + len_pk_dst_wo_def)]
            in_pk_wo_def_src = in_pos[(len_po + len_pk_dst_wo_def):(len_po + len_pk_wo_def)]
            in_pk_w_def_dst = in_pos[(len_po + len_pk_wo_def):(len_po + len_pk_wo_def + len_pk_dst_w_def)]
            in_pk_w_def_src = in_pos[(len_po + len_pk_wo_def + len_pk_dst_w_def):(len_po + len_pk_wo_def + len_pk_w_def)]
            in_vp_src = in_pos[(len_po + len_pk_wo_def + len_pk_w_def):]

            #300. Split keyword parameters
            in_ko_dst = {k:v for k,v in in_kw.items() if k in ko_dst}
            in_ko_src = {k:v for k,v in in_kw.items() if k in ko_fr_src}
            in_kw_rest = {k:v for k,v in in_kw.items() if k not in ko}

            #500. Prepare the adjustment on those POSITIONAL_OR_KEYWORD which are translated into keyword input
            kw_wo_def_dst = {k:v for k,v in in_kw_rest.items() if k in pk_dst_wo_def}
            kw_wo_def_src = {k:v for k,v in in_kw_rest.items() if k in pk_wo_def_fr_src}
            kw_w_def_dst = {k:v for k,v in in_kw_rest.items() if k in pk_dst_w_def}
            kw_w_def_src = {k:v for k,v in in_kw_rest.items() if k in pk_w_def_fr_src}
            adj_pk_wo_def_dst = tuple(kw_wo_def_dst.values())
            adj_pk_wo_def_src = tuple(kw_wo_def_src.values())
            adj_pk_w_def_dst = tuple(kw_w_def_dst.values())
            adj_pk_w_def_src = tuple(kw_w_def_src.values())

            #600. Identify VAR_KEYWORD
            in_vk_src = {
                k:v
                for k,v in in_kw_rest.items()
                if k not in (kw_wo_def_dst | kw_wo_def_src | kw_w_def_dst | kw_w_def_src)
            }

            #800. Prepare the parameters for the call
            out_pos = in_po_dst + in_pk_wo_def_dst + adj_pk_wo_def_dst + in_pk_w_def_dst + adj_pk_w_def_dst
            out_vp = in_po_src + in_pk_wo_def_src + adj_pk_wo_def_src + in_pk_w_def_src + adj_pk_w_def_src + in_vp_src
            out_ko = in_ko_dst
            out_vk = in_ko_src | in_vk_src

            #900. Call <dst>
            return(dst(*out_pos, *out_vp, **out_ko, **out_vk))

        #900. Prepare the output
        _ = deco.__code__.replace(**co_deco)
        deco.__wrapped__ = passer
        attr_deco = ['__name__','__qualname__','__defaults__','__kwdefaults__','__annotations__','__doc__','__module__']
        for attr in attr_deco:
            setattr(deco, attr, getattr(passer, attr))

        #999. Return the wrapped one
        return(deco)

    #500. Function to identify the input value by argument name
    def getParam(self, arg : str, pos_src : tuple, kw_src : dict):
        #[ASSUMPTION]
        #[1] If there are holes in <pos_src> while we can neither obtain their default values in the signature, the final call
        #     would fail
        #[2] Below process still cannot verify which arguments are missing inputs
        #[3] Hence it is safe to retrieve the parameter value to the call to <src> by following below steps
        #    [1] Call <insParams> when knowing which arguments are missing, i.e. all the shared arguments of <src> and <dst>,
        #         this step is always required if there are shared arguments to ensure correct positioning
        #    [2] Call <updParams> when there should be changes or calculation upon above result (not required when not needed)
        #    [3] Call this method to get the final input value from above result
        pos_in, kw_in = nameArgsByFormals(
            self.src
            ,pos_ = pos_src
            ,kw_ = (kw_src | { k:v for k,v in self.defaulted_src.items() if k not in kw_src })
            ,coerce_ = True
            ,strict_ = True
        )
        if len(pos_in) > (arg_loc := [ i for i,s in enumerate(self.sig_src) if s.name == arg ][0]):
            return(pos_in[arg_loc])
        else:
            return(kw_in.get(arg))

    #600. Function to insert the dedicated input parameters in terms of the signature
    def insParams(self, args_ins : dict, pos_src : tuple, kw_src : dict):
        #[ASSUMPTION]
        #[1] We cannot standardize the input as <updParams> does, as the input has some holes as we know at the wrapping, while
        #     the function <nameArgsByFormals> would skip the holes in <pos_src> which causes mismatching of positional parameters

        #100. Prepare the patch
        pos_patch = { i:s.name for i,s in self.sig_patch.items() if s.name in args_ins }
        pos_in = list(pos_src)

        #300. Positional inputs
        #[ASSUMPTION]
        #[1] In general, we would process the list (even empty) of arguments shared by both callables in below way
        #    [1] If len(pos) > 0, identify all POSITIONAL_ONLY or POSITIONAL_OR_KEYWORD of the shared arguments and insert them into
        #         <*pos> from left to right in terms of their locations in the signature of <src>. If len(pos) == 0, there is
        #         nothing to do as: either there is no positional argument in <src>, or all arguments for <src> can be translated
        #         into keyword input
        #    [2] Overwrite all these arguments in <**kw>, including those processed at above step
        if len(pos_src) > 0:
            for i in sorted(list(pos_patch.keys())):
                pos_in.insert(i, args_ins.get(pos_patch.get(i)))

        #500. Keywords
        #[ASSUMPTION]
        #[1] No matter whether <*pos> is patched, it is safe to add <args_ins> into the keyword input, as we will patch all inputs
        #     in one batch later, by allowing (and deduplicating) multiple inputs for the same arguments
        #[2] We must use the explicit input of <args_ins> to replace the possible keyword in <kw> to ensure the correct syntax
        kw_in = kw_src | args_ins

        #900. Reshape the input parameters
        #[ASSUMPTION]
        #[1] If the parameters are still insufficient, exceptions will be raised here
        return(nameArgsByFormals(self.src, pos_ = tuple(pos_in), kw_ = kw_in, coerce_ = True, strict_ = True))

    #700. Function to update the dedicated input parameters in terms of the signature
    def updParams(self, args_upd : dict, pos_src : tuple, kw_src : dict):
        #010. Ensure the input has the same structure as the signature
        #[ASSUMPTION]
        #[1] If there are holes in <pos_src>, we would never know which are the one to update, hence we will not allow missing
        #     inputs by setting <strict_ = True>
        pos_raw, kw_raw = nameArgsByFormals(self.src, pos_ = pos_src, kw_ = kw_src, coerce_ = True, strict_ = True)

        #100. Prepare the patch
        pos_patch = { i:s.name for i,s in self.sig_patch.items() if s.name in args_upd }
        pos_in = list(pos_raw)
        len_pos_src = len(pos_raw)

        #100. Positional inputs
        #[ASSUMPTION]
        #[1] We only update the value at the position which exists in the list of parameters
        for i in sorted(list(pos_patch.keys())):
            if len_pos_src > i:
                pos_in[i] = args_upd.get(pos_patch.get(i))

        #500. Keywords
        #[ASSUMPTION]
        #[1] No matter whether <*pos> is patched, it is safe to add <args_upd> into the keyword input, as we will patch all inputs
        #     in one batch later, by allowing (and deduplicating) multiple inputs for the same arguments
        #[2] We must use the explicit input of <args_upd> to replace the possible keyword in <kw> to ensure the correct syntax
        kw_in = kw_raw | args_upd

        #900. Reshape the input parameters
        #[ASSUMPTION]
        #[1] If the parameters are still insufficient, exceptions will be raised here
        return(nameArgsByFormals(self.src, pos_ = tuple(pos_in), kw_ = kw_in, coerce_ = True, strict_ = True))

    #900. Set the instance as a decorator
    def __call__(self, dst : callable):
        return(self._wrapper(dst))
#End ExpandSignature

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create environment.
    import sys
    from inspect import signature, Parameter
    from typing import Any
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import nameArgsByFormals, withDefaults
    from omniPy.AdvOp import ExpandSignature

    #050. Define a universal function to print the private environment
    def printEnv():
        frame = sys._getframe(1)
        getvar = frame.f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print('[{0}]=[{1}]'.format(v,str(frame.f_locals.get(v))))

    #100. Define the function with all kinds of arguments
    def testf_src(arg1 : list[str], arg2, /, arg3 : float, arg4 = 4, *pos, arg5 = 5, arg6, **kw) -> Any:
        """ This is testf_src """
        print('From testf_src:')
        printEnv()

    #110. Function to take the signature of source function
    #[ASSUMPTION]
    #[1] If one needs to leverage the internal methods to extract input values of some arguments, or needs to insert
    #     additional parameters when insufficient, a named instance is helpful
    #[2] For simple decoration, one can use the conventional way, see other test cases
    eSig = ExpandSignature(testf_src)
    @eSig
    def testf_dst(arg2 : int, arg7, /, arg8 = 8, *pos, arg9, **kw):
        """ This is testf_dst """
        #Define more internal variables to test the functionality
        vvv : int = 1
        def h_int(): pass

        print('From testf_dst:')
        printEnv()

        #[ASSUMPTION]
        #[1] Since <arg2> is in the signature of <dst>, we should insert it into the parameters for the call of <src>
        args_share = {'arg2' : arg2}
        pos_out, kw_out = eSig.insParams(args_share, pos, kw)

        testf_src(*pos_out, **kw_out)

    help(testf_dst)
    # Help on function testf_dst in module __main__:
    # deco(arg2: int, arg7, arg1: list[str], /, arg3: float, arg8=8, arg4=4, *pos, arg9, arg5=5, arg6, **kw) -> Any
    # This is testf_dst
    # Expanded from: testf_src
    #  This is testf_src

    #[ASSUMPTION]
    #[1] We remove the extra local variables from the log for a clear result
    testf_dst(2,7,1,arg3 = 3,arg6 = 6, arg9 = 9)
    # From testf_dst:
    # [arg2]=[2]
    # [arg7]=[7]
    # [arg8]=[8]
    # [arg9]=[9]
    # [pos]=[(1, 3, 4)]
    # [kw]=[{'arg5': 5, 'arg6': 6}]
    # From testf_src:
    # [arg1]=[1]
    # [arg2]=[2]
    # [arg3]=[3]
    # [arg4]=[4]
    # [arg5]=[5]
    # [arg6]=[6]
    # [pos]=[()]
    # [kw]=[{}]

    #120. Provide sufficient positional arguments for <*pos> in <src> to take
    testf_dst(2,7,1,3,80,40,50,arg6 = 6, arg9 = 9)
    # From testf_dst:
    # [arg2]=[2]
    # [arg7]=[7]
    # [arg8]=[80]
    # [arg9]=[9]
    # [pos]=[(1, 3, 40, 50)]
    # [kw]=[{'arg5': 5, 'arg6': 6}]
    # From testf_src:
    # [arg1]=[1]
    # [arg2]=[2]
    # [arg3]=[3]
    # [arg4]=[40]
    # [arg5]=[5]
    # [arg6]=[6]
    # [pos]=[(50,)]
    # [kw]=[{}]

    #200. We set all arguments as able to take keyword input and test if the inputs in different shape can be recognized
    testf_dst2 = withDefaults(testf_dst)
    testf_dst2(arg3 = 3,arg6 = 6, arg9 = 9, arg2 = 2, arg1 = 1, arg7 = 7)
    # From testf_dst:
    # [arg2]=[2]
    # [arg7]=[7]
    # [arg8]=[8]
    # [arg9]=[9]
    # [pos]=[(1, 3, 4)]
    # [kw]=[{'arg5': 5, 'arg6': 6}]
    # From testf_src:
    # [arg1]=[1]
    # [arg2]=[2]
    # [arg3]=[3]
    # [arg4]=[4]
    # [arg5]=[5]
    # [arg6]=[6]
    # [pos]=[()]
    # [kw]=[{}]

    #300. Test if the <src> takes different arguments
    #310. No argument
    def src1():
        print('This is src1:')
    @ExpandSignature(src1)
    def dst1(arg2, *pos):
        src1()
        print('This is dst1:')
        print(f'arg2 : {str(arg2)}')

    dst1(2)
    # This is src1:
    # This is dst1:
    # arg2 : 2

    #330. <src> has different arguments than <dst>
    def src2(arg1, *, arg3 = 3):
        print('This is src2:')
        print(f'arg1 : {str(arg1)}')
        print(f'arg3 : {str(arg3)}')
    @ExpandSignature(src2)
    def dst2(arg2, *pos, **kw):
        src2(*pos, **kw)
        print('This is dst2:')
        print(f'arg2 : {str(arg2)}')

    dst2(2,1)
    # This is src2:
    # arg1 : 1
    # arg3 : 3
    # This is dst2:
    # arg2 : 2

    #400. Real cases
    #410. Create a method out of an existing function with nested expansion
    def src3(arg1, *, arg3 = 3, **kw):
        print('This is src3:')
        print(f'arg1 : {str(arg1)}')
        print(f'arg3 : {str(arg3)}')
        print(f'kw : {str(kw)}')

    @ExpandSignature(src3)
    def dst3(arg4, /, *pos, **kw):
        src3(*pos, **kw)
        print('This is dst3:')
        print(f'arg4 : {str(arg4)}')

    @ExpandSignature(dst3)
    def dst4(self, /, *pos, arg5, **kw):
        dst3(*pos, **kw)
        print('This is dst4:')
        print(f'arg5 : {str(arg5)}')

    help(dst4)
    # Help on function dst4 in module __main__:
    # dst4(self, arg4, /, arg1, *, arg5, arg3=3, **kw)

    dst4(1, 4, 1, arg5 = 5, arg7 = 7)
    # This is src3:
    # arg1 : 1
    # arg3 : 3
    # kw : {'arg7': 7}
    # This is dst3:
    # arg4 : 4
    # This is dst4:
    # arg5 : 5

    #450. Interaction with <functools.wraps>
    from functools import wraps
    @wraps(dst4)
    def dst5(*pos, **kw):
        return(dst4(*pos, **kw))

    #[ASSUMPTION]
    #[1] The signature seems correct as expected
    #[2] However, <__name__> is the wrapped one instead of the wrapper, which is the design but not what we need
    help(dst5)
    # Help on function dst4 in module __main__:
    # dst4(self, arg4, /, arg1, *, arg5, arg3=3, **kw)

    #[ASSUMPTION]
    #[1] <dst5.__code__.co_flags> is <15>, indicating both <*pos> and <**kw> exists in the signature
    #[2] <dst5.__wrapped__.__code__.co_flags> is <31>, also including both <*pos> and <**kw>, as it directly retrieves
    #     the value from <dst4.__code__.co_flags>
    #[3] However in our design for an expanded callable
    #    [1] <dst4.__code__.co_flags> is <31>, coming from the wrapper in <expandSignature> that takes both <*pos> and
    #         <**kw>. This cannot be updated by any means
    #    [2] <dst4.__wrapped__.__code__.co_flags> is (as what we do imperatively) <11>, which exactly matches its
    #         signature, and is what we need to pass for a nested expansion
    print(dst4.__code__.co_flags)
    # 31
    print(dst4.__wrapped__.__code__.co_flags)
    # 11
    print(dst5.__code__.co_flags)
    # 15
    print(dst5.__wrapped__.__code__.co_flags)
    # 31

    #[ASSUMPTION]
    #[1] After above step, when we try to expand <dst5> to another callable, it fails because of the inconsistency between
    #     <co_flags> (from either <dst5.__code__> or <dst5.__wrapped__.__code__>) and <dst5.__code__.co_varnames>
    @ExpandSignature(dst5)
    def dst6(*pos, **kw):
        return(dst5(*pos, **kw))

    # ValueError: code: co_varnames is too small

    #[CONCLUSION]
    #[1] For Python <= 3.11, <expandSignature> cannot wrap any function that is already wrapped by <functools.wraps>
    #[2] One can replace most cases of decoration with <functools.wraps>, with some exceptions
    #    [1] <AdvOp.simplifyDeco> is defined to wrap a decorator, instead of expand its signature
    #    [2] <AdvOp.withDefaults> is defined to mask the signature
    #[3] If one needs to chain the expansion, every intermediate expansion must be done by <expandSignature>

#-Notes- -End-
'''
