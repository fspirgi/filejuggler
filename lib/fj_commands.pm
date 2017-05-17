package fj_commands;
# provides the commands catalog
#

use FindBin qw($Bin);
my $fj_commands = {};
my $fj_modlib = "$Bin/../lib/fj_modlib"; # "require" the mods from there


# each module must have an fj_provides function,
# let's call these
sub what_provides {
	my $module = shift;
	# I'm sure there is a better way than evaluated strings...
	my $func = "${module}::fj_provides";
	my $provides = &$func;

	foreach my $key (keys %$provides) {
		$fj_commands->{$key} = $provides->{$key};
	}
}

# sub find_mods 
sub find_modules {
	opendir(IN,$fj_modlib) || (warn "Module directory $fj_modlib not opened: $!" && return 0);
	while (my $file = readdir(IN)) {
		next unless ($file =~ /\.pm/);
		require "$fj_modlib/$file";
		$file =~ s/\.pm$//;
		&what_provides($file);
	}
	closedir(IN);
	return 1;
}

sub catalog {
	return $fj_commands;
}


# END
1;
