import numpy as np
import time
from scipy.spatial import distance_matrix
from mip import Model, xsum, maximize, BINARY
from matplotlib import pyplot as plt

#####################    MCLP ALGORITHM    ######################
#######input
#points             -> 커버해야할 포인트들(2차원 nparray). ex) [[10,1], [127,127]]
#K                  -> 설치할 기기의 수(int)
#radius             -> 한 기기당 커버 가능한 범위
#w                  -> 포인트들의 중요도(wight) 벡터
#sites              -> 설치가 가능한 위치(후보지)

#######output
#opt_sites          -> 결과적으로 설치할 위치들
#m.objective_value  -> 결과값의 커버 크기
#################################################################
def mclp(points:np.ndarray, K, radius, w, sites:np.ndarray):
    print('----- Configurations -----')
    print('  Number of points %g' % points.shape[0])
    print('  K %g' % K)
    print('  Radius %g' % radius)

    start = time.time()
    J, I = sites.shape[0], points.shape[0]
    D = distance_matrix(points,sites)
    mask1 = (D <= radius)
    D[mask1]=1
    D[~mask1]=0

    # Build model
    m:Model = Model("mclp")

    # Add variables
    x = [m.add_var(name = "x%d" % j, var_type = BINARY) for j in range(J)]
    y = [m.add_var(name = "y%d" % i, var_type = BINARY) for i in range(I)]

    # Add objective function
    m.objective = maximize(xsum(w[i]*y[i] for i in range (I)))
    m += xsum(x[j] for j in range(J)) == K
    for i in range(I):
        m += xsum(x[j] for j in np.where(D[i]==1)[0]) >= y[i]

    m.optimize()

    end = time.time()
    print('----- Output -----')
    print('  Running time : %s seconds' % float(end-start))
    print('  Optimal coverage points: %g' % m.objective_value)

    solution = []
    for i in range(J):
        if x[i].x ==1:
            solution.append(int(x[i].name[1:]))
    opt_sites = sites[solution]

    return opt_sites, m.objective_value

def plot_input(points):
    '''
    Plot the result
    Input:
        points: input points, Numpy array in shape of [N,2]
        opt_sites: locations K optimal sites, Numpy array in shape of [K,2]
        radius: the radius of circle
    '''
    fig = plt.figure(figsize=(8,8))
    plt.scatter(points[:,0],points[:,1],c='C0')
    ax = plt.gca()
    ax.axis('equal')
    ax.tick_params(axis='both',left=False, top=False, right=False,
                       bottom=False, labelleft=False, labeltop=False,
                       labelright=False, labelbottom=False)
    plt.show()

def plot_result(points,opt_sites,radius):
    '''
    Plot the result
    Input:
        points: input points, Numpy array in shape of [N,2]
        opt_sites: locations K optimal sites, Numpy array in shape of [K,2]
        radius: the radius of circle
    '''
    fig = plt.figure(figsize=(8,8))
    plt.scatter(points[:,0],points[:,1],c='C0')
    ax = plt.gca()
    plt.scatter(opt_sites[:,0],opt_sites[:,1],c='C1',marker='+')
    for site in opt_sites:
        circle = plt.Circle(site, radius, color='C1',fill=False,lw=2)
        ax.add_artist(circle)
    ax.axis('equal')
    ax.tick_params(axis='both',left=False, top=False, right=False,
                       bottom=False, labelleft=False, labeltop=False,
                       labelright=False, labelbottom=False)
    plt.show()