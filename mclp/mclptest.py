from .mclp import *
from .mclpdemo import demo_generate_candidate_sites
from sklearn.datasets import make_moons

if __name__ == "__main__":
    # Number of sites to select
    K = 10

    # Service radius of each site
    radius = 0.2

    # Candidate site size (random sites generated)
    M = 100

    #커버해야할 포인트 생성(demo)
    points, _ = make_moons(300, noise=0.15)

    #후보지 생성(demo)
    sites = demo_generate_candidate_sites(points, M)

    plot_input(points)
    plot_input(sites)

    #모든 포인트에 대해 1점
    w = [ 1 for _ in points ]

    opt_sites, f = mclp(points, K, radius, w, sites)
    print(f)

    # # Plot the result 
    plot_result(points, opt_sites, radius)