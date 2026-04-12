#受体准备方法：
AutoDock Tools准备
盒子参数格式样例(configure.txt)：
center_x = -1.0
center_y = 5.151
center_z = -0.5
size_x = 20.0
size_y = 18.0
size_z = 28.0

#配体准备
LigPrep(Schrodinger工具)处理所有分子(都在一个文件中)
处理后利用meeko转为pdbqt
mk_prepare_ligand.py -i ligprep-out.sdf -o ligprep-out.pdbqt --multimol_outdir pdbqt

#利用脚本将每个小分子分割为单个文件


#虚拟筛选
##$prov为小分子id（比如ligprep-out-1，ligprep-out-2）
for db in $prov
do
{
 vina_1.2.5_linux_x86_64 --receptor receptor.pdbqt --config configure.txt --ligand pdbqt/${db}.pdbqt --exhaustiveness=32 --seed 123 --out vina_out/${db}_out.pdbqt >>vina_out.log
}&
done

#感兴趣小分子利用Meeko工具将pdbqt转为sdf，方便后续可视化
source activate meeko
cd vina_out_interested_ligand
for i in $(ls)
do
a=${i%%.*}
mk_export.py $i -o $a.sdf
done








