#!/bin/sh
usage() {
    echo "Usage: $0 [-t TYPE] [-v RIAK_VSN] [-O OTP_VSN] [-X EXTRA_VSN] [-n NODENAME] [-j JOIN_TO]"
    echo "          [-c COOKIE] [-r RINGSIZE] [-l LOCAL_PKG] [-f LOCAL_CONFIG] [-b BACKEND]"
    echo "          [-a DATADIR] [-o OS_OVERRIDE]"
    echo "          [-u CS_ADMIN_USER] [-e CS_ADMIN_EMAIL] [-k CS_ADMIN_KEY] [-m CS_KV_VSN]"
    echo "          [-p] [-g] [-y] [-h]" 1>&2
    exit 1
}

## Read in any user provided flags and assign to the correct variables
while getopts 't:O:n:j:c:r:l:v:f:b:d:a:i:o:u:e:k:e:pgyh' c
do
    case $c in
        t) type=$OPTARG ;;
        O) otp=$OPTARG ;;
        X) extra_vsn=$OPTARG ;;
        n) nodename=$OPTARG ;;
        j) joining=$OPTARG ;;
        c) cookie=$OPTARG ;;
        r) ringsize=$OPTARG ;;
        l) package=$OPTARG ;;
        v) subver=$OPTARG ;;
        f) config=$OPTARG ;;
        b) backend=$OPTARG ;;
        d) datadir=$OPTARG ;;
        a) aae=$OPTARG ;;
        i) interface=$OPTARG ;;
        s) search=$OPTARG ;;
        o) override=$OPTARG ;;
        u) user=$OPTARG ;;
        e) email=$OPTARG ;;
        k) key=$OPTARG ;;
        m) kvpackage=$OPTARG ;;
        p) performance=1 ;;
        g) generate=yes ;;
        y) yes=1 ;;
        h) help=1 ;;
    esac
done

override=${override:-$os_override}
user=${user:-$cs_admin_user}
email=${email:-$cs_admin_email}
key=${key:-$cs_admin_key}
generate=${generate:-$cs_admin_generate}

packagerepo=${packagerepo:-https://files.tiot.jp/riak}
prepare_for_riak_control=${prepare_for_riak_control:-no}
ssl_bundle_url=${ssl_bundle_url:-}

yes=1

if [ "$help" = 1 ]
  then
  echo "Welcome to the Riak Installer Help Section"
  echo ""
  echo "This program should detect your operating system and help you install a matching Riak package on it."
  echo ""
  echo "Usage: ./install-riak.sh [OPTIONS]"
  echo ""
  echo "When run with no options, it will prompt you for user input on each step."
  echo "If you use one or more options, questions related to that option will be bypassed in the installer."
  echo ""
  echo "-t    Type of Riak. Valid options are \"kv\", \"cs\" and \"ts\"."
  echo "-O    OTP version (i.e., 24, 26, etc)."
  echo "-n    Nodename. This needs to be name@IP or name@FQDN e.g. dev1@10.2.3.4 or riak@prod01.my.domain.com"
  echo "-j    Joining. If your node is joining a pre-existing cluster, enter the nodename of an existing node to join."
  echo "-c    Cookie. The pre-shared cookie for all nodes in this cluster. Regular text accepted but no spaces."
  echo "-r    Ring size. The number of shards in the database. Needs to be a power of 2. Recommend 1024 for 3.x versions."
  echo "-l    Local package. If you are installing from a locally downloaded package, specify the full path and filename."
  echo "-v    Version. The version number of the type of Riak you are installing e.g. for KV \"3.0.16\" or \"3.2.1\"."
  echo "-f    Folder location of pre-existing config. If you have customized config files to use, specify the folder."
  echo "-b    Backend. This is the storage backend. Valid options are \"bitcask\", \"leveldb\" and \"leveled\"(KV>2.9.0)."
  echo "-d    Data Directory. This is the path to where Riak stores the actual data. Default is \"/var/lib/riak\"."
  echo "-a    AAE. The type of Active Anti-Entropy. Valid options are \"legacy\" and \"tictac\" (KV>2.9.0)."
  echo "-i    Interface. This is the IP of the interface that Riak will listen on e.g. \"0.0.0.0\", \"127.0.0.1\", \"10.0.0.1\"."
  echo "-s    Search settings. This is where you can specify settings for the JVM if you plan to use Yokozuna."
  echo "-p    Performance. Allow the installer to attempt to tune the ulimit setting for the Riak user for better performance."
  echo "-o    Override. This will override the OS version the script auto detects e.g. \"-o trusty\" when on 2.1.3 with Ubuntu"
  echo "      Jammy or \"-o 7\" with rhel 9. This is useful when using an OS for which a package does not exist for your desired version."
  echo "-y    Yes. Automatically agree to all confirmation steps in the installer - essentially an unattended install."
  echo "-h    Help. Display this help screen again."
  echo ""
  echo "Riak CS Only Options:"
  echo "-l    CS Local package. If you are installing from a locally downloaded CS package, specify the full path and filename."
  echo "-m    KV local package. If you are installing from a locally downloaded KV package, specify the full path and filename."
  echo "NOTE: Riak CS needs BOTH Riak KV AND Riak CS to function correctly. However, the installer will download one or both if needed."
  echo "-g    Generate an admin user (requires a username and email address to be set with -u and -e options)."
  echo "-u    Specify the admin user name."
  echo "-e    Specify the admin email address."
  echo "-k    Specify the admin key if one has already been created."
  echo "NOTE: -g and -k are mutually exclusive. Do not attempt to use -g and -k together."
  echo ""
  echo "Example of an unattended standalone Riak KV 3.0.16 setup:"
  echo "./install-riak.sh -t kv -n riak@10.0.0.1 -c riakcookie -v 3.0.16 -b leveled -a tictac -i 0.0.0.0 -r 256 -y"
  echo ""
  echo "Found a bug? Report it on https://github.com/ti-tokyo/install_riak"
  echo "Need extra Riak help? Email info@tiot.jp"
  exit
fi

## Get "OS" from uname to check for OSX
os=$(uname -a | cut -d " " -f 1)

if [ "$os" = "Darwin" ]
  then
  ## Now we know it's OSX, use Apple specific commands to get details
  os="osx"
  version=$(sw_vers -productVersion)
  ospretty=$(sw_vers -productName)
  riakstart="sudo riak start"
  riakstop="sudo riak stop"
  riakcsstart="sudo riak-cs start"
  riakcsstop="sudo riak-cs stop"
else
  ## As all other POSIX systems tried have /etc/os-release with useful details, use those
  os=$(grep "^ID=" /etc/os-release | cut -d "=" -f 2 | sed "s@\"@@g")
  version=$(grep "^VERSION_ID=" /etc/os-release | cut -d "=" -f 2 | sed "s@\"@@g")
  ospretty=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d "=" -f 2 | sed "s@\"@@g")
  #riakstart="sudo systemctl start riak"
  #riakstop="sudo systemctl stop riak"
  #riakcsstart="sudo systemctl start riak-cs"
  #riakcsstop="sudo systemctl stop riak-cs"
  riakstart="sudo riak start"
  riakstop="sudo riak stop"
  riakcsstart="sudo riak-cs start"
  riakcsstop="sudo riak-cs stop"
