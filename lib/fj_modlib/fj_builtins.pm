# package fj_builtins

package fj_builtins;

use File::Copy;
use File::Basename;
use fj_config;

# provides function is mandatory for all modules
# returns a ref to a hash. The hash key is the command provided,
# its value the number of expected arguments (without any semantics). Each
# command will get the number of args requested starting from the second argument
# to the command (first goes to walker)

sub fj_provides {
	&fj_setup;
	return {
		"state" => \&fj_state_func,
		"copy" => \&fj_copy_func,
		"move" => \&fj_move_func,
		"unlink" => \&fj_unlink_func,
		"exists" => \&fj_exists_func,
		"not" => \&fj_not_func,  
		"noweep" => \&fj_noweep_func,  
		"age" => \&fj_fage_func,
		"match" => \&fj_match_func,
		"log" => \&fj_log_func,
		"cplog" => \&fj_cm_log_func,
		"rename" => \&fj_rename_func,
		"convert" => \&fj_convert_func,
		"grep" => \&fj_grep_func,
		"suffix" => \&fj_suffix_func,
		"system" => \&fj_system_func
	};
}

my %fj_config;
# setup package vars
sub fj_setup {
	$fj_config{'STATE'} = shift || &fj_state_func;
	$fj_config{'LOG'} = shift || &fj_log_func;
}

# each function will get a filename (which can be a directory) and a type (1 = normal file, 0 = special file)
# if it does not want to work with directory it should return 0

# rename func
# can only rename files

sub fj_rename_func {
	my $from = shift;
	my $to = shift;
	return sub {
		my $file = shift;
		return 0 unless (shift());
		my ($nf,$path,$suffix) = fileparse($file);
		$nf =~ s/$from/$to/g;
		return move($file,"$path/$nf");
	}
}


# add a suffix 
sub fj_suffix_func {
	my $suff = shift;
	return sub {
		my $file = shift;
		return move($file,"$file.$suff");
	}
}





# status func
sub fj_state_func {
	# internal status
	my $istate;
	my $logfunc = $fj_config{'LOG'} || &fj_log_func;
	return sub {
		if (my $state = shift) {
			# set new
			$istate = $state;
			&$logfunc($istate);
			return 1;
		} 
		return $istate;
	}
}


# log function
# just prints to stdout at the moment

sub fj_log_func {
	return sub {
		my $msg = shift;
		my @ctime = localtime;
       		$ctime[4]++;
		$ctime[5] += 1900;
		for (my $i = 0; $i < @ctime; $i++) {
			$ctime[$i] = "0$ctime[$i]" if ($ctime[$i] < 10);
		}
		print "[$ctime[5]$ctime[4]$ctime[3] $ctime[2]:$ctime[1]:$ctime[0]]\t$msg\n"; 
	}
}

# special log func, translates message to target file name for copies
sub fj_cm_log_func {
	my $target = shift;
	my $logfunc = shift;
	return sub {
		&$logfunc($target . "/" . basename(shift));
	}
}


# name recognizer
# returns true if a regex matches a filename 

sub fj_match_func {
	my $regex = shift;
	my $logf = &fj_log_func;
	$regex = qr/$regex/;
	return sub {
		my $str = shift;
		if ($str =~ /$regex/) {
			$logf->("$str matches");
			return 1;
		}
		return 0;
	}
}

# fj_copy_func($target)
# return a copy function pointer
# can not work on directories
sub fj_copy_func {
	my $target = shift;
	my $logf = &fj_log_func;
	return sub {
		my $file = shift;
		return 0 unless (shift());
		if (copy($file,$target)) {
			$logf->("Copy $file to $target");
			return 1;
		}
		$logf->("ERROR: Copy $file to $target: $!");
		return 0;
	}
}

# fj_move_func($target)
# can work and will work on directories
sub fj_move_func {
	my $target = shift;
	my $logf = &fj_log_func;
	return sub {
		my $file = shift;
		if (move($file,$target)) {
			$logf->("Move $file to $target");
			return 1;
		}
		$logf->("ERROR: Move $file to $target: $!");
		return 0;
	}
}

# fj_unlink_func()
# never use unlink on directories
sub fj_unlink_func {
	my $logf = &fj_log_func;
	return sub {
		my $file = shift;
		return 0 unless (shift());
		if (-d $file) {
			$logf->("ERROR: $file is a directory, not unlinked, something's rotten");
			return 0;
		}
		if (unlink($file)) {
			$logf->("Unlink $file");
			return 1;
		}
		$logf->("ERROR: Unlink $file: $!");
		return 0;
	}
}


# fj_exists_func()
# test whether a file exists
# will code some filewatcher functionality here too
# basic version
sub fj_exists_func {
	my $logf = &fj_log_func;
	my $exists = 0;
	return sub {
		my $file = shift;
		# of course file exists, we would not get here!
		if (-e $file) {
			$logf->("$file exists");
			$exists = 1;
		}
		return $exists;
	}
}

