WIFI_STATUS=$(networksetup -getairportnetwork en0 | grep "Current Wi-Fi Network")
if [[ $WIFI_STATUS == "" ]]; then
  ICON=$WIFI_OFF
  LABEL="Off"
  COLOR=$RED
else
  SSID=$(networksetup -getairportnetwork en0 | grep "Current Wi-Fi Network" | cut -d ":" -f2 | xargs)
  ICON=$WIFI_ON
  LABEL="$SSID"
  COLOR=$WHITE
fi