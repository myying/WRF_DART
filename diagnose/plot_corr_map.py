#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import wrf_functions as wrf
import util
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader

plt.switch_backend('Agg')
plt.figure(figsize=(8, 5))

workdir = '/glade/scratch/mying/MPD/forecast/20190614/'
var = wrf.getvar(workdir+'wrfinput_d02', 'ua')
nt, nz, ny, nx = var.shape
nens = 100

lat = wrf.getvar(workdir+'wrfinput_d02', 'XLAT')[0, :, :]
lon = wrf.getvar(workdir+'wrfinput_d02', 'XLONG')[0, :, :]
y1,y2=120,200
x1,x2=150,200

### target variable:
var1 = np.zeros(nens)
for m in range(nens):
  tmp = wrf.getvar(workdir+'{:03d}/wrfout_d02_2019-06-14_08:00:00'.format(m+1), 'QRAIN')
  var1[m] = np.sum(tmp[0, :, y1:y2, x1:x2])
# print(var1)

### predictor variable:
var0 = np.zeros((ny, nx, nens))
for m in range(nens):
  tmp0 = wrf.getvar(workdir+'{:03d}/wrfout_d02_2019-06-14_06:30:00'.format(m+1), 'QVAPOR')
  var0[:, :, m] = np.sum(tmp0[0, 5:, :, :], axis=0)

corr = np.zeros((ny, nx))
for i in range(nx):
  for j in range(ny):
    corr[j, i] = util.sample_correlation(var0[j, i, :], var1)

ax = plt.axes(projection=ccrs.PlateCarree())

c = ax.contourf(lon, lat, corr, np.arange(-1, 1.1, 0.1), cmap='seismic')
plt.colorbar(c)
ax.contour(lon, lat, corr, (-0.3, 0.3), colors='r')

ax.plot([lon[y1,x1], lon[y2,x1], lon[y2,x2], lon[y1,x2], lon[y1,x1]],
    [lat[y1,x1], lat[y2,x1], lat[y2,x2], lat[y1,x2], lat[y1,x1]], 'k:')

#MPD sites
ax.text(-97.93, 36.31, '1', color='k', fontsize=8)
ax.text(-97.09, 36.88, '2', color='k', fontsize=8)
ax.text(-97.82, 36.82, '3', color='k', fontsize=8)
ax.text(-97.07, 36.37, '4', color='k', fontsize=8)
ax.text(-97.49, 36.61, '5', color='k', fontsize=8)

ax.set_extent([-102, -92, 33, 40])
us_shapes = list(shpreader.Reader('/glade/work/mying/data/shapefiles/gadm36_USA_1.shp').geometries())
ax.add_geometries(us_shapes, ccrs.PlateCarree(), facecolor='none', edgecolor='gray')


plt.savefig('2.pdf')
