#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
from collections.abc import Iterable

def arrayIntersections(
    Y : Iterable
    ,eps : float = 1e-9
) -> np.ndarray[np.bool_]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to flag the intersection points along the curves fitted by the provided series of data points in the form#
#   | of a matrix (or 2-D array), with the assumption that they share the same coordination system along an equidistant axis-0 as       #
#   | independent variable                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The input arrays should not contain null values. Please make proper interpolation before passing them in                       #
#   |[2] Curves that fit between two consecutive data points are always regarded as a straight line as simplification                   #
#   |[3] Curves that fit the edges of the data points are always regarded as a straight line across the edges                           #
#   |[4] The intersections will be adsorbed to their closest data points where applicable, to simplify data analysis                    #
#   |[5] Use <numpy> atomic methods instead of the primitive loops to increase the efficiency by 6 times on average                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Verify the crossing of multiple trend lines in a stock dataset, e.g. 3 lines intersect on the same trade date                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Y                 :   <Matrix  > 2-D numpy array of shape (n, k), n data points, k curves (columns)                                #
#   |eps               :   <float   > Tolerance used in intersection logic                                                              #
#   |                      [1e-9                ] <Default> Use the common tolerance level                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<matrix>          :   <Matrix  > 2-D boolean numpy array of shape (n, C(k, 2)), mask[:, p] is True where the p-th pair of columns  #
#   |                                  intersects per rules.                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260511        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |numpy, collections                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #012. Parameter buffer
    Y = np.asarray(Y, dtype = float)
    n, k = Y.shape

    #050. Direct return for simple scenarios
    #051. No pairs to compare
    if k < 2:
        return(np.zeros((n, 0), dtype = bool))

    #100. Helper functions
    #110. Determination of difference direction with tolerance
    def h_sign(val: np.ndarray, eps_: float = eps) -> np.ndarray:
        rstOut = np.zeros_like(val, dtype = int)
        rstOut[val > 0] = 1
        rstOut[val < 0] = -1
        rstOut[np.abs(val) <= eps_] = 0
        return rstOut

    #200. Prepare all column pairs (i, j) with i < j
    #[ASSUMPTION]
    #[1] Prepare an upper triangle matrix selector for the column indices, to simulate a full combination of column pairs
    #[2] Only select where (i < j) parts to enable the sliced selection of column pairs
    #[3] See <itertools.combinations> to find the similar result
    I, J = np.triu_indices(k, k = 0)
    mask_pairs = I < J
    I = I[mask_pairs]
    J = J[mask_pairs]

    #290. Extract the number of pairs = C(k, 2)
    m = I.size

    #300. Gather pairwise data: y1 for column I, y2 for column J
    #[ASSUMPTION]
    #[1] Both matrices share the shape (n, m)
    y1_m = Y[:, I]
    y2_m = Y[:, J]

    #390. If there are no pairs (should not happen since k>=2), handle safely
    if m == 0:
        return np.zeros((n, 0), dtype = bool)

    #400. Determine the intersections
    #401. Identify the previous and next items along the respective curves (vectorized)
    y1_next = np.roll(y1_m, -1, axis = 0)
    y1_prev = np.roll(y1_m, 1, axis = 0)

    # Boundary adjustments for y1
    #[ASSUMPTION]
    #[1] Always assume that the fitted curves cross their respective edges at consistent slope, i.e. 线性外推
    y1_next[-1, :] = y1_m[-1, :] * 2 - y1_prev[-1, :]
    y1_prev[0, :] = y1_m[0, :] * 2 - y1_next[0, :]

    y2_next = np.roll(y2_m, -1, axis = 0)
    y2_prev = np.roll(y2_m, 1, axis = 0)
    # Boundary adjustments for y2
    y2_next[-1, :] = y2_m[-1, :] * 2 - y2_prev[-1, :]
    y2_prev[0, :] = y2_m[0, :] * 2 - y2_next[0, :]

    #410. Calculate the difference between the data points
    # shape (n, m)
    diff = y2_m - y1_m

    #420. Signs helpers (vectorized)
    s_diff = h_sign(diff, eps)
    s_next = h_sign(y2_next - y1_next, eps)
    s_prev = h_sign(y2_prev - y1_prev, eps)

    #430. Prepare calculations for intersections
    y1_diff = y1_next - y1_m
    y2_diff = y2_next - y2_m
    denom = y1_diff - y2_diff

    #450. Intersections parameter t in [0,1]
    #[ASSUMPTION]
    #[1] This step does not determine whether two curves intersect at all
    #[2] It is only the condition to verify at later steps
    #[3] Safe division: avoid div by zero by masking
    with np.errstate(divide='ignore', invalid='ignore'):
        tgt = diff / denom
    tgt = np.clip(tgt, 0.0, 1.0)

    #455. Intersection coordinates (not strictly needed for final mask, but part of logic)
    y1_cross = y1_m + tgt * y1_diff
    y2_cross = y2_m + tgt * y2_diff

    #458. Flag the points (vectorized per pair) where the coordinates are not close to each other
    f_unknown = np.abs(y1_cross - y2_cross) > eps

    #470. Whether the sign of the difference at a point differs from the other
    # sign change -> potential intersection
    o_diff = (s_diff * s_next) < 0

    #473. Ignore parallel/unstable or unknowns
    o_diff[np.abs(denom) <= eps] = False
    o_diff[f_unknown] = False

    #475. Eliminate current point as the intersection if the actual one is closer to its next point
    rstOut = o_diff
    pos_removal = o_diff & (tgt > 0.5)
    rstOut[pos_removal] = False

    #476. Re-tag the next point as the intersection if the actual one is closer to it
    pos_retag = np.roll(pos_removal, 1, axis=0)
    pos_retag[0, :] = False
    rstOut[pos_retag] = True

    #600. Handle the scenario where the data points are just the intersections
    p_diff = np.abs(diff) <= eps
    rstOut[p_diff & (s_prev * s_next < 0)] = True

    return(rstOut)
