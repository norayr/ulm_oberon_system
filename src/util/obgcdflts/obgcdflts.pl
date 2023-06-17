#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;

my $cmdname = $0; $cmdname =~ s{.*/}{};
my $usage = "Usage: $cmdname confdir\n";
die $usage unless @ARGV == 1;
my $confdir = shift;

my $in = new IO::File "/proc/meminfo"
   or die "$cmdname: unable to open /proc/meminfo\n";

my $physmem;
while (<$in>) {
   next unless ($physmem) = m{^MemTotal:\s+(\d+)\s+kB$};
   last;
}
die "$cmdname: unable to retrieve size of physical memory\n"
   unless defined $physmem;

my %intensity = ();
if ($physmem >= 1000000) {
   $intensity{cdbd} = 9;
   $intensity{obload} = 8;
} elsif ($physmem >= 800000) {
   $intensity{cdbd} = 8;
   $intensity{obload} = 8;
} elsif ($physmem >= 600000) {
   $intensity{cdbd} = 7;
   $intensity{obload} = 7;
} else {
   $intensity{cdbd} = 6;
   $intensity{obload} = 6;
}

foreach my $tool (keys %intensity) {
   my $outfile = "$confdir/$tool";
   my $out = new IO::File $outfile, O_WRONLY|O_CREAT|O_TRUNC, 0644
      or die "$cmdname: unable to create $outfile: $!\n";
   print $out $intensity{$tool}, "\n";
   $out->close or die "$cmdname: unable to write to $outfile: $!\n";
}
