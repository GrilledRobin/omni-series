#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def getMemberByStrPattern(
    inDIR : str
    ,inRegExp : str
    ,exclRegExp : str = r"^$"
    ,chkType : int = 1
    ,FSubDir : bool = False
):
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to search for specific files or sub-folders under given folder name by given matching rule with respect  #
#   | of Regular Expression.                                                                                                            #
#   |The switch [FSubDir] is intended to define whether to search for ALL sub-directories by infinite recursion.                        #
#   |Documents for Regular Expressions are placed on the website: https://docs.python.org/3.6/library/re.html                           #
#   |Documents for [os.path] are placed on the website: https://docs.python.org/3/library/os.path.html                                  #
#   |Documents for [collections] are placed on the website: https://docs.python.org/3.6/library/collections.html                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDIR      :   Directory name under which files or sub-directories should be searched.                                             #
#   |               IMPORTANT: If only a Driver Name is to be provided, make sure it is provided as: r'X:\ ' (Note the White Space)     #
#   |inRegExp   :   Matching rule of character combination.                                                                             #
#   |exclRegExp :   Excluding rule of character combination.                                                                            #
#   |chkType    :   0 - both files and directories, 1 - files, 2 - directories.                                                         #
#   |FSubDir    :   [False] - find members in current directory, [True] - search in all sub-directories.                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Out_Rst    :   Output list storing all the members found: [ [ Elements<1> ] , [ Elements<2> ] , ... ]                              #
#   |               <Elements for each member>                                                                                          #
#   |               FullPath<n> :   Absolute Path Name of the member (including the member full name)                                   #
#   |               MemType<n>  :   Type of member, 1 - File, 2 - Directory                                                             #
#   |               Name<n>     :   Name of member, including the extension if it is a File                                             #
#   |               cTime<n>    :   Create Time of the member                                                                           #
#   |               mTime<n>    :   Last Modified Time of the member                                                                    #
#   |               PathSize<n> :   The size in bytes of the member                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20180107        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200517        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the function [os.walk] with the user-defined function itself as recursion as mentioned by below article, to     #
#   |      | increasethe overall efficiency.                                                                                            #
#   |      | Quote: https://stackoverflow.com/questions/18394147/recursive-sub-folder-search-and-return-files-in-a-list-python          #
#   |      | See the #5th answer of above article for speed comparison                                                                  #
#   |      |[2] Remove the [AbsPath<n>] and [RelPath<n>] from the output list as they are obselete during usage                         #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, re, os, collections                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Import necessary functions for processing.
    #from imp import find_module
    import sys
    import re
    import os
    import collections as clt

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = "ERROR: [" + LfuncName + "]Process failed due to errors!"

    #012.   Handle the parameter buffer.
    if len(inDIR.strip()) == 0:
        raise ValueError( "[" + LfuncName + "]No Folder is given for search of files! Program is interrupted!" )
    if len(inRegExp.strip()) == 0:
        print( "NOTE: [" + LfuncName + "]No pattern is specified for file search, program will find all files in given folder: [" + inDIR + "]." )
        inRegExp = r".*"
    if len(exclRegExp.strip()) == 0:
        exclRegExp = r"^$"
    if chkType not in [ 0 , 1 , 2 ]:
        print( "NOTE: [" + LfuncName + "]No type is specified. Program will search for files instead of directories." )
        chkType = 1
    if not isinstance( FSubDir , bool ):
        raise TypeError( '[' + LfuncName +  ']Parameter [FSubDir] should be of the type [bool]! Type of input value is [{0}]'.format( type(FSubDir) ) )

    #013.   Define the local environment.
    #Since the list is to be extended within the Generator, we use [deque] to improve the performance of [append()].
    Out_Rst = clt.deque([])
    Mem_Type : int
    reIN = re.compile( inRegExp.strip() , re.I | re.M | re.S | re.X )
    reEX = re.compile( exclRegExp.strip() , re.I | re.M | re.S | re.X )

    #200.   Prepare the elements of the output list by going through the directory tree.
    for f in os.scandir(inDIR.strip()):
        #100.   Determine the type of the member.
        Mem_Type = 1 if f.is_file() else 2 if f.is_dir() else 0

        #300.   Append the dedicated members to the element in the output list.
        if chkType == 0 or Mem_Type == chkType:
            if not reEX.search( f.name ):
                if reIN.search( f.name ):
                    #900.   Append the member.
                    Out_Rst.append(
                        [
                            f.path
                            , Mem_Type
                            , f.name
                            , os.path.getctime( f.path )
                            , os.path.getmtime( f.path )
                            , os.path.getsize( f.path )
                        ]
                    )
                #End If
            #End If
        #End If

        #900.   Continue the generation if the behavior as implied by [FSubDir] is set to True while current member is a directory.
        if FSubDir and Mem_Type == 2:
            #100.   Call itself as recursion to its sub-folders.
            subs = getMemberByStrPattern(
                f.path
                ,inRegExp
                ,exclRegExp
                ,chkType
                ,FSubDir
            )

            #900.   Extend the output result if anything is found in its sub-folders.
            Out_Rst.extend(subs)
    #End For

    #800.   Purge the memory usage.
    re.purge()

    #900.   Output.
    return( list(Out_Rst) )
#End getMemberByStrPattern

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import getMemberByStrPattern

    #100.   Look up files in current directory.
    PyLst = getMemberByStrPattern( r"D:\Python\Learning" , r".+\.py" )
    print( PyLst )

    #200.   Look up files in current directory and all its subdirectories.
    PyLst = getMemberByStrPattern( r"D:\Python" , r".+\.py" , FSubDir = True )
    print( PyLst )

    #300.   Print all files in current directory and all its subdirectories.
    print( getMemberByStrPattern( r"D:\Python\Learning" , "" , FSubDir = True ) )

    #400.   Look up files in an entire hard drive.
    #Please note the usage of the function [strip()].
    print( getMemberByStrPattern( r"E:\ ".strip() , r".+\.mp4" , FSubDir = True ) )

    #500.   Look up files by excluding the "testing" ones.
    print( getMemberByStrPattern( r"D:\Python\omniPy" , r".+\.py$" , exclRegExp = r'^test' , FSubDir = True ) )

    #600.   Look up all directory names.
    print( getMemberByStrPattern( r"D:\Python" , "" , chkType = 2 , FSubDir = True ) )
#-Notes- -End-
"""