fi

## Get architecture
arch=$(uname -m)
bit=$(getconf LONG_BIT)

## Adjust $os to match OS name on the downloads server, set the package type and installer command
if [ "$os" = "amzn" ]
  then
  os="amazon"
  packagetype="rpm"
  if [ "$version" = "2" ] || [ "$version" = "2016" ] || [ "$version" = "1" ]
    then
    installer="yum localinstall -y "
    if [ "$arch" = "x86_64" ]
      then
      version="2 (x86_64)"
    else
      version="2 (graviton 3)"
    fi
  fi
  if [ "$version" = "2023" ]
    then
    installer="rpm -i --nodeps "
    if [ "$arch" = "x86_64" ]
      then
      version="2023 (x86_64)"
    else
      version="2023 (graviton 3)"
    fi
  fi
fi
if [ "$os" = "centos" ]; then os="rhel"; packagetype="rpm"; installer="yum localinstall -y "; fi
if [ "$os" = "ol" ]; then os="oracle"; packagetype="rpm"; installer="yum localinstall -y "; fi
if [ "$os" = "rhel" ]; then packagetype="rpm"; installer="yum localinstall -y "; fi
if [ "$os" = "suse" ]; then os="rhel"; packagetype="rpm"; installer="zypper install "; fi
if [ "$os" = "ubuntu" ]
  then
  version="$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d '=' -f 2 | sed 's@\"@@g')$bit"
  packagetype="deb"
  installer="dpkg -i"
fi
if [ "$os" = "kali" ]
  then
  os="ubuntu"
  version="jammy$bit"
  packagetype="deb"
  installer="dpkg -i "
  riakstart="sudo riak start"
  riakstop="sudo riak stop"
  riakcsstart="sudo riak-cs start"
  riakcsstop="sudo riak-cs stop"
fi
if [ "$os" = "debian" ]; then packagetype="deb"; installer="dpkg -i "; fi
if [ "$os" = "raspbian" ]; then packagetype="deb"; installer="dpkg -i "; fi
if [ "$os" = "freebsd" ]
  then
  packagetype="pkg"
  installer="pkg add "
  version=$(echo $version | cut -d "." -f 1)
  case $version in
    10) version="10.4" ;;
    11) version="11.1" ;;
    12) version="12.1" ;;
    13) version="13.0" ;;
    14) version="14.0" ;;
  esac
  riakstart="sudo riak start"
  riakstop="sudo riak stop"
  riakcsstart="sudo riak-cs start"
  riakcsstop="sudo riak-cs stop"
fi
if [ "$os" = "alpine" ]
  then
  packagetype="apk"
  installer="apk add "
  riakstart="sudo riak start"
  riakstop="sudo riak stop"
  riakcsstart="sudo riak-cs start"
  riakcsstop="sudo riak-cs stop"
fi
if [ "$os" = "osx" ]; then packagetype="tar.gz"; installer="tar -xvf "; fi
if [ -n "$override" ]; then version="$override"; fi


## Define a "Yes or No" function that will be used multiple times throughout the script.
yes_or_no () {
    if [ "$yes" = "1" ]; then
        return 0
    else
        while true; do
            read -p "$* [y/n]: " yn
            case $yn in
                [Yy]*) return 0 ;;
                [Nn]*) return 1 ;;
            esac
        done
    fi
}

## Time to greet the users!

echo "Welcome to the Riak easy installer!"
echo ""
echo "This installer is recommended for new uers to Riak or for those who just need to get a test node up quickly."
echo "Although basic configuration is available through this installer, please consult the docs on"
echo "https://www.tiot.jp/riak-docs/ for details on further configuration."
echo ""
echo "Please answer the following yes/no questions and provide details when prompted."
echo "Assuming you decide to begin the install, you may need the sudo password."
echo "If you choose the wrong answer by mistake, you can drop out of the installer with Ctrl-C and restart it."
echo ""
echo "Please note that this installer needs to be run on the intended Riak node and requires an internet connection"
echo "unless you pre-downloaded the desired package and specified its location and filename with the -l flag when"
echo "calling this script."
echo ""
echo "* For additional installer options such as installing from local storage, please exit and re-run with \"-h\""
echo ""
message="Are you ready to proceed?"
if yes_or_no "$message"
  then
  echo "Thank you."
else
  echo "Exiting. Have a nice day!"
  exit
fi

## Set type (KV, CS or TS) unless pre-set by the calling command
if [ -z "$type" ]
  then
  echo "First of all, we're going to ask you to choose the desired flavour of Riak that you would like to use."
  echo "Are you looking for the most commonly used key/value store, Riak KV?"
  message="(This will give you key/value storage in addition to CRDTs)"
  if yes_or_no "$message"
    then
    echo "Type set to Riak KV"
    type="kv"
  else
    echo ""
    message="Are you looking to store large files in an s3 compatible environment?"
    if yes_or_no "$message"
      then
      echo "Type set to Riak CS"
      type="cs"
    else
      echo ""
      echo "Assuming that you are looking for Riak TS, the time series option with basic SQL capablilities."
      echo "Type set to Riak TS"
      type="ts"
    fi
  fi
