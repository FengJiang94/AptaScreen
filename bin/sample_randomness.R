# get the command line args
# Args[1] specifics the working directory
# Args[2] specifics the input file, colomn separate by ','
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")
paste("report randomness for ", Args[2], sep = " ")

# set library path
path <- .libPaths()
print(paste("R package library:", path, sep = ""))
#.libPaths(c("/scratch/fjiang7/Rlib", path))

# load required libraries
library(pillar)
library(dplyr)
library(data.table)
library(tidyr)

# read the input files 
dt1 <- fread(Args[2], sep = ",", header = T)

# get the distribution of the occurance of each sequence
R <- as.data.table(table(dt1[,2]))
colnames(R) <- c("occurance", "#seq")
# save the merged data
write.csv(R, paste(Args[2], ".randomness.csv", sep = ""), row.names = F)
