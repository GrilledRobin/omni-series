#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def calcKS( inDAT , dependent , response , event = 1 ) -> 'Calculate the Kolmogorov-Smirnov score for [response] variable in the dataset':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the K-S Value for the variable [response] in terms of [dependent] variable in the provided  #
#   | pd.DataFrame.                                                                                                                     #
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
#   |[outKS]    :   [float64]The K-S score upon [response] for [dependent]                                                              #
#   |[outDAT]   :   [pd.DataFrame]The cross-tabulation of [dependent] X [Event/NonEvent] with the interim calculation values for        #
#   |                validation                                                                                                         #
#   |[ourAR]    :   [float64]The K-S score upon [response] for [dependent]                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20190331        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas                                                                                                                    #
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

    #110.   Calculate the Positive Ratio in the entire sample base.
    r_pos : float64 = k_Event / ( k_Event + k_NonEvent )

    #190.   Raise error if either of the counts is zero, as WoE means nothing if [dependent] has no effect upon [response].
    if k_Event == 0:
        raise ValueError( '[' + LfuncName +  ']Count of [event:{0}] is zero! KS means nothing to the response:[{1}] in terms of the dependent:[{2}]!'.format( event , response , dependent ) )
    if k_NonEvent == 0:
        raise ValueError( '[' + LfuncName +  ']Count of [non-event:(other than: {0})] is zero! KS means nothing to the response:[{1}] in terms of the dependent:[{2}]!'.format( event , response , dependent ) )

    #200.   Create the cross tabulation with row as [dependent] and column as a binary mask to [response].
    #210.   Create a binary mask to [responese].
    mask : pd.Series = inDAT[response].apply( lambda x : x == event )

    #250.   Cross-tabulation.
    tabfreq : pd.DataFrame = pd.crosstab( inDAT[dependent] , mask ).rename( columns = { False:'NonEvent' , True:'Event' } )

    #300.   Calculate the cummulative density at row level.
    #310.   Sum the [Event] and [NonEvent] at row level. (Stats: 计算逻辑回归结果中，每个cummulative decile的总样本量，也即[预测为正例]的总样本量)
    tabfreq['Total'] = tabfreq.sum(axis = 1)

    #320.   Calculate the cummulative percentage for [Event], [NonEvent] and [Total] respectively. (Stats: 分别计算TP，FP与当前[预测为正例]的累计百分比)
    cumdens = ( tabfreq.cumsum() / tabfreq.sum() ).rename( columns = { 'NonEvent':'cp_NonEvent' , 'Event':'cp_Event' , 'Total':'cp_Total' } )

    #330.   Calculate the gap between TPR and FPR at each row. (Stats: 二者累计百分比的差值)
    cumdens['TPR_FPR_Gap'] = abs( cumdens['cp_Event'] - cumdens['cp_NonEvent'] )

    #350.   Crate a smooth value for the cummulative density. (Stats: 对累计百分比做连续两组的平滑处理)(Exp: This is implemented in UOBC.)
    cumdens['rcp_Event'] = ( cumdens['cp_Event'] + cumdens['cp_Event'].shift(1).fillna(0) ) / 2
    cumdens['rcp_Total'] = ( cumdens['cp_Total'] + cumdens['cp_Total'].shift(1).fillna(0) ) / 2

    #500.   Calculate K-S score.
    outKS : float64 = cumdens[ cumdens['TPR_FPR_Gap'] == cumdens['TPR_FPR_Gap'].max() ]['TPR_FPR_Gap'][0]

    #600.   Calculate Accuracy Ratio. (Exp: This is implemented in UOBC.)
    #用当前decile中平滑处理过的TPR与同样处理过的[预测正例在全数据中的比重]做差值，再用[当前decile的样本在全数据中的比重]进行加权
    cumdens['AR'] = ( cumdens['rcp_Event'] - cumdens['rcp_Total'] ) * ( cumdens['cp_Total'] - cumdens['cp_Total'].shift(1).fillna(0) )
    #将全部加权后的差值加总，再除以[负例在全数据中的比重的1/2](同样可理解为[负例累计百分比的平滑处理])
    ourAR : float64 = abs( sum( cumdens['AR'] ) / ( ( 1 - r_pos )/2 ) )

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None
    k_Event , k_NonEvent , r_pos , mask = None , None , None , None

    #900.   Output.
    return( outKS , tabfreq.merge( cumdens , on = dependent ) , ourAR )