fi
echo ""
echo "If you are unhappy with your type selection, remember that you can exit the installer with Ctrl-C and start again"
echo ""

## Set node name unless pre-set or using local config files

if [ -z "$nodename" ] && [ -z "$config" ]
  then
  echo "What node name would you like to give this node? Here are some examples of acceptible formats:"
  echo ""
  echo "riak@192.168.10.5"
  echo "prod1@some.domain.name"
  echo ""
  echo "Note how each one has three parts - the local identifier, the \"@\" and the location identifier. All three parts"
  echo "are needed to generate a nodename that is usable by Riak."
  echo ""
  echo "Please note that if using an IP address, that IP address must be allocated uniquely to this node. Also, if using"
  echo "a fully qualified domain name (FQDN), that must map to an IP address on this node via either DNS or /etc/hosts."
  echo "Additionally, if you plan to use more than one node in this cluster, do not use a loopback IP address such as "
  echo "\"127.0.0.1\". However, if you plan to use this as only a standalone node, this loopback address is fine."
  echo ""
  echo "Please enter your desired nodename underneath and press enter"
  read nodename
  echo ""
else
## If a set of config files have been specified, retrieve the nodename from there
  if [ -n "$config" ]
    then
    nodename=$(grep "^nodename =" $config/riak.conf | cut -d "=" -f "2")
  fi
fi

## Attempt to work out what the IP address of the node is based on the nodename
echo "Checking nodename settings, please ignore any error messages displayed here."

## Grab the second part of the nodename e.g. riak@127.0.0.1 or prod@prod1.example.com as 127.0.0.1 or prod1.example.com
maybeFQDN=$(echo $nodename | cut -d '@' -f 2 | xargs)
## Is the potential FQDN uncommented in the hosts file and separated by a tab?
ipaddr=$(grep $maybeFQDN /etc/hosts | grep -v "#" | head -n 1 | cut -f 1)
if [ -z "$ipaddr" ]
  then
## How about separated by space(s)?
  ipaddr=$(grep $maybeFQDN /etc/hosts | grep -v "#" | head -n 1 | cut -d " " -f 1)
  if [ -z "$ipaddr" ]
    then
## Is it resolvable as an IPv4 address via DNS (using `ping` as `dig`` is not installed by default on some OS)
    ipaddr=$(ping $maybeFQDN -c 1 -4 | grep "64 bytes" | cut -d " " -f4)
    if [ -z $(ipaddr) ]
      then
## How about as an IPv6 address?
      ipaddr=$(ping $maybeFQDN -c 1 -6 | grep "64 bytes" | cut -d " " -f4)
    else
## OK, having tried everything else in case it's an FQDN, this is probably a hard coded IP
      ipaddr=$(echo $maybeFQDN | xargs)
    fi
  fi
fi
## If the IP address contains spaces, just return the IP address at the start
ipaddr=$(echo $ipaddr | cut -d " " -f 1)

## Set shared cookie if not already set

## If no version has been set, default to 3.0.16 for KV and 3.0.1 for TS. CS needs two subversions, KV and CS with CS being 3.2.5
if [ -z "$subver" ]
  then
  case $type in
  cs) subver="3.2.5"; kvsubver="3.2.6" ;;
  kv) subver="3.2.6" ;;
  ts) subver="3.0.1"  ;;
  esac
  echo "No version specified for Riak $(echo $type | tr '[:lower:]' '[:upper:]')."
  if [ $type = "cs" ]
    then
    echo "Defaulting to version $subver with Riak KV version $kvsubver."
  else
    echo "Defaulting to version $subver."
  fi
else
  echo "Using user specified Riak $(echo $type | tr '[:lower:]' '[:upper:]') version of $subver."
fi

##Check which form of riak admin/riak-admin and riak repl (for future usage) should be used based on top level version
topver=$(echo $subver | cut -d "." -f 1)
if [ "$topver" = "2" ] || [ "$topver" = "1" ]
  then
  riakadmin="riak-admin"
  riakrepl="riak-repl"
  riakcsadmin="riak-cs-admin"
  else
  riakadmin="riak admin"
  riakrepl="riak repl"
  riakcsadmin="riak-cs admin"
fi
## In the case of the CS version being set by a flag to the installer, the KV version is not set. Adding the best matches here.
if [ "$type" = "cs" ] && [ -z ${kvsubver} ]
  then
  if [ "$topver" = "3" ]
    then
    kvsubver="3.2.0"
  else
    kvsubver="2.9.10"
  fi
fi
echo ""

## Set ring size if not already set

if [ -z "$ringsize" ] && [ -z "$config" ]
  then
  echo "What ring size should your cluster have? This should be a power of 2."
  if [ "$topver" = "2" ] || [ "$topver" = "1" ]
    then
    echo "For 2.x versions of Riak, approximate recommendations are as follows:"
    echo ""
    echo "+-------+---------------+"
    echo "| Nodes |   Ring Size   |"
    echo "+-------+---------------+"
    echo "|    ~5 |       64, 128 |"
    echo "|     6 |  64, 128, 256 |"
    echo "|  7-10 |      128, 256 |"
    echo "| 11-12 | 128, 256, 512 |"
    echo "| 13-15 |      256, 512 |"
    echo "|   15+ |     512, 1024 |"
    echo "+-------+---------------+"
    echo ""
    echo "These recommendations are for general use but use case specific ring sizes may be larger or smaller than the above numbers." 
    echo ""
  else
    echo "Riak KV 3.x and above use a newer version of OTP that does not suffer from the size restrictions encountered in 2.x."
    echo "The standard recommended ring size for recent (3.x and higher) versions is 1024."
    echo "Please note that all nodes in a cluster need to have the same value set for ring size."
    echo ""
  fi
  echo "Please enter your desired ring size underneath."
  read ringsize
  echo ""
fi

## Yokozuna

