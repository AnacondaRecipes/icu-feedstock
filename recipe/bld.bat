SETLOCAL EnableDelayedExpansion
cd source

:: Remove all instances of /W4 from configure -- they get passed to the linker
:: which then dies on the unrecognised flag. We don't care about warnings here.
sed "s~ /W4~~g" configure > configure.new
move configure.new configure

:: rc.exe (Windows resource compiler) gets confused by the '/' form of slashes
:: that MSYS2 substitutes; this env var keeps backslashes intact.
set MSYS_RC_MODE=1

:: Needed during `make install` but ICU's tree doesn't pre-create it.
mkdir data\out\tmp

echo "build - %build_platform% - %BUILD_PLATFORM%"
cd ..

:: msys2 bash inherits the parent process env, but %build_platform% is a
:: conda-build template variable that isn't auto-exported. Prepend it to a
:: generated wrapper script so build.sh can branch on target/build platform.
echo export build_platform=%build_platform% > build.sh
type "%RECIPE_DIR%\build.sh" >> build.sh

set MSYSTEM=MINGW%ARCH%
set MSYS2_PATH_TYPE=inherit
set CHERE_INVOKING=1
FOR /F "delims=" %%i in ('cygpath.exe -u "%LIBRARY_PREFIX%"') DO set "PREFIX=%%i"
:: ICU 78.x configure invokes Python during data/rules.mk generation. Without
:: this override it tries to use _h_env_placehold_/.../python which doesn't
:: exist at configure time. Point it at the real python.exe in BUILD_PREFIX.
FOR /F "delims=" %%i in ('cygpath.exe -u "%BUILD_PREFIX%"') DO set "ac_cv_prog_PYTHON=%%i/python.exe"

set CC=cl.exe
set CXX=cl.exe

bash -lc "./build.sh"
if errorlevel 1 exit 1

:: `make install` deposits .dlls into lib/, but conda expects shared libs in bin/.
move %LIBRARY_LIB%\icu*.dll %LIBRARY_BIN%
if errorlevel 1 exit 1
