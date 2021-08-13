install.packages("foreach")
install.packages("doParallel")
install.packages("tidyverse")
install.packages("data.table")
install.packages("sf")
install.packages("dplyr")

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


folderRaw <- "C:/Users/PC/Desktop/seoul_elect_map_data/11000"    
#마지막에 슬래시를 붙이지 않는다.
#마지막에 슬래시를 넣는다.
src_folders <- list.dirs(folderRaw, recursive = TRUE) # list
loopSize <- length(src_folders)

result <- foreach::foreach(index = 1:loopSize,
                           .combine = rbind)  %dopar% {
                             
                             library(sf)              
                             library(data.table)  
                             library(dplyr)                 
                             
                             fileName <- paste0(src_folders[index],"/TL_SPBD_BULD.shp")
                             print(paste0("read.....",fileName))
                             
                             bldg <- fileName %>% read_sf() #파일을 읽는다.
                             print(bldg)
                             bldgCoord <- as.data.table(st_coordinates(bldg)) #좌표들만 추출해서 table에 담는다.
                             
                             #250m 격자에 할당한다.
                             gridTrue <- bldgCoord %>% mutate( xx = as.integer(X/100), yy = as.integer(Y/100) ) %>%
                               distinct( gridx = xx, gridy = yy)           
                             return(gridTrue)
                           }
# 클러스터 중지

folderWrite <- "C:/Users/PC/Desktop/work/"

parallel::stopCluster(myCluster)
eTime <- Sys.time()
print((eTime - sTime)*60)
rm(sTime)
rm(eTime)
uniqueGrid <- result %>%  distinct( gridx,gridy) %>%
  mutate( x = gridx*100, y = gridy*100)
fwrite(uniqueGrid, file=paste0(folderWrite,"bldgGrid_parallel.tsv"),
       quote=FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

rm(result)
rm(myCluster)
rm(loopSize)
rm(numCores)
rm(src_folders)
rm(folderRaw)
rm(uniqueGrid)
rm(folderWrite)

install.packages("Rcpp")
folderWrite <- "C:/Users/PC/Desktop/work/" 

library(Rcpp)
library(sf)
library(data.table)

sourceCpp("C:/Users/PC/Desktop/distributeValueToGrid_100m.cpp")

bldgGrid <- fread(paste0(folderWrite,"bldgGrid_parallel.tsv"),
                  sep = "\t", header = TRUE, stringsAsFactors = FALSE)

bldgGridToSet(as.integer(bldgGrid$gridx), as.integer(bldgGrid$gridy))
rm(bldgGrid)

#============================================================


folderAdm <- "C:/Users/PC/Desktop/pixel_allocate_data/stat_boundary/"
fileName <- paste0(folderAdm,"bnd_oa_11_2020_2020_2Q.shp")

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

print(admCD)
folderPopu <- "C:/Users/PC/Desktop/pixel_allocate_data/stat_boundary_pfh/"
fileName <- paste0(folderPopu, "11_2019년_성연령별인구.txt")
popuGrid50 <- distributePopulation(fileName, admCD)

print(admCD)
print(popuGrid50)
fwrite(popuGrid50, file=paste0(folderWrite,"resultDistributed_20m_2000.tsv"),
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

install.packages("rmapshaper")
library(rmapshaper)


fileName <- paste0(folderAdm,"bnd_sigungu_00_2020_2020_2Q.shp")
system.time( sggBndry <- fileName %>% read_sf())
#맵 단순화. 그리드 중 특정 시군구 소속 경계를 추출하기 위함이므로 적당히 단순화시킨다.
#약 1분 가까이 걸린다.

system.time(sggSimple <- sggBndry %>% ms_simplify())
#정상적으로 읽고 변환되었는지 확인

ggplot() + geom_sf(data = sggSimple) 
sggcoord <- sggSimple %>% st_coordinates() 
sggcoord <- as.data.frame(sggcoord) 
sggCode <- data.frame(as.integer(rownames(sggBndry)), sggSimple$SIGUNGU_CD, sggSimple$SIGUNGU_NM) 
colnames(sggCode) <- c("index", "sggcode", "sggname") 

sggcoord <- sggcoord %>% left_join(sggCode, by=c("L3"="index")) 
rm(sggBndry)



extractSggGrid <- function(popuGridData, sggCode, sggcoordData) {
  
  sggcoordExtracted <- sggcoordData %>% filter(sggcode==sggCode)
  
  popuGridFiltered <- filteringSggGrid(popuGridData$x, popuGridData$y,
                                       popuGridData$value, sggcoordExtracted$X,
                                       sggcoordExtracted$Y,sggcoordExtracted$L1,
                                       sggcoordExtracted$L2,sggcoordExtracted$L3)   
  return (popuGridFiltered)
  
}

popuShp <- st_as_sf(popuGrid100, coords = c("x", "y"), crs = 5179) 
st_write(popuShp, paste0(folderWrite,"popu100.shp"), driver="ESRI Shapefile")