if [ -n "$search" ] && [ "$type" = "kv" ]
  then
  echo "This section is regarding Yokozuna, a search feature that uses Solr from the Apache project."
  echo "Most use cases do not require Yokozuna, especially as the Solr JVM makes it surprisingly memory hungry."
  echo "If you need to use Yokozuna, you will have needed to specify leveldb as your backend and use"
  echo "Legacy AAE."
  echo ""
  message="Do you plan to use Yokozuna"
  if yes_or_no "$message"
    then
    echo "As you may be aware, Yokozuna runs a Java Virtual Machine (JVM) which usually needs to be tuned."
    echo "The default options are:"
    echo "-d64 -Xms 1g -Xmx 1g -XX:+UseStringCache -XX:+UseCompressedOops"
    echo ""
    echo "Not all of these are compatible with all versions of Java. Commonly \"-d64\" and \"-XX:UseStrongCache\""
    echo "can cause Yokozuna to fail to start. Also, note the minimum and maximum amounts of memory available for"
    echo "the JVM to use should be adjusted based on your node's physical memory. Usually \"-Xmx\" should be 40-50%"
    echo "of your node's total memory whilst \"-Xms\" is commonly between 5 and 25% depending on use case. Trial"
    echo "and error tuning is recommended and you can revisit this setting in /etc/riak/riak.conf near the end of"
    echo "the file when needed."
    echo ""
    echo "Note: when tuning this setting, a restart of Riak is required for the changes to take effect."
    echo ""
    echo "Please enter the desired JVM settings. If unsure, copy and paste the default for now and tune later."
    read search
  else
    echo "Leaving Yokozuna disabled as this is the default settting. The JVM will not be used."
  fi
  echo ""
fi
## Time for a bit more complicated stuff where we auto-config some things based on
## previous user input and other stuff based on extra details we need to know

## First set backend and AAE automatically if TS, CS or using Yokozuna
if [ "$type" = "ts" ] || [ "$type" = "cs" ] || [ -n "$search" ]
  then
  backend="leveldb"
  aae="legacy"
else
## Give backend options
  if [ -z "$backend" ] && [ -z "$config" ]
    then
    echo "First, we shall look at database backends."
    echo "NOTE: this installer is not capable of configuring multiple backends except the default one for Riak CS." 
    echo "If you need to set multi-backends, please exit the installer when it prompts you to start Riak and configure manually"
    echo "If you are unsure which backend you should use, simply answer \"no\" to the following two questions"
    echo ""
    message="Does you you plan to have a comparatively small quantity (a few million items) of large (>1MB) data?"
    if yes_or_no "$message"
      then
      echo "Setting backend to Bitcask"
      backend="bitcask"
    else
      echo "Do you need indexing functionality for things such as secondary indexes (2i) or does your"
      message="setup need to handle large quantities of tiny data e.g. 100s of millions of <2KB files?"
      if yes_or_no "$message"
        then
        echo "Setting backend to Leveldb"
        backend="leveldb"
      else
        echo "Setting backend to Leveled"
        backend="leveled"
      fi
    fi
    echo ""
  fi

## Give AAE options but do not present "disabled" (passive) as an option.
  if [ -z "$aae" ] && [ -z "$config" ]
    then
    echo "Next we are going to set up Active Anti-Entropy (AAE)."
    echo "Unless you have a strong reason to use the legacy AAE from 2016 e.g. future plans to use Yokozuna or CS,"
    echo "it is generally recommended to use TicTacAAE."
    message="Do you wish to use TicTacAAE?"
    if yes_or_no "$message"
      then
      echo "Setting AAE to TicTacAAE."
      aae="tictac"
    else
      echo "Setting AAE to legacy."
      aae="legacy"
    fi
    echo ""
  fi
fi

## Set data directory

