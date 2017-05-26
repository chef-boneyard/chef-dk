
@ECHO OFF

cd C:\opscode\chefdk\bin

REM ; Set the temporary directory to a custom location, and wipe it before
REM ; and after the tests run.
SET TEMP=%TEMP%\cheftest
SET TMP=%TMP%\cheftest
RMDIR /S /Q %TEMP%
MKDIR %TEMP%

REM ; Ensure the calling environment (disapproval look Bundler) does not
REM ; infect our Ruby environment created by the `chef` cli.
FOR %%E IN (_ORIGINAL_GEM_PATH, BUNDLE_BIN_PATH, BUNDLE_GEMFILE, GEM_HOME, GEM_PATH, GEM_ROOT, RUBYLIB, RUBYOPT, RUBY_ENGINE, RUBY_ROOT, RUBY_VERSION, BUNDLER_VERSION) DO SET %%E=

REM ; Ensure the msys2 build dlls are not on the path
SET PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\opscode\chefdk\bin

REM ; Run this last so the correct exit code is propagated
chef verify
