#!/usr/bin/perl -w
#

use FindBin qw($Bin);
use lib "$Bin/../lib";

# use fj_builtins;
use fj_walker;
use fj_rules;
use fj_commands;
use fj_exec;

$ret =  fj_exec::tree_executor(shift());

exit ($ret ? 0 : 66);
