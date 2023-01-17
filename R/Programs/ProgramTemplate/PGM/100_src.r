#Below function is from [main.r]
logger.info('step 1')
#> INFO: 2021-06-30 11:21:13 step 1

#Below message is NOT captured by [withCallingHandlers], only shows in command console
print('test print')

#Below message is captured by [withCallingHandlers]
message('test info')
#> INFO: 2021-06-30 11:21:13 test info

#Below message is captured by [withCallingHandlers]
warning('test warning')
#> WARN: 2021-06-30 11:21:13 test warning

logger.warning('warning from my_logger')
#> WARN: 2021-06-30 11:21:13 warning from my_logger
