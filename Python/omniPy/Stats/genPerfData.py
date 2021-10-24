#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001.   Import necessary functions for processing.
import datetime as dt
import collections as clt
from itertools import permutations
import numpy as np
from scipy.special import comb, perm
import pandas as pd
from omniPy.Dates import *

#100.   Definition of the class.
class genPerfData( UserCalendar ):
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This class is intended to create the random dataset(s) that resemble the customer statistical KPIs for simulations in other        #
#   | processes.                                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods.                                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Internal methods.                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |101.   __init__                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |The default initialization method.                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   Parameters.                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |countrycode    :   2-character country code to identify the user-defined shifted days.                                         #
#   |   |                   [Type]  [str]                                                                                               #
#   |   |                   [Default] [CN]                                                                                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |900.   Return Values.                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |200.   Object creation.                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |201.   _weekdayname                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |900.   Return Values.                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[list]    :   List of all weekday names under different settings (such as different languages)                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class.                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |       Property Name         |                             Value Examples and Property Description                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | calendardata                | Return the dataset created at initialization of the class for external reference.           #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |600.   Writeable properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |601.   fmtdatetostr                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Writeable property to set or retrieve the internal format to transform the timestamp into string                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   Parameters.                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |strfmt :   The format to display the timestamp                                                                                 #
#   |   |           [Type]  [str]                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |900.   Return Values.                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |strfmt :   The format to display the timestamp                                                                                 #
#   |   |           [Type]  [str]                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |602.   _obsdates                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Writeable property to set or retrieve the DataFrame of Observation Dates, stored as Timestamps, for [self.object] to calculate #
#   |   | various attributes, such as Previous Work Days or Next 5 Trade Days.                                                          #
#   |   |NOTE: The output DataFrame will be sorted in ascending order.                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   Parameters.                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |indate :   The date or list of dates to be observed in current [self.object]                                                   #
#   |   |           [Type]  [datetime.datetime], [pandas.Timestamp] or [list[datetime.datetime] or [pandas.Timestamp]]                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |900.   Return Values.                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |__obsdatedf :   The DataFrame of timestamps to be observed in current [self.object]                                            #
#   |   |               [Type] [pandas.DataFrame] object                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Field specifications for the dataset. (For field types please use [df.info()] for retrieval)                        #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |          Field Name         |                                 Field Description                                           #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | DT_DATE                     | Observation Date in the type of [Timestamp].                                                #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |603.   _datespan                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Writeable property to set or retrieve the span to extend the user requested period of time.                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   Parameters.                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |tdelta :   The timedelta to extend the period                                                                                  #
#   |   |           [Type]  [datetime.timedelta]                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |900.   Return Values.                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |__datespan :   The timedelta to extend the period                                                                              #
#   |   |               [Type]  [datetime.timedelta]                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |604.   _countrycode                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Writeable property to set or retrieve the 2-character country code to determine the shift days in different regions.           #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   Parameters.                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |countrycode    :   The country code to determine the shift days in current region                                              #
#   |   |                   [Type]  [str]                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |900.   Return Values.                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |__countrycode  :   The country code to determine the shift days in current region                                              #
#   |   |                   [Type]  [str]                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20180429        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |100.   Internal Modules.                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |datetime                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   External Modules.                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |pandas                                                                                                                     #
#   |   |   |omniPy.Dates                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |200.   Dependent classes                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   External classes.                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |ShiftDateList                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Constructor
    def __init__( self , datebgn : dt.datetime , dateend : dt.datetime , countrycode : str = "CN" ):
        #010.   Parameters.
        self.__datebgn : dt.datetime = datebgn
        self.__dateend : dt.datetime = dateend
        super(genPerfData,self).__init__( self.__datebgn , self.__dateend , countrycode )
        self.__usrclndr : pd.DataFrame = self._crcalendar( self.__datebgn , self.__dateend , self._countrycode )
        self.__curdate : pd.Timestamp = self.__usrclndr.at[self.__usrclndr.index.min(),'DT_DATE']

        #100.   Demographics.
        self.__nation : list = [ ['CN',0.78] , ['US',0.03] , ['SG',0.12] , ['MY',0.05] , ['JP',0.02] ]
        self.__resi : list = [ [u'上海',0.427] , [u'北京',0.332] , [u'杭州',0.058] , [u'天津',0.125] , [u'重庆',0.014] , [u'成都',0.007] , [u'广州',0.009] , [u'深圳',0.001] , [u'厦门',0.027] ]
        self.__prof : list = [ [u'金融',0.189] , [u'快消',0.106] , [u'医疗',0.101] , [u'教育',0.116] , [u'交通',0.006] , [u'工程',0.054] , [u'电信',0.085] , [u'电商',0.229] , [u'媒体',0.114] ]
        self.__gender : list = [ 'F' , 'M' ]
        self.__acq : list = [ ['WM Sales',0.76] , ['Walk In',0.06] , ['MGM',0.02] , ['Credit Card',0.09] , ['Mortgage',0.07] ]
        self.__consume : list = [ [u'美食',0.251] , [u'电影',0.185] , [u'游戏',0.101] , [u'旅游',0.219] , [u'健身',0.014] , [u'网购',0.221] , [u'线下购物',0.009] ]
        self.__age : list = [ ['10. 18~24',0.14] , ['20. 25~33',0.37] , ['40. 34~42',0.26] , ['60. 43~55',0.19] , ['80. 56~65',0.04] , ['90. 66~80',0.00] ]

        #200.   Product initialization.
        #210.   Prepare the original lists.
        self.__ccy : list = [ ['CNY',0.62] , ['USD',0.12] , ['SGD',0.10] , ['HKD',0.05] , ['AUD',0.03] , ['EUR',0.02] , ['CAD',0.02] , ['GBP',0.02] , ['JPY',0.02] ]
        #The On-BS products should take up 65% +/- 5% of the entire AUM.
        self.__p_l_onbs : list = [ ['CASA-LCY',0.206] , ['CASA-FCY',0.048] , ['TD-LCY',0.121] , ['TD-FCY',0.134] , ['ASP',0.093] , ['RSP',0.041] , ['PCI',0.003] ]
        self.__p_l_onbs_dict : dict = { i[0]:i[-1] for i in self.__p_l_onbs }
        #Core products within QD should take up 75% +/- 5%.
        self.__p_l_offbs : list = [ ['QD-Core',0.146] , ['QD-Tatical1',0.033] , ['QD-Tactical2',0.019] , ['LUT',0.011] , ['BOND',0.003] , ['MMF',0.142] ]
        self.__p_l_offbs_dict : dict = { i[0]:i[-1] for i in self.__p_l_offbs }
        #The sum of probabilities of all AUM products should be 100%
        self.__p_aum : list = self.__p_l_onbs + self.__p_l_offbs
        self.__p_a : list = [ ['House Loan',0.694] , ['Credit Card',0.141] , ['PIL',0.132] , ['Car Loan',0.033] ]
        self.__p_d : list = [ ['Banca',0.87] , ['FX',0.13] ]
        #print( sum([__prof[i][1] for i in range(len(__prof))]) )

        #220.   Tenor for specific Products.
        self.__tenors : list = [
                                    [ 'TD' , [ [ 30 , 0.125 ] , [ 90 , 0.125 ] , [ 180 , 0.187 ] , [ 365 , 0.188 ] , [ 390 , 0.062 ] , [ 540 , 0.063 ] , [ 730 , 0.188 ] , [ 1825 , 0.062 ] ] ]
                                    ,[ 'PCI' , [ [ 7 , 0.19 ] , [ 14 , 0.42 ] , [ 30 , 0.39 ] ] ]
                                    ,[ 'House Loan' , [ [ 20*365 , 0.13 ] , [ 25*365 , 0.11 ] , [ 30*365 , 0.20 ] , [ 35*365 , 0.11 ] , [ 40*365 , 0.45 ] ] ]
                                    ,[ 'PIL' , [ [ 180 , 0.27 ] , [ 270 , 0.18 ] , [ 365 , 0.55 ] ] ]
                                ]

        #250.   Determine the proportion of each product in the overall Product Pool.
        #251.   We consider the Balance Sheet of the Bank is healthy at the beginning of the period, for the A/D Ratio is maintained at 85%~95%.
        ad_ratio : float = 0.85 + 0.1 * np.random.random()
        __pp_a : list = [ [ i[0] , i[-1] * sum( [ j[-1] for j in self.__p_l_onbs ] ) * ad_ratio ] for i in self.__p_a ]

        #252.   We presume the Volumes of Distribution Products rival 25%~30% of Off-Balance-Sheet Product Balance.
        dis_ratio : float = 0.25 + 0.05 * np.random.random()
        __pp_d : list = [ [ i[0] , i[-1] * sum( [ j[-1] for j in self.__p_l_offbs ] ) * dis_ratio ] for i in self.__p_d ]

        #253.   Scale the proportions of the Products.
        tmp_all : float = sum([i[-1] for i in self.__p_l_onbs]) + sum([i[-1] for i in self.__p_l_offbs]) + sum([i[-1] for i in __pp_a]) + sum([i[-1] for i in __pp_d])
        self.__pp_l_onbs : list = [ [ i[0] , i[-1]/tmp_all ] for i in self.__p_l_onbs ]
        self.__pp_l_offbs : list = [ [ i[0] , i[-1]/tmp_all ] for i in self.__p_l_offbs ]
        self.__pp_a : list = [ [ i[0] , i[-1]/tmp_all ] for i in __pp_a ]
        self.__pp_d : list = [ [ i[0] , i[-1]/tmp_all ] for i in __pp_d ]

        #259.   Summarize by different angles.
        self.__product : list = [ [ 'Liability' , self.__pp_l_onbs + self.__pp_l_offbs ] , [ 'Asset' , self.__pp_a ] , [ 'Distribution' , self.__pp_d ] ]
        self.__balsheet : list = [ [ 'On' , self.__pp_l_onbs + self.__pp_a ] , [ 'Off' , self.__pp_l_offbs + self.__pp_d ] ]
        #print( sum([ j[-1] for i in self.__product for j in i[-1] ]) )
        #print( np.random.choice([ j[-1] for i in self.__balsheet for j in i[-1] ],1)[0] )

        #290.   Create the Product mapping tables for current simulation.
        self.__metaprod_all : pd.DataFrame = self.__metaprod

        #300.   Initialize the data frames.
        #301.   Account base.
        self.__allaccts : pd.DataFrame = pd.DataFrame( columns = [ 'NC_CIFNO' , 'C_Prod_Code' , 'C_CCY' , 'NC_ACCTNO' ] , dtype = str )
        self.__allaccts['K_ACCT'] = 0

        #800.   Counters.
        self.__max_k_cif : int = 0
        #Full Account List

        #900.   Purge.
        ad_ratio , dis_ratio , tmp_all , __pp_a , __pp_d = None , None , None , None , None
    #End of [__init__]

    #005.   Define the attributes that can be accessed from inside.
    __slots__ = (
        '__datebgn' , '__dateend' , '__countrycode' , '__curdate' , '__usrclndr'
        , '__nation' , '__resi' , '__prof' , '__gender' , '__acq' , '__consume' , '__age'
        , '__p_l_onbs' , '__p_l_offbs' , '__p_aum' , '__p_a' , '__p_d' , '__product' , '__balsheet' , '__ccy' , '__p_l_onbs_dict' , '__p_l_offbs_dict' , '__tenors'
        , '__pp_l_onbs' , '__pp_l_offbs' , '__pp_a' , '__pp_d'
        , '__metaprod_all' , '__metaprod_SPmapping' , '__metaprod_QDmapping' , '__metaprod_LUTmapping' , '__metaprod_MMFmapping' , '__metaprod_Bondmapping' , '__metaprod_Bncmapping'
        , '__metaprod_CASAmapping' , '__metaprod_TDmapping' , '__metaprod_PCImapping' , '__metaprod_FXmapping' , '__metaprod_MTGmapping' , '__metaprod_CCmapping' , '__metaprod_PILmapping' , '__metaprod_CLmapping'
        , '__max_k_cif' , '__allaccts'
        , 'chkdf'
    )

    #010.   Define the document when printing an object instantiated from current class.
    def __str__( self ):
        return( 'Random Customer Performance Data Generator for [{0}]'.format( self.__countrycode ) )
    #End of [__str__]

    #011.   Define the representation of the object.
    __repr__ = __str__

    #100.   Create datasets.
    #101.   Create the Example of Customer Holdings.
    def genExampleDat( self , ncust : int ):
        #000.   Info.
        """
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #300.   Update log.                                                                                                                     #
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #   | Date |    20180429        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
    #   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
    #   | Log  |Version 1.                                                                                                                  #
    #   |______|____________________________________________________________________________________________________________________________#
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #500.   Dependent Facilities.                                                                                                           #
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #   |300.   Dependent functions                                                                                                         #
    #   |-----------------------------------------------------------------------------------------------------------------------------------#
    #   |   |100.   Properties.                                                                                                             #
    #   |   |-------------------------------------------------------------------------------------------------------------------------------#
    #   |   |-------------------------------------------------------------------------------------------------------------------------------#
    #   |   |200.   Methods.                                                                                                                #
    #   |   |-------------------------------------------------------------------------------------------------------------------------------#
    #   |   |   |self.__crCustList                                                                                                          #
    #   |   |   |self.__crCustProdHolding                                                                                                   #
    #   |   |   |self.__crDemoInf                                                                                                           #
    #   |-----------------------------------------------------------------------------------------------------------------------------------#
    #---------------------------------------------------------------------------------------------------------------------------------------#
        """

        #010.   Local Parameters.
        date_samp : pd.Timestamp = np.random.choice( self.__usrclndr['DT_DATE'].tolist() , 1 )[0]
        n_cust : int = int( ncust * ( 0.8 + 0.4 * np.random.random() ) )

        #100.   Create sub-datasets
        date_list : list = [ date_samp for i in range(n_cust) ]
        cus_list : list = self.__crCustList( date_samp , n_cust )
        lst_out : list = list(map(list,zip( date_list , cus_list )))
        cus_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'DT_TABLE' , 'NC_CIFNO' ] )
        cus_base['DT_RelOpen'] = np.random.choice( pd.date_range( start = ( date_samp - dt.timedelta(days=3650) ).strftime("%m/%d/%Y") , end = date_samp.strftime("%m/%d/%Y") ).tolist() , n_cust ).tolist()
        cus_inf : pd.DataFrame = self.__crDemoInf( cus_list )
        cus_bal : pd.DataFrame = self.__crCustProdHolding( cus_list , newcust = False )

        #500.   Join all datasets based on the customer list.
        ds_out = pd.merge( cus_base , cus_inf , how = 'left' , on = 'NC_CIFNO' , suffixes = ( '' , '' ) ).fillna('')
        ds_out = pd.merge( ds_out , cus_bal , how = 'left' , on = 'NC_CIFNO' , suffixes = ( '' , '' ) ).fillna(0)

        #900.   Purge.
        date_samp , n_cust , date_list , cus_list , lst_out , cus_base , cus_inf , cus_bal = None , None , None , None , None , None , None , None

        #990.   Return
        return( ds_out )
    #End of [genExampleDat]

    #102.   Create the Example of Customer transaction.
    def genExampleTxn( self , ncust : int ):
        #000.   Info.
        """
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #300.   Update log.                                                                                                                     #
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #   | Date |    20180506        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
    #   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
    #   | Log  |Version 1.                                                                                                                  #
    #   |______|____________________________________________________________________________________________________________________________#
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #500.   Dependent Facilities.                                                                                                           #
    #---------------------------------------------------------------------------------------------------------------------------------------#
    #   |300.   Dependent functions                                                                                                         #
    #   |-----------------------------------------------------------------------------------------------------------------------------------#
    #   |   |100.   Properties.                                                                                                             #
    #   |   |-------------------------------------------------------------------------------------------------------------------------------#
    #   |   |-------------------------------------------------------------------------------------------------------------------------------#
    #   |   |200.   Methods.                                                                                                                #
    #   |   |-------------------------------------------------------------------------------------------------------------------------------#
    #   |   |   |self.genExampleDat                                                                                                         #
    #   |   |   |self.__txn_OpenEnd                                                                                                         #
    #   |-----------------------------------------------------------------------------------------------------------------------------------#
    #---------------------------------------------------------------------------------------------------------------------------------------#
        """

        #010.   Local Parameters.
        date_samp : pd.Timestamp = np.random.choice( self.__usrclndr['DT_DATE'].tolist() , 1 )[0]
        casa : pd.DataFrame = self.genExampleDat( ncust )[[ 'NC_CIFNO' , 'A_CASA_LCY' ]]

        #990.   Return
        return( self.__txn_OpenEnd( casa , indate = date_samp , colname = 'A_CASA_LCY' , prodname = 'CASA-LCY' , currency = 'CNY' , commonfundin = 10000 , f_fundin = 0.5125 ) )
    #End of [genExampleTxn]

    #500.   Methods to simulate customer transactions.
    #510.   Function to simulate the transactions of Open-ended products.
    def __txn_OpenEnd( self , fromholdings : pd.DataFrame , **kw ) -> 'Simulate the customer transactions on the open-ended products':
        #010.   Parameters.
        #[kw] must contain these arguments: { 'indate':pd.Timestamp , 'colname':str , 'prodname':str , 'currency':str , 'commonfundin':float , 'f_fundin':float }
        ncust : int = len(fromholdings)
        fundin : np.ndarray = np.random.noncentral_chisquare( 4 , 1 , ncust ) * kw['commonfundin']

        #100.   Define the pattern of transaction behavior.
        def ptn_txn( row ):
            if row['f_fundin']:
                #If the customer chooses to fund-in, he or she inputs an amount that follows non-central chisquare distribution with a common value of 10000.
                return( np.random.choice( fundin.tolist() , 1 )[0] )
            else:
                #If the customer decides to fund-out, he or she withdraws a certain proportion of his or her holding, which follows a uniform distribution.
                return( np.random.random() * row[kw['colname']] * (-1) )

        #200.   Create the output dataset.
        tmp_Out : pd.DataFrame = fromholdings
        tmp_Out['DT_TABLE'] = kw['indate']
        tmp_Out['C_Prod_Name'] = kw['prodname']
        tmp_Out['C_CCY'] = kw['currency']
        tmp_Out['f_fundin'] = np.random.choice( [ False , True ] , ncust , p = [ 1 - kw['f_fundin'] , kw['f_fundin'] ] ).tolist()
        tmp_Out['A_TXN'] = tmp_Out.apply( ptn_txn , axis = 1 )
        Rst_Out : pd.DataFrame = tmp_Out[[ 'DT_TABLE' , 'NC_CIFNO' , 'C_Prod_Name' , 'C_CCY' , 'A_TXN' ]]

        #900.   Purge.
        ncust , fundin , tmp_Out = None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__txn_OpenEnd]

    #200.   Methods to simulate the daily activities.
    #201.   Accout Opening.
    def __cus_ACOpen( self , custlist : list , nprod : list , dfprod : pd.DataFrame , **kw ) -> 'Simulate the Account Opening of the customers within the provided list.':
        #010.   Local Parameters.
        lst_out : clt.deque = clt.deque([])

        #100.   Re-shape the Product Class list as all customers should open an account of 'CASA-LCY'.
        __product : list = [ j for i in self.__product for j in i[-1] if j[0] != 'CASA-LCY' ]
        __product = [ [ i[0] , i[-1] / sum( [ j[-1] for j in __product ] ) ] for i in __product ]
        custprod : list = [ np.random.choice( [ i[0] for i in __product ] , nprod[k] - 1 , [ i[-1] for i in __product ] ).tolist() for k in range(len(custlist)) ]

        #200.   Identify Product Codes for each customer.
        #210.   Each customer should have 'CASA-LCY' Product.
        #We use Cartesian Join to merge these data frames to indicate that each customer should have only one CASA-CNY account.
        Rst_Out : pd.DataFrame = pd.merge(
                                    pd.DataFrame( data = custlist , columns = ['NC_CIFNO'] ).assign( key = 0 )
                                    , dfprod[ dfprod['C_Prod_Name'] == 'Saving-CNY' ].assign( key = 0 )
                                    , suffixes = ( '' , '' )
                                ).drop( 'key' , axis = 1 )

        #215.   Define the function to filter the Products available for account opening.
        def prodfilter( row : pd.DataFrame ):
            if row['DT_Value'] == self.__curdate:
                return( True )
            elif pd.isnull(row['DT_Value']) & ( row['DT_Begin'] <= self.__curdate ) & ( row['DT_End'] >= self.__curdate ):
                return( True )
            else:
                return( False )

        #220.   Define the function to correct the Tenor.
        def settenor( row : pd.DataFrame ):
            if row['C_Prod_Name'].split('-')[0] in [ i[0] for i in self.__tenors ]:
                rlst : list = self.__tenors[ [ i[0] for i in self.__tenors ].index( row['C_Prod_Name'].split('-')[0] ) ][-1]
                return( np.random.choice( [ i[0] for i in rlst ] , 1 , [ i[-1] for i in rlst ] )[0] )
            else:
                return( row['K_Tenor_Day'] )

        #230.   Define the function to create the Account Number.
        def crAcct( row : pd.DataFrame ):
            if row['DT_Issue']:
                if row['K_ACCT'] == 0:
                    return( row['NC_CIFNO'] + '-' + row['C_Prod_Code'] + '-' + '{0:{fill}{width}}'.format( 1 , fill = 0 , width = 3 ) )
                else:
                    return( '' )
            else:
                return( row['NC_CIFNO'] + '-' + row['C_Prod_Code'] + '-' + '{0:{fill}{width}}'.format( row['K_ACCT'] + 1 , fill = 0 , width = 3 ) )

        #250.   There could be 1 or 2 accounts opened for each Product Class for each customer EXCEPT 'CASA-LCY'.
        for idx , cust in enumerate(custlist):
            if custprod[idx]:
                prodcode : pd.DataFrame = dfprod[ dfprod['C_Cat_Rpt'].apply( lambda x : True if x in custprod[idx] else False ) ]
                #self.chkdf = custprod[idx]
                mask = prodcode.apply( prodfilter , axis = 1 )
                prodcode = prodcode[ mask ]

                if len(prodcode):
                    for prod in custprod[idx]:
                        prodforacct : pd.DataFrame = prodcode[ prodcode['C_Cat_Rpt'] == prod ]
                        if len(prodforacct):
                            #100.   Retrieve the products by weighted random selection.
                            acctpre : pd.DataFrame = prodforacct.sample( np.random.randint( low = 1 , high = min( 2 , len(__product) ) ) , weights = 'R_Prob_RptCust' )

                            #200.   Add the CIFNO.
                            acctpre['NC_CIFNO'] = cust

                            #300.   Correct the Tenor for specific Products.
                            acctpre['K_Tenor_Day'] = acctpre.apply( settenor , axis = 1 )

                            #900.   Append current customer to the whole DataFrame.
                            Rst_Out = pd.concat( [ Rst_Out , acctpre ] , ignore_index = True )
                        #End If
                    #End For
                #End If
            #End If
        #End For

        #500.   Account Opening.
        #510.   Retrieve the existing accounts of these customers, including those closed ones, for extension of sequence numbers.
        acct_merge : pd.DataFrame = pd.merge(
                                        Rst_Out
                                        , self.__allaccts
                                        , how = 'left'
                                        , on = [ 'NC_CIFNO' , 'C_Prod_Code' , 'C_CCY' ]
                                        , suffixes = ( '' , '_a' )
                                        , indicator = 'Has_Acct'
                                    ).fillna( value = { 'NC_ACCTNO':'' , 'K_ACCT':0 } )

        #520.   Identify the maximum sequence number of any Product Code for the same customer.
        acct_exist : pd.DataFrame = acct_merge.groupby( [ 'NC_CIFNO' , 'C_Prod_Code' , 'C_CCY' , 'DT_Issue' ] , as_index = False )['K_ACCT'].max()

        #550.   Create Account Numbers.
        acct_exist['NC_ACCTNO'] = acct_exist.apply( crAcct , axis = 1 )
        ds_out : pd.DataFrame = acct_exist[ pd.notnull( acct_exist['NC_ACCTNO'] ) ][ [ 'NC_CIFNO' , 'C_Prod_Code' , 'C_CCY' , 'NC_ACCTNO' ] ]
        ds_out['K_ACCT'] = ds_out['NC_ACCTNO'].apply( lambda x : int(x.split('-')[-1]) )

        #700.   Update the full Account List.
        self.__allaccts = pd.concat( [ self.__allaccts , ds_out ] , ignore_index = True )

        #900.   Purge.
        lst_out , __product , prodcode , mask , prodforacct , acctpre , acct_merge , acct_exist = None , None , None , None , None , None , None , None

        #990.   Return
        return( ds_out.drop( 'K_ACCT' , axis = 1 ) )
    #End of [__cus_ACOpen]

    #600.   Utilities.
    #601.   Function to create the CIFNO for the provided customers.
    def __crCustList( self , ncust : int ) -> 'Create CIFNO for the customers as provided':
        lst_out : list = [ '{0:{fill}{width}}'.format( self.__max_k_cif + i + 1 , fill = 0 , width = 7 ) for i in range(ncust) ]
        self.__max_k_cif += ncust
        return( lst_out )
    #End of [__crCustList]

    #606.   Function to create the Product Holdings dataset by the total Fund Amount and the Account Dataset.
    def __crAcctBalance( self , AUM : float , acct : pd.DataFrame ) -> 'Create the dataset of customer Account Balance':
        #010.   Local Parameters.
        lst_pre : list = []
        acct_main : clt.deque = clt.deque([])
        acct_dist : clt.deque = clt.deque([])
        #Retrieve the identifier of whether the Product belongs to Main Banking Business or Distribution Business, as well as the corresponding probability of fund size for each customer.
        l_acctpre : pd.DataFrame = pd.merge( acct , self.__metaprod_all[ [ 'C_Prod_Code' , 'C_Family_Fin' , 'R_Prob_RptCust' ] ] , how = 'left' , on = 'C_Prod_Code' , suffixes = ( '' , '' ) )
        l_acctpre['C_Family_Acct'] = l_acctpre['C_Family_Fin'].apply( lambda x : 'Distribution' if x == 'Distribution' else 'MainBiz' )

        #030.   Standardize the possibilities of Products of each customer, making the sum of them equal to 1 for choice selection.
        l_acctprop : pd.DataFrame = l_acctpre.groupby( ['NC_CIFNO','C_Family_Acct'] , as_index = False )['R_Prob_RptCust'].sum()
        l_acct : pd.DataFrame = pd.merge( l_acctpre , l_acctprop , how = 'left' , on = ['NC_CIFNO','C_Family_Acct'] , suffixes = ( '' , '_s' ) )
        l_acct['R_Prob_Final'] = l_acct.apply( lambda x : x['R_Prob_RptCust'] / x['R_Prob_RptCust_s'] , axis = 1 )

        #050.   Create the customer list.
        cust_all : list = pd.unique( l_acct['NC_CIFNO'] ).tolist()
        np.random.shuffle(cust_all)

        #100.   Prepare Account Lists for all customers.
        for cus in cust_all:
            ds_cus : pd.DataFrame = l_acct[ l_acct['NC_CIFNO'] == cus ]
            #Accounts for Main Banking Business.
            ds_tmp : pd.DataFrame = ds_cus[ ds_cus['C_Family_Acct'] != 'Distribution' ]
            if len(ds_tmp):
                lst_tmp : list = [ [ ds_tmp.at[ i , 'NC_ACCTNO' ] , ds_tmp.at[ i , 'R_Prob_Final' ] ] for i in ds_tmp.index.tolist() ]
                acct_main.append( lst_tmp )
            #Accounts for Disbribution Business.
            ds_tmp : pd.DataFrame = ds_cus[ ds_cus['C_Family_Acct'] == 'Distribution' ]
            if len(ds_tmp):
                lst_tmp : list = [ [ ds_tmp.at[ i , 'NC_ACCTNO' ] , ds_tmp.at[ i , 'R_Prob_Final' ] ] for i in ds_tmp.index.tolist() ]
                acct_dist.append( lst_tmp )
        #End For

        #400.   Split the AUM by Accounts for Main Banking Business.
        if acct_main:
            #100.   AUM of the customers follows noncentral chi-square distribution.
            prop_aum_pre : np.ndarray = np.random.noncentral_chisquare( 3 , 1 , len(acct_main) )
            prop_aum : np.ndarray = prop_aum_pre * AUM / sum(prop_aum_pre)
            cust_aum : list = prop_aum.tolist()

            #500.   Split AUM by choices of each customer.
            bal_main : list = self.__splitAmtByChoice( cust_aum , acct_main )
            lst_pre.extend(bal_main)
        #End If

        #500.   Split the Volume by Accounts for Distribution Business.
        if acct_dist:
            #100.   Volume of the customers follows noncentral chi-square distribution, and the lumpsum takes up around 1/4 of the AUM.
            prop_aum_pre : np.ndarray = np.random.noncentral_chisquare( 3 , 1 , len(acct_dist) )
            prop_aum : np.ndarray = prop_aum_pre * AUM * ( 0.25 + 0.05 * np.random.random() ) / sum(prop_aum_pre)
            cust_aum : list = prop_aum.tolist()

            #500.   Split AUM by choices of each customer.
            bal_dist : list = self.__splitAmtByChoice( cust_aum , acct_dist )
            lst_pre.extend(bal_dist)
        #End If

        #600.   Retrieve the Account list and the Balance list separately.
        out_acct : list = [ j[0] for i in lst_pre for j in i ]
        out_bal : list = [ j[-1] for i in lst_pre for j in i ]

        #800.   Create the dataset of Account Balance.
        lst_out : list = list(map(list,zip( out_acct , out_bal )))
        ds_out : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'NC_ACCTNO' , 'A_Balance' ] )

        #900.   Purge.
        lst_pre , lst_out , l_acctpre , l_acctprop , l_acct , cust_all , ds_tmp , acct_main , acct_dist , bal_main , bal_dist = None , None , None , None , None , None , None , None , None , None , None
        prop_aum_pre , prop_aum , cust_aum , ds_cus , lst_tmp = None , None , None , None , None

        #990.   Return
        return( ds_out )
    #End of [__crAcctBalance]

    #610.   Function to split the amount of each element in the provided list into several choices, in terms of their respective probabilities
    def __splitAmtByChoice( self , listamt : list , listchoice : list ) -> 'Split the amount of each element in the provided list into several choices':
        #010.   Parameters.
        if not listamt:
            raise ValueError( 'The input list of amounts should contain at least one observation!' )
        if len(listamt) != len(listchoice):
            raise ValueError( 'The input list of amounts should have the same number of elements as the input list of choices!' )
        Out_Rst : clt.deque = clt.deque([])
        l_markers : np.ndarray
        tmpmarkers : list
        split_base : list
        split_sub : list
        split_amt : list
        feed_amt : list

        #500.   Split the input amount.
        for idx , amt in enumerate(listamt):
            #010.   Sort the list of choices by their probabilities to take up the proportion in the AUM.
            #We have to sort the probabilities by descending order to compromise the feature of [numpy.random.choice].
            c_list : list = sorted( [ i[::-1] for i in listchoice[idx] ] , reverse = True )

            #050.   Assign the amount to the choice if there is only one, and skip to the next element.
            if len(c_list) == 1:
                Out_Rst.append( [ [ c_list[0][-1] , amt ] ] )
                continue

            #100.   Create [n-1] markers to split the amount, where [n] represents the number of choices.
            l_markers = np.random.random(size=len(c_list)-1) * amt
            tmpmarkers = sorted(list(l_markers))

            #200.   Calculate the [n] random numbers which can sum up to the same as input number based on the [n-1] markers.
            split_base = tmpmarkers + [amt]
            split_sub = [0] + tmpmarkers
            split_amt = sorted( list(map( lambda x,y:x-y , split_base , split_sub )) , reverse = True )

            #500.   Feed the numbers into the positions of choices by their descending probabilities.
            #We presume that people would put their larger proportion of funds into the most poppular products.
            #We use option [replace = False] to ensure every number is selected from the source.
            feed_amt = np.random.choice( split_amt , len(c_list) , p = [ i[0] for i in c_list ], replace = False ).tolist()

            #800.   Append current row of amounts to the output.
            Out_Rst.append( [ [ c_list[i][-1] , feed_amt[i] ] for i in range(len(c_list)) ] )
        #End For

        #900.   Purge.
        c_list , l_markers , tmpmarkers , split_base , split_sub , split_amt , feed_amt = None , None , None , None , None , None , None

        #990.   Return
        #The result is of the same shape as [listchoice], replacing the possibilities with the split values.
        return( list(Out_Rst) )
    #End of [__splitAmtByChoice]

    #620.   Function to split the amount of each element in the provided list into [K] proportions, in terms of uniform distribution.
    #The sum of [rows] in the output result is the same as the one at the same position in the input list.
    def __splitAmtIntoK( self , listamt : list , k : int ) -> 'Split the amount of each element in the provided list into [K] proportions':
        #010.   Parameters.
        if not listamt:
            raise ValueError( 'The input list of amounts should contain at least one observation!' )
        Out_Rst : list
        tmp_Rst : clt.deque = clt.deque([])
        l_markers : np.ndarray
        tmpmarkers : list
        split_base : list
        split_sub : list
        split_amt : list

        #500.   Split the input amount.
        for amt in listamt:
            #100.   Create [n-1] markers to split the amount, where [n] represents the number of choices.
            l_markers = np.random.random(size=k-1) * amt
            tmpmarkers = sorted(list(l_markers))

            #200.   Calculate the [n] random numbers which can sum up to the same as input number based on the [n-1] markers.
            split_base = tmpmarkers + [amt]
            split_sub = [0] + tmpmarkers
            split_amt = list(map( lambda x,y:x-y , split_base , split_sub ))

            #800.   Append current row of amounts to the output.
            tmp_Rst.append( split_amt )

        #600.   Exchange the [row] and [column] of the result, then add the descriptions in the choice list to all new rows.
        if len(listamt) == 1:
            Out_Rst = tmp_Rst[0]
        else:
            Out_Rst = list(map(list,zip(*list(tmp_Rst))))

        #900.   Purge.
        tmp_Rst , l_markers , tmpmarkers , split_base , split_sub , split_amt = None , None , None , None , None , None

        #990.   Return
        return( Out_Rst )
    #End of [__splitAmtByChoice]

    #690.   Function to create the dataset of Demographic Information for the provided customer list.
    def __crDemoInf( self , custlist : list ) -> 'Create the dataset of Demographic Information for the provided customer list':
        #010.   Local Parameters.
        ncust : int = len(custlist)

        #110.   Nationality
        cus_nation : list = np.random.choice( [ i[0] for i in self.__nation ] , ncust , p = [ i[1] for i in self.__nation ] ).tolist()

        #120.   Residence
        cus_resi : list = np.random.choice( [ i[0] for i in self.__resi ] , ncust , p = [ i[1] for i in self.__resi ] ).tolist()

        #130.   Profession
        cus_prof : list = np.random.choice( [ i[0] for i in self.__prof ] , ncust , p = [ i[1] for i in self.__prof ] ).tolist()

        #140.   Gender
        cus_gender : list = np.random.choice( self.__gender , ncust ).tolist()

        #150.   Acquisition Channel
        cus_acq : list = np.random.choice( [ i[0] for i in self.__acq ] , ncust , p = [ i[1] for i in self.__acq ] ).tolist()

        #160.   Consumption Habit
        cus_consume : list = np.random.choice( [ i[0] for i in self.__consume ] , ncust , p = [ i[1] for i in self.__consume ] ).tolist()

        #170.   Age Distribution
        cus_age : list = np.random.choice( [ i[0] for i in self.__age ] , ncust , p = [ i[1] for i in self.__age ] ).tolist()

        #500.   Create the datasets.
        lst_out : list = list(map(list,zip(
                                custlist
                                , cus_nation , cus_resi , cus_prof , cus_gender , cus_acq , cus_consume , cus_age
                            )))
        ds_out : pd.DataFrame = pd.DataFrame(
                                    data = lst_out
                                    , columns = [
                                                'NC_CIFNO'
                                                , 'C_Nationality' , 'C_Residence' , 'C_Profession' , 'C_Gender' , 'C_Acquisition' , 'C_ConsumptionHabit' , 'C_AgeSegment'
                                            ]
                                )

        #900.   Purge.
        cus_nation , cus_resi , cus_prof , cus_gender , cus_acq , cus_consume , cus_age = None , None , None , None , None , None , None
        lst_out , ncust = None , None

        #990.   Return
        return( ds_out )
    #End of [__crDemoInf]

    #700.   Formats and Pictures for data mapping.
    #701.   Currency category.
    def __fmt_ccytype( self , row : pd.DataFrame ) -> 'Format to categorize the currencies':
        if row['C_CCY'] == 'CNY':
            return( 'LCY' )
        else:
            return( 'FCY' )
    #End of [__fmt_ccytype]

    #702.   Report category.
    def __fmt_prodrptcat( self , row : pd.DataFrame ) -> 'Format to categorize the Products for Reporting purpose':
        if row['C_ProdType'] in [ 'CASA' , 'TD' ]:
            return( row['C_ProdType'] + '-' + row['C_CcyType'] )
        elif row['C_ProdType'] in [ 'QDII' , 'QDUT' , 'QDSN' ]:
            return( row['C_Category'] )
        else:
            return( row['C_ProdType'] )
    #End of [__fmt_prodrptcat]

    #710.   Mapping table for Structured Products.
    @property
    def metaprod_SP( self ) -> 'Get the mapping table for Structured Products':
        return( self.__metaprod_SPmapping )
    #End of [metaprod_SP]
    @property
    def __metaprod_SP( self ) -> 'Create the mapping table for Structured Products':
        #010.   Parameters.
        #There are much more tranches of [ASP] products issued than [RSP], while their average volumens are much less than those within [RSP].
        #The bank issues 4 tranches of 3-month ASP in each month, on the 6~9th working day and [-9]~[-6]th working day respectively.
        #The bank issues 2 tranches of 6-month ASP in each month, on the 8~15th working day.
        #There is 1/3 chance of the bank to issue 1 tranche of 1-year ASP in each month.
        #There is 1/6 chance of the bank to issue 1 tranche of 2-year ASP in each month.
        #There is 1/2 chance of the bank to issue 1 tranche of RSP in each month, with the tenor of 3-month or 6-month at probability of 0.75 and 0.25 respectively.
        pfx_ASP : list = [ ['MALI',0.75] , ['RLI',0.25] ]
        pfx_RSP : list = [ ['ILI',0.68] , ['ELI',0.32] ]

        #100.   Create the mapping table for all existing products.
        #110.   Lists of products
        #There should be 12 active tranches of 3-month ASP at any time.
        ASP3m : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '3M' + str(j) for j in range(12) ]
        ASP3m_tenor : list = [ 90 for j in range(12) ]
        ASP3m_mat : list = [ self.__curdate.to_pydatetime() + dt.timedelta(days=np.random.randint(low=7 * (j+1),high=7 * (j+1) + 3)) for j in range(12) ]
        #There should be 12 active tranches of 6-month ASP at any time.
        ASP6m : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '6M' + str(j) for j in range(12) ]
        ASP6m_tenor : list = [ 180 for j in range(12) ]
        ASP6m_mat : list = [ self.__curdate.to_pydatetime() + dt.timedelta(days=np.random.randint(low=13 * (j+1),high=13 * (j+1) + 4)) for j in range(12) ]
        #The chances where there are [k] tranches of 1-year ASP are calculated below.
        pASP1y : list = [ [ i , comb( 12 , i ) * pow( 1/3 , i ) * pow( 1 - 1/3 , 12 - i ) ] for i in range(12) ]
        pASP1y[0][1] += 1- sum(i[1] for i in pASP1y)
        pASP1y.sort( key=lambda x : x[1] , reverse = True )
        nASP1y : int = np.random.choice([i[0] for i in pASP1y],1,p=[i[-1] for i in pASP1y])[0]
        if nASP1y:
            ASP1y : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '1Y' + str(j) for j in range(nASP1y) ]
            ASP1y_tenor : list = [ 360 for j in range(nASP1y) ]
            ASP1y_mat : list = [ self.__curdate.to_pydatetime() + dt.timedelta(days=np.random.randint(low=1,high=360)) for j in range(nASP1y) ]
        else:
            ASP1y : list = []
            ASP1y_tenor : list = []
            ASP1y_mat : list = []
        #The chances where there are [k] tranches of 2-year ASP are calculated below.
        pASP2y : list = [ [ i , comb( 12 , i ) * pow( 1/6 , i ) * pow( 1 - 1/6 , 12 - i ) ] for i in range(12) ]
        pASP2y[0][1] += 1- sum(i[1] for i in pASP2y)
        pASP2y.sort( key=lambda x : x[1] , reverse = True )
        nASP2y : int = np.random.choice([i[0] for i in pASP2y],1,p=[i[-1] for i in pASP2y])[0]
        if nASP2y:
            ASP2y : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '2Y' + str(j) for j in range(nASP2y) ]
            ASP2y_tenor : list = [ 730 for j in range(nASP2y) ]
            ASP2y_mat : list = [ self.__curdate.to_pydatetime() + dt.timedelta(days=np.random.randint(low=1,high=730)) for j in range(nASP2y) ]
        else:
            ASP2y : list = []
            ASP2y_tenor : list = []
            ASP2y_mat : list = []
        #The chances where there are [k] tranches of 3-month RSP are calculated below.
        pRSP3m : list = [ [ i , comb( 3 , i ) * pow( 3/8 , i ) * pow( 1 - 3/8 , 3 - i ) ] for i in range(3) ]
        pRSP3m[0][1] += 1- sum(i[1] for i in pRSP3m)
        pRSP3m.sort( key=lambda x : x[1] , reverse = True )
        nRSP3m : int = np.random.choice([i[0] for i in pRSP3m],1,p=[i[-1] for i in pRSP3m])[0]
        if nRSP3m:
            RSP3m : list = [ np.random.choice([i[0] for i in pfx_RSP],1,p=[i[-1] for i in pfx_RSP])[0] + '3M' + str(j) for j in range(nRSP3m) ]
            RSP3m_tenor : list = [ 90 for j in range(nRSP3m) ]
            RSP3m_mat : list = [ self.__curdate.to_pydatetime() + dt.timedelta(days=np.random.randint(low=1,high=90)) for j in range(nRSP3m) ]
        else:
            RSP3m : list = []
            RSP3m_tenor : list = []
            RSP3m_mat : list = []
        #The chances where there are [k] tranches of 6-month RSP are calculated below.
        pRSP6m : list = [ [ i , comb( 6 , i ) * pow( 1/8 , i ) * pow( 1 - 1/8 , 6 - i ) ] for i in range(6) ]
        pRSP6m[0][1] += 1- sum(i[1] for i in pRSP6m)
        pRSP6m.sort( key=lambda x : x[1] , reverse = True )
        nRSP6m : int = np.random.choice([i[0] for i in pRSP6m],1,p=[i[-1] for i in pRSP6m])[0]
        if nRSP6m:
            RSP6m : list = [ np.random.choice([i[0] for i in pfx_RSP],1,p=[i[-1] for i in pfx_RSP])[0] + '6M' + str(j) for j in range(nRSP6m) ]
            RSP6m_tenor : list = [ 180 for j in range(nRSP6m) ]
            RSP6m_mat : list = [ self.__curdate.to_pydatetime() + dt.timedelta(days=np.random.randint(low=1,high=180)) for j in range(nRSP6m) ]
        else:
            RSP6m : list = []
            RSP6m_tenor : list = []
            RSP6m_mat : list = []

        #160.   Create dataset.
        l_prod : list = ASP3m + ASP6m + ASP1y + ASP2y + RSP3m + RSP6m
        l_tenor : list = ASP3m_tenor + ASP6m_tenor + ASP1y_tenor + ASP2y_tenor + RSP3m_tenor + RSP6m_tenor
        l_mat : list = ASP3m_mat + ASP6m_mat + ASP1y_mat + ASP2y_mat + RSP3m_mat + RSP6m_mat
        lst_out : list = list(map(list,zip( l_prod , l_tenor , l_mat )))
        ds_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'K_Tenor_Day' , 'DT_Maturity' ] )

        #170.   Correct the data and add necessary fields.
        #171.   Shift the maturity dates to their respective Previous Work Days if they are not Work Days.
        ds_base['DT_Maturity'] = ShiftDateList( ds_base['DT_Maturity'].tolist() ).shiftByWorkDay

        #172.   Add fields.
        def genValueDate( row ):
            return( row['DT_Maturity'] - dt.timedelta(days=row['K_Tenor_Day']) )
        ds_base['DT_Value'] = ds_base.apply( genValueDate , axis = 1 )

        #200.   Create the mapping table for all products that will be launched in current period.
        #210.   3-month ASP
        n_ASP3m_pre : list = self.__metaprod_SPValueDay
        n_ASP3m_value : list = [ k for j in n_ASP3m_pre for k in j[-1] ]
        n_ASP3m : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '3M' + j[0] + '{0:{fill}{width}}'.format( k + 1 , fill = 0 , width = 2 ) for j in n_ASP3m_pre for k in range(len(j[-1])) ]
        n_ASP3m_tenor : list = [ 90 for j in n_ASP3m_value ]
        #Ensure all maturity dates are work days.
        n_ASP3m_mat : list = ShiftDateList( [ n_ASP3m_value[i] + dt.timedelta( days = n_ASP3m_tenor[i] ) for i in range(len(n_ASP3m_value)) ] ).shiftByWorkDay

        #220.   6-month ASP
        n_ASP6m_pre : list = [ [ dt.datetime.strftime(i[0],'%Y%m') , np.random.choice(i,2).tolist() ] for i in self.wd_of_months ]
        n_ASP6m_value : list = [ k for j in n_ASP6m_pre for k in j[-1] ]
        n_ASP6m : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '6M' + j[0] + '{0:{fill}{width}}'.format( k + 1 , fill = 0 , width = 2 ) for j in n_ASP6m_pre for k in range(len(j[-1])) ]
        n_ASP6m_tenor : list = [ 180 for j in n_ASP6m_value ]
        #Ensure all maturity dates are work days.
        n_ASP6m_mat : list = ShiftDateList( [ n_ASP6m_value[i] + dt.timedelta( days = n_ASP6m_tenor[i] ) for i in range(len(n_ASP6m_value)) ] ).shiftByWorkDay

        #230.   1-year ASP
        fn_pASP1y : list = [ np.random.choice([False,True],1,p=[1-1/3,1/3])[0] for i in range(self.kMth) ]
        n_ASP1y_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pASP1y[i] ]
        n_ASP1y_value : list = [ j[-1] for j in n_ASP1y_pre ]
        if n_ASP1y_value:
            n_ASP1y : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '1Y' + j[0] + '01' for j in n_ASP1y_pre ]
            n_ASP1y_tenor : list = [ 360 for j in n_ASP1y_value ]
            #Ensure all maturity dates are work days.
            n_ASP1y_mat : list = ShiftDateList( [ n_ASP1y_value[i] + dt.timedelta( days = n_ASP1y_tenor[i] ) for i in range(len(n_ASP1y_value)) ] ).shiftByWorkDay
        else:
            n_ASP1y : list = []
            n_ASP1y_tenor : list = []
            n_ASP1y_mat : list = []

        #240.   2-year ASP
        fn_pASP2y : list = [ np.random.choice([False,True],1,p=[1-1/6,1/6])[0] for i in range(self.kMth) ]
        n_ASP2y_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pASP2y[i] ]
        n_ASP2y_value : list = [ j[-1] for j in n_ASP2y_pre ]
        if n_ASP2y_value:
            n_ASP2y : list = [ np.random.choice([i[0] for i in pfx_ASP],1,p=[i[-1] for i in pfx_ASP])[0] + '2Y' + j[0] + '01' for j in n_ASP2y_pre ]
            n_ASP2y_tenor : list = [ 730 for j in n_ASP2y_value ]
            #Ensure all maturity dates are work days.
            n_ASP2y_mat : list = ShiftDateList( [ n_ASP2y_value[i] + dt.timedelta( days = n_ASP2y_tenor[i] ) for i in range(len(n_ASP2y_value)) ] ).shiftByWorkDay
        else:
            n_ASP2y : list = []
            n_ASP2y_tenor : list = []
            n_ASP2y_mat : list = []

        #250.   3-month RSP
        fn_pRSP3m : list = [ np.random.choice([False,True],1,p=[1-3/8,3/8])[0] for i in range(self.kMth) ]
        n_RSP3m_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pRSP3m[i] ]
        n_RSP3m_value : list = [ j[-1] for j in n_RSP3m_pre ]
        if n_RSP3m_value:
            n_RSP3m : list = [ np.random.choice([i[0] for i in pfx_RSP],1,p=[i[-1] for i in pfx_RSP])[0] + '3M' + j[0] + '01' for j in n_RSP3m_pre ]
            n_RSP3m_tenor : list = [ 90 for j in n_RSP3m_value ]
            #Ensure all maturity dates are work days.
            n_RSP3m_mat : list = ShiftDateList( [ n_RSP3m_value[i] + dt.timedelta( days = n_RSP3m_tenor[i] ) for i in range(len(n_RSP3m_value)) ] ).shiftByWorkDay
        else:
            n_RSP3m : list = []
            n_RSP3m_tenor : list = []
            n_RSP3m_mat : list = []

        #260.   6-month RSP
        fn_pRSP6m : list = [ np.random.choice([False,True],1,p=[1-1/8,1/8])[0] for i in range(self.kMth) ]
        n_RSP6m_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pRSP6m[i] ]
        n_RSP6m_value : list = [ j[-1] for j in n_RSP6m_pre ]
        if n_RSP6m_value:
            n_RSP6m : list = [ np.random.choice([i[0] for i in pfx_RSP],1,p=[i[-1] for i in pfx_RSP])[0] + '6M' + j[0] + '01' for j in n_RSP6m_pre ]
            n_RSP6m_tenor : list = [ 180 for j in n_RSP6m_value ]
            #Ensure all maturity dates are work days.
            n_RSP6m_mat : list = ShiftDateList( [ n_RSP6m_value[i] + dt.timedelta( days = n_RSP6m_tenor[i] ) for i in range(len(n_RSP6m_value)) ] ).shiftByWorkDay
        else:
            n_RSP6m : list = []
            n_RSP6m_tenor : list = []
            n_RSP6m_mat : list = []

        #300.   Create dataset for new products to be launched.
        n_prod : list = n_ASP3m + n_ASP6m + n_ASP1y + n_ASP2y + n_RSP3m + n_RSP6m
        n_tenor : list = n_ASP3m_tenor + n_ASP6m_tenor + n_ASP1y_tenor + n_ASP2y_tenor + n_RSP3m_tenor + n_RSP6m_tenor
        n_mat : list = n_ASP3m_mat + n_ASP6m_mat + n_ASP1y_mat + n_ASP2y_mat + n_RSP3m_mat + n_RSP6m_mat
        n_value : list = n_ASP3m_value + n_ASP6m_value + n_ASP1y_value + n_ASP2y_value + n_RSP3m_value + n_RSP6m_value
        lst_out : list = list(map(list,zip( n_prod , n_tenor , n_mat , n_value )))
        ds_app : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'K_Tenor_Day' , 'DT_Maturity' , 'DT_Value' ] )

        #400.   Add necessary fields for the new products.
        Rst_Out : pd.DataFrame = ds_base.append( ds_app , ignore_index = True )
        Rst_Out['C_CCY'] = np.random.choice( [ i[0] for i in self.__ccy ] , len(Rst_Out) , p = [ i[1] for i in self.__ccy ] ).tolist()
        def prodtype( row ):
            for pfx in pfx_ASP:
                if row['C_Prod_Name'][0:len(pfx[0])] == pfx[0]:
                    return( 'ASP' )
            return( 'RSP' )
        Rst_Out['C_ProdType'] = Rst_Out.apply( prodtype , axis = 1 )

        #900.   Purge.
        pfx_ASP , pfx_RSP = None , None
        ASP3m , ASP3m_tenor , ASP3m_mat , ASP6m , ASP6m_tenor , ASP6m_mat = None , None , None , None , None , None
        pASP1y , nASP1y , ASP1y , ASP1y_tenor , ASP1y_mat = None , None , None , None , None
        pASP2y , nASP2y , ASP2y , ASP2y_tenor , ASP2y_mat = None , None , None , None , None
        pRSP3m , nRSP3m , RSP3m , RSP3m_tenor , RSP3m_mat = None , None , None , None , None
        pRSP6m , nRSP6m , RSP6m , RSP6m_tenor , RSP6m_mat = None , None , None , None , None
        n_ASP3m_pre , n_ASP3m_value , n_ASP3m , n_ASP3m_tenor , n_ASP3m_mat = None , None , None , None , None
        n_ASP6m_pre , n_ASP6m_value , n_ASP6m , n_ASP6m_tenor , n_ASP6m_mat = None , None , None , None , None
        fn_pASP1y , n_ASP1y_value , n_ASP1y , n_ASP1y_tenor , n_ASP1y_mat , n_ASP1y_pre = None , None , None , None , None , None
        fn_pASP2y , n_ASP2y_value , n_ASP2y , n_ASP2y_tenor , n_ASP2y_mat , n_ASP2y_pre = None , None , None , None , None , None
        fn_pRSP3m , n_RSP3m_value , n_RSP3m , n_RSP3m_tenor , n_RSP3m_mat , n_RSP3m_pre = None , None , None , None , None , None
        fn_pRSP6m , n_RSP6m_value , n_RSP6m , n_RSP6m_tenor , n_RSP6m_mat , n_RSP6m_pre = None , None , None , None , None , None
        l_prod , l_tenor , l_mat , lst_out , ds_base , ds_app = None , None , None , None , None , None
        n_prod , n_tenor , n_mat , n_value = None , None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__metaprod_SP]

    #711.   Define the value days of SP products in current period.
    @property
    def __metaprod_SPValueDay( self ) -> 'Generate the list of value dates for SP products within current period':
        #010.   Parameters.
        lst_tmp : list = []
        lst_mon : list = []
        lst_out : list = []

        #100.   Retrieve the list of dedicated range of Work Days.
        wdlst : list = self.wd_of_months
        #The first batch of value days lie in 6th~9th of each month.
        value1 : list = [ list(filter(lambda x: 6<=x.day<=9,wdlst[i])) for i in range(len(wdlst)) ]
        #The first batch of value days lie in 19th~23rd of each month.
        value2 : list = [ list(filter(lambda x: 19<=x.day<=23,wdlst[i])) for i in range(len(wdlst)) ]

        #200.   Select 2 work days from the first batch of days in each month.
        for mon in value1:
            if mon:
                lst_tmp.extend( np.random.choice( mon , 2 ).tolist() )

        #300.   Select 2 work days from the second batch of days in each month.
        for mon in value2:
            if mon:
                lst_tmp.extend( np.random.choice( mon , 2 ).tolist() )

        #900.   Purge.
        lst_mon = np.unique( [ dt.datetime.strftime(i,'%Y%m') for i in lst_tmp ] ).tolist()
        lst_out = [ [ i , list(filter(lambda x:dt.datetime.strftime(x,'%Y%m')==i,lst_tmp)) ] for i in lst_mon ]
        lst_tmp , lst_mon , wdlst , value1 , value2 = None , None , None , None , None

        #990.   Return
        return( lst_out )
    #End of [__metaprod_SPValueDay]

    #720.   Mapping table for QD Products.
    @property
    def metaprod_QD( self ) -> 'Get the mapping table for QD Products':
        return( self.__metaprod_QDmapping )
    #End of [metaprod_QD]
    @property
    def __metaprod_QD( self ) -> 'Create the mapping table for QD Products':
        #010.   Parameters.
        #There is not any necessary relationship between the issuance and the holding of the QD Products.
        #The bank issues 4~6 tranches of QDII or QDUT Products within each year, indicating there is 1/3 ~ 1/2 chance in each month for product issuance.
        #The bank issues 1~3 tranches of QDSN Products in each year, indicating there is 1/12 ~ 1/4 chance in each month for product issuance.
        pfx_QD : list = [ ['QDII',0.55] , ['QDUT',0.35] , ['QDSN',0.10] ]
        cat_QD : list = [ ['QD-Core',0.60] , ['QD-Tatical1',0.30] , ['QD-Tactical2',0.10] ]

        #100.   Create the mapping table for all existing products.
        #All products are active since 10 years ago when the bank opened business.
        #There could be 1~3 currencies of the same product line.
        k_QD_base : list = [ np.random.randint( low = 4 , high = 9 ) for i in range(10) ]
        qd_name_pre : list = [
                            [
                                np.random.choice([i[0] for i in pfx_QD],1,p=[i[-1] for i in pfx_QD])[0]
                                + '{0:{fill}{width}}'.format( j + 1 , fill = 0 , width = 3 )
                                , np.random.choice( pd.date_range( start = ( self.__curdate.to_pydatetime() - dt.timedelta(days=3650) ).strftime('%m/%d/%Y') , end = self.__curdate.strftime('%m/%d/%Y') ).tolist() , 1 )[0]
                                , np.random.choice([i[0] for i in cat_QD],1,p=[i[-1] for i in cat_QD])[0]
                                , np.random.choice( [l[0] for l in self.__ccy] , np.random.randint( low = 1, high = 3 ) , p=[l[-1] for l in self.__ccy] , replace=False ).tolist()
                            ]
                            for j in range(sum(k_QD_base))
                        ]
        qd_name : list = [ j[0] + i for j in qd_name_pre for i in j[-1] ]
        qd_issue : list = [ j[1] for j in qd_name_pre for i in j[-1] ]
        qd_cat : list = [ j[2] for j in qd_name_pre for i in j[-1] ]
        qd_ccy : list = [ i for j in qd_name_pre for i in j[-1] ]

        #190.   Create dataset for existing products.
        lst_out : list = list(map(list,zip( qd_name , qd_issue , qd_cat , qd_ccy )))
        ds_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' , 'C_Category' , 'C_CCY' ] )

        #200.   Create the mapping table for all products that will be launched in current period.
        fn_pqd : list = [ np.random.choice([False,True],1,p=[1-1/3,1/3])[0] for i in range(self.kMth) ]
        n_qd_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pqd[i] ]
        if n_qd_pre:
            n_qd_name_pre : list = [
                                [
                                    np.random.choice([i[0] for i in pfx_QD],1,p=[i[-1] for i in pfx_QD])[0] + j[0]
                                    , j[-1]
                                    , np.random.choice([i[0] for i in cat_QD],1,p=[i[-1] for i in cat_QD])[0]
                                    , np.random.choice( [l[0] for l in self.__ccy] , np.random.randint( low = 1, high = 3 ) , p=[l[-1] for l in self.__ccy] , replace=False ).tolist()
                                ]
                                for j in n_qd_pre
                            ]
            n_qd_name : list = [ j[0] + i for j in n_qd_name_pre for i in j[-1] ]
            n_qd_issue : list = [ j[1] for j in n_qd_name_pre for i in j[-1] ]
            n_qd_cat : list = [ j[2] for j in n_qd_name_pre for i in j[-1] ]
            n_qd_ccy : list = [ i for j in n_qd_name_pre for i in j[-1] ]
        else:
            n_qd_name_pre : list = []
            n_qd_name : list = []
            n_qd_issue : list = []
            n_qd_cat : list = []
            n_qd_ccy : list = []

        #290.   Create dataset for new products to be launched and append to the base product list.
        if n_qd_pre:
            lst_out : list = list(map(list,zip( n_qd_name , n_qd_issue , n_qd_cat , n_qd_ccy )))
            ds_app : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' , 'C_Category' , 'C_CCY' ] )
            Rst_Out : pd.DataFrame = ds_base.append( ds_app , ignore_index = True )
        else:
            Rst_Out : pd.DataFrame = ds_base

        #800.   Append additional fields.
        Rst_Out['C_ProdType'] = Rst_Out['C_Prod_Name'].apply( lambda x : x[0:4] )

        #900.   Purge.
        pfx_QD , cat_QD = None , None
        k_QD_base , qd_name_pre , qd_name , qd_issue , qd_category = None , None , None , None , None
        fn_pqd , n_qd_pre , n_qd_name_pre , n_qd_name , n_qd_issue , n_qd_cat , n_qd_ccy = None , None , None , None , None , None , None
        lst_out , ds_base , ds_app = None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__metaprod_QD]

    #730.   Mapping table for Local UT Products.
    @property
    def metaprod_LUT( self ) -> 'Get the mapping table for Local UT Products':
        return( self.__metaprod_LUTmapping )
    #End of [metaprod_LUT]
    @property
    def __metaprod_LUT( self ) -> 'Create the mapping table for Local UT Products':
        #010.   Parameters.
        #There is not any necessary relationship between the issuance and the holding of the Local UT Products.
        #The bank issues 1~3 tranches of Local UT Products in each year, indicating there is 1/12 ~ 1/4 chance in each month for product issuance.
        c_LUT : float = np.random.choice([1/12,1/4],1)[0]

        #100.   Create the mapping table for all existing products.
        #All products are active since 10 years ago when the bank opened business.
        #All Local UT products share the same currency CNY.
        k_LUT_base : list = [ np.random.randint( low = 1 , high = 3 ) for i in range(10) ]
        lut_name_pre : list = [
                            [
                                '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 999999 ) , fill = 0 , width = 6 )
                                , np.random.choice( pd.date_range( start = ( self.__curdate.to_pydatetime() - dt.timedelta(days=3650) ).strftime('%m/%d/%Y') , end = self.__curdate.strftime('%m/%d/%Y') ).tolist() , 1 )[0]
                            ]
                            for j in range(sum(k_LUT_base))
                        ]
        lut_name : list = [ j[-1].strftime('%Y%m%d') + j[0] for j in lut_name_pre ]
        lut_issue : list = [ j[-1] for j in lut_name_pre ]

        #190.   Create dataset for existing products.
        lst_out : list = list(map(list,zip( lut_name , lut_issue )))
        ds_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' ] )

        #200.   Create the mapping table for all products that will be launched in current period.
        fn_plut : list = [ np.random.choice([False,True],1,p=[1-c_LUT,c_LUT])[0] for i in range(self.kMth) ]
        n_lut_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_plut[i] ]
        if n_lut_pre:
            n_lut_name_pre : list = [
                                [
                                    '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 999999 ) , fill = 0 , width = 6 )
                                    , j[-1]
                                ]
                                for j in n_lut_pre
                            ]
            n_lut_name : list = [ j[-1].strftime('%Y%m%d') + j[0] for j in n_lut_name_pre ]
            n_lut_issue : list = [ j[-1] for j in n_lut_name_pre ]
        else:
            n_lut_name_pre : list = []
            n_lut_name : list = []
            n_lut_issue : list = []

        #290.   Create dataset for new products to be launched and append to the base product list.
        if n_lut_pre:
            lst_out : list = list(map(list,zip( n_lut_name , n_lut_issue )))
            ds_app : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' ] )
            Rst_Out : pd.DataFrame = ds_base.append( ds_app , ignore_index = True )
        else:
            Rst_Out : pd.DataFrame = ds_base

        #800.   Append additional fields.
        Rst_Out['C_ProdType'] = 'LUT'

        #900.   Purge.
        c_LUT = None
        k_LUT_base , lut_name_pre , lut_name , lut_issue = None , None , None , None
        fn_plut , n_lut_pre , n_lut_name_pre , n_lut_name , n_lut_issue = None , None , None , None , None
        lst_out , ds_base , ds_app = None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__metaprod_LUT]

    #735.   Mapping table for Money Market Fund Products.
    @property
    def metaprod_MMF( self ) -> 'Get the mapping table for Money Market Fund Products':
        return( self.__metaprod_MMFmapping )
    #End of [metaprod_MMF]
    @property
    def __metaprod_MMF( self ) -> 'Create the mapping table for Money Market Fund Products':
        #010.   Parameters.
        #There is not any necessary relationship between the issuance and the holding of the Money Market Fund Products.
        #There is 1/20 chance in each month for product issuance.
        c_MMF : float = 1/20

        #100.   Create the mapping table for all existing products.
        #All products are active when the bank opened business.
        #All Local UT products share the same currency CNY.
        k_MMF_base : list = np.random.randint( low = 1 , high = 3 )
        mmf_name_pre : list = [
                            [
                                '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 9999999 ) , fill = 0 , width = 7 )
                                , np.random.choice( pd.date_range( start = ( self.__curdate.to_pydatetime() - dt.timedelta(days=1800) ).strftime('%m/%d/%Y') , end = self.__curdate.strftime('%m/%d/%Y') ).tolist() , 1 )[0]
                            ]
                            for j in range(k_MMF_base)
                        ]
        mmf_name : list = [ j[-1].strftime('%Y%m%d') + j[0] for j in mmf_name_pre ]
        mmf_issue : list = [ j[-1] for j in mmf_name_pre ]

        #190.   Create dataset for existing products.
        lst_out : list = list(map(list,zip( mmf_name , mmf_issue )))
        ds_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' ] )

        #200.   Create the mapping table for all products that will be launched in current period.
        fn_pmmf : list = [ np.random.choice([False,True],1,p=[1-c_MMF,c_MMF])[0] for i in range(self.kMth) ]
        n_mmf_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pmmf[i] ]
        if n_mmf_pre:
            n_mmf_name_pre : list = [
                                [
                                    '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 9999999 ) , fill = 0 , width = 7 )
                                    , j[-1]
                                ]
                                for j in n_mmf_pre
                            ]
            n_mmf_name : list = [ j[-1].strftime('%Y%m%d') + j[0] for j in n_mmf_name_pre ]
            n_mmf_issue : list = [ j[-1] for j in n_mmf_name_pre ]
        else:
            n_mmf_name_pre : list = []
            n_mmf_name : list = []
            n_mmf_issue : list = []

        #290.   Create dataset for new products to be launched and append to the base product list.
        if n_mmf_pre:
            lst_out : list = list(map(list,zip( n_mmf_name , n_mmf_issue )))
            ds_app : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' ] )
            Rst_Out : pd.DataFrame = ds_base.append( ds_app , ignore_index = True )
        else:
            Rst_Out : pd.DataFrame = ds_base

        #800.   Append additional fields.
        Rst_Out['C_ProdType'] = 'MMF'

        #900.   Purge.
        c_MMF = None
        k_MMF_base , mmf_name_pre , mmf_name , mmf_issue = None , None , None , None
        fn_pmmf , n_mmf_pre , n_mmf_name_pre , n_mmf_name , n_mmf_issue = None , None , None , None , None
        lst_out , ds_base , ds_app = None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__metaprod_MMF]

    #740.   Mapping table for Bond Products.
    @property
    def metaprod_Bond( self ) -> 'Get the mapping table for Bond Products':
        return( self.__metaprod_Bondmapping )
    #End of [metaprod_Bond]
    @property
    def __metaprod_Bond( self ) -> 'Create the mapping table for Bond Products':
        #010.   Parameters.
        #There is not any necessary relationship between the issuance and the holding of the Bond Products.
        #There is 1/12 ~ 1/6 chance in each month for product issuance.
        c_Bond : float = np.random.choice([1/12,1/6],1)[0]
        tnr_Bond : list = [ [360,0.55] , [730,0.35] , [1830,0.10] ]

        #100.   Create the mapping table for all existing products.
        #We presume there are 3~7 products launched in the previous year, hence they should all be active.
        k_Bond_base : list = np.random.randint( low = 3 , high = 7 )
        bond_name_pre : list = [
                            [
                                '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 999999 ) , fill = 0 , width = 6 )
                                , np.random.choice( pd.date_range( start = ( self.__curdate.to_pydatetime() - dt.timedelta(days=359) ).strftime('%m/%d/%Y') , end = self.__curdate.strftime('%m/%d/%Y') ).tolist() , 1 )[0]
                                , np.random.choice( [l[0] for l in tnr_Bond], 1 , p=[l[-1] for l in tnr_Bond] )[0]
                                , np.random.choice( [l[0] for l in self.__ccy], 1 , p=[l[-1] for l in self.__ccy] )[0]
                            ]
                            for j in range(k_Bond_base)
                        ]
        bond_name : list = [ 'BOND' + j[1].strftime('%Y%m%d') + j[0] for j in bond_name_pre ]
        bond_value : list = [ j[1] for j in bond_name_pre ]
        bond_tenor : list = [ int(j[2]) for j in bond_name_pre ]
        bond_ccy : list = [ j[3] for j in bond_name_pre ]
        #Ensure all maturity dates are work days.
        bond_mat : list = ShiftDateList( [ bond_value[i] + dt.timedelta( days = bond_tenor[i] ) for i in range(len(bond_value)) ] ).shiftByWorkDay

        #190.   Create dataset for existing products.
        lst_out : list = list(map(list,zip( bond_name , bond_tenor , bond_mat , bond_value , bond_ccy )))
        ds_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'K_Tenor_Day' , 'DT_Maturity' , 'DT_Value' , 'C_CCY' ] )

        #200.   Create the mapping table for all products that will be launched in current period.
        fn_pbond : list = [ np.random.choice([False,True],1,p=[1-c_Bond,c_Bond])[0] for i in range(self.kMth) ]
        n_bond_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pbond[i] ]
        if n_bond_pre:
            n_bond_name_pre : list = [
                                [
                                    '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 999999 ) , fill = 0 , width = 6 )
                                    , j[-1]
                                    , np.random.choice( [l[0] for l in tnr_Bond], 1 , p=[l[-1] for l in tnr_Bond] )[0]
                                    , np.random.choice( [l[0] for l in self.__ccy], 1 , p=[l[-1] for l in self.__ccy] )[0]
                                ]
                                for j in n_bond_pre
                            ]
            n_bond_name : list = [ 'BOND' + j[1].strftime('%Y%m%d') + j[0] for j in n_bond_name_pre ]
            n_bond_value : list = [ j[1] for j in n_bond_name_pre ]
            n_bond_tenor : list = [ int(j[2]) for j in n_bond_name_pre ]
            n_bond_ccy : list = [ j[3] for j in n_bond_name_pre ]
            #Ensure all maturity dates are work days.
            n_bond_mat : list = ShiftDateList( [ n_bond_value[i] + dt.timedelta( days = n_bond_tenor[i] ) for i in range(len(n_bond_value)) ] ).shiftByWorkDay
        else:
            n_bond_name_pre : list = []
            n_bond_name : list = []
            n_bond_value : list = []
            n_bond_tenor : list = []
            n_bond_ccy : list = []
            n_bond_mat : list = []

        #290.   Create dataset for new products to be launched and append to the base product list.
        if n_bond_pre:
            lst_out : list = list(map(list,zip( n_bond_name , n_bond_tenor , n_bond_mat , n_bond_value , n_bond_ccy )))
            ds_app : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'K_Tenor_Day' , 'DT_Maturity' , 'DT_Value' , 'C_CCY' ] )
            Rst_Out : pd.DataFrame = ds_base.append( ds_app , ignore_index = True )
        else:
            Rst_Out : pd.DataFrame = ds_base

        #800.   Append additional fields.
        Rst_Out['C_ProdType'] = 'BOND'

        #900.   Purge.
        c_Bond , tnr_Bond = None , None
        k_Bond_base , bond_name_pre , bond_name , bond_value , bond_tenor , bond_ccy , bond_mat = None , None , None , None , None , None , None
        fn_pbond , n_bond_pre , n_bond_name_pre , n_bond_name , n_bond_value , n_bond_tenor , n_bond_ccy , n_bond_mat = None , None , None , None , None , None , None , None
        lst_out , ds_base , ds_app = None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__metaprod_Bond]

    #750.   Mapping table for Banca Products.
    @property
    def metaprod_Bnc( self ) -> 'Get the mapping table for Banca Products':
        return( self.__metaprod_Bncmapping )
    #End of [metaprod_Bnc]
    @property
    def __metaprod_Bnc( self ) -> 'Create the mapping table for Banca Products':
        #010.   Parameters.
        #There is not any necessary relationship between the issuance and the holding of the Banca Products.
        #Only the first contract will be counted for Sales Volume in the Bank, for all subsequent payments go to the Insurance Company directly.
        #There is 4/12 ~ 5/12 chance in each month for product issuance.
        c_Bnc : float = np.random.choice([4/12,5/12],1)[0]
        tnr_Bnc : list = [ [1830,0.55] , [3650,0.25] , [5475,0.10] , [7300,0.10] ]

        #100.   Create the mapping table for all existing products.
        #We presume there are 20~25 products launched in the previous 5 years, hence they should all be active.
        k_Bnc_base : list = np.random.randint( low = 20 , high = 25 )
        bnc_name_pre : list = [
                            [
                                '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 999999 ) , fill = 0 , width = 6 )
                                , np.random.choice( pd.date_range( start = ( self.__curdate.to_pydatetime() - dt.timedelta(days=1800) ).strftime('%m/%d/%Y') , end = self.__curdate.strftime('%m/%d/%Y') ).tolist() , 1 )[0]
                                , np.random.choice( [l[0] for l in tnr_Bnc], 1 , p=[l[-1] for l in tnr_Bnc] )[0]
                            ]
                            for j in range(k_Bnc_base)
                        ]
        bnc_name : list = [ 'BNC' + j[1].strftime('%Y%m%d') + j[0] for j in bnc_name_pre ]
        bnc_value : list = [ j[1] for j in bnc_name_pre ]
        bnc_tenor : list = [ int(j[2]) for j in bnc_name_pre ]
        #Ensure all maturity dates are work days.
        bnc_mat : list = ShiftDateList( [ bnc_value[i] + dt.timedelta( days = bnc_tenor[i] ) for i in range(len(bnc_value)) ] ).shiftByWorkDay

        #190.   Create dataset for existing products.
        lst_out : list = list(map(list,zip( bnc_name , bnc_tenor , bnc_mat , bnc_value )))
        ds_base : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'K_Tenor_Day' , 'DT_Maturity' , 'DT_Value' ] )

        #200.   Create the mapping table for all products that will be launched in current period.
        fn_pbnc : list = [ np.random.choice([False,True],1,p=[1-c_Bnc,c_Bnc])[0] for i in range(self.kMth) ]
        n_bnc_pre : list = [ [ dt.datetime.strftime(self.wd_of_months[i][0],'%Y%m') , np.random.choice(self.wd_of_months[i],1)[0] ] for i in range(self.kMth) if fn_pbnc[i] ]
        if n_bnc_pre:
            n_bnc_name_pre : list = [
                                [
                                    '{0:{fill}{width}}'.format( np.random.randint( low = 1, high = 999999 ) , fill = 0 , width = 6 )
                                    , j[-1]
                                    , np.random.choice( [l[0] for l in tnr_Bnc], 1 , p=[l[-1] for l in tnr_Bnc] )[0]
                                ]
                                for j in n_bnc_pre
                            ]
            n_bnc_name : list = [ 'BNC' + j[1].strftime('%Y%m%d') + j[0] for j in n_bnc_name_pre ]
            n_bnc_value : list = [ j[1] for j in n_bnc_name_pre ]
            n_bnc_tenor : list = [ int(j[2]) for j in n_bnc_name_pre ]
            #Ensure all maturity dates are work days.
            n_bnc_mat : list = ShiftDateList( [ n_bnc_value[i] + dt.timedelta( days = n_bnc_tenor[i] ) for i in range(len(n_bnc_value)) ] ).shiftByWorkDay
        else:
            n_bnc_name_pre : list = []
            n_bnc_name : list = []
            n_bnc_value : list = []
            n_bnc_tenor : list = []
            n_bnc_mat : list = []

        #290.   Create dataset for new products to be launched and append to the base product list.
        if n_bnc_pre:
            lst_out : list = list(map(list,zip( n_bnc_name , n_bnc_tenor , n_bnc_mat , n_bnc_value )))
            ds_app : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'K_Tenor_Day' , 'DT_Maturity' , 'DT_Value' ] )
            Rst_Out : pd.DataFrame = ds_base.append( ds_app , ignore_index = True )
        else:
            Rst_Out : pd.DataFrame = ds_base

        #800.   Append additional fields.
        Rst_Out['C_ProdType'] = 'Banca'

        #900.   Purge.
        c_Bnc , tnr_Bnc = None , None
        k_Bnc_base , bnc_name_pre , bnc_name , bnc_value , bnc_tenor , bnc_mat = None , None , None , None , None , None
        fn_pbnc , n_bnc_pre , n_bnc_name_pre , n_bnc_name , n_bnc_value , n_bnc_tenor , n_bnc_mat = None , None , None , None , None , None , None
        lst_out , ds_base , ds_app = None , None , None

        #990.   Return
        return( Rst_Out )
    #End of [__metaprod_Bnc]

    #791.   Mapping table for all Products.
    @property
    def metaprod( self ) -> 'Collect the mapping table for all Products':
        return( self.__metaprod_all )
    #End of [metaprod]
    @property
    def __metaprod( self ) -> 'Combine the mapping tables for all Products':
        #010.   Parameters.
        l_mtables : list = []

        #020.   Define function to generalize the Product Issuance.
        #All these Products were issued when the Bank opened business.
        def prodissue( namepfx : str , prodtype : str , ccy : list ):
            _name : list = [ namepfx + '-' + i[0] for i in ccy ]
            _issue : list = [ self.__curdate.to_pydatetime() - dt.timedelta(days=3650) for i in ccy ]
            _ccy : list = [ i[0] for i in ccy ]
            _type : list = [ prodtype for i in ccy ]
            _out : list = list(map(list,zip( _name , _issue , _ccy , _type )))
            outds : pd.DataFrame = pd.DataFrame( data = _out , columns = [ 'C_Prod_Name' , 'DT_Issue' , 'C_CCY' , 'C_ProdType' ] )
            _name , _issue , _ccy , _type , _out = None , None , None , None , None
            return( outds )

        #100.   Initialize the mapping tables for specific Products.
        self.__metaprod_SPmapping : pd.DataFrame = self.__metaprod_SP
        self.__metaprod_QDmapping : pd.DataFrame = self.__metaprod_QD
        self.__metaprod_LUTmapping : pd.DataFrame = self.__metaprod_LUT
        self.__metaprod_MMFmapping : pd.DataFrame = self.__metaprod_MMF
        self.__metaprod_Bondmapping : pd.DataFrame = self.__metaprod_Bond
        self.__metaprod_Bncmapping : pd.DataFrame = self.__metaprod_Bnc
        l_mtables.extend( [ self.__metaprod_SPmapping , self.__metaprod_QDmapping , self.__metaprod_LUTmapping , self.__metaprod_MMFmapping , self.__metaprod_Bondmapping , self.__metaprod_Bncmapping ] )

        #200.   Deposit products.
        self.__metaprod_CASAmapping : pd.DataFrame = prodissue( 'Saving' , 'CASA' , self.__ccy )
        l_mtables.append( self.__metaprod_CASAmapping )
        self.__metaprod_TDmapping : pd.DataFrame = prodissue( 'TD' , 'TD' , self.__ccy )
        l_mtables.append( self.__metaprod_TDmapping )

        #300.   PCI products.
        pci_pre : list = list(permutations([i[0] for i in self.__ccy],2))
        pci_name : list = [ 'PCI' + '-' + i[0] + '-' + i[-1] for i in pci_pre ]
        pci_issue : list = [ self.__curdate.to_pydatetime() - dt.timedelta(days=3650) for i in pci_pre ]
        pci_ccy : list = [ i[0] for i in pci_pre ]
        pci_ccy_to : list = [ i[-1] for i in pci_pre ]
        pci_type : list = [ 'PCI' for i in pci_pre ]
        lst_out : list = list(map(list,zip( pci_name , pci_issue , pci_ccy , pci_ccy_to , pci_type )))
        self.__metaprod_PCImapping : pd.DataFrame = pd.DataFrame( data = lst_out , columns = [ 'C_Prod_Name' , 'DT_Issue' , 'C_CCY' , 'C_CCY_TO' , 'C_ProdType' ] )
        l_mtables.append( self.__metaprod_PCImapping )

        #310.   FX products are almost the same as PCI products.
        self.__metaprod_FXmapping : pd.DataFrame = self.__metaprod_PCImapping.copy()
        self.__metaprod_FXmapping['C_Prod_Name'] = self.__metaprod_FXmapping['C_Prod_Name'].apply( lambda x : 'FX-Spot' + x.split('-')[1] + '-' + x.split('-')[2] )
        self.__metaprod_FXmapping['C_ProdType'] = 'FX'
        l_mtables.append( self.__metaprod_FXmapping )

        #400.   Asset products.
        self.__metaprod_MTGmapping : pd.DataFrame = prodissue( 'House Loan' , 'House Loan' , self.__ccy )
        l_mtables.append( self.__metaprod_MTGmapping )
        self.__metaprod_CCmapping : pd.DataFrame = prodissue( 'Credit Card' , 'Credit Card' , self.__ccy )
        l_mtables.append( self.__metaprod_CCmapping )
        self.__metaprod_PILmapping : pd.DataFrame = prodissue( 'PIL' , 'PIL' , self.__ccy )
        l_mtables.append( self.__metaprod_PILmapping )
        self.__metaprod_CLmapping : pd.DataFrame = prodissue( 'Car Loan' , 'Car Loan' , self.__ccy )
        l_mtables.append( self.__metaprod_CLmapping )

        #700.   Combine the mapping tables and correct the field values.
        mtables : pd.DataFrame = pd.concat( l_mtables , ignore_index = True )

        #710.   Correct the currency.
        def correctccy( row ):
            if row['C_ProdType'] in [ 'LUT' , 'MMF' , 'Banca' ]:
                return( 'CNY' )
            else:
                return( row['C_CCY'] )
        mtables['C_CCY'] = mtables.apply( correctccy , axis = 1 )
        mtables['C_CcyType'] = mtables.apply( self.__fmt_ccytype , axis = 1 )

        #720.   Define the Beginning and Ending of the Products.
        def genbgn( row ):
            if row['K_Tenor_Day'] > 0:
                return( row['DT_Value'] )
            else:
                return( row['DT_Issue'] )
        def genend( row ):
            if row['K_Tenor_Day'] > 0:
                return( row['DT_Maturity'] )
            else:
                return( pd.Timestamp(2099,12,31) )
        mtables['DT_Begin'] = mtables.apply( genbgn , axis = 1 )
        mtables['DT_End'] = mtables.apply( genend , axis = 1 )

        #750.   Demographic categories.
        mtables['C_Prod_Code'] = [ '{0:{fill}{width}}'.format( i + 1 , fill = 0 , width = 4 ) for i in mtables.index.tolist() ]
        mtables['C_Cat_Rpt'] = mtables.apply( self.__fmt_prodrptcat , axis = 1 )
        mtables['C_Family_Fin'] = mtables['C_Cat_Rpt'].apply( lambda x : [i[0] for i in self.__product for j in i[-1] if j[0] == x][0] )
        mtables['C_Family_BS'] = mtables['C_Cat_Rpt'].apply( lambda x : [i[0] for i in self.__balsheet for j in i[-1] if j[0] == x][0] )


        #760.   Retrieve the probability of the Product holdings by currencies for customers at the beginning of the period.
        ccy : pd.DataFrame = pd.DataFrame( data = self.__ccy , columns = [ 'C_CCY' , 'R_Prob_CCY' ] )
        mtables = pd.merge( mtables , ccy , how = 'left' , on = 'C_CCY' , suffixes = ( '' , '' ) )
        mtables['R_Prob_Rpt'] = mtables['C_Cat_Rpt'].apply( lambda x : [j[-1] for i in self.__product for j in i[-1] if j[0] == x][0] )
        mtables['R_Prob_RptCcy'] = mtables['R_Prob_CCY'] * mtables['R_Prob_Rpt']
        mtables = pd.merge( mtables , mtables.groupby(['C_Cat_Rpt'],as_index=False)['C_Prod_Code'].count() , how = 'left' , on = 'C_Cat_Rpt' , suffixes = ( '' , '_cnt' ) )
        mtables['R_Prob_RptCust'] = mtables['R_Prob_Rpt'] * mtables['R_Prob_CCY'] / mtables['C_Prod_Code_cnt']
        #mtables.drop( columns = ['C_ProdCode_cnt'] )

        #900.   Purge.
        l_mtables , lst_out , ccy = None , None , None
        pci_pre , pci_name , pci_issue , pci_ccy , pci_ccy_to , pci_type = None , None , None , None , None , None

        #990.   Return
        return( mtables )
    #End of [__metaprod]

    #999.   Test the methods.
    @property
    def testmethod( self ) -> 'Test the methods from within the Class':
        cus_list : list = self.__crCustList( 300 )
        prodlist : list = [ np.random.randint( low = 2 , high = 5 ) for i in range(len(cus_list)) ]
        accts : pd.DataFrame = self.__cus_ACOpen( cus_list , prodlist , self.__metaprod_all )
        bal : pd.DataFrame = self.__crAcctBalance( 180000000 , accts )
        acct_bal : pd.DataFrame = pd.merge( accts , bal , how = 'left' , on = 'NC_ACCTNO' , suffixes = ( '' , '' ) )
        return( acct_bal )
    #End of [testmethod]
#End Class

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #100.   Create envionment.
    import datetime as dt
    import numpy as np
    import pandas as pd
    from omniPy.Dates import *
    ud = genPerfData( dt.datetime(2017,1,1) , dt.datetime(2017,12,31) )

    #200.   Create datasets.
    #210.   Create a dataset with sample size of 300 on a random working day within the provided period.
    dat1 = ud.genExampleDat( 300 )
    dat2 = ud.genExampleTxn( 300 )

    #211.   View the distribution o Relationship Open Dates.
    rel = dat1[[ 'NC_CIFNO' , 'DT_RelOpen' ]]
    rel['M_RelOpen'] = rel['DT_RelOpen'].apply( lambda x : dt.datetime.strftime(x,'%Y-%m') )
    reldf = rel.groupby('M_RelOpen').count()
#-Notes- -End-
"""