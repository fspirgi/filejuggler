package fj_exec;
# takes care about the execution of the stanzas
#

use fj_commands;
use fj_walker;
use fj_rules;
use fj_config;

# just call the task_executor
sub rules_executor {
	my $target = shift;

	# empty target
	return 1 unless (defined $target);

	my $tconf = shift(@$target);
	my ($walkdir,@elsefunc) = @$tconf;
	# else function
	my $efunc = sub { return 1 };
	if (@elsefunc) {
		$efunc = &fj_commands::catalog()->{$elsefunc[0]}(@elsefunc[1,]);
	}


	# list of functions to be executed
	my $funclist;
	foreach my $task (@$target) {
		my $cmd = shift(@$task);
		if ($cmd eq "not" || $cmd eq "noweep" || $cmd eq "waitfor") {
			my $ncmd = shift(@$task);
			push(@$funclist,&fj_commands::catalog()->{$cmd}(&fj_commands::catalog()->{$ncmd}(@$task)));	
			next;
		}
		push(@$funclist,&fj_commands::catalog()->{$cmd}(@$task));	
	}
	return &fj_walker::fj_walker($walkdir,$funclist,$efunc);
}

# tree_executor(tree,target)
sub tree_executor {
	&setup;
	my $tree = &fj_rules::targets();
	my $target = shift || "main";
	my $logf = &fj_commands::catalog()->{'log'}();
	my $retval = 1;

	$logf->("Starting target $target");

	$logf->("Dependencies...");
	my $noweep = 0;
	my $waitfor = 0;
	while (my $dep = pop(@{$tree->[1]{$target}})) {
		if ($dep =~ /~/) {
			# modifier available
			my @t = split(/~/,$dep);
			$dep = $t[0];
			$noweep = 1 if ($t[1] eq "noweep");
			$waitfor = 1 if ($t[1] eq "waitfor");
		}
		$logf->("Target $dep");
		unless (&rules_executor($tree->[0]{$dep})) {
			if ($noweep) {
				$logf->("$dep execution failed but noweep specified");
				$noweep = 0;
				next;
			}
			if ($waitfor) {
				$logf->("$dep execution failed, waitfor specified, try again...");
				my $okcount = 0;
				my $tmout = get_timeout($fj_config::fj_config->{'tmout'});
				while (1) {
					# ERROR rules_executor does a shift, values not available
					# anymore... Thinking how to do that...
					if (&rules_executor($tree->[0]{$dep})) {
						$okcount++;
						if ($okcount >= $fj_config::fj_config->{'confirms'}) {
							$waitfor = 0;
							next;
						}
					} else {
						$okcount = 0;
					}
					$waitfor = 0 if (&$tmout());
					sleep $fj_config::fj_config->{'pollint'};
				}
			}
			$logf->("$dep execution failed, leaving...");
			if (defined $tree->[0]{$dep}[0][1]) {
				my ($command,@errcmd) = @{$tree->[0]{$dep}[0]}[1,];
				&fj_commands::catalog()->{$command}(@errcmd)->($dep);
			}
			# just leave the building
			$retval = 0;
			last;
		}
		$logf->("Finished target $dep");
	}
	$logf->("End dependencies...");

	if ($retval) {
		$logf->("Target $target");
		$retval =  &rules_executor($tree->[0]{$target});
		$logf->("End target $target");
	}
	return $retval;
}

sub setup {
	&fj_commands::find_modules();
}

# helper function
# # sets a timeout
# # get_timeout(<sec>) will get you a function back that returns false as long as timeout is not gone
sub get_timeout {
	my $secs = shift;
        my $timethen = time() + $secs;
        return sub {
		return ( $timethen <= time() );
        }
}

# END
1;
