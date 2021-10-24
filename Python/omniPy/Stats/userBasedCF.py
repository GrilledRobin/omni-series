#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
import sys, warnings
from scipy.stats import rankdata
from .sim_matrix_cosine import sim_matrix_cosine

def userBasedCF(
    dat,keyvar
    ,method = 'CosSim',matrix_sim = None
    ,sim_gt = None,score_gt = None
    ,topk_sim = 10,topk_recom = 5
    ,op_activity = 'all'
    ,**kw
) -> 'User-based Collaborative Filtering':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to make recommendation to each [row] in the provided data by item based similarity/distance for all      #
#   | respective columns, other than the [keyvar], upon others                                                                          #
#   |[Quote: http://www.salemmarafi.com/code/collaborative-filtering-r/ ]                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Concept:                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[100] 将除了[keyvar]之外的其他字段([Item])组成一个矩阵                                                                             #
#   |[200] 若未提供[相似度矩阵]，为上述矩阵中的[Item]两两计算[相似性]，默认为[余弦相似性]                                               #
#   |[310] 将[相似度矩阵]的对角线赋值，使其在整个矩阵中为最小，其作用为：在排名时，每个[Item]对自己的相似度排最后，从而排除在计算之外   #
#   |[320] 对[相似度矩阵]以“行”为单位排名，最大值排名为1（此时每个[Item]对自己的相似度被排为最低，所以不受影响）                        #
#   |[330] 对所有排名小于（也即高于）给定值的相似度标记为有效                                                                           #
#   |[340] 在上述有效标记的基础上，进一步筛选出相似度高于给定阈值的元素                                                                 #
#   |[390] 根据上述标记为“有效”的元素，得出用于计算的[相似度矩阵]                                                                       #
#   |[610] 对上述的新[相似度矩阵]按“行”加总，作为后续计算公式的“分母”                                                                   #
#   |[640] 用公式：[sumproduct(purchaseHistory, similarities)/sum(similarities)]对[User]的这个未做过[Activity]的[Item]计算分数          #
#   |[660] 将这些未做过[Activity]的[Item]s按上述的分数倒序排列，找出每个[User]排在前[topk_recom]的[Item]s，作为推荐结果输出             #
#   |[670] 标记出每个[User]排在前[topk_recom]的[Item]s                                                                                  #
#   |[680] 在上述有效标记的基础上，进一步筛选出分数高于给定阈值的元素                                                                   #
#   |[690] 根据上述标记为“有效”的元素，得出用于输出的[分数矩阵]                                                                         #
#   |[810] 按每个分数在[分数矩阵]中的绝对位置，标记出不为0的分数；方向为从上到下-从左到右（先行后列）；方便从中取出对应的分数           #
#   |[820] 按每个分数在[分数矩阵]中的“行”与“列”位置，标记出不为0的分数；方便在输入数据集中对位填充符合推荐条件的[Item]s                 #
#   |[890] 从输入数据集中取出符合推荐条件的[keyvar]，再补上推荐的[Item]s及它们的排名和分数；最后输出                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dat        :   The input dataset for which the calculation is to be taken upon the columns                                         #
#   |                [IMPORTANT] All the variables, other than the [keyvar] should be [numeric], and [non-missing]                      #
#   |keyvar     :   The variable name(s) that denotes to the [User]                                                                     #
#   |                A character string or a list of character strings, which represent the column names, should be provided            #
#   |method     :   The method to conduct the calculation, usually the similarity function or distance function                         #
#   |                Below methods are supported:                                                                                       #
#   |                [CosSim] Cosine Similarity between each respective columns and others                                              #
#   |matrix_sim :   The pre-calculated [N*N] matrix that denotes the similarities between all [Item]s                                   #
#   |                If it is not provided, the function will generate it out of the [dat] using the provided [method]                  #
#   |sim_gt     :   Only preserve the [Item]s whose similarities between each other are greater than this value                         #
#   |score_gt   :   Only preserve the scores in the output result which are greater than this value                                     #
#   |topk_sim   :   How many similar [Item]s to the [Item] tha the [User] has NOT acted upon                                            #
#   |topk_recom :   How many [Item]s to be recommended to each [User]                                                                   #
#   |op_activity:   The strategy of recommendation (or operation) upon the items on which the user has taken activity                   #
#   |                [all       ]<default>  Recommend all [item]s, regardless of those on which user has taken activity, e.g. purchased #
#   |                [inclusive ]           Only recommend the [item]s on which user has taken activity, e.g. purchased                 #
#   |                                        This is used to recommend the products among those the user has purchased.                 #
#   |                [exclusive ]           Only recommend the [item]s on which user has never taken activity, e.g. purchased           #
#   |                                        This is used to recommend the products among those the user never purchased.               #
#   |**kw       :   Any other parameters that are required by the method to be used. Please check the documents for those functions     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[df]       :   [data.frame] The dataset containing the recommendation for all users                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[keyvar]   :   The variable(s) acting as [User] in the input data                                                              #
#   |   |ItemName   :   The name of the [Item] to be recommended to the [User] based on the request                                     #
#   |   |ItemRank   :   The rank of the [Item] for recommendation, the smaller the higher priority                                      #
#   |   |Score      :   The score of the [Item] for evaluation                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200607        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200706        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the [rankdata] (scipy >= v1.5.1) to save 33% of system calculation effort, compared to [.argsort().argsort()] #
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
#   |   |numpy, sys, warnings, scipy, pandas                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Stats                                                                                                                   #
#   |   |   |sim_matrix_cosine                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012.   Handle the parameter buffer.
    op_choices = ('all','inclusive','exclusive')
    if op_activity not in op_choices:
        raise ValueError( '[' + LfuncName + '][op_activity] must be among: ' + str(op_choices) + '! Input is [{0}]'.format( op_activity ) )
    map_func = { 'CosSim': sim_matrix_cosine }
    if method is None: method = 'CosSim'
    if len(method) == 0: method = 'CosSim'
    if topk_sim is None: topk_sim = 10
    if topk_recom is None: topk_recom = 5

    #100. Turn the input data into a matrix for calculation
    #110. Retrieve the column names, except the key variables, for later mapping of output result
    #[Quote: https://stackoverflow.com/questions/27129152/pandas-column-names-to-list ]
    colnames = dat.head(1).drop( keyvar , axis = 1 ).columns.values

    #190. Conversion
    #[Quote: https://stackoverflow.com/questions/13411544/delete-column-from-pandas-dataframe ]
    m_dat = np.asmatrix( dat.drop( keyvar , axis = 1 ) )

    #200. Calculate the similarity/distance for columns/[Item]s
    if matrix_sim is None:
        m_item_sim = map_func.get(method)( m_dat , **kw )
    else:
        m_item_sim = matrix_sim

    #300. Retrieve the [topk_sim] similar [Item]s to each [Item]
    #310. Ensure the self-similarity to be placed at last during the ranking
    #The second [diag] creates a diagonal matrix for later subtraction only upon the diagonal values
    m_item_sim_mod = m_item_sim - np.diag( np.diag(m_item_sim) + np.amax(m_item_sim) + 1 )

    #320. Rank the similarity matrix by row in descending order of similarity values
    #We will soon use [tcrossprod] for matrix multiplication,
    # hence here we calculate upon rows in preparation of later transposition
    #[Quote: https://stackoverflow.com/questions/5284646/rank-items-in-an-array-using-python-numpy-without-sorting-array-twice ]
    #The first [np.argsort] to obtain the orders of the matrix along the axis [-1] by default
    #The second [np.argsort] to obtain the ranks of the matrix along the axis [-1] by default
    #m_item_sim_rnk = ( m_item_sim_mod * (-1) ).argsort().argsort()
    #Introduction of the function [rankdata] saves 33% of system effort
    m_item_sim_rnk = rankdata( m_item_sim_mod * (-1) , method = 'ordinal' , axis = 1 )

    #330. Flag those elements which rank lower than [topk_sim + 1], while set others as 0 for exclusion
    #m_item_sim_flg = (m_item_sim_rnk < topk_sim)
    #Introduction of the function [rankdata] indicates that the [ranks] start from 1, hence we set the operand as [<=]
    m_item_sim_flg = (m_item_sim_rnk <= topk_sim)

    #340. Flag those elements whose values are greater than the requested [sim_gt]
    #We use [np.multiply] to conduct element-wise multiplication between the matrices
    if sim_gt is not None: m_item_sim_flg = np.multiply( m_item_sim_flg , m_item_sim > sim_gt )

    #390. Create the final [Item] similarity matrix by adding all requested filtrations
    m_item_sim_fnl = np.multiply( m_item_sim , m_item_sim_flg )

    #600. Calculate the [User] based score with below formula:
    #[score = sumproduct( purchaseHistory , similarity ) / sum( similarity )]
    #where:
    #[purchaseHistory]: times of purchase upon the most similar products to that one the [User] did not purchase
    #[similarity]: the similarity of the most similar products to that one the [User] did not purchase
    #610. Prepare the denominator, i.e. the [similarity] matrix mentioned in above formula
    #611. Inverse every element of the row-sum of adjusted similarity matrix
    #This step acts as: [1 / sum( similarity )]
    m_item_sim_inv = 1 / np.sum( m_item_sim_fnl , axis = 1 )

    #612. Reset the infinite values as 0 for those [Item]s without similar [Item]s to them
    m_item_sim_inv[np.isinf(m_item_sim_inv)] = 0

    #615. Make the denominator a matrix instead of a single dimensional vector
    #Python will broadcast the array to the same axis along a matrix only upon the common operands, like [*],
    # hence we still have to create proper matrix for multiplication if we use [np.multiply]
    m_item_sim_inv = np.repeat( m_item_sim_inv.T , m_dat.shape[0] , axis = 0 )

    #640. Translate the formula into matrix multiplication
    m_user_score = np.multiply( np.dot( m_dat , m_item_sim_fnl.T ) , m_item_sim_inv )

    #650. Apply the recommendation strategy
    if op_activity == 'inclusive':
        m_user_score = np.multiply( m_user_score , m_dat != 0 )
    elif op_activity == 'exclusive':
        m_user_score = np.multiply( m_user_score , m_dat == 0 )

    #660. Rank the scores of [Item]s per [User] in descending order
    #For [np.argsort], the first element among the same ones along the dedicated axis takes the higher rank, same as 'first' in R
    #m_user_score_rnk = ( m_user_score * (-1) ).argsort().argsort()
    #Introduction of the function [rankdata] saves 33% of system effort
    m_user_score_rnk = rankdata( m_user_score * (-1) , method = 'ordinal' , axis = 1 )

    #670. Flag those scores which rank lower than [topk_recom + 1], while set others as 0 for exclusion
    #m_user_score_flg = (m_user_score_rnk < topk_recom)
    #Introduction of the function [rankdata] indicates that the [ranks] start from 1, hence we set the operand as [<=]
    m_user_score_flg = (m_user_score_rnk <= topk_recom)

    #680. Flag those scores whose values are greater than the requested [score_gt]
    if score_gt is not None: m_user_score_flg = np.multiply( m_user_score_flg , m_user_score > score_gt )

    #690. Finalize the scores by adding all requested filtrations
    m_user_score_fnl = np.multiply( m_user_score , m_user_score_flg )

    #800. Extract the valid recommendation result by removing those with final scores equal to 0
    #[Quote: https://stackoverflow.com/questions/4588628/find-indices-of-elements-equal-to-zero-in-a-numpy-array ]
    #Below is a tuple with two arrays as elements
    m_user_score_iarr = np.where( m_user_score_fnl != 0 )

    #890. Form a data frame out of the matrices by indexing, which is faster than data.frame operations
    df_user_score = pd.DataFrame( dat[keyvar].loc[m_user_score_iarr[0]] , columns = [keyvar] )
    df_user_score['ItemName'] = colnames[m_user_score_iarr[1]]
    #df_user_score['ItemRank'] = m_user_score_rnk[m_user_score_iarr].T + 1
    #Introduction of the function [rankdata] indicates that the [ranks] start from 1, hence we remove the operation [+1]
    df_user_score['ItemRank'] = m_user_score_rnk[m_user_score_iarr].T
    df_user_score['Score'] = m_user_score_fnl[m_user_score_iarr].T

    #900.   Output.
    return( df_user_score )
