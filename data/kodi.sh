#!/bin/bash
kodi_username="YOUR_USERNAME_HERE"
kodi_password="YOUR_PASSWORD_HERE"
kodi_host="http://localhost:8080/jsonrpc"

case $1 in

playpause)
	curl -u "$kodi_username:$kodi_password" -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": 0 }, "id": 1}' $kodi_host
	curl -u "$kodi_username:$kodi_password" -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": 1 }, "id": 1}' $kodi_host
;;

input)
	direction=$2
	curl -u "$kodi_username:$kodi_password" -X POST -H "Content-Type: application/json" -d "{\"jsonrpc\": \"2.0\", \"method\": \"Input.$direction\", \"id\": 1}" $kodi_host
;;

quit)
	curl -u "$kodi_username:$kodi_password" -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "Application.Quit", "id": 1}' $kodi_host
;;

res)
	kodi_resolution=$2
	echo "request resolution $kodi_resolution"

	# current resolution
	kodi_currentresolutionid=$(curl -s -u "$kodi_username:$kodi_password" -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"Settings.GetSettingValue","params":{"setting":"videoscreen.resolution"},"id":1}' $kodi_host | jq '.result.value')
	echo "current resolution id $kodi_currentresolutionid"

	# id for resolution
	kodi_resolutionid=$(curl -s -u "$kodi_username:$kodi_password" -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"Settings.GetSettings","params":{"level":"expert", "filter":{"section":"system", "category":"display"}},"id":1}' $kodi_host | jq 'first(.result.settings[] | select(.id=="videoscreen.resolution") | .options[] | select(.label | contains($kodi_resolution))| .value)' --arg kodi_resolution "$kodi_resolution")
	echo "new resolution id $kodi_resolutionid"

	curl -u "$kodi_username:$kodi_password" -H "Content-type: application/json" -X POST -d "{\"jsonrpc\":\"2.0\",\"method\":\"Settings.SetSettingValue\", \"params\":{\"setting\":\"videoscreen.resolution\",\"value\":$kodi_resolutionid},\"id\":1}" $kodi_host
;;

*)
	echo "Syntax: $0 <quit|res> <value>"
;;

esac