#End arrayIntersections

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
    from omniPy.AdvOp import snippetimer
    from omniPy.Stats import arrayIntersections

    #100. Comparison function as indicated by AI
    def arrayIntersections2(y1: np.ndarray, y2: np.ndarray, eps: float = 1e-9) -> np.ndarray:
        n = len(y1)
        if n != len(y2):
            raise ValueError("y1 和 y2 长度必须相同")
        if n == 0:
            return np.zeros(0, dtype=bool)
        if n == 1:
            return np.array([abs(y1[0] - y2[0]) <= eps], dtype=bool)

        result = np.zeros(n, dtype=bool)
        diff = y2 - y1

        def sgn(x: float) -> int:
            return 0 if abs(x) <= eps else (1 if x > 0 else -1)

        for i in range(n - 1):
            d0 = diff[i]
            d1 = diff[i + 1]
            s0 = sgn(d0)
            s1 = sgn(d1)

            if s0 * s1 < 0:
                denom = (y1[i + 1] - y1[i]) - (y2[i + 1] - y2[i])
                if abs(denom) < eps:
                    continue
                t = d0 / denom
                t = max(0.0, min(1.0, t))

                y_cross1 = y1[i] + t * (y1[i + 1] - y1[i])
                y_cross2 = y2[i] + t * (y2[i + 1] - y2[i])
                if abs(y_cross1 - y_cross2) > eps:
                    continue

                if t <= 0.5:
                    result[i] = True
                else:
                    result[i + 1] = True

        for i in range(n):
            if abs(diff[i]) <= eps:
                if i == 0 or i == n - 1:
                    result[i] = True
                else:
                    left_sgn = sgn(diff[i - 1])
                    right_sgn = sgn(diff[i + 1])
                    if left_sgn * right_sgn < 0:
                        result[i] = True

        return result

    #200. Intersections of two Sine Curves within the range of [0, 2π]
    x = np.linspace(0, 2*np.pi, 100)
    y1 = np.sin(x)
    y2 = np.sin(x + np.pi/4)

    #210. Time the function
    with snippetimer('Intersect 100 points'):
        rst1 = arrayIntersections(np.vstack((y1, y2)).T, eps=1e-9)
    # Intersect 100 points elapsed 260400 ns, or 0.2604 ms

    with snippetimer('Compare 100 points'):
        comp1 = arrayIntersections2(y1, y2, eps=1e-9)
    # Compare 100 points elapsed 53100 ns, or 0.0531 ms

    assert (rst1[:,0] == comp1).all() == True

    #300. Intersections of two Sine Curves within the range of [0, 200π]
    #[ASSUMPTION]
    #[1] Atomic calculations with numpy is much more efficient than the spontaneous loops on large data
    xb = np.linspace(0, 200*np.pi, 10000000)
    yb1 = np.sin(xb)
    yb2 = np.cos(xb + np.pi/4)

    #310. Time the function
    mat_b1 = np.vstack((yb1, yb2)).T
    with snippetimer('Intersect 10000000 points'):
        rst2 = arrayIntersections(mat_b1, eps=1e-9)
    # Intersect 10000000 points elapsed 495195800 ns, or 495.1958 ms

    with snippetimer('Compare 10000000 points'):
        comp2 = arrayIntersections2(yb1, yb2, eps=1e-9)
    # Compare 10000000 points elapsed 3703823100 ns, or 3703.8231 ms

    assert (rst2[:,0] == comp2).all() == True

    #400. Test full combinations
    yb2_1 = np.sin(xb + np.pi/4)

    #410. Time the function
    mat_b2 = np.vstack((yb1, yb2, yb2_1)).T
    with snippetimer('10000000 points for 3 curves'):
        rst3 = arrayIntersections(mat_b2, eps=1e-9)
    # 10000000 points for 3 curves elapsed 2167055000 ns, or 2167.0550 ms

    with snippetimer('Compare 10000000 points for 3 curves'):
        comp3_1 = arrayIntersections2(yb1, yb2, eps=1e-9)
        comp3_2 = arrayIntersections2(yb1, yb2_1, eps=1e-9)
        comp3_3 = arrayIntersections2(yb2, yb2_1, eps=1e-9)
    # Compare 10000000 points for 3 curves elapsed 10972698900 ns, or 10972.6989 ms

    assert (rst3[:,0] == comp3_1).all() == True
    assert (rst3[:,1] == comp3_2).all() == True
    assert (rst3[:,2] == comp3_3).all() == True

    #700. Test the edges
    #710. Intersect at the tail
    pts1 = np.array([7.5, 8.4, 3.0], dtype = float)
    pts2 = np.array([1.1, 2.2, 3.0], dtype = float)

    pts_c1 = arrayIntersections(np.vstack((pts1, pts2)).T)
    pts_t1 = arrayIntersections2(pts1, pts2)
    assert (pts_c1[:,0] == pts_t1).all() == True

    #720. Intersect at the head
    pts3 = np.array([3.0, 7.5, 8.4], dtype = float)
    pts4 = np.array([3.0, 2.2, 1.1], dtype = float)

    pts_c2 = arrayIntersections(np.vstack((pts3, pts4)).T)
    pts_t2 = arrayIntersections2(pts3, pts4)
    assert (pts_c2[:,0] == pts_t2).all() == True

    #800. Test tangent, which is NOT recognized as an intersection due to the function design
    pts5 = np.array([7.5, 3.0, 8.4], dtype = float)
    pts6 = np.array([1.1, 3.0, 2.2], dtype = float)

    pts_c3 = arrayIntersections(np.vstack((pts5, pts6)).T)
    pts_t3 = arrayIntersections2(pts5, pts6)
    assert (pts_c3[:,0] == pts_t3).all() == True

