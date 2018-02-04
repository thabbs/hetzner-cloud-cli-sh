# hetzner-cloud-cli-sh
Inofficial Bash command line interface for the Hetzner Cloud API.

Licensed under the MIT License.

Find the official Hetzner Cloud documentation at https://docs.hetzner.cloud

Use this script and all related files at your own risk.

This is not a complete implementation of the Hetzner Cloud API. It is just a tool to make
some things easier. Feel free to contribute and send your pull requests.


## Usage

    hetzner-cloud-cli.sh [scope] [ -c | -d | -s ] options [object]"
    
    
    Examples:
    hetzner-cloud-cli.sh servers --show
    hetzner-cloud-cli.sh servers
    hetzner-cloud-cli.sh
            Show all servers
    
    hetzner-cloud-cli.sh images --show
    hetzner-cloud-cli.sh images
            Show all available images
    
    hetzner-cloud-cli.sh servers -c -n my-server
    hetzner-cloud-cli.sh -c -n my-server
            Create a server in the default datacenter with default type
    
    hetzner-cloud-cli.sh servers -c -n my-server -S https://example.com/some/path/cloud-init.sh
    hetzner-cloud-cli.sh -c -n my-server -S https://example.com/some/path/cloud-init.sh
            Provision your server with a shell script provided at some url.
    
    hetzner-cloud-cli.sh -c -n my-server -k 120,567
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
    

