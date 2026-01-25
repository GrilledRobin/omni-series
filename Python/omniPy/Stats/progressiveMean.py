#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numpy as np
from collections.abc import Iterable

def progressiveMean(
    ignoreNan : bool = True
    ,ignoreInf : bool = True
) -> dict[str, float | int]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the mean value of the provided iterable of float numbers in a progressive way, i.e. batch by#
#   | batch, when the input iterable is too long, and also when any among the input numbers are near the edge of overflow               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Numeric elements of input iterable can be converted to <np.float64>, i.e. none of them causes overflow                         #
#   |[2] The state of current mean value of all previous batches of inputs cannot be modified                                           #
#   |[3] Mean value of all inputs does not cause overflow, which is obvious in terms of <1>                                             #
#   |[4] `(num / k / q).sum()` does not cause overflow, where                                                                           #
#   |    [1] <num> is any input batch converted to array                                                                                #
#   |    [2] <k> is the cumulated number of elements before current step (or 1 if this batch is the first one)                          #
#   |    [3] <q> is defined as: <(1 if k else 0) + (k1 / (k or 1))>, where                                                              #
#   |        [1] <k1> is the number of elements provided in current batch                                                               #
#   |[5] Total number of input elements does not cause overflow, i.e. we only get mean value of finite number of floats                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ignoreNan         :   <bool    > Whether to ignore np.nan values                                                                   #
#   |                      [True                ]<Default> Ignore <np.nan> values                                                       #
#   |                      [False               ]          Causes the result to be <np.nan> when input contains invalid value           #
#   |ignoreInf         :   <bool    > Whether to ignore <np.Inf> and <-np.Inf> values                                                   #
#   |                      [True                ]<Default> Ignore <np.Inf> and <-np.Inf> values                                         #
#   |                      [False               ]          Causes the progressive result to be <np.Inf> or <-np.Inf> when input contains#
#   |                                                       infinite values                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |910.   Yield Values by position.                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>            :   <dict    > holding below keys and values:                                                                    #
#   |                      [mean    ]<float   > Mean value calculated progressively until current stop                                  #
#   |                      [k       ]<int     > Number of elements involved progressively until current stop                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20251115        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1                                                                                                                   #
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
#   |   |sys, numpy, collections                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(ignoreNan, bool):
        ignoreNan = True
    if not isinstance(ignoreInf, bool):
        ignoreInf = True

    #050. Initialization
    cum_mean, cum_k = None, 0

    #500. Reduce the calculation
    while True:
        #010. Start the engine and prepare to receive the input numbers
        num : int | float | np.int_ | np.float_ | Iterable[int | float | np.int_ | np.float_] = yield {
            'mean' : cum_mean
            ,'k' : cum_k
        }

        #011. Reset the generator if None is received
        if num is None:
            cum_mean, cum_k = None, 0
            continue

        #012. Parameter buffer
        if isinstance(num, Iterable):
            num_ = np.array(num, dtype = np.float64)
        elif isinstance(num, (int, float, np.int_, np.float_)):
            num_ = np.array([num], dtype = np.float64)
        else:
            raise TypeError(f'[{LfuncName}]<num> should be Iterable of float numbers, provided: {type(num)}')
        if num_.ndim > 1:
            raise ValueError(f'[{LfuncName}]Can only process 1-D array!')
        f_cum_k = float(cum_k)

        if ignoreNan:
            num_ = num_[~np.isnan(num_)]
        if ignoreInf:
            num_ = num_[~np.isinf(num_)]

        #100. Skip progression if current provision is empty
        if (curr_k := len(num_)) == 0:
            continue
        f_curr_k = float(curr_k)

        #500. Apply the algorithm
        # Basic formula: (
        #         prev_mean * k_prev_cum + curr_mean * curr_k
        #     ) / (
        #         k_prev_cum + curr_k
        #     )
        # To prevent overflow
        #[1] We divide both sides by <k_prev_cum>
        #[2] We split the numerator into two parts
        denom = (1.0 if f_cum_k else 0.0) + (f_curr_k / (f_cum_k or 1.0))

        mean_part1 = (cum_mean or 0.0) / denom
        mean_part2 = (num_ / (f_cum_k or 1.0) / denom).sum()
        cum_mean = mean_part1 + mean_part2

        #700. Increment the counter
        cum_k += curr_k
