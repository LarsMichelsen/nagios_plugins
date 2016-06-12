<?php
# Name this file to match the check command you use in Nagios.

$multigraph_name[1] = "Occupied ports";
$opt[1] = "--vertical-label \"Occupied ports\" --title \"Occupied Ports: $hostname ($servicedesc)\" ";
#
#
#
$def[1] =  "DEF:var1=$rrdfile:$DS[1]:AVERAGE " ;
$def[1] .= "DEF:var2=$rrdfile:$DS[2]:AVERAGE " ;
$def[1] .= "CDEF:var2draw=var2,-1,* ";
$def[1] .= "HRULE:$CRIT[1]#FF0000 ";
$def[1] .= "AREA:var1#9CCFFF:\"$NAME[1] \" " ;
$def[1] .= "LINE1:var1#10A2FF " ;
$def[1] .= "AREA:var2draw#FFCF9C:\"$NAME[2] \\n\" " ;
$def[1] .= "LINE1:var2draw#FFA26B " ;

$def[1] .= "COMMENT:\"          current     average   maximum\"  " ;
$def[1] .= "COMMENT:\"\\n\"  " ;
$def[1] .= "COMMENT:\"audio    \"  " ;
$def[1] .= "GPRINT:var1:LAST:\"%7.0lf  \" " ;
$def[1] .= "GPRINT:var1:AVERAGE:\"%7.0lf \" " ;
$def[1] .= "GPRINT:var1:MAX:'%7.0lf' " ;
$def[1] .= "COMMENT:\"\\n\" " ;
$def[1] .= "COMMENT:\"video    \"  " ;
$def[1] .= "GPRINT:var2:LAST:\"%7.0lf  \" " ;
$def[1] .= "GPRINT:var2:AVERAGE:\"%7.0lf \" " ;
$def[1] .= "GPRINT:var2:MAX:\"%7.0lf\"  " ;

$def[1] .= "COMMENT:\"                          ".date("d.m.Y H:i:s")."\\n\" " ;
?>
