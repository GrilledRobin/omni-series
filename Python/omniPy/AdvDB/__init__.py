#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001.   Import necessary functions for processing.

#print( 'Importing [' + os.path.dirname( os.path.abspath(__file__) ) + ']' )

#100.   Import the local modules.
#[IMPORTANT] The sequence of below statements should align the dependency tree,
#             i.e. the definition of the latter function depends on the former one
from .wrapAsGroupedFunc import wrapAsGroupedFunc
from .validateDMCol import validateDMCol
from .parseHDFStoreInfo import parseHDFStoreInfo
from .loadSASdat import loadSASdat
from .std_read_HDFS import std_read_HDFS
from .std_read_RAM import std_read_RAM
from .std_read_SAS import std_read_SAS
from .parseDatName import parseDatName
from .OpenSourceApiMeta import OpenSourceApiMeta

from .inferContents import inferContents
from .writeSASdat import writeSASdat
from .std_write_HDFS import std_write_HDFS
from .std_write_RAM import std_write_RAM
from .std_write_SAS import std_write_SAS
from .DataIO import DataIO
from .aggrByPeriod import aggrByPeriod
from .DBuse_SetKPItoInf import DBuse_SetKPItoInf
from .DBuse_MrgKPItoInf import DBuse_MrgKPItoInf
from .DBuse_GetTimeSeriesForKpi import DBuse_GetTimeSeriesForKpi

from .kfCore_ts_agg import kfCore_ts_agg
from .kfFunc_ts_mtd import kfFunc_ts_mtd
from .kfFunc_ts_roll import kfFunc_ts_roll
from .kfFunc_ts_fullmonth import kfFunc_ts_fullmonth

#200.   Define available resources.
__all__ = [
    'DBuse_MrgKPItoInf', 'DBuse_SetKPItoInf', 'DBuse_GetTimeSeriesForKpi'
    , 'parseHDFStoreInfo', 'validateDMCol'
    , 'loadSASdat', 'std_read_HDFS', 'std_read_RAM', 'std_read_SAS'
    , 'aggrByPeriod'
    , 'parseDatName'
    , 'OpenSourceApiMeta', 'wrapAsGroupedFunc'
    , 'inferContents', 'writeSASdat', 'std_write_HDFS', 'std_write_RAM', 'std_write_SAS', 'DataIO'
    , 'kfCore_ts_agg'
    , 'kfFunc_ts_mtd', 'kfFunc_ts_roll', 'kfFunc_ts_fullmonth'
]
