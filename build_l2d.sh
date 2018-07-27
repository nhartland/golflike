#!/bin/sh
# Builds the love2d package with loverocks
loverocks deps
rm golflike.love
zip -r golflike.love *

# Make macos app
wget https://bitbucket.org/rude/love/downloads/love-11.1-macos.zip
unzip love-11.1-macos.zip
cp Info.plist love.app/Contents/
cp golflike.love love.app/Contents/Resources/
mv love.app golflike.app

# Make windows package
wget https://bitbucket.org/rude/love/downloads/love-11.1-win32.zip
unzip love-11.1-win32.zip
mv love-11.1.0-win32 golflike_win32
cat  golflike_win32/love.exe golflike.love >  golflike_win32/golflike.exe
rm golflike_win32/love.exe
rm golflike_win32/lovec.exe
rm golflike_win32/love.ico
rm golflike_win32/changes.txt
rm golflike_win32/readme.txt

#Cleanup
rm *.zip
zip -ry golflike_macos.zip golflike.app
zip -ry golflike_win32.zip golflike_win32
rm -rf golflike.app
rm -rf golflike_win32
#loverocks purge
