#Reference: https://www.vw-lab.com/85
#           https://github.com/vuski/populationDistribution

# install.packages("foreach")
# install.packages("doParallel")
# install.packages("tidyverse")
# install.packages("data.table")
# install.packages("reshape2")
# install.packages("scales")

library(foreach) 
library(doParallel) 
library(tidyverse) 
library(data.table) 
library(reshape2)
library(scales)
library(Rcpp)
library(sf)

######### 병렬 처리 ########## 
# 코어 개수 획득 
numCores <- parallel::detectCores() - 1 

# 클러스터 초기화 
myCluster <- parallel::makeCluster(numCores) 
doParallel::registerDoParallel(myCluster)

folderRaw <- "./shp" #마지막에 슬래시를 붙이지 않는다. 
folderWrite <- "./getGridWork/" #마지막에 슬래시를 넣는다.
src_folders <- list.dirs(folderRaw, recursive = FALSE) # list

loopSize <- length(src_folders)

result <- foreach::foreach(index = 1:loopSize, .combine = rbind) %dopar% { 
    library(sf) 
    library(data.table) 
    library(dplyr) 
    fileName <- paste0(src_folders[index],"/TL_SPBD_BULD.shp") 
    print(paste0("read.....",fileName)) 
    bldg <- fileName %>% read_sf() #파일을 읽는다. 
    bldgCoord <- as.data.table(st_coordinates(bldg)) #좌표들만 추출해서 table에 담는다. 
    
    #250m 격자에 할당한다. 
    gridTrue <- bldgCoord %>% mutate( xx = as.integer(X/250), yy = as.integer(Y/250) ) %>% distinct( gridx = xx, gridy = yy) 
    return(gridTrue) 
    }

parallel::stopCluster(myCluster)

uniqueGrid <- result %>% distinct( gridx,gridy) %>% mutate( x = gridx*250, y = gridy*250)

fwrite(uniqueGrid, file=paste0(folderWrite,"bldgGrid_parallel.tsv"), quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)


rm(result) 
rm(myCluster) 
rm(loopSize) 
rm(numCores) 
rm(src_folders) 
rm(folderRaw) 
rm(uniqueGrid) 
rm(folderWrite)