#End userBasedCF

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import time
    import sys
    import pandas as pd
    import os
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import sim_matrix_cosine, userBasedCF
    print(userBasedCF.__doc__)
    omniR = r'D:\R\omniR\ '.strip()

    #100. Import from raw data
    #[Quote: https://docs.python.org/3.7/library/os.path.html#os.path.join ]
    play_data = pd.read_csv( os.path.join( omniR , r'SampleData' , r'sim_10000.txt' ) , sep = '\t' )
    play_data.columns = [ 'user' , 'song_id' , 'plays' ]

    song_data = pd.read_csv( os.path.join( omniR , r'SampleData' , r'sim_song_data.csv' ) , header = 0 )
    song_data = song_data[['song_id','title','artist_name']].drop_duplicates()

    all_data = play_data.groupby( ['user','song_id'] , as_index = False ).sum()
    all_data = all_data.merge( song_data , on = 'song_id' , suffixes = ( '' , '' ) )

    top_1k_songs = all_data.groupby( ['song_id','title','artist_name'] , as_index = False ).sum()
    top_1k_songs = top_1k_songs.nlargest( 1000 , 'plays' )['song_id'].drop_duplicates().reset_index().drop(columns=['index'])

    all_data_top_1k = all_data.merge( top_1k_songs , on = 'song_id' , suffixes = ( '' , '' ) )

    top_1k_wide_src = all_data_top_1k[['user','song_id','plays']].drop_duplicates()
    top_1k_wide = pd.pivot_table( top_1k_wide_src , values = 'plays' , index = ['user'] , columns = ['song_id'] , aggfunc = sum , fill_value = 0 ).reset_index()

    #190. Conduct the calculation
    t0 = time.time()
    recomm = userBasedCF(top_1k_wide,'user',method = 'CosSim',topk_sim = 10,topk_recom = 5)
    print(time.time() - t0)
    # CPU: 55%
    # RAM: 3GB
    # Time elapse: 15.1s (83% of the same function empowered by C++ in R)

    #Check the result
    test_usr = 'c012ec364329bb08cbe3e62fe76db31f8c5d8ec3'

    #Check whether it is the same as what we did for a solius solution
    recomm_usr = recomm.loc[recomm['user'] == test_usr]
    #[Quote: https://stackoverflow.com/questions/49188960/how-to-show-all-of-columns-name-on-pandas-dataframe ]
    #pd.options.display.max_columns = None
    #recomm_usr
    #Below statement will not affect the subsequent scripts in the same session.
    with pd.option_context('display.max_columns', None):
        display(recomm_usr)
#-Notes- -End-
'''
