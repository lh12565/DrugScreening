#软件
https://manual.gromacs.org/current/download.html
https://valdes-tresanco-ms.github.io/gmx_MMPBSA/dev/installation/
https://avogadro.cc/install/index.html



#2022版不一样，加-ter参数，需要选 Start terminus MET-1: NH3+   End terminus LYS-371: COO-(来自https://gromacs.bioexcel.eu/t/atom-c1-not-found-in-building-block-pdb2gmx-fatal-error/5206)
gmx_mpi pdb2gmx -f receptor.pdb -o rec_processed.gro -ter


cd ligand1  #进入特定配体（如ligand1）文件夹，在这里运行和存储蛋白和ligand1的MD相关输出文件
cp -R ../charmm36-jul2022.ff/ .
#pro_lig.pdb来自于从pymol中导入原始蛋白pdb和对接后的配体sdf（之前通过meeko将vina输出的pdbqt转为sdf的文件），保存为此文件
grep UNL pro_lig.pdb >lig.pdb
#grep HETATM pro_lig.pdb >lig.pdb  #提取配体信息。根据自己的配体文件修改grep的HETATM内容
#Avogadro:  addh  保存为mol2
#修改小分子(lig)  #....变为lig   UNK*变为lig

perl ../script/sort_mol2_bonds.pl lig.mol2 lig_fix.mol2
#去CGenFF（https://cgenff.com/）生成str

##注意这里的警告中的版本与自己的版本需要尽量一致
source activate gromacs
python ../script/cgenff_charmm2gmx_py3_nx2.py lig lig_fix.mol2 lig_fix.str ../charmm36-jul2022.ff
conda deactivate


gmx_mpi editconf -f lig_ini.pdb -o lig.gro
#md运行前，常常需要修改gro、top等文件，比如添加配体信息，添加体系限制等，用我的脚本添加更方便：
#先备份一份原始文件，以便之后处理错误后，再复制这个原始文件
#mkdir ori
#cp rec_processed.gro ori/
#cp posre.itp ori/
#topol.top ori/

#修改complex.gro:
perl ../script/addatom.pl lig.gro rec_processed.gro


#cp ../topol.top .
#修改topol文件(已经修改)[注意：把lig信息加进去]


#盒子和水模型
gmx_mpi editconf -f complex.gro -o newbox.gro -bt dodecahedron -d 1.0
gmx_mpi solvate -cp newbox.gro -cs spc216.gro -p topol.top -o solv.gro


##能量最小化配置（需要ion.mdp）
gmx_mpi grompp -f ../mdp/ions.mdp -c solv.gro -p topol.top -o ions.tpr
##加NACL
gmx_mpi genion -s ions.tpr -o solv_ions.gro -p topol.top -pname SOD -nname CLA -neutral  #2022版charmm的ions.itp：NA为SOD  CL为CLA
###选15 SOL 来替换NACL

##能量最小化（需要em.mdp）
gmx_mpi grompp -f ../mdp/em.mdp -c solv_ions.gro -p topol.top -o em.tpr
gmx_mpi mdrun -v -deffnm em

##1. 对配体施加约束2. 温度耦合组的处理
###生成一个配体位置约束拓扑
####首先为配体创建一个只包含非氢原子的索引组
gmx_mpi make_ndx -f lig.gro -o index_lig.ndx
 > 0 & ! a H*
 > q
###用genrestr选择上面的非氢配体组
gmx_mpi genrestr -f lig.gro -n index_lig.ndx -o posre_lig.itp -fc 1000 1000 1000
####选3

###加入约束信息到topol.top
####对于不同的约束加入不同的约束条件:
perl ../script/addmode2.pl topol.top

##如果对每个分子类型进行温度耦合（即tc-grps = Protein lig SOL CL），会造成崩溃（耦合算法的不稳定性，如配体和CL）
##可以设置为tc-grps = Protein Non-Protein，但是蛋白和配体互作性高，可以看成整体
###合并蛋白和配体
gmx_mpi make_ndx -f em.gro -o index.ndx
> 1 | 13
> 15 | 14   #根据自己的参数来
> q
##现在可以将tc-grps = Protein_lig Water_and_ions看做为Protein Non-Protein
###执行NVT（需要nvt.mdp）
gmx_mpi grompp -f ../mdp/nvt.mdp -c em.gro -r em.gro -p topol.top -n index.ndx -o nvt.tpr
gmx_mpi mdrun -v -deffnm nvt
###执行NPT（需要npt.mdp）
gmx_mpi grompp -f ../mdp/npt.mdp -c nvt.gro -t nvt.cpt -r nvt.gro -p topol.top -n index.ndx -o npt.tpr
gmx_mpi mdrun -v -deffnm npt


gmx_mpi grompp -f ../mdp/md.mdp -c npt.gro -t npt.cpt -p topol.top -n index.ndx -o md_0_10.tpr
gmx_mpi mdrun -v -deffnm md_0_10  # 100ns 根据mdp文件修改
#gmx_mpi mdrun -v -deffnm md_0_10  -gpu_id 1



#rmsd
###Choose "Protein" for centering and "System" for output. 
echo 1 0 | gmx_mpi trjconv -s md_0_10.tpr -f md_0_10.xtc -o md_0_10_center.xtc -center -pbc mol -ur compact
gmx_mpi make_ndx -f em.gro -n index.ndx <<EOF
13 & ! a H*
name 20 lig_Heavy
q
EOF
###选择backbone和20
echo 4 20 | gmx_mpi rms -s em.tpr -f md_0_10_center.xtc -n index.ndx -tu ns -o rmsd_lig.xvg


#gmx_MMPBSA
#gmx_MMPBSA -O -i mmpbsa_charm.in -cs md_0_10.tpr -ci index.ndx -cg 1 13 -ct md_0_10_center.xtc
source activate gmxMMPBSA

#修改平衡的frame，比如75-100在mmpbsa_charm.in里面改,更多参数修改，请参考gmxMMPBSA手册：https://valdes-tresanco-ms.github.io/gmx_MMPBSA/dev/input_file/
cd mmpbsa
mpirun -np 10 gmx_MMPBSA MPI -O -i mmpbsa_charm.in -cs ../md_0_10.tpr -ci ../index.ndx -cg 1 13 -ct ../md_0_10_center.xtc -cp ../topol.top



