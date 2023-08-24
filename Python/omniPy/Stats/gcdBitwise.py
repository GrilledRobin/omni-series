#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numpy as np
from copy import deepcopy
from collections.abc import Iterable

def gcdBitwise( a , b ) -> int:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Greatest Common Divisor (GCD), a.k.a. Highest Common Factor (HCF) of two integers,      #
#   | using Stein's Algorithm.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |This is only a demonstration of bitwise calculation, and is much slower than <numpy.gcd> using Euclidean Algorithm                 #
#   |[1] https://www.geeksforgeeks.org/steins-algorithm-for-finding-gcd/                                                                #
#   |[2] https://reddit.com/r/3blue1brown/comments/yn6wfo/divide_a_whole_number_by_2_until_it_reaches_an/                               #
#   |[3] https://www.pythonfixing.com/2022/11/fixed-numpy-int-bit-length.html                                                           #
#   |[4] https://stackoverflow.com/questions/11175131/code-for-greatest-common-divisor-in-python                                        #
#   |[5] https://www.geeksforgeeks.org/time-complexity-of-euclidean-algorithm/                                                          #
#   |[6] https://www.baeldung.com/cs/euclid-time-complexity                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |a,b         :   The input integer objects, or Iterable of integers                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[int]       :   Element-wise GCD of the inputs                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230819        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1                                                                                                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230824        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function with numpy to make it vectorized, raise the speed by 10 times (still 10 times slower than numpy)   #
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
#   |   |sys, numpy, copy, collections                                                                                                  #
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

    #012. Handle the parameter buffer
    a_iterable = isinstance(a, Iterable)
    b_iterable = isinstance(b, Iterable)
    if a_iterable:
        a = np.array(deepcopy(a), dtype = np.int64)
    else:
        a = np.array([deepcopy(a)], dtype = np.int64)
    if b_iterable:
        b = np.array(deepcopy(b), dtype = np.int64)
    else:
        b = np.array([deepcopy(b)], dtype = np.int64)

    #100. Initialization
    rstOut = np.where(a > b, b, a)

    #100. Finding 2^K, where K is the greatest power of 2 that divides both a and b
    #[ASSUMPTION]
    #[1] numpy does not have method <obj.bit_length()>, hence we should look out for alternatives
    ab = a | b
    exp2 = ab & np.invert(ab - 1)

    #300. Dividing a by 2 until a becomes odd
    a_exp2 = a & np.invert(a - 1)
    with np.errstate(divide = 'ignore', invalid = 'ignore'):
        a = np.where(a == 0, a, (a / a_exp2).astype(np.int64))

    #500. From here on, 'a' is always odd
    while(np.any(b != 0)):
        #100. If b is even, remove all factor of 2 in b
        b_exp2 = b & np.invert(b - 1)
        with np.errstate(divide = 'ignore', invalid = 'ignore'):
            b = np.where(b == 0, b, (b / b_exp2).astype(np.int64))

        #500. Now a and b are both odd. Swap if necessary
        comp = a > b
        tmp_a = np.where(comp, b, a)
        tmp_b = np.where(comp, a, b)

        #900. Subtract a from b
        b = np.where(b == 0, b, tmp_b - tmp_a)
        a = tmp_a

        #990. Assign the result
        rstOut = np.where(a == 0, rstOut, a)

    #900. Restore common factors of 2
    if a_iterable or b_iterable:
        return(rstOut * exp2)
    else:
        return((rstOut * exp2)[0])
#End gcdBitwise

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import time
    import sys
    import math
    import numpy as np
    from functools import reduce
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import gcdBitwise
    print(gcdBitwise.__doc__)

    #[AMD Ryzen 5 5600X 6Core 3.7G]

    #100. Create the testing data
    pool = [7,21,10,27,87,111,35]

    aaa = np.random.choice(pool, 1000000, replace = True).astype(int)
    bbb = np.random.choice(pool, 1000000, replace = True).astype(int)
    ccc = np.random.choice(pool, 1000000, replace = True).astype(int)

    #200. Vectorize the function to handle large vector
    gcd_math = np.vectorize(math.gcd)

    #500. Compare the speed
    t0 = time.time()
    x1 = np.gcd(aaa,bbb)
    print(time.time() - t0)
    #0.0115s

    t0 = time.time()
    x2 = gcdBitwise(aaa,bbb)
    print(time.time() - t0)
    #0.159s
    #14 times of the numpy function

    t0 = time.time()
    x3 = gcd_math(aaa,bbb)
    print(time.time() - t0)
    #0.071s
    #6 times of the numpy function

    np.all(x1 == x2)
    #True

    np.all(x1 == x3)
    #True

    #500. Compare the speed for reducing over multiple vectors
    t0 = time.time()
    y1 = np.gcd.reduce([aaa,bbb,ccc])
    print(time.time() - t0)
    #0.022s

    t0 = time.time()
    y2 = reduce(gcdBitwise, [aaa,bbb,ccc])
    print(time.time() - t0)
    #0.327s
    #14 times of the numpy function

    t0 = time.time()
    y3 = reduce(gcd_math, [aaa,bbb,ccc])
    print(time.time() - t0)
    #0.139s
    #6 times of the numpy function

    np.all(y1 == y2)
    #True

    np.all(y1 == y3)
    #True

    #900. Official code
    def gcd(a,b):
        while b:
            a, b = b, a % b
        return(a)

    # Time Complexity: O(log b)
    # Auxiliary Space: O(log b)
#-Notes- -End-
'''

'''
#-Terminology- -Begin-
Time Complexity: O(N*N)
Auxiliary Space: O(1)

Quote: https://www.geeksforgeeks.org/highest-power-of-two-that-divides-a-given-number/?ref=ml_lbp
a = 64
b = 48
ab = a | b

[1] Below gives the maximum power to 2 that divides ab (also used in below original algorithm):
4 == (ab ^ (ab - 1)).bit_length() - 1

[2] Below two algorithms give the number that divides ab:
16 == ab & ~(ab - 1)
16 == 1 << (ab & -ab).bit_length() - 1

#old function to handle one pair of integers at one time
#100 times slower than numpy.gcd
def gcdBitwiseOld(a,b):
    #050. Direct return for special cases
    # GCD(0, b) == b; GCD(a, 0) == a,
    # GCD(0, 0) == 0
    if (a == 0):
        return b

    if (b == 0):
        return a

    #100. Finding K, where K is the greatest power of 2 that divides both a and b
    ab = a | b
    k = int(ab ^ (ab - 1)).bit_length() - 1

    #300. Dividing a by 2 until a becomes odd
    a_k2 = int(a ^ (a - 1)).bit_length() - 1
    a >>= a_k2

    #500. From here on, 'a' is always odd
    while(b):
        #100. If b is even, remove all factor of 2 in b
        b_k2 = int(b ^ (b - 1)).bit_length() - 1
        b >>= b_k2

        #500. Now a and b are both odd. Swap if necessary
        if (a > b):
            a, b = b, a

        #900. Subtract a from b
        b -= a

    #900. Restore common factors of 2
    return (a << k)
#-Terminology- -End-
'''
