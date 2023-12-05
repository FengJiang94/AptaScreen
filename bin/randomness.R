# get the command line args
# Args[1] specifics the working directory
# Args[2:] specifics the input files (randomness files) ','
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")
paste("process", Args[2:length(Args)], ".csv.randomness.csv", sep = " ")

# set library path
path <- .libPaths()
print(paste("R package library:", path, sep = ""))
#.libPaths(c("/scratch/fjiang7/Rlib", path))

# load required libraries
library(pillar, quietly = T)
library(dplyr, quietly = T)
library(data.table, quietly = T)
library(ggplot2, quietly = T)
# a tmp function to calcualte the duplicate level of each sample
# duplicate level indicates the randomness of each sample.
# we calculate the % of reads that are duplicated 1, 2, 3, 4, 5, 6, 7, 8, 9, 10-50, 50-100, 100-500, 500-1000
# 1K-5K, 5K-10K, >10K times.
tmp_function <- function(filename){
  dt0 <- fread(filename, header = T)
  dt0$`#seq` <- dt0$`#seq` * dt0$occurance
  dt0$per <- dt0$`#seq`/sum(dt0$`#seq`)
  s1 <- sum(dt0[(dt0$occurance >= 10 & dt0$occurance < 50),]$per)
  s2 <- sum(dt0[(dt0$occurance >= 50 & dt0$occurance < 100),]$per)
  s3 <- sum(dt0[(dt0$occurance >= 100 & dt0$occurance < 500),]$per)
  s4 <- sum(dt0[(dt0$occurance >= 500 & dt0$occurance < 1000),]$per)
  s5 <- sum(dt0[(dt0$occurance >= 1000 & dt0$occurance < 5000),]$per)
  s6 <- sum(dt0[(dt0$occurance >= 5000 & dt0$occurance < 10000),]$per)
  s7 <- sum(dt0[(dt0$occurance >= 10000),]$per)
  R0 = c(dt0[c(1:9), ]$per,s1, s2, s3,s4,s5,s6,s7)
  R0[is.na(R0)] <- 0
  return(R0)
}


# create an empty table to store the duplicate level information
df <- data.table("duplicate_level" = 
                   factor(c(seq(1,9,1), "10-50", "50-100", "100-500", "500-1K", "1-5K", "5-10K", ">10K"),
                          levels = c(seq(1,9,1), "10-50", "50-100", "100-500", "500-1K", "1-5K", "5-10K", ">10K")))
# calculate the duplicate level for each sample                
for (i in 2:length(Args))
{
  assign(Args[i], data.table(tmp_function(paste(Args[i], ".csv.randomness.csv", sep = ""))))
  df <- cbind(df, get(Args[i]))
}
colnames(df) <- c("duplicate_level", Args[2:length(Args)])

# save the dataset with duplicate level of each sample
write.csv(df, "Randomness.csv", row.names = F)

# Plot the duplicate level to show the randomness of each sample
df <- read.table("Randomness.csv", header = T, sep = ",")

library(reshape2)
dt <- melt(df)
pdf(file = "Randomness.pdf", height = 8, width = 12)
ggplot(dt, aes(x=duplicate_level, y=value, group = variable, color = variable)) +
  geom_line() +
  theme_bw() +
  ylab(" % of total reads") +
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        axis.title = element_text(size = 20), 
        axis.title.y = element_text(angle = 90, vjust = 0.5), 
        axis.text.y = element_text(size = 10),
        axis.text.x = element_text(size = 10,),
        legend.text = element_text(size = 20),
        legend.title = element_text(colour = "transparent"))
dev.off()

## barplot of sample duplicated level
nums <- ncol(df)
df1 <- colSums(df[1,c(2:nums)])
df10 <- colSums(df[c(2:9),c(2:nums)])
df100 <-colSums(df[c(10:11),c(2:nums)])
df1000 <- colSums(df[c(12:13),c(2:nums)])
df10000 <-colSums(df[c(14:16),c(2:nums)])
df <- rbind(df1,df10, df100, df1000, df10000)
df <- as.data.frame(df)
# total number of reads ineach sample
Readnum <- read.table("reads_number_report.csv", header = F, sep = ",")
Readnum <- as.data.frame(Readnum)
# percentage * #total reads = #reads
for (i in c(1:ncol(df)))
{
  df[,i] <- df[,i]*Readnum[Readnum$V1 == colnames(df)[i],]$V2
}
df$duplicated_level <- c("unique", "2-9", "10-100", "100-1000", ">1000")
write.csv(df, "Randomness_barplot.csv", row.names = F)

# plot
df <- read.table("Randomness_barplot.csv", header = T, sep = ",")

pdf(file = "Randomness_barplot.pdf", height = 12, width = 12)
m <- melt(df)
ggplot(m, aes(x=variable, y=value, group = duplicated_level, fill = duplicated_level)) +
  geom_bar(stat="identity") +
  theme_bw() +
  ylab(" number of reads") +
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        axis.title = element_text(size = 20), 
        axis.title.y = element_text(angle = 90, vjust = 0.5), 
        axis.text.y = element_text(size = 10),
        axis.text.x = element_text(size = 10,),
        legend.text = element_text(size = 20),
        legend.title = element_text(colour = "transparent"))
dev.off()