#End progressiveMean

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import os
    import sys
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import ExpandSignature
    from omniPy.AdvDB import DataIO
    from omniPy.Stats import progressiveMean

    cwd = os.getcwd()

    #100. Direct call
    def demo_basic_usage():
        """ Basic Usage """
        print('=== Basic Usage ===')

        #100. Setup generator
        avg_gen = progressiveMean()

        #200. Activation
        next(avg_gen)

        #500. Prepare source data
        data_points = [10, 20, 30, 40, 50]

        #700. Send data and collect the result
        for data in data_points:
            current_avg = avg_gen.send(data)
            print(f'Add data: {data}, result: {current_avg}')

    demo_basic_usage()
    # === Basic Usage ===
    # Add data: 10, result: {'mean': 10.0, 'k': 1}
    # Add data: 20, result: {'mean': 15.0, 'k': 2}
    # Add data: 30, result: {'mean': 20.0, 'k': 3}
    # Add data: 40, result: {'mean': 25.0, 'k': 4}
    # Add data: 50, result: {'mean': 30.0, 'k': 5}

    #200. Test reset feature
    def demo_reset_feature():
        """ Demo for Resetting """
        print('\n=== Demo for Resetting ===')

        #100. Activate the generator
        avg_gen = progressiveMean()
        next(avg_gen)

        #300. Send the first batch of data
        data1 = [5, 10, 15]
        for data in data1:
            current_avg = avg_gen.send(data)
            print(f'Group1 - Add data: {data}, result: {current_avg}')

        #500. Reset the generator
        print('Resetting ...')
        avg_gen.send(None)

        #700. Send another batch and calculate from scratch
        data2 = [2, 4, 6, 8]
        for data in data2:
            current_avg = avg_gen.send(data)
            print(f'Group2 - Add data: {data}, result: {current_avg}')

    demo_reset_feature()
    # === Demo for Resetting ===
    # Group1 - Add data: 5, result: {'mean': 5.0, 'k': 1}
    # Group1 - Add data: 10, result: {'mean': 7.5, 'k': 2}
    # Group1 - Add data: 15, result: {'mean': 10.0, 'k': 3}
    # Resetting ...
    # Group2 - Add data: 2, result: {'mean': 2.0, 'k': 1}
    # Group2 - Add data: 4, result: {'mean': 3.0, 'k': 2}
    # Group2 - Add data: 6, result: {'mean': 4.0, 'k': 3}
    # Group2 - Add data: 8, result: {'mean': 5.0, 'k': 4}

    #300. Wrapped with a tracker
    def demo_advanced_usage():
        """ Advanced Usage """
        print('\n=== Advanced Usage ===')

        #100. Define a tracker class
        class AverageTracker:
            """ Class to track the progressive mean """

            def __init__(self):
                self.gen = progressiveMean()
                next(self.gen)

            def add_data(self, value):
                """ Add data and return the latest result """
                return self.gen.send(value)

            def reset(self):
                """ Reset counter """
                self.gen.send(None)
                return self

            def get_stats(self):
                """ Get additional status (need design) """
                # This function will retrieve more additional information at runtime
                pass

        #300. Encapsulate the function
        tracker = AverageTracker()

        #500. Track the batch of data
        test_data = [1.5, 2.5, 3.5, 4.5, 5.5]
        for i, data in enumerate(test_data, 1):
            avg = tracker.add_data(data)
            print(f'Add data at step {i}: {data}, latest result: {avg}')

    demo_advanced_usage()
    # === Advanced Usage ===
    # Add data at step 1: 1.5, latest result: {'mean': 1.5, 'k': 1}
    # Add data at step 2: 2.5, latest result: {'mean': 2.0, 'k': 2}
    # Add data at step 3: 3.5, latest result: {'mean': 2.5, 'k': 3}
    # Add data at step 4: 4.5, latest result: {'mean': 3.0, 'k': 4}
    # Add data at step 5: 5.5, latest result: {'mean': 3.5, 'k': 5}

    #400. Error handling
    def demo_with_error_handling():
        """ Error Handling """
        print('\n=== Error Handling ===')

        #100. Activate the generator
        avg_gen = progressiveMean()
        next(avg_gen)

        try:
            #100. Send correct data
            print(f'Add 10: {avg_gen.send(10)}')
            print(f'Add 20: {avg_gen.send(20)}')

            #500. Send character string to trigger numpy error
            print(f'Add string: {avg_gen.send("invalid")}')

        except Exception as e:
            print(f'Exception captured: {e}')

        finally:
            #900. Close the generator as garbage collection
            avg_gen.close()
            print('Generator closed')

    demo_with_error_handling()
    # === Error Handling ===
    # Add 10: {'mean': 10.0, 'k': 1}
    # Add 20: {'mean': 15.0, 'k': 2}
    # Exception captured: could not convert string to float: 'invalid'
    # Generator closed

    #500. Expand its signature with flexibility
    @(eSig := ExpandSignature(progressiveMean))
    def gen_cum_info(user : str, *pos, **kw):
        #100. Verify arguments passed to <progressiveMean>
        args_share = {}
        eSig.vfyConflict(args_share)

        #200. Reshape the parameters passed for the call to <progressiveMean>
        pos_int, kw_int = eSig.insParams(args_share, pos, kw)

        #300. Setup the generator
        inner_gen = eSig.src(*pos_int, **kw_int)

        #500. Handle the values
        try:
            inner_value = inner_gen.__next__()
            while True:
                try:
                    # yield current result and obtain the `send()` inputs
                    received_msg = yield inner_value

                    # Print the message to send for processing
                    print(f'<{user}> sending: {received_msg}')

                    if received_msg is not None:
                        inner_value = inner_gen.send(received_msg)
                    else:
                        inner_value = inner_gen.__next__()
                except StopIteration as e:
                    print('outer_generator end')
                    return e.value
        except Exception as e:
            inner_gen.close()
            raise e

    def demo_gen_cum_info():
        """ Demo for Nesting """
        print('\n=== Demo for Nesting ===')

        #100. Activate the generator
        avg_gen = gen_cum_info('User A')
        next(avg_gen)

        #300. Send the first batch of data
        data1 = [1,2,3,4,5]
        current_avg = avg_gen.send(data1)
        print(f'Group1 - Add data: {data1}, result: {current_avg}')

        #500. Send the second batch of data
        data2 = [6,7,8,9]
        current_avg = avg_gen.send(data2)
        print(f'Group1 - Add data: {data2}, result: {current_avg}')

        avg_gen.close()

    demo_gen_cum_info()
    # === Demo for Nesting ===
    # <User A> sending: [1, 2, 3, 4, 5]
    # Group1 - Add data: [1, 2, 3, 4, 5], result: {'mean': 3.0, 'k': 5}
    # <User A> sending: [6, 7, 8, 9]
    # Group1 - Add data: [6, 7, 8, 9], result: {'mean': 5.0, 'k': 9}

    #600. Bind it to the generalized Data I/O Tool
    #610. Make a copy of the generator function for recognition by the tool
    std_prog_mean = progressiveMean

    #620. Helper function to print additional message in the log for any `send()` message
    def addLog(msg):
        print(f'Received {msg=}')
        return(msg)

    #630. Setup the Data I/O Tool
    #[1] Print extra message when sending data to the generator
    #[2] Format the result into proper string and drop <k> as intention
    dataIO = DataIO(
        apiPkgPull = None
        ,apiPfxPull = 'std_prog_'
        ,apiPullYldHdl = {
            'mean' : lambda x: f'{val:.5f}' if isinstance(val := x.get("mean"), float) else None
        }
        ,apiPullSendHdl = {
            'mean' : addLog
        }
    )
    dataIO.add('mean')

    def demo_gen_dataIO():
        """ Demo for DataIO Usage """
        print('\n=== Demo for DataIO Usage ===')

        #100. Activate the generator
        avg_gen = dataIO['mean'].pull()
        next(avg_gen)

        #300. Send the first batch of data
        data1 = [1,2,3,4,5]
        current_avg = avg_gen.send(data1)
        print(f'Group1 - Add data: {data1}, result: {current_avg}')

        #500. Send the second batch of data
        data2 = [6,7,8,9]
        current_avg = avg_gen.send(data2)
        print(f'Group2 - Add data: {data2}, result: {current_avg}')

        #700. Send an empty list
        data3 = []
        current_avg = avg_gen.send(data3)
        print(f'Group3 - Add data: {data3}, result: {current_avg}')

        avg_gen.close()

    demo_gen_dataIO()
    # === Demo for DataIO Usage ===
    # Received msg=[1, 2, 3, 4, 5]
    # Group1 - Add data: [1, 2, 3, 4, 5], result: 3.00000
    # Received msg=[6, 7, 8, 9]
    # Group2 - Add data: [6, 7, 8, 9], result: 5.00000
    # Received msg=[]
    # Group3 - Add data: [], result: 5.00000

    #700. Calculate progressive mean from a large file of data points
    outf1 = os.path.join(cwd, 'test.txt')
    with open(outf1, 'w', encoding = 'utf-8') as f:
        for v in ['20','20','','50']:
            f.write(f'{v}\n')

    def getAvg(file : str):
        BUFFER_SIZE = 3
        # It is detected that the real number of records read from the file is as below
        len_rec = BUFFER_SIZE - 1

        fstream = open(file, encoding = 'utf-8')
        data_raw = fstream.readlines(BUFFER_SIZE)

        #100. Activate the generator
        #[1] One ignores the np.nan values, the other does not
        avg_gen1 = progressiveMean(ignoreNan = False)
        next(avg_gen1)
        avg_gen2 = progressiveMean()
        next(avg_gen2)

        while data_raw:
            data_proc = [ np.nan if v == '\n' else v for v in data_raw ]
            data_num = np.array(data_proc, dtype = np.float64)
            data_avg = avg_gen1.send(data_num)
            data_avg2 = avg_gen2.send(data_num)
            print(f'Add data: {data_num}, result: {data_avg}')
            data_raw = fstream.readlines(BUFFER_SIZE)

        fstream.close()
        avg_gen1.close()
        avg_gen2.close()

        print(f'Result ignoring NaN inputs: {data_avg2}')

        return(data_avg)

    print(f'final result: {getAvg(outf1)}')
    # Add data: [20. 20.], result: {'mean': 20.0, 'k': 2}
    # Add data: [nan 50.], result: {'mean': nan, 'k': 4}
    # Result ignoring NaN inputs: {'mean': 30.0, 'k': 3}
    # final result: {'mean': nan, 'k': 4}

    #790. Clean up
    if os.path.isfile(outf1): os.remove(outf1)
'''
