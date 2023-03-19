@echo off
set BUILDPATH=%~dp0
cd %BUILDPATH%
setlocal enabledelayedexpansion

:initConfig
set configFile=%~n0.ini
set LLVM_DIR=%BUILDPATH%/llvm-project
set CMAKE=cmake.exe
set MAKE=ninja.exe
set GENERATOR=Ninja
set BUILD_DIR=build
set RELEASE_DIR=release
set ANDROID_NDK=
set ANDROID_API_LEVEL=21
set TARGET_ABI_LIST=armeabi-v7a arm64-v8a x86 x86_64
set BUILD_TYPE_LIST=Release Debug
call:readini %configFile% build CMAKE_PROGRAM CMAKE
call:readini %configFile% build CMAKE_MAKE_PROGRAM MAKE
call:readini %configFile% build GENERATOR GENERATOR
call:readini %configFile% build BUILD_DIR BUILD_DIR
call:readini %configFile% build RELEASE_DIR RELEASE_DIR
call:readini %configFile% build ANDROID_NDK ANDROID_NDK
call:readini %configFile% build ANDROID_API_LEVEL ANDROID_API_LEVEL
call:readini %configFile% build ANDROID_ABI_LIST TARGET_ABI_LIST
call:readini %configFile% build BUILD_TYPE_LIST BUILD_TYPE_LIST
set BUILD_DIR=%BUILDPATH%%BUILD_DIR%
set RELEASE_DIR=%BUILDPATH%%RELEASE_DIR%

%CMAKE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto build
echo ERROR: cmake not found: %CMAKE%
goto exit

:build
for %%a in (%BUILD_TYPE_LIST%) do (
	set BUILD_TYPE=%%a
	for %%b in (%TARGET_ABI_LIST%) do (
		set TARGET_ABI=%%b
		set PROJECT_BUILD_DIR=%BUILD_DIR%/android_!TARGET_ABI!/!BUILD_TYPE!

		echo.
		echo.
		set command_generator=%CMAKE% -Wno-dev -G %GENERATOR% -S %BUILDPATH% -B "!PROJECT_BUILD_DIR!" -DCMAKE_INSTALL_PREFIX="!PROJECT_BUILD_DIR!" ^
-DCMAKE_MAKE_PROGRAM="%MAKE%" ^
-DCMAKE_BINARY_DIR="%BUILD_DIR%" ^
-DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK%/build/cmake/android.toolchain.cmake" ^
-DCMAKE_BUILD_TYPE=!BUILD_TYPE! ^
-DCMAKE_SYSTEM_NAME=Android ^
-DANDROID_NDK="%ANDROID_NDK%" ^
-DANDROID_ABI=!TARGET_ABI! ^
-DANDROID_PLATFORM=%ANDROID_API_LEVEL% ^
-DTARGET_ABI=!TARGET_ABI! ^
-DRELEASE_DIR="%RELEASE_DIR%" ^
-DLLVM_DIR="%LLVM_DIR%"
		echo !command_generator!
		call !command_generator!
		
		echo.
		echo.
		set command_build=%CMAKE% --build !PROJECT_BUILD_DIR! --config=!BUILD_TYPE! --target=install-cxxandcxxabi
		echo !command_build!
		call !command_build!
		
		echo.
		echo.
		set command_build=%CMAKE% --build !PROJECT_BUILD_DIR! --config=!BUILD_TYPE! --target=install-cxxandcxxabi-stripped
		echo !command_build!
		call !command_build!
	)
)


::读取ini配置. %~1:文件名，%~2:域，%~3:key %~4:返回的value值
:readini 
@setlocal enableextensions enabledelayedexpansion
@echo off
set file=%~1
set area=[%~2]
set key=%~3
set currarea=
for /f "usebackq delims=" %%a in ("!file!") do (
    set ln=%%a
    if "x!ln:~0,1!"=="x[" (
        set currarea=!ln!
    ) else (
        for /f "tokens=1,2 delims==" %%b in ("!ln!") do (
            set currkey=%%b
            set currval=%%c
            if "x!area!"=="x!currarea!" (
                if "x!key!"=="x!currkey!" (
                    set var=!currval!
                )
            )
        )
    )
)
(endlocal
    set "%~4=%var%"
)
goto:eof


:exit
echo. & pause
exit /b
