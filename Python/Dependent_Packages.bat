@echo off
title Python Installation Batch
@set CurDir=%~dp0

pip install numpy==1.19.0
pip install scipy==1.5.1
pip install tables==3.6.1
pip install pandas==1.3.1
pip install numexpr==2.7.3
pip install pathos==0.2.7
pip install pyecharts==1.9.0
pip install pygame==1.9.6
pip install pynput==1.7.4
pip install pyreadstat==1.0.0
pip install pywin32==302
pip install scikit_learn==0.23.1
pip install xlwings==0.24.9
pip install requests==2.26.0
pip install selenium==4.0.0
pip install beautifulsoup4==4.10.0
pip install h5py==3.5.0
pip install progressbar2==3.55.0

@pause
@echo on