##
#

mkdir arsd -p
cd arsd
curl --remote-name "https://raw.githubusercontent.com/adamdruppe/arsd/master/terminal.d" 
cd ..

##
# minilib
# https://github.com/parmaja/d-minilib
#

mkdir minilib -p
cd minilib
curl --remote-name "https://raw.githubusercontent.com/parmaja/d-minilib/master/sets.d" 
curl --remote-name "https://raw.githubusercontent.com/parmaja/d-minilib/master/metaclasses.d" 
curl --remote-name "https://raw.githubusercontent.com/parmaja/d-minilib/master/package.d" 
cd ..

# I dislike using submodules