#!/usr/bin/perl -w
#
# 

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Getopt::Long;

# use fj_builtins;
use fj_walker;
use fj_rules;
use fj_commands;
use fj_exec;
use fj_config;

# Get the option
GetOptions( "service|s" => \$service, "rcfile|f=s" => \$rcfile ) || die "Error in command line parsing";

$rcfile = "$Bin/../etc/fjrc" unless ($rcfile);
&fj_config::read_rcfile($rcfile);

$ret = 0;

if ($service) {
  fj_exec::tree_executor(shift()) while (sleep 1);
} else {
  $ret =  fj_exec::tree_executor(shift());
}


exit ($ret ? 0 : 66);
