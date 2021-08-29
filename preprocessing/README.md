
# 데이터 캠퍼스 '수퍼루키조' 코드 설명

## 📃 Brief Description
<br>

- dataset: 데이터 분석에 필요한 데이터 셋이 있는 폴더
- npy_file: 'process_1_coverage.ipynb' 실행 시 결과가 저장되는 폴더
- preprocessing 폴더: 유동인구, 거주인구, 1인가구, 배달인구 변수들을 전처리하는 폴더
- process_1_coverage.ipynb : 공원, 역, 버스정류소 등의 변수을 전처리하는 파일
- process_2_regression_anaylsis_mclp.ipynb: 회귀 및 mclp을 통한 결과를 보여주는 파일

<br>

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



### 2️⃣ 배달 인구

#### 1) 데이터 전처리

- result 폴더에서 'delivery_data_preprocessing.ipynb' 파일 실행
- 끝까지 실행시키면 del_data 에 총 6개의 txt 파일 생성 
<br><br>(오래걸리는 것을 대비해서 del_data에 파일 실행 결과 txt 파일 사전 첨부)

#### 2) 배달인구 데이터 격자화

- 이후에 '배달인구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 'del_popu_100_n.shp' 외 3개의 파일이 생성됩니다. (n은 10대부터 60대까지 3시간 간격의 숫자) 

<br><br>

### 3️⃣ 거주 인구

#### 1) 거주인구 데이터 격자화

- 이후에 '거주인구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 'live_popu_100.shp' 외 3개의 파일이 생성됩니다. 
<br><br>(오래걸리는 것을 대비해서 live_data에 파일 실행 결과 txt 파일 사전 첨부)


<br><br>
### 4️⃣ 1인 가구

#### 1) 1인 가구 데이터 격자화

- 이후에 '1인가구_격자화코드.R'을 실행합니다.
- 끝까지 실행하면 output_file 폴더에 '1live_popu_100.shp' 외 3개의 파일이 생성됩니다. 
<br><br>(오래걸리는 것을 대비해서 1family_data에 파일 실행 결과 txt 파일 사전 첨부)


<br><br>
### 5️⃣ 지하철, 버스정류소, AI 재활용 로봇

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

## 📊 회귀 분석 및 가중치 설정