#-Notes- -End-

#-Skeleton- -Begin-
# DeepSeek-V4
你是Python专家，请设计一个 function 用于高效计算两个数组各自拟合的曲线在同一坐标系中的所有交点。功能如下：
- function 名称：arrayIntersections ；参数为三个： y1 ， y2 和 eps ，其中：
  - y1和y2为类型相同且 index 相同的浮点 numpy 数组
  - eps为浮点数，用于指定依附边界，默认值为 1e-9
  - 输出为与y1同样 index 的 bool 类型数组； True 代表该数据点处两曲线相交，否则为 False
- 计算 y1 与 y2 分别所拟合的曲线的交点。包含以下子逻辑：
  - 两组数据共享线性直角坐标系、共享X轴；各数值代表X轴上等距的X值所对应的y值
  - 为简化拟合，可设上述等距的X值为0开始，间隔为1的整数
  - 所有非交点索引上的输出值初始化为 False
  - 两曲线最近点直线距离须小于或等于 eps ，否则不为交点
  - 设边界点为(X[0], y1[0])、(X[-1], y1[-1])、(X[0], y2[0])、(X[-1], y2[-1])
  - 曲线相切不为交点；但边界点处不判定是否相切
  - 交点若不在数据点上，则按如下子逻辑取数据点作为交点标识：
    - 设离交点最近的前一个数据点分别为 (X[i], y1[i]) 和 (X[i], y2[i])，后一个数据点分别为 (X[j], y1[j]) 和 (X[j], y2[j])
    - 坐标系交点处的X值和y值由拟合过程计算得出；记为 (X, y)
    - 设 dist1 = X - X[i] ； dist2 = X[j] - X
    - 若 dist1 <= dist2 ，则X[i]索引位置的输出值为 True ，否则X[j]索引位置的输出值为 True
  - 边界处理逻辑
    - 边界点本身是交点则替代其他全部逻辑
    - 若边界点是离交点最近的点，则输出 True
    - 其他情形的边界点均输出 False

