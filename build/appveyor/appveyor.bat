setlocal
@echo ON

cd %APPVEYOR_BUILD_FOLDER%
:: get version label
git describe --exact-match HEAD
if %ERRORLEVEL% == 0 (
    SET release=1
) else (
    SET release=0
)
if %release% == 0 (
    for /f %%i in ('powershell get-date -format "yyyyMMddHHmm"') do set datetime=%%i

    ::for /f %%i in ('git rev-parse --abbrev-ref HEAD') do set branch=%%i
    set branch=%APPVEYOR_REPO_BRANCH%

    for /f %%i in ('git rev-parse --short HEAD') do set revision=%%i
) else (
    for /f %%i in ('git describe --tags') do set version=%%i
)

if %release% == 0 (
    set version=%datetime%-%branch%-%revision%
)
echo #define REVISION "%version%" > src\application\revision.h || goto :error
appveyor UpdateBuild -Version "%version%-%ARCH%" || goto :error


vcpkg install zeromq:%ARCH%-windows
if %ARCH% == x64 (
    SET ZEROMQDIR=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x\lib\x64
) else (
    SET ZEROMQDIR=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x\lib\Win32
)
mkdir -p %ZEROMQDIR%
SET ZMQVERSION=4_3_4
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows\lib\libzmq-mt-%ZMQVERSION%.lib %ZEROMQDIR%\libzmq.lib || goto :error
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows\lib\libzmq-mt-%ZMQVERSION%.lib %QTDIR%\lib\libzmq.lib || goto :error
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows\bin\libzmq-mt-%ZMQVERSION%.dll %QTDIR%\bin\ || goto :error

cd %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows
SET ZEROMQDIR=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x
cp -r include %ZEROMQDIR% || goto :error
rm -r %ZEROMQDIR%\include\google\protobuf || goto :error
cd %APPVEYOR_BUILD_FOLDER% || goto :error

vcpkg install protobuf:%ARCH%-windows-static-md
if %ARCH% == x64 (
    SET PROTODIR=%HOMEDRIVE%%HOMEPATH%\bin\protobuf\vsprojects\x64\Release
) else (
    SET PROTODIR=%HOMEDRIVE%%HOMEPATH%\bin\protobuf\vsprojects\Release
)
mkdir -p %PROTODIR%
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows-static-md\tools\protobuf\protoc.exe %PROTODIR%\ || goto :error
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows-static-md\lib\libprotoc.lib %PROTODIR%\ || goto :error
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows-static-md\lib\libprotobuf.lib %PROTODIR%\ || goto :error
cp %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows-static-md\lib\libprotobuf.lib %QTDIR%\lib\ || goto :error

cd %HOMEDRIVE%\tools\vcpkg\installed\%ARCH%-windows-static-md
SET PROTODIR=%HOMEDRIVE%%HOMEPATH%\bin\protobuf\
cp -r include %PROTODIR% || goto :error

:: start build
cd %APPVEYOR_BUILD_FOLDER%
mkdir build.release
cd build.release
qmake -r .. || goto :error
nmake || goto :error
nmake install || goto :error

mkdir MachinekitClient
cd MachinekitClient
cp ../apps/MachinekitClient/release/machinekit-client.exe . || goto :error
windeployqt --angle --release --qmldir ../../apps/MachinekitClient/ machinekit-client.exe || goto :error
cp ../translations/*.qm translations/ || goto :error
cp %QTDIR%\bin\libzmq-mt-%ZMQVERSION%.dll . || goto :error
cd .. || goto :error
7z a MachinekitClient.zip MachinekitClient/ || goto :error

mkdir qml
mkdir lib
cp -r %QTDIR%/qml/Machinekit qml/ || goto :error
cp -r %QTDIR%/bin/libzmq-mt-%ZMQVERSION%.dll lib/ || goto :error
7z a QtQuickVcp.zip qml/ lib/ translations/ || goto :error

:: rename deployment files
set platform=%ARCH%
if %release% == 0 (
    set target1="QtQuickVcp_Development"
    set target2="MachinekitClient_Development"
) else (
    set target1="QtQuickVcp"
    set target2="MachinekitClient"
)

mv QtQuickVcp.zip %target1%-%version%-Windows-%platform%.zip || goto :error
mv MachinekitClient.zip %target2%-%version%-%platform%.zip || goto :error

goto :EOF

:error
echo Failed!
EXIT /b %ERRORLEVEL%
