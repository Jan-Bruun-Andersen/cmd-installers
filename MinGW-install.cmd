@   echo off

:main /? | [/v] [/unpack] [/noxpath] [mingw-get.zip [package-name...]]

:: = DESCRIPTION
:: =   !PROG_NAME! - a script to install MinGW (32-bit).
:: =
:: =   In short, !PROG_NAME! does the following:
:: =
:: =     1) Unpacks the archive containing the MinGW install utility into the
:: =        MinGW home directory (!MINGW_HOME!).
:: =     2) Creates the initial package catalogue.
:: =     3) Updates existing packages.
:: =     4) Installs MinGW and MSYS packages.
:: =     5) Records '!MINGW_HOME!' as the mount-point for /mingw.
:: =     6) Creates dummy directories for /usr and /tmp in '!MSYS_HOME!'.
:: =        These directories will be overlaid using default mounts by MSYS,
:: =        but the fact that they exists allows for automatic path expansion.
:: =     7) Appends '!MINGW_HOME!\bin' and '!MSYS_HOME!\bin' to the user's system-wide
:: =        PATH environment variable.
:: =
:: =   By default these packages are installed:
:: =
:: =     Package                  Description
:: =     -----------------------  ----------------------------------------------
:: =     gcc                      GNU C Compiler
:: =     g++                      GNU C++ Compiler
:: =     mingw-developer-toolkit  MSYS Installation for MinGW Developers
:: =     msys-man                 Formats and displays manual pages
:: =
:: =   While the Developer Toolkit includes utilities such as 'patch' as 'vim',
:: =   it lacks the manual pages, so you might want to install the full packages
:: =   for a more complete MSYS environment. These packages can be installed by
:: =   supplying the package name(s) as paramaters to !PROG_NAME!
:: =
:: =   Some useful package names and their descriptions:
:: =
:: =     Package                  Description
:: =     -----------------------  ----------------------------------------------
:: =     msys-patch               Apply a diff to do an original
:: =     msys-vim                 Vi IMproved, a programmers text editor
:: =     msys-wget                Non-interactive network downloader
:: =
:: =  PARAMETERS
:: =    mingw-get.zip
:: =             Name of the archive (7z, zip, or tar) containing the MinGW (32-bit)
:: =             ommand line installer.
:: =             !PROG_NAME! has been verified to work with the following
:: =             archives:
:: =
:: =              mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip (default)
:: =
:: =    package-name
:: =             Package(s) to be installed. For a complete package list, use the
:: =             command "!MINGW_HOME!\bin\mingw-get" list | more
:: =
:: = OPTIONS
:: =   /v        Be verbose.
:: =
:: =   /unpack   Only unpack the files into !MINGW_HOME!. Do not install.
:: =
:: =   /noxpath  Do not append !MINGW_HOME!\bin and !MSYS_HOME!\bin to the user's
:: =             system-wide PATH environment variable.
:: = FILES
:: =   Archive with MinGW (32-bit) installer:    !archive!
:: =   Program for unpacking archive:            !UNPACKER!
:: =   Default catalogue of installed packages:  !def_cat!
:: =   Current catalogue of installed packages:  !sys_cat!
:: =
:: = ENVIRONMENT VARIABLES
:: =   MINGW_HOME Home-directory for MinGW.        Default is %SystemDrive%\MinGW
:: =   MSYS_HOME  Home-directory for MSYS.         Default is %MINGW_HOME%\msys\1.0
:: =   UNPACKER   Program used to unpack archive.  Default is %ProgramFiles%\7-Zip\7z