以下是您需要的 `arrayIntersections` 函数的完整实现。该函数高效计算两条折线（由等距采样点 `y1` 和 `y2` 定义）的所有交点，并将交点分配给最近的整数索引数据点。

```python
import numpy as np

def arrayIntersections(y1: np.ndarray, y2: np.ndarray, eps: float = 1e-9) -> np.ndarray:
    """
    计算两条折线在等距采样点（X = 0,1,2,...）上的所有交点。

    参数:
        y1 (np.ndarray): 第一条曲线的纵坐标，形状 (n,)
        y2 (np.ndarray): 第二条曲线的纵坐标，形状 (n,)
        eps (float): 数值容差，用于判断零和接近相等，默认 1e-9

    返回:
        np.ndarray: bool 数组，长度 n，True 表示该索引对应的数据点被判定为交点
                    或离交点最近的数据点。
    """
    n = len(y1)
    if n != len(y2):
        raise ValueError("y1 和 y2 长度必须相同")
    if n == 0:
        return np.zeros(0, dtype=bool)
    if n == 1:
        return np.array([abs(y1[0] - y2[0]) <= eps], dtype=bool)

    result = np.zeros(n, dtype=bool)
    diff = y2 - y1

    # 带容差的符号函数
    def sgn(x: float) -> int:
        return 0 if abs(x) <= eps else (1 if x > 0 else -1)

    # 遍历每个区间 [i, i+1]
    for i in range(n - 1):
        d0 = diff[i]
        d1 = diff[i + 1]
        s0 = sgn(d0)
        s1 = sgn(d1)

        # 穿越情形：符号相反 => 存在交点（非相切）
        if s0 * s1 < 0:
            # 分母 = (y1[i+1]-y1[i]) - (y2[i+1]-y2[i])
            denom = (y1[i + 1] - y1[i]) - (y2[i + 1] - y2[i])
            if abs(denom) < eps:
                continue  # 平行（几乎），忽略
            t = d0 / denom  # 交点参数 t ∈ [0,1]
            t = max(0.0, min(1.0, t))

            # 计算交点纵坐标，并验证两曲线在交点处的值是否足够接近
            y_cross1 = y1[i] + t * (y1[i + 1] - y1[i])
            y_cross2 = y2[i] + t * (y2[i + 1] - y2[i])
            if abs(y_cross1 - y_cross2) > eps:
                continue  # 交点数值不精确，跳过

            # 按水平距离选择最近的数据点 (dist = t 或 1-t)
            if t <= 0.5:
                result[i] = True
            else:
                result[i + 1] = True

    # 处理差值为零的数据点（包括端点）
    for i in range(n):
        if abs(diff[i]) <= eps:
            # 边界点直接标记为交点
            if i == 0 or i == n - 1:
                result[i] = True
            else:
                # 内部点：只有左右符号相反（穿越）才视为交点，排除相切
                left_sgn = sgn(diff[i - 1])
                right_sgn = sgn(diff[i + 1])
                if left_sgn * right_sgn < 0:
                    result[i] = True

    return result
```

