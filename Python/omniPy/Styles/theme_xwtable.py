#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import xlwings as xw
from xlwings.constants import LineStyle as xwLS
from xlwings.constants import BordersIndex as xwBI
from xlwings.constants import BorderWeight as xwBW
from xlwings.constants import VAlign as xwVA
from functools import reduce
from copy import deepcopy

def theme_xwtable(
    theme : str = 'BlackGold'
) -> 'Create the theme for the EXCEL range defined by xlwings during exporting pd.DataFrame':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create the theme for the EXCEL range defined by xlwings during exporting pd.DataFrame                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Create universal styles when exporting multiple data frames into EXCEL                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |theme       :   Predefined name to be created                                                                                      #
#   |                [BlackGold   ] <Default> Default theme                                                                             #
#   |                [SAS         ]           Similar theme as SAS TABULATE Procedure                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   Nested dict containing various attributes to be set for the EXCEL ranges                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20221029        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, xlwings, functools, copy                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer

    #050. Local parameters
    #This defines the sequence to apply the styles, hence the latter overwrites the former
    themes = {}
    #[ASSUMPTION]
    #[1] [attr], [val] and [args] are the arguments to the function [omniPy.AdvOp.rsetattr]

    #100. Black Gold
    color_dark = '#202122'
    color_light = '#FFE8CB'
    themes['BlackGold'] = {}
    themes['BlackGold']['table'] = {
        '.'.join(['Borders',m,'LineStyle']) : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlLineStyleNone
            ,'args' : {
                'api.Borders' : {
                    'pos' : (getattr(xwBI, m),)
                }
            }
        }
        for m in dir(xwBI)
        if m[:2] == 'xl' and m not in ['xlDiagonalDown','xlDiagonalUp']
    }
    #This is to provide compatibility to [Python < 3.8]
    themes['BlackGold']['table'] = {**themes['BlackGold']['table'], **{
        'background_color' : {
            'attr' : 'color'
            ,'val' : xw.utils.hex_to_rgb(color_dark)
        }
        ,'Font.Color' : {
            'attr' : 'api.Font.Color'
            #[IMPORTANT] This value must be converted to [int] for above API [xlwings <= 0.27.15]
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_light))
        }
        ,'Font.Name' : {
            'attr' : 'api.Font.Name'
            ,'val' : 'Microsoft YaHei UI'
        }
    }}

    themes['BlackGold']['data.int'] = {
        'NumberFormat' : {
            'attr' : 'api.NumberFormat'
            ,'val' : '_( * #,##0_) ;_ (* #,##0)_ ;_( * "-"??_) ;_ @_ '
        }
    }

    themes['BlackGold']['data.float'] = {
        'NumberFormat' : {
            'attr' : 'api.NumberFormat'
            ,'val' : '_( * #,##0.00_) ;_ (* #,##0.00)_ ;_( * "-"??_) ;_ @_ '
        }
    }

    themes['BlackGold']['box'] = {
        'Borders.xlEdgeBottom.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlContinuous
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeBottom,)
                }
            }
        }
        ,'Borders.xlEdgeBottom.Weight' : {
            'attr' : 'api.Borders.Weight'
            ,'val' : xwBW.xlThin
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeBottom,)
                }
            }
        }
        ,'Borders.xlEdgeBottom.Color' : {
            'attr' : 'api.Borders.Color'
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_light))
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeBottom,)
                }
            }
        }
        ,'Font.Bold' : {
            'attr' : 'api.Font.Bold'
            ,'val' : True
        }
    }

    themes['BlackGold']['header'] = {
        'Borders.xlEdgeBottom.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlContinuous
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeBottom,)
                }
            }
        }
        ,'Borders.xlEdgeBottom.Weight' : {
            'attr' : 'api.Borders.Weight'
            ,'val' : xwBW.xlThin
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeBottom,)
                }
            }
        }
        ,'Borders.xlEdgeBottom.Color' : {
            'attr' : 'api.Borders.Color'
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_light))
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeBottom,)
                }
            }
        }
        ,'Borders.xlInsideVertical.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlContinuous
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlInsideVertical,)
                }
            }
        }
        ,'Borders.xlInsideVertical.Weight' : {
            'attr' : 'api.Borders.Weight'
            ,'val' : xwBW.xlThin
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlInsideVertical,)
                }
            }
        }
        ,'Borders.xlInsideVertical.Color' : {
            'attr' : 'api.Borders.Color'
            #rgba2rgb('#FFE8CB', alpha_in = 0.5, color_bg = '#202122')
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#8F8476'))
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlInsideVertical,)
                }
            }
        }
        ,'Font.Bold' : {
            'attr' : 'api.Font.Bold'
            ,'val' : True
        }
    }

    themes['BlackGold']['index'] = {
        'Font.Bold' : {
            'attr' : 'api.Font.Bold'
            ,'val' : True
        }
    }

    themes['BlackGold']['stripe'] = {
        'background_color' : {
            'attr' : 'color'
            #rgba2rgb('#FFE8CB', alpha_in = 0.1, color_bg = '#202122')
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#363432'))
        }
    }

    #Ranges expanded from the vertically merged index levels
    themes['BlackGold']['index.merge'] = {
        'Borders.xlEdgeTop.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlContinuous
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeTop,)
                }
            }
        }
        ,'Borders.xlEdgeTop.Weight' : {
            'attr' : 'api.Borders.Weight'
            ,'val' : xwBW.xlThin
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeTop,)
                }
            }
        }
        ,'Borders.xlEdgeTop.Color' : {
            'attr' : 'api.Borders.Color'
            #rgba2rgb('#FFE8CB', alpha_in = 0.5, color_bg = '#202122')
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#8F8476'))
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeTop,)
                }
            }
        }
        ,'VerticalAlignment' : {
            'attr' : 'api.VerticalAlignment'
            ,'val' : xwVA.xlVAlignTop
        }
    }

    #Ranges expanded from the horizontally merged column levels
    themes['BlackGold']['header.merge'] = {
        'Borders.xlEdgeLeft.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlContinuous
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeLeft,)
                }
            }
        }
        ,'Borders.xlEdgeLeft.Weight' : {
            'attr' : 'api.Borders.Weight'
            ,'val' : xwBW.xlHairline
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeLeft,)
                }
            }
        }
        ,'Borders.xlEdgeLeft.Color' : {
            'attr' : 'api.Borders.Color'
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_light))
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeLeft,)
                }
            }
        }
        ,'VerticalAlignment' : {
            'attr' : 'api.VerticalAlignment'
            ,'val' : xwVA.xlVAlignTop
        }
    }

    #Ranges when [index] is not to be exported
    themes['BlackGold']['index.False'] = {
        'Borders.xlEdgeLeft.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlLineStyleNone
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeLeft,)
                }
            }
        }
    }

    #Ranges when [columns] is not to be exported
    themes['BlackGold']['header.False'] = {
        'Borders.xlEdgeTop.LineStyle' : {
            'attr' : 'api.Borders.LineStyle'
            ,'val' : xwLS.xlLineStyleNone
            ,'args' : {
                'api.Borders' : {
                    'pos' : (xwBI.xlEdgeTop,)
                }
            }
        }
    }

    #200. SAS TABULATE Procedure default theme
    color_dark = '#000000'
    color_light = '#FFFFFF'
    themes['SAS'] = {}
    themes['SAS']['table'] = reduce(lambda d1,d2: {**d1,**d2}, [
        {
            '.'.join(['Borders',m,'LineStyle']) : {
                'attr' : 'api.Borders.LineStyle'
                ,'val' : xwLS.xlContinuous
                ,'args' : {
                    'api.Borders' : {
                        'pos' : (getattr(xwBI, m),)
                    }
                }
            }
            ,'.'.join(['Borders',m,'Weight']) : {
                'attr' : 'api.Borders.Weight'
                ,'val' : xwBW.xlThin
                ,'args' : {
                    'api.Borders' : {
                        'pos' : (getattr(xwBI, m),)
                    }
                }
            }
            ,'.'.join(['Borders',m,'Color']) : {
                'attr' : 'api.Borders.Color'
                ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#C1C1C1'))
                ,'args' : {
                    'api.Borders' : {
                        'pos' : (getattr(xwBI, m),)
                    }
                }
            }
        }
        for m in dir(xwBI)
        if m[:2] == 'xl' and m not in ['xlDiagonalDown','xlDiagonalUp']
    ])
    #This is to provide compatibility to [Python < 3.8]
    themes['SAS']['table'] = {**themes['SAS']['table'], **{
        'Font.Name' : {
            'attr' : 'api.Font.Name'
            ,'val' : 'Microsoft YaHei UI'
        }
    }}

    themes['SAS']['data.int'] = {
        'NumberFormat' : {
            'attr' : 'api.NumberFormat'
            ,'val' : '_( * #,##0_) ;_ (* #,##0)_ ;_( * "-"??_) ;_ @_ '
        }
    }

    themes['SAS']['data.float'] = {
        'NumberFormat' : {
            'attr' : 'api.NumberFormat'
            ,'val' : '_( * #,##0.00_) ;_ (* #,##0.00)_ ;_( * "-"??_) ;_ @_ '
        }
    }

    themes['SAS']['box'] = {
        'background_color' : {
            'attr' : 'color'
            ,'val' : xw.utils.hex_to_rgb('#EDF2F9')
        }
        ,'Font.Color' : {
            'attr' : 'api.Font.Color'
            #[IMPORTANT] This value must be converted to [int] for above API [xlwings <= 0.27.15]
            ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#112277'))
        }
        ,'Font.Bold' : {
            'attr' : 'api.Font.Bold'
            ,'val' : True
        }
    }

    themes['SAS']['header'] = deepcopy(themes['SAS']['box'])

    themes['SAS']['index'] = deepcopy(themes['SAS']['box'])

    #Ranges expanded from the vertically merged index levels
    themes['SAS']['index.merge'] = {
        'VerticalAlignment' : {
            'attr' : 'api.VerticalAlignment'
            ,'val' : xwVA.xlVAlignTop
        }
    }

    #Ranges expanded from the horizontally merged column levels
    themes['SAS']['header.merge'] = {
        'VerticalAlignment' : {
            'attr' : 'api.VerticalAlignment'
            ,'val' : xwVA.xlVAlignTop
        }
    }

    #900. Export
    return(themes.get(theme, {}))
#End theme_xwtable

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Styles import theme_xwtable

    #100. Obtain the default theme
    utheme = theme_xwtable()

#-Notes- -End-
'''
