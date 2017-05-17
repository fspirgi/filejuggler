# fj_walker
# 
# provides a file system walker
# that accepts a ref to an array of function pointers that are ADDed and called with each file
#
# first one is usually meant as a checker and
# second as a doer. other usages can be thought of of course
#

package fj_walker;

# use fj_builtins;

sub fj_walker {
	my $startdir = shift;
	my $funcs = shift;
	my $elsefunc = shift;
	my $logfunc = &fj_builtins::fj_log_func;
	my $retval = 0;

	my @stack;
	push(@stack,$startdir);

	$logfunc->("Start working on $startdir");
	while (my $dir = shift @stack) {
		# default is to succeed
		opendir(DIR,$dir) || ($logfunc->("$dir: $!") && next);
		while (my $file = readdir(DIR)) {
			next if ($file =~ /^\.{1,2}/);
			my $lstat = 1;
			my $type = 1; # normally we work with normal files
			if (-d "$dir/$file") {
				# we have a directory, put it on the stack
				push(@stack,"$dir/$file");
				$type = 0;
			}
			if (-f "$dir/$file") {
				$type = 1;
				# last status variable
				# file, call the functions ANDed	
			}
			foreach my $func (@$funcs) {
				unless ($lstat = $func->("$dir/$file",$type)) {
					$elsefunc->("$dir/$file",$type);
					last;
				}
			}
			# set it to succeed if there was something to do.
			$retval = 1 if ($lstat);
		}
		$logfunc->("No file found to process") unless ($retval);
	}
	$logfunc->("Finished working on $startdir");
	return $retval;
}


# END
1;

