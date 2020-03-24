#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import wrf_functions as wrf
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader

workdir = '/glade/scratch/mying/MPD/forecast/20190614/'
nens = 100
varname = 'QVAPOR'
varmin = 0
varmax = 0.01 #0.15
varint = 0.001 #0.005
# varname = 'QRAIN'
# varmin = -0.0001
# varmax = 0.01
# varint = 0.0001

plt.switch_backend('Agg')
plt.figure(figsize=(10, 5))

ax = plt.subplot(1,1,1,projection=ccrs.PlateCarree())
lat = wrf.getvar(workdir+'wrfinput_d02', 'XLAT')[0, :, :]
lon = wrf.getvar(workdir+'wrfinput_d02', 'XLONG')[0, :, :]
ny, nx = lon.shape
var_ens = np.zeros((nens, ny, nx))

for m in range(nens):
  var = wrf.getvar(workdir+'{:03d}/wrfout_d02_2019-06-14_04:00:00'.format(m+1), varname)
  var_ens[m, :, :] = np.sum(var[0, 5:15, :, :], axis=0)

###variance
var_mean = np.mean(var_ens, axis=0)
var_sprd = np.zeros((ny, nx))
for m in range(nens):
  var_sprd = var_sprd + (var_ens[m, :, :] - var_mean)**2
var_sprd = np.sqrt( var_sprd / (nens-1) )
# print(np.min(var_mean))

c = ax.contourf(lon, lat, var_sprd, np.arange(varmin, varmax, varint), cmap='jet')
plt.colorbar(c)

#MPD sites
ax.text(-97.93, 36.31, '1', color='w', fontsize=8)
ax.text(-97.09, 36.88, '2', color='w', fontsize=8)
ax.text(-97.82, 36.82, '3', color='w', fontsize=8)
ax.text(-97.07, 36.37, '4', color='w', fontsize=8)
ax.text(-97.49, 36.61, '5', color='w', fontsize=8)

ax.set_extent([-102, -92, 33, 40])
us_shapes = list(shpreader.Reader('/glade/work/mying/data/shapefiles/gadm36_USA_1.shp').geometries())
ax.add_geometries(us_shapes, ccrs.PlateCarree(), facecolor='none', edgecolor='k')

plt.savefig('1.pdf')