## 使用示例

```python
import numpy as np

# 示例：两条正弦曲线在 [0, 2π] 上的交点
x = np.linspace(0, 2*np.pi, 100)
y1 = np.sin(x)
y2 = np.sin(x + np.pi/4)

result = arrayIntersections(y1, y2, eps=1e-9)
print(result)  # True 出现在交点附近的数据点
```

## 算法要点说明

1. **线性拟合假设**：
   由于采样点等距（X = 0,1,2,...），相邻点之间按线性插值构造折线。

2. **交点检测**：
   对每个区间 `[i, i+1]`，计算差值 `diff = y2 - y1`。若 `diff[i]` 与 `diff[i+1]` 符号相反，则存在穿越交点（排除相切）。

3. **交点精确计算**：
   解线性方程组得到交点参数 `t ∈ [0,1]`，并验证交点处两曲线纵坐标差不超过 `eps`。

4. **最近数据点分配**：
   比较 `t` 与 `0.5`（即水平距离 `t` 与 `1-t`）。若 `t ≤ 0.5`，则将交点分配给左端点 `i`，否则分配给右端点 `i+1`。

5. **数据点恰为交点的处理**：
   遍历 `diff[i] ≈ 0` 的点。边界点直接标记为交点（不计相切）；内部点仅当左右区间 `diff` 符号相反（曲线穿越）时才标记，从而排除相切情形。

6. **数值稳定性**：
   所有比较均使用容差 `eps`，避免浮点误差。平行或重合线段被忽略（符合“相切不为交点”的要求）。

该实现时间复杂度 O(n)，空间复杂度 O(1)（除输出数组外），适合大规模数据。

-------------------------------------------------------------------------------
以下为自行改版，用numpy atomic operations代替循环，速度提升6倍
-------------------------------------------------------------------------------
import numpy as np
from collections.abc import Iterable

def arrayIntersections(
    y1 : Iterable
    ,y2 : Iterable
    ,eps : float = 1e-9
) -> np.ndarray[np.bool_]:
    #012. Parameter buffer
    y1 = np.array(y1, dtype = float)
    y2 = np.array(y2, dtype = float)
    k_rec = len(y1)
    if k_rec != len(y2):
        raise ValueError
    if k_rec == 0:
        return(np.zeros(0, dtype = bool))
    if k_rec == 1:
        return(np.array([abs(y1[0] - y2[0]) <= eps], dtype=bool))

    #100. Calculate the difference between the data points
    diff = y2 - y1

    #200. Helper functions
    #210. Determination of difference direction with tolerance
    def h_sign(val : np.ndarray, eps_ : float = eps) -> np.ndarray[np.integer]:
        rstOut = np.zeros_like(val, dtype = int)
        rstOut[val > 0] = 1
        rstOut[val < 0] = -1
        rstOut[abs(val) <= eps_] = 0
        return(rstOut)

    #400. Determine the intersections
    #401. Identify the previous and next items along the respective curves
    y1_next = np.roll(y1, -1)
    y1_prev = np.roll(y1, 1)
    y1_next[-1] = y1[-1] * 2 - y1_prev[-1]
    y1_prev[0] = y1[0] * 2 - y1_next[0]

    y2_next = np.roll(y2, -1)
    y2_prev = np.roll(y2, 1)
    y2_next[-1] = y2[-1] * 2 - y2_prev[-1]
    y2_prev[0] = y2[0] * 2 - y2_next[0]

    #410. Calculate the signs of the difference and prepare the comparison
    s_diff = h_sign(diff)
    s_next = h_sign(y2_next - y1_next)
    s_prev = h_sign(y2_prev - y1_prev)

    #430. Prepare the calculation of the intersections
    y1_diff = y1_next - y1
    y2_diff = y2_next - y2
    denom = y1_diff - y2_diff

    #450. Intersections
    tgt = np.clip(diff / denom, 0.0, 1.0)

    #455. Coordinates of the intersections
    y1_cross = y1 + tgt * y1_diff
    y2_cross = y2 + tgt * y2_diff

    #458. Flag the points where the coordinates are not close to each other
    f_unknown = abs(y1_cross - y2_cross) > eps

    #470. Whether the sign of the difference at a point differs from the other
    o_diff = (s_diff * s_next) < 0

    #473. Ignore if parallel or unstable
    o_diff[abs(denom) <= eps] = False
    o_diff[f_unknown] = False

    rstOut = o_diff

    #475. Eliminate current point as the intersection if the actual one is closer to its next point
    pos_removal = o_diff & (tgt > 0.5)
    rstOut[pos_removal] = False

    #476. Re-tag the next point as the intersection if the actual one is closer to it
    pos_retag = np.roll(pos_removal, 1)
    pos_retag[0] = False
    rstOut[pos_retag] = True

    #600. Handle the scenario where the data points are just the intersections
    p_diff = abs(diff) < eps
    rstOut[p_diff & (s_prev * s_next < 0)] = True

    #990. Export
    return(rstOut)

