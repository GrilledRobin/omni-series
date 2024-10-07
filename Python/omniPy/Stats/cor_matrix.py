#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import sys, warnings
from omniPy.Stats import cov_matrix

def cor_matrix( x , y = None , rowvar = False ) -> 'Correlation Coefficient between each column in a matrix to all others':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Correlation Coefficient Matrix for each column in the matrix to all other columns       #
#   |Quote: https://blog.csdn.net/lph188/article/details/84501481                                                                       #
#   |Formula of [pearson correlation coefficient] is as below:                                                                          #
#   |COR(X,Y) = COV(X,Y) / ( STD(X) * STD(Y) )                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Difference between this function, [np.corrcoef] and R:                                                                             #
#   |[1] This function is able to be applied to two different matrices, while [np.corrcoef] can only be applied to a single matrix      #
#   |[2] This function is slightly slower than [np.corrcoef] on large matrix                                                            #
#   |[3] Both functions in Python are slightly faster than R with much less CPU effort (only when Rcpp is applied for calculation based #
#   |     on C++ optmization), and much faster than base function [cor] in R                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x,y        :   The input matrices for which the calculation is to be taken upon the columns                                        #
#   |rowvar     :   Whether the requested calculation is applied to each row to all others (Compatible to [numpy])                      #
#   |               [False]<Default> Calculate the distance between each column in [x] to that in [y]                                   #
#   |               [True]           Calculate the distance between each row in [x] to that in [y]                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[matrix]   :   The [K*M] matrix, where [K] is equal to the number of columns of [x], while [M] is the number of columns of [y]     #
#   |               Each [k,m] represents the Correlation Coefficient of [k]th column in [x] to [m]th column in [y]                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200606        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1                                                                                                                   #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent packages                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |numpy, sys, warnings                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Stats                                                                                                                   #
#   |   |   |cov_matrix                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001.   Import necessary functions for processing.

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012.   Handle the parameter buffer.
    if not isinstance( x , ( np.ndarray , np.matrix ) ):
        raise TypeError( '[' + LfuncName +  '][x] should be of the type [np.matrix]! Type of input value is [{0}]'.format( type(x) ) )
    chkNaN_x = min( x[np.isnan(x)].shape ) != 0
    chkNaN_y = False
    if y is not None:
        if not isinstance( y , ( np.ndarray , np.matrix ) ):
            raise TypeError( '[' + LfuncName +  '][y] should be of the type [np.matrix]! Type of input value is [{0}]'.format( type(y) ) )
        chkNaN_y = min( y[np.isnan(y)].shape ) != 0
    chkNaN = chkNaN_x | chkNaN_y
    if chkNaN:
        warnings.warn( '[' + LfuncName +  ']NaN values are found, [np.nanstd] is used instead! Result may be unexpected!' )
        f_std = np.nanstd
    else:
        f_std = np.std

    #013.   Define the local environment.

    #050.   Transpose [x] if it is requested for calculation based on [row]s.
    if isinstance( x , ( np.ndarray ) ): x = np.asmatrix(x)
    if rowvar: x = x.T

    #100.   Reshape [x].
    x = x.astype(np.float64)

    #300.   Further handle [y] if it is provided.
    if y is None: y = x
    elif y is x: pass
    else:
        #050.   Transpose [x] if it is requested for calculation based on [row]s.
        if isinstance( y , ( np.ndarray ) ): y = np.asmatrix(y)
        if rowvar: y = y.T

        #100.   Reshape [y].
        y = y.astype(np.float64)

    #500.   Calculate the Standard Deviation of both [x] and [y].
    std_x = np.asmatrix( f_std( x , axis = 0 , ddof = 1 ) )
    if y is x: std_y = std_x
    else: std_y = np.asmatrix( f_std( y , axis = 0 , ddof = 1 ) )

    #900.   Output.
    return( cov_matrix(x, y) / np.dot( std_x.T , std_y ) )
#End cor_matrix

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import time
    import sys
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import cov_matrix, cor_matrix
    print(cor_matrix.__doc__)

    #[AMD FX-6300 6Core 3.5G]

    #100.   Create the testing dataset.
    x1 = np.random.randn(10,5)
    y1 = np.random.randn(10,5)
    isinstance(x1,( np.ndarray ))

    #200.   Calculate the covariance matrix of a single matrix.
    t0 = time.time()
    r1 = cor_matrix(x1)
    print(time.time() - t0)

    t0 = time.time()
    r2 = np.corrcoef(x1, rowvar = False)
    print(time.time() - t0)

    np.allclose(r1,r2)

    #500.   Create the large matrices.
    x2 = np.random.randn(100000,1000)
    y2 = np.random.randn(100000,500)

    #500. Calculation upon large matrix
    t0 = time.time()
    r3 = cor_matrix(x2)
    print(time.time() - t0)
    #9.34s

    t0 = time.time()
    r4 = np.corrcoef(x2, rowvar = False)
    print(time.time() - t0)
    #4.61s

    np.allclose(r3,r4)

    #600. Calculation upon two different matrices.
    t0 = time.time()
    r_xy1 = cor_matrix(x2, y2)
    print(time.time() - t0)
    #7.14s
#-Notes- -End-
'''
