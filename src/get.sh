##
# ConsoleD is open-source, small library written in D Programming Language that helps you add colors and formatting to your console output. 
# Work on both Windows and Posix operating systems.
# https://github.com/robik/ConsoleD
#

mkdir consoled -p
cd consoled
curl --remote-name "https://raw.githubusercontent.com/robik/ConsoleD/master/source/consoled.d" 
curl --remote-name "https://raw.githubusercontent.com/robik/ConsoleD/master/source/terminal.d" 
cd ..

##
# minilib
# https://github.com/parmaja/d-minilib
#

mkdir minilib -p
cd minilib
curl --remote-name "https://raw.githubusercontent.com/parmaja/d-minilib/master/sets.d" 
curl --remote-name "https://raw.githubusercontent.com/parmaja/d-minilib/master/package.d" 
cd ..

# I dislike using submodule