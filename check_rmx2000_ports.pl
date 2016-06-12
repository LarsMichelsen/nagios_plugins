#!/usr/bin/perl -w
# ##############################################################################
# 2009-02-03 Lars Michelsen <lars@vertical-visions.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
#
# GNU General Public License: http://www.gnu.org/licenses/gpl-2.0.txt
#
# ##############################################################################
# SCRIPT:       check_rmx2000_ports.pl
# VERSION:      1.0
# AUTHOR:       Lars Michelsen
# DECRIPTION:   Checks the XML API of RMX2000 (And maybe other polycom bridges
#               like MGC) for the CIF port usage.
# ##############################################################################

use strict;
use Getopt::Long;
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST);
use XML::Simple;
use Data::Dumper;
use Sys::Hostname;
Getopt::Long::Configure('bundling');

my ($oHelp, $oHost, $oUser, $oPw, $oAddress, $oPort, $oWarn, $oCrit);

my @warn = (-1,-1);
my @crit = (-1,-1);
my $state = 'OK';
my $output = '';
my $perfdata = '';

my $userAgent;
my $token;
my $uToken;

my $bridgeIp = '';
my $bridgeUser = '';
my $bridgePw = '';
my $hostName = hostname;
my $bridgePort = '80';
my $bridgeUrl = '';

# Exit-Status-Array
my %ERRORS = ('UNKNOWN' , '-1',
    'OK' , '0',
    'WARNING', '1',
    'CRITICAL', '2');

# Parameter handling ###########################################################

GetOptions("H|host:s" => \$oHost,
      "U|user:s" => \$oUser,
      "P|pw:s" => \$oPw,
      "A|address:s" => \$oAddress,
            "w|warn:s" => \$oWarn,
            "c|crit:s" => \$oCrit,
            "p|port:i" => \$oPort,
            "h|help" => \$oHelp);

if($oHelp || !$oUser || !$oHost || !$oPw || !$oAddress) {
    print <<EOU;
  Usage: $0 -H <FQDN/IP: string> -A <URL/Address: string> -U <Username: string> 
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

EOU
  exit($ERRORS{'UNKNOWN'});
}

$bridgeIp = $oHost;
$bridgeUrl = $oAddress;
$bridgeUser = $oUser;
$bridgePw = $oPw;

if($oPort) {
    $bridgePort = $oPort;
}
if($oWarn) {
    @warn = split(',', $oWarn);
}
if($oCrit) {
    @crit = split(',', $oCrit);
}

# Script start #################################################################

connect_bridge() if !$userAgent;

my $request = '<TRANS_RSRC_REPORT><TRANS_COMMON_PARAMS><MCU_TOKEN>'.$token.'</MCU_TOKEN>'.
    '<MCU_USER_TOKEN>'.$uToken.'</MCU_USER_TOKEN><MESSAGE_ID>0</MESSAGE_ID>'.
    '</TRANS_COMMON_PARAMS><ACTION><GET_CARMEL_REPORT/></ACTION></TRANS_RSRC_REPORT>';

my $responseXml = http_post($bridgeUrl, $request);
my $oXml = XMLin($responseXml);

# DEBUG: print Dumper($oXml);

my $audioPorts;
my $videoPorts;
foreach my $report (@{$oXml->{'ACTION'}->{'GET_CARMEL_REPORT'}->{'RSRC_REPORT_RMX_LIST'}->{'RSRC_REPORT_RMX'}}) {
    if($report->{'RSRC_REPORT_ITEM'} eq 'audio') {
        # Possible options:
        #$report->{'RSRC_REPORT_ITEM'}->{'RESERVED'}
        #$report->{'RSRC_REPORT_ITEM'}->{'OCCUPIED'}
        #$report->{'RSRC_REPORT_ITEM'}->{'TOTAL'}
        #$report->{'RSRC_REPORT_ITEM'}->{'FREE'}
        
        $audioPorts = $report;
    } elsif($report->{'RSRC_REPORT_ITEM'} eq 'video') {
        $videoPorts = $report;
    }
}

# Audio tresholds
if($warn[0] != -1 && $audioPorts->{'OCCUPIED'} > $warn[0]) {
    $state = 'WARNING';
}
if($crit[0] != -1 && $audioPorts->{'OCCUPIED'} > $crit[0]) {
    $state = 'CRITICAL';
}

# Video tresholds
if($warn[1] != -1 && $videoPorts->{'OCCUPIED'} > $warn[1]) {
    $state = 'WARNING';
}
if($crit[1] != -1 && $videoPorts->{'OCCUPIED'} > $crit[1]) {
    $state = 'CRITICAL';
}

$output = $state.': Audio occupied: '.$audioPorts->{'OCCUPIED'}.'/'.$audioPorts->{'TOTAL'}.
          ' Video occupied: '.$videoPorts->{'OCCUPIED'}.'/'.$videoPorts->{'TOTAL'};

$perfdata = 'audio='.$audioPorts->{'OCCUPIED'}.';'.$warn[0].';'.$crit[0].';0;'.$audioPorts->{'TOTAL'}.
            ' video='.$videoPorts->{'OCCUPIED'}.';'.$warn[1].';'.$crit[1].';0;'.$videoPorts->{'TOTAL'};

print($output.' | '.$perfdata."\n");
exit($ERRORS{$state});

# Subs #########################################################################

sub login_bridge {
    my $request = '<TRANS_MCU><TRANS_COMMON_PARAMS><MCU_TOKEN>-1</MCU_TOKEN>'.
        '<MCU_USER_TOKEN>-1</MCU_USER_TOKEN></TRANS_COMMON_PARAMS><ACTION><LOGIN>'.
        '<MCU_IP><IP>'.$bridgeIp.'</IP>'.
        '<LISTEN_PORT>'.$bridgePort.'</LISTEN_PORT>'.
        '</MCU_IP><USER_NAME>'.$bridgeUser.'</USER_NAME>'.
        '<PASSWORD>'.$bridgePw.'</PASSWORD>'.
        '<STATION_NAME>'.$hostName.'</STATION_NAME>'.
        '</LOGIN></ACTION></TRANS_MCU>';
    
    my $responseXml = http_post($bridgeUrl, $request);
    my $xml = XMLin($responseXml);
    
    # DEBUG: print Dumper($xml);
    
    my $token = 0;
    my $uToken = 0;
    if($xml->{'RETURN_STATUS'}->{'ID'} == 0) {
        $token = $xml->{'ACTION'}->{'LOGIN'}->{'MCU_TOKEN'};
        $uToken = $xml->{'ACTION'}->{'LOGIN'}->{'MCU_USER_TOKEN'};
    }
    
    return ($token, $uToken);
}

sub connect_bridge {
    $userAgent = LWP::UserAgent->new(agent => 'VCMgmtLib', keep_alive => 1);
    
    ($token, $uToken) = login_bridge();
    
    if($token == 0 || $uToken == 0) {
        # Login failed
        print("UNKNOWN: Login failed!\n");
        exit($ERRORS{'UNKNOWN'});
    }
}

sub http_post {
    my ($url, $content) = @_;
    
    my $req = POST $bridgeUrl,
      Content_Type => 'application/x-www-form-urlencoded',
      Content => $content;
    
    my $response = $userAgent->request($req);
    
    print $response->error_as_HTML unless $response->is_success;
    
    return $response->content;
}

# End of script ################################################################
