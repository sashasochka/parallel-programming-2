gnatmake -d -PE:\Dropbox\pp\lab7\lab7.gpr lab7.adb
gnatbind -x E:\Dropbox\pp\lab7\lab7.ali
gnatlink E:\Dropbox\pp\lab7\lab7.ali -Xlinker --stack=0x10000000 -o E:\Dropbox\pp\lab7\lab7.exe