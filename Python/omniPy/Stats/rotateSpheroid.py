#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import numpy as np
from copy import deepcopy
from collections.abc import Iterable
from omniPy.AdvOp import get_values

#How to annotate numpy
# https://geek-docs.com/numpy/numpy-ask-answer/417_numpy_specific_type_annotation_for_numpy_ndarray_using_mypy.html#:~:text=numpy%20ndar
def rotateSpheroid(
    X : float | np.ndarray[float], Y : float | np.ndarray[float], Z : float | np.ndarray[float]
    ,rotX : float = 0.0, rotY : float = 0.0, rotZ : float = 0.0
    ,moveX : float = 0.0, moveY : float = 0.0, moveZ : float = 0.0
    ,scaleX : float = 1.0, scaleY : float = 1.0, scaleZ : float = 1.0
    ,rotSeq : str = 'xyz'
    ,tolSurface = 1E-09
    ,moveOf = 'Axis'
    ,invRotX : bool = False, invRotY : bool = False, invRotZ : bool = False
) -> np.ndarray[[float, float, float]]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to move a point on the surface of a spheroid into another position on the same spheroid by rotating its  #
#   | coordinates on the 3 dimensions respectively                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The spheroid has the center as [0,0,0] and a standard form as [X^2 + Y^2 + Z^2 == 1]                                           #
#   |[2] Direct3D and the plugin Element3D (from Video Copilot) for Adobe After Effects, as well as many other 3D modeling environments,#
#   |     use the <left-handed cartesian coordinates> to draw 3D objects.                                                               #
#   |    https://baike.baidu.com/item/%E5%B7%A6%E6%89%8B%E5%9D%90%E6%A0%87%E7%B3%BB/9171764?fr=ge_ala                                   #
#   |[3] Adobe After Effects draw video clips with <right-handed cartesian coordinates>                                                 #
#   |[4] The only factor that impacts the result is whether the point itself moves or the axes rotate                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Reference]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Rotation on spheroid: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243          #
#   |[2] Rotation on ellipse: https://blog.csdn.net/u014779685/article/details/136454696                                                #
#   |[3] Coordinate systems: https://zhuanlan.zhihu.com/p/672926406                                                                     #
#   |[4] Rotation on Right-handed system: https://blog.csdn.net/shenquanyue/article/details/103262512                                   #
#   |[5] Rotation on Left-handed system: https://blog.csdn.net/qq_20828983/article/details/81481437                                     #
#   |[6] DCM is the same of Left/Right, only different on the positive directions: https://zhuanlan.zhihu.com/p/677674288               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate the new position of a point when only rotating it along the spheroidal surface in a 3D system                        #
#   |[2] Attach the <light source> to the E3D objects in Adobe After Effects, to simulate a rotating Sun around the planet              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |X,Y,Z        :   Coordinate on 3D axes on the surface of a unit sphere                                                             #
#   |rotX,Y,Z     :   Arcs to rotate the axes                                                                                           #
#   |                 [0.0            ]  <Default> Do not rotate the vector                                                             #
#   |moveX,Y,Z    :   Values as coordinate to shift the vector                                                                          #
#   |                 [0.0            ]  <Default> Do not shift the vector                                                              #
#   |scaleX,Y,Z   :   Multipliers to scale the axes                                                                                     #
#   |                 [1.0            ]  <Default> Do not scale the axes                                                                #
#   |rotSeq       :   Sequence of the rotation on axes, currently only support <extrinsic> rotations, see official document of the      #
#   |                  Python method <scipy.spatial.transform.Rotation.from_euler>                                                      #
#   |                 [IMPORTANT] Different sequences result in different new positions                                                 #
#   |                 [xyz            ]  <Default> Rotate X axis, then Y, then Z                                                        #
#   |                 [Perm<x,y,z>    ]            Other permutations of the 3 axis names                                               #
#   |tolSurface   :   Tolerance when verifying whether the provided coordinates represents a point on the dedicated spheroid            #
#   |                 [<see def.>     ]  <Default> Use the generally sufficient tolerance level                                         #
#   |moveOf       :   Whether to move the point (holding the axes static) or rotate the axes (holding the position of the point)        #
#   |                 [A<xis>         ]  <Default> Rotate the axes by holding the position of the provided point                        #
#   |                 [P<oint>        ]            Move the point by holding the axes static                                            #
#   |invRotX,Y,Z  :   If True then the inverse of the rotation(s) is applied to the input vectors. Default is False.                    #
#   |                 [FALSE          ]  <Default> Rotate in the classic way                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<matrix>     :   matrix [N,3] where N is the number of elements in the provided vectors X, Y and Z                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241008        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20241009        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Corrected the logic by <Reference [6]>                                                                                  #
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
#   |   |sys, re, numpy, copy, collections                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |get_values                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

    #013. Define the local environment.
    dict_moveOf = {
        'A' : 'Axis'
        ,'P' : 'Point'
    }
    re_flags = re.I
    seqAxis = rotSeq.upper()

    #050. Ensure the inputs are converted into arrays
    if isinstance(X, Iterable):
        newX0 = np.array(deepcopy(X), dtype = np.float64)
    else:
        newX0 = np.array([deepcopy(X)], dtype = np.float64)
    if isinstance(Y, Iterable):
        newY0 = np.array(deepcopy(Y), dtype = np.float64)
    else:
        newY0 = np.array([deepcopy(Y)], dtype = np.float64)
    if isinstance(Z, Iterable):
        newZ0 = np.array(deepcopy(Z), dtype = np.float64)
    else:
        newZ0 = np.array([deepcopy(Z)], dtype = np.float64)

    #070. Standardize the [moveOf]
    #071. Combine all patterns into one, using [|] to minimize the system effort during matching
    str_move_match = '|'.join( list(dict_moveOf.keys()) + list(dict_moveOf.values()) )
    ptn_move_match = re.compile(str_move_match, re_flags)

    #078. Conduct substitution
    ptn_move_matchobj = ptn_move_match.fullmatch(moveOf)
    if ptn_move_matchobj:
        for k,v in dict_moveOf.items():
            #[matchobj[1]] represents the first capture group in the match object
            if re.fullmatch(k + '|' + v, ptn_move_matchobj[0], flags = re_flags):
                moveOf = v
    else:
        raise ValueError(
            f'[{LfuncName}][moveOf]:[{str(moveOf)}] is not accepted!'
            + '\n' + f'Valid alignments should match the pattern: {str_move_match}'
        )

    #080. Define the direction of moving
    coef_dir = -1 if moveOf == 'Axis' else 1

    #095. Verify whether the provided coordinates is on the surface of the dedicated spheroid
    spheroid = np.power(newX0, 2) + np.power(newY0, 2) + np.power(newZ0, 2)
    if not np.allclose(spheroid, 1.0):
        raise ValueError(f'[{LfuncName}]Some of the provided coordinates are not on the dedicated spheroids!')

    #[ASSUMPTION]
    #[1] Below steps to create matrices use the <left-handed cartesian coordinates>, as it is popular in 3D development environment.
    #[2] 球体坐标旋转推导: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243
    #[3] 坐标系旋转变换公式图解 https://blog.csdn.net/panyonglin999/article/details/50083441
    #[4] 坐标的旋转变换和坐标系的旋转变换 https://blog.csdn.net/jc15988821760/article/details/133345301
    #[5] 右手坐标系 3d变换基础：平移、旋转、缩放（仿射变换）详解——公式推导 https://blog.csdn.net/shenquanyue/article/details/103262512
    #[6] 左手坐标系 3D坐标系中 点 的 平移、旋转和缩放 https://blog.csdn.net/qq_20828983/article/details/81481437
	#[7] 三维向量绕任意轴的旋转公式 https://blog.csdn.net/FreeSouthS/article/details/112576370
    #[8] Python中如何实现三维图像（体素）旋转 https://zhuanlan.zhihu.com/p/571309602
    #[9] 三个方向同时旋转，需要做矩阵乘法
    #100. Initialize the position into a matrix
    posOrg = np.stack((newX0,newY0,newZ0,np.ones(len(newX0)))).T


    #200. Matrix to move the axes
    movMat = np.array([
        [               1.0,              0.0,              0.0,0.0]
        ,[              0.0,              1.0,              0.0,0.0]
        ,[              0.0,              0.0,              1.0,0.0]
        ,[ coef_dir * moveX, coef_dir * moveY, coef_dir * moveZ,1.0]
    ])

    #400. Rotation matrices, A.K.A Direction Cosine Matrix (DCM)
    #[ASSUMPTION]
    #[1] 欧拉角 https://blog.csdn.net/yq_forever/article/details/79558790
    #410. Coefficient matrix during rotation by holding X direction static
    rotMatX = np.array([
        [               1.0,              0.0,              0.0,0.0]
        ,[              0.0,     np.cos(rotX),     np.sin(rotX),0.0]
        ,[              0.0,    -np.sin(rotX),     np.cos(rotX),0.0]
        ,[              0.0,              0.0,              0.0,1.0]
    ])

    #440. Coefficient matrix during rotation by holding Y direction static
    rotMatY = np.array([
        [      np.cos(rotY),              0.0,    -np.sin(rotY),0.0]
        ,[              0.0,              1.0,              0.0,0.0]
        ,[     np.sin(rotY),              0.0,     np.cos(rotY),0.0]
        ,[              0.0,              0.0,              0.0,1.0]
    ])

    #470. Coefficient matrix during rotation by holding Z direction static
    rotMatZ = np.array([
        [      np.cos(rotZ),     np.sin(rotZ),              0.0,0.0]
        ,[    -np.sin(rotZ),     np.cos(rotZ),              0.0,0.0]
        ,[              0.0,              0.0,              1.0,0.0]
        ,[              0.0,              0.0,              0.0,1.0]
    ])

    #495. Transpose the matrices if only the dedicated point on the provided (X,Y,Z) is to move
    if moveOf == 'Point':
        rotMatX = deepcopy(rotMatX.T)
        rotMatY = deepcopy(rotMatY.T)
        rotMatZ = deepcopy(rotMatZ.T)

    #497. Make an inverse rotation on the dedicated axes as required
    #[ASSUMPTION]
    #[1] This is inspired by the different behavior in <VideoCopilot Element 3D> plugin for Adobe After Effects,
    #     where the rotation around Y axis is inverse to the classic algorithm
    if invRotX:
        rotMatX = deepcopy(rotMatX.T)
    if invRotY:
        rotMatY = deepcopy(rotMatY.T)
    if invRotZ:
        rotMatZ = deepcopy(rotMatZ.T)

    #600. Matrix to scale the axes
    scaleMat = np.array([
        [            scaleX,              0.0,              0.0,0.0]
        ,[              0.0,           scaleY,              0.0,0.0]
        ,[              0.0,              0.0,           scaleZ,0.0]
        ,[              0.0,              0.0,              0.0,1.0]
    ])

    #800. Rotation from different sequence of directions
    posNew = deepcopy(posOrg)
    for ax in seqAxis:
        mat = get_values(f'rotMat{ax}', instance = np.ndarray, scope = 'f_locals')
        posNew = deepcopy(posNew.dot(mat))

    #900. Calculation under different coordinate systems
    #[ASSUMPTION]
    #[1] Below sequence during multiplication is important!
    return(posNew.dot(movMat).dot(scaleMat)[:,:-1])

    #900. Combine the arrays
    return( np.stack((newX, newY, newZ)) )
#End rotateSpheroid

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import rotateSpheroid
    print(rotateSpheroid.__doc__)

    #How to determine a point on the surface of a sphere
    if False:
        #100. Provide a random point in the system, in order to determine the rotation angles on the dedicated sphere
        posX = 0.627 * (-1)
        posY = 1.149
        posZ = 2.118

        #200. Determine the size of the sphere
        rSphere = 2.5

        #300. Calculate the attributes
        # [ASSUMPTION]
        # [1] 球面坐标变换 https://baike.baidu.com/item/%E7%90%83%E9%9D%A2%E5%9D%90%E6%A0%87%E5%8F%98%E6%8D%A2/22368776?fr=ge_ala
        rTempSphere = np.sqrt(posX**2 + posY**2 + posZ**2)
        posTheta = np.arccos(posZ / rTempSphere)
        posPhi = np.arctan2(posY, posX)
        #Above usage of <arctan2> is exactly the same as below statements
        # if posX == 0:
        #     posPhi = np.pi / 2 * np.sign(posY)
        # elif posY == 0:
        #     posPhi = np.pi / 2 * (1 - np.sign(posX))
        # else:
        #     posPhi = np.arctan(np.divide(posY, posX))

        #     #500. Correct the attributes due to the limitation of arc triangular functions
        #     #[ASSUMPTION]
        #     #[1] The scenario [X == Y == 0] does not exist for a spherical calculation
        #     if np.sign(posPhi) != np.sign(posY):
        #         posPhi = posPhi + np.pi

        #800. Calculate the coordinates
        oldX = round(rSphere * np.sin(posTheta) * np.cos(posPhi), 10)
        oldY = round(rSphere * np.sin(posTheta) * np.sin(posPhi), 10)
        oldZ = round(rSphere * np.cos(posTheta), 10)
        [oldX, oldY, oldZ]
        # [-0.6295610254, 1.1536931709, 2.1266511192]

    #100. Select a point on a sphere with radius as 2.5
    #[ASSUMPTION]
    #[1] If the spheroid is not a unit sphere, one has to standardize it, such as dividing each axis by their respective radius
    rSphere = 2.5
    oldX = -0.6295610254 / rSphere
    oldY = 1.1536931709 / rSphere
    oldZ = 2.1266511192 / rSphere
    oldPos = np.array([oldX, oldY, oldZ])
    # array([-0.25182441, -0.46147727,  0.85066045])
    centerAE = np.array([1924.0, 1080.0, 0.0])
    centerAdj = np.array([4.892923, 4.849852, 18.577313])
    oldPosAE = oldPos * 640.0 * np.array([1,-1,1]) + centerAE + centerAdj
    # array([1767.7253005 , 1380.19530375,  562.99999952])

    #200. These numbers are values in Degrees instead of arcs
    rot_X = -5 * np.pi / 180.0
    rot_Y = 7 * np.pi / 180.0
    rot_Z = -36 * np.pi / 180.0
    newPosAE_to_be = np.array([1699.69, 991.6018, 605.4006])
    newPosE3D_to_be = (newPosAE_to_be - centerAE - centerAdj) / 640.0 / np.array([1,-1,1])
    # array([-0.35812957,  0.14570008,  0.91691139])

    #300. Move the point along the surface of the sphere, i.e. rotate the point
    #[ASSUMPTION]
    #[1] In <VideoCopilot Element 3D> plugin for Adobe After Effects, the rotation on Y axis is inverse to the classic behavior
    #[2] Meanwhile, the rotation sequence is <zyx>, i.e. rotating Z axis at first, then Y axis, and last X axis
    newPos = rotateSpheroid(oldX,oldY,oldZ, rot_X, rot_Y, rot_Z, invRotY = True, rotSeq = 'zyx', moveOf = 'p')
    # array([[-0.3677699 ,  0.14583448,  0.91841037]])
    newPosAE = newPos * 640.0 * np.array([1,-1,1]) + centerAE + centerAdj
    # array([[1693.52018527,  991.51578176,  606.35994771]])

    #700. Test the rotation of axes by holding the position of the provided point
    #[ASSUMPTION]
    #[1] <scipy> 中的坐标系是右手坐标系，同VTK、Blender
    #    https://blog.csdn.net/qq_45232776/article/details/140389687
    #[2] scipy中的“旋转”是保持给定的点不动而转动坐标轴
    axis_X = -5 * np.pi / 180.0
    axis_Y = 7 * np.pi / 180.0
    axis_Z = -36 * np.pi / 180.0
    newPosAx_xyz = rotateSpheroid(oldX,oldY,oldZ, axis_X, axis_Y, axis_Z, rotSeq = 'xyz', moveOf = 'a')
    # array([[0.19116973, 0.52099573, 0.83187594]])
    newPosAx_zxy = rotateSpheroid(oldX,oldY,oldZ, axis_X, axis_Y, axis_Z, rotSeq = 'zxy', moveOf = 'a')
    # array([[0.16475326, 0.59351763, 0.78777737]])

    #785. The same result in <scipy>
    from scipy.spatial.transform import Rotation
    import numpy as np
    # 定义待旋转的点
    point = np.array([-0.6295610254, 1.1536931709, 2.1266511192]) / 2.5
    # 创建旋转对象
    rotation = Rotation.from_euler('xyz', np.array([-5.0, 7.0, -36.0]), degrees = True)
    # 执行旋转（注意：scipy中的“旋转”是保持给定的点不动而转动坐标轴）
    rotated_point = rotation.apply(point)
    print(rotated_point)

    # 创建旋转对象
    rotation = Rotation.from_euler('zxy', np.array([-36.0, -5.0, 7.0]), degrees = True)
    # 执行旋转
    rotated_point = rotation.apply(point)
    print(rotated_point)


    #790. Verify the result by linear calculation
    #[ASSUMPTION]
    #[1] Reference: https://blog.csdn.net/shenquanyue/article/details/103262512
    #[2] Above article is for rotation of axes by holding the position of the vector
    #[3] Above article uses the <left-multiplication> hence the DCMs are transposed
    vfyMat = np.array([[
        (
            np.cos(axis_Y) * np.cos(axis_Z) * oldX
            + (np.sin(axis_X) * np.sin(axis_Y) * np.cos(axis_Z) - np.sin(axis_Z) * np.cos(axis_X)) * oldY
            + (np.sin(axis_Y) * np.cos(axis_X) * np.cos(axis_Z) + np.sin(axis_X) * np.sin(axis_Z)) * oldZ
        )
        ,(
            np.cos(axis_Y) * np.sin(axis_Z) * oldX
            + (np.cos(axis_X) * np.cos(axis_Z) + np.sin(axis_X) * np.sin(axis_Y) * np.sin(axis_Z)) * oldY
            + (-np.sin(axis_X) * np.cos(axis_Z) + np.sin(axis_Z) * np.sin(axis_Y) * np.cos(axis_X)) * oldZ
        )
        ,(
            -np.sin(axis_Y) * oldX
            + np.sin(axis_X) * np.cos(axis_Y) * oldY
            + np.cos(axis_X) * np.cos(axis_Y) * oldZ
        )
    ]])

    np.allclose(vfyMat, newPosAx_xyz)
    # True
#-Notes- -End-
'''
