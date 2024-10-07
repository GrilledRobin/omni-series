#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numpy as np
from copy import deepcopy
from collections.abc import Iterable

#How to annotate numpy
# https://geek-docs.com/numpy/numpy-ask-answer/417_numpy_specific_type_annotation_for_numpy_ndarray_using_mypy.html#:~:text=numpy%20ndar
def rotateSpheroid(
    X : float | np.ndarray[float], Y : float | np.ndarray[float], Z : float | np.ndarray[float]
    ,tolSurface = 1E-09
    ,angleX : float | np.ndarray[float] = 0.0, angleY : float | np.ndarray[float] = 0.0, angleZ : float | np.ndarray[float] = 0.0
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
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Reference]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Rotation on spheroid: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243          #
#   |[2] Rotation on ellipse: https://blog.csdn.net/u014779685/article/details/136454696                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate the new position of a point when only rotating it along the spheroidal surface in a 3D system                        #
#   |[2] If the moving is on a spheroid other than unit sphere, one may need to standardize it before using this function               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |X,Y,Z        :   Coordinate on 3D axes                                                                                             #
#   |tolSurface   :   Tolerance when verifying whether the provided coordinates represents a point on the dedicated spheroid            #
#   |                 [<see def.>     ]  <Default> Use the system default tolerance level                                               #
#   |angleX,Y,Z   :   Angles (instead of arcs) to rotate the point on axes                                                              #
#   |                 [0.0            ]  <Default> Do not rotate the director                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<ndarray>    :   numpy array [N,3] where N is the number of elements in the provided vectors X, Y and Z                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241007        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, numpy, copy, collections                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

    #013. Define the local environment.

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

    #095. Verify whether the provided coordinates is on the surface of the dedicated spheroid
    spheroid = np.power(newX0, 2) + np.power(newY0, 2) + np.power(newZ0, 2)
    if not np.allclose(spheroid, 1.0):
        raise ValueError(f'[{LfuncName}]Some of the provided coordinates are not on the dedicated spheroids!')

    #200. Convert the angles into arcs
    if isinstance(angleX, Iterable):
        rotX = np.array(deepcopy(angleX), dtype = np.float64)
    else:
        rotX = np.array([deepcopy(angleX)], dtype = np.float64)
    if isinstance(angleY, Iterable):
        rotY = np.array(deepcopy(angleY), dtype = np.float64)
    else:
        rotY = np.array([deepcopy(angleY)], dtype = np.float64)
    if isinstance(angleZ, Iterable):
        rotZ = np.array(deepcopy(angleZ), dtype = np.float64)
    else:
        rotZ = np.array([deepcopy(angleZ)], dtype = np.float64)

    rotX *= np.pi / 180.0
    rotY *= np.pi / 180.0
    rotZ *= np.pi / 180.0

    #[ASSUMPTION]
    #[1] 球体坐标旋转推导: https://wenku.baidu.com/view/8be9144b1db91a37f111f18583d049649b660e83.html?_wkts_=1728186022243
    #[2] 坐标旋转公式: https://blog.csdn.net/u014779685/article/details/136454696
    #300. Rotate X
    newX1 = newX0
    newY1 = newY0 * np.cos(rotX) - newZ0 * np.sin(rotX)
    newZ1 = newZ0 * np.cos(rotX) + newY0 * np.sin(rotX)

    #500. Rotate Y
    newY2 = newY1
    newX2 = newX1 * np.cos(rotY) + newZ1 * np.sin(rotY)
    newZ2 = newZ1 * np.cos(rotY) - newX1 * np.sin(rotY)

    #700. Rotate Z
    newZ = newZ2
    newX = newX2 * np.cos(rotZ) - newY2 * np.sin(rotZ)
    newY = newY2 * np.cos(rotZ) + newX2 * np.sin(rotZ)

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
    import warnings
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import rotateSpheroid
    print(rotateSpheroid.__doc__)

    #How to determine a point on the surface of a sphere
    if False:
        #100. Provide a random point in the system, in order to determine the rotation angles on the dedicated sphere
        posX = 0.627 * (-1)
        posY = 1.149 * (-1)
        posZ = 2.118

        #200. Determine the size of the sphere
        rSphere = 2.5

        #300. Calculate the attributes
        # [ASSUMPTION]
        # [1] 球面坐标变换 https://baike.baidu.com/item/%E7%90%83%E9%9D%A2%E5%9D%90%E6%A0%87%E5%8F%98%E6%8D%A2/22368776?fr=ge_ala
        rTempSphere = np.sqrt(posX**2 + posY**2 + posZ**2)
        posTheta = np.arccos(posZ / rTempSphere)
        if posX == 0:
            posPhi = np.pi / 2 * np.sign(posY)
        elif posY == 0:
            posPhi = np.pi / 2 * (1 - np.sign(posX))
        else:
            posPhi = np.arctan(np.divide(posY, posX))

            #500. Correct the attributes due to the limitation of arc triangular functions
            #[ASSUMPTION]
            #[1] The scenario [X == Y == 0] does not exist for a spherical calculation
            if np.sign(posPhi) != np.sign(posY):
                posPhi = posPhi + np.pi

        #800. Calculate the coordinates
        oldX = round(rSphere * np.sin(posTheta) * np.cos(posPhi), 10)
        oldY = round(rSphere * np.sin(posTheta) * np.sin(posPhi), 10)
        oldZ = round(rSphere * np.cos(posTheta), 10)
        [oldX, oldY, oldZ]
        # [-0.6295610254, -1.1536931709, 2.1266511192]

    #100. Select a point on a sphere with radius as 2.5
    #[ASSUMPTION]
    #[1] If the spheroid is not a unit sphere, one has to standardize it, such as dividing each axis by their respective radius
    rSphere = 2.5
    oldX = -0.6295610254 / rSphere
    oldY = -1.1536931709 / rSphere
    oldZ = 2.1266511192 / rSphere

    #200. These numbers are values in Degrees instead of arcs
    rotX = -17
    rotY = -8
    rotZ = 0

    #300. Rotate the sphere
    newPos = rotateSpheroid(oldX,oldY,oldZ, tolSurface = 1e-6, angleX = rotX, angleY = rotY, angleZ = rotZ) * rSphere
    # array([
    #     [-0.95341831],
    #     [-0.48150965],
    #     [ 2.26034112]
    # ])
#-Notes- -End-
'''
