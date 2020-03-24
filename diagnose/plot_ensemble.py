#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import wrf_functions as wrf
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader

workdir = '/glade/scratch/mying/MPD/forecast/20190614/'
nens = 100

plt.switch_backend('Agg')
plt.figure(figsize=(15, 5))

ax = plt.subplot(1,2,1,projection=ccrs.PlateCarree())
lat = wrf.getvar(workdir+'wrfinput_d02', 'XLAT')[0, :, :]
lon = wrf.getvar(workdir+'wrfinput_d02', 'XLONG')[0, :, :]
var_ens = np.zeros(nens)
y1,y2=100,200
x1,x2=140,210

cmap = [plt.cm.jet(m) for m in np.linspace(0, 1, nens)]
for m in range(nens):
  var = wrf.getvar(workdir+'{:03d}/wrfout_d02_2019-06-14_08:00:00'.format(m+1), 'QRAIN')
  var_ens[m] = np.sum(var[0, :, y1:y2, x1:x2])
  var_out = np.sum(var[0, :, :, :], axis=0)
  ax.contour(lon, lat, var_out, (0.005,), colors=[cmap[m][0:3]], linestyles='solid', linewidths=2)

###draw a box where target value is averaged
ax.plot([lon[y1,x1], lon[y2,x1], lon[y2,x2], lon[y1,x2], lon[y1,x1]],
        [lat[y1,x1], lat[y2,x1], lat[y2,x2], lat[y1,x2], lat[y1,x1]], 'k')

ax.set_extent([-102, -92, 33, 40])
us_shapes = list(shpreader.Reader('/glade/work/mying/data/shapefiles/gadm36_USA_1.shp').geometries())
ax.add_geometries(us_shapes, ccrs.PlateCarree(), facecolor='none', edgecolor='gray')

ax = plt.subplot(1,2,2)
ax.hist(var_ens)

plt.savefig('2.pdf')
