

@echo off


SET ORICUTRON="D:\Users\plifp\Onedrive\oric\oricutron_twilighte"


SET ORIGIN_PATH=%CD%

SET ROM=filesys

%CC65%\ca65.exe -ttelestrat --include-dir %CC65%\asminc\ src/%ROM%.asm -o %ROM%.ld65  
%CC65%\ld65.exe -tnone  %ROM%.ld65 -o %ROM%.rom 





IF "%1"=="NORUN" GOTO End
rem mkdir %ORICUTRON%\sdcard\usr\share\filesys\
copy %ROM%.rom %ORICUTRON%\sdcard\usr\share\filesys > NUL
copy %ROM%.rom %ORICUTRON%\roms > NUL

cd %ORICUTRON%

oricutron

:End
cd %ORIGIN_PATH%

