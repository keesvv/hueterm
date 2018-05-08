#!/usr/bin/env bash
version="1.0.0-b"

# User settings
ip_address=$(jq -r .settings.ip_address hueterm.json)
api_key=$(jq -r .settings.api_key hueterm.json)
quiet=false
light_id=
command=

# Environment variables
api_url="http://$ip_address/api/$api_key"
lights_url="http://$ip_address/api/$api_key/lights"

# Functions
function display_help {
  echo -e "Usage:"
  echo -e "\t -v|--version  Display the current version."
  echo -e "\t -h|--help     Show this screen."
  echo -e "\t -q|--quiet    Suppress the output of messages.\n"
  echo -e "\t -i|--id       Specifies the light ID to use to execute the light command."
  echo -e "\t               To see the current available lights, type -l or --list."
  echo -e "\t -c|--command  Specify the light command to use to perform on the selected light ID."
  echo -e "\t -l|--list     List available lights and light IDs.\n"

  echo -e "Examples:"
  echo -e "\t Turning a light on or off:"
  echo -e "\t $0 -i 6 -c on:true"
  echo -e "\t $0 -i 6 -c on:false\n"
  echo -e "\t You can also provide multiple commands and multiple light IDs at a time:"
  echo -e "\t $0 -i 3,6 -c on:false,hue:30000,bri:120"
  echo -e "\t $0 -i 3,4,6 -c effect:colorloop\n"
  echo -e "\t Suppressing messages for automated scripts:"
  echo -e "\t $0 -q -i 6 -c alert:select"
}

function send_request {
  curl -s -X PUT -d "$2" $api_url/$1 > /dev/null
}

function list_available_lights {
  echo "Available lights:"
  curl -s $lights_url | jq .
}

while getopts ":vhqli:c:" opt; do
  case $opt in
    v)
      echo "HueTerm v$version -- Created by DeadNet." && exit 0
      ;;

    h)
      display_help && exit 0
      ;;

    q)
      quiet=true
      ;;

    i)
      light_id="$OPTARG"
      ;;

    c)
      command="$OPTARG"
      ;;

    l)
      list_available_lights && exit 0
      ;;

    \?)
      echo "Invalid option: '-$OPTARG'" >&2
      echo "Try typing $0 -h"
      exit 1
      ;;

    :)
      echo "Option '-$OPTARG' requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ "$command" != "" ]] && [[ "$light_id" != "" ]]; then
  IFS=',' read -ra lights_ids <<< "$light_id"
  for id in "${lights_ids[@]}"; do
    IFS=',' read -ra commands <<< "$command"
    for cmd in "${commands[@]}"; do
      IFS=':' read -ra split <<< "$cmd"
      cmd_id=${split[0]}
      cmd_value=${split[1]}

      if [[ $quiet = false ]]; then
        echo "Executing command $cmd on light $id."
      fi

      if [[ $cmd_value =~ [0-9] ]] || [[ $cmd_value = false ]] || [[ $cmd_value = true ]]; then
        send_request lights/$id/state "{\"$cmd_id\":$cmd_value}"
      else
        send_request lights/$id/state "{\"$cmd_id\":\"$cmd_value\"}"
      fi
    done
  done
else
  if [[ $quiet = false ]]; then
    echo "There was no light ID or light command given."
  fi
  exit 1
fi
