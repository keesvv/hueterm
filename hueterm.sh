#!/usr/bin/env bash
cd /usr/share/hueterm
version="1.0.0-b"

# User settings
ip_address=$(jq -r .settings.ip_address /etc/hueterm/hueterm.json)
api_key=$(jq -r .settings.api_key /etc/hueterm/hueterm.json)
quiet=false
light_id=
command=

# Environment variables
api_url="http://$ip_address/api/$api_key"
lights_url="http://$ip_address/api/$api_key/lights"

# Functions
function display_help {
  echo -e "\e[1mUSAGE\e[0m"
  echo -e "\t -v|--version  Display the current version."
  echo -e "\t -h|--help     Show this screen."
  echo -e "\t -s|--settings Edit the configuration for HueTerm (required before use)."
  echo -e "\t -u|--update   Update HueTerm to the latest available version."
  echo -e "\t -q|--quiet    Suppress the output of messages.\n"
  echo -e "\t -i|--id       Specifies the light ID to use to execute the light command."
  echo -e "\t               To see the current available lights, type -l or --list."
  echo -e "\t -c|--command  Specify the light command to use to perform on the selected light ID."
  echo -e "\t -g|--get-prop Gets a property value from the current light ID."
  echo -e "\t -l|--list     List available lights and light IDs.\n"

  echo -e "\e[1mEXAMPLES\e[0m"
  echo -e "\t Turning a light on or off:"
  echo -e "\t \e[96m$0\e[0m -i 6 -c on:true"
  echo -e "\t \e[96m$0\e[0m -i 6 -c on:false\n"
  echo -e "\t You can also provide multiple commands and multiple light IDs at a time:"
  echo -e "\t \e[96m$0\e[0m -i 3,6 -c on:false,hue:30000,bri:120"
  echo -e "\t \e[96m$0\e[0m -i 3,4,6 -c effect:colorloop\n"
  echo -e "\t Suppressing messages for automated scripts:"
  echo -e "\t \e[96m$0\e[0m -q -i 6 -c alert:select"
}

function send_request {
  curl -s -X PUT -d "$2" $api_url/$1 > /dev/null
}

function list_available_lights {
  lights_available=$(curl -s $lights_url | jq .)
  if [[ "$lights_available" == "" ]] || [[ "$lights_available" = *"error"* ]]; then
    echo "No lights available. Have you properly configured /etc/hueterm/hueterm.json?" | less
  else
    echo "$lights_available" | less
  fi
}

function get_property_value {
  if [[ "$light_id" != "" ]]; then
    curl -s $lights_url/$light_id | jq -r .state.$1
  else
    echo -e "You need to supply a light ID using the '-i' option.\n"
    display_help
  fi
}

while getopts ":vhsuqli:c:g:" opt; do
  case $opt in
    v)
      echo -e "\e[1mHueTerm \e[92mv$version\e[0m // Created by \e[96mDeadNet.\e[0m" && exit 0
      ;;

    h)
      display_help && exit 0
      ;;

    s)
      sudo -p "Password: " nano -AED /etc/hueterm/hueterm.json
      ;;

    u)
      ./install.sh && exit 0
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

    g)
      get_property_value "$OPTARG" && exit 0
      ;;

    l)
      list_available_lights && exit 0
      ;;

    \?)
      echo -e "Invalid option: '-$OPTARG'\n" >&2
      display_help
      exit 1
      ;;

    :)
      echo -e "Option '-$OPTARG' requires an argument.\n" >&2
      display_help
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
        echo -e "Executing command \e[93m$cmd\e[0m on light \e[93m$id\e[0m."
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
    echo -e "There was no light ID or light command given.\n"
    display_help
  fi
  exit 1
fi
