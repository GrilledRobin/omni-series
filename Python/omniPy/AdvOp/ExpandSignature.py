#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import ast, types, inspect
import datetime as dt
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature, Parameter
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
#   |[2] Since <nameArgsByFormals> is in use, most functions wrapped by this decorator can be called in the fashion <fn(**kw)>, i.e. the#
#   |     caller is able to provide all parameters in keyword pattern, regardless of whether there is POSITIONAL_ONLY argument in the   #
#   |     signature of the wrapped function. This convention enables parametric function calls at most of times, except when there is   #
#   |     VAR_POSITIONAL in <src> and meanwhile it should be provided with parameter(s) at the function call.                           #
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
#   |[4] <co_flags> is the bitwise OR of various flags from both callables, details are as below                                        #
#   |    [1] <CO_VARARGS> and <CO_VARKEYWORDS> are taken from <src>                                                                     #
#   |    [2] All the rest <co_flags> are from <dst>                                                                                     #
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
#   |   |   |inc_default       :   <bool    > Whether to include the default values if no input is provided at runtime                  #
#   |   |   |                      [True                ]<Default> Include the default values if no input is provided at runtime        #
#   |   |   |                      [False               ]          Only obtain the input value at runtime                               #
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
#   |   |[vfyConflict]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to Verify the conflict of argument names at runtime, to secure the dynamic signature expansion #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |args_share        :   <dict    > The argument names shared by both callables that are declared to be excluded              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |None              :   This method is only used to raise exception if conflict is detected                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[isDefault]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to indicate whether the callable (primarily <src>) is called with the default value of an      #
#   |   |   |   | argument instead of from the input                                                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |arg               :   <str     > The argument name to detect                                                               #
#   |   |   |scope_            :   <str     > Within which signature of the callables to detect the flag                                #
#   |   |   |                      [src                 ]<Default> Detect the flag in the signature of <src> for most of cases          #
#   |   |   |                      [dst                 ]          Detect the flag in the signature of <dst> for certain cases          #
#   |   |   |                      [<any other strings> ]          Detect the flag among all the arguments with default values          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<bool>            :   True if its parameter passed to the call is from its default value in the signature                  #
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
#   |   |   |args              :   <ast.arguments> instance for fabrication of the new callable                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   The callable determined by <flags>                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_getSig]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to parse the Signature of the provided callable and extract the attributes for internal process#
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |func              :   <callable> for which to extract the Signature details                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<dict>            :   Variable attributes extracted from the Signature                                                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_reshapeParams]                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to reshape the parameters at runtime to facilitate the call to <dst> and <src> in a proper     #
#   |   |   |   | sequence                                                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |*pos              :   <tuple> of all positional parameters passed for the call to the wrapped callable                     #
#   |   |   |**kw              :   <dict> of all keyword parameters passed for the call to the wrapped callable                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<tuple>           :   <tuple[tuple,dict]> as the reshaped parameters to facilitate the call to <dst>, and thus to the call #
#   |   |   |                       to <src> subsequently from inside the body of <dst>                                                 #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250224        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add detection of whether the parameter passed for an argument to the call is from its default value, instead of from the#
#   |      |     input at runtime; the detection is not by values hence it can be flagged correctly even if they are identical          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251101        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce abstract syntax tree <ast> to fabricate the null function                                                     #
#   |      |[2] Now supports all these types of callables: function, generator, async generator, coroutine, iterable coroutine. See     #
#   |      |     official document of <co_flags> in <inspect> for the difference between them                                           #
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
#   |   |types, ast, inspect, datetime                                                                                                  #
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
        '_isdefault','_isdefault_scope','_defaults'
        ,'src','sig_src','dst','sig_dst'
        ,'arg_kind','sig_patch','passer'
        ,'len_po','len_pk_wo_def','len_pk_w_def'
        ,'ko_fr_src','ko','pk_wo_def_fr_src','pk_w_def_fr_src'
    )

    #100. Initialize by extracting the signature of the ancestor
    def __init__(self, src : callable):
        #020. Local environment
        self._isdefault = {}
        self._isdefault_scope = {'src' : {}, 'dst' : {}}
        self.src = src
        self.arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']

        #200. Retrieve the signature of the callable
        self.sig_src = self._getSig(src)

        #210. Define the signature to patch when the positional arguments passed to the wrapped call are insufficient
        #[ASSUMPTION]
        #[1] When the list of parsed positional parameters (e.g. reshaped by <nameArgsByFormals>) is not empty, all the
        #     positional arguments should be provided inputs in a positional pattern, and it also leaves some holes to fill
        #[2] We need all the locations of the positional arguments in <src> to determine which holes to fill
        self.sig_patch = {
            i : s
            for i,s in enumerate(self.sig_src['sig'])
            if s.kind in (Parameter.POSITIONAL_ONLY, Parameter.POSITIONAL_OR_KEYWORD)
        }

        #300. Identify specific arguments
        #307. Arguments with default values
        self._defaults = {**self.sig_src['defaulted']}

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
    def _nullfn(self, flags : int, args : ast.arguments) -> callable:
        #010. Local environment
        Name = lambda s, ctx = ast.Load(): ast.Name(id = s, ctx = ctx)
        Const = lambda v: ast.Constant(value = v)
        Attr = lambda base, attr: ast.Attribute(value = base, attr = attr, ctx = ast.Load())
        if f_async := (self._hasFlag(flags, inspect.CO_COROUTINE) or self._hasFlag(flags, inspect.CO_ASYNC_GENERATOR)):
            class_def = ast.AsyncFunctionDef
        else:
            class_def = ast.FunctionDef

        #300. Prepare simple body statements
        #310. Await statement
        # await asyncio.sleep(0)
        if f_async:
            stmt_await = [ast.Expr(
                value = ast.Await(
                    value = ast.Call(
                        func = Attr(Name('asyncio'), 'sleep')
                        ,args = [Const(0)]
                        ,keywords = []
                    )
                )
            )]
        else:
            stmt_await = []

        #330. Yield statement
        # yield 0
        if f_generator := (
            self._hasFlag(flags, inspect.CO_GENERATOR)
            or self._hasFlag(flags, inspect.CO_ASYNC_GENERATOR)
            or self._hasFlag(flags, inspect.CO_ITERABLE_COROUTINE)
        ):
            stmt_yield = [ast.Expr(value = ast.Yield(value = Const(0)))]
        else:
            stmt_yield = []

        #350. Pass statement
        # pass
        if not (f_async | f_generator):
            stmt_pass = [ast.Pass()]
        else:
            stmt_pass = []

        #350. Decorator statement
        # @types.coroutine
        if self._hasFlag(flags, inspect.CO_ITERABLE_COROUTINE):
            deco_list = [Attr(Name('types'), 'coroutine')]
            ns_types = {'types' : types}
        else:
            deco_list = []
            ns_types = {}

        #500. Assemble the function definition
        func_def = class_def(
            name = self.dst.__name__
            ,args = args
            ,body = stmt_await + stmt_yield + stmt_pass
            ,decorator_list = deco_list
            ,returns = None
            ,type_comment = None
        )

        #700. Compile the module
        #[ASSUMPTION]
        #[1] In case of possible extension, we introduce a universal namespace `ns`
        ns = {**ns_types}
        module = ast.Module(body = [func_def], type_ignores = [])
        ast.fix_missing_locations(module)
        exec(compile(module, '<ast-expand-sig>', 'exec'), ns)

        return(ns[self.dst.__name__])

    #160. Function to extract the signature as well as useful attributes of the callable
    def _getSig(self, func : callable) -> dict:
        #010. Local environment
        rstOut = {}

        #100. Retrieve the signature of the callable
        #[ASSUMPTION]
        #[1] Python evaluates the parameters passed for the call of a function in the priority as listed in <arg_kind>
        rstOut['sig'] = signature(func).parameters.values()
        rstOut['bykind'] = {
            n : {
                i : s
                for i,s in enumerate(rstOut['sig'])
                if s.kind == s.__getattribute__(n)
            }
            for n in self.arg_kind
        }
        rstOut['has_vp'] = len(rstOut['bykind']['VAR_POSITIONAL']) == 1
        rstOut['has_vk'] = len(rstOut['bykind']['VAR_KEYWORD']) == 1

        #300. Identify specific arguments
        #301. All arguments
        #[1] We do all below processes assuming that <dict> in Python >= 3.7 is ordered
        #    https://www.geeksforgeeks.org/are-python-dictionaries-ordered/
        rstOut['args'] = {s.name : s.default for s in rstOut['sig']}

        #305. Named arguments
        rstOut['named'] = {s.name : s.default for s in rstOut['sig'] if s.kind not in [s.VAR_POSITIONAL,s.VAR_KEYWORD]}

        #307. Arguments with default values
        rstOut['defaulted'] = {s.name : s.default for s in rstOut['sig'] if s.default is not s.empty}

        #310. POSITIONAL_ONLY
        rstOut['po'] = {s.name : s.default for s in rstOut['bykind']['POSITIONAL_ONLY'].values()}
        rstOut['len_po'] = len(rstOut['po'])

        #330. POSITIONAL_OR_KEYWORD
        rstOut['pk_wo_def'] = {
            s.name : s.default
            for s in rstOut['bykind']['POSITIONAL_OR_KEYWORD'].values()
            if s.default is s.empty
        }
        rstOut['pk_w_def'] = {
            s.name : s.default
            for s in rstOut['bykind']['POSITIONAL_OR_KEYWORD'].values()
            if s.default is not s.empty
        }
        rstOut['len_pk_wo_def'] = len(rstOut['pk_wo_def'])
        rstOut['len_pk_w_def'] = len(rstOut['pk_w_def'])

        #360. All positional arguments
        rstOut['pos'] = (
            rstOut['bykind']['POSITIONAL_ONLY']
            | rstOut['bykind']['POSITIONAL_OR_KEYWORD']
            | rstOut['bykind']['VAR_POSITIONAL']
        )

        #370. KEYWORD_ONLY
        rstOut['ko'] = {s.name : s.default for s in rstOut['bykind']['KEYWORD_ONLY'].values()}
        rstOut['ko_w_def'] = {
            s.name : s.default
            for s in rstOut['bykind']['KEYWORD_ONLY'].values()
            if s.default is not s.empty
        }

        #395. All keyword arguments
        rstOut['kw'] = rstOut['bykind']['KEYWORD_ONLY'] | rstOut['bykind']['VAR_KEYWORD']

        #500. Identify specific attributes
        #510. Docstring
        rstOut['doc'] = func.__doc__ or ''

        #520. Code Object Flags
        #[ASSUMPTION]
        #[1] It is tested that <co_varnames> is also matched against the indication in <co_flags>
        #[2] Failure on the matching will lead to below exception
        #    ValueError: code: co_varnames is too small
        #[3] <co_flags> cannot be updated using <.replace()> method, so if the wrapper has <*pos>, CO_VARARGS is set to the
        #     wrapped result anyway, same as CO_VARKEYWORDS
        #[4] Hence, when we need to chain the expansion of signatures with many functions, direct search in
        #     <func.__code__.co_flags> fails to indicate the correct flags of <*pos> and <**kw> when <func> is already expanded
        #     with signatures of other functions
        #[5] As a workaround, as as what <functools.wraps> does, we always prioritize the search for the flags in the newly
        #     created attribute <__wrapped__> and do not provide alternatives like <follow_wrapped = False>, because it never
        #     works for a nested expansion
        #[6] Although it is NOT recommended (see `inspect` in official documents) to use <co_flags> for function type
        #     determination, there is no precise solution to recognize a `function wrapped by types.coroutine()` except from
        #     <co_flags> until Python==3.14, given that we cannot execute such function to verify its runtime behavior at all
        #     times. Therefore, we can neither abandon the usage of <co_flags> at present
        if hasattr(func, '__wrapped__'):
            rstOut['flags'] = func.__wrapped__.__code__.co_flags
        else:
            rstOut['flags'] = func.__code__.co_flags

        return(rstOut)

    #170. Function to reshape the parameters at runtime
    def _reshapeParams(self, *pos, **kw) -> tuple[tuple, dict]:
        #100. Create a dummy class and make it (relatively) unique
        def _init(self, key : str):
            self.key = key
        cls_dummy = type(f'tmpcls{dt.datetime.now().strftime("%Y%m%d%H%M%S%f")}', (object,), {'__init__' : _init})

        #070. Patch the inputs where necessary
        #[ASSUMPTION]
        #[1] We pretend that the defaults for POSITIONAL_OR_KEYWORD-with-defaults and KEYWORD_ONLY-with-defaults are always
        #     set in <kw>, in case there are no explicit inputs for them
        #[2] Only by doing so, can we set the additional provision during the expansion of <dst>, for it to fill the
        #     respective holes in <src>
        #[3] Input value recognition priority is as below
        #    [1] If the argument is provided in <pos>, it is programmatically taken prior to the same provision in <kw>
        #    [2] If it is provided in <kw>, we take it prior to any of its default values in either <src> or <dst>
        #    [3] If the same argument exists in both callables, we still take the default value in <dst> prior to <src>
        kw_ = (
            { k:cls_dummy(k) for k,v in self.sig_src['pk_w_def'].items() }
            | { k:cls_dummy(k) for k,v in self.sig_dst['pk_w_def'].items() }
            | { k:cls_dummy(k) for k,v in self.sig_src['ko_w_def'].items() }
            | { k:cls_dummy(k) for k,v in self.sig_dst['ko_w_def'].items() }
            | kw
        )

        #090. Translate the parameters in terms of the merged signature
        #[ASSUMPTION]
        #[1] In order to make a valid call, we do not accept insufficient parameters passed
        #[2] However, we allow excessive parameters, i.e. multiple inputs, for we allow the patching at above steps
        in_pos, in_kw = nameArgsByFormals(self.passer, pos_ = pos, kw_ = kw_, coerce_ = True, strict_ = True)

        #100. Split positional parameters
        #[ASSUMPTION]
        #[1] To fulfill the arguments for <src> and <dst> separately, we need to split the parameters according to their
        #     respective signatures
        #[2] That is, we identify the parameters specifically for <dst> and put the rest into <*pos> of the signature of <dst>
        #[3] Since <*pos> is after POSITIONAL_ONLY and POSITIONAL_OR_KEYWORD, we handle these <kind>s together
        #[4] We do the same for the rest <kind> of parameters as well
        in_po_dst = in_pos[:self.sig_dst['len_po']]
        in_po_src = in_pos[self.sig_dst['len_po']:self.len_po]
        in_pk_wo_def_dst = in_pos[self.len_po:(bgn_pk_wo_def_src := self.len_po + self.sig_dst['len_pk_wo_def'])]
        in_pk_wo_def_src = in_pos[bgn_pk_wo_def_src:(bgn_pk_w_def_dst := self.len_po + self.len_pk_wo_def)]
        in_pk_w_def_dst = in_pos[bgn_pk_w_def_dst:(bgn_pk_w_def_src := self.len_po + self.len_pk_wo_def + self.sig_dst['len_pk_w_def'])]
        in_pk_w_def_src = in_pos[bgn_pk_w_def_src:(bgn_vp_src := self.len_po + self.len_pk_wo_def + self.len_pk_w_def)]
        in_vp_src = in_pos[bgn_vp_src:]

        #300. Split keyword parameters
        in_ko_dst = {k:v for k,v in in_kw.items() if k in self.sig_dst['ko']}
        in_ko_src = {k:v for k,v in in_kw.items() if k in self.ko_fr_src}
        in_kw_rest = {k:v for k,v in in_kw.items() if k not in self.ko}

        #500. Prepare the adjustment on those POSITIONAL_OR_KEYWORD which are translated into keyword input
        kw_wo_def_dst = {k:v for k,v in in_kw_rest.items() if k in self.sig_dst['pk_wo_def']}
        kw_wo_def_src = {k:v for k,v in in_kw_rest.items() if k in self.pk_wo_def_fr_src}
        kw_w_def_dst = {k:v for k,v in in_kw_rest.items() if k in self.sig_dst['pk_w_def']}
        kw_w_def_src = {k:v for k,v in in_kw_rest.items() if k in self.pk_w_def_fr_src}
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
        out_pos_pre = in_po_dst + in_pk_wo_def_dst + adj_pk_wo_def_dst + in_pk_w_def_dst + adj_pk_w_def_dst
        out_vp_pre = in_po_src + in_pk_wo_def_src + adj_pk_wo_def_src + in_pk_w_def_src + adj_pk_w_def_src + in_vp_src
        out_ko_pre = in_ko_dst
        out_vk_pre = in_ko_src | in_vk_src

        #830. Flag the parameters retained from default values instead of from inputs
        #[ASSUMPTION]
        #[1] This step should be done at runtime
        self._isdefault = { k:False for k in self._defaults.keys() }
        self._isdefault_scope = {
            'src' : { k:False for k in self.sig_src['defaulted'].keys() }
            ,'dst' : { k:False for k in self.sig_dst['defaulted'].keys() }
        }
        for v in (out_pos_pre + out_vp_pre + tuple(out_ko_pre.values()) + tuple(out_vk_pre.values())):
            if isinstance(v, cls_dummy):
                self._isdefault[v.key] = True
                if v.key in self.sig_src['defaulted']:
                    self._isdefault_scope['src'][v.key] = True
                if v.key in self.sig_dst['defaulted']:
                    self._isdefault_scope['dst'][v.key] = True
                    if v.key in self.sig_src['defaulted']:
                        self._isdefault_scope['src'][v.key] = False

        #890. Obtain the actual parameters for the placeholders
        out_pos = [ v if not isinstance(v, cls_dummy) else self._defaults.get(v.key) for v in out_pos_pre ]
        out_vp = [ v if not isinstance(v, cls_dummy) else self._defaults.get(v.key) for v in out_vp_pre ]
        out_ko = { k:(v if not isinstance(v, cls_dummy) else self._defaults.get(v.key)) for k,v in out_ko_pre.items() }
        out_vk = { k:(v if not isinstance(v, cls_dummy) else self._defaults.get(v.key)) for k,v in out_vk_pre.items() }

        return(out_pos + out_vp, out_ko | out_vk)

    #300. Create the decorator
    def _wrapper(self, dst : callable) -> callable:
        #010. Local environment
        rest_src = {**self.sig_src['named']}

        #200. Identify specific arguments
        #290. VAR_KEYWORD
        if (not self.sig_dst['has_vp']) and (not self.sig_dst['has_vk']):
            raise TypeError(
                f'[{dst.__name__}]No expansion of VAR_POSITIONAL or VAR_KEYWORD can be conducted for <{self.src.__name__}>!'
            )

        if self.sig_src['args']:
            if not self.sig_dst['has_vp']:
                if self.sig_src['pos']:
                    raise TypeError(f'[{dst.__name__}]Missing VAR_POSITIONAL to expand for <{self.src.__name__}>!')

            if not self.sig_dst['has_vk']:
                if self.sig_src['kw']:
                    raise TypeError(f'[{dst.__name__}]Missing VAR_KEYWORD to expand for <{self.src.__name__}>!')

        #300. Identify specific attributes
        #320. Code Object Flags
        flags_dst = dst.__code__.co_flags

        #400. Merge arguments
        #410. POSITIONAL_ONLY
        #[ASSUMPTION]
        #[1] At this step, there may be arguments of other <kind> in <src> changed into this <kind> in <dst>
        #[2] We should honor this change by prioritize the <kind> in <dst>, similar for all the rest process
        po_fr_src = {k:v for k,v in self.sig_src['po'].items() if k in rest_src and k not in self.sig_dst['args']}
        po = self.sig_dst['po'] | po_fr_src
        self.len_po = len(po)
        rest_src = {k:v for k,v in rest_src.items() if k not in po}

        #430. POSITIONAL_OR_KEYWORD
        #[ASSUMPTION]
        #[1] In this <kind>, arguments without defaults are always to the left of those with defaults
        #[2] There are two scenarios given <src> has <arg1, arg2 = 2>
        #    [1] If <dst> has <arg3 = 3>, we should put <arg3> between <arg1> and <arg2>, i.e. before the first one with default value
        #    [2] If <dst> has <arg3> (i.e. without default), we should put <arg3> before <arg1>
        self.pk_wo_def_fr_src = {k:v for k,v in self.sig_src['pk_wo_def'].items() if k in rest_src and k not in self.sig_dst['args']}
        pk_wo_def = self.sig_dst['pk_wo_def'] | self.pk_wo_def_fr_src
        self.len_pk_wo_def = len(pk_wo_def)
        rest_src = {k:v for k,v in rest_src.items() if k not in pk_wo_def}

        self.pk_w_def_fr_src = {k:v for k,v in self.sig_src['pk_w_def'].items() if k in rest_src and k not in self.sig_dst['args']}
        pk_w_def = self.sig_dst['pk_w_def'] | self.pk_w_def_fr_src
        self.len_pk_w_def = len(pk_w_def)
        rest_src = {k:v for k,v in rest_src.items() if k not in pk_w_def}

        #450. VAR_POSITIONAL
        vp = {s.name : s.default for s in self.sig_src['bykind']['VAR_POSITIONAL'].values()}

        #470. KEYWORD_ONLY
        #[ASSUMPTION]
        #[1] Sequence (even with or without defaults) does not matter for this <kind> of arguments
        #[2] After this step, <rest_src> must have been empty, so there is no need for verification
        self.ko_fr_src = {k:v for k,v in self.sig_src['ko'].items() if k in rest_src and k not in self.sig_dst['args']}
        ko = self.sig_dst['ko'] | self.ko_fr_src
        rest_src = {k:v for k,v in rest_src.items() if k not in ko}
        self.ko = ko

        #490. VAR_KEYWORD
        vk = {s.name : s.default for s in self.sig_src['bykind']['VAR_KEYWORD'].values()}

        #500. Prepare final attributes for Code Object
        #510. Full arguments
        args_full = po | pk_wo_def | pk_w_def | vp | ko | vk
        len_args = len(args_full)

        #520. Basic Code Object is from the wrapped callable
        co_base = {k:getattr(dst.__code__, k) for k in dir(dst.__code__) if k.startswith('co_')}

        #530. Prepare merged flags
        flags_from_src = 0
        if self._hasFlag(self.sig_src['flags'], inspect.CO_VARARGS):
            flags_from_src += inspect.CO_VARARGS
        if self._hasFlag(self.sig_src['flags'], inspect.CO_VARKEYWORDS):
            flags_from_src += inspect.CO_VARKEYWORDS

        if self._hasFlag(flags_dst, inspect.CO_VARARGS):
            flags_dst -= inspect.CO_VARARGS
        if self._hasFlag(flags_dst, inspect.CO_VARKEYWORDS):
            flags_dst -= inspect.CO_VARKEYWORDS

        flags = flags_from_src | flags_dst

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
                'co_argcount' : self.len_po + len(pk_wo_def) + len(pk_w_def)
                ,'co_posonlyargcount' : self.len_po
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
        #710. Setup arguments
        #[ASSUMPTION]
        #[1] `kw_defaults` should have the same length as `kwonlyargs`
        #[2] We would provide the default values at later steps, hence here we should nullify them here
        vararg_ = None if len(vp) == 0 else [ast.arg(arg = n) for n in vp.keys()][0]
        kwarg_ = None if len(vk) == 0 else [ast.arg(arg = n) for n in vk.keys()][0]
        func_args = ast.arguments(
            posonlyargs = [ast.arg(arg = n) for n in po.keys()]
            ,args = [ast.arg(arg = n) for n in (pk_wo_def | pk_w_def).keys()]
            ,vararg = vararg_
            ,kwonlyargs = [ast.arg(arg = n) for n in ko.keys()]
            ,kw_defaults = [None for n in ko.keys()]
            ,kwarg = kwarg_
            ,defaults = []
        )

        #730. Create the passer
        passer = self._nullfn(flags, func_args)

        #770. Correct its attributes
        passer.__name__ = dst.__name__
        passer.__qualname__ = dst.__qualname__
        passer.__module__ = dst.__module__
        passer.__defaults__ = tuple(pk_w_def.values())
        passer.__kwdefaults__ = {k:v for k,v in ko.items() if v is not inspect._empty}
        passer.__annotations__ = self.src.__annotations__ | dst.__annotations__
        passer.__doc__ = (
            (self.sig_dst['doc'] if self.sig_dst['doc'] else '')
             + ('\n\n' if (self.sig_dst['doc'] and self.sig_src['doc']) else '')
            + ((f'Expanded from: {self.src.__name__}\n' + self.sig_src['doc']) if self.sig_src['doc'] else '')
        )
        if not passer.__doc__:
            setattr(passer, '__doc__', None)

        #790. Broadcast it for other internal usage
        self.passer = passer

        #800. Reshape the call
        #[ASSUMPTION]
        #[1] Before this step, we transmuted the arguments; at this step, we translate the parameters passed during the call
        #[2] When <__doc__> is None, Python will automatically look up the consecutive comments just above the function declaration
        #     and replace it with them
        #[3] That is why we skip an empty line to ensure this block of comments is not taken as the nil <__doc__>

        def deco(*pos, **kw):
            #100. Reshape the parameters at runtime
            out_pos, out_kw = self._reshapeParams(*pos, **kw)

            #500. Call <dst>
            return(dst(*out_pos, **out_kw))

        #900. Prepare the output
        _ = deco.__code__.replace(**co_deco)
        deco.__wrapped__ = passer
        attr_deco = ['__name__','__qualname__','__defaults__','__kwdefaults__','__annotations__','__doc__','__module__']
        for attr in attr_deco:
            setattr(deco, attr, getattr(passer, attr))

        #999. Return the wrapped one
        return(deco)

    #500. Function to identify the input value by argument name
    def getParam(self, arg : str, pos_src : tuple, kw_src : dict, *, inc_default : bool = True):
        #100. Determine the approach
        if inc_default:
            args_getdef = {
                'kw_' : (kw_src | { k:v for k,v in self.sig_src['defaulted'].items() if k not in kw_src })
                ,'strict_' : True
            }
        else:
            args_getdef = {
                'kw_' : kw_src
                ,'strict_' : False
            }

        #500. Reshape the input
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
            ,coerce_ = True
            ,**args_getdef
        )

        #900. Prioritize the retrieval
        if len(pos_in) > (arg_loc := [ i for i,s in enumerate(self.sig_src['sig']) if s.name == arg ][0]):
            return(pos_in[arg_loc])
        else:
            return(kw_in.get(arg))

    #600. Function to insert the dedicated input parameters in terms of the signature
    def insParams(self, args_ins : dict, pos_src : tuple, kw_src : dict) -> tuple[tuple, dict]:
        #[ASSUMPTION]
        #[1] We cannot standardize the input as <updParams> does, as the input has some holes as we know at the wrapping, while
        #     the function <nameArgsByFormals> would skip the holes in <pos_src> which causes mismatching of positional parameters

        #005. Update the status for the inserted arguments
        for arg in args_ins.keys():
            if arg in self._isdefault:
                self._isdefault[arg] = False
            if arg in self._isdefault_scope['src']:
                self._isdefault_scope['src'][arg] = False

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
        #[2] If any keyword parameter is from its default value in the signature, we remove it
        pos_out, kw_out = nameArgsByFormals(self.src, pos_ = tuple(pos_in), kw_ = kw_in, coerce_ = True, strict_ = True)
        kw_out = {k:v for k,v in kw_out.items() if not self.isDefault(k, 'src')}
        return(pos_out, kw_out)

    #700. Function to update the dedicated input parameters in terms of the signature
    def updParams(self, args_upd : dict, pos_src : tuple, kw_src : dict) -> tuple[tuple, dict]:
        #005. Update the status for the inserted arguments
        for arg in args_upd.keys():
            if arg in self._isdefault:
                self._isdefault[arg] = False
            if arg in self._isdefault_scope['src']:
                self._isdefault_scope['src'][arg] = False

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
        #[2] If any keyword parameter is from its default value in the signature, we remove it
        pos_out, kw_out = nameArgsByFormals(self.src, pos_ = tuple(pos_in), kw_ = kw_in, coerce_ = True, strict_ = True)
        kw_out = {k:v for k,v in kw_out.items() if not self.isDefault(k, 'src')}
        return(pos_out, kw_out)

    #800. Miscellaneous functions
    #810. Verify the conflict of argument names in both callables, except those declared as acceptable
    def vfyConflict(self, args_share : dict = {}):
        if (arg_conflict := [ k for k in self.sig_dst['named'].keys() if k in self.sig_src['args'] and k not in args_share ]):
            raise NotImplementedError(f'[{self.dst.__name__}]Detected conflict arguments: {str(arg_conflict)}')

    #820. Verify whether the parameter is from the default value of an argument, useful at runtime
    def isDefault(self, arg : str, scope_ : str = 'src') -> bool:
        if scope_ in self._isdefault_scope:
            return(self._isdefault_scope.get(scope_).get(arg, False))
        return(self._isdefault.get(arg, False))

    #900. Set the instance as a decorator
    def __call__(self, dst : callable) -> callable:
        #010. Local environment
        self.dst = dst
        self.sig_dst = self._getSig(dst)
        #[ASSUMPTION]
        #[1] Overwrite the default values of those in <src>, with those in <dst>
        self._defaults = self.sig_src['defaulted'] | self.sig_dst['defaulted']

        #990. Return the wrapped result
        return(self._wrapper(dst))
