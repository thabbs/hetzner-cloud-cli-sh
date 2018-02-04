#!/bin/bash

CDIR=$HOME/.config/hetzner
CONFIG=${CDIR}/cloud-cli-sh-config

if [ ! -f $CONFIG ]
then
  mkdir -p ${CDIR}
  cat <<EOF > ${CONFIG}
# hetzner-cloud-cli-sh
# Thomas Abraham, 2018
# https://github.com/thabbs/hetzner-cloud-cli-sh
#
# configuration file - adjust to your needs
#
# Besides of TOKEN any option has its own switch on command line.
# Not all options are configurable here.
# See -h or --help for all options.
#
#
# TOKEN is required.
TOKEN=''

# [show|create|delete]
# runtime options: -s|--show -c|--create -d|--delete
# default: -s
ACTION='show'

# see https://api.hetzner.cloud/v1/server_types
# option: -t|--type string
# default: -t cx11-ceph
TYPE=cx11-ceph

# comma separated list of ssh_keys to inject into a server
# option: -k|--keys list
# default: unset
KEYS=''

# datacenter
# option: -D|--datacenter string
# default: -D fsn1-dc8
DC=fsn1-dc8

# OS image
# option: -i|--image int|string
# default: -i 3 (CentOs 7.4)
IMAGE=3

# user-data is a string which must be compatible to cloud-config
# see http://cloudinit.readthedocs.io/en/latest/topics/examples.html
# In complex setups consider to provide a script url instead (see -S|--script-url)
# option: -U|--user-data string
# default: unset
USER_DATA=""

EOF
fi

. ${CONFIG}

if [ -z ${TOKEN} ]
then
  echo specifiy your API token in ${CONFIG}.
  exit 1
fi


# default values
[ -z ${ACTION} ]     && ACTION='show'
[ -z ${TYPE} ]       && TYPE=cx11-ceph
[ -z ${KEYS} ]       && KEYS=4580
[ -z ${DC} ]         && DC=fsn1-dc8
[ -z ${IMAGE} ]      && IMAGE=3 # centos 7.4 
[ -z ${USER_DATA} ]  && USER_DATA=""
[ -z ${SCOPE} ]      && SCOPE='servers'



function help {
  cat <<EOF

  |-----------------------------------------------------------|
  | hetzner-cloud-cli-sh                                      |
  | Thomas Abraham, 2018                                      |
  | https://github.com/thabbs/hetzner-cloud-cli-sh            |
  |                                                           |
  | Inofficial Bash client for the Hetzner Cloud API.         |
  | Licensed under the MIT License.                           |
  | You should have received the LICENSE file                 |
  | with this script.                                         |
  |                                                           |
  | Find the official Hetzner Cloud documentation             |
  | at https://docs.hetzner.cloud                             |
  |                                                           |
  | Use this script and all related files at your own risk.   |
  |                                                           |
  | This script is not a complete implementation of           |
  | the Hetzner Cloud API. It is just a tool to make          |
  | some things easier. Feel free to contribute and send your |
  | pull requests to                                          |
  | https://github.com/thabbs/hetzner-cloud-cli-sh            |
  |-----------------------------------------------------------|


  Usage:
  $1 [scope] [ -c | -d | -s ] options [object]"


  Examples:
  $1
  $1 servers
  $1 servers --show
          Show all servers

  $1 -c -n my-server-name
  $1 servers -c -n my-server
          Create a server in the default datacenter with default type

  $1 servers -c -n my-server -S https://example.com/some/path/cloud-init.sh
          Provision your server with a shell script provided at some url.

  $1 servers -c -n my-server -k 120,567
          Create a default server. Inject keys 120 and 567

  1. Scope
  One of servers, datacenters, images, ssh_keys
  default: servers

  2. Actions
  -s, --show       show
  -c, --create     create
  -d, --delete     delete

  3. Options and their arguments
  -n, --name       string
                   A user friendly name of your ressource.

  -t, --type       string
                   Server type, see https://api.hetzner.cloud/v1/server_types
                   default: cx11-ceph

  -K, --key-file   filename
                   Local file containing a ssh public key.
                   Mandatory with ssh_keys.
                   default: unset

  -k, --keys       list
                   Comma separated list of ssh_keys to inject into a server
                   default: unset

  -D, --datacenter string
                   Data center
                   default: fsn1-dc8

  -l, --location   string
                   default: unset

  -i, --image      string or integer
                   OS image
                   default: 3 (CentOs 7.4)

  -U, --user-data  string
                   Must be compatible to cloud-config (see
                   http://cloudinit.readthedocs.io/en/latest/topics/examples.html)
                   In complex setups consider to provide a script url instead
                   (see -S|--script-url)
                   default: unset

  -S, --script-url url
                   Injecting complex shell scripts into cloud-init is not recommended.
                   Hetzner Cloud does not seem to provide, yet, the ability to pass
                   base64 encoded user-data. Hence this option should help to support
                   your bash script. Upload it to a server and let cloud-init take care
                   of downloading and executing it at first boot.
                   Be aware that your script does not open security holes.
                   Passwords, private keys shouldn't be in there.

EOF


}


# servers, datacenters, images, ssh_keys
case $1 in
  servers|datacenters|images|ssh_keys)
    SCOPE=$1
    shift
    ;;
