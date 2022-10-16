@echo off
title Python Installation Batch
@set CurDir=%~dp0

::Dependency for [pandas]
::An upgrade of [numpy] is a must, or the BAT call for Python will fail!
::UserWarning: mkl-service package failed to import
pip install numpy==1.23.4
pip install tables==3.6.1
pip install numexpr==2.8.1
pip install pandas==1.4.2

pip install scipy==1.9.2

::Dependency for [pathos]
::pip install dill>=0.3.5.1
::pip install ppft>=1.7.6.5
::pip install pox>=0.3.1
::pip install multiprocess>=0.70.13
pip install pathos==0.2.9

::Dependency for [pyecharts]
::pip install simplejson>=3.17.6
::pip install prettytable>=3.4.1
pip install pyecharts==1.9.1

pip install pygame==2.1.2
pip install pynput==1.7.6
pip install pyreadstat==1.1.9
pip install pywin32==304
pip install scikit_learn==1.1.2
pip install xlwings==0.27.15

::Dependency for [requests]
pip install pathlib>=1.0.1
pip install ruamel.yaml.clib==0.2.6
pip install ruamel-yaml==0.17.21
pip install requests==2.28.1

::Dependency for [selenium]
::pip install h11<1,>=0.9.0
::pip install wsproto>=0.14
::pip install exceptiongroup>=1.0.0rc9
::pip install async-generator>=1.9
::pip install outcome>=1.2.0
::pip install trio-websocket~=0.9
::pip install trio~=0.17
pip install selenium==4.5.0

pip install beautifulsoup4==4.11.1
pip install h5py==3.7.0

::Dependency for [progressbar2]
pip install python-utils==3.3.3
pip install progressbar2==4.0.0

@pause
@echo on