:: @author MiniMax
:: @version @(#) Version: 2015-12-05

    verify 2>NUL: other
    setlocal EnableExtensions
    if ErrorLevel 1 (
	echo Error - Unable to enable extensions.
	goto :EOF
    )

    for %%F in (cl_init.cmd) do if "" == "%%~$PATH:F" PATH %~dp0\cmd-lib.lib;%PATH%
    call cl_init "%~f0" "%~1" || (echo Failed to initialise cmd-lib. & goto :exit)
    if /i "%~1" == "/trace" shift & prompt $G$G & echo on

:defaults
    if not defined MINGW_HOME	set "MINGW_HOME=%SystemDrive%\MinGW"
    if not defined MSYS_HOME	set "MSYS_HOME=%MINGW_HOME%\msys\1.0"
    if not defined UNPACKER	set "UNPACKER=%ProgramFiles%\7-Zip\7z"
    if not defined GET_OPTS	set "GET_OPTS=--desktop=all-users --start-menu=all-users"

    set "MINGW32_GET_URL=http://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip"
rem set "MINGW32_SETUP_URL=http://downloads.sourceforge.net/project/mingw/Installer/mingw-get-setup.exe"
rem set "MINGW64_INSTALLER_URL=http://downloads.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe"

    set "GET_URL=%MINGW32_GET_URL%"

    set "show_help=false"
    set "verbosity=0"
    set "install=true"
    set "noxpath=false"

    rem Define the list of packages to install. Each entry in the list consist of
    rem an optional description in qoutes followed by an equal sign and then the
    rem name of the package.

    (set packages=)
    (set packages=%packages% "GNU C Compiler"=gcc)
    (set packages=%packages% "GNU C++ Compiler"=g++)
    (set packages=%packages% "MSYS Installation for MinGW Developers"=mingw-developer-toolkit)
    (set packages=%packages% "Formats and displays manual pages"=msys-man)

    call cl_basename "%GET_URL%"
    set "archive=%_basename%"

    set "def_cat=%MINGW_HOME%\var\lib\mingw-get\data\defaults.xml"
    set "sys_cat=%MINGW_HOME%\var\lib\mingw-get\data\profile.xml"

:getopts
    if /i "%~1" == "/?"		set "show_help=true"	& shift		& goto :getopts

    if /i "%~1" == "/v"		set /a "verbosity+=1"	& shift		& goto :getopts
    if /i "%~1" == "/unpack"	set "install=false"	& shift		& goto :getopts
    if /i "%~1" == "/noxpath"	set "noxpath=true"	& shift		& goto :getopts

    set "char1=%~1"
    set "char1=%char1:~0,1%"
    if "%char1%" == "/" echo Unknown option - %1. & echo. & call cl_usage "%PROG_FULL%" & goto :error_exit

    if "%show_help%" == "true" call cl_help "%PROG_FULL%" & goto :EOF

    if not "%~1" == "" set "archive=%~1"    & shift
    if not "%~1" == "" set "packages=%~1"   & shift

    if 0%verbosity% geq 1 (
	echo MINGW_HOME   = %MINGW_HOME%
	echo MSYS_HOME    = %MSYS_HOME%
	echo UNPACKER     = %UNPACKER%
	echo archive-file = %archive%
	echo packages     = %packages%
	echo.
    )

    if not exist "%archive%" (
	echo.
	echo ERROR: No such archive: "%archive%"
	echo Please download "%GET_URL%" and try again.
	goto :error_exit
    )

    rem .----------------------------------------------------------------------
    rem | This is where the real fun begins!
    rem '----------------------------------------------------------------------

    echo === 1^) Unpacking MinGW install utility ===
    call :unpack "%archive%" "%MINGW_HOME%" || goto :EOF

    if "%install%" == "false" goto :EOF

    if exist %sys_cat% (
	echo === 2^) Package catalogue exist. Skipped ===
    ) else (
	echo === 2^) Creating initial package catalogue ===
	if 0%verbosity% gtr 0 echo >&2 Copying default catalogue to %sys_cat%
	copy "%def_cat%" "%sys_cat%"
    )

    echo === 3^) Updating existing MinGW and MSYS packages ===
    call :mingw_get update

    rem The tricky code below utilises the fact that the CMD-interpreter will,
    rem for some obscure reason, treat the '=' in the 'packages' list as a
    rem separator. This means that a package list like:
    rem
    rem   "MSYS Installation for MinGW Developers"=mingw-developer-toolkit
    rem
    rem will be expanded into two elements:
    rem
    rem   "MSYS Installation for MinGW Developers" mingw-developer-toolkit
    rem
    rem By looking at the first character in the element we can deduce if it is
    rem a package description or an actual package name.

    echo === 4^) Installing packages ===
    setlocal enabledelayedexpansion
    for %%P in (%packages%) do (
	set char1=%%P
	set char1=!char1:~0,1!
	if !char1! == ^" (
	    echo Installing package %%P.
	) else (
	    call :mingw_get install %%~P
	)
    )
    endlocal
    if errorlevel 1 goto :error_exit
    
    echo === 5^) Updating MSYS mount table ===
    pushd "%MSYS_HOME%" || goto :error_exit
    PATH=%CD%\bin;%PATH%
    sh -c "[[ -d /mingw ]] || mount '%MINGW_HOME%' /mingw"
    popd

    echo === 6^) Creating dummy directories for /usr and /tmp ===
    for %%D in ("%MSYS_HOME%\usr" "%MSYS_HOME%\tmp") do if not exist "%%~D\" mkdir "%%~D"

    if "%noxpath%" == "true" (
	echo === 7^) Skipping update of system PATH ===
    )
	echo === 7^) Updating system PATH ===
	call :xPATH "gcc.exe" "%MINGW_HOME%\bin"
	call :xPATH "sh.exe"  "%MSYS_HOME%\bin"
	echo Please exit this CMD for the changes to take effect.
    )

    echo === All done ===
    echo.
    echo You may now launch MSYS using the msys.bat file that the installer created in
    echo %MSYS_HOME%.
    goto :exit