# finds strings in files
# returns 1 if found, 0 otherwise
# if verbose specified, matching strings are logged
# fj_grep($file,$searchstring)
# & fj_grep_func(pattern,verbose)
sub fj_grep_func {
	my $search = shift;
	my $verbose = shift || 0;
	$search = qr/$search/;

	return sub {
		my $file = shift;
		return 0 unless (shift());
		my $rset;
		my $found = 0;

		my $logf = &fj_log_func;

		open(IN,$file) || return 0;

		while (<IN>) {
			chomp;
			if (/$search/) {
				push(@{$rset->{$file}},$_);
				$found = 1;
			}
		}

		close IN || return 0;

		if ($verbose) {
			foreach my $mfile (keys %$rset) {
				foreach my $match (@{$rset->{$mfile}}) {
					$logf->("Match [$mfile] $match");
				}
			}
		}
		if ($found) {
			$logf->("Content of $file matches");
		} else {
			$logf->("No match in $file found");
		}

		return $found;
	}
}

# converts line feeds
# if $mode is 'w' file will be converted to dos linefeeds, otherwise unix
# needs to be tested on windows...
#
# & fj_convert_func(mode)
sub fj_convert_func {
	my $mode = shift || "u";
	my $logf = &fj_log_func();
	return sub {
		my $file = shift;
		return 0 unless (shift());
		my $lf = "\n";

		my $of = "${file}~";

		$lf = "\r\n" if ($mode eq 'w');

		open(IN,$file) || return 0;
		open(OUT,">$of") || return 0;

		while (<IN>) {
			if ($mode eq "u") {
				s/\r\n//;
				$lf = "\n";
			} elsif ($mode eq "w") {
				s/\n//;
				$lf = "\r\n";
			}
			print OUT "$_$lf";
		}

		close IN;
		close OUT || return 0;
		
		my $status = move($of,$file);
		
		if ($status) {
			$logf->("$file converted ($mode)");
			return 1;
		} else {
			$logf->("$file conversion error");
			return 0;
		}
	}
}

# checks whether a file modified date falls between two other values
# (check access and create time is planned but low prio)
# sub fj_fage()
sub fj_fage_func {
	my ($max,$min) = @_;
	return sub {
		my $file = shift;
		my @stat = stat($file);
		if (my $mtime = $stat[9]) {
			my $status = &chk_time($mtime,$max,$min);
			$status ?  &fj_log_func()->("$file age ok") : &fj_log_func()->("$file age restrictions not met");
			return $status;
		}
		# something's rotten if we get here
		&fj_log_func()->("ERROR: STAT $file failed: $!");
	}
}

# system function, this is the default function, when something is called, that does not exist.
# The command is given to the system
sub fj_system_func {
	my ($command,@args) = @_;
	print "Command: $command, args: @args\n";
	return sub {
		my $file = shift;
		&fj_log_func()->("Executing $command on $file");
		return (system($command,@args,$file) ? 0 : 1);
	}
}

# not and noweep functions
# returns true on failure or true anyway respectively of the function attached 
# this is special because the caller needs to extract exact function pointer
# this is done in fj_exec
sub fj_not_func {
	my $func = shift;
	# default is to be ok
	my $status = 1;
	return sub {
		my $file = shift;
		if (&$func($file)) {
			$status = 0;
		}
		return $status;
	}
}

sub fj_noweep_func {
	my $func = shift;
	return sub {
		my $file = shift;
		&$func($file);
		return 1;
	}
}


# helper function
# checks whether a timestamp is between max or minage 
# bool chk_time(timestamp, maxage, minage)
# ages: 3 or 3d: 3 days
#	3h: 3 hours
#	3m: 3 minutes
# 
# maxage: files are newer than that value (value is bigger)
# minage: files are older than that value (value is smaller)
#
# true if maxage > time > minage
sub chk_time {
	my ($time,$maxage,$minage) = @_;
	my $bt = 1500000000;
	my $lt = 0;
	if ($maxage) {
		$bt = get_age_val($maxage);
	}
	if ($minage) {
		$lt = get_age_val($minage);
	}
	return 0 if ($bt && $time < $bt);
	return 0 if ($lt && $time > $lt);
	return 1;
}

# helper function
# computes a timestamp (seconds from epoch) from an age value
# int get_age_val(age)
sub get_age_val {
        my $val = shift;
        my ($amount,$unit) = $val =~ /(\d+)(.*)/;
        my $curtime = time();
        return $curtime unless ($amount);
        my $minval = 0;
        if ($unit eq 'h') {
                $minval = $amount * 60 * 60;
        } elsif ($unit eq 'm') {
                $minval = $amount * 60;
        } else {
                $minval = $amount * 60 * 60 * 24;
        }
        return $curtime - $minval;
}

# helper function
# sets a timeout
# get_timeout(<sec>) will get you a function back that returns false as long as timeout is not gone
sub get_timeout {
	my $secs = shift;
	my $timethen = time() + $secs;
	return sub {
		return ( $timethen <= time() );
	}
}


# END
1;

