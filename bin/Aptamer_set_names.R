# get the command line args
# Args[1] specifics the working directory
# Args[2] specifics the file name of the integrated table to save
# Args[3:] specifics the names of input files to display in the table
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")

# create colnames for the integrated table
colname <- c('seq')
for(i in c(3:length(Args)))
{
  name <- c(paste(Args[i],"_read", sep=""), paste(Args[i],"_RPM", sep=""))
  colname <- c(colname, name)
  paste("use name ",Args[i], sep = "")
}

# read the intergrated table
tmp <- read.csv("tmp.csv", header = T, row.names = 1)

# set the colnames to the new names
colnames(tmp) <- colname

# save the data
write.csv(tmp, paste(Args[2], ".csv", sep = ""))


