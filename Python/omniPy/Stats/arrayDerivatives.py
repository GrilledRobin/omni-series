#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numpy as np
from omniPy.AdvOp import ExpandSignature

@(eSig := ExpandSignature(np.gradient))
def arrayDerivatives(
    *pos
    ,k : int = 1
    ,cap : float = 1e9
    ,**kw
):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the <k>th order gradient, a.k.a. derivative, of the data points in the provided array, by   #
#   | setting the too-large gradient as infinity with certain tolerance when required                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] A simple expansion of <np.gradient> at runtime                                                                                 #
#   |[3] For high dimensional (D > 1) array when requesting high order gradient (k > 1), <axis> should be provided, otherwise it raises #
#   |     exception as the official gradient calculation to all dimensions becomes ambiguous                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] It can be used to calculate the <k>th order derivative for data points in a <pd.Series> or <pd.DataFrame> where necessary      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |*pos              :   Various positional arguments to expand from its ancestor; see its official document                          #
#   |k                 :   <int     > The <k>th order derivative to calculate, should be positive                                       #
#   |                      [<see def.>          ] <Default> Calculate the derivative to the certain order                               #
#   |                      [<int>               ]           Provide integer to indicate the dedicated order of derivative               #
#   |cap               :   <float   > Tolerance used to set the too-large derivative to infinity                                        #
#   |                      [<see def.>          ] <Default> Use the common tolerance level                                              #
#   |                      [<float>             ]           Provide float number to indicate the dedicated tolerance                    #
#   |**kw              :   Various keyword arguments to expand from its ancestor; see its official document                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Any>             :   See the output part of official document <np.gradient>                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260608        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, numpy                                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(k, int) or k <= 0:
        raise ValueError(f'[{LfuncName}]<k> must be a positive integer')
    if not isinstance(cap, (int, float)):
        raise ValueError(f'[{LfuncName}]<cap> must be a number')

    #100. Define helper functions
    #110. Function to process the values
    def h_setInf(arr : np.ndarray):
        rstOut = arr.astype(float)
        rstOut = np.where(rstOut > cap, np.inf, rstOut)
        rstOut = np.where(rstOut < -cap, -np.inf, rstOut)
        return(rstOut)

    #300. Retrieve the necessary inputs
    #310. Reshape the raw input
    #[ASSUMPTION]
    #[1] After the insertion, the arguments have been validated, so all updates to below result only need to be applied
    #     by <eSig.updParams()>
    args_dummy = {
        'k' : None
        ,'cap' : None
    }
    eSig.vfyConflict(args_dummy)
    pos_in, kw_in = eSig.insParams(args_dummy, pos, kw)

    #330. Retrieve the environment from the reshaped input
    #[ASSUMPTION]
    #[1] 转换为浮点类型（避免整数梯度问题，且不修改原数组）
    deriv = np.asarray(eSig.getParam('f', pos_in, kw_in, inc_default = True)).astype(float)
    axis = eSig.getParam('axis', pos_in, kw_in, inc_default = True)

    #390. Further verification
    y_shape = deriv.shape
    highD = len(y_shape) > 1
    if axis is None:
        if (k > 1) and (len(y_shape) > 1):
            raise ValueError(f'[{LfuncName}]<axis> should be specified for <{k}> order gradient of {y_shape} array!')
    if isinstance(axis, tuple):
        if (k > 1) and (len(axis) > 1):
            raise ValueError(f'[{LfuncName}]Ambiguous <axis={axis}> for <{k}> order gradient of any array!')

    #500. 重复应用 gradient 计算 k 阶导数
    for _ in range(k):
        #400. Identify the shared arguments between this function and its ancestor functions
        args_share = {
            'f' : deriv
        }

        #900. Finalize the parameters
        pos_fnl, kw_fnl = eSig.updParams(args_share, pos_in, kw_in)

        deriv = eSig.src(*pos_fnl, **kw_fnl)

    #800. 应用截断阈值
    if (axis is None) and highD:
        deriv = [h_setInf(arr) for arr in deriv]
    elif isinstance(axis, tuple):
        if len(axis) > 1:
            deriv = [h_setInf(arr) for arr in deriv]
        else:
            deriv = h_setInf(deriv)
    else:
        deriv = h_setInf(deriv)

    return(deriv)
#End arrayDerivatives

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import arrayDerivatives

    #100. 示例数据：y = x^2 和 y = x，x = 0,1,2,3
    Y = np.array([[0, 0], [1, 1], [4, 2], [9, 3]], dtype=float)

    #300. 一阶导数（理论值：2x 和 1）
    d1 = arrayDerivatives(Y, k = 1, axis = 0)
    print(d1)
    # 输出示例（边界处为一阶差分）：
    # [[1.  1.]
    #  [2.  1.]
    #  [4.  1.]
    #  [5.  1.]]

    #320. 根据numpy官方文档，分别计算矩阵的axis=1和axis=0的梯度
    d1_1 = arrayDerivatives(Y, k = 1, axis = (1,0))
    print(d1_1)
    # [array([[ 0.,  0.],
    #        [ 0.,  0.],
    #        [-2., -2.],
    #        [-6., -6.]]), array([[1., 1.],
    #        [2., 1.],
    #        [4., 1.],
    #        [5., 1.]])]

    #400. 二阶导数（理论值：2 和 0）
    d2 = arrayDerivatives(Y, k = 2, axis = 0)
    print(d2)
    # 输出示例：
    # [[1.  0. ]
    #  [1.5 0. ]
    #  [1.5 0. ]
    #  [1.  0. ]]

    #490. Raise exception if the request is ambiguous
    arrayDerivatives(Y, k = 2)
    # ValueError: [arrayDerivatives]<axis> should be specified for <2> order gradient of (4, 2) array!

    arrayDerivatives(Y, k = 2, axis = (1,0))
    # ValueError: [arrayDerivatives]Ambiguous <axis=(1, 0)> for <2> order gradient of any array!