-------------------------------------------------------------------------------
以下为提示词和答案解析，最终版本使用了手工修复小部分后的模型答案
-------------------------------------------------------------------------------
你是Python专家，请将上述function推广至二维矩阵运算
- 输入单一矩阵(n, k)，令n为行数，k为列数
- 求出k方向上每两列数据中各行数据点是否相交，即计算结果有C(k,2)个(n,)数组构成
- 计算时避免使用循环
- 输出为(n, C(k,2))的矩阵

G-5-nano
http://chat.hzsumin.cn/

下面给出将你给的单列 arrayIntersections 推广到二维矩阵的实现版本。输入是一个矩阵 Y 的形状为 (n, k)，
其中 n 是行数（数据点数量），k 是列数（需要两两比较的曲线组数）。输出是一个布尔矩阵，形状为 (n, C(k, 2))，
其中每一列对应两列之间的拟合曲线在同一坐标系中的交点判定结果，且尽量避免显式 Python 循环。

核心思路
- 对所有列对 (i, j) 取两列数据作为 y1 和 y2，构造一个形状为 (n, m) 的中间数组，其中 m = C(k, 2)，每一列对应一个列对的比较数据。
- 将原来的一维算法向量化到列维度：对 (n, m) 形状的 y1、y2，沿第一个轴（行）使用 roll、加减、比较等操作，得到与单列实现等价的中间量，最后得到 (n, m) 的布尔输出。
- 沿用原算法中的边界、近似相等、以及不在数据点的交点的处理规则，全部在向量化计算中并行完成。

实现代码

