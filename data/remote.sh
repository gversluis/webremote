#!/usr/bin/bash
export LANG=C.UTF-8

#ls -l /dev/snd/
#aplay -l
#amixer -c 2
#whoami

if [ "$1" == "" ]; then
	>&2 echo "Syntax: $0 <command from remote.json>"
	exit
fi;

export DBUS_SESSION_BUS_ADDRESS=$( grep -osPahm1 "\0DBUS_SESSION_BUS_ADDRESS=[^\0]+" /proc/*/environ | tail -n1 | cut -d= -f2- )
#echo "$1 Execute $EXEC";
# pick highest display nr. because thats probably started latest
export DISPLAY=$( grep -osPahm1 "\0DISPLAY=:[\d\.]+" /proc/*/environ | sort | tail -n1 | cut -d= -f2- )
EXEC=$(jq -r ".buttons.$1.exec" data/remote.json)
if [[ ( -n "$EXEC" ) && ( "$EXEC" != "null" ) ]]; then
  #	echo "Execute $EXEC"
	export OUTPUT=$(eval "$EXEC")
else
  >&2 echo "Command for $1 not found"
fi
CURRENTSONG=$(audtool current-song)
# move pinguin radio stuff to the end on a new line
CURRENTSONG=$( echo $CURRENTSONG | perl -C -pe 's/(p[ei]nguin [a-zA-Z0-9_\- ]+)( - )(.*)/$3\n$1/ig' )
# remove urls
CURRENTSONG=$( echo $CURRENTSONG | perl -C -pe 's/([0-9a-z\.]+\.com)( - )?//ig' )
# change pinguin text to icon
CURRENTSONG=$( echo $CURRENTSONG | perl -C -pe 's/(.*)(p[ei]nguin)/$1\n\x{1F427}/ig' )
DURATION=$(audtool current-song-length-seconds)
SECONDSPROGRESS=$(audtool current-song-output-length-seconds)
if [[ $DURATION -eq "0" ]]; then
#	CURRENTSONG="$CURRENTSONG $DURATION $SECONDSPROGRESS"
  DURATION=$(($SECONDSPROGRESS+10))
fi
if [[ $CURRENTSONG =~ (listen\?|Pinguin[A-Za-z]{1,}[0-9]{3}) ]]; then
  CURRENTSONG="LOADING... $CURRENTSONG"
  DURATION=3
  SECONDSPROGRESS=0
fi
NOWPLAYINGLENGTHLEFT=$DURATION-$SECONDSPROGRESS
jq -n \
  --arg user "$(whoami)" \
	--arg command "$1" \
	--arg executed "$EXEC" \
	--arg output "$OUTPUT" \
	--arg nowplaying "$CURRENTSONG" \
  --arg duration "$DURATION" \
  --arg secondsprogress "$SECONDSPROGRESS" \
  --arg secondsleft "$NOWPLAYINGLENGTHLEFT" \
  --arg audacity "$(audtool version | grep Aud -c)" \
	--arg	kodi "$(pidof kodi.bin)" \
	'{ $command, $output, $nowplaying, $duration, progress: $secondsprogress, $kodi, $audacity}' 

