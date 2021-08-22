import pandas as pd
import numpy as np

# 하버사인 거리 획득
def haversine_np(lon1, lat1, lon2, lat2):
    lon1, lat1, lon2, lat2 = map(np.radians, [lon1, lat1, lon2, lat2])

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    a = np.sin(dlat/2.0)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon/2.0)**2

    c = 2 * np.arcsin(np.sqrt(a))
    km = 6367 * c
    return km

# input 모든 지점에 대한 하버사인 거리 획득
def haversine_wrapper(x, y):
    m, k = x.shape
    n, kk = y.shape
    result = np.empty((m,n),dtype=float)
    for i in range(m):
        print('\r'+str(i), end='')
        for j in range(n):
            result[i,j]=haversine_np(x[i,0], x[i,1], y[j,0], y[j,1])
    return result

# 기준에 해당하는 시설의 수 카운트
def getCountOfPlace(secent_place, meter=300):
    #secent_place_c = np.copy(secent_place)
    mask1 = secent_place*1000<=meter
    secent_place[mask1]=1
    secent_place[~mask1]=0
    return np.sum(secent_place, axis=-1)