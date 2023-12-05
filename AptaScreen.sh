#!/bin/bash


################################ AptamerScreen.sh ###########################
#Get pipeline directory
HomeDir=$(dirname `readlink -f $0`)
#set default parameters
array=( "$@" ) #read all command line variable to "array"
AdapterF="" # store the 5' adapter/conserved sequence if forward strand is sequenced
AdapterR="" # store the 5' adapter/conserved sequence if reverse strand is sequenced
Length=40 # store the length of diverse region (Ns)
Table=0  # store the name of the integrated table generated
P=1
counter=0 #counter to keep track of the variable indexes
keep=100000 #keep the top 100000 enriched sequences

#export R_LIBS_SITE="${HomeDir}/Rlib"

if [ $# == 0 ]
    then
        echo "********************************************************************************************"
        echo "*                 AptaScreen: pipeline for RNA Aptamer screening (SELEX)                   *"
        echo "*                              Version 6, 2023-05-15, F.J                                  *"
        echo "* Usage: AptaScreen.sh -i file1 file2 file3 [options]                                      *"
        echo "*        Required (unstrandaed single end sequencing data) :                               *"
        echo "*                 -i --input Input raw fastq/fastq.gz.                                     *"
        echo "*                    For multiple files use -i file1 file2 file3.                          *"
        echo "*        Optional flags:                                                                   *"
        echo "*                 -n --name Names of input files.                                          *"
        echo "*                    For multiple files use -n file1name file2name file3name.              *"
        echo "*                    Default: Filenames of fastq/fastq.gz                                  *"
        echo "*                 -g1 5' adapter/conserved sequence if forward strand is sequenced.        *"
        echo "*                    Default: -g1 GGGGGAATTCTAATACGACTCACTATAGGGAGGACGATGCGG               *"
        echo "*                 -g2 5' adapter/conserved sequence if reverse strand is sequenced.        *"
        echo "*                    Default: -g2 TCTCGGATCCTCAGCGAGTCGTCTG                                *"
        echo "*                 -l --length Length of diverse region (Ns).                               *"
        echo "*                    Default: -l 40                                                        *"
        echo "*                 -t --table Generate a integrated table for all fastq files processed     *"
        echo "*                    Example: -t tablename                                                 *"
        echo "*                    Default: -t Integrated_table                                          *"
        echo "*                 -k --keep number of top enriched sequences to keep in the table          *"
        echo "*                    For more than one fastq input, the intergated table will only show the*"
        echo "*                    top 'k' sequences in the last fastq.                                  *"
        echo "*                    Default: -k 100000                                                    *"
        echo "*                 -p --processer Number of processers to use for parallel computing.       *"
        echo "*                    Default: -p 1                                                         *"
        echo "* This is the all-in-one function for RNA aptamer screening.                               *"
        echo "* This function assumes that unstranded single-end sequencing is perfromed.                *"
        echo "* This function assumes that sequenced library to be as follows:                           *"
        echo "*      adapter(conserved region)-NNNNNNNNNNNNNNNNNNN-adapter(conserved regiion)            *"
        echo "* NOTE: R, cutadapt, and fastx are required and should be loaded prior to analysis.        *"
        echo "********************************************************************************************"
        exit 1
fi
echo "********************************************************************************************"
echo "*                 AptaScreen: pipeline for RNA Aptamer screening (SELEX)                   *"
echo "*                              Version 6, 2023-05-15, F.J                                  *"
echo "********************************************************************************************"
echo "0. Loading softwares:"
#echo "${array[@]}"
#echo "${#array[@]}"
#echo "${#Input[@]}"
#echo "${Input[@]}"
#echo "${Name[@]}"
#echo "${#Name[@]}"
for var in "$@" #for every variable
do 

#if the variable is "-i", set up input file
    if [[ $var == "-i" || $var == "--input" ]] 
    then 
        Input=( ${array[$counter+1]} )
        echo "${Input[@]}"
        # if there is more than one input file, set up it as well
        index=$((counter+2))
        while [ $index -le ${#array[@]} ]
        do
          if [[ ${array[$index]} != "-n" && ${array[$index]} != "--name" && ${array[$index]} != "-i" && ${array[$index]} != "--input" && ${array[$index]} != "-g1" && ${array[$index]} != "-g2" && ${array[$index]} != "-t" && ${array[$index]} != "--table" && ${array[$index]} != "-h" && ${array[$index]} != "-l" && ${array[$index]} !=  "--length" && ${array[$index]} != "--help" && ${array[$index]} != "-p" && ${array[$index]} != "--processer" ]]
          then
              Input+=( ${array[$index]} )
              ((index+=1))
          else
              index=${#array[@]}
          fi
        done
        #echo "Input filess ${Input[@]}"
        #echo "Input ${#Input[@]} filess"
#if the variable is "-n", set up names of input
    elif [[ $var == "-n" || $var == "--name" ]]
    then
        Name=( ${array[$counter+1]} )
        # if there is more than one input file, set up it as well
        index=$((counter+2))
        while [ $index -le ${#array[@]} ]
        do
          if [[ ${array[$index]} != "-n" && ${array[$index]} != "--name" && ${array[$index]} != "-i" && ${array[$index]} != "--input" && ${array[$index]} != "-g1" && ${array[$index]} != "-g2" && ${array[$index]} != "-t" && ${array[$index]} != "--table" && ${array[$index]} != "-h" && ${array[$index]} != "-l" && ${array[$index]} !=  "--length" && ${array[$index]} != "--help" && ${array[$index]} != "-p" && ${array[$index]} != "--processer" ]]
          then
              Name+=( ${array[$index]} )
              ((index+=1))
          else
              index=${#array[@]}    
          fi
        done
#if the variable is -g1, set up the 5' adapter/conserved sequence if forward strand is sequenced
    elif [[ $var == "-g1" ]]
    then
        AdapterF=( ^${array[$counter+1]} )
        AdapterR3=$( echo ${array[$counter+1]} | tr ACGTacgt TGCAtgca | rev )
#if the variable is -g2, set the 5' adapter/conserved sequence if reverse strand is sequenced
    elif [[ $var == "-g2" ]]
    then
        AdapterR=( ^${array[$counter+1]} )
        AdapterF3=$( echo ${array[$counter+1]} | tr ACGTacgt TGCAtgca | rev )
#if the variable is -l, set up the length of diverse region (Ns)
    elif [[ $var == "-l" || $var == "--length" ]]
    then
        Length=( ${array[$counter+1]} )
#if the variable is -k, set up the number of sequences (count from top enriched) to keep 
    elif [[ $var == "-k" || $var == "--keep" ]]
    then
        keep=( ${array[$counter+1]} )
        num=$((keep+1))
#if the variable is -t, set up the table name for the intrgrated table generated
    elif [[ $var == "-t" || $var == "--table" ]]
    then
        Table=( ${array[$counter+1]} )
#if the variable is -t, set up the table name for the intrgrated table generated
    elif [[ $var == "-p" || $var == "--processer" ]]
    then
        P=( ${array[$counter+1]} )
#if the variable is -h, generate help information
    elif [[ $var == "-h" || $var == "--help"  ]]
    then
        echo "********************************************************************************************"
        echo "*                 AptaScreen: pipeline for RNA Aptamer screening (SELEX)                   *"
        echo "*                              Version 6, 2023-05-15, F.J                                  *"
        echo "* Usage: AptaScreen.sh -i file1 file2 file3 [options]                                      *"
        echo "*        Required (unstrandaed single end sequencing data) :                               *"
        echo "*                 -i --input Input raw fastq/fastq.gz.                                     *"
        echo "*                    For multiple files use -i file1 file2 file3.                          *"
        echo "*        Optional flags:                                                                   *"
        echo "*                 -n --name Names of input files.                                          *"
        echo "*                    For multiple files use -n file1name file2name file3name.              *"
        echo "*                    Default: Filenames of fastq/fastq.gz                                  *"
        echo "*                 -g1 5' adapter/conserved sequence if forward strand is sequenced.        *"
        echo "*                    Default: -g1 GGGGGAATTCTAATACGACTCACTATAGGGAGGACGATGCGG               *"
        echo "*                 -g2 5' adapter/conserved sequence if reverse strand is sequenced.        *"
        echo "*                    Default: -g2 TCTCGGATCCTCAGCGAGTCGTCTG                                *"
        echo "*                 -l --length Length of diverse region (Ns).                               *"
        echo "*                    Default: -l 40                                                        *"
        echo "*                 -t --table Generate a integrated table for all fastq files processed     *"
        echo "*                    Example: -t tablename                                                 *"
        echo "*                    Default: -t Integrated_table                                          *"
        echo "*                 -k --keep number of top enriched sequences to keep in the table          *"
        echo "*                    For more than one fastq input, the intergated table will only show the*"
        echo "*                    top 'k' sequences in the last fastq.                                  *"
        echo "*                    Default: -k 100000                                                    *"
        echo "*                 -p --processer Number of processers to use for parallel computing.       *"
        echo "*                    Default: -p 1                                                         *"
        echo "* This is the all-in-one function for RNA aptamer screening.                               *"
        echo "* This function assumes that unstranded single-end sequencing is perfromed.                *"
        echo "* This function assumes that sequenced library to be as follows:                           *"
        echo "*      adapter(conserved region)-NNNNNNNNNNNNNNNNNNN-adapter(conserved regiion)            *"
        echo "* NOTE: R, cutadapt, and fastx are required and should be loaded prior to analysis.        *"
        echo "********************************************************************************************"
        exit 1
    fi
    ((counter+=1)) #iterate counter
done

# check whether input files are valid
# if no input provided
if [[ ${#Input[@]} == 0 ]]
then
    echo "[Error] No input provided."
    exit 1
fi

# check whether the paired sequenced input files exist
for i in ${Input[@]}
do
 if [ -s ${i} ]
 then
    echo "load sequence files: ${i} "
 else
    echo "[Error] ${i} dose not exist."
    exit 1
 fi
done

# if name is not provided for all input fasta, set to filenames of inpit files
if [[ ${#Name[@]} != ${#Input[@]} ]] 
then
   Name=("${Input[@]}")
   echo "names are not provided for all input fastq. Use filenames instead."
else
   echo "setting sample names to ${Name[@]}"
fi

echo "trim $AdapterF for forward reads"
echo "trim $AdapterR for reverse reads"
echo "keep $Length nucletide as the NNNNN region"

# if table is not provided, set table name to Integrated_table
if [[ $Table == 0 ]] 
then
   Table=Integrated_table
fi
echo "set integrated table name to $Table"
echo "keep top $keep sequences in the integrated table"
echo "set number of processers to $P"


# time to start the analysis
start=$(date +%s.%N)

echo "***** analysis began........"
# start analysis
for i in ${Input[@]}
do
  echo "***** process ${i}........"
# trim the reads when forward strand is sequenced
  echo "cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -g $AdapterF -m $Length --trimmed-only -o $i.R1.T1.trim.fastq.gz $i > $i.trim.cutadpt.log"

  cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -g $AdapterF -m $Length --trimmed-only -o $i.R1.T1.trim.fastq.gz $i > $i.trim.cutadpt.log
  
  echo "cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -a ${AdapterF3}X -m $Length --trimmed-only -o $i.R1.trim.fastq.gz $i.R1.T1.trim.fastq.gz >> $i.trim.cutadpt.log"
  
  cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -a ${AdapterF3}X -m $Length --trimmed-only -o $i.R1.trim.fastq.gz $i.R1.T1.trim.fastq.gz >> $i.trim.cutadpt.log

# trim the reads when reverse strand is sequenced
  echo "cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -g $AdapterR -m $Length --trimmed-only -o $i.R2.T1.trim.fastq.gz $i >> $i.trim.cutadpt.log"

  cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -g $AdapterR -m $Length --trimmed-only -o $i.R2.T1.trim.fastq.gz $i >> $i.trim.cutadpt.log
  
  echo "cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -a ${AdapterR3}X -m $Length --trimmed-only -o $i.R2.trim.fastq.gz $i.R2.T1.trim.fastq.gz >> $i.trim.cutadpt.log"
  
  cutadapt -f fastq -j 15 --max-n 0 --times 1 -e 0.1 -O 1 --quality-cutoff 5 -a ${AdapterR3}X -m $Length --trimmed-only -o $i.R2.trim.fastq.gz $i.R2.T1.trim.fastq.gz >> $i.trim.cutadpt.log

# reverse compliment the reads when reverse strand is sequenced 
  #echo "reverse compliment the reads when reverse strand is sequenced"
  gunzip -c $i.R2.trim.fastq.gz > $i.R2.trim.fastq
  fastx_reverse_complement -z -i $i.R2.trim.fastq -o $i.R2.trim.rev.fastq.gz
# combine the processed fastq
  #echo "combine the reads when forward strand is sequenced and reads when reverse strand is sequenced"
  cat $i.R1.trim.fastq.gz $i.R2.trim.rev.fastq.gz > $i.trim.processed.combined.fastq.gz
  rm $i.R2.trim.fastq.gz
  rm $i.R2.trim.fastq
  rm $i.R2.trim.rev.fastq.gz
  rm $i.R1.trim.fastq.gz
  rm $i.R1.T1.trim.fastq.gz
  rm $i.R2.T1.trim.fastq.gz
done

echo "***** use FASTaptamer to count sequences........"
# use FASTaptamer to count the sequences
for i in ${Input[@]}
do
  echo "count ${i}........"
# unzip the fastq
  gunzip -c $i.trim.processed.combined.fastq.gz > $i.trim.processed.combined.fastq
# use Fastaptamer count 
  perl ${HomeDir}/software/FASTAptamer_v1.0.3/fastaptamer_count -i $i.trim.processed.combined.fastq -o $i.trim.processed.combined.count.fasta
  echo ""
done

echo "***** call R to generate raw count tables........"

echo "***** call R to generate raw count tables........" > R.log
# calling R to generate an count tables for all fastq
WD=$(pwd)
for i in ${!Input[@]}
do
  ((n=n%P)); ((n++==0)) && wait
  echo "generate raw count table for ${Input[i]}........"
  echo "count table for ${Input[i]} is named as ${Name[i]}"
  linux_call_R.sh ${HomeDir}/bin/Aptamer_table.R $WD ${Input[i]} ${Name[i]} 1>>R.log &
done

wait

# check whether count tables are made
for i in ${Name[@]}
do
  if [ ! -s $i.csv ]
  then
     echo "[Error] count table, ${i} is missing or empty, check R.log for details."
     exit 1
  fi
done

echo "***** filter count tables to keep top $keep sequences........"
# generate the filtered tables containing top $keep sequences for ecah input
for i in ${Name[@]}
do
  ((n=n%P)); ((n++==0)) && wait
  echo "filter ${i}........"
  less $i.csv |head -n $num >$i.top$keep.csv &
done

wait


module unload cutadapt # we have to unload cutadapt since it is not compatible with r-dplyr, whcih is needed for the following steps. This is probably a problem with our local cluster only.

# merge all the tables into one integrated table
echo "***** generate the integrated table........"
echo "***** generate the integrated table........" >>R.log
if [[ ${#Name[@]} > 1 ]]
    then
        less ${Name[-1]}.csv |head -n $num >tmp.csv
        for (( i=${#Name[@]}-1; i>=0; i-- ))
        do 
          rev[${#rev[@]}]=${Name[i]}
        done
        echo "order samples in ${rev[@]}"
        for i in ${rev[@]:1:${#rev[@]}}
        do
          echo "integrate $i........"
          linux_call_R.sh ${HomeDir}/bin/Table_merge.R $WD $i.csv tmp.csv seq right tmp.csv 1>>R.log 2>>R.log
        done
        mv tmp.csv $Table.top$keep.csv
    else
        less ${Name[-1]}.csv |head -n $num >$Table.top$keep.csv    
    fi
    
# check whether integrated table is generated
if [ ! -s $Table.top$keep.csv ]
then
   echo "[Error] integrated table is missing or empty, check R.log and log for details."
   exit 1
fi

echo "generated $Table.top$keep.csv containing top $keep sequences for ${Input[@]}"

# generate reports for each input file 
# sample randomness (distribution of the occurance of each sequence) and ATCG distribution at each position
echo "***** generate reports........"
echo "***** generate reports........" >>R.log
for i in ${Name[@]}
do
  ((n=n%P)); ((n++==0)) && wait
  echo "generate randomness report for $i........"
  linux_call_R.sh ${HomeDir}/bin/sample_randomness.R $WD $i.csv 1>>R.log 2>>R.log &
  echo "generate ATGC distribution report for $i........"
  linux_call_R.sh ${HomeDir}/bin/sample_ATGC_distribution.R $WD $i.csv $Length 1>>R.log 2>>R.log &
done

wait

# count number of reads for each sample
echo "generate report for number of reads in each sample........"
echo "" > reads_number_report.csv
for i in ${!Input[@]}
do
  Lnum=$(less ${Input[i]}.trim.processed.combined.fastq | wc -l)
  Rnum=$(echo "$Lnum/4" | bc)
  echo "${Name[i]},$Rnum" >> reads_number_report.csv
done

# we used duplicate level indicates the randomness of each sample.
# we calculate the % of reads that are duplicated 1, 2, 3, 4, 5, 6, 7, 8, 9, 10-50, 50-100, 100-500, 500-1000, 1K-5K, 5K-10K, >10K times.
echo "generate integrated randomness report........"
echo "generate integrated randomness report........" >>R.log
linux_call_R.sh ${HomeDir}/bin/randomness.R $WD ${Name[@]} 1>>R.log 2>>R.log

# time to end the analysis
Finish=$(date +%s.%N)
# execution time
dur=$(echo "$Finish - $start" | bc)
echo "********************************************************************************************"
echo "*                                   analysis finished                                      *"
echo "********************************************************************************************"
echo "analysis started at $start, ended at $Finish"
echo "Excution time $dur"