```python
import numpy as np

def arrayIntersections2d(Y: np.ndarray, eps: float = 1e-9) -> np.ndarray:
    """
    Compute intersections between the fitted lines of every pair of columns in Y.

    Parameters:
    - Y: 2-D numpy array of shape (n, k), n data points, k curves (columns)
    - eps: tolerance used in intersection logic (default 1e-9)

    Returns:
    - mask: 2-D boolean numpy array of shape (n, C(k, 2))
            mask[:, p] is True where the p-th pair of columns intersects per rules.
    """
    Y = np.asarray(Y, dtype=float)
    n, k = Y.shape

    if k < 2:
        # No pairs to compare
        return np.zeros((n, 0), dtype=bool)

    # Prepare all column pairs (i, j) with i < j
    I, J = np.triu_indices(k, k=0)  # upper triangle indices, includes diagonal
    mask_pairs = I < J  # select only i < j
    I = I[mask_pairs]
    J = J[mask_pairs]
    m = I.size  # number of pairs = C(k, 2)

    # Gather pairwise data: y1 for column I, y2 for column J
    y1_m = Y[:, I]  # shape (n, m)
    y2_m = Y[:, J]  # shape (n, m)

    # If there are no pairs (shouldn't happen since k>=2), handle safely
    if m == 0:
        return np.zeros((n, 0), dtype=bool)

    # 1) Compute "next" and "prev" along the rows for each pair (vectorized)
    y1_next = np.roll(y1_m, -1, axis=0)
    y1_prev = np.roll(y1_m, 1, axis=0)
    # Boundary adjustments for y1
    y1_next[-1, :] = y1_m[-1, :] * 2 - y1_prev[-1, :]
    y1_prev[0, :] = y1_m[0, :] * 2 - y1_next[0, :]

    y2_next = np.roll(y2_m, -1, axis=0)
    y2_prev = np.roll(y2_m, 1, axis=0)
    # Boundary adjustments for y2
    y2_next[-1, :] = y2_m[-1, :] * 2 - y2_prev[-1, :]
    y2_prev[0, :] = y2_m[0, :] * 2 - y2_next[0, :]

    # 2) Signs helpers (vectorized)
    diff = y2_m - y1_m  # shape (n, m)

    def h_sign(val: np.ndarray, eps_: float = eps) -> np.ndarray:
        rstOut = np.zeros_like(val, dtype=int)
        rstOut[val > 0] = 1
        rstOut[val < 0] = -1
        rstOut[np.abs(val) <= eps_] = 0
        return rstOut

    s_diff = h_sign(diff, eps)
    s_next = h_sign(y2_next - y1_next, eps)
    s_prev = h_sign(y2_prev - y1_prev, eps)

    # 3) Prepare calculations for intersections
    y1_diff = y1_next - y1_m
    y2_diff = y2_next - y2_m
    denom = y1_diff - y2_diff  # shape (n, m)

    # 4) Intersections parameter t in [0,1]
    # Safe division: avoid div by zero by masking
    with np.errstate(divide='ignore', invalid='ignore'):
        tgt = diff / denom
    tgt = np.clip(tgt, 0.0, 1.0)

    # 5) Intersection coordinates (not strictly needed for final mask, but part of logic)
    y1_cross = y1_m + tgt * y1_diff
    y2_cross = y2_m + tgt * y2_diff

    # 6) Flags per pair (vectorized)
    f_unknown = np.abs(y1_cross - y2_cross) > eps  # shape (n, m)

    o_diff = (s_diff * s_next) < 0  # sign change -> potential intersection

    # Ignore parallel/unstable or unknowns
    o_diff = o_diff.copy()
    o_diff[np.abs(denom) <= eps] = False
    o_diff[f_unknown] = False

    # 7) Remove the current point if it's closer to next point
    rstOut = o_diff.copy()
    pos_removal = o_diff & (tgt > 0.5)
    rstOut[pos_removal] = False

    # Re-tag the next point as intersection if actual is closer to it
    # 根据查错过程，下一句中的 -1 应当为 1 。可见AI出现幻觉。最终版本修复后测试通过
    pos_retag = np.roll(pos_removal, -1, axis=0)  # shift towards previous column
    pos_retag[0, :] = False
    rstOut[pos_retag] = True

    # 8) Boundary/intersection edge case
    p_diff = np.abs(diff) < eps  # close to zero diff
    rstOut[p_diff & (s_prev * s_next < 0)] = True

    return rstOut
```

使用示例

```python
import numpy as np

# 示例数据：3 条曲线（列），共 10 个数据点（行）
np.random.seed(0)
n, k = 10, 3
Y = np.random.randn(n, k)

mask = arrayIntersections(Y, eps=1e-9)  # 形状 (n, C(3,2)) = (n, 3)
print("mask shape:", mask.shape)
print(mask)
```

你也可以把测试映射回原来单列的行为来对比：对每一个列对调用单列版的 arrayIntersections(y1=Y[:, i], y2=Y[:, j])，结果应等价于对应的 mask 列。

注意事项与边界
- 该实现与原先的单列算法保持一致的判定准则，全部在向量化路径中完成，避免显式 Python 循环。
- 当 k 很大时，输出矩阵的列数为 C(k, 2)，维度上会快速增大，请确保内存足够承载 (n, C(k, 2)) 的布尔矩阵。
- eps、边界处理和近似相等的行为与单列实现保持一致，若有自定义的极端数据，请适当调整 eps。

后续建议
- 如果你希望支持不止一组点对的交点判断（例如需要把所有可能的交点位置映射回某些特定点），可以给出更多约束，
  我可以把实现扩展为可选的多交点模式（如多项式拟合后产生的多次交点）。
- 需要处理的曲线不是单纯的线性拟合，而是多项式或分段拟合吗？我可以提供相应的向量化实现版本。

想继续吗？你希望对哪种拟合模型（如二次多项式、分段线性等）扩展这个功能，以及对输出的形状或数据类型是否有进一步的约束？

#-Skeleton- -End-
'''
