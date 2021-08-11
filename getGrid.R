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

folderRaw <- "D:/건물 SHAPE 파일 경로" #마지막에 슬래시를 붙이지 않는다.

sourceCpp("distributeValueToGrid.cpp")

list.dirs(".", recursive = FALSE)
length(list.dirs(".", recursive = FALSE))

출처: https://www.vw-lab.com/85 [VW LAB]