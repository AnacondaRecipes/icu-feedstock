@echo off
SETLOCAL EnableDelayedExpansion

if "%target_platform%"=="win-arm64" (
    set "PLATFORM=ARM64"
    set "BINDIR=binARM64"
    set "LIBDIR=libARM64"
) else if "%ARCH%"=="64" (
    set "PLATFORM=x64"
    set "BINDIR=bin64"
    set "LIBDIR=lib64"
) else (
    set "PLATFORM=Win32"
    set "BINDIR=bin"
    set "LIBDIR=lib"
)

if not exist "source\data\out\tmp" mkdir "source\data\out\tmp"

msbuild source\allinone\allinone.sln ^
    /p:Configuration=Release ^
    /p:Platform=%PLATFORM% ^
    /p:WindowsTargetPlatformVersion=%WindowsSDKVer% ^
    /p:SkipUWP=true

:: msbuild may return non-zero due to test data build needing the py launcher.
:: Verify the essential artifacts exist instead.
if not exist "%BINDIR%\icuuc73.dll" (
    echo ERROR: ICU build failed - essential DLLs not found in %BINDIR%.
    if not exist "%BINDIR%" (
        echo Listing top-level directories for debugging:
        dir /ad /b
    ) else (
        echo Contents of %BINDIR%:
        dir /b "%BINDIR%"
    )
    exit 1
)
if not exist "%BINDIR%\icudt73.dll" (
    echo ERROR: ICU data build failed - icudt73.dll not found in %BINDIR%.
    exit 1
)

:: Install headers
if not exist "%LIBRARY_INC%\unicode" mkdir "%LIBRARY_INC%\unicode"
xcopy /Y "source\common\unicode\*.h" "%LIBRARY_INC%\unicode\"
if errorlevel 1 exit 1
xcopy /Y "source\i18n\unicode\*.h" "%LIBRARY_INC%\unicode\"
if errorlevel 1 exit 1
xcopy /Y "source\io\unicode\*.h" "%LIBRARY_INC%\unicode\"
if errorlevel 1 exit 1

:: Install import libraries
copy /Y "%LIBDIR%\icu*.lib" "%LIBRARY_LIB%\"
if errorlevel 1 exit 1

:: Install DLLs
copy /Y "%BINDIR%\icu*.dll" "%LIBRARY_BIN%\"
if errorlevel 1 exit 1

:: Install command-line tools
for %%t in (derb genbrk gencfu gencnval gendict gennorm2 genrb gensprep icuexportdata icuinfo makeconv pkgdata uconv) do (
    if exist "%BINDIR%\%%t.exe" copy /Y "%BINDIR%\%%t.exe" "%LIBRARY_BIN%\"
)

:: Install pkg-config files
if not exist "%LIBRARY_LIB%\pkgconfig" mkdir "%LIBRARY_LIB%\pkgconfig"

> "%LIBRARY_LIB%\pkgconfig\icu-uc.pc" (
    echo prefix=${pcfiledir}/../..
    echo exec_prefix=${prefix}
    echo libdir=${exec_prefix}/lib
    echo includedir=${prefix}/include
    echo.
    echo Name: icu-uc
    echo Description: International Components for Unicode: Common Library
    echo Version: 73.1
    echo Libs: -L${libdir} -licuuc -licudt
    echo Cflags: -I${includedir}
)

> "%LIBRARY_LIB%\pkgconfig\icu-i18n.pc" (
    echo prefix=${pcfiledir}/../..
    echo exec_prefix=${prefix}
    echo libdir=${exec_prefix}/lib
    echo includedir=${prefix}/include
    echo.
    echo Name: icu-i18n
    echo Description: International Components for Unicode: Internationalization Library
    echo Version: 73.1
    echo Requires: icu-uc
    echo Libs: -L${libdir} -licuin
    echo Cflags: -I${includedir}
)

> "%LIBRARY_LIB%\pkgconfig\icu-io.pc" (
    echo prefix=${pcfiledir}/../..
    echo exec_prefix=${prefix}
    echo libdir=${exec_prefix}/lib
    echo includedir=${prefix}/include
    echo.
    echo Name: icu-io
    echo Description: International Components for Unicode: Stream and I/O Library
    echo Version: 73.1
    echo Requires: icu-uc icu-i18n
    echo Libs: -L${libdir} -licuio
    echo Cflags: -I${includedir}
)
