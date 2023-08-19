#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def gcdExtInteger(a, b):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the extended Greatest Common Divisor (GCD), a.k.a. Highest Common Factor (HCF) of two       #
#   | integers using Euclidean Algorithm, together with integers <x> and <y> such that: ax + by = gcd(a,b)                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://www.geeksforgeeks.org/euclidean-algorithms-basic-and-extended/                                                         #
#   |[2] https://www.rookieslab.com/posts/extended-euclid-algorithm-to-find-gcd-bezouts-coefficients-python-cpp-code                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |a,b         :   The input integer objects                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[tuple]     :   3-tuple of : (GCD of the inputs, x, y)                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230819        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys                                                                                                                            #
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

    #050. Initialization
    s = 0; old_s = 1
    t = 1; old_t = 0
    r = b; old_r = a

    #500. Reduce the calculation
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
        old_t, t = t, old_t - quotient * t

    #900. Output a tuple
    return((old_r, old_s, old_t))
#End gcdExtInteger

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
    from omniPy.Stats import gcdExtInteger
    print(gcdExtInteger.__doc__)

    #[AMD Ryzen 5 5600X 6Core 3.7G]

    #100. Create the testing data
    pool = [7,21,10,27,87,111,35]

    aaa = np.random.choice(pool, 1000000, replace = True).astype(int)
    bbb = np.random.choice(pool, 1000000, replace = True).astype(int)
    ccc = np.random.choice(pool, 1000000, replace = True).astype(int)

    #200. Vectorize the function to handle large vector
    gcdext_vec = np.vectorize(gcdExtInteger)

    #300. Simple test
    res = gcdext_vec(95642, 1681)
    print('GCD of 95642 and 1681 is %d. x = %d and y = %d in 95642x + 1681y = gcd(95642, 1681)' % (res[0], res[1], res[2]))
    # GCD of 95642 and 1681 is 1. x = 682 and y = -38803 in 95642x + 1681y = gcd(95642, 1681)

    #500. Test the speed
    t0 = time.time()
    x = gcdext_vec(aaa,bbb)
    print(time.time() - t0)
    #0.681s

    aaa[:5]
    bbb[:5]
    x[0][:5]
    x[1][:5]
    x[2][:5]

    #900. Official code in recursion (which is much slower)
    def gcd_extended(a,b):
        # Base Case
        if a == 0 :
            return((b,0,1))

        gcd,x1,y1 = gcd_extended(b%a, a)

        # Update x and y using results of recursive call
        x = y1 - (b//a) * x1
        y = x1

        return((gcd,x,y))
#-Notes- -End-
'''

'''
#-Terminology- -Begin-
As seen above, x and y are results for inputs a and b,
a.x + b.y = gcd                      -(1)
And x1 and y1 are results for inputs b%a and a
(b%a).x1 + a.y1 = gcd
When we put b%a = (b – ([b/a]).a) in above,
we get following. Note that [b/a] is floor(b/a)
(b – ([b/a]).a).x1 + a.y1  = gcd
Above equation can also be written as below
b.x1 + a.(y1 – ([b/a]).x1) = gcd      -(2)
After comparing coefficients of a and b in (1) and
(2), we get following,

Comparing LHS and RHS,
x = y1 – [b/a] * x1
y = x1

print('r: ', r, '\n', 's: ', s, '\n', 't: ', t, '\n', 'old_r: ', old_r, '\n', 'old_s: ', old_s, '\n', 'old_t: ', old_t)

Time Complexity: O(log N)
Auxiliary Space: O(log N)
#-Terminology- -End-
'''
