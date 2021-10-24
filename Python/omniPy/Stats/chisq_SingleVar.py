#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def chisq_SingleVar( inDAT , dependent , response , event = 1 ) -> 'Calculate the Chi-Square score for [response] variable in the dataset':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to test the Chi-Square distribution for [response] in the provided dataset in terms of a single          #
#   | [dependent], while return below values:                                                                                           #
#   |[1] Chi-Square value                                                                                                               #
#   |[2] Degree of Freedom                                                                                                              #
#   |[3] P-Value at such Chi-Square and Degree of Freedom                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDAT      :   The input pd.DataFrame for the calculation.                                                                         #
#   |dependent  :   The dependent variable in the procided dataset                                                                      #
#   |response   :   The independent variable, or the response variable, in the procided dataset                                         #
#   |event      :   The value that represents the Event                                                                                 #
#   |               DEFAULT : [1]                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[outChiSq] :   [float64]The Chi-Square value upon [response] for [dependent]                                                       #
#   |[outDoF]   :   [int]The degree of Freedom in terms of unique values in [dependent]                                                 #
#   |[ourPVal]  :   [float64]The P-Value at such Chi-Square distribution with such Degree of Freedom                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20190402        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, pandas, scipy                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Stats                                                                                                                   #
#   |   |   |countEvent                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Import necessary functions for processing.
    #from imp import find_module
    import pandas as pd
    import sys
    from scipy.stats import chi2
    from omniPy.Stats import countEvent

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = "ERROR: [" + LfuncName + "]Process failed due to errors!"

    #012.   Handle the parameter buffer.
    if not isinstance( inDAT , pd.DataFrame ):
        raise TypeError( '[' + LfuncName +  ']Parameter [inDAT] should be of the type [pd.DataFrame]! Type of input value is [{0}]'.format( type(inDAT) ) )

    #013.   Define the local environment.

    #100.   Count the Event and Non-Event per requested [response].
    k_Event , k_NonEvent = countEvent( inDAT[response] , event = event )

    #110.   Calculate the Positive Ratio and Negative Ratio in the entire sample base.
    r_pos : float = k_Event / ( k_Event + k_NonEvent )
    r_neg : float = k_NonEvent / ( k_Event + k_NonEvent )

    #190.   Raise error if either of the counts is zero, as Chi-Square test fails if [dependent] has no effect upon [response].
    if k_Event == 0:
        raise ValueError( '[' + LfuncName +  ']Count of [event:{0}] is zero! Chi-Square test fails for the response:[{1}] in terms of the dependent:[{2}]!'.format( event , response , dependent ) )
    if k_NonEvent == 0:
        raise ValueError( '[' + LfuncName +  ']Count of [non-event:(other than: {0})] is zero! Chi-Square test fails for the response:[{1}] in terms of the dependent:[{2}]!'.format( event , response , dependent ) )

    #200.   Create the cross tabulation with row as [dependent] and column as a binary mask to [response].
    #210.   Create a binary mask to [responese].
    mask : pd.Series = inDAT[response].apply( lambda x : x == event )

    #250.   Cross-tabulation.
    tabfreq : pd.DataFrame = pd.crosstab( inDAT[dependent] , mask ).rename( columns = { False:'NonEvent' , True:'Event' } )

    #300.   Calculate Chi-Square value at row level.
    #310.   Sum the [Event] and [NonEvent] at row level. (Stats: 卡方检验中，此值用于计算当前分组中正例与负例的期望值)
    tabfreq['Total'] = tabfreq.sum(axis = 1)

    #320.   Calculate the expected value of [Event] and [NonEvent] respectively. (Stats: 当前组中正例的期望值=当前组样本量*总样本中正例的比例；负例同理)
    tabfreq['e_Event'] = tabfreq['Total'] * r_pos
    tabfreq['e_NonEvent'] = tabfreq['Total'] * r_neg

    #350.   Calculate the element of Chi-Square value at current row.
    tabfreq['chisq_Event'] = ( tabfreq['Event'] - tabfreq['e_Event'] )**2 / tabfreq['e_Event']
    tabfreq['chisq_NonEvent'] = ( tabfreq['NonEvent'] - tabfreq['e_NonEvent'] )**2 / tabfreq['e_NonEvent']
    tabfreq['chisq'] = tabfreq['chisq_Event'] + tabfreq['chisq_NonEvent']

    #500.   Calculate Chi-Square value.
    outChiSq : float = tabfreq['chisq'].sum()

    #600.   Calculate Degree of Freedom.
    outDoF : int = tabfreq['chisq'].count() - 1
    #The original function should be as below, we simplify it as the [response] is only split into 2 parts with DOF=2-1=1.
    #outDoF : int = ( tabfreq['chisq'].count() - 1 ) * ( inDAT[response].apply( lambda x : x == event ).nunique() - 1 )

    #700.   Calculate P-Value.
    #Here the P-Value is identical to the Survival Function at current Chi-Square value for current Degree of Freedom.
    ourPVal : float = chi2.sf( outChiSq , outDoF )

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None
    k_Event , k_NonEvent , r_pos , r_neg , mask , tabfreq = None , None , None , None , None , None

    #900.   Output.
    return( outChiSq , outDoF , ourPVal )
