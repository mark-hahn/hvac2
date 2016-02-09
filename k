#   -*-  grammar-ext: sh  -*-

if [ $LOCATION != "server" ]; then 
  echo "k can only run on the server"
  exit
fi

if [ $(pwd) == "/root/dev/apps/hvac2" ]; then isdev=true; else isdev=false; fi

if $isdev
  then 
    echo "killing dev hvac app"
    kill $(pgrep -f "hvac dev") 2> /dev/null  
  else 
    echo "killing all hvac apps"
    kill $(pgrep -f "hvac") 2> /dev/null  
fi

