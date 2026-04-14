#本教程通过AutoDock Vina对接

#安装软件
https://github.com/ccsb-scripps/AutoDock-Vina
https://github.com/forlilab/Meeko
https://ccsb.scripps.edu/mgltools/
https://www.schrodinger.com/release-download/  (收费) 或者 https://github.com/rdkit/rdkit  (免费)


#受体准备方法（移除非必须分子，如水分子；加H，电荷）：
AutoDock Tools准备（可参考：https://vina.scripps.edu/tutorial/或https://2024.igem.wiki/nyu-new-york/contribution）
盒子参数格式样例(configure.txt)：
###################################
receptor = receptor.pdbqt  #可选
ligand = ligand.pdbqt  #可选

center_x = -1.0
center_y = 5.151
center_z = -0.5
size_x = 20.0
size_y = 18.0
size_z = 28.0

energy_range = 4  #可选
exhaustiveness = 12  #可选
num_modes = 9  #可选
###################################


#配体准备（加H，电荷，质子化）
##1)如果是一个小分子或少量小分子，直接用AutoDock Tools处理（参见以上链接）
##2)如果是虚拟筛选多个小分子，可用LigPrep或RDKit处理：
###LigPrep
LigPrep(Schrodinger工具:一般保持默认参数)处理所有分子(都在一个文件中)；保存为sdf文件
###RDKit
#################################################
from rdkit import Chem
from rdkit.Chem import rdDistGeom
from rdkit.Chem import rdForceFieldHelpers

mol = Chem.MolFromMol2File("molecule.mol2")  #mol2格式
mol_h = Chem.AddHs(mol)
etkdgv3 = rdDistGeom.ETKDGv3()  #3D构象
rdDistGeom.EmbedMolecule(mol_h, etkdgv3)
rdForceFieldHelpers.UFFOptimizeMolecule(mol_h)
print(Chem.MolToMolBlock(mol_h), end='')

#或者
from rdkit import Chem
from rdkit.Chem import AllChem
smiles = "CC(C)CC1=CC=C(C=C1)C(C)C(=O)O"  #示例
mol = Chem.MolFromSmiles(smiles)
mol = Chem.AddHs(mol)
AllChem.EmbedMolecule(mol, randomSeed=42)   #注：AllChem.EmbedMultipleConfs(mol, numConfs=10, randomSeed=42)可以生成多个构象
AllChem.MMFFOptimizeMolecule(mol)  #用MMFF力场优化几何结构

#多个分子保存
from rdkit import Chem
from rdkit.Chem import AllChem
supplier = Chem.SDMolSupplier("ligands_2d.sdf", removeHs=False)  #sdf格式
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

##处理后利用meeko转为pdbqt（注意：Meeko的输入：The input needs to be 3D and protonated, and SD files are preferred to MOL2）：
mk_prepare_ligand.py -i ligprep-out.sdf --multimol_prefix lig --multimol_outdir pdbqt

##将id（上面的pdbqt文件夹中输出的每个小分子id）和药物对应起来：
###注我的文件里面有<IDNUMBER>， <NAME>等内容，下面代码根据你的内容修改
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



#虚拟筛选
##$prov为小分子id（比如ligprep-out-1，ligprep-out-2）
for db in $prov
do
{
 vina_1.2.5_linux_x86_64 --receptor receptor.pdbqt --config configure.txt --ligand pdbqt/${db}.pdbqt --exhaustiveness=32 --seed 123 --out vina_out/${db}_out.pdbqt >>vina_out.log
}&
done

#提前ID和分数（perl）:
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

##输出后需要结合上面的vina_id.txt文件来看对应药物
#####################################################


#感兴趣小分子利用Meeko工具将pdbqt转为sdf，方便后续可视化
source activate meeko
cd vina_out_interested_ligand
for i in $(ls)
do
a=${i%%.*}
mk_export.py $i -o $a.sdf
done








