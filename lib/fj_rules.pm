package fj_rules;

use Data::Dumper;
use FindBin qw($Bin);

my $rulesfile = "$Bin/../etc/fjrules.in";

# setup a new rules file
sub setup {
	$rulesfile = shift;
	return $rulesfile;
}

# get tokens from the file
sub tokens {
	my @tokens;
	open(IN,$rulesfile) || return 0;
	while(<IN>) {
		my @line;
		s/#.*//;
		next if (/^\s*$/);
		@line = split(/\s+/,$_);
		push(@tokens,@line,"ENDL");
	}
	close IN || return 0;
	return \@tokens;
}

# just sets up the targets without dependencies for now
sub targets {
	my $tokens = tokens();
	my %targets;
	my %deps;

	my $curtoken;
	my $dep = 0;
	my $ncom = 0;
	my $cmdcnt;
	my $idx;

	foreach my $item (@$tokens) {
		if ($item =~ /:$/) {
			# this is the target name
			$item =~ s/://;
			$curtoken = $item;
			# the rest are deps
			$dep = 1;
			# new commands should be pushed here:
			$cmdcnt = 0;
			next;
		}
		if ($item eq 'ENDL') {
			# end of deps (if any)
			$dep = 0;
			$ncom = 1;
			next;
		}
		if ($dep) {
			push(@{$deps{$curtoken}},$item);
			next;
		}
		# if we are here there is a command or the starting dir
		# 
		# if rules file is correct, startdir will always be in idx 0 
		next if ($item eq "startdir" || $item eq "else");
		if ($ncom) {
			$ncom = 0;
			$idx = $cmdcnt;
			$cmdcnt++;
		} 
		push(@{$targets{$curtoken}[$idx]},$item);

	}

	# resolve deps
	# endless loop detect
	foreach my $key (keys %deps) {
		my %had;
		$had{$key} = 1;
		foreach my $val (@{$deps{$key}}) {
			if ($had{$val}) {
				die "FATAL: Endless recursion in rules file ($key)\nNon recoverable\n";
			}
			my $lkpval = $val;
			if ($val =~ /~/) {
				# modifier available
				$lkpval = (split(/~/,$val))[0];
			}
			if (defined $deps{$lkpval}) {
				push(@{$deps{$key}},@{$deps{$lkpval}});
			}
		}
		# Go through it again to make sure we don't do targets twice
		my $dhad = {};
		my @nval = ();
		foreach my $val (@{$deps{$key}}) {
			push(@nval,$val) unless (defined $dhad->{$key}{$val});
			$dhad->{$key}{$val} = 1;
		}
		@{$deps{$key}} = @nval;
	}
	return [\%targets,\%deps];
}

		


#END
1;