goto :EOF

:mingw_get [options...] action packages....
    "%MINGW_HOME%"\bin\mingw-get %GET_OPTS% %*
    echo === Done with '%*' ===
goto :EOF

rem .--------------------------------------------------------------------------
rem | Unpacks an archive into the specified directory.
rem |
rem | @param 1 = Archive to unpack.
rem | @param 2 = Directory into which the archive will be unpacked.
rem |
rem | @global %UNPACKER%  = path to unpack program.
rem | @global %verbosity% = verbosity level (0..1).
rem '--------------------------------------------------------------------------
:unpack archive dst-dir
    call cl_abspath "%~2"
    if 0%verbosity% geq 1 echo Unpacking "%~1" into "%_abspath%".

    call cl_stripexts "%UNPACKER%" .exe .com .cmd .bat
    call cl_basename "%_stripexts%"
    if /i "%_basename%" == "7z"  goto :upk7z
    if /i "%_basename%" == "jar" goto :upkjar
    
    echo %PROG_NAME%: Sorry, no support for "%UNPACKER%"
    echo as UNPACKER in this version.
    echo.
    echo Please check that you have defined UNPACKER correctly in %PROG_FULL%.
    echo Alternatively, you can manually unpack "%~1" into a folder called
    echo "%~2" and then re-run this script.
    exit /b 1
goto :EOF

:upk7z
    if 0%verbosity% geq 2 (call cl_unpack_7z  /v "%UNPACKER%" "%~1" "%~2") else (
			   call cl_unpack_7z     "%UNPACKER%" "%~1" "%~2")
    goto :upk

:upkjar
    if 0%verbosity% geq 2 (call cl_unpack_jar /v "%UNPACKER%" "%~1" "%~2") else (
			   call cl_unpack_jar    "%UNPACKER%" "%~1" "%~2")
    goto :upk

:upk
    if ErrorLevel 1 (
	echo.
	echo ERROR: Unable to unpack file "%~1" into "%~2%"
	echo using "%UNPACKER%".
    )
goto :EOF

:xPATH
    call :getx_var PATH
    set oPATH=%_%

    setlocal enabledelayedexpansion
    for %%I in ("%~1") do (
	if "" == "%%~$oPATH:I" (
	    call :getx_var PATH
	    if 0%verbosity% geq 1 echo Appending "%~2" to PATH.
	    if exist "%~2\%%I" setx PATH !_!;%~2
	)
    )
    endlocal
goto :EOF

:getx_var var-name
    set _=
    for /F "skip=2 tokens=3*" %%V in ('reg query "HKCU\Environment" /v "%~1"') do set _=%%V%%W
goto :EOF

rem .--------------------------------------------------------------------------
rem | Displays a selection of variables belonging to this script.
rem | Very handy when debugging.
rem '--------------------------------------------------------------------------
:dump_variables
    echo =======
    echo cwd            = "%CD%"
    echo tmp_dir        = "%tmp_dir%"

    echo MINGW_HOME     = "%MINGW_HOME%"
    echo MSYS_HOME      = "%MSYS_HOME%"
    echo UNPACKER       = "%UNPACKER%"
    echo GET_OPTS       = "%GET_OPTS%"
    echo GET_URL        = "%GET_URL%"

    echo show_help      = "%show_help%"
    echo verbosity      = "%verbosity%"
    echo install        = "%install%"
    echo noxpath        = "%noxpath%"
    echo archive        = "%archive%"
    echo def_cat        = "%def_cat%"
    echo sys_cat        = "%sys_cat%"

    if defined tmp_dir if exist "%tmp_dir%\" (
	echo.
	dir %tmp_dir%
    )

    echo =======
goto :EOF

rem ----------------------------------------------------------------------------
rem Sets ErrorLevel and exit-status. Without a proper exit-status tests like
rem 'command && echo Success || echo Failure' will not work,
rem
rem OBS: NO commands must follow the call to %ComSpec%, not even REM-arks,
rem      or the exit-status will be destroyed. However, null commands like
rem      labels (or ::) is okay.
rem ----------------------------------------------------------------------------
:no_error
    time >NUL: /t	& rem Set ErrorLevel = 0.
    goto :exit
:error_exit
    verify 2>NUL: other	& rem Set ErrorLevel = 1.
:exit
    %ComSpec% /c exit %ErrorLevel%

:: vim: set filetype=dosbatch tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab:
:: vim: set foldmethod=indent