if [ -z "$datadir" ] && [ -z "$config" ]
  then
  echo "Where would you like to save your data? The default path is /var/lib/riak. It is possible to use a dedicated hard disk mounted here or mount it at a different location"
  echo "and use that for your data directory. Either way, please mount dedicated drives with the \"noatime\" flag in /etc/fstab for better performance."
  message="Would you like to use the default path of /var/lib/riak?"
  if [ yes_or_no "$message"
    then
    echo "Leaving it as /var/lib/riak"
    datadir="/var/lib/riak"
  else
    echo "Please enter new data directory path (without a trailing slash)."
    read datadir
  fi
  echo ""
fi

## Set listening interface

if [ -z "$interface" ] && [ -z "$config" ]
  then
  echo "Finally, we are going to determine which interface(s) Riak should listen on."
  message="Can Riak listen on all interfaces (recommended)?"
  if yes_or_no "$message"
    then
    echo "Setting listener to listen on 0.0.0.0 (all interfaces)."
    interface="0.0.0.0"
  else
    message="Should Riak only listen on localhost i.e. 127.0.0.1 (default but cannot be used in a cluster)?"
    if yes_or_no "$message"
      then
      echo "Setting listener to listen on 127.0.0.1 (localhost only)."
      interface="127.0.0.1"
    else
      echo "What IP4 address should Riak listen on?"
      echo "Note: must be a valid IPv4 address that resolves to this machine."
      read interface
    fi
  fi
  echo ""
fi

## Do some CS only settings

if [ "$type" = "cs" ]
  then
  if [ -z "$generate" ]
    then
    if [ -z "$key" ]
    then
      echo "Riak CS requires an admin key to perform some functions. This is commonly generated by the first node in a cluster."
      echo "If you do not currently have an admin key, this can be generated later."
      message="Do you have an admin key generated by another CS node in this cluster?"
      if yes_or_no "$message"
        then
        echo "Please enter the admin key below. The admin secret is not required here."
        read key
      else
        echo "Not a problem."
        echo ""
        echo "To generate an admin key, you need to provide a username and email address for the admin user."
        echo "If an admin key already exists but you do not have it to hand, do not attempt to generate another one."
        message="Would you like to generate an admin key?"
        if yes_or_no "$message"
          then
          generate=yes
          if [ -z "$user" ]
            then
            echo "Please provide a username e.g. \"admin\" or \"sausage\""
            read user
          else
            echo "Username of $user already provided."
          fi
          if [ -z "$email" ]
            then
            echo "Please provide an email address for the admin user."
            read email
          else
            echo "Email address of $email already provided."
          fi
        else
          echo "An admin key can always be generated later if you do not already have one. Refer to"
          echo "https://www.tiot.jp/riak-docs/cs/latest/cookbooks/configuration/riak-cs/#specifying-the-admin-user"
          echo "for more details."
        fi
      fi
    fi
  else
    if [ -n "$key" ]
      then
      echo "As an admin key has already been specified, there is no need to generate one as well. Using provided key."
      unset $generate
    else
      if [ -z "$user" ]
        then
        echo "Please provide a username for the Riak CS admin user e.g. \"admin\" or \"sausage\""
        read user
      else
        echo "Username of $user already provided."
      fi
      if [ -z "$email" ]
        then
        echo "Please provide an email address for the Riak CS admin user."
        read email
      else
        echo "Email address of $email already provided."
      fi
    fi
  fi
fi

## Does the user want us to tune ulimit for them?

#########
# To do #
#########

#Add support for other operating systems i.e. debian, freebsd for the max limit of open files available to Riak

#######
# End #
#######

if [ -z "$performance" ]
  then
  echo "To function well, Riak needs to be able to open large numbers of tiny files simultaneously. This is controlled by the ulimit setting."
  message="Would you like the installer to attempt to tune ulimit settings for you?"
  if yes_or_no "$message"
    then
    limit=$(grep riak /etc/security/limits.conf)
    if [ "$limit" = "" ]
      then
      echo "Tuning /etc/security/limits.conf by adding soft and hard limits for the number of files Riak can have open."
      sudo sed -i '$ariak             soft    nofile          65536\nriak             hard    nofile          200000' /etc/security/limits.conf
    else
      echo "It would appear that /etc/security/limits.conf has already been tuned. The installer will not make any changes to this file."
    fi
  else
    echo "When you attempt to start Riak, it will probably complain that ulimit is set too low. It will probably still function but not as well as it could normally."
  fi
  echo ""
else
  limit=$(grep riak /etc/security/limits.conf)
  if [ "$limit" = "" ]
    then
    echo "Tuning /etc/security/limits.conf by adding soft and hard limits for the number of files Riak can have open."
    sudo sed -i '$ariak             soft    nofile          65536\nriak             hard    nofile          200000' /etc/security/limits.conf
  else
    echo "It would appear that /etc/security/limits.conf has already been tuned. The installer will not make any changes to this file."
  fi
fi

## Confirmation

echo "This brings us to the end of the first part of the installer. Please confirm the below details before continuing."
echo ""
echo "We have detected that you are using:"
echo "Operating system: $ospretty ($bit bit)"
echo "Compatible OS equivalent version for a corresponding Riak package (see https://files.tiot.jp/riak/$type): $version"
echo "Architecture: $arch"
if [ -n "$override" ]
  then
  echo "You wish to override the detected OS with $override."
fi
echo ""
if [ $type = "cs" ]
  then
    echo "You would like to install Riak CS $subver with Riak KV version $kvsubver."
else
    echo "You would like to install Riak $(echo $type | tr '[:lower:]' '[:upper:]') version $subver."
fi

# If using an external file, pull in all variables settable via the installer
if [ ! -z "$config" ]
  then
  cookie=$(grep "^distributed_cookie =" $config/riak.conf | cut -d "=" -f 2 | xargs)
  ringsize=$(grep "^ring_size =" $config/riak.conf | cut -d "=" -f 2 | xargs)
  nodename=$(grep "^nodename = " $config/riak.conf | cut -d "=" -f 2 | xargs)
  interface=$(grep "^listener.http" $config/riak.conf | cut -d "=" -f 2 | xargs)
  backend=$(grep "^storage.backend = " $config/riak.conf | cut -d '=' -f 2 | xargs)
  if [ -z "$backend" ]
    then
    backend="multi"
  fi
  datadir=$(grep ^platform_data_dir /etc/riak/riak.conf | cut -d "=" -f 2 | xargs)
  aae=$(grep "^anti_entropy = " $config/riak.conf | cut -d '=' -f 2 | xargs)
  if [ "$aae" = "active" ]
    then
    aae="legacy"
  else
    aae=$(grep "^tictacaae_active = " $config/riak.conf | cut -d '=' -f 2 | xargs)
    if [ "$aae" = "active" ]
      then
      aae="tictac"
    else
      aae="disabled"
    fi
  fi
  if [ "$(grep "^search = " $config/riak.conf | cut -d '=' -f 2 | xargs)" = "on" ]
    then
    search=$(grep "^search.solr.jvm_options =" $config/riak.conf | cut -d "=" -f 2 | xargs)
  fi
  echo "You will be using external configuration files located at $config"
fi
echo "The node will be called $nodename"
if [ -z "$joining" ]
  then
  if [ "$ipaddr" != "127.0.0.1" ] && [ "$ipaddr" != "::1" ]
    then
    echo "It's a standalone node or the first node of a new cluster."
  else
    echo "It's a standalone node that cannot be made into a cluster."
  fi
else
  echo "It will be joining a pre-exiting cluster via $joining."
fi
echo "The pre-shared cookie is \"$cookie\"."
echo "The ring size is $ringsize."
echo "The backend is set to $backend."
echo "Riak's data will be stored under $datadir."
echo "Active Anti-Entropy (AAE) is set to $aae."
if [ "$aae" = "disabled" ]
  then
  echo ""
  echo "*********************************************************************************************"
  echo "* WARNING: Having AAE set to disabled is not recommended as it can lead to data corruption! *"
  echo "*********************************************************************************************"
  echo ""
fi
if [ ! -z "$search" ]
  then
  echo "Yokozuna's JVM settings are: \"$search\"."
fi
if [ ! -z "$package" ]
  then
  echo "You wish to install a local package located at \"$package\"."
fi
echo "The node will be listen for incoming connections from $interface."
echo ""
echo "You may wish to take a note of the above information if you are considering adding further nodes to the cluster."
echo "NOTE: Remember to change the node name and IP address of the interface if making a cluster."
echo ""
message="Is the above information correct? If so, answer \"yes\" to proceed or, if not, answer \"no\" to exit the installer"
if yes_or_no "$message"
  then
  echo "Excellent. In a moment we shall download Riak and begin installation. Please enter the sudo password if prompted."
else
  echo "Exiting. Have a nice day!"
  exit
fi

## Check whether local packages exist or if it's a repo based OS
if [ -z "$package" ] || [ "$os" != "alpine" ]
  then
## Chop the subversion up as needed then download
  ver=$(echo $subver | cut -d "." -f 1,2)
  echo "Attempting to get package from $packagerepo/$type/$ver/$subver/$os/$version/"
  package=$(curl --silent $packagerepo/$type/$ver/$subver/$os/$version/ \
                | grep $packagetype \
                | grep "<li>" | sed -n 's/.*href="\(.*\)".*/\1/p' \
                | grep -v -e ".src." -e "dbgsym" -e "Parent" -e ".sha" \
                | grep OTP$otp \
                | grep $extra_vsn)
  if [ -z "$package" ]
    then
    echo "No packages of Riak $type version $subver available for your operating system."
    exit
  fi
  if [ "$type" = "cs" ] && [ -z "$kvpackage" ]
    then
    kvver=$(echo $kvsubver | cut -d "." -f 1,2)
    echo "Attempting to get package from $packagerepo/kv/$kvver/$kvsubver/$os/$version/"
    kvpackage=$(curl $packagerepo/kv/$kvver/$kvsubver/$os/$version/ | grep $packagetype | cut -d ">" -f 9 | cut -d "<" -f 1 | grep -v -e ".src." -e "dbgsym" -e "Parent" -e ".sha"  | grep OTP$otp)
    if [ -z "$kvpackage" ]
      then
      echo "No packages of Riak KV version $kvsubver available for your operating system."
      exit
    fi
    ##get KV packages
    echo "KV package successfully located. Downloading from $packagerepo/kv/$kvver/$kvsubver/$os/$version/$kvpackage..."
    curl -O $packagerepo/kv/$kvver/$kvsubver/$os/$version/$kvpackage
    curl -O $packagerepo/kv/$kvver/$kvsubver/$os/$version/$kvpackage.sha
  ##check valid
    if $(sha256sum --check $kvpackage.sha --status)
      then
      echo "KV package passed sha checksum test, ready to proceed with CS download."
    else
      echo "Bad sha checksum test result detected, aborting."
      exit
    fi
  fi
##get packages
  echo "$type package successfully located. Downloading from $packagerepo/$type/$ver/$subver/$os/$version/$package..."
  curl -O $packagerepo/$type/$ver/$subver/$os/$version/$package
  curl -O $packagerepo/$type/$ver/$subver/$os/$version/$package.sha
##check valid
  if $(sha256sum --check $package.sha --status)
    then
    echo "Package passed sha checksum test, proceeding with install."
  else
    echo "Bad sha checksum test result detected, aborting."
    exit
  fi
else
#########
# To do #
#########
#
# Add CS support to alpine and self specified packages
#
#######
# End #
#######
  current=$(pwd)
  if [ "$os" = "alpine" ]
    then
    echo "Adding repository for Riak"
    sudo echo "https://files.tiot.jp/alpine/v3.16/main" >> /etc/apk/repositories
    cd /etc/apk/keys
    sudo curl -O alpine@tiot.jp.rsa.pub
    sudo apk update
    sudo apk add riak=$subver
  else
    packagename=$(rev $package | cut -d "/" -f 1 | rev)
    path=sed "s@$packagename@@g" $package
    cd path
    sha=$(ls $package* | grep "sha")
    if [ ! -z "$sha" ]
      then
      if $(sha256sum --check $package.sha --status)
        then
        echo "Package passed sha checksum test, proceeding with install"
      else
        echo "Bad sha checksum test result detected, aborting"
        exit
      fi
    else
      echo "No $package.sha file found so unable to perform sha checksum test."
      message="Proceed without checking file integrity of locally saved package?"
      if yes_or_no "$message"
        then
        echo "Proceeding without checking file integrity."
      else
        echo "Exiting. Have a nice day!"
        exit
      fi
    fi
    if [ "$type" = "cs"]
      then
        kvpackagename=$(rev $kvpackage | cut -d "/" -f 1 | rev)
        kvpath=$(sed "s@$kvpackagename@@g" $kvpackage)
        cd path
        sha=$(ls $kvpackage* | grep "sha")
        if [ ! -z "$sha" ]
          then
          if $(sha256sum --check $kvpackage.sha --status)
            then
            echo "Package passed sha checksum test, proceeding with install"
          else
            echo "Bad sha checksum test result detected, aborting"
            exit
          fi
        else
          echo "No $kvpackage.sha file found so unable to perform sha checksum test."
          message="Proceed without checking file integrity of locally saved package?"
          if yes_or_no "$message"
            then
            echo "Proceeding without checking file integrity."
          else
            echo "Exiting. Have a nice day!"
            exit
          fi
        fi
    fi
  fi
fi
##install Riak KV for CS as well if set
echo "About to install $package with $installer"
if [ ! -z "$kvpackage" ]
  then
  sudo $installer $kvpackage $package
else
  sudo $installer $package
fi
## If we installed from a specified package directory, return to the main directory
if [ ! -z "$current" ]; then cd $current; fi
## If using local config files, move them into place
if [ ! -z "$config" ]
  then
  sudo mv /etc/riak/riak.conf /etc/riak/riak.bak
  sudo mv /etc/riak/advanced.config /etc/riak/advanced.bak
  sudo cp $config/riak.conf /etc/riak/riak.conf
  sudo cp $config/advanced.config /etc/riak/advanced.config
## Otherwise, begin configuring them
else
  echo "This completes the basic tuning. The script will now update riak.conf and advanced.config"
  echo "accordingly. Please enter the sudo password if prompted to do so."
  sudo sed -i "s/nodename = riak@127.0.0.1/nodename = $nodename/g" /etc/riak/riak.conf
  sudo sed -i "s/distributed_cookie = riak/distributed_cookie = $cookie/g" /etc/riak/riak.conf
  sudo sed -i "s/ring_size = 64/ring_size = $ring/g" /etc/riak/riak.conf
  sudo sed -i "s/127.0.0.1:8098/$interface:8098/g" /etc/riak/riak.conf
  sudo sed -i "s/127.0.0.1:8087/$interface:8087/g" /etc/riak/riak.conf
  sudo sed -i "s/127.0.0.1/$interface/g" /etc/riak/advanced.config
  sudo sed -i "s/storage_backend = bitcask/storage_backend = $backend/g" /etc/riak/riak.conf
  if [ "$type" = "cs" ]
    then
    sudo sed -i "s/storage_backend = /# storage_backend = /g" /etc/riak/riak.conf
    echo "buckets.default.allow_mult = true" | sudo tee -a /etc/riak/riak.conf > /dev/null
    ##echo $(head -n -1 /etc/riak/advanced.config) | tee /etc/riak/advanced.config > /dev/null
    #sudo sed -i "s/]}\]./]},/g" /etc/riak/advanced.config
    sudo sed -i "s/]\./,/g" /etc/riak/advanced.config
    if [ "$packagetype" = "rpm" ]
      then
      cslib="lib64"
    else
      cslib="lib"
    fi
    echo "
      {riak_kv, [
        {add_paths, [\"/usr/$cslib/riak-cs/lib/riak_cs-$subver/ebin\"]},
        {storage_backend, riak_cs_kv_multi_backend},
        {multi_backend_prefix_list, [{<<\"0b:\">>, be_blocks}]},
        {multi_backend_default, be_default},
        {multi_backend, [
          {be_default, riak_kv_eleveldb_backend, [
            {total_leveldb_mem_percent, 30},
            {data_root, \"$datadir/leveldb\"}
          ]},
          {be_blocks, riak_kv_bitcask_backend, [
            {data_root, \"$datadir/bitcask\"}
          ]}
         ]}
       ]}
     ]." | sudo tee -a /etc/riak/advanced.config > /dev/null
    if [ "$interface" = "0.0.0.0" ]
      then
      sudo sed -i "s/listener = 127.0.0.1/listener = $interface/g" /etc/riak-cs/riak-cs.conf
      sudo sed -i "s/riak_host = 127.0.0.1/riak_host = $ipaddr/g" /etc/riak-cs/riak-cs.conf
      sudo sed -i "s/stanchion_subnet = 127.0.0.1/stanchion_subnet = $ipaddr/g" /etc/riak-cs/riak-cs.conf
      sudo sed -i "s/nodename = riak-cs@127.0.0.1/nodename = riak-cs@$maybeFQDN/g" /etc/riak-cs/riak-cs.conf
    else
      sudo sed -i "s/127.0.0.1/$interface/g" /etc/riak-cs/riak-cs.conf
    fi
    if [ ! -z {$key+x} ]
      then
      echo "Inserting admin key of $key"
      sudo sed -i "s/admin.key = admin-key/admin.key = $key/g" /etc/riak-cs/riak-cs.conf
    fi
    if [ ! -z {$generate+x} ]
      then
      sudo sed -i "s/anonymous_user_creation = off/anonymous_user_creation = on/g" /etc/riak-cs/riak-cs.conf
    fi
  fi
  if [ "$aae" = "tictac" ]
    then
    sudo sed -i "s/anti_entropy = active/anti_entropy = passive/g" /etc/riak/riak.conf
    sudo sed -i "s/tictacaae_active = passive/tictacaae_active = active/g" /etc/riak/riak.conf
  fi
  if [ ! -z "$search" ]
    then
    sudo sed -i "s/search = off/search = on/g" /etc/riak/riak.conf
    sudo sed -i "s/-d64 -Xms 1g -Xmx 1g -XX:+UseStringCache -XX:+UseCompressedOops/$search/g" /etc/riak/riak.conf
  fi

  if [ "$prepare_for_riak_control" = "yes" ]
  then
    echo "Enabling ssl and https listener"
    sudo sed -i "s/^#+ +ssl\./ssl./" /etc/riak/riak.conf
    sudo sed -i "s/#+ +listener.https.internal/listener.https.internal/" /etc/riak/riak.conf
    sudo sed -i "s/ {riak_core,/ {riak_kv, [{secure_referer_check, false}]},\n {riak_core,/" /etc/riak/advanced.config
  fi
  if [ ! -z ${ssl_bundle_url+x} ]
  then
    echo "Fetching and installing your certificate bundle"
    tmpf=/tmp/riak-ssl-cert-bundle.tar.gz
    curl -o $tmpf $ssl_bundle_url && sudo tar -C /etc/riak -xzf $tmpf
    rm $tmpf
  fi
fi

sudo riak chkconfig
if [ "$type" = "cs" ]
  then
  $riakstart
  echo "Checking whether riak is up via the variable option"
  sudo $riakadmin wait-for-service riak_kv
  echo "Checking whether riak is up via a hard coded command"
  sudo riak admin wait-for-service riak_kv
  echo "Checking whether riak is up via a hard coded command including node name"
  sudo riak admin wait-for-service riak_kv riak@127.0.0.1
  sudo riak admin ringready
  sudo riak admin services
  sudo sed -i "s/distributed_cookie = riak/distributed_cookie = $cookie/g" /etc/riak-cs/riak-cs.conf
  sudo mkdir -p /tmp/erl_pipes
  sudo chmod -R 777 /tmp/erl_pipes/
  echo "Riak KV has now finished the initial setup, we will shut it down and start it again for normal operations."
  $riakstop
  $riakstart
  echo "Checking whether riak is up via the variable option"
  sudo $riakadmin wait-for-service riak_kv
  echo "Checking whether riak is up via a hard coded command"
  sudo riak admin wait-for-service riak_kv
  echo "Checking whether riak is up via a hard coded command including node name"
  sudo riak admin wait-for-service riak_kv riak@127.0.0.1
  sudo riak admin ringready
  sudo riak admin services
  sudo riak-cs chkconfig
  $riakcsstart
  prekey=$(sudo grep "admin.key" /etc/riak-cs/riak-cs.conf | grep -v "#")
  echo "Before starting, the key is $prekey"
  ## Start Riak CS then:
  if [ "$interface" = "0.0.0.0" ]
    then
    cslocal=$ipaddr
  else
    cslocal=$interface
  fi
  if [ ! -z "$generate" ]
    then
    netstat -tpln
    curl http://127.0.0.1:8080/test
    curl http://127.0.0.1:8080/riak-cs/ping
    echo "The cslocal variable is [$cslocal]"
    curl -XPOST http://$cslocal:8080/riak-cs/user   -H 'Content-Type: application/json'   -d "{\"email\":\"$email\", \"name\":\"$name\"}" > ~/secret.txt
    #key=$(cat ~/secret.txt | cut -d '"' -f 16)
    key=$(cat ~/secret.txt | cut -d '"' -f 34)
    #secret=$(cat ~/secret.txt | cut -d '"' -f 20)
    secret=$(cat ~/secret.txt | cut -d '"' -f 38)
    if [ -z "$key" ]
      then
      echo "CS has failed to start for some ridiculous reason. Sorry, we dropped the ball. Bye!"
    else
      sudo sed -i "s/admin.key = admin-key/admin.key = $key/g" /etc/riak-cs/riak-cs.conf
      #echo "admin.secret = $secret" | sudo tee -a /etc/riak-cs/riak-cs.conf > /dev/null
      sudo sed -i "s/anonymous_user_creation = on/anonymous_user_creation = off/g" /etc/riak-cs/riak-cs.conf
      $riakcsstop
      $riakcsstart
      echo '
            access_key = admin.key
            bucket_location = US
            cloudfront_host = cloudfront.amazonaws.com
            cloudfront_resource = /2010-07-15/distribution
            default_mime_type = binary/octet-stream
            delete_removed = False
            dry_run = False
            encoding = UTF-8
            encrypt = False
            follow_symlinks = False
            force = False
            get_continue = False
            gpg_command = /usr/bin/gpg
            gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
            gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
            gpg_passphrase =
            guess_mime_type = True
            host_base = s3.amazonaws.com
            host_bucket = %(bucket)s.s3.amazonaws.com
            human_readable_sizes = False
            list_md5 = False
            log_target_prefix =
            preserve_attrs = True
            progress_meter = True
            proxy_host = 127.0.0.1
            proxy_port = 8080
            recursive = False
            recv_chunk = 4096
            reduced_redundancy = False
            secret_key = admin.secret
            send_chunk = 4096
            simpledb_host = sdb.amazonaws.com
            skip_existing = False
            socket_timeout = 10
            urlencoding_mode = normal
            use_https = False
            verbosity = WARNING' >> ~/.s3cfg
      sed -i "s/admin.key/$key/g" ~/.s3cfg
      sed -i "s/admin.secret/$secret/g" ~/.s3cfg
      sed -i "s/127.0.0.1/$cslocal/g" ~/.s3cfg
      echo "The installer has generated a sample configuration file for s3 which is located at ~/.s3cfg"
      echo "Being in the root of your user folder, s3cmd will automatically use this unless you specify another."
      echo "Depending on how you access, you may need to change the \"proxy_host\" setting in .s3cfg from $cslocal"
      echo "to an externally accessable IP address."
      echo ""
      echo "The admin key and admin secret can be found in ~/secret.txt and they are $key and $secret accordingly."
    fi
  fi
fi

if [ -n "$joining" ]
  then
  message="In order to join this node to $joining, we will need to start Riak. Proceed?"
  if yes_or_no "$message"
    then
    echo "Note: there is a known bug on the first start of Riak that can cause the terminal that launched it"
    echo "to hang as the launch command does not return \"completed\" despite it completing successfully."
    echo "Using Ctrl C to get out of this lock will also kill the installer but Riak will be up at that point."
    echo "If you have to do this, manually execute"
    echo "the following commands after exiting the installer:"
    echo ""
    echo "$riakadmin wait-for-service riak_kv"
    echo "$riakadmin cluster join $joining"
    echo "$riakadmin cluster plan"
    echo "$riakadmin cluster commit"
    echo "$riakadmin transfers"
    echo ""
    echo "Once the transfers complete (re-run \"$riakadmin transfers\" as often as needed to check), everything is finished"
    echo "If the launch command does not lock up then the installer will perform all of these for you automatically."
    echo ""
    echo "Attempting to starting Riak..."
## Alpine and Kali usually don't have systemctl installed, so start the traditional way
    $riakstart
    echo "Checking Riak is fully up..."
    sudo $riakadmin wait-for-service riak_kv
    echo "Beginning join..."
    sudo $riakadmin cluster join $joining
    sudo $riakadmin cluster plan
    message="The above shows the distribution of the cluster both before and after joining. Proceed?"
    if yes_or_no "$message"
    then
      $riakadmin cluster commit
      $riakadmin transfers
    else
      echo "Plan is staged but not committed. If you plan to add other nodes as well, this would"
      echo "be an ideal time to add them as fewer ring transitions reduce unnecessary work for Riak."
      echo "Add your other nodes either with this installer or manually."
      echo "If adding manually, remember to run \"$riakadmin cluster plan\" and, if happy, run"
      echo "\"$riakadmin cluster commit\" once all nodes being added are in the plan."
    fi
  else
    echo "Very well, the installer will not start Riak or join $joining."
    echo "To start Riak, run \"systemctl start riak\""
    echo "Once Riak is up (optionally test with \"$riakadmin wait-for-service riak_kv\"),"
    echo "you can then tell Riak to join the cluster with \"$riakadmin cluster join $joining\""
    echo "After this show the plan and commit it with:"
    echo "\"$riakadmin cluster plan\" and \"$riakadmin cluster commit\" accordingly."
  fi
fi

if [ "$prepare_for_riak_control" = "yes" ]
then
  echo "Enabling security and creating an admin user for Riak Control"
  $riakadmin security enable
  $riakadmin security add-user "$riak_control_user" password="$riak_control_password"
  $riakadmin security grant riak_kv.riak_control on any to "$riak_control_user"
  $riakadmin security add-source all "$riak_control_pwd_sec_net_source" password
fi

echo "The installer has now completed. We recommend you look at the documentation available on"
echo "https://www.tiot.jp/riak-docs/\" for Riak $type for further information on how to use Riak."
echo "Thank you very much for using the installer."