#-Notes- -End-

#-Skeleton- -Begin-
# DeepSeek-V4
你是Python专家，请设计一个 function 利用 numpy 高效计算矩阵在各列数据中每行各点的 k 阶导数。功能如下：
- function 名称：arrayDerivatives ；参数为三个： Y , k 和 cap ，其中：
  - Y 为二维浮点 numpy 数组，形状为 (n_points, n_columns)
  - k 为 int 类型，须限制为仅大于0
  - cap 为浮点数，用于指定导数边界，默认值为 1e9 。当导数大于 cap 时，输出为 np.inf；导数小于 -cap 时，输出为 -np.inf
  - 输出为与 Y 同型的 float 类型数组
- 前提条件如下
  - Y 的每一列数据对应直角坐标系中 x 轴上距离为1的各点的 y 坐标值
  - Y 的各列相互独立
  - 边界处数据采用 numpy 相关函数的默认外推方法

以下是满足要求的 `arrayDerivatives` 函数实现。该函数利用 `numpy.gradient` 沿行方向（axis=0）迭代计算 k 阶导数，并对超出阈值的导数进行截断。

```python
import numpy as np

def arrayDerivatives(Y: np.ndarray, k: int, cap: float = 1e9) -> np.ndarray:
    """
    计算二维数组每列（axis=0 方向）的 k 阶导数。

    参数
    ----------
    Y : np.ndarray
        二维浮点数组，形状 (n_points, n_columns)。
        每一列对应 x 轴上等距点（间距 = 1）处的函数值。
    k : int
        正整数，指定导数的阶数。
    cap : float, default=1e9
        截断阈值。若导数绝对值超过 cap，则替换为 ±np.inf。

    返回
    -------
    np.ndarray
        与 Y 形状相同的浮点数组，包含每列在每行处的 k 阶导数。
        边界处理采用 numpy.gradient 的默认方法（一阶前向/后向差分，即线性外推）。
    """
    # 输入验证
    if not isinstance(Y, np.ndarray) or Y.ndim != 2:
        raise ValueError("Y must be a 2D numpy array")
    if not isinstance(k, int) or k <= 0:
        raise ValueError("k must be a positive integer")
    if not isinstance(cap, (int, float)):
        raise ValueError("cap must be a number")

    # 转换为浮点类型（避免整数梯度问题，且不修改原数组）
    deriv = Y.astype(float)

    # 重复应用 gradient 计算 k 阶导数
    for _ in range(k):
        deriv = np.gradient(deriv, axis=0)   # axis=0：沿行方向（每列独立）

    # 应用截断阈值
    deriv = np.where(deriv > cap, np.inf, deriv)
    deriv = np.where(deriv < -cap, -np.inf, deriv)

    return deriv
```

### 设计要点

1. **导数方向**
   根据前提“每一列对应 x 轴上间距为 1 的点”，沿 `axis=0`（行方向）求导，确保各列相互独立。

2. **边界处理**
   `numpy.gradient` 的默认行为是：
   - 内部点：二阶中心差分
   - 边界点：一阶前向/后向差分（等价于线性外推）
   完全符合“采用 numpy 相关函数的默认外推方法”的要求。

3. **高阶导数**
   通过循环 `k` 次调用 `gradient`，每次在前一阶导数基础上计算，最终得到 k 阶导数。

4. **截断与无穷大**
   使用 `np.where` 向量化替换，效率高且保留数组形状。超限值替换为 `np.inf` 或 `-np.inf`，符合 IEEE 浮点标准。

5. **输入不变性**
   `Y.astype(float)` 生成新数组，原数组未被修改。

### 示例用法

```python
# 示例数据：y = x^2 和 y = x，x = 0,1,2,3
Y = np.array([[0, 0], [1, 1], [4, 2], [9, 3]], dtype=float)

# 一阶导数（理论值：2x 和 1）
d1 = arrayDerivatives(Y, k=1)
print(d1)
# 输出示例（边界处为一阶差分）：
# [[1.  1.]
#  [2.  1.]
#  [4.  1.]
#  [5.  1.]]

# 二阶导数（理论值：2 和 0）
#[注] 这里有幻觉，官方np.gradient计算两次时，结果为1.5，没有2；见我自己的文档
d2 = arrayDerivatives(Y, k=2)
print(d2)
# 输出示例：
# [[1.  0.]
#  [2.  0.]
#  [2.  0.]
#  [1.  0.]]
```

该实现高效、简洁，完全满足题目约束条件。

#-Skeleton- -End-
'''
