#!/usr/bin/env python3
import numpy as np
import pygrib
import wrf_functions as wrf
import matplotlib
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader
import sys

# nws_precip_colors = [
#     "#04e9e7",  # 0.01 - 0.10 inches
#     "#019ff4",  # 0.10 - 0.25 inches
#     "#0300f4",  # 0.25 - 0.50 inches
#     "#02fd02",  # 0.50 - 0.75 inches
#     "#01c501",  # 0.75 - 1.00 inches
#     "#008e00",  # 1.00 - 1.50 inches
#     "#fdf802",  # 1.50 - 2.00 inches
#     "#e5bc00",  # 2.00 - 2.50 inches
#     "#fd9500",  # 2.50 - 3.00 inches
#     "#fd0000",  # 3.00 - 4.00 inches
#     "#d40000",  # 4.00 - 5.00 inches
#     "#bc0000",  # 5.00 - 6.00 inches
#     "#f800fd",  # 6.00 - 8.00 inches
#     "#9854c6",  # 8.00 - 10.00 inches
#     "#fdfdfd"   # 10.00+
# ]
# precip_colormap = matplotlib.colors.ListedColormap(nws_precip_colors)
# levels = [0.01, 0.1, 0.25, 0.50, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0,
#           6.0, 8.0, 10., 20.0]

##target area
y1,y2=35.1,38.8
x1,x2=-98.2,-96.1

###obs from stage4
t = int(sys.argv[1])
f = pygrib.open("/glade/work/mying/data/MPD/stage4_precip/ST4.20190614{:02d}.01h".format(t))
dat = f.read(1)[0]
lat, lon = dat.latlons()
var = dat.values.data
var[np.where(var==9999.)] = None
var = 0.0393701*var ##mm to inch
nx, ny = var.shape

plt.switch_backend('Agg')
plt.figure(figsize=(9, 5))
ax = plt.axes(projection=ccrs.PlateCarree())
c = ax.contourf(lon, lat, var, np.arange(0.1,1.05,0.05), cmap='Reds')
plt.colorbar(c)
ax.set_extent([-102, -92, 33, 40])
us_shapes = list(shpreader.Reader('/glade/work/mying/data/shapefiles/gadm36_USA_1.shp').geometries())
ax.add_geometries(us_shapes, ccrs.PlateCarree(), facecolor='none', edgecolor='#79d3fc')
ax.plot([x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], 'k:')
ax.text(-97.93, 36.31, '1', color='k', fontsize=10)
ax.text(-97.09, 36.88, '2', color='k', fontsize=10)
ax.text(-97.82, 36.82, '3', color='k', fontsize=10)
ax.text(-97.07, 36.37, '4', color='k', fontsize=10)
ax.text(-97.49, 36.61, '5', color='k', fontsize=10)
ax.set_title("1h precipitation (inch), 2019-06-14 {:02d}:00".format(t))
plt.savefig("precip/observation/{:02d}.png".format(t), dpi=200)
plt.close()
