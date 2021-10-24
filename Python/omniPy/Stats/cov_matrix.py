#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import sys, warnings

def cov_matrix( x , y = None , rowvar = False ) -> 'Covariance between each column in a matrix to all others':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Covariance Matrix for each column in the matrix to all other columns                    #
#   |This function calculates much faster than the internal function [np.cov()]                                                         #
#   |Quote: https://blog.csdn.net/lph188/article/details/84501481                                                                       #
#   |Quick solution is as below:                                                                                                        #
#   |n <- nrow(x)                                                                                                                       #
#   |#Below function [diag(1,100000)] will consume 74.5GB RAM! Thus it cannot be applied to mass calculation.                           #
#   |mx <- diag(1,n) - matrix(1,n,n) / n                                                                                                #
#   |cov <- t(x) %*% mx %*% x)/(n-1)                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Difference between this function, [np.cov] and R:                                                                                  #
#   |[1] This function is able to be applied to two different matrices, while [np.cov] can only be applied to a single matrix           #
#   |[2] This function is slightly slower than [np.cov] on large matrix                                                                 #
#   |[3] Both functions in Python are twice faster than R with much less CPU effort (only when Rcpp is applied for calculation based on #
#   |     C++ optmization)                                                                                                              #
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
#   |               Each [k,m] represents the covariance of [k]th column in [x] to [m]th column in [y]                                  #
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
        warnings.warn( '[' + LfuncName +  ']NaN values are found, [np.nanmean] is used instead! Result may be unexpected!' )
        f_mean = np.nanmean
    else:
        f_mean = np.mean

    #013.   Define the local environment.

    #050.   Transpose [x] if it is requested for calculation based on [row]s.
    if isinstance( x , ( np.ndarray ) ): x = np.asmatrix(x)
    if rowvar: x = x.T

    #100.   Reshape [x].
    x = x.astype(np.float64)
    n = x.shape[0]
    x -= f_mean(x, axis = 0)

    #300.   Further handle [y] if it is provided.
    if y is None: y = x
    elif y is x: pass
    else:
        #050.   Transpose [x] if it is requested for calculation based on [row]s.
        if isinstance( y , ( np.ndarray ) ): y = np.asmatrix(y)
        if rowvar: y = y.T

        #100.   Reshape [y].
        y = y.astype(np.float64)
        y -= f_mean(y, axis = 0)

    #900.   Output.
    return( np.dot(x.T, y) / (n - 1) )
#End cov_matrix

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import time
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import cov_matrix
    print(cov_matrix.__doc__)

    #[AMD FX-6300 6Core 3.5G]

    #100.   Create the testing dataset.
    x1 = np.random.randn(10,5)
    y1 = np.random.randn(10,5)
    isinstance(x1,( np.ndarray ))

    #200.   Calculate the covariance matrix of a single matrix.
    t0 = time.time()
    c1 = cov_matrix(x1)
    print(time.time() - t0)

    t0 = time.time()
    c2 = np.cov(x1, rowvar = False)
    print(time.time() - t0)

    np.allclose(c1,c2)

    #500.   Create the large matrices.
    x2 = np.random.randn(100000,1000)
    y2 = np.random.randn(100000,500)

    #500. Calculation upon large matrix
    t0 = time.time()
    c3 = cov_matrix(x2)
    print(time.time() - t0)
    #5.08s

    t0 = time.time()
    c4 = np.cov(x2, rowvar = False)
    print(time.time() - t0)
    #4.85s

    np.allclose(c3,c4)

    #600. Calculation upon two different matrices.
    t0 = time.time()
    c_xy1 = cov_matrix(x2, y2)
    print(time.time() - t0)
    #4.82s
#-Notes- -End-
'''
