#!/usr/bin/bash
export LANG=C.UTF-8

#ls -l /dev/snd/
#aplay -l
#amixer -c 2
#whoami

# export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
for f in /proc/*
do
	export DBUS_SESSION_BUS_ADDRESS=$( grep -zsP "^DBUS_SESSION_BUS_ADDRESS=.+" ${f}/environ|cut -d= -f2-| tr -d '\0')
	if [ "$DBUS_SESSION_BUS_ADDRESS" != "" ]; then
		break
	fi
done
# echo "$DBUS_SESSION_BUS_ADDRESS"

export DISPLAY=:0.0
EXEC=$(jq -r ".buttons.$1.exec" data/remote.json)
# echo "Execute $EXEC";
$(eval "$EXEC")
CURRENTSONG=$(audtool current-song)
# move pinguin radio stuff to the end on a new line
CURRENTSONG=`echo $CURRENTSONG | perl -pe 's/(p[ei]nguin [a-zA-Z0-9_\- ]+)( - )(.*)/$3\n$1/ig'`
# CURRENTSONG=`echo $CURRENTSONG | perl -pe 's/(the rocks)( - )?(.*)/$3\n$1/ig'`
# remove urls
CURRENTSONG=`echo $CURRENTSONG | perl -pe 's/([0-9a-z\.]+\.com)( - )?//ig'`
# change pinguin text to icon
CURRENTSONG=`echo $CURRENTSONG | perl -pe 's/(.*)(p[ei]nguin)/$1\n\x{1F427}/ig'`
DURATION=$(audtool current-song-length-seconds)
SECONDSPROGRESS=$(audtool current-song-output-length-seconds)
# |Pinguin[A-Za-z][0-9]{3}\) ]];
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

jq --ascii-output -n \
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

