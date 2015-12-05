@   echo off

:main /? | [/v] [/clean] | [/prefix directory]

:: = DESCRIPTION
:: =   !PROG_NAME! - configures cmd-installers.
:: =
:: = OPTIONS
:: =   /v       Be verbose. Repeat for extra verbosity.
:: =   /clean   Remove files generated by !PROG_NAME!.
:: =   /prefix  Name of directory to install cmd-installers in.
:: =            Default is !prefix!.

:: @author Jan Bruun Andersen
:: @version @(#) Version: 2015-12-05

    verify 2>NUL: other
    setlocal EnableExtensions
    if ErrorLevel 1 (
	echo Error - Unable to enable extensions.
	goto :EOF
    )

    for %%F in (cl_init.cmd) do if "" == "%%~$PATH:F" PATH %~dp0\src\lib;%PATH%
    call cl_init "%~f0" "%~1" || (echo Failed to initialise cmd-lib. & goto :exit)
    if /i "%~1" == "/trace" shift & prompt $G$G & echo on

:defaults
    set "show_help=false"
    set "verbosity=0"
    set "action=configure"
    set "prefix=%UserProfile%\LocalTools"

:getopts
    if /i "%~1" == "/?"		set "show_help=true"	& shift		& goto :getopts

    if /i "%~1" == "/v"		set /a "verbosity+=1"	& shift		& goto :getopts
    if /i "%~1" == "/prefix"	set "prefix=%~2"	& shift & shift	& goto :getopts
    if /i "%~1" == "/clean"	set "action=clean"	& shift		& goto :getopts

    set "char1=%~1"
    set "char1=%char1:~0,1%"
    if "%char1%" == "/" (
	echo Unknown option - %1.
	echo.
	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if "%show_help%" == "true" call cl_help "%PROG_FULL%" & goto :EOF

    if not "%~1" == "" (
	echo Extra argument - %1.
	echo.
    	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if not defined prefix (
	echo Missing argument - dest-dir is empty.
	echo.
    	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    rem .----------------------------------------------------------------------
    rem | This is where the real fun begins!
    rem '----------------------------------------------------------------------

    goto :%action%
:configure
    call cl_token_subst install.cmd.tmpl install.cmd PROG_NAME=install DST_DIR="%prefix%"
    goto :exit
:clean
    for %%F in (install.cmd) do (
	if 0%verbosity% geq 1 echo Deleting %%F.
	if exist "%%F" del "%%F"
    )
    goto :exit
goto :EOF

rem .--------------------------------------------------------------------------
rem | Displays a selection of variables belonging to this script.
rem | Very handy when debugging.
rem '--------------------------------------------------------------------------
:dump_variables
    echo =======
    echo cwd            = "%CD%"
    echo tmp_dir        = "%tmp_dir%"

    echo show_help      = "%show_help%"
    echo prefix         = "%prefix%"
    echo action         = "%action%"

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
