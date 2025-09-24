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

# get environment variables
# by sorting we get the hightest values, because these probably started latest
# if you get WAYLAND_SOCKET wlr-randr stops working most of the time
eval $(grep -osPahm1 "\0(WAYLAND_DISPLAY|DBUS_[A-Z_]+|XDG_[A-Z_]+|DISPLAY)=[^\0]+" /proc/*/environ | cut -d= -f1- | sort | uniq | tr -d '\0' | sed 's/^/export /g')
[ "$WAYLAND_DISPLAY" != "" ] || WAYLAND_DISPLAY=$(ls $XDG_RUNTIME_DIR/wayland-[0-9])

#echo "$1 Execute $EXEC";
EXEC=$(jq -r ".buttons.$1.exec" data/remote.json)
if [[ ( -n "$EXEC" ) && ( "$EXEC" != "null" ) ]]; then
  #	echo "Execute $EXEC"
	export OUTPUT=$(eval "$EXEC")
else
  >&2 echo "Command for $1 not found"
fi
CURRENTSONG=$(audtool current-song)
# move pinguin radio stuff to the end on a new line
CURRENTSONG=$( echo $CURRENTSONG | perl -C -pe 's/(p[ei]nguin [a-zA-Z0-9_\- ]+)( - )(.*?)(Kodi: |$)/$3\n$1$2/ig' )
# remove urls
CURRENTSONG=$( echo $CURRENTSONG | perl -C -pe 's/([0-9a-z\.]+\.com)( - )?//ig' )
# change pinguin text to icon
CURRENTSONG=$( echo $CURRENTSONG | perl -C -pe 's/(.*)(p[ei]nguin)/$1\n\x{1F427}/ig' )
KODIPLAYING=$(~/kodi.sh current)
[[ -z "$CURRENTSONG" ]] && CURRENTSONG=$KODIPLAYING || CURRENTSONG+=$'\n'"$KODIPLAYING"

DURATION=$(audtool current-song-length-seconds)
SECONDSPROGRESS=$(audtool current-song-output-length-seconds)
# OUTPUT=$(/usr/bin/pactl -s /run/user/1000/pulse/native get-default-sink)
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
	--arg	kodi "$KODIPLAYING" \
	'{ $command, $output, $nowplaying, $duration, progress: $secondsprogress, $kodi, $audacity}' 

