#!/usr/bin/env python3
import numpy as np
import pygrib
import wrf_functions as wrf
import matplotlib
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader
import sys

##target area
y1,y2=35.1,38.8
x1,x2=-98.2,-96.1

workdir = "/glade/scratch/mying/MPD/"
casename = "NoDA" #"assim_MPD"
t = int(sys.argv[1]) ##hour
m = int(sys.argv[2])
mem_id = '{:03d}'.format(m+1)
# mem_id = 'mean'

lat1 = wrf.getvar(workdir+casename+"/fc/201906140000/wrfinput_d02", "XLAT")[0, :, :]
lon1 = wrf.getvar(workdir+casename+"/fc/201906140000/wrfinput_d02", "XLONG")[0, :, :]

###for assim_MPD (RAINNC is 15-min cycling period cumulated rain)
# tmp = wrf.getvar(workdir+casename+"/fc/20190614{:02d}15".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
# tmp += wrf.getvar(workdir+casename+"/fc/20190614{:02d}30".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
# tmp += wrf.getvar(workdir+casename+"/fc/20190614{:02d}45".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
# tmp += wrf.getvar(workdir+casename+"/fc/20190614{:02d}00".format(t)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]

###for NoDA (continuous run so RAINNC is cumulative)
tmp = wrf.getvar(workdir+casename+"/fc/20190614{:02d}00".format(t)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
tmp -= wrf.getvar(workdir+casename+"/fc/20190614{:02d}00".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]

var1 = 0.0393701*tmp/9*16  ##convert unit

plt.switch_backend('Agg')
plt.figure(figsize=(9, 5))
ax = plt.axes(projection=ccrs.PlateCarree())
c = ax.contourf(lon1, lat1, var1, np.arange(0.1,1.05,0.05), cmap='Reds')
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
plt.savefig("precip_"+casename+"_{:02d}_".format(t)+mem_id+".png", dpi=200)
plt.close()
