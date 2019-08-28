#   -*-  grammar-ext: sh  -*-

if [ $(pwd) == "/root/dev/apps/hvac2" ]; then isdev=true; else isdev=false; fi

if $isdev
  then
    export hvaclog="hvac-debug.log"
    echo "killing dev hvac app"
    kill $(pgrep -f "hvac dev") 2> /dev/null
    echo "Running hvac2 in debug mode"
    cd /root/dev/apps/hvac2
  else
    export hvaclog="hvac.log"
    echo "killing all hvac apps"
    kill $(pgrep -f "hvac") 2> /dev/null
    echo "Running hvac in normal mode"
    cd /root/apps/hvac
fi

killall tail > /dev/null 2>&1
tail -fn 0 ~/logs/$hvaclog &

set -e

if $isdev; then
  coffee -co /root/dev/apps/imprea/js /root/dev/apps/imprea/src/*.coffee
  coffee -co js src/*.coffee
  coffee -co js src/drivers/*.coffee
  coffee -co www/js www/*.coffee
fi

#export DEBUG=*
if $isdev
  then node js/main.js hvac dev
  else nohup node js/main.js hvac     >> ~/logs/$hvaclog 2>&1 &
fi