#End calcKS

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010.   Create envionment.
    import pandas as pd
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import calcKS

    #100.   Create the testing dataset.
    raw_x : list = [0,0,0,1,1,1,0,1,1,1]
    raw_y : list = [0,0,0,1,0,1,1,1,1,1]
    data : pd.DataFrame = pd.DataFrame( list(zip( raw_x , raw_y )) , columns = [ 'x' , 'y' ] )

    #200.   Calculate the WoE.
    KS , KSdat , AR = calcKS( data , 'x' , 'y' )
#-Notes- -End-
"""

"""
#-Explanation- -Begin-
#读懂逻辑回归的结果: https://www.jianshu.com/p/a72302fa03d7
#See the example of ROC: https://baike.baidu.com/item/ROC%E6%9B%B2%E7%BA%BF/775606?fr=aladdin
#Diagnostic example: https://www.cnblogs.com/webRobot/p/6803747.html

#Keywords:
#[01] 逻辑回归中，odds ratio (OR)，代表当前自变量改变一个单位时，odds改变的百分比。如OR[gender]=5.2：性别从男变女，改变1单位；则odds会因此改变5.2倍
#[02] 如果将odds ratio 减去1后乘以100（（odds ratio - 1）* 100），这个值就是自变量X每改变一个单位，odds的改变量
#[03] 在一个二分类模型中，对于所得到的连续结果，假设已确定一个阈值，比如说 0.6，大于这个值的实例划归为正类，小于这个值则划到负类中。
#[04] 逻辑回归得到的结果[模型得分（一般为预测正类的概率）]按从[大]到[小]排列
#[05] 按decile划分成10个组
#[06] 倘若以前10%的数值作为阈值，即将前10%的实例都划归为正类；则其中FP(真 正类)占全部正类的比重即为：[p_Event] = True Positive
#[07] 相应的FP(假 正类)占全部负类的比重即为：[p_NonEvent] = False Positive
#[08] ROC曲线：X轴 - p_NonEvent；Y轴 - p_Event
#[09] 对角线，代表P(y/SN)=P(y/N)，即被试者的辨别力d为0，ROC曲线离这条线愈远，表示被试者辨别力愈强

#[10] 同样以前10%的数值作为阈值，即将前10%的实例都划归为正类；则正确预测到的正例数占预测正例总数的比例：PV = [Event] / ( [Event] + [NonEvent] ) (若以前20%的数值作为阈值，则上述计算需用[累计数])
#[11] 此例中，正例的比例：Pi = k_Event / ( k_Event + k_NonEvent ) (此值无论以哪个decile来划分均不会变)
#[12] Lift即为：Lift = PV / Pi。大于1代表模型有提升，否则模型无效

#ROC与KS值的检验: https://blog.csdn.net/u012735708/article/details/86507026
#[31] ROC值一般在0.5-1.0之间。值越大表示模型判断准确性越高，即越接近1越好。ROC=0.5表示模型的预测能力与随机结果没有差别。
#[32] KS值表示了模型将+和-区分开来的能力。值越大，模型的预测准确性越好。一般，KS>0.2即可认为模型有比较好的预测准确性。

#Alternative:
#利用roc_curve。缺点：若数据中有缺失值会报错
#Reference: https://blog.csdn.net/u012735708/article/details/86678933
#from sklearn.metrics import roc_curve
#fpr,tpr,thresholds= roc_curve(data['y'],data['x'])
#ks = max(tpr-fpr)

#-Explanation- -End-
"""