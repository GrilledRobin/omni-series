#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import types
import inspect
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from functools import partial
from omniPy.AdvOp import nameArgsByFormals

def expandSignature(
    src : callable
) -> callable:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to merge the signatures of <src> to the wrapped callable <dst> by expanding the <*pos> and <**kw> defined#
#   | in <dst>, similar to <functools.wraps> but applied to extended argument list in high order functions                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] One can extend the arguments of <src> with certain high order function, and merge the signature of <src> into the wrapper, also#
#   |     for the caller to inspect the new signature wrapped by that high order function                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |RATIONALE                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Without this function, when you need to call the traditionally wrapped callable, you need to do <dst(arg1,*pos,**kw)>, where   #
#   |     all these arguments are from the definition of <dst>. This indicates <*pos> holds all positional arguments of <src>           #
#   |[2] We follow this rule, but further expand <*pos> and <**kw> by filling the respective holes with those in <src>                  #
#   |[3] By doing this, we hold the proper argument sequence and expansion rules                                                        #
#   |[4] Since this function requires <src> and <dst> to provide at every call, decoration magics as <simplifyDeco> no longer validate, #
#   |     we would create a double wrapper to enable parametric decoration                                                              #
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
#   |    [2] <co_nlocals> in <dst> with changes during the expansion of VAR_POSITIONAL and VAR_KEYWORD                                  #
#   |[4] <co_flags> is the bitwise OR of <src> and (<dst>.<co_flags> - CO_VARARGS - CO_VARKEYWORDS). E.g. if <src> is not a generator   #
#   |     while <dst> is one, then the wrapped callable is still a generator                                                            #
#   |    see: https://docs.python.org/3/library/inspect.html#inspect-module-co-flags                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |INSTANCE ATTRIBUTES                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] <__annotations__> is merged as it is to (only) describe the arguments                                                          #
#   |[2] <__defaults__> is merged as it only contains the default values of POSITIONAL_OR_KEYWORD, from left to right with no skip      #
#   |[3] <__kwdefaults__> is merged as it only contains the default values of KEYWORD_ONLY                                              #
#   |[4] <__doc__> is merged if either has one, or None if neither has one                                                              #
#   |[5] <__name__>, <__qualname__>, <__module__> are taken from <dst>                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://chriswarrick.com/blog/2018/09/20/python-hackery-merging-signatures-of-two-python-functions/                            #
#   |[2] https://github.com/Kwpolska/merge_args                                                                                         #
#   |[3] https://docs.python.org/3/reference/datamodel.html                                                                             #
#   |[4] https://www.goldsborough.me/python/low-level/2016/10/04/00-31-30-disassembling_python_bytecode/                                #
#   |[5] https://www.cnblogs.com/traditional/p/13507329.html                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |src         :   <callable >Function as source to extract the signature and take place of the expanded holes in <dst>               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>  :   Decorated callable with merged signature                                                                           #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    if not isinstance(src, types.FunctionType):
        raise NotImplementedError('Class decorator is not designed to be wrapped with extra arguments!')

    #020. Local environment
    arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']

    #100. Helper functions
    #110. Function to detect whether a Code Object Bit Flag is included in <co_flags>
    #[ASSUMPTION]
    #[1] <co_flags> are bitmaps so they are unique as binaries
    #[2] We exclude the tested flag from the <flags> using subtraction (see binary operation)
    #[3] If the rest flags do not match the tested flag and any binary position, the tested flag must have been included in <flags>
    #[4] If otherwise, the tested flag is not in <flags>
    #[5] Same as <(flags - flag) & flag == 0>
    #[6] Simple method is as below
    #Quote: https://docs.python.org/3/library/inspect.html#inspect-module-co-flags
    def h_hasFlag(flags : int, flag : int):
        return(flags & flag != 0)

    #130. Null function to take over the merged signature
    def h_nullfn(flags : int):
        if h_hasFlag(flags, inspect.CO_GENERATOR):
            def rst():
                yield 1
        elif h_hasFlag(flags, inspect.CO_COROUTINE) or h_hasFlag(flags, inspect.CO_ITERABLE_COROUTINE):
            async def rst(): pass
        elif h_hasFlag(flags, inspect.CO_ASYNC_GENERATOR):
            async def rst():
                yield
        else:
            def rst(): pass

        return(rst)

    #150. Function to identify the container for object instantiation
    def h_getType(flags: int):
        if h_hasFlag(flags, inspect.CO_GENERATOR):
            rst = types.GeneratorType
        elif h_hasFlag(flags, inspect.CO_COROUTINE) or h_hasFlag(flags, inspect.CO_ITERABLE_COROUTINE):
            rst = types.CoroutineType
        elif h_hasFlag(flags, inspect.CO_ASYNC_GENERATOR):
            rst = types.AsyncGeneratorType
        else:
            rst = partial(types.FunctionType, globals = globals())

        return(rst)

    #200. Retrieve the signature of the callable
    #[ASSUMPTION]
    #[1] Python evaluates the parameters passed for the call of a function in the priority as listed in <arg_kind>
    sig_src = signature(src).parameters.values()
    sig_src_bykind = {
        n : {
            i : s
            for i,s in enumerate(sig_src)
            if s.kind == s.__getattribute__(n)
        }
        for n in arg_kind
    }
    #[ASSUMPTION]
    #[1] Actually there could only be at most 1 VAR_POSITIONAL argument in the signature of a callable, same as VAR_KEYWORD
    has_vp_src = len(sig_src_bykind['VAR_POSITIONAL']) == 1
    has_vk_src = len(sig_src_bykind['VAR_KEYWORD']) == 1

    #300. Identify specific arguments
    #301. All arguments
    #[1] We do all below processes assuming that <dict> in Python >= 3.7 is ordered
    #    https://www.geeksforgeeks.org/are-python-dictionaries-ordered/
    args_src = {s.name : s.default for s in sig_src}

    #305. Named arguments
    named_src = {s.name : s.default for s in sig_src if s.kind not in [s.VAR_POSITIONAL,s.VAR_KEYWORD]}

    #310. POSITIONAL_ONLY
    po_src = {s.name : s.default for s in sig_src_bykind['POSITIONAL_ONLY'].values()}

    #330. POSITIONAL_OR_KEYWORD
    pk_src_wo_def = {s.name : s.default for s in sig_src_bykind['POSITIONAL_OR_KEYWORD'].values() if s.default is s.empty}
    pk_src_w_def = {s.name : s.default for s in sig_src_bykind['POSITIONAL_OR_KEYWORD'].values() if s.default is not s.empty}

    #350. VAR_POSITIONAL
    if has_vp_src:
        vp_src_name = list(sig_src_bykind['VAR_POSITIONAL'].values())[0].name
    else:
        vp_src_name = ''

    #360. All positional arguments
    pos_src = sig_src_bykind['POSITIONAL_ONLY'] | sig_src_bykind['POSITIONAL_OR_KEYWORD'] | sig_src_bykind['VAR_POSITIONAL']

    #370. KEYWORD_ONLY
    ko_src = {s.name : s.default for s in sig_src_bykind['KEYWORD_ONLY'].values()}
    ko_src_w_def = {s.name : s.default for s in sig_src_bykind['KEYWORD_ONLY'].values() if s.default is not s.empty}

    #390. VAR_KEYWORD
    if has_vk_src:
        vk_src_name = list(sig_src_bykind['VAR_KEYWORD'].values())[0].name
    else:
        vk_src_name = ''

    #395. All keyword arguments
    kw_src = sig_src_bykind['KEYWORD_ONLY'] | sig_src_bykind['VAR_KEYWORD']

    #500. Identify specific attributes
    #510. Docstring
    doc_src = src.__doc__ or ''

    #520. Code Object Flags
    flags_src = src.__code__.co_flags

    #800. Create the decorator
    def wrapper(dst : callable) -> callable:
        #010. Check parameters.
        if not isinstance(dst, types.FunctionType):
            raise NotImplementedError('Class decorator is not designed to be wrapped with extra arguments!')

        #100. Retrieve the signature of the callable
        sig_dst = signature(dst).parameters.values()
        sig_dst_bykind = {
            n : {
                i : s
                for i,s in enumerate(sig_dst)
                if s.kind == s.__getattribute__(n)
            }
            for n in arg_kind
        }
        has_vp_dst = len(sig_dst_bykind['VAR_POSITIONAL']) == 1
        has_vk_dst = len(sig_dst_bykind['VAR_KEYWORD']) == 1
        rest_src = {**named_src}

        #200. Identify specific arguments
        #201. All arguments
        # args_dst = {s.name : s.default for s in sig_dst}

        #205. Named arguments
        named_dst = {s.name : s.default for s in sig_dst if s.kind not in [s.VAR_POSITIONAL,s.VAR_KEYWORD]}

        if has_vp_src:
            if vp_src_name in named_dst:
                raise TypeError(f'Argument <{vp_src_name}> already exists as VAR_POSITIONAL in <src>!')

        if has_vk_src:
            if vk_src_name in named_dst:
                raise TypeError(f'Argument <{vk_src_name}> already exists as VAR_KEYWORD in <src>!')

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
            raise TypeError(f'[{dst.__name__}]No expansion of VAR_POSITIONAL or VAR_KEYWORD can be conducted for <{src.__name__}>!')

        if args_src:
            if not has_vp_dst:
                if pos_src:
                    raise TypeError(f'[{dst.__name__}]Missing VAR_POSITIONAL to expand for <{src.__name__}>!')

            if not has_vk_dst:
                if kw_src:
                    raise TypeError(f'[{dst.__name__}]Missing VAR_KEYWORD to expand for <{src.__name__}>!')

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
        po_fr_src = {k:v for k,v in po_src.items() if k in rest_src and k not in po_dst}
        po = po_dst | po_fr_src
        len_po = len(po)
        rest_src = {k:v for k,v in rest_src.items() if k not in po}

        #430. POSITIONAL_OR_KEYWORD
        #[ASSUMPTION]
        #[1] In this <kind>, arguments without defaults are always to the left of those with defaults
        #[2] There are two scenarios given <src> has <arg1, arg2 = 2>
        #    [1] If <dst> has <arg3 = 3>, we should put <arg3> between <arg1> and <arg2>, i.e. before the first one with default value
        #    [2] If <dst> has <arg3> (i.e. without default), we should put <arg3> before <arg1>
        pk_wo_def_fr_src = {k:v for k,v in pk_src_wo_def.items() if k in rest_src and k not in pk_dst_wo_def}
        pk_wo_def = pk_dst_wo_def | pk_wo_def_fr_src
        len_pk_wo_def = len(pk_wo_def)
        rest_src = {k:v for k,v in rest_src.items() if k not in pk_wo_def}

        pk_w_def_fr_src = {k:v for k,v in pk_src_w_def.items() if k in rest_src and k not in pk_dst_w_def}
        pk_w_def = pk_dst_w_def | pk_w_def_fr_src
        len_pk_w_def = len(pk_w_def)
        rest_src = {k:v for k,v in rest_src.items() if k not in pk_w_def}

        #450. VAR_POSITIONAL
        vp = {s.name : s.default for s in sig_src_bykind['VAR_POSITIONAL'].values()}

        #470. KEYWORD_ONLY
        #[ASSUMPTION]
        #[1] Sequence (even with or without defaults) does not matter for this <kind> of arguments
        #[2] After this step, <rest_src> must have been empty, so there is no need for verification
        ko_fr_src = {k:v for k,v in ko_src.items() if k in rest_src and k not in ko_dst}
        ko = ko_dst | ko_fr_src
        rest_src = {k:v for k,v in rest_src.items() if k not in ko}

        #490. VAR_KEYWORD
        vk = {s.name : s.default for s in sig_src_bykind['VAR_KEYWORD'].values()}

        #500. Prepare final attributes for Code Object
        #510. Full arguments
        args_full = po | pk_wo_def | pk_w_def | vp | ko | vk
        len_args = len(args_full)

        #520. Basic Code Object is from the wrapped callable
        co_base = {k:getattr(dst.__code__, k) for k in dir(dst.__code__) if k.startswith('co_')}

        #530. Prepare merged flags
        if h_hasFlag(flags_dst, inspect.CO_VARARGS):
            flags_upd -= inspect.CO_VARARGS
        if h_hasFlag(flags_dst, inspect.CO_VARKEYWORDS):
            flags_upd -= inspect.CO_VARKEYWORDS

        flags = flags_src | flags_upd

        #540. Prepare the null callable
        nullfn = h_nullfn(flags)

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
        passer = h_getType(flags)(nullfn.__code__.replace(**co_wrap))
        passer.__name__ = dst.__name__
        passer.__qualname__ = dst.__qualname__
        passer.__module__ = dst.__module__
        passer.__defaults__ = tuple(pk_w_def.values())
        passer.__kwdefaults__ = {k:v for k,v in ko.items() if v is not inspect._empty}
        passer.__annotations__ = src.__annotations__ | dst.__annotations__
        passer.__doc__ = (
            (f'From: {src.__name__}\n{doc_src}\n\n' if doc_src else '')
            + (f'From: {dst.__name__}\n{doc_dst}' if doc_dst else '')
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
            kw_ = pk_src_w_def | pk_dst_w_def | ko_src_w_def | ko_dst_w_def | kw

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

            #500. Prepare the adjustment on those POSITIONAL_OR_KEYWORD which are translated into keyword input
            kw_wo_def_dst = {k:v for k,v in in_kw.items() if k in pk_dst_wo_def}
            kw_wo_def_src = {k:v for k,v in in_kw.items() if k in pk_wo_def_fr_src}
            kw_w_def_dst = {k:v for k,v in in_kw.items() if k in pk_dst_w_def}
            kw_w_def_src = {k:v for k,v in in_kw.items() if k in pk_w_def_fr_src}
            adj_pk_wo_def_dst = tuple(kw_wo_def_dst.values())
            adj_pk_wo_def_src = tuple(kw_wo_def_src.values())
            adj_pk_w_def_dst = tuple(kw_w_def_dst.values())
            adj_pk_w_def_src = tuple(kw_w_def_src.values())

            #600. Identify VAR_KEYWORD
            in_vk_src = {
                k:v
                for k,v in in_kw.items()
                if k not in ko
                and k not in (kw_wo_def_dst | kw_wo_def_src | kw_w_def_dst | kw_w_def_src)
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

    return(wrapper)
#End expandSignature

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    from inspect import signature, Parameter
    from typing import Any
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import nameArgsByFormals, withDefaults
    from omniPy.AdvOp import expandSignature

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
    @expandSignature(testf_src)
    def testf_dst(arg2 : int, arg7, /, arg8 = 8, *pos, arg9, **kw):
        """ This is testf_dst """
        #Define more internal variables to test the functionality
        vvv : int = 1
        def h_int(): pass

        print('From testf_dst:')
        printEnv()

        #[ASSUMPTION]
        #[1] When we define <arg2> in the signature of <testf_dst>, we at least wish to pass it for <testf_src>, or we know that it
        #     exists in the signature of <testf_src>
        #[2] For cases when we do not know whether <arg2> exists in the signature of <testf_src>, we also do not need to pass it for
        #     the call to <testf_src>
        #[3] Hence the design is safe
        #[4] For this test case, we certainly need to pass <arg2> to <testf_src> as designed
        #[5] That say, if you really need to design the dual operations as <arg2>, you also need to do the similar patching as below
        arg_kind = ['POSITIONAL_ONLY','POSITIONAL_OR_KEYWORD','VAR_POSITIONAL','KEYWORD_ONLY','VAR_KEYWORD']
        sig_src = signature(testf_src).parameters.values()
        sig_bykind = {
            getattr(Parameter, n) : {
                i : s
                for i,s in enumerate(sig_src)
                if s.kind == s.__getattribute__(n)
            }
            for n in arg_kind
        }
        arg2_pos, arg2_kind = [ (i, s.kind) for i,s in enumerate(sig_src) if s.name == 'arg2' ][0]
        arg2_pos_rel = [ i for i,s in enumerate(sig_bykind[arg2_kind].values()) if s.name == 'arg2' ][0]

        #[ASSUMPTION]
        #[1] Since there are excessive positional arguments in <src> in the resulted signature (e.g. <arg1>), <*pos> has been
        #     validated and is not empty
        #[2] Actually, for the same reason, <*pos> holds all values for POSITIONAL_ONLY and POSITIONAL_OR_KEYWORD in <src>
        #[3] That say, if the tested argument (for this case, <arg2>) is among POSITIONAL_OR_KEYWORD, we will replace the value
        #     at the corresponding position with the input
        if arg2_kind is getattr(Parameter, 'POSITIONAL_ONLY'):
            pos_in = pos[:arg2_pos_rel] + (arg2,) + pos[arg2_pos_rel:]
        elif arg2_kind is getattr(Parameter, 'POSITIONAL_OR_KEYWORD'):
            pos_in = pos[:arg2_pos] + (arg2,) + pos[(arg2_pos + 1):]
        else:
            pos_in = pos[:]

        #[ASSUMPTION]
        #[1] No matter whether <*pos> is patched, it is safe to add <arg2> into the keyword input, as we will patch all inputs
        #     in one batch later, by allowing (and deduplicating) multiple inputs for the same arguments
        #[2] We must use the explicit input of <arg2> to replace the possible keyword in <kw> to ensure the correct syntax
        kw_in = kw | {'arg2' : arg2}

        pos_out, kw_out = nameArgsByFormals(testf_src, pos_in, kw_in, coerce_ = True, strict_ = True)
        testf_src(*pos_out, **kw_out)

    help(testf_dst)
    # Help on function testf_dst in module __main__:
    # deco(arg2: int, arg7, arg1: list[str], /, arg3: float, arg8=8, arg4=4, *pos, arg9, arg5=5, arg6, **kw) -> Any
    # From: testf_src
    #  This is testf_src
    # From: testf_dst
    #  This is testf_dst

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
    @expandSignature(src1)
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
    @expandSignature(src2)
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
    #410. Create a method out of an existing function
    def src3(arg1, *, arg3 = 3):
        print('This is src3:')
        print(f'arg1 : {str(arg1)}')
        print(f'arg3 : {str(arg3)}')
    @expandSignature(src3)
    def dst3(self, /, *pos, **kw):
        src3(*pos, **kw)
        print('This is dst3:')

    help(dst3)
    # Help on function dst3 in module __main__:
    # dst3(self, /, arg1, *, arg3=3)

#-Notes- -End-
'''
