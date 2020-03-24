#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import wrf_functions as wrf
import util
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader

plt.switch_backend('Agg')
plt.figure(figsize=(8, 5))

workdir = '/glade/scratch/mying/MPD/forecast/long/'
var = wrf.getvar(workdir+'wrfinput_d02', 'ua')
nt, nz, ny, nx = var.shape
nens = 100

lat = wrf.getvar(workdir+'wrfinput_d02', 'XLAT')[0, :, :]
lon = wrf.getvar(workdir+'wrfinput_d02', 'XLONG')[0, :, :]
y1,y2=60,150
x1,x2=220,290

### target variable:
var1 = np.zeros(nens)
for m in range(nens):
  tmp = wrf.getvar(workdir+'{:03d}/wrfout_d02_2019-06-19_12:00:00'.format(m+1), 'QRAIN')
  var1[m] = np.sum(tmp[0, :, y1:y2, x1:x2])
# print(var1)
plt.hist(var1)
# thresh = 0.25
thresh = 22

### predictor variable:
var0 = np.zeros((ny, nx, nens))
for m in range(nens):
  tmp0 = wrf.getvar(workdir+'{:03d}/wrfout_d02_2019-06-19_11:00:00'.format(m+1), 'tk')
  var0[:, :, m] = np.mean(tmp0[0, 0:10, :, :], axis=0)
pert = 1

out = np.mean(var0[:, :, var1>=thresh], axis=2) - np.mean(var0[:, :, var1<thresh], axis=2)

ax = plt.axes(projection=ccrs.PlateCarree())
c = ax.contourf(lon, lat, out, np.arange(-pert, pert, pert/10), cmap='jet')
ax.set_title('CI - no CI')
plt.colorbar(c)

ax.plot([lon[y1,x1], lon[y2,x1], lon[y2,x2], lon[y1,x2], lon[y1,x1]],
        [lat[y1,x1], lat[y2,x1], lat[y2,x2], lat[y1,x2], lat[y1,x1]], 'k')

ax.set_extent([-103, -92, 33, 40])
us_shapes = list(shpreader.Reader('/glade/work/mying/data/shapefiles/gadm36_USA_1.shp').geometries())
ax.add_geometries(us_shapes, ccrs.PlateCarree(), facecolor='none', edgecolor='gray')

plt.savefig('1.pdf')