#End chisq_SingleVar

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010.   Create envionment.
    import pandas as pd
    import numpy as np
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import chisq_SingleVar

    #100.   Create the testing dataset.
    #110.   Create customer list.
    ncust : int = 200
    lcust : list = [ '{0:{fill}{width}}'.format( i + 1 , fill = 0 , width = 7 ) for i in range(ncust) ]
    np.random.shuffle( lcust )

    #120.   Create performance data.
    l_qpv : list = [ [ 1 , 0.3 ] , [ 0 , 0.7 ] ]
    cus_qpv : list = np.random.choice( [ i[0] for i in l_qpv ] , ncust , p = [ i[1] for i in l_qpv ] ).tolist()
    np.random.shuffle( cus_qpv )

    #130.   Create residential information.
    l_resi : list = [ [u'上海',0.427] , [u'北京',0.332] , [u'杭州',0.058] , [u'天津',0.125] , [u'重庆',0.014] , [u'成都',0.007] , [u'广州',0.009] , [u'深圳',0.001] , [u'厦门',0.027] ]
    cus_resi : list = np.random.choice( [ i[0] for i in l_resi ] , ncust , p = [ i[1] for i in l_resi ] ).tolist()
    np.random.shuffle( cus_resi )

    #190.   Create the dataset.
    data : pd.DataFrame = pd.DataFrame( list(zip( lcust , cus_qpv , cus_resi )) , columns = [ 'CustID' , 'QPV' , 'Residence' ] )
    #Read the exiting CSV:
    data : pd.DataFrame = pd.read_csv( r'D:\Python\omniPy\Stats\data_for_chisq.csv' )

    #200.   Calculate the Chi-Square value.
    chisq_resi , dof_resi , pval_resi = chisq_SingleVar( data , 'Residence' , 'QPV' )

    #300.   Export for SAS program to verify the calculation result.
    data.to_csv( r'D:\Python\omniPy\Stats\data_for_chisq.csv' , index = False )

#-Notes- -End-
"""

"""
#SAS Program as verification for the same dataset:
data cust_data;
    infile 'D:\Python\omniPy\Stats\data_for_chisq.csv' dsd dlm = ',' firstobs = 2 encoding = 'utf-8';
    length c_custid $8 f_qpv 3 c_resi $16;
    input c_custid $ f_qpv c_resi $;
run;

proc freq data=cust_data;
    tables c_resi * f_qpv / chisq;
run;

"""

"""
#-Explanation- -Begin-
#卡方检验: https://baike.baidu.com/item/%E5%8D%A1%E6%96%B9%E6%A3%80%E9%AA%8C/2591853?fr=aladdin
#Another case: https://blog.csdn.net/ludan_xia/article/details/81737669

#Keywords:
#[01] 卡方检验的目的是验证两组数据是否独立，Null Hypothesis即原假设是：两者独立
#[02] 上例中，其中一组结果是：[chisq_resi=9.52], [dof_resi=7], [pval_resi=0.2177]
#[03] 查表得知：[DOF=7]的时候，[6.35 < 9.52 < 12.02]，则“两者相关”的概率区间为：[1-0.5 ~ 1-0.1]即[50%~90%] (SAS中给出的概率为：[1-21.77%]=78.23%)
#[04] 表中的P-Value等价于H0的Survival Function，也即“两者独立的概率”；因此21.77%可以解读为：两者独立的概率为21.77%
#[05] 然而，由于卡方检验仅检验独立性，并非检验相关性，所以不能因此认为两者相关；需要借助其他工具，如IV进一步检验
#-Explanation- -End-
"""