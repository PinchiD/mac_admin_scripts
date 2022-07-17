#!/bin/zsh

shell=$(ps | grep `echo $$` | awk '{ print $4 }' | grep -v grep)
echo $shell



# Establishing the logging variables
LOGFOLDER="/var/log"
LOGFILE="${LOGFOLDER}/WS1_Sensors.log"
search_domains=("example.local" "example.com" "domain3.co.il" "playtika.local") #use more if you wish
if [[ $shell != "zsh" ]]; then
	search_domains=$(printf '%s\n' "${search_domains[*]}")
fi


if [ ! -d "$LOGFOLDER" ];
then
	/bin/mkdir "$LOGFOLDER"
fi

if [ ! -f "$LOGFILE" ];
then
	/usr/bin/touch ${LOGFILE}
fi

# Establishing the logging functionality
function logme()
{
# Check to see if function has been called correctly
	if [ -z "$1" ]; then
		#/bin/echo "$(date '+%F %T') - logme function call error: no text passed to function! Please recheck code!"
		/bin/echo "$(date '+%F %T') - logme function call error: no text passed to function! Please recheck code!" >> ${LOGFILE}
		exit 1
	fi

# Log the passed details
	#/bin/echo "$(date '+%F %T') - $1"
	/bin/echo "$(date '+%F %T') - $1" >> ${LOGFILE}
}


logme "===Starting set_searchdomains Sensor==="


function active_interfaces {
  while read -r line; do
      sdev=$(echo "$line" | awk -F  "(, )|(: )|[)]" '{print $4}')
      sname=$(networksetup -listnetworkserviceorder | grep -B1 $sdev | awk 'NR==1{print}' |  sed "s/^[^ ]* //")
      #echo "Current service: $sname, $sdev, $currentservice"
      if [ -n "$sdev" ]; then
          ifout="$(ifconfig "$sdev" 2>/dev/null)"
          echo "$ifout" | grep 'status: active' > /dev/null 2>&1
          rc="$?"
          if [ "$rc" -eq 0 ]; then
              currentservice="$sname"
              currentdevice="$sdev"
              currentmac=$(echo "$ifout" | awk '/ether/{print $2}')

              # may have multiple active devices, so echo it here
              echo "$currentservice, $currentdevice, $currentmac"
          fi
      fi
  done <<< "$(networksetup -listnetworkserviceorder | grep 'Hardware Port')"

  if [ -z "$currentservice" ]; then
      logme "Could not find current service"
      exit 1
  fi
}

### Printing active interface to console
interface=$(active_interfaces)
logme "Active interface: $interface"

### interfaces name and number:
wifi_intfc=$(networksetup listallhardwareports | grep Wi-Fi -A 1 | awk 'NR==2{print $2}')
ethernet_int=$(printf "$interface\n" | grep -v Wi-Fi)
ethernet_interface_name=$(printf "$interface\n" | grep -v Wi-Fi | awk -F'[,]' {'print $1'})


####### Functions
function set_searchdomains {
  /usr/sbin/networksetup -setsearchdomains "${ethernet_interface_name}" $search_domains
}

function set_searchdomains_wifi {
  /usr/sbin/networksetup -setsearchdomains Wi-fi $search_domains
}


function get_searchdomains_eth {
  current_search_domains_eth=$(/usr/sbin/networksetup -getsearchdomains "${ethernet_interface_name}")
  search_domain_exist_eth=$(echo $current_search_domains_eth | grep "There aren't any Search Domains set")
}

function get_searchdomains_wifi {
  current_search_domains_wifi=$(/usr/sbin/networksetup -getsearchdomains Wi-fi)
  search_domain_exist_wifi=$(echo $current_search_domains_wifi | grep "There aren't any Search Domains set")
}
#######

get_searchdomains_eth
if [[ $search_domain_exist_eth ]]; then
  logme "No search domains configured to $ethernet_interface_name interface"
  logme "Configuring..."
  set_searchdomains
  sleep 2
  get_searchdomains_eth
  logme "$current_search_domains_eth is configured to the $ethernet_interface_name interface"
else
  logme "$current_search_domains_eth is configured to the $ethernet_interface_name interface"
fi

get_searchdomains_wifi
if [[ $search_domain_exist_wifi ]]; then
  logme "No search domains configured to Wifi interface"
  logme "Configuring..."
  set_searchdomains_wifi
  sleep 2
  get_searchdomains_wifi
  logme "$current_search_domains_wifi is configured on the Wifi interface"
else
  logme "$current_search_domains_wifi is configured on the Wifi interface"
fi

echo "$current_search_domains_wifi | $current_search_domains_eth"
