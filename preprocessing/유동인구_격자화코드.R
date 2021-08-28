install.packages("foreach")
install.packages("doParallel")
install.packages("tidyverse")
install.packages("data.table")
install.packages("sf")
install.packages("dplyr")
install.packages("Rcpp")
install.packages("rmapshaper")


library(foreach) 
library(doParallel) 
library(tidyverse) 
library(data.table)


######### 병렬 처리 ########## 
# 코어 개수 획득 
numCores <- parallel::detectCores() - 1 

# 클러스터 초기화 


myCluster <- parallel::makeCluster(numCores) 

doParallel::registerDoParallel(myCluster)

folderRaw  <- dirname(rstudioapi::getActiveDocumentContext()$path)
folderRaw  <- paste0(folderRaw, "/move_data")
print(folderRaw)

#마지막에 슬래시를 붙이지 않는다.
#마지막에 슬래시를 넣는다.
src_folders <- list.dirs(folderRaw, recursive = TRUE) # list
loopSize <- length(src_folders)

result <- foreach::foreach(index = 1:loopSize,
                           .combine = rbind)  %dopar% {
                             
                             library(sf)              
                             library(data.table)  
                             library(dplyr)                 
                             
                             fileName <- paste0(src_folders[index],"/Z_NGII_N3L_A0033320.shp")
                             print(paste0("read.....",fileName))
                             
                             bldg <- fileName %>% read_sf() #파일을 읽는다.
                             print(bldg)
                             bldgCoord <- as.data.table(st_coordinates(bldg)) #좌표들만 추출해서 table에 담는다.
                             
                             gridTrue <- bldgCoord %>% mutate( xx = as.integer(X/100), yy = as.integer(Y/100) ) %>%
                               distinct( gridx = xx, gridy = yy)           
                             return(gridTrue)
                           }
# 클러스터 중지

folderWrite <- dirname(rstudioapi::getActiveDocumentContext()$path)
folderWrite  <- paste0(folderWrite, "/move_data")

parallel::stopCluster(myCluster)

uniqueGrid <- result %>%  distinct( gridx,gridy) %>%
  mutate( x = gridx*100, y = gridy*100)
