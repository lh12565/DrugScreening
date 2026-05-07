# This tutorial uses AutoDock Vina for docking

# Install the software
https://github.com/ccsb-scripps/AutoDock-Vina
https://github.com/forlilab/Meeko
https://ccsb.scripps.edu/mgltools/
https://www.schrodinger.com/release-download/ (commercial) or https://github.com/rdkit/rdkit (free)


# Receptor preparation (remove non-essential molecules, e.g., water; add hydrogen atoms and charges):
## AutoDock Tools preparation（refer to: https://vina.scripps.edu/tutorial/ or https://2024.igem.wiki/nyu-new-york/contribution）
Example of box parameter format (configure.txt)：
###################################
receptor = receptor.pdbqt  # Optional
ligand = ligand.pdbqt  # Optional

center_x = -1.0
center_y = 5.151
center_z = -0.5
size_x = 20.0
size_y = 18.0
size_z = 28.0

energy_range = 4  # Optional
exhaustiveness = 12  # Optional
num_modes = 9  # Optional
###################################


# Ligand preparation (adding hydrogen atoms, charges, and protonation)
## 1)For a single small molecule or a few small molecules, process directly with AutoDock Tools (see above links)
## 2)For virtual screening of multiple small molecules, LigPrep or RDKit can be used for processing:
###LigPrep
LigPrep (Schrodinger tool: generally keep default parameters) processes all molecules (all in one file); save as an sdf file.
###RDKit
#################################################
from rdkit import Chem
from rdkit.Chem import rdDistGeom
from rdkit.Chem import rdForceFieldHelpers

mol = Chem.MolFromMol2File("molecule.mol2")  # mol2 format
mol_h = Chem.AddHs(mol)
etkdgv3 = rdDistGeom.ETKDGv3()  # 3D structure
rdDistGeom.EmbedMolecule(mol_h, etkdgv3)
rdForceFieldHelpers.UFFOptimizeMolecule(mol_h)
print(Chem.MolToMolBlock(mol_h), end='')

# Or
from rdkit import Chem
from rdkit.Chem import AllChem
smiles = "CC(C)CC1=CC=C(C=C1)C(C)C(=O)O"  # Example
mol = Chem.MolFromSmiles(smiles)
mol = Chem.AddHs(mol)
AllChem.EmbedMolecule(mol, randomSeed=42)   # Note: AllChem.EmbedMultipleConfs(mol, numConfs=10, randomSeed=42) can be used to generate multiple conformations
AllChem.MMFFOptimizeMolecule(mol)  # Optimize the geometry using the MMFF force field

# Save multiple molecules
from rdkit import Chem
from rdkit.Chem import AllChem
supplier = Chem.SDMolSupplier("ligands_2d.sdf", removeHs=False)  # sdf format
writer = Chem.SDWriter("ligands_3d_confs.sdf")
for mol in supplier:
    if mol is None:
        continue
    mol_h = Chem.AddHs(mol)
    AllChem.EmbedMolecule(mol_h, randomSeed=42) 
    AllChem.MMFFOptimizeMolecule(mol_h)
    writer.write(mol_h)
writer.close()
#################################################

## After processing, use Meeko to convert to pdbqt (Note: The input needs to be 3D and protonated, and SD files are preferred to MOL2):
mk_prepare_ligand.py -i ligprep-out.sdf --multimol_prefix lig --multimol_outdir pdbqt

## Map the IDs (each small molecule ID output in the pdbqt folder above) to the corresponding drugs:
### Note: My file contains <IDNUMBER>, <NAME>, etc. Modify the code below according to your own file.
############################################################
#! /usr/bin/perl -w
open INA,"$ARGV[0]" or die "cannot open ligprep-out.sdf:$!";
open OUT,'>>vina_id.txt' or die "$!";
$i=1;
$/="\$\$\$\$";
while(<INA>){
	push @sdf,$_;
}
$/="\n";
foreach(@sdf){
	$myfile="specs-".$i.".pdbqt";
	print OUT $myfile."\t";
	if(/> <IDNUMBER>\n(.*?)\n/){
		print OUT $1."\t";
	}
	if(/> <NAME>\n(.*?)\n/){
		print OUT $1."\t";
	}
	if(/> <s_m_source_file>\n(.*?)\n/){
		print OUT $1."\t";
	}
	if(/> <s_lp_Variant>\n(.*?)\n/){
		print OUT $1;
	}
        print OUT "\n";
	$i=$i+1;
}
close INA;
close OUT;
############################################################



# Virtual screening
##$prov为小分子id（e.g. ligprep-out-1，ligprep-out-2）
for db in $prov
do
{
 vina_1.2.5_linux_x86_64 --receptor receptor.pdbqt --config configure.txt --ligand pdbqt/${db}.pdbqt --exhaustiveness=32 --seed 123 --out vina_out/${db}_out.pdbqt >>vina_out.log
}&
done

# Extract IDs and scores (Perl):
#####################################################
#!/usr/bin/perl
opendir DIR,"$ARGV[0]" or die "cannot open dir:$!";

open OUT,'>>vina_res.txt' or die "$!";

foreach $file(sort readdir DIR){
	open INA,$ARGV[0].$file or die "cannot open file $file:$!";
	while(<INA>){
		if(/REMARK VINA RESULT/){
			@score=split /\s+/, $_;
			#print $score[1];
			#$a=~s/\s+//,$score[1];
			print OUT $file."\t".$score[3]."\n";
			close INA;
			last;
		}
	}
}

## After output, combine with the vina_id.txt file above to identify the corresponding drugs.
#####################################################


#Convert pdbqt to sdf using the Meeko tool for small molecules of interest to facilitate downstream visualization.
source activate meeko
cd vina_out_interested_ligand
for i in $(ls)
do
a=${i%%.*}
mk_export.py $i -o $a.sdf
done








