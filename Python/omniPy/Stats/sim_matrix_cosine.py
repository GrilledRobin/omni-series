#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import sys, warnings

def sim_matrix_cosine( x , y = None , rowvar = False , adj = False ) -> 'Cosine Similarity between each column in a matrix to all others':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Cosine Similarity for each column in the matrix to all other columns                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Difference between this function, [sklearn.metrics.pairwise.cosine_similarity] and R:                                              #
#   |[1] This function is able to be applied to two different matrices, while [sklearn.metrics.pairwise.cosine_similarity] can only be  #
#   |     applied to a single matrix                                                                                                    #
#   |[2] This function is slightly slower than [sklearn.metrics.pairwise.cosine_similarity] on large matrix                             #
#   |[3] This function can calculate based on columns, while [sklearn.metrics.pairwise.cosine_similarity] can only be applied on rows   #
#   |[4] This function can adjust the center of the vectors to 0 (a.k.a. adjusted cosine similarity), while                             #
#   |     [sklearn.metrics.pairwise.cosine_similarity] will not make such adjustment                                                    #
#   |[5] Both functions in Python are slightly faster than R with much less CPU effort (only when Rcpp is applied for calculation based #
#   |     on C++ optmization)                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x,y        :   The input matrices for which the calculation is to be taken upon the columns                                        #
#   |rowvar     :   Whether the requested calculation is applied to each row to all others (Compatible to [numpy])                      #
#   |               [False]<Default> Calculate the distance between each column in [x] to that in [y]                                   #
#   |               [True]           Calculate the distance between each row in [x] to that in [y]                                      #
#   |adj        :   Whether to adjust the input matrix by deducting the means of the respective columns before calculation              #
#   |                Check the blog for reason: https://blog.csdn.net/ifnoelse/article/details/7766123                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[matrix]   :   The [K*M] matrix, where [K] is equal to the number of columns of [x], while [M] is the number of columns of [y]     #
#   |               Each [k,m] represents the similarity of [k]th column in [x] to [m]th column in [y]                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200606        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
    if adj: x -= f_mean(x, axis = 0)

    #300.   Further handle [y] if it is provided.
    if y is None: y = x
    elif y is x: pass
    else:
        #050.   Transpose [x] if it is requested for calculation based on [row]s.
        if isinstance( y , ( np.ndarray ) ): y = np.asmatrix(y)
        if rowvar: y = y.T

        #100.   Reshape [y].
        y = y.astype(np.float64)
        if adj: y -= f_mean(y, axis = 0)

    #500.   Calculate the Norms by columns of both [x] and [y].
    norm_x = np.sqrt( np.asmatrix( np.sum( np.square(x) , axis = 0 ) ) )
    if y is x: norm_y = norm_x
    else: norm_y = np.sqrt( np.asmatrix( np.sum( np.square(y) , axis = 0 ) ) )

    #900.   Output.
    return( np.dot(x.T, y) / np.dot( norm_x.T , norm_y ) )
#End sim_matrix_cosine

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    from sklearn.metrics.pairwise import cosine_similarity
    import numpy as np
    import time
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import sim_matrix_cosine
    print(sim_matrix_cosine.__doc__)

    #[AMD FX-6300 6Core 3.5G]

    #100.   Create the testing dataset.
    x1 = np.random.randn(10,5)
    y1 = np.random.randn(10,5)
    isinstance(x1,( np.ndarray ))

    #200.   Calculate the covariance matrix of a single matrix.
    t0 = time.time()
    s1 = sim_matrix_cosine(x1)
    print(time.time() - t0)

    t0 = time.time()
    s2 = cosine_similarity(x1.T)
    print(time.time() - t0)

    np.allclose(s1,s2)

    #500.   Create the large matrices.
    x2 = np.random.randn(100000,1000)
    y2 = np.random.randn(100000,500)

    #500. Calculation upon large matrix
    t0 = time.time()
    s3 = sim_matrix_cosine(x2)
    print(time.time() - t0)
    #5.31s

    t0 = time.time()
    s4 = cosine_similarity(x2.T)
    print(time.time() - t0)
    #5.20s

    np.allclose(s3,s4)

    #600. Calculation upon two different matrices.
    t0 = time.time()
    s_xy1 = sim_matrix_cosine(x2, y2)
    print(time.time() - t0)
    #4.98s

    #700. Test real case
    #701. Parameters
    import pandas as pd
    import os
    omniR = r'D:\R\omniR\ '.strip()
    keyvar = 'user'
    topk_sim = 5

    #705. Import from raw data
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

    colnames = top_1k_wide.head(1).drop( keyvar , axis = 1 ).columns.values
    ratings = np.asmatrix( top_1k_wide.drop( keyvar , axis = 1 ) )

    #709. Conduct the calculation
    t0 = time.time()
    ratings_sim = sim_matrix_cosine(ratings)
    print(time.time() - t0)
    # Time elapse: 3.3s (60% of the same function empowered by C++ in R)

    #Check the result
    forgot_about_dre = 'SOBOAFP12A8C131F36'

    #Retrieve the top 5 similar songs for each one of the songs
    #710. Ensure the self-similarity to be placed at last during the ranking
    item_sim_mod = ratings_sim - np.diag( np.diag(ratings_sim) + np.amax(ratings_sim) + 1 )

    #720. Rank the similarity matrix by row in descending order of similarity values
    item_sim_rnk = ( item_sim_mod * (-1) ).argsort().argsort()

    #730. Flag those elements which rank lower than [topk_sim + 1], while set others as 0 for exclusion
    item_sim_flg = (item_sim_rnk < topk_sim)

    #740. Create the final [Item] similarity matrix by adding all requested filtrations
    item_sim_fnl = np.multiply( ratings_sim , item_sim_flg )

    #750. Flag those elements to be extracted from the input dataset
    item_sim_iarr = np.where( item_sim_fnl != 0 )

    #790. Create a data.frame to hold the top 5 similar songs to each song in the input data
    ratings_sim_top5 = pd.DataFrame( colnames[item_sim_iarr[0]] , columns = ['song_id'] )
    ratings_sim_top5['ItemName'] = colnames[item_sim_iarr[1]]
    ratings_sim_top5['ItemRank'] = item_sim_rnk[item_sim_iarr].T + 1
    ratings_sim_top5['Score'] = item_sim_fnl[item_sim_iarr].T

    #Check whether it is the same as what we did for a solius solution
    ratings_sim_top5.loc[ratings_sim_top5['song_id'] == forgot_about_dre]
#-Notes- -End-
'''
