#!/usr/bin/env python3
# -*- coding: utf-8 -*-

logger.info('pandas operation')
import pandas as pd
import numpy as np
from functools import partial

#100. Create testing data
rng = np.random.default_rng()
dat_raw = pd.DataFrame({
    'key' : ['a','b','c','e','d']
    ,'val' : rng.random(5)
})
dat_mrg = pd.DataFrame({
    'key' : ['a','c','f']
    ,'val2' : rng.random(3)
    ,'val4' : rng.random(3)
    ,'val6' : rng.random(3)
})

#200. Merge without using <pd.merge>
#[SCENARIO]
#[1] Merge several columns from large data <a> to large data <b> where <a> has lots of columns than the selected ones
#[ASSUMPTION]
#[1] <pd.merge> causes both dataframe to sort by keys on-the-fly, thus leads to terrible slowness
#[2] <reindex> method is a good replacement of <pd.merge> due to high performance
#210. Helper function to extract a column <col> from <indat> and assign it to the dedicated <df>, matching by <'key'> column
def mrgAssign(df : pd.DataFrame, indat : pd.DataFrame, col : str, fillval = None):
    rstOut = (
        indat
        .set_index('key')
        .reindex(df['key'])
        .set_index(df.index)
        .loc[:, col]
        .fillna(fillval)
    )
    return(rstOut)

#230. Mapper to merge columns in <dat_mrg> to <dat_raw> and fill values when empty
mapper_cols = {
    'val2' : np.inf
    ,'val6' : -1
}

#290. Merge the data by mappers
#[ASSUMPTION]
#[1] We have to create dynamic number of columns at one step for one dataframe
#[2] If we use <lambda>, we create a closure within the <dict comprehension> that locks the value of input <k>,
#     that is why the values of all created columns become the same
#[3] We then introduce an external function and pass <k> as argument to avoid creation of closures
rst_mrg = (
    dat_raw
    .assign(**{
        k : partial(mrgAssign, indat = dat_mrg, col = k, fillval = v)
        for k,v in mapper_cols.items()
    })
)