fwrite(uniqueGrid, file=paste0(folderWrite,"/bldgGrid_parallel.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

rm(result)
rm(myCluster)
rm(loopSize)
rm(numCores)
rm(src_folders)
rm(folderRaw)
rm(uniqueGrid)
rm(folderWrite)

folderWrite <- dirname(rstudioapi::getActiveDocumentContext()$path)
folderWrite  <- paste0(folderWrite, "/move_data")

library(Rcpp)
library(sf)
library(data.table)

cpp_file <- dirname(rstudioapi::getActiveDocumentContext()$path)
cpp_file  <- paste0(cpp_file, "/distributeValueToGrid_100m.cpp")

print(cpp_file)


sourceCpp(cpp_file)

bldgGrid <- fread(paste0(folderWrite,"/bldgGrid_parallel.tsv"),
                  sep = "\t", header = TRUE, stringsAsFactors = FALSE)

bldgGridToSet(as.integer(bldgGrid$gridx), as.integer(bldgGrid$gridy))
rm(bldgGrid)




#============================================================


folderAdm <- dirname(rstudioapi::getActiveDocumentContext()$path)

fileName <- paste0(folderAdm,"/common_file/bnd_oa_11_2020_2020_2Q.shp")
print(fileName)
system.time( admBndry <- fileName %>% read_sf())
print(admBndry)
admCD <- as.data.frame(admBndry$TOT_REG_CD)
print(admCD)
colnames(admCD) <- c("TOT_REG_CD")

admcoord <- admBndry %>% st_coordinates
print(admcoord)
putAdmBoundary(admcoord[,1], admcoord[,2],
               as.integer(admcoord[,3]), as.integer(admcoord[,4]),
               as.integer(admcoord[,5]))
rm(admcoord)
rm(admBndry)



distributePopulation <- function(fileName, admCD_) {
  # 통계청 집계구별 인구를 읽는다.
  system.time(popu <- fread(fileName,
                            sep = "^", header = TRUE, stringsAsFactors = FALSE,
                            colClasses = c('integer', 'character','character','character')))
  
  #집계구별 총 인구를 계산한다.
  #집계구별 인구 중 1~4인은 NA로 처리되어 있으므로 NA대신 2.5를 입력한다.
  popu <- popu %>% mutate(code = as.integer(substr(item,8, length(item)))) %>% 
    filter(code<=21 | code == 999) %>% #21까지가 남녀인구 999는 자료없는 집계구 
    mutate(popu = replace_na(as.numeric(value), 2.5)) %>% 
    group_by(tot_oa_cd) %>% 
    summarise(.groups="keep", popu = sum(popu)) %>% 
    ungroup()
    

  #집계 확인
  print(paste0("인구 집계(파일 총계) :",sum(popu$popu)))
  
  #Rcpp 변수에 입력한다. 집계구 polygon의 일련번호와 일치하는 인구다.
  #뒤에서 그리드에 할당할 때 사용한다.
  admJoined <- admCD_ %>% left_join(., popu,
                                    by=c("TOT_REG_CD"="tot_oa_cd"))
  putAdmPopu(admJoined$popu)
  rm(admJoined)
  rm(popu)
  
  
  numCores <- parallel::detectCores()-1
  result <- distributeValue(numCores)
  
  print(paste0("인구 집계(파일 총계) :",sum(result$value)))
  
  return(result)
}


library(foreach) 
library(doParallel) 
library(tidyverse) 
library(data.table)

#=================================================================================

folderPopu <- dirname(rstudioapi::getActiveDocumentContext()$path)
fileName2 <- paste0(folderPopu, "/move_data/2019_move_6.txt")
popuGrid50 <- distributePopulation(fileName2, admCD)
popuGrid50<-popuGrid50 %>% mutate(value = replace_na(as.numeric(value), 0))
popuGrid50<-popuGrid50[-4]

fwrite(popuGrid50, file=paste0(folderWrite,"/resultDistributed_20m_2000.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

aggregatePopuGrid <- function(gridPopu, fromGrid, toGrid) {
  
  if (fromGrid >= toGrid) {
    print("그리드 설정 오류")
    return(NULL)
  }
  
  temp <- gridPopu %>% mutate(x = as.integer(as.integer(x/toGrid)*toGrid) + (toGrid/2) ,
                              y = as.integer(as.integer(y/toGrid)*toGrid) + (toGrid/2)) %>%
    group_by(x,y) %>%
    summarise(.groups="keep", value = sum(value)) %>%
    ungroup()
  
  return(temp)
  
}

system.time(popuGrid100 <- aggregatePopuGrid(popuGrid50, 50, 100))
sum(popuGrid100$value)
system.time(popuGrid250 <- aggregatePopuGrid(popuGrid50, 50, 250))
sum(popuGrid250$value)


library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")




extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
folderWrite = paste0(folderPopu, "/output_file")

st_write(popuShp, paste0(folderWrite,"/move_popu_100_6.shp"), driver="ESRI Shapefile")


#======================================================================================

folderPopu <- dirname(rstudioapi::getActiveDocumentContext()$path)
fileName2 <- paste0(folderPopu, "/move_data/2019_move_9.txt")
popuGrid50 <- distributePopulation(fileName2, admCD)
popuGrid50<-popuGrid50 %>% mutate(value = replace_na(as.numeric(value), 0))
popuGrid50<-popuGrid50[-4]

fwrite(popuGrid50, file=paste0(folderWrite,"/resultDistributed_20m_2000.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

aggregatePopuGrid <- function(gridPopu, fromGrid, toGrid) {
  
  if (fromGrid >= toGrid) {
    print("그리드 설정 오류")
    return(NULL)
  }
  
  temp <- gridPopu %>% mutate(x = as.integer(as.integer(x/toGrid)*toGrid) + (toGrid/2) ,
                              y = as.integer(as.integer(y/toGrid)*toGrid) + (toGrid/2)) %>%
    group_by(x,y) %>%
    summarise(.groups="keep", value = sum(value)) %>%
    ungroup()
  
  return(temp)
  
}

system.time(popuGrid100 <- aggregatePopuGrid(popuGrid50, 50, 100))
sum(popuGrid100$value)
system.time(popuGrid250 <- aggregatePopuGrid(popuGrid50, 50, 250))
sum(popuGrid250$value)


library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")




extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
st_write(popuShp, paste0(folderWrite,"/move_popu_100_9.shp"), driver="ESRI Shapefile")

#======================================================================================

folderPopu <- dirname(rstudioapi::getActiveDocumentContext()$path)
fileName2 <- paste0(folderPopu, "/move_data/2019_move_12.txt")
popuGrid50 <- distributePopulation(fileName2, admCD)
popuGrid50<-popuGrid50 %>% mutate(value = replace_na(as.numeric(value), 0))
popuGrid50<-popuGrid50[-4]

fwrite(popuGrid50, file=paste0(folderWrite,"/resultDistributed_20m_2000.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

aggregatePopuGrid <- function(gridPopu, fromGrid, toGrid) {
  
  if (fromGrid >= toGrid) {
    print("그리드 설정 오류")
    return(NULL)
  }
  
  temp <- gridPopu %>% mutate(x = as.integer(as.integer(x/toGrid)*toGrid) + (toGrid/2) ,
                              y = as.integer(as.integer(y/toGrid)*toGrid) + (toGrid/2)) %>%
    group_by(x,y) %>%
    summarise(.groups="keep", value = sum(value)) %>%
    ungroup()
  
  return(temp)
  
}

system.time(popuGrid100 <- aggregatePopuGrid(popuGrid50, 50, 100))
sum(popuGrid100$value)
system.time(popuGrid250 <- aggregatePopuGrid(popuGrid50, 50, 250))
sum(popuGrid250$value)


library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")




extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
st_write(popuShp, paste0(folderWrite,"/move_popu_100_12.shp"), driver="ESRI Shapefile")

#======================================================================================

folderPopu <- dirname(rstudioapi::getActiveDocumentContext()$path)
fileName2 <- paste0(folderPopu, "/move_data/2019_move_15.txt")
popuGrid50 <- distributePopulation(fileName2, admCD)
popuGrid50<-popuGrid50 %>% mutate(value = replace_na(as.numeric(value), 0))
popuGrid50<-popuGrid50[-4]

fwrite(popuGrid50, file=paste0(folderWrite,"/resultDistributed_20m_2000.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

aggregatePopuGrid <- function(gridPopu, fromGrid, toGrid) {
  
  if (fromGrid >= toGrid) {
    print("그리드 설정 오류")
    return(NULL)
  }
  
  temp <- gridPopu %>% mutate(x = as.integer(as.integer(x/toGrid)*toGrid) + (toGrid/2) ,
                              y = as.integer(as.integer(y/toGrid)*toGrid) + (toGrid/2)) %>%
    group_by(x,y) %>%
    summarise(.groups="keep", value = sum(value)) %>%
    ungroup()
  
  return(temp)
  
}

system.time(popuGrid100 <- aggregatePopuGrid(popuGrid50, 50, 100))
sum(popuGrid100$value)
system.time(popuGrid250 <- aggregatePopuGrid(popuGrid50, 50, 250))
sum(popuGrid250$value)


library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")




extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
st_write(popuShp, paste0(folderWrite,"/move_popu_100_15.shp"), driver="ESRI Shapefile")

#======================================================================================

folderPopu <- dirname(rstudioapi::getActiveDocumentContext()$path)
fileName2 <- paste0(folderPopu, "/move_data/2019_move_18.txt")
popuGrid50 <- distributePopulation(fileName2, admCD)
popuGrid50<-popuGrid50 %>% mutate(value = replace_na(as.numeric(value), 0))
popuGrid50<-popuGrid50[-4]

fwrite(popuGrid50, file=paste0(folderWrite,"/resultDistributed_20m_2000.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

aggregatePopuGrid <- function(gridPopu, fromGrid, toGrid) {
  
  if (fromGrid >= toGrid) {
    print("그리드 설정 오류")
    return(NULL)
  }
  
  temp <- gridPopu %>% mutate(x = as.integer(as.integer(x/toGrid)*toGrid) + (toGrid/2) ,
                              y = as.integer(as.integer(y/toGrid)*toGrid) + (toGrid/2)) %>%
    group_by(x,y) %>%
    summarise(.groups="keep", value = sum(value)) %>%
    ungroup()
  
  return(temp)
  
}

system.time(popuGrid100 <- aggregatePopuGrid(popuGrid50, 50, 100))
sum(popuGrid100$value)
system.time(popuGrid250 <- aggregatePopuGrid(popuGrid50, 50, 250))
sum(popuGrid250$value)


library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")




extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
st_write(popuShp, paste0(folderWrite,"/move_popu_100_18.shp"), driver="ESRI Shapefile")

#======================================================================================

folderPopu <- dirname(rstudioapi::getActiveDocumentContext()$path)
fileName2 <- paste0(folderPopu, "/move_data/2019_move_21.txt")
popuGrid50 <- distributePopulation(fileName2, admCD)
popuGrid50<-popuGrid50 %>% mutate(value = replace_na(as.numeric(value), 0))
popuGrid50<-popuGrid50[-4]

fwrite(popuGrid50, file=paste0(folderWrite,"/resultDistributed_20m_2000.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

aggregatePopuGrid <- function(gridPopu, fromGrid, toGrid) {
  
  if (fromGrid >= toGrid) {
    print("그리드 설정 오류")
    return(NULL)
  }
  
  temp <- gridPopu %>% mutate(x = as.integer(as.integer(x/toGrid)*toGrid) + (toGrid/2) ,
                              y = as.integer(as.integer(y/toGrid)*toGrid) + (toGrid/2)) %>%
    group_by(x,y) %>%
    summarise(.groups="keep", value = sum(value)) %>%
    ungroup()
  
  return(temp)
  
}

system.time(popuGrid100 <- aggregatePopuGrid(popuGrid50, 50, 100))
sum(popuGrid100$value)
system.time(popuGrid250 <- aggregatePopuGrid(popuGrid50, 50, 250))
sum(popuGrid250$value)


library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")




extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
st_write(popuShp, paste0(folderWrite,"/move_popu_100_21.shp"), driver="ESRI Shapefile")


