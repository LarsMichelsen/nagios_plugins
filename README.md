# Some Nagios check plugins

This is a collection of Nagios check plugins I developed some years ago.

## check_rmx2000_ports.pl

You will need the following perl modules to get the plugin running:

* Getopt::Long
* LWP::UserAgent
* HTTP::Request::Common
* XML::Simple
* Sys::Hostname
* Data::Dumper (Only for debugging)

### Parameters

```
  Usage: ./check_rmx2000_ports.pl -H <FQDN/IP: string> -A <URL/Address: string> -U <Username: string> 
            -P <Passwort: string> [-p <Port: integer>] [-w <audio ports warn: integer>,<video ports warn: integer>]
            [-c <audio ports warn: integer>,<video ports warn: integer>]


    Options:

    -H --host STRING or IPADDRESS
        FQDN or IP-Address of the bridge
    -A --address STRING 
        Address to the XML API (e.g. http://<hostname>/Receiver.asp)
    -U --user STRING
        User name on the bridge
    -P --pw STRING
        Password of the account on the bridge
    -p --port INTEGER
        TCP port the API listens on the bridge
    -w --warn INTEGER
        Warning tresholds. Give maximum number of audio/video ports to be 
        occupied before warning state occurs.

        Example:
        A value of 50,25 would warn on 51 occupied audio- and/or 26 occupied
        video ports.
    -c --crit INTEGER
        Critical tresholds. Give maximum number of audio/video ports to be 
        occupied before critical state occurs.

        Example:
        A value of 60,30 would warn on 61 occupied audio- and/or 31 occupied
        video ports.
```

### Sample configuration

Here some sample command and service definition for Nagios configuration.

```
define command {
  command_name   check_rmx2000_ports
  command_line   $USER1$/check_rmx2000_ports.pl -H $HOSTADDRESS$ -A $ARG1$ -U $ARG2$ -P $ARG3$ -w $ARG4$ -c $ARG5$
}

define service {
  host_name            rmx2000
  service_description  OCCUPIED-PORTS
  check_command        check_rmx2000_ports!http://rmx2000/Receiver.asp!script-read!aLAn7gjMa29naHAy!30,15!45,18
  use                  service-standard
}
```

## check_gms_directory_entries

The base for this script is to be able to fetch the information automatically. As I found no documentation about the communication API between the GMS global address book service and the endpoints I tried to figure out the needed transactions by sniffing the network traffic. After some research I was able to get the wanted results by using a simple telnet session connecting the port 3601 on the GMS system.

After having the basic information I wrote this small perl script which simply counts the number of entries.

With the basic communication information it is also possible to build some other things like e.g.

* Dynamic webpage which displays the contents of the global addressbook
* Monitor script which checks for special entries instead of just counting them

### Prerequisites

* Net::Telnet
* Getopt::Long

### Parameters

```
  Usage: ./check_gms_directory_entries.pl -H <FQDN/IP: string>
            -P <Password: string> -N <Client Name: string>
            -I <Client IP: string> [-t <timeout in seconds: integer>]
            [-w <warning level: integer] [-c <critical level: integer>]
            [-h]


    Options:

    -H --host STRING or IPADDRESS
        FQDN or IP-Address of the GMS host
    -P --pw STRING
        Password to access the global directory on GMS host
    -N --name STRING
        Name of the client host. In this case the monitoring server
    -I --ip String
        IP of the client host. In this case the monitoring server
    -w --warn INTEGER
        Warning treshold. Give the minimum number of entries in the
        directory

        Example:
        Give a number of 10 to get a WARNING state on less than 10 entires
    -c --crit INTEGER
        Critical treshold. Give the minimum number of entries in the
        directory

        Example:
        Give a number of 10 to get a CRITICAL state on less than 10 entires
        occupied before critical state occurs.
    -h --help
        Print this help text
```

### Sample configuration

```
define command {
  command_name  check_gms_directory_entries
  command_line  $USER1$/check_gms_directory_entries.pl -H $HOSTADDRESS$ -P $ARG1$ -N $ARG2$ -I $ARG3$ -w $ARG4$ -c $ARG5$
}

define service {
  hostgroup_name     gms
  service_description  GMS-NUM-ADDRESSES
  check_command        check_gms_directory_entries!<password>!nagios!<nagios-server-ip>!15!10
  use                  sdm-standard
}
```
