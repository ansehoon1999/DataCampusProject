
# 📮 자원순환기기 입지 분석 - '수퍼루키조😎'

## 📃 Brief Description
<br>

- dataset: 데이터 분석에 필요한 데이터 셋이 있는 폴더
- npy_file: 'process_1_coverage.ipynb' 실행 시 결과가 저장되는 폴더
- preprocessing 폴더: 유동인구, 거주인구, 1인가구, 배달인구 변수들을 전처리하는 폴더
- process_1_coverage.ipynb : 공원, 역, 버스정류소 등의 변수을 전처리하는 파일
- process_2_regression_anaylsis_mclp.ipynb: 회귀 및 mclp을 통한 결과를 보여주는 파일

<br><br>

## 🗂 활용 데이터셋 간략 설명

| num | 파일명 | 설명 | 출처 | 처리 | url |
| --- | ------ | ---- | ---- | ---- | --- |
|  1  | 네프론.csv | 서울시 네프론 설치 위치 | 슈퍼빈 | 구글api를 통한 좌표 획득 | [LINK](http://superbin.co.kr/new/contents/location_list.php) |
|  2  | WeBin.csv | 서울시 위빈 설치 위치 | 오늘의 분리수거 | 구글api를 통한 좌표 획득 | [LINK](https://oysterable.com/) |
|  3  | Sssaem.csv | 서울시 쓰샘 설치 위치 | 이노버스 | 구글api를 통한 좌표 획득 | [LINK](https://www.inobus.co.kr/) |
|  4  | 역+위도경도.xlsx | 수도권 전철 역 좌표 | 서울열린데이터광장 | 구글api를 통한 좌표 획득 | [LINK](http://data.seoul.go.kr/dataList/OA-15442/S/1/datasetView.do) |
|  5  | 서울시버스정류소좌표데이터(2021.01.14.).csv | 서울시 버스 정류소 좌표 | 서울열린데이터광장 | - | [LINK](http://data.seoul.go.kr/dataList/OA-15067/S/1/datasetView.do) | 
|  6  | 서울시 주요 공원현황.csv | 서울시 주요 공원 위치 | 서울열린데이터광장 | - | [LINK](http://data.seoul.go.kr/dataList/OA-394/S/1/datasetView.do;jsessionid=51E489E9D1FA1446F6ACD3F4CE9FB1A8.new_portal-svr-21) |
|  7  | BULD_공공시설.csv | 서울시 공공시설 위치 | 도로명주소 안내시스템 | QGIS를 통한 좌표 획득 | [LINK](https://www.juso.go.kr/) |
|  8  | TL_SPBD_BULD.shp | 서울시 건물 위치 | 도로명주소전자지도 | - | [LINK](https://www.juso.go.kr/addrlink/devLayerRequestWrite.do) |
|  9  | TL_SPBD_BULD_거주지.shp | 서울시 건물 위치 | 도로명주소전자지도 | QGIS를 통한 거주지 추출 | [LINK](https://www.juso.go.kr/addrlink/devLayerRequestWrite.do) |
|  10  |Z_NGII_N3L_A0033320.shp | 전국 보도 위치 | 국토지리정보원 | - | [LINK](http://data.nsdi.go.kr/dataset/20180927ds0063) |
|  11  | bnd_sigungu_00_2020_2020_2Q.shp, bnd_oa_11_2020_2020_2Q  | 서울시 집계구 경계 | 통계지리서비스 | - | [LINK](http://sgis.kostat.go.kr) |
|  12  |11_2019년_성연령별인구.txt | 서울시 집계구 별 연령별 인구 | 국토지리정보원 | - | [LINK](http://data.nsdi.go.kr/dataset/20180927ds0063) |
|  13  |2019년_1인가구.txt | 서울시 집계구 별 1인 가구 수 | 국토지리정보원 | - | [LINK](http://data.nsdi.go.kr/dataset/20180927ds0063) |

<br><br>

## 🔗 데이터 전처리

✨ 오래걸리는 것을 대비해서 output_file에 결과 파일들을 모두 첨부했습니다. 만약에 실제로 돌려보고 싶다면 output_file 내에 있는 파일들을 모두 삭제하고 돌려주세요

### 1️⃣ 유동 인구

#### 1) 데이터 전처리

- result 폴더에서 'move_data_preprocessing.ipynb' 파일 실행 (약 20분 소요)
- 끝까지 실행시키면 move_data 에 총 6개의 txt 파일 생성 
<br><br>(오래걸리는 것을 대비해서 move_data에 파일 실행 결과 txt 파일 사전 첨부)

#### 2) 유동인구 데이터 격자화

- 이후에 '유동인구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 'move_popu_100_n.shp' 외 3개의 파일이 생성됩니다. (n은 6~21시까지 3시간 간격의 숫자) 
<br><br> 


| 인도(보도) 위치 추출 | 100x100 격자화 | 격자에 유동인구 할당 |
| --- | ---- | --- |
|![image](https://user-images.githubusercontent.com/63048392/131242381-aa53d744-edd3-4cce-bf59-798734f2928a.png)|![image](https://user-images.githubusercontent.com/63048392/131242384-7bfcf686-a9b6-4840-b46a-57cf42bf5e39.png)|![image](https://user-images.githubusercontent.com/63048392/131242387-bff062b7-ce83-48a8-9bd9-bb71ab6f1ec5.png)|

<br><br> 

### 2️⃣ 배달 인구

#### 1) 데이터 전처리

- result 폴더에서 'delivery_data_preprocessing.ipynb' 파일 실행
- 끝까지 실행시키면 del_data 에 총 6개의 txt 파일 생성 
<br><br>(오래걸리는 것을 대비해서 del_data에 파일 실행 결과 txt 파일 사전 첨부)

#### 2) 배달인구 데이터 격자화

- 이후에 '배달인구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 'del_popu_100_n.shp' 외 3개의 파일이 생성됩니다. (n은 10대부터 60대까지 3시간 간격의 숫자) 
<br><br> 


| 건물 위치 추출 | 100x100 격자화 | 격자에 배달인구 할당 |
| --- | ---- | --- |
|![image](https://user-images.githubusercontent.com/63048392/131242434-9f45e2e6-dbf1-44ac-9275-2d1870274d88.png)|![image](https://user-images.githubusercontent.com/63048392/131242436-59ba5c45-7804-4d3d-98c6-ef068595bdbf.png)|![image](https://user-images.githubusercontent.com/63048392/131242442-60177154-a369-49fd-b379-211dedc69a16.png)|

<br><br>

### 3️⃣ 거주 인구

#### 1) 거주인구 데이터 격자화

- 이후에 '거주인구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 'live_popu_100.shp' 외 3개의 파일이 생성됩니다. 
<br><br>(오래걸리는 것을 대비해서 live_data에 파일 실행 결과 txt 파일 사전 첨부)
<br><br> 


| 거주지 위치 추출 | 100x100 격자화 | 격자에 거주인구 할당 |
| --- | ---- | --- |
|![image](https://user-images.githubusercontent.com/63048392/131242510-3555133c-b1a9-4a2d-b32b-0a49c42415eb.png)|![image](https://user-images.githubusercontent.com/63048392/131242512-a2fbd951-3fbb-433e-9328-342f7b462011.png)|![image](https://user-images.githubusercontent.com/63048392/131242516-a9215a16-e289-4b9c-9665-7c273b9d0f7c.png)|

<br><br>
### 4️⃣ 1인 가구

#### 1) 1인 가구 데이터 격자화

- 이후에 '1인가구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 '1live_popu_100.shp' 외 3개의 파일이 생성됩니다. 
<br><br>(오래걸리는 것을 대비해서 1family_data에 파일 실행 결과 txt 파일 사전 첨부)
<br><br> 


| 거주지 위치 추출 | 100x100 격자화 | 격자에 1인가구 할당 |
| --- | ---- | --- |
|![image](https://user-images.githubusercontent.com/63048392/131242510-3555133c-b1a9-4a2d-b32b-0a49c42415eb.png)|![image](https://user-images.githubusercontent.com/63048392/131242512-a2fbd951-3fbb-433e-9328-342f7b462011.png)|![image](https://user-images.githubusercontent.com/63048392/131242684-ab3c6607-8843-44d5-ab1d-c6446964e893.png)|

<br><br>
### 5️⃣ 지하철, 버스정류소, AI 재활용 로봇

#### 1) 격자마다 시설 커버받고 있는 시설의 수 할당

- 지구는 둥근 구 형태이기 때문에, 단순 직선 거리를 구한 것이 두 지점간의 정확한 거리라고 하기에는 조금 아쉽다.
- 이를 보완하기 위해 하버사인 공식을 활용한다.

  📌 각종 시설들의 경우는 300m 이하<br>
  📌 회수 기기들의 경우는 500m 이하

- 에 해당하는 경우에 시설 또는 기기가 해당 격자를 커버하고 있다고 설정하여 할당한다.

![하버사인공식_위키피디아](https://upload.wikimedia.org/wikipedia/commons/3/38/Law-of-haversines.svg)
<br>
https://en.wikipedia.org/wiki/Haversine_formula
<br>
- 'process_1_coverage.ipynb' 파일 실행합니다
- 끝까지 실행하게 되면 dataset 폴더에 '서울시격자중심점_좌표수정_회수로봇.xlsx' 파일이 생성됩니다.
<br><br>(오래걸리는 것을 대비해서 del_data에 파일 실행 결과 xlsx 파일 사전 첨부)

<br><br>

## 📂 데이터 합치기

- 모든 shp 파일을 QGIS를 통해 xlsx 파일로 바꿨습니다.
- 생성된 파일을 '서울시격자중심점_좌표수정_회수로봇.xlsx'와 합친 후에 엑셀 내에서 MinMax-Scaling을 진행합니다.
- 이 후에 결과 파일을 dataset 폴더에 'sc_data_m.xlsx'로 저장했습니다.

<br><br>


## 📊 회귀 분석 및 가중치 설정

- 'process_2_regression_anaylsis_mclp.ipynb' 파일을 실행합니다.
- 'MCLP' text cell 전까지 실행합니다
- 아래 코드를 통해서 상관관계를 파악할 수 있습니다.
```python
from sklearn.linear_model import LinearRegression
from sklearn import linear_model

df_LR = mclp_data.copy()
X = df_LR[["sc_거주인구","sc_유동인구_평균","sc_배달인구_평균","sc_1인가구","sc_역", 'sc_버스정류소']]
y = df_LR["회수합"]

X.corr()
```

- 아래 코드는 회귀 분석 코드로 얼마나 회수합과 관련이 있는지 확인할 수 있습니다.
```python
regr = linear_model.LinearRegression()
regr.fit(X, y)
print(regr.coef_)
regr.score(X, y)
```

<br><br>
## 📡 MCLP

- 제한된 시설물의 개수로 지역 수요를 최대한 많이 커버하기 위한 모델링 방법

### _inputs_
| num | parameter  | description  |
| --- | ---------- | ------------ |
|  1  | points     | 커버해야하는 지점들 |
|  2  | K          | 설치할 기기의 수 | 
|  3  | radius     | 한 기기가 커버하는 범위 |
|  4  | w          | 지점들의 중요도 벡터 |
|  5  | sites      | 기기가 들어설 수 있는 위치 |

### _outputs_
| num | variable           | description  |
| --- | ------------------ | ------------ |
|  1  | opt_sites          | 기기가 설치될 위치 |
|  2  | m.objective_value  | 설치한 기기들로 커버가능한 수요 | 

<br>
---
reference: https://github.com/cyang-kth/maximum-coverage-location

- MCLP text cell 이후의 코드를 실행합니다.
- 코드를 실행하면 아래와 같은 예시 결과가 나옵니다.

<img src="https://user-images.githubusercontent.com/63048392/131242158-c05e156a-c86c-44b5-a925-62fddb7b7d60.png" width="400" height="300">
