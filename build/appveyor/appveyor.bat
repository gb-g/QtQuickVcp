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


::mkdir -p tmp
::cd tmp
cd %HOMEDRIVE%%HOMEPATH%
mkdir -p bin
cd bin
git clone https://github.com/google/protobuf.git
cd protobuf
git checkout v2.6.1
cd vsprojects
if %ARCH% == x64 (
    msbuild protobuf.sln /t:libprotobuf /p:Platform=x64 /p:Configuration=Release
    msbuild protobuf.sln /t:libprotobuf-lite /p:Platform=x64 /p:Configuration=Release
    msbuild protobuf.sln /t:libprotoc /p:Platform=x64 /p:Configuration=Release
    msbuild protobuf.sln /t:protoc /p:Platform=x64 /p:Configuration=Release
    SET PROTODIR=%HOMEDRIVE%%HOMEPATH%\bin\protobuf\vsprojects\x64\Release
) else (
    msbuild protobuf.sln /t:libprotobuf /p:Platform=Win32 /p:Configuration=Release
    msbuild protobuf.sln /t:libprotobuf /p:Platform=Win32 /p:Configuration=Release
    msbuild protobuf.sln /t:libprotoc /p:Platform=Win32 /p:Configuration=Release
    msbuild protobuf.sln /t:protoc /p:Platform=Win32 /p:Configuration=Release
    ::msbuild protobuf.sln /p:Platform=Win32 /p:Configuration=Release
    SET PROTODIR=%HOMEDRIVE%%HOMEPATH%\bin\protobuf\vsprojects\Release
)
::mkdir -p %PROTODIR%
::mv protoc.exe %PROTODIR%\ || goto :error
::mv libprotoc.lib %PROTODIR%\ || goto :error
::cp libprotobuf.lib %PROTODIR%\ || goto :error
cp %PROTODIR%\libprotobuf.lib %QTDIR%\lib\ || goto :error

cd %APPVEYOR_BUILD_FOLDER%
mkdir -p tmp
cd tmp
SET PROTOVERSION=2.6.1
appveyor DownloadFile https://github.com/google/protobuf/archive/v%PROTOVERSION%.zip -Filename protosrc.zip
7z x protosrc.zip || goto :error
cd protobuf-%PROTOVERSION% || goto :error
SET PROTODIR=%HOMEDRIVE%%HOMEPATH%\bin\protobuf\
cp -r src %PROTODIR% || goto :error
::cd .. || goto :error

cd %HOMEDRIVE%%HOMEPATH%\bin
git clone https://github.com/zeromq/zeromq4-x.git
cd zeromq4-x
git checkout v4.0.8
cd builds\msvc
if %ARCH% == x64 (
    msbuild msvc11.sln /t:libzmq /p:Platform=x64 /p:Configuration=Release
::    msbuild msvc11.sln /p:Platform=x64 /p:Configuration=Release
    SET ZEROMQDIR=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x\lib\x64
    SET ZEROMQDIRBIN=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x\bin\x64
) else (
    msbuild msvc11.sln /t:libzmq /p:Platform=Win32 /p:Configuration=Release
    SET ZEROMQDIR=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x\lib\Win32
    SET ZEROMQDIRBIN=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x\bin\Win32
)
::mkdir -p %ZEROMQDIR%
::cp libzmq.lib %ZEROMQDIR%\ || goto :error
cp %ZEROMQDIR%\libzmq.lib %QTDIR%\lib\ || goto :error
cp %ZEROMQDIRBIN%\libzmq.dll %QTDIR%\bin\ || goto :error

cd %APPVEYOR_BUILD_FOLDER%
cd tmp 
SET ZMQVERSION=4.0.8
appveyor DownloadFile https://github.com/zeromq/zeromq4-x/archive/v%ZMQVERSION%.zip -Filename zmqsrc.zip || goto :error
7z x zmqsrc.zip || goto :error
cd zeromq4-x-%ZMQVERSION%
SET ZEROMQDIR=%HOMEDRIVE%%HOMEPATH%\bin\zeromq4-x
cp -r include %ZEROMQDIR% || goto :error
cd ..

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
cp %QTDIR%\bin\libzmq.dll . || goto :error
cd .. || goto :error
7z a MachinekitClient.zip MachinekitClient/ || goto :error

mkdir qml
mkdir lib
cp -r %QTDIR%/qml/Machinekit qml/ || goto :error
cp -r %QTDIR%/bin/libzmq.dll lib/ || goto :error
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
