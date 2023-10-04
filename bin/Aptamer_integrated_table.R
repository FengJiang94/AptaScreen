
# function to get the fastaptmer_count output fasta to a table
data_final_function <- function(filename)
{
  # input the fastq file
  data <- read.csv(filename, header = F)
  # get seq information
  seq <- data$V1[seq(from = 2, to = length(data$V1), by = 2)]
  # get #reads and RPM (reads per million reads)
  rank_read_RPM <- data$V1[seq(from = 1, to = length(data$V1), by = 2)]
  read <- c()
  RPM <- c()
  for (i in c(1:length(rank_read_RPM))) 
  {
    read[i] <- unlist(strsplit(rank_read_RPM[i], split = "-"))[2]
    RPM[i] <- unlist(strsplit(rank_read_RPM[i], split = "-"))[3]
  }
  # store data in data frame
  data_final <- data.frame("seq" = seq,
                           "read" = read,
                           "RPM" = RPM)
  return(data_final)
}


# get the command line args
# Args[1] specifics the working directory
# Args[2:] specifics the input files
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")
paste("process", length(Args)-3, "fasta files", sep = " ")

### set up R parameters
# Muuliticores
library(doParallel)
# Find out how many cores are available (if you don't already know)
# Core processes. Here we leave 2 cores that are not used by R
cl <- makeCluster(Args[2]-2)
# Register cluster
registerDoParallel(cl)
# Find out how many cores are available for mclapply
# RIPSeeker uses parallel::mclapply for muliticores
#mc.cores = getOption("mc.cores", 2L)
# set mc.cores
#options(mc.cores = 4)
#mc.cores = getOption("mc.cores", 2L)
#mc.cores

# Maximum rm
library(future)
options(future.globals.maxSize = Args[3] * 1024^2)


# convert the first fastaptmer_count output fasta to table
table_1 <- data_final_function(paste(Args[4],'.trim.processed.combined.count.fasta', sep = ""))
colnames(table_1) <- c("seq", paste(Args[4],"_read", sep=""), paste(Args[4],"_RPM", sep=""))

# if there is only one fastaptmer_count output fasta
if (length(Args) == 4)
{
  # save the result to a tmp table
  write.csv(table1, file = "tmp.csv")
}else
  {
  M <- table_1
  # loop through all the fastaptmer_count output fasta
  for (i in c(5:length(Args)))
  {
    # convert fasta to table
    table_tmp <- data_final_function(paste(Args[i],'.trim.processed.combined.count.fasta', sep = ""))
    colnames(table_tmp) <- c("seq", paste(Args[i],"_read", sep=""), paste(Args[i],"_RPM", sep=""))
    # merge the tables into one
    M <- merge(M, table_tmp, by = "seq", all = T)
    M[is.na(M)] <- 0
  }
  # save the output file
  write.csv(M, file = "tmp.csv")
}

