#!/usr/bin/perl
open INA,"$ARGV[0]" or die "cannot open topol.top:$!";
$/=/^\s+$/;
@topol=<INA>;
close INA;
open OUT,'>topol.top' or die "$!";
$/="\n";
foreach (@topol){ 
 if($_=~/; Include ligand topology/){
	$_="$_; Ligand position restraints\n# ifdef POSRES\n#include \"posre_lig.itp\"\n#endif\n\n";
	}
}
print OUT @topol;
close INA;
close OUT;
