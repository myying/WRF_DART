#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import netCDF4
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader

geo_dir = '/glade/scratch/mying/MPD/icbc'
num_domain = 2
var_dim = 2
lv = 0
var_name = 'HGT_M'
var_range = np.arange(0, 5000, 100)

plt.switch_backend('Agg')
plt.figure(figsize=(12, 5))
ax = plt.axes(projection=ccrs.PlateCarree())

for d in range(num_domain):
  f = netCDF4.Dataset(geo_dir+"/geo_em.d0{}.nc".format(d+1))
  if var_dim == 2:
    hgt = f.variables[var_name][0, :, :]
  if var_dim == 3:
    hgt = f.variables[var_name][0, lv, :, :]
  lat = f.variables['XLAT_M'][0, :, :]
  lon = f.variables['XLONG_M'][0, :, :]
  c = ax.contourf(lon, lat, hgt, var_range, cmap="jet")
  ax.plot(lon[0, :], lat[0, :], 'k')
  ax.plot(lon[:, 0], lat[:, 0], 'k')
  ax.plot(lon[-1, :], lat[-1, :], 'k')
  ax.plot(lon[:, -1], lat[:, -1], 'k')
  ax.text(lon[-1, 0], lat[-1, 0]+0.2, 'd0{}'.format(d+1), fontsize=8)
plt.colorbar(c)

ax.set_extent([-122, -72, 22, 48])
us_shapes = list(shpreader.Reader('/glade/work/mying/data/shapefiles/gadm36_USA_1.shp').geometries())
ax.add_geometries(us_shapes, ccrs.PlateCarree(), facecolor='none', edgecolor='#79d3fc')
ax.coastlines()
ax.set_xticks(np.arange(-120, -74, 5), crs=ccrs.PlateCarree())
ax.set_yticks(np.arange(20, 51, 5), crs=ccrs.PlateCarree())

plt.savefig('domain.png', dpi=100)
