#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import wrf_functions as wrf
from scipy import interpolate
import sys

workdir = '/glade/scratch/mying/MPD/'
casename = 'NoDA'
nens = 60
varname = 'abs_humidity'
varmin = 0
varmax = 20
varint = 1
timestart = '201906140000'
nt = 33
tt = np.arange(nt)
zz = np.arange(500, 6100, 100)
nz = zz.size
site_ij = np.array([[217, 198],
                    [242, 219],
                    [221, 217],
                    [243, 200],
                    [230, 209]])
ns = 5
mem_id = 'mean'
# m = int(sys.argv[1])
#mem_id = '{:03d}'.format(m+1)

tmp = wrf.getvar(workdir+casename+'/fc/'+timestart+'/wrfinput_d02_001', varname)
n, nk, ny, nx = tmp.shape
var = np.zeros((nt, nz, ns))
for t in range(nt):
  timestr = wrf.advance_time(timestart, t*15)
  # print(timestr)
  filename = workdir+casename+'/fc/'+timestr+'/wrfinput_d02_'+mem_id
  tmp = wrf.getvar(filename, varname)
  height = wrf.getvar(filename, 'z')
  for s in range(ns):
    ii, jj = site_ij[s, :]
    f = interpolate.interp1d(height[0, :, jj, ii], tmp[0, :, jj, ii])
    var[t, :, s] = f(zz)

plt.switch_backend('Agg')
plt.figure(figsize=(5, 10))
for s in range(ns):
  ax = plt.subplot(ns, 1, s+1)
  c = ax.contourf(var[:, :, s].T, np.arange(varmin, varmax, varint), cmap='jet')
  ax.set_xticks(np.arange(0, nt, 4))
  ax.set_xticklabels(np.arange(0, 9))
  ax.set_yticks(np.arange(1, nz, 10))
  ax.set_yticklabels(np.arange(1, 7))
  plt.colorbar(c)

plt.savefig('abs_humid_tz_'+mem_id+'.png', dpi=100)
