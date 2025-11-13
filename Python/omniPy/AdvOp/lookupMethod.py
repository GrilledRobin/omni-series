#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re, ast, inspect
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from typing import Optional
from omniPy.AdvOp import importByStr, ls_frame, ExpandSignature

def lookupMethod(
    apiCls : str = None
    ,apiPkg : Optional[str] = None
    ,apiPfx : str = ''
    ,apiSfx : str = ''
    ,lsOpt : dict = {}
    ,attr_handler : Optional[str] = None
    ,attr_hdl_yield : Optional[str] = None
    ,attr_hdl_send : Optional[str] = None
    ,attr_kwInit : Optional[str] = None
    ,attr_assign : Optional[str] = None
    ,attr_return : Optional[str] = None
    ,coerce_ : bool = True
) -> callable:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to lookup the callable from a dedicated package, a frame, or a stack of frames, by the provided pattern  #
#   | of name, and escalate it into a separate callable with <self> as the first positional argument, for further binding to an         #
#   | instance as a method. Meanwhile, it enables to call the further bound method by ignoring excessive parameters.                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Dynamically lookup the method for an instance                                                                                  #
#   |[2] Prepare descriptor to enable dynamic method lookup                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |apiCls            :   <str     > Class/owner name of the method to lookup and bind                                                 #
#   |                      [None                ]<Default> System would raise exception if it is not provided                           #
#   |                      [str                 ]          Any string that is legal to form attribute names of a class                  #
#   |apiPkg            :   <str     > Package name in which to lookup the dedicated callable                                            #
#   |                      [None                ]<Default> System would search the callable from current session                        #
#   |                      [str                 ]          System would search the callable from within the package                     #
#   |apiPfx            :   <str     > Prefix of the pattern to search for the name of the callable: <apiPfx> + <apiCls> + <apiSfx>      #
#   |                      [<empty str>         ]<Default> No specific prefix                                                           #
#   |                      [str                 ]          Set a proper prefix to validate the search                                   #
#   |apiSfx            :   <str     > Suffix of the pattern to search for the name of the callable: <apiPfx> + <apiCls> + <apiSfx>      #
#   |                      [<empty str>         ]<Default> No specific suffix                                                           #
#   |                      [str                 ]          Set a proper suffix to validate the search                                   #
#   |lsOpt             :   <dict    > Additional options for <ls_frame> given <apiPkg> is not provided, for search in current session   #
#   |                      [<empty dict>        ]<Default> No additional options, see function definition for details                   #
#   |                      [dict                ]          See <AdvOp.ls_frame> for additional options                                  #
#   |attr_handler      :   <str     > Attribute name to get from the bound instance, to mutate the result returned from the method call #
#   |                      [None                ]<Default> No need to mutate the result from the newly bound method                     #
#   |                      [str                 ]          Existing attribute to handle the result from the newly bound method          #
#   |attr_hdl_yield    :   <str     > Attribute name to get from the bound instance, to mutate the result yielded from the method call  #
#   |                      [None                ]<Default> No need to mutate the result from the newly bound method                     #
#   |                      [str                 ]          Existing attribute to handle the result from the newly bound method          #
#   |attr_hdl_send     :   <str     > Attribute name to get from the bound instance, to mutate the `send()` message before it reaches   #
#   |                       the inner generator, a.k.a. <src>, if it is a generator in the first place                                  #
#   |                      [None                ]<Default> No need to mutate the result from the newly bound method                     #
#   |                      [str                 ]          Existing attribute to handle the result from the newly bound method          #
#   |attr_kwInit       :   <str     > Attribute name to get from the bound instance, to initialize the keyword arguments of the newly   #
#   |                       bound method at the binding stage                                                                           #
#   |                      [None                ]<Default> No need to adjust the default keyword arguments of the newly bound method    #
#   |                      [str                 ]          Existing attribute to initialize the keyword arguments of the newly bound    #
#   |                                                       method                                                                      #
#   |attr_assign       :   <str     > Attribute name to get from the bound instance, to assign the result from the newly bound method   #
#   |                      [None                ]<Default> No need to store the result of the newly bound method to another attribute   #
#   |                      [str                 ]          Existing attribute to store the result from the newly bound method           #
#   |attr_return       :   <str     > Attribute name to get from the bound instance, to return from the newly bound method              #
#   |                      [None                ]<Default> Only return the result from the newly bound method                           #
#   |                      [str                 ]          Only return the value of the dedicated attribute, similar to <property>      #
#   |coerce_            :   <bool    > Whether to raise exception if the dedicated callable is not found                                #
#   |                      [True                ]<Default> Return <None> if the callable is not found                                   #
#   |                      [False               ]          Raise exception if the callable is not found                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>        :   The new method which can be bound to any dedicated instance                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250104        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250201        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250225        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Simplify the logic since we are able to detect default values at runtime in <ExpandSignature>                           #
#   |      |[2] Since there is manipulation of parameters with <ExpandSignature>, all arguments of the wrapped function now can be      #
#   |      |     provided in the fashion of positional or keyword, regardless of their <kind>s in the expanded signature                #
#   |      |[3] Make <self> as the first POSITIONAL_ONLY argument, to ensure the wrapped function is correctly bound to an instance     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251102        | Version | 4.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce abstract syntax tree (AST) to create the wrapper dynamically                                                  #
#   |      |[2] Now supports all these types of callables: function, generator, async generator, coroutine, iterable coroutine. See     #
#   |      |     official document of <co_flags> in <inspect> for the difference between them                                           #
#   |      |[3] Introduce new argument <attr_hdl_yield> to handle the <yield> values in addition, where applicable                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251113        | Version | 4.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <attr_hdl_send> to enable modification upon `send()` messages where applicable                       #
#   |      |[2] Now supports `send()` operations for generator, async generator and iterable coroutine                                  #
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
#   |   |sys, re, ast, inspect, typing                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |importByStr                                                                                                                #
#   |   |   |modifyDict                                                                                                                 #
#   |   |   |ls_frame                                                                                                                   #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(apiCls, str):
        raise TypeError(f'[{LfuncName}][apiCls] must be <str>!')
    if not apiCls:
        raise ValueError(f'[{LfuncName}][apiCls] cannot be empty!')

    #020. Local environment
    lsOptNew = {
        'verbose' : True
        ,'predicate' : callable
        ,'flags' : re.NOFLAG
        ,**{ k:v for k,v in lsOpt.items() if k not in ['pattern','verbose','predicate','flags'] }
    }
    hasPkg = False
    if isinstance(apiPkg, str):
        if len(apiPkg) > 0:
            hasPkg = True

    #100. Define the name pattern for search
    apiPtn = str(apiPfx) + apiCls + str(apiSfx)

    #200. Lookup the callable core
    try:
        if hasPkg:
            __dfl_func_ = importByStr('.' + apiPtn, package = apiPkg)
        else:
            __dfl_func_ = list(ls_frame(pattern = f'^{apiPtn}$', **lsOptNew).values())
            if len(__dfl_func_) == 1:
                __dfl_func_ = __dfl_func_[0]
            else:
                __dfl_func_ = None
    except:
        __dfl_func_ = None

    #300. Verify whether it can be found
    if not callable(__dfl_func_):
        if coerce_:
            return(None)
        else:
            raise TypeError(f'[{LfuncName}][{apiPtn}] is not callable!')

    #400. Get the signature of the callable
    sig_raw = signature(__dfl_func_).parameters.values()

    #500. Identify the existence of <self> argument, to act as a bound method
    #[ASSUMPTION]
    #[1] <self> must be the first positional argument of the callable
    has_self = [
        i
        for i,s in enumerate(sig_raw)
        if s.kind in ( s.POSITIONAL_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.name == 'self'
    ] == [0]

    #600. Helper functions
    #610. Function to detect whether a Code Object Bit Flag is included in <co_flags>
    #[ASSUMPTION]
    #[1] <co_flags> are bitmaps so they are unique as binaries
    #[2] We exclude the tested flag from the <flags> using subtraction (see binary operation)
    #[3] If the rest flags do not match the tested flag and any binary position, the tested flag must have been included in <flags>
    #[4] If otherwise, the tested flag is not in <flags>
    #[5] Same as <(flags - flag) & flag == 0>
    #[6] Simple method is as below
    #Quote: https://docs.python.org/3/library/inspect.html#inspect-module-co-flags
    def _hasFlag(flags : int, flag : int) -> bool:
        return((flags & flag) == flag)

    #620. Function to determine whether to `await` as per AST requires
    def h_ast_await(stmt, is_await : bool = False):
        return(ast.Await(value = stmt) if is_await else stmt)

    #700. Define a method-like callable to wrap the original API
    #[ASSUMPTION]
    #[1] To avoid this block of comments being collected as docstring, we skip an empty line below

    eSig = ExpandSignature(__dfl_func_)

    name_exp = __dfl_func_.__name__ or 'func_'
    #[ASSUMPTION]
    #[1] <body> has strict sequence, hence we should append items one by one
    Name = lambda s, ctx = ast.Load(): ast.Name(id = s, ctx = ctx)
    Const = lambda v: ast.Constant(value = v)
    Attr = lambda base, attr: ast.Attribute(value = base, attr = attr, ctx = ast.Load())
    flags = eSig.sig_src['flags']
    f_await = _hasFlag(flags, inspect.CO_COROUTINE)
    f_yieldfrom = _hasFlag(flags, inspect.CO_GENERATOR) or _hasFlag(flags, inspect.CO_ITERABLE_COROUTINE)
    f_asyncyield = _hasFlag(flags, inspect.CO_ASYNC_GENERATOR)
    f_return = not _hasFlag(flags, inspect.CO_ASYNC_GENERATOR)
    if _hasFlag(flags, inspect.CO_COROUTINE) or _hasFlag(flags, inspect.CO_ASYNC_GENERATOR):
        class_def = ast.AsyncFunctionDef
    else:
        class_def = ast.FunctionDef
    body = []

    #701. Prepare arguments
    # def func_(self, /, *pos, **kw)
    args = ast.arguments(
        posonlyargs=[ast.arg(arg='self', annotation=None)],
        args=[],
        vararg=ast.arg(arg='pos', annotation=None),
        kwonlyargs=[],
        kw_defaults=[],
        kwarg=ast.arg(arg='kw', annotation=None),
        defaults=[]
    )

    #710. Local environment
    # clsname_ = apiCls or self.__class__.__name__
    body.append(
        ast.Assign(
            targets = [Name('clsname_', ctx=ast.Store())]
            ,value = ast.BoolOp(
                op = ast.Or()
                ,values = [
                    Const(apiCls)
                    ,Attr(Attr(Name('self'), '__class__'), '__name__')
                ]
            )
        )
    )

    #711. Verify input parameters
    # Create a pseudo parameter when necessary
    # if has_self:
    #     args_share = {'self' : self}
    # else:
    #     args_share = {}
    vfy_in_if = [
        ast.Assign(
            targets = [Name('args_share', ctx=ast.Store())]
            ,value = ast.Dict(
                keys = [Const('self')]
                ,values = [Name('self')]
            )
        )
    ]

    vfy_in_else = [
        ast.Assign(
            targets = [Name('args_share', ctx=ast.Store())]
            ,value = ast.Dict(keys=[], values=[])
        )
    ]

    body.append(
        ast.If(
            test = Name('has_self')
            ,body = vfy_in_if
            ,orelse = vfy_in_else
        )
    )

    #715. Force verification of argument conflict
    #[ASSUMPTION]
    #[1] This is useful when `self` is defined in <src>, but at other places than the first one
    # eSig.vfyConflict(args_share)
    body.append(
        ast.Expr(value = ast.Call(
            func = Attr(Name('eSig'), 'vfyConflict')
            ,args = [Name('args_share')]
            ,keywords = []
        ))
    )

    #730. Identify whether there are default values for API call, as provided at instantiation
    # if attr_kwInit:
    #     if not hasattr(self, attr_kwInit):
    #         raise AttributeError(f'[{clsname_}] has no attribute as [{attr_kwInit}]')
    #     kw_def = getattr(self, attr_kwInit, {})
    # else:
    #     kw_def = {}
    if_attr_kwinit = [
        ast.If(
            test = ast.UnaryOp(
                op = ast.Not()
                ,operand = ast.Call(
                    func = Name('hasattr')
                    ,args = [
                        Name('self')
                        ,Name('attr_kwInit')
                    ]
                    ,keywords = []
                )
            )
            ,body = [
                ast.Raise(
                    exc = ast.Call(
                        func = Name('AttributeError')
                        ,args = [
                            ast.JoinedStr(
                                values = [
                                    Const('[')
                                    ,ast.FormattedValue(
                                        value = Name('clsname_')
                                        ,conversion = -1
                                    )
                                    ,Const('] has no attribute as [')
                                    ,ast.FormattedValue(
                                        value = Name('attr_kwInit')
                                        ,conversion = -1
                                    )
                                    ,Const(']')
                                ]
                            )
                        ]
                        ,keywords = []
                    )
                    ,cause = None
                )
            ]
            ,orelse = []
        )
        ,ast.Assign(
            targets = [Name('kw_def', ctx=ast.Store())]
            ,value = ast.Call(
                func = Name('getattr')
                ,args = [
                    Name('self')
                    ,Name('attr_kwInit')
                    ,ast.Dict(keys=[], values=[])
                ]
                ,keywords = []
            )
        )
    ]

    else_attr_kwinit = [
        ast.Assign(
            targets = [Name('kw_def', ctx=ast.Store())]
            ,value = ast.Dict(keys=[], values=[])
        )
    ]

    body.append(
        ast.If(
            test = Name('attr_kwInit')
            ,body = if_attr_kwinit
            ,orelse = else_attr_kwinit
        )
    )

    #733. Patch the input by the required default values (instead of the default values in the signature)
    #[ASSUMPTION]
    #[1] It is safe if we only patch <**kw>, and the reasons are as below
    #    [1] If the provision of any positional argument is in <*pos>, and we add its patched default value in <**kw>; then
    #         the one in <**kw> is ignored by validation in <eSig>
    #    [2] If the provision of any keyword argument is in <**kw>, we do not provide its patched default value, and just
    #         use the provision
    #[2] We use <kw_def> to overwrite all parameters that are flagged as <called with default values>
    # pos_int, kw_int = eSig.insParams(args_share, pos, kw)
    # kw_patch = {k:v for k,v in kw_def.items() if eSig.isDefault(k, 'src')}
    body.append(
        ast.Assign(
            targets = [ast.Tuple(
                elts = [
                    Name('pos_int', ctx=ast.Store())
                    ,Name('kw_int', ctx=ast.Store())
                ]
                ,ctx = ast.Store()
            )]
            ,value = ast.Call(
                func = Attr(Name('eSig'), 'insParams')
                ,args = [
                    Name('args_share')
                    ,Name('pos')
                    ,Name('kw')
                ]
                ,keywords = []
            )
        )
    )

    body.append(
        ast.Assign(
            targets = [Name('kw_patch', ctx=ast.Store())]
            ,value = ast.DictComp(
                key = Name('k')
                ,value = Name('v')
                ,generators = [
                    ast.comprehension(
                        target = ast.Tuple(
                            elts = [
                                Name('k', ctx=ast.Store())
                                ,Name('v', ctx=ast.Store())
                            ]
                            ,ctx = ast.Store()
                        )
                        ,iter = ast.Call(
                            func = Attr(Name('kw_def'), 'items')
                            ,args = []
                            ,keywords = []
                        )
                        ,ifs = [
                            ast.Call(
                                func = Attr(Name('eSig'), 'isDefault')
                                ,args = [
                                    Name('k')
                                    ,Const('src')
                                ]
                                ,keywords = []
                            )
                        ]
                        ,is_async = False
                    )
                ]
            )
        )
    )

    #735. Reshape the inputs
    #[ASSUMPTION]
    #[1] Below process ensures all arguments in <kw_patch> are flagged as <called with input at runtime>, which means that
    #     their default values in definition are overwritten by the updated <default values> at runtime
    # pos_fnl, kw_fnl = eSig.updParams(kw_patch, pos_int, kw_int)
    body.append(
        ast.Assign(
            targets = [ast.Tuple(
                elts = [
                    Name('pos_fnl', ctx=ast.Store())
                    ,Name('kw_fnl', ctx=ast.Store())
                ]
                ,ctx = ast.Store()
            )]
            ,value = ast.Call(
                func = Attr(Name('eSig'), 'updParams')
                ,args = [
                    Name('kw_patch')
                    ,Name('pos_int')
                    ,Name('kw_int')
                ]
                ,keywords = []
            )
        )
    )

    #750. Call the API
    #[ASSUMPTION]
    #[1] This is where we should differ the process upon different types of input callables
    call_src = ast.Call(
        func = Attr(Name('eSig'), 'src')
        ,args = [
            ast.Starred(value = Name('pos_fnl'), ctx = ast.Load())
        ]
        ,keywords = [ast.keyword(arg = None, value = Name('kw_fnl'))]
    )

    #751. Cases of different call methods
    # rstOut = await eSig.src(*pos_fnl, **kw_fnl)
    # rstOut = eSig.src(*pos_fnl, **kw_fnl)
    body.append(
        ast.Assign(
            targets = [Name('rstOut', ctx=ast.Store())]
            ,value = h_ast_await(call_src, is_await = f_await)
        )
    )

    #753. Prepare statements to handle the yielded value
    # val_mutate = getattr(self, attr_hdl_yield)(val_inner)
    if attr_hdl_yield:
        stmt_mutate = [
            ast.Assign(
                targets = [Name('val_mutate', ctx=ast.Store())]
                ,value = ast.Call(
                    func = ast.Call(
                        func = Name('getattr')
                        ,args = [
                            Name('self')
                            ,Name('attr_hdl_yield')
                        ]
                        ,keywords = []
                    )
                    ,args = [Name('val_inner')]
                    ,keywords = []
                )
            )
        ]
    else:
        stmt_mutate = [
            ast.Assign(
                targets = [Name('val_mutate', ctx=ast.Store())]
                ,value = Name('val_inner')
            )
        ]

    #754. Prepare statements to handle the `send` value
    # val_mut_send = getattr(self, attr_hdl_send)(received_msg)
    if attr_hdl_send:
        stmt_mut_send = [
            ast.Assign(
                targets = [Name('val_mut_send', ctx=ast.Store())]
                ,value = ast.Call(
                    func = ast.Call(
                        func = Name('getattr')
                        ,args = [
                            Name('self')
                            ,Name('attr_hdl_send')
                        ]
                        ,keywords = []
                    )
                    ,args = [Name('received_msg')]
                    ,keywords = []
                )
            )
        ]
    else:
        stmt_mut_send = [
            ast.Assign(
                targets = [Name('val_mut_send', ctx=ast.Store())]
                ,value = Name('received_msg')
            )
        ]

    #756. Yield if <src> is generator, iterable coroutine or async generator
    # Normal generator or iterable coroutine
    # try:
    #     inner_value = inner_gen.__next__()
    #     while True:
    #         try:
    #             # yield当前值，并等待可能的send
    #             received_msg = yield inner_value
    #             if received_msg is not None:
    #                 inner_value = inner_gen.send(received_msg)
    #             else:
    #                 inner_value = inner_gen.__next__()
    #         except StopIteration as e:
    #             print('outer_generator end')
    #             return e.value
    # except Exception as e:
    #     inner_gen.close()
    #     raise e

    # Async generator
    # try:
    #     inner_value = await inner_gen.__anext__()
    #     while True:
    #         try:
    #             received_msg = yield inner_value
    #             if received_msg is not None:
    #                 inner_value = await inner_gen.asend(received_msg)
    #             else:
    #                 inner_value = await inner_gen.__anext__()
    #         except StopAsyncIteration as e:
    #             return_value = e.value if hasattr(e, 'value') else None
    #             return return_value
    # except Exception as e:
    #     await inner_gen.aclose()
    #     raise e

    stmt_gen = ast.Try(
        body = [
            # inner_value = inner_gen.__next__()
            ast.Assign(
                targets = [Name('val_inner', ctx=ast.Store())]
                ,value = h_ast_await(
                    ast.Call(
                        func = Attr(Name('rstOut'), '__anext__' if f_asyncyield else '__next__')
                        ,args = []
                        ,keywords = []
                    )
                    ,is_await = f_asyncyield
                )
            )

            # while True:
            ,ast.While(
                test = Const(True)
                ,body = [
                    # try:
                    ast.Try(
                        body = stmt_mutate + [
                            # received_msg = yield inner_value
                            ast.Assign(
                                targets = [Name('received_msg', ctx=ast.Store())]
                                ,value = ast.Yield(value = Name('val_mutate'))
                            )

                            # if received_msg is not None:
                            ,ast.If(
                                test = ast.Compare(
                                    left = Name('received_msg')
                                    ,ops = [ast.IsNot()]
                                    ,comparators = [Const(None)]
                                )
                                ,body = stmt_mut_send + [
                                    # inner_value = inner_gen.send(received_msg)
                                    ast.Assign(
                                        targets = [Name('val_inner', ctx=ast.Store())]
                                        ,value = h_ast_await(
                                            ast.Call(
                                                func = Attr(Name('rstOut'), 'asend' if f_asyncyield else 'send')
                                                ,args = [Name('val_mut_send')]
                                                ,keywords = []
                                            )
                                            ,is_await = f_asyncyield
                                        )
                                    )
                                ]
                                ,orelse = [
                                    # else: inner_value = inner_gen.__next__()
                                    ast.Assign(
                                        targets = [Name('val_inner', ctx=ast.Store())]
                                        ,value = h_ast_await(
                                            ast.Call(
                                                func = Attr(Name('rstOut'), '__anext__' if f_asyncyield else '__next__')
                                                ,args = []
                                                ,keywords = []
                                            )
                                            ,is_await = f_asyncyield
                                        )
                                    )
                                ]
                            )
                        ]
                        ,handlers = [
                            # except StopIteration as e:
                            ast.ExceptHandler(
                                type = Name('StopAsyncIteration' if f_asyncyield else 'StopIteration'),
                                name = 'e',
                                body = [
                                    # return_value = e.value if hasattr(e, 'value') else None
                                    ast.Assign(
                                        targets = [Name('rstOut', ctx=ast.Store())]
                                        ,value = ast.IfExp(
                                            test = ast.Call(
                                                func = Name('hasattr')
                                                ,args = [
                                                    Name('e')
                                                    ,Const('value')
                                                ]
                                                ,keywords = []
                                            )
                                            ,body = Attr(Name('e'), 'value')
                                            ,orelse = Const(None)
                                        )
                                    )
                                    # break
                                    ,ast.Break()
                                ]
                            )
                        ]
                        ,orelse = []
                        ,finalbody = []
                    )
                ]
                ,orelse=[]
            )
        ]
        ,handlers = [
            # except Exception as e:
            ast.ExceptHandler(
                # 捕获所有异常
                type = None
                ,name = None
                ,body = [
                    # inner_gen.close()
                    ast.Expr(value = h_ast_await(
                        ast.Call(
                            func = Attr(Name('rstOut'), 'aclose' if f_asyncyield else 'close')
                            ,args=[]
                            ,keywords=[]
                        )
                        ,is_await = f_asyncyield
                    ))
                    # 重新抛出当前异常
                    ,ast.Raise(exc=None, cause=None)
                ]
            )
        ]
        ,orelse = []
        ,finalbody = []
    )

    if f_yieldfrom or f_asyncyield:
        body.append(stmt_gen)

    #760. Handle the result if required
    #[ASSUMPTION]
    #[1] Currently it only takes one positional argument
    # if f_return:
    #     if attr_handler:
    #         rstOut = getattr(self, attr_handler)(rstOut)
    if_handler_body = [
        ast.Assign(
            targets = [Name('rstOut', ctx=ast.Store())]
            ,value = ast.Call(
                func = ast.Call(
                    func = Name('getattr')
                    ,args = [
                        Name('self')
                        ,Name('attr_handler')
                    ]
                    ,keywords = []
                )
                ,args = [Name('rstOut')]
                ,keywords = []
            )
        )
    ]

    if f_return:
        body.append(
            ast.If(
                test = Name('attr_handler')
                ,body = if_handler_body
                ,orelse = []
            )
        )

    #770. Assign the result to another attribute if required
    # if f_return:
    #     if attr_assign:
    #         setattr(self, attr_assign, rstOut)
    if_assign_body = [
        ast.Expr(
            value = ast.Call(
                func = Name('setattr')
                ,args = [
                    Name('self')
                    ,Name('attr_assign')
                    ,Name('rstOut')
                ]
                ,keywords = []
            )
        )
    ]

    if f_return:
        body.append(
            ast.If(
                test = Name('attr_assign')
                ,body = if_assign_body
                ,orelse = []
            )
        )

    #780. Return values
    #[ASSUMPTION]
    #[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
    #[2] This is also where we differ the process upon different types of input callables
    #[3] There are cases where there should not be `return` statements (e.g. async generator)
    # return(self)
    # if f_return:
    #     if attr_return:
    #         return(getattr(self, attr_return))
    #     else:
    #         return(rstOut)
    if_return_body = [
        ast.Return(
            value = ast.Call(
                func = Name('getattr')
                ,args = [
                    Name('self')
                    ,Name('attr_return')
                ]
                ,keywords = []
            )
        )
    ]

    else_return_body = [
        ast.Return(value = Name('rstOut'))
    ]

    if f_return:
        body.append(
            ast.If(
                test = Name('attr_return')
                ,body = if_return_body
                ,orelse = else_return_body
            )
        )

    #790. Compile the function
    # 创建函数定义
    func_def = class_def(
        name = name_exp
        ,args = args
        ,body = body
        ,decorator_list = []
        ,returns = None
    )

    # 创建模块
    module = ast.Module(body = [func_def], type_ignores = [])
    ast.fix_missing_locations(module)

    # 编译AST
    code = compile(module, '<ast-lookup-method>', 'exec')

    # 执行编译后的代码
    namespace = {
        'eSig' : eSig
        ,'has_self' : has_self
        ,'attr_kwInit' : attr_kwInit
        ,'attr_handler' : attr_handler
        ,'attr_hdl_yield' : attr_hdl_yield
        ,'attr_hdl_send' : attr_hdl_send
        ,'attr_assign' : attr_assign
        ,'attr_return' : attr_return
    }
    exec(code, namespace)

    #990. Wrap the callable
    return(eSig(namespace[name_exp]))
#End lookupMethod

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import types, asyncio, queue, threading
    from typing import Optional
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import lookupMethod

    #100. Define the API which can be bound as a method of some instance
    def loader_api001(self, b):
        return(self.aaa + b)

    # https://stackoverflow.com/questions/34073370/best-way-to-receive-the-return-value-from-a-python-generator
    class GenReturnAccessor:
        def __init__(self, gen):
            self.gen = gen

        def __iter__(self):
            self.value = yield from self.gen
            return self.value

    # 一个兼容运行器，在无事件循环时用`asyncio.run`；若当前线程已有`loop`，则在新线程中运行
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

    #200. Directly call the function to bind the API to an instance
    #[ASSUMPTION]
    #[1] There should be an extra method <add> to bind the API and an extra step to add it, which is less efficient
    #[2] One can mannually assign any value to the newly added API, which is a risk of injection
    #[3] However, method lookup can become dynamic
    class MyClass:
        def __init__(self):
            self.aaa = 10

        def add(self, attr):
            func_ = lookupMethod(
                apiCls = attr
                ,apiPkg = None
                ,apiPfx = 'loader_'
                ,apiSfx = ''
                ,lsOpt = {}
                ,attr_handler = None
                ,attr_kwInit = None
                ,attr_assign = None
                ,attr_return = None
                ,coerce_ = False
            )
            setattr(self, attr, types.MethodType(func_, self))

    testadd = MyClass()
    testadd.add('api001')
    testadd.api001(20)
    # 30

    #300. Use the magic method <__getattr__> to enable dynamic attribute creation
    #[ASSUMPTION]
    #[1] This solution usually can only enable looking up the method for the first time it is invoked in an instance
    #[2] We can neither prevent injection, even using <__setattr__> to do the trick is not recommended, as it will be complicated
    #     to differ those pre-defined internal attributes from the newly bound methods
    #    https://www.pythonmorsels.com/python-setattr/
    class MyClass1:
        def __init__(self):
            self.aaa = 10

        def __getattr__(self, attr):
            func_ = lookupMethod(
                apiCls = attr
                ,apiPkg = None
                ,apiPfx = 'loader_'
                ,apiSfx = ''
                ,lsOpt = {}
                ,attr_handler = None
                ,attr_kwInit = None
                ,attr_assign = None
                ,attr_return = None
                ,coerce_ = False
            )
            print('Identified the method for the first time')
            setattr(self, attr, types.MethodType(func_, self))
            return(getattr(self, attr))

    testadd1 = MyClass1()
    testadd1.api001(20)
    # Identified the method for the first time
    # 30

    # No longer print the pre-defined message as the method has already been bound to the instance
    testadd1.api001(30)
    # 40

    #400. Protect the instance while allowing dynamic method look up
    #[ASSUMPTION]
    #[1] This solution enables looking up the method each time it is invoked in an instance
    #[2] Use slots to prevent new attributes from being created
    #    https://wiki.python.org/moin/UsingSlots
    class MyClass2:
        #100. Define slots to prevent attributes from modification
        #[ASSUMPTION]
        #[1] Defining slots will hence eliminate <__dict__> in the instance
        #[2] Even if we add a slot of <__dict__> in this definition, it is empty
        #[3] Be careful when using <cached_property> together with slots, or other similar objects that require access to <__dict__>
        __slots__ = ('aaa',)

        #200. Initialize
        #[ASSUMPTION]
        #[1] Even if we add a slot of <__dict__> in slots, we still cannot add attributes, e.g. <bbb>, in this structure
        def __init__(self):
            self.aaa = 10

        #300. Define the method for dynamic look-up
        #[ASSUMPTION]
        #[1] Only define the method to access non-existing attributes
        #[2] Do not set the newly found method as an attribute of the instance, otherwise it conflicts with above rule
        #[3] <__dict__> and <__weakref__> may be accessed via <dir()>, we bypass look-up for them
        def __getattr__(self, attr):
            if attr in ['__dict__','__weakref__']:
                return(super().__getattribute__(attr))

            func_ = lookupMethod(
                apiCls = attr
                ,apiPkg = None
                ,apiPfx = 'loader_'
                ,apiSfx = ''
                ,lsOpt = {}
                ,attr_handler = None
                ,attr_kwInit = None
                ,attr_assign = None
                ,attr_return = None
                ,coerce_ = False
            )
            print('Identified the method for each time')
            return(types.MethodType(func_, self))

        #400. Define the protection to add new attributes
        #[ASSUMPTION]
        #[1] This method overwrites the functionality of <__slots__>
        #[2] We define this method for demonstration of managing the attribute creation
        def __setattr__(self, attr, value):
            if attr not in dir(self):
                raise AttributeError(f'[{self.__class__.__name__}]Not allowed to create attribute: {attr}')
            return(super().__setattr__(attr, value))

    testadd2 = MyClass2()
    testadd2.api001(20)
    # Identified the method for each time
    # 30

    # Look for the method again
    testadd2.api001(30)
    # Identified the method for each time
    # 40

    #410. Define another API
    def loader_api002(self, b):
        return(self.aaa - b * 2)

    #420. Try to bind the method manually in vain
    testadd2.api002 = types.MethodType(loader_api002, testadd2)
    # AttributeError: [MyClass2]Not allowed to create attribute: api002

    #430. Direct call of the new API is successful
    testadd2.api002(5)
    # Identified the method for each time
    # 0

    #500. Embed this function into a descriptor
    #[ASSUMPTION]
    #[1] Any pre-defined class attribute can be dynamically searched in the dedicated way
    #[2] If necessary, one can set the descriptor as a read-only data descriptor, to prevent injection
    #[3] The class attribute should be pre-defined, and its name cannot be dynamically created
    #[4] The descriptor takes no effect in any instance
    #[5] Use the descriptor in a metaclass can enable dynamic method lookup in a dynamically created class
    #310. Prepare a descriptor
    class MyDescriptor:
        #010. Constructor
        def __init__(
            self
            ,apiCls : str = None
            ,apiPkg : Optional[str] = None
            ,apiPfx : str = ''
            ,apiSfx : str = ''
            ,lsOpt : dict = {}
            ,attr_handler : Optional[str] = None
            ,attr_hdl_yield : Optional[str] = None
            ,attr_hdl_send : Optional[str] = None
            ,attr_kwInit : Optional[str] = None
            ,attr_assign : Optional[str] = None
            ,attr_return : Optional[str] = None
            ,coerce_ : bool = True
        ):
            #100. Assign values to local variables
            self.apiCls = apiCls
            self.apiPkg = apiPkg
            self.apiPfx = apiPfx
            self.apiSfx = apiSfx
            self.lsOpt = lsOpt
            self.attr_handler = attr_handler
            self.attr_hdl_yield = attr_hdl_yield
            self.attr_hdl_send = attr_hdl_send
            self.attr_kwInit = attr_kwInit
            self.attr_assign = attr_assign
            self.attr_return = attr_return
            self.coerce_ = coerce_

        #100. Assign attribute name
        def __set_name__(self, owner, name):
            self._dfl_public_name_ = name
            self._dfl_private_name_ = f'__dfl_{name}_'

        #300. Define non-data part of the descriptor
        def __get__(self, instance, objtype = None):
            #100. Search for the method on the fly
            func_ = lookupMethod(
                apiCls = self.apiCls or self._dfl_public_name_
                ,apiPkg = self.apiPkg
                ,apiPfx = self.apiPfx
                ,apiSfx = self.apiSfx
                ,lsOpt = self.lsOpt
                ,attr_handler = self.attr_handler
                ,attr_hdl_yield = self.attr_hdl_yield
                ,attr_hdl_send = self.attr_hdl_send
                ,attr_kwInit = self.attr_kwInit
                ,attr_assign = self.attr_assign
                ,attr_return = self.attr_return
                ,coerce_ = self.coerce_
            )

            #900. Export
            return(types.MethodType(func_, instance))

        #500. Ensure it is a read-only data descriptor
        def __set__(self, instance, value):
            apiCls = self.apiCls or self._dfl_public_name_
            raise AttributeError(f'[{instance.__class__.__name__}]Attribute [{apiCls}] is read-only!')

    #350. Use the descriptor in the class
    class MyClass5:
        api001 = MyDescriptor(
            apiCls = None
            ,apiPkg = None
            ,apiPfx = 'loader_'
            ,apiSfx = ''
            ,lsOpt = {}
            ,attr_handler = None
            ,attr_kwInit = None
            ,attr_assign = None
            ,attr_return = None
            ,coerce_ = False
        )

        def __init__(self):
            self.aaa = 10

    testadd5 = MyClass5()

    #[ASSUMPTION]
    #[1] Extra named parameters are omitted
    testadd5.api001(20, e = 5)
    # 30

    #560. Try to assign the API with another object
    testadd5.api001 = 111
    # AttributeError: [MyClass5]Attribute [api001] is read-only!

    help(testadd5.api001)

    #600. Test coroutine
    async def loader_aio(x : int, y : int) -> int:
        await asyncio.sleep(0)
        return(x + y)

    class ClsCoro:
        aio = MyDescriptor(
            apiCls = None
            ,apiPkg = None
            ,apiPfx = 'loader_'
            ,apiSfx = ''
            ,lsOpt = {}
            ,attr_handler = None
            ,attr_kwInit = None
            ,attr_assign = None
            ,attr_return = None
            ,coerce_ = False
        )

    clsCoro = ClsCoro()

    print(runAsyncCompat(clsCoro.aio(2, 3)))
    # 5

    #700. Test generator and iterable coroutine (as they are called in the same way)
    #710. Prepare a generator
    def loader_genInt(n : int = 5, cap : int = 4) -> int:
        for i in range(n):
            if i < cap:
                yield i
        return(-1)

    #715. Concept of nesting of generators
    # DeepSeek-3.2
    def outer_generator(n : int = 5, cap : int = 4):
        print('outer_generator begin')

        # 创建内层生成器
        inner_gen = loader_genInt(n, cap)

        # 启动内层生成器
        inner_value = None
        try:
            inner_value = next(inner_gen)
        except StopIteration as e:
            print('outer_generator end')
            return e.value

        try:
            while True:
                try:
                    # yield当前的内层值
                    received_msg = yield inner_value

                    # 如果有send消息，则调用内层生成器的send方法
                    if received_msg is not None:
                        inner_value = inner_gen.send(received_msg)
                    else:
                        # 如果没有send消息，继续next内层生成器
                        inner_value = next(inner_gen)

                except StopIteration as e:
                    # 内层生成器结束，返回其返回值
                    print('outer_generator end')
                    return e.value

        except GeneratorExit:
            # 处理生成器关闭
            inner_gen.close()

    #720. Prepare an iterable coroutine
    @types.coroutine
    def loader_icoro(n : int) -> int:
        # 第一次调度（prime）时产生一个值，这里用0
        yield 0
        # 随后（例如`send(None)`或`await`驱动的继续执行）返回最终结果
        return n * 2

    class ClsGen:
        genInt = MyDescriptor(
            apiCls = None
            ,apiPkg = None
            ,apiPfx = 'loader_'
            ,apiSfx = ''
            ,lsOpt = {}
            ,attr_handler = None
            ,attr_hdl_yield = 'pow2'
            ,attr_kwInit = None
            ,attr_assign = None
            ,attr_return = None
            ,coerce_ = False
        )
        icoro = MyDescriptor(
            apiCls = None
            ,apiPkg = None
            ,apiPfx = 'loader_'
            ,apiSfx = ''
            ,lsOpt = {}
            ,attr_handler = 'pow3'
            ,attr_hdl_yield = 'pow2'
            ,attr_kwInit = None
            ,attr_assign = None
            ,attr_return = None
            ,coerce_ = False
        )

        def pow2(self, x):
            return(x**2)

        def pow3(self, x):
            return(x**3)

    clsGen = ClsGen()

    g_prep = clsGen.genInt(6,3)
    r_gen = GenReturnAccessor(g_prep)
    for f in r_gen:
        print(f)
    print(f'{r_gen.value=}')
    # 0
    # 1
    # 4
    # r_gen.value=-1

    print('clsGen.icoro(3) -> ', runIterCoro(clsGen.icoro, 3))
    # clsGen.icoro(3) ->  216

    #800. Test async generator
    async def loader_ag(start : int, stop : int, delay : float = 0.0) -> int:
        for i in range(start, stop):
            if delay:
                await asyncio.sleep(delay)
            msg = yield i
            print(f'[{i}]{msg=}')

    class ClsAG:
        ag = MyDescriptor(
            apiCls = None
            ,apiPkg = None
            ,apiPfx = 'loader_'
            ,apiSfx = ''
            ,lsOpt = {}
            ,attr_handler = None
            ,attr_hdl_yield = 'pow2'
            ,attr_hdl_send = 'pr'
            ,attr_kwInit = None
            ,attr_assign = None
            ,attr_return = None
            ,coerce_ = False
        )

        def pow2(self, x):
            return(x**2)

        def pr(self, x):
            return(f'added [{x}]')

    clsAG = ClsAG()

    # A helper coroutine to collect all items from an async generator into a list
    async def collect(gen):
        out = []
        async for x in gen:
            out.append(x)
        return(out)

    async def collect2(gen):
        out = []
        # 启动
        inner_value = await gen.__anext__()
        out.append(inner_value)

        send_cand = list('ABCDE')
        for msg in send_cand:
            try:
                inner_value = await gen.asend(msg)
                out.append(inner_value)
            except StopAsyncIteration:
                break
        return(out)

    ag_rst1 = runAsyncCompat(collect(clsAG.ag(3,7,0.0)))
    print(ag_rst1)
    # [3]msg=None
    # [4]msg=None
    # [5]msg=None
    # [6]msg=None
    # [9, 16, 25, 36]

    #[ASSUMPTION]
    #[1] Send messages to obtain yield values one by one
    #[2] The `send` messages are processed by the method `obj.pr` as indicated, before it reaches the underlying function
    ag_rst2 = runAsyncCompat(collect2(clsAG.ag(3,7,0.0)))
    print(ag_rst2)
    # [3]msg='added [A]'
    # [4]msg='added [B]'
    # [5]msg='added [C]'
    # [6]msg='added [D]'
    # [9, 16, 25, 36]
#-Notes- -End-
'''
