
@ECHO OFF

cd C:\opscode\chefdk\bin

REM ; Set the temporary directory to a custom location, and wipe it before
REM ; and after the tests run.
SET TEMP=%TEMP%\cheftest
SET TMP=%TMP%\cheftest
RMDIR /S /Q %TEMP%
MKDIR %TEMP%

ECHO(

FOR %%b IN (
  berks
  chef
  chef-client
  kitchen
  knife
  rubocop
) DO (


  ECHO Checking for existence of binfile `%%b`...

  IF EXIST %%b (

    ECHO ...FOUND IT!

  ) ELSE (

    GOTO :error

  )
  ECHO(
)

REM ; Run this last so the correct exit code is propagated
chef verify
