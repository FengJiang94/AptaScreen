# set library path
path <- .libPaths()
print(paste("R package library:", path, sep = ""))
# Add your own library path
#.libPaths(c("/scratch/fjiang7/Rlib", path))

# get the command line args
# Args[1] specifics the working directory
# Args[2] specifics the input files
# Args[3] specifics the name of the sample and output file
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")
paste("process", Args[2], sep = " ")
paste("set name to", Args[3], sep = " ")

# report number of workers available for R
library(parallel) # for using parallel::mclapply() and checking #totalCores on compute nodes / workstation: detectCores()
library(future) # for checking #availble cores / workers on compute nodes / workstation: availableWorkers() / availableCores() 
workers <- availableWorkers()
cat(sprintf("#workders/#availableCores/#totalCores: %d/%d/%d, workers:\n", length(workers), availableCores(), detectCores()))
print( workers )

# report ram usage for R
library(unix)
ram <- rlimit_as()
print(ram)



# read the input file line by line and write the output table line by line (to avoid exceeding RAM limitation)
inputFile <- paste(Args[2], ".trim.processed.combined.count.fasta", sep = "")
con  <- file(inputFile, open = "r")
# write the header (1st line) of the output table. This line store the column namesl
col1name <- "seq"
col2name <- paste(Args[3], "read", sep = "_")
col3name <- paste(Args[3], "RPM", sep = "_")
headerLine <- paste(col1name, col2name, col3name, sep = ",")
write(headerLine, paste(Args[3],".csv", sep = ""))
# A loop to write the following lines to the output table
while (length(oneLine <- readLines(con, n = 2)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  seq <- myLine[2]
  read <- unlist(strsplit(myLine[1], split = "-"))[2]
  RPM <- unlist(strsplit(myLine[1], split = "-"))[3]
  outputLine <- paste(seq, read, RPM, sep = ",")
  write(outputLine, paste(Args[3],".csv", sep = ""), append = T)
} 
close(con)
paste("process input file ", Args[2], " as table", Args[3], ".csv", sep = "")

### report ram usage for R
usage <- gc()
print(usage)
