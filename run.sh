# make sure to terminate this script if the build fails
set -e

haxe build.hxml

# change this to wherever your nwjs executable is
Z:\\javascript\\nwjs-v0.50.2-win-x64\\nw.exe ./js
