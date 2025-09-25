@echo off

@REM echo "compilin da linucks"
@REM g++ -std=c++17 -fPIC -shared libvlc_wrapper.cpp -Iinclude -lvlc -lvlccore -o ../linux/libvlc_wrapper.so

echo "compilin da srinky windows"
x86_64-w64-mingw32-g++ -std=c++17 -shared -static-libgcc -static-libstdc++     -o ../win64/libvlc_wrapper.dll libvlc_wrapper.cpp -Iinclude -L../win64/ -lOpenAL32 -llibvlc -llibvlccore