esac


function argXor {
    echo "Only one of these options is allowed: ${@}"
    exit 1
}

while [ $# -gt 0 ]
do
    case $1 in
    -c|--create)
      ACTION=create
      ;;
    -d|--delete)
      ACTION=delete
      ;;
    -D|--datacenter)
      shift
      DC=$1
      ;;
    -i|--image)
      shift
      IMAGE=$1
      ;;
    -h|--help)
      help $0
      exit
      ;;
    -K|--key-file)
      shift
      KEY=$1
      ;;
    -k|--keys)
      shift
      KEYS=$1
      ;;
    -l|--location)
      shift
      LOCATION=$1
      ;;
    -n|--name)
      shift
      NAME=$1
      ;;
    -s|--show)
      ACTION=show
      ;;
    -S|--script-url)
      [ "${USER_DATA}" != "" ] && argXor '-S|--script-url' '-U|--user-data'
      shift
      USER_DATA="#cloud-config\\nruncmd:\\n  - curl --silent ${1} > /tmp/cloud-init.sh\\n  - /bin/bash /tmp/cloud-init.sh\\n"
      ;;
    -t|--type)
      shift
      TYPE=$1
      ;;
    -U|--user-data)
      [ "${USER_DATA}" != "" ] && argXor '-S|--script-url' '-U|--user-data'
      shift
      USER_DATA=$1
      ;;
    [a-zA-Z0-9]??*)
    # ??? an object ID should have at least three digits or characters ???
      OBJECT=$1
      break;
      ;;
    *)
      echo "invalid parameter: ${1}"
      exit 1
      ;;
    esac

    shift

done

function show {
  curl -H "Authorization: Bearer ${TOKEN}" \
    https://api.hetzner.cloud/v1/${1}
}

function create {
SCOPE=$1
JSON="$2"
  curl --silent -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" \
  -d "${JSON}" \
    https://api.hetzner.cloud/v1/${1}
}

function delete {
  SCOPE=$1
  ID=$2
  curl -X DELETE -H "Authorization: Bearer ${TOKEN}" \
    https://api.hetzner.cloud/v1/${SCOPE}/${ID}
}

function missingArg {
  echo "${SCOPE} requires: ${1}"
  exit 42
}

function error {
  echo error
  exit 43
}


function fileExists {
  if [ ! -r "${1}" ]
  then
    echo "file '${1}' does not exist or is not readable"
    exit 44
  fi
}


function checkArgs {
  case $1 in
  ssh_keys)
    if [ "${KEY}" == "" -o "${NAME}" == "" ]
    then
      missingArg "--name, --key"
    fi
    fileExists "${KEY}"
  ;;
  esac
}


function assembleJson {
echo '{'
  case $1 in
  ssh_keys)
cat <<EOF
    "name": "${NAME}",
    "public_key": "$(cat $KEY)"
EOF
  ;;
  servers)
if [ "${USER_DATA}" != "" ]
then
cat <<EOF
    "user_data": "${USER_DATA}",
EOF
fi
cat <<EOF
    "name": "${NAME}",
    "server_type": "${TYPE}",
    "datacenter": "${DC}",
    "image": "${IMAGE}",
    "ssh_keys": [ ${KEYS} ]
EOF
  ;;
  esac
echo '}'
}

if [ $ACTION == show ]
then
  show $SCOPE
  exit
fi

if [ $ACTION == create ]
then
  checkArgs $SCOPE
  JSON="`assembleJson $SCOPE`"
  create $SCOPE "$JSON"
  exit
fi

if [ $ACTION == delete ]
then
  if [ "${OBJECT}" == "" ]
  then
    echo specify an object to delete in ${SCOPE}
    exit 2
  fi
  delete $SCOPE $OBJECT
  exit
fi

exit

