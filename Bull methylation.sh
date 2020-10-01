a #!/bin/bash
#SBATCH --job-name=meth
#SBATCH -p medium
#SBATCH -n 1
#SBATCH --cpus-per-task=10
#SBATCH -t 7-00:00:00
#SBATCH --output=../meth_%A_%a.out
#SBATCH --error=../meth_%A_%a.err
#SBATCH --array=1-11
module load fastqc
module load bowtie2
module load cutadapt
module load samtools

cd /project/bull_scr/clean_data
file=`ls -d H0* L01 L04 L05 L06 L09| head -n $SLURM_ARRAY_TASK_ID|tail -n 1`


name=`echo ${file}`
trim_galore="/project/uvm_mckay/bin/TrimGalore-master/trim_galore"
bismark="/beegfs/project/uvm_mckay/bin/Bismark_v0.19.0"
genome_folder="/beegfs/project/bull_age/dor_new_assembly"

#run trim_galore
cd /project/uvm_mckay/WGBS_others/tissue-specific-MHL/Sperm_methylation_ARS
mkdir ${file}
cd ${file}
mkdir trim_reads

${trim_galore} --paired --fastqc --max_n 15 -o ./trim_reads /project/bull_scr/clean_data/${file}/QCtrim/${name}_1.fq.gz /project/bull_scr/clean_data/${file}/QCtrim/${name}_2.fq.gz


#run bismark
mkdir bamfile
cd ./trim_reads

if [ -e ${name}_1_val_1.fq.gz ]
then
${bismark}/bismark --multicore 2 --bowtie2 --gzip -p 4 -N 0 -o ../bamfile ${genome_folder} -1 ${name}_1_val_1.fq.gz -2 ${name}_2_val_2.fq.gz
else
exit
fi


#run deduplicate_bismark
cd ../bamfile

if [ -e ${name}_1_val_1_bismark_bt2_pe.bam ]
then
${bismark}/deduplicate_bismark -p --bam ${name}_1_val_1_bismark_bt2_pe.bam
else
exit
fi

mkdir ../methylation
${bismark}/bismark_methylation_extractor -p --ignore_r2 6 --multicore 8 --bedgraph -o ../methylation --cytosine_report --genome_folder ${genome_folder} *.deduplicated.bam



             
