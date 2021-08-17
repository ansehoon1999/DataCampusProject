from pyproj import Proj, transform
import numpy as np
import pandas  as pd

# Projection 정의
# UTM-K
proj_UTMK = Proj(init='epsg:5178') # UTM-K(Bassel) 도로명주소 지도 사용 중

# WGS1984
proj_WGS84 = Proj(init='epsg:4326') # Wgs84 경도/위도, GPS사용 전지구 좌표

# UTM-K -> WGS84 샘플
x1, y1 = 961114.519726,1727112.269174
x2, y2 = transform(proj_UTMK,proj_WGS84,x1,y1)
print(x2,y2)

# WGS84 -> UTM-K 샘플
x1, y1 = 127.07098392510115, 35.53895289091983
x2, y2 = transform(proj_WGS84, proj_UTMK, x1, y1)
print(x2,y2)

# x, y 컬럼을 이용하여 UTM-K좌표를 WGS84로 변환한 Series데이터 반환
def transform_utmk_to_w84(df):
    return pd.Series(transform(proj_UTMK, proj_WGS84, df['x'], df['y']), index=['x', 'y'])

df_xy = pd.DataFrame([
                                        ['A', 961114.519726,1727112.269174],
                                        ['B', 940934.895125,1685175.196487],
                                        ['C', 1087922.228298,1761958.688262]
                                    ], columns=['id', 'x', 'y'])

df_xy[['x_w84', 'y_w84']] = df_xy.apply(transform_utmk_to_w84, axis=1)

print(df_xy)