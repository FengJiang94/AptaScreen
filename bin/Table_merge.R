# get the command line args
# Args[1] specifics the working directory
# Args[2] specifics the left file, colomn separate by ','
# Args[3] specifics the right file, colomn separate by ','
# Args[4] specifics the column to merge by  
# Args[5] specifics the way to merge (left, right, inner, full, semi, anti)
# Args[6] specifics the name of the merged file 
Args <- commandArgs(trailingOnly=TRUE)
# set up the working directory
setwd(Args[1])
paste("working directory set to ",Args[1], sep = "")
paste("merge", Args[2], Args[3], sep = " ")
paste("merge by", Args[4], sep = " ")

# set library path
path <- .libPaths()
print(paste("R package library:", path, sep = ""))
#.libPaths(c("/scratch/fjiang7/Rlib", path))

# load required libraries
library(pillar)
library(dplyr)
library(data.table)

# read the input files 
dt1 <- fread(Args[2], sep = ",", header = T)
dt2 <- fread(Args[3], sep = ",", header = T)

# if Args[5] is left do left join
if (Args[5] == "left"){
  M <- left_join(dt1, dt2, by = Args[4])
  M[is.na(M)] <- 0
# if Args[5] is right do left join
}else if (Args[5] == "right"){
  M <- right_join(dt1, dt2, by = Args[4])
  M[is.na(M)] <- 0
# if Args[5] is inner do inner join
}else if (Args[5] == "inner"){
  M <- inner_join(dt1, dt2, by = Args[4])
  M[is.na(M)] <- 0
# if Args[5] is full do full join
}else if (Args[5] == "full"){
  M <- full_join(dt1, dt2, by = Args[4])
  M[is.na(M)] <- 0
# if Args[5] is semi do semi join
}else if (Args[5] == "semi"){
  M <- semi_join(dt1, dt2, by = Args[4])
  M[is.na(M)] <- 0
# if Args[5] is anti do anti join
}else if (Args[5] == "anti"){
  M <- anti_join(dt1, dt2, by = Args[4])
  M[is.na(M)] <- 0
}

# save the merged data
write.csv(M, Args[6], row.names = F)









