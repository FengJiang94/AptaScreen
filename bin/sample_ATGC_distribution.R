# get the command line args
# Args[1] specifics the working directory
# Args[2] specifics the input file, colomn separate by ','
# Args[3] specifics the length iof each sequence
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")
paste("report ATGC frequency for ", Args[2], sep = " ")
paste("sequence length set to ", Args[3], sep = " ")
len <- Args[3]
# set library path
path <- .libPaths()
print(paste("R package library:", path, sep = ""))
#.libPaths(c("/scratch/fjiang7/Rlib", path))

# load required libraries
library(pillar)
library(dplyr)
library(data.table)
library(tidyr)

# To calculate the A, T, G, C occurance at each position, 
# we read the input file line by line (to avoid exceeding RAM limitation)
inputFile <- Args[2]
con  <- file(inputFile, open = "r")
# Skip the first line single it is the names not sequence.
firstLine <- readLines(con, n = 1)
# create 4 empty vectors to store the A, T, G, C occurance
A_ <- c(rep(0,len))
T_ <- c(rep(0,len))
G_ <- c(rep(0,len))
C_ <- c(rep(0,len))
# A loop to calculate the number of A, T, G,C at each position of the sequence line by line 
while (length(oneLine <- readLines(con, n = 1)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  # sequence information
  seq <- unlist(strsplit(myLine[1], split = ""))
  # occurance of the sequence
  freq <- myLine[2]
  # A loop to calculate the number of A, T, G,C at each position for one line
  for (i in 1:len){
    if (seq[i] == "A"){
      A_[i] = as.numeric(A_[i])+as.numeric(freq) 
    } else if (seq[i] == "T"){
      T_[i] = as.numeric(T_[i])+as.numeric(freq)
    }else if (seq[i] == "G"){
      G_[i] = as.numeric(G_[i])+as.numeric(freq)
    }else if (seq[i] == "C"){
      C_[i] = as.numeric(C_[i])+as.numeric(freq)
    }
  }
}
close(con)

# save output data
output <- data.table("A"=A_, 
                     "T"=T_, 
                     "G"=G_, 
                     "C"=C_)
write.csv(output, paste(Args[2], ".ATGCdistribution.csv", sep = ""), row.names = F)