#End ExpandSignature

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create environment.
    import sys
    import asyncio, queue, threading, types, inspect
    from typing import Any
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import withDefaults
    from omniPy.AdvOp import ExpandSignature

    #030. Class to receive both the yield values and the return values from a generator
    # https://stackoverflow.com/questions/34073370/best-way-to-receive-the-return-value-from-a-python-generator
    class GenReturnAccessor:
        def __init__(self, gen):
            self.gen = gen

        def __iter__(self):
            self.value = yield from self.gen
            return self.value

    #040. 一个兼容运行器，在无事件循环时用`asyncio.run`；若当前线程已有`loop`，则在新线程中运行
    #[ASSUMPTION]
    #[1] 来自ChatGPT-5.0
    def runAsyncCompat(coro):
        try:
            asyncio.get_running_loop()
        except RuntimeError:
            # 当前线程没有运行中的`loop`
            return(asyncio.run(coro))

        # 已有运行中的`loop`（如Jupyter）
        q = queue.Queue()
        def worker():
            try:
                # 在新线程里独立运行一个事件循环
                res = asyncio.run(coro)
                q.put((True, res))
            except Exception as e:
                q.put((False, e))
        t = threading.Thread(target = worker, daemon = True)
        t.start()
        ok, payload = q.get()
        if ok:
            return(payload)
        raise payload

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

        print(f'Whether <arg8> is from default value: <{str(eSig.isDefault("arg8", "all"))}>')

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
    # Whether <arg8> is from default value: <True>
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
    # Whether <arg8> is from default value: <False>
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
    # Whether <arg8> is from default value: <True>
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
    #[ASSUMPTION]
    #[1] If you need to chain the expansion, make sure either of below designs is set
    #    [1] Each of the nodes is in a separate module
    #    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module
    #[2] <arg9> is the shared argument in both expanded callables. Once the last node is called without <arg9> as input,
    #     its default value is honored so its flag is <True> in <dst>. In its parent node(s), <arg9> will hence be provided
    #     with the value as retained from the last node, therefore all inputs for it will be deemed <not from default>
    def src3(arg1, *, arg3 = 3, **kw):
        print('This is src3:')
        print(f'arg1 : {str(arg1)}')
        print(f'arg3 : {str(arg3)}')
        print(f'kw : {str(kw)}')

    @(eSig := ExpandSignature(src3))
    def dst3(arg4, /, *pos, arg8 = 8, arg9 = 9, **kw):
        src3(*pos, **kw)
        print('This is dst3:')
        print(f'arg4 : {str(arg4)}')
        print(f'arg3 : {str(eSig.getParam("arg3", pos, kw))}')
        print(f'Whether <arg8> is from default value: <{str(eSig.isDefault("arg8", "dst"))}>')
        print(f'Whether <arg9> is from default value of <dst>: <{str(eSig.isDefault("arg9", "dst"))}>')

    @(eSig2 := ExpandSignature(dst3))
    def dst4(self, /, *pos, arg5, arg9 = 90, **kw):
        pos_out, kw_out = eSig2.insParams({'arg9' : arg9}, pos, kw)
        dst3(*pos_out, **kw_out)
        print('This is dst4:')
        print(f'arg5 : {str(arg5)}')
        print(f'arg3 : {str(eSig2.getParam("arg3", pos, kw))}')
        print(f'Whether <arg8> is from default value of <src>: <{str(eSig2.isDefault("arg8", "src"))}>')
        print(f'Whether <arg9> is from default value of <dst>: <{str(eSig2.isDefault("arg9", "dst"))}>')
        print(f'Whether <arg9> is from default value of <src>: <{str(eSig2.isDefault("arg9", "src"))}>')

    help(dst4)
    # Help on function dst4 in module __main__:
    # dst4(self, arg4, /, arg1, *, arg5, arg9=90, arg8=8, arg3=3, **kw)

    #[ASSUMPTION]
    #[1] The parameter passed to <arg8> is correctly detected
    dst4(1, 4, 1, arg5 = 5, arg7 = 7)
    # This is src3:
    # arg1 : 1
    # arg3 : 3
    # kw : {'arg7': 7}
    # This is dst3:
    # arg4 : 4
    # arg3 : 3
    # Whether <arg8> is from default value: <True>
    # Whether <arg9> is from default value of <dst>: <False>
    # This is dst4:
    # arg5 : 5
    # arg3 : 3
    # Whether <arg8> is from default value of <src>: <True>
    # Whether <arg9> is from default value of <dst>: <True>
    # Whether <arg9> is from default value of <src>: <False>

    #500. Generator
    def gen_print(txt : str, n : int = 5, cap : int = 4) -> str:
        print('gen_print begin')
        for i in range(n):
            if i < cap:
                msg = yield f'print [{txt}] [{i}] out of [{n}]'
                print(f'gen_print {msg=}')
        print('gen_print end')
        return('gen_print done')

    # Verify the code flag
    gen_print.__code__.co_flags & inspect.CO_GENERATOR == inspect.CO_GENERATOR
    # True

    #510. Change the behavior
    #[ASSUMPTION]
    #[1] In such case, the wrapper cannot handle the `yield` values one by one
    @(eSig := ExpandSignature(gen_print))
    def gen_print2(usr : str, *pos, **kw):
        print('gen_print2 begin')
        # Local environment
        args_share = {}
        eSig.vfyConflict(args_share)
        pos_out, kw_out = eSig.insParams(args_share, pos, kw)

        rst = yield from eSig.src(*pos_out, **kw_out)

        print('gen_print2 end')
        return(rst)

    help(gen_print2)
    # Help on function gen_print2 in module __main__:
    # gen_print2(usr: str, txt: str, n: int = 5, cap: int = 4) -> str

    # Verify the code flag
    gen_print2.__wrapped__.__code__.co_flags & inspect.CO_GENERATOR == inspect.CO_GENERATOR
    # True

    g_prep = gen_print2('User', 'paper')
    r_gen = GenReturnAccessor(g_prep)
    for f in r_gen:
        print(f)
    print(f'{r_gen.value=}')
    # gen_print2 begin
    # gen_print begin
    # print [paper] [0] out of [5]
    # gen_print msg=None
    # print [paper] [1] out of [5]
    # gen_print msg=None
    # print [paper] [2] out of [5]
    # gen_print msg=None
    # print [paper] [3] out of [5]
    # gen_print msg=None
    # gen_print end
    # gen_print2 end
    # r_gen.value='gen_print done'

    #550. Resemble the behavior of the source generator
    #[ASSUMPTION]
    #[1] In such case, the wrapper is able to handle the `yield` values one by one
    @(eSig := ExpandSignature(gen_print))
    def gen_print3(usr : str, *pos, **kw):
        print('gen_print3 begin')
        # Local environment
        args_share = {}
        eSig.vfyConflict(args_share)
        pos_out, kw_out = eSig.insParams(args_share, pos, kw)
        # 创建内层生成器实例
        inner_gen = eSig.src(*pos_out, **kw_out)

        try:
            while True:
                # 获取内层yield结果
                inner_yield = next(inner_gen)

                # 将内层yield结果乘以2（因无类型限制，若为字符串则重复两次）
                doubled_result = inner_yield * 2

                # 将处理后的结果yield
                yield doubled_result

        except StopIteration as e:
            # 获取内层最终return值
            final_return_value = e.value
            print('gen_print3 end')
            # 将内层的return值作为外层的return值
            return(f'[{usr}] {final_return_value}')

    help(gen_print3)
    # Help on function gen_print2 in module __main__:
    # gen_print3(usr: str, txt: str, n: int = 5, cap: int = 4) -> str

    g_prep3 = gen_print3('User', 'word')
    r_gen3 = GenReturnAccessor(g_prep3)
    for f in r_gen3:
        print(f)
    print(f'{r_gen3.value=}')
    # gen_print3 begin
    # gen_print begin
    # print [word] [0] out of [5]print [word] [0] out of [5]
    # gen_print msg=None
    # print [word] [1] out of [5]print [word] [1] out of [5]
    # gen_print msg=None
    # print [word] [2] out of [5]print [word] [2] out of [5]
    # gen_print msg=None
    # print [word] [3] out of [5]print [word] [3] out of [5]
    # gen_print msg=None
    # gen_print end
    # gen_print3 end
    # r_gen3.value='[User] gen_print done'

    #600. Coroutine
    async def aio_add(x : int, y : int) -> int:
        await asyncio.sleep(0)
        return(x + y)

    # Verify the code flag
    aio_add.__code__.co_flags & inspect.CO_COROUTINE == inspect.CO_COROUTINE
    # True

    @(eSig := ExpandSignature(aio_add))
    async def aio_add2(usr : str, *pos, **kw):
        """
        外层协程：调用内层协程并返回结果的平方
        """
        # Local environment
        args_share = {}
        eSig.vfyConflict(args_share)
        pos_out, kw_out = eSig.insParams(args_share, pos, kw)

        # 调用内层协程获取结果
        inner_result = await eSig.src(*pos_out, **kw_out)

        # 内层结果出来后继续等待0秒
        print(f'{usr}: wait once more')
        await asyncio.sleep(0)

        # 返回内层结果的平方
        return inner_result ** 2

    # Verify the code flag
    aio_add2.__wrapped__.__code__.co_flags & inspect.CO_COROUTINE == inspect.CO_COROUTINE
    # True

    #[ASSUMPTION]
    #[1] Apparently the wrapped callable is NOT a coroutine function
    #[2] If one needs to inspect the wrapped callable in below way, add `.__wrapped__` where necessary
    inspect.iscoroutinefunction(aio_add2.__wrapped__)
    # True

    help(aio_add2)
    # Help on function aio_add2 in module __main__:
    # aio_add2(usr: str, x: int, y: int) -> int
    #     外层协程：调用内层协程并返回结果的平方

    print(runAsyncCompat(aio_add2('User', 2, 3)))
    # User: wait once more
    # 25

    #700. Asynchronous generator
    #[ASSUMPTION]
    #[1] Yield integers from start to stop by 1, awaiting delay between items
    #[2] `async` callables are not allowed to `return` values
    async def ag_ticker(start : int, stop : int, delay : float = 0.0) -> int:
        for i in range(start, stop):
            if delay:
                await asyncio.sleep(delay)
            yield i

    # A helper coroutine to collect all items from an async generator into a list
    async def collect(gen):
        out = []
        async for x in gen:
            out.append(x)
        return(out)

    #707. Check the finctionality
    ag_rst1 = runAsyncCompat(collect(ag_ticker(3,7,0.0)))
    print(ag_rst1)
    # [3, 4, 5, 6]

    # Verify the code flag
    ag_ticker.__code__.co_flags & inspect.CO_ASYNC_GENERATOR == inspect.CO_ASYNC_GENERATOR
    # True

    @(eSig := ExpandSignature(ag_ticker))
    async def ag_ticker2(usr : str, /, *pos, **kw):
        """
        外层异步生成器：嵌套调用内层生成器，将结果乘以2
        """
        print('ag_ticker2 begin')
        # Local environment
        args_share = {}
        eSig.vfyConflict(args_share)
        pos_out, kw_out = eSig.insParams(args_share, pos, kw)

        # 使用异步for循环遍历内层生成器的结果
        async for value in eSig.src(*pos_out, **kw_out):
            # 将内层yield结果乘以2，再将其yield
            doubled_value = value * 2
            yield doubled_value

        print('ag_ticker2 end')
        print(f'{usr=}')

    # Verify the code flag
    ag_ticker2.__wrapped__.__code__.co_flags & inspect.CO_ASYNC_GENERATOR == inspect.CO_ASYNC_GENERATOR
    # True

    help(ag_ticker2)
    # Help on function ag_ticker2 in module __main__:
    # ag_ticker2(usr: str, /, start: int, stop: int, delay: float = 0.0) -> int
    #     外层异步生成器：嵌套调用内层生成器，将结果乘以2

    ag_rst2 = runAsyncCompat(collect(ag_ticker2('User',5,8,0.0)))
    print(ag_rst2)
    # ag_ticker2 begin
    # ag_ticker2 end
    # usr='User'
    # [10, 12, 14]

    #800. Iterable coroutine
    @types.coroutine
    def icoro1(n : int) -> int:
        for i in range(n):
            msg = yield i
            print(f'icoro1 {msg=}')
        # 随后（例如`send(None)`或`await`驱动的继续执行）返回最终结果
        return n * 2

    # Verify the code flag
    icoro1.__code__.co_flags & inspect.CO_ITERABLE_COROUTINE == inspect.CO_ITERABLE_COROUTINE
    # True

    # Helper function to run the iterable coroutine
    #[ASSUMPTION]
    #[1] 来自ChatGPT-5.0
    def runIterCoro(func, *pos, **kw):
        """ 用生成器协议驱动`iterable coroutine`，取最终返回值 """
        g = func(*pos, **kw)
        # 预激活
        val = next(g)
        print(f'inner icoro yield={val}')
        i = 0
        try:
            while True:
                # 推进到`return`
                val = g.send(f'send {i=}')
                print(f'inner icoro yield={val}')
                i += 1
        except StopIteration as e:
            return e.value

    @(eSig := ExpandSignature(icoro1))
    @types.coroutine
    def icoro2(usr : str, /, *pos, **kw):
        print('icoro2 begin')
        # Local environment
        args_share = {}
        eSig.vfyConflict(args_share)
        pos_out, kw_out = eSig.insParams(args_share, pos, kw)

        val = yield from eSig.src(*pos_out, **kw_out)

        print('icoro2 end')
        print(f'{usr=}')
        return(val)

    # Verify the code flag
    icoro2.__wrapped__.__code__.co_flags & inspect.CO_ITERABLE_COROUTINE == inspect.CO_ITERABLE_COROUTINE
    # True

    help(icoro2)
    # Help on function icoro2 in module __main__:
    # icoro2(usr: str, /, n: int) -> int

    print('icoro2(3) -> ', runIterCoro(icoro2, 'User', 3))
    # icoro2 begin
    # inner icoro yield=0
    # icoro1 msg='send i=0'
    # inner icoro yield=1
    # icoro1 msg='send i=1'
    # inner icoro yield=2
    # icoro1 msg='send i=2'
    # icoro2 end
    # usr='User'
    # icoro2(3) ->  6

    #900. Interaction with <functools.wraps>
    from functools import wraps
    @wraps(dst4)
    def dst5(*pos, **kw):
        return(dst4(*pos, **kw))

    #[ASSUMPTION]
    #[1] The signature seems correct as expected
    #[2] However, <__name__> is the wrapped one instead of the wrapper, which is the design but not what we need
    help(dst5)
    # Help on function dst4 in module __main__:
    # dst4(self, arg4, /, arg1, *, arg5, arg9=90, arg8=8, arg3=3, **kw)

    #[ASSUMPTION]
    #[1] <dst5.__code__.co_flags> is <15>, indicating both <*pos> and <**kw> exists in the signature
    #[2] <dst5.__wrapped__.__code__.co_flags> is <31>, also including both <*pos> and <**kw>, as it directly retrieves
    #     the value from <dst4.__code__.co_flags>
    #[3] However in our design for an expanded callable
    #    [1] <dst4.__code__.co_flags> is <31>, coming from the wrapper in <ExpandSignature> that takes both <*pos> and
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
    #[1] For Python <= 3.11, <ExpandSignature> cannot wrap any function that is already wrapped by <functools.wraps>
    #[2] One can replace most cases of decoration with <functools.wraps>, with some exceptions
    #    [1] <AdvOp.simplifyDeco> is defined to wrap a decorator, instead of expand its signature
    #    [2] <AdvOp.withDefaults> is defined to mask the signature
    #[3] If one needs to chain the expansion, every intermediate expansion must be done by <ExpandSignature>

#-Notes- -End-
'''
