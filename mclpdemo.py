from mclp import *
import numpy as np
import pandas as pd
Npoints = 300
from sklearn.datasets import make_moons
points,_ = make_moons(Npoints,noise=0.15)

# Number of sites to select
K = 10

# Service radius of each site
radius = 0.2

# Candidate site size (random sites generated)
M = 100

# print( pd.DataFrame(points))

def generate_candidate_sites(points,M=100):
    '''
    Generate M candidate sites with the convex hull of a point set
    Input:
        points: a Numpy array with shape of (N,2)
        M: the number of candidate sites to generate
    Return:
        sites: a Numpy array with shape of (M,2)
    '''
    hull = ConvexHull(points)
    polygon_points = points[hull.vertices]
    poly = Polygon(polygon_points)
    min_x, min_y, max_x, max_y = poly.bounds
    sites = []
    while len(sites) < M:
        random_point = Point([random.uniform(min_x, max_x),
                             random.uniform(min_y, max_y)])
        if (random_point.within(poly)):
            sites.append(random_point)
    return np.array([(p.x,p.y) for p in sites])

#후보지 생성(demo)
sites = generate_candidate_sites(points, M)

plot_input(points)
plot_input(sites)

#모든 포인트에 대해 1점
w = [ 1 for _ in points]

opt_sites,f = mclp(points, K, radius, w, sites)
print(f)

# # Plot the result 
plot_result(points,opt_sites,radius)