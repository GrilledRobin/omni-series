#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from shiny import module

def ns(id_ : module.Id = None) -> module.ResolvedId:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to expose the `id` of the web element created by `shiny.module`, so that one can manipulate it through   #
#   | external tools like JavaScript, to create more effects                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This function only works within a function that is created via the decorators `module.ui` or `module.server`                   #
#   |[2] ID of any web element within a `shiny.module` is created via the decorators `module.ui` or `module.server`                     #
#   |[3] We have to lookup its value (as a parameter input at the caller program) at runtime                                            #
#   |[4] Since the user defined UI/Server functions are already decorated, we have to further look backward once more along the frame   #
#   |     stack. So in this program, we look directly 2 frames back from current one                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |id_               :   <module.Id> Valid `module.Id` that represents an element in HTML, basically a character string               #
#   |                      [None                ] <Default> Parse the ID of current active module                                       #
#   |                      [<str>               ]           Parse the ID of the child element within current module                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<module.Id>       :   The resolved element ID within current session context in `shiny`                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260622        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |sys, shiny                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #100. Recognize the NameSpace (NS) of current web element
    if id_ is None:
        frame = sys._getframe(2)
        return(module.resolve_id(frame.f_locals.get('id')))
    else:
        return(module.resolve_id(id_))
#End ns

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp.Modules import ns
    print(ns.__doc__)

    #100. See <omniPy.ShinyApp.jsKeyShortcutListener> for detailed implementation of this function
#-Notes- -End-
'''
