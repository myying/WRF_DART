#!/usr/bin/env python3
import numpy as np
import pygrib
import wrf_functions as wrf
import matplotlib
import matplotlib.pyplot as plt
import sys

plt.switch_backend('Agg')
plt.figure(figsize=(9, 5))

workdir = "/glade/scratch/mying/MPD/"
casename = "assim_MPD"
t = int(sys.argv[1]) ##hour
nens = 60

##target area
y1,y2=35.1,38.8
x1,x2=-98.2,-96.1

###obs from stage4
f = pygrib.open("/glade/work/mying/data/MPD/stage4_precip/ST4.20190614{:02d}.01h".format(t))
dat = f.read(1)[0]
lat, lon = dat.latlons()
var = dat.values.data
var[np.where(var==9999.)] = None
var = 0.0393701*var ##mm to inch
nx, ny = var.shape

##target area sum
var_out = 0.0
count = 0
for i in range(nx):
  for j in range(ny):
    if(lat[i,j]>y1 and lat[i,j]<y2 and lon[i,j]>x1 and lon[i,j]<x2):
      count += 1
      var_out += var[i,j]
var_out = var_out/count
# print(var_out)

###from model simulation
var1_out = np.zeros(nens)
for m in range(nens):
  lat1 = wrf.getvar(workdir+casename+"/fc/201906140000/wrfinput_d02", "XLAT")[0, :, :]
  lon1 = wrf.getvar(workdir+casename+"/fc/201906140000/wrfinput_d02", "XLONG")[0, :, :]
  mem_id = "{:03d}".format(m+1)

  ###for assim_MPD (RAINNC is 15-min cycling period cumulated rain)
  tmp = wrf.getvar(workdir+casename+"/fc/20190614{:02d}15".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
  tmp += wrf.getvar(workdir+casename+"/fc/20190614{:02d}30".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
  tmp += wrf.getvar(workdir+casename+"/fc/20190614{:02d}45".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
  tmp += wrf.getvar(workdir+casename+"/fc/20190614{:02d}00".format(t)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]

  ###for NoDA (continuous run so RAINNC is cumulative)
  # tmp = wrf.getvar(workdir+casename+"/fc/20190614{:02d}00".format(t)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
  # tmp -= wrf.getvar(workdir+casename+"/fc/20190614{:02d}00".format(t-1)+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]

  var1 = 0.0393701*tmp/9*16

  nx1, ny1 = var1.shape
  count = 0
  for i in range(nx1):
    for j in range(ny1):
      if(lat1[i,j]>y1 and lat1[i,j]<y2 and lon1[i,j]>x1 and lon1[i,j]<x2):
        count += 1
        var1_out[m] += var1[i,j]
var1_out = var1_out/count
# print(var1_out)

plt.hist(var1_out)
plt.plot([var_out, var_out], [0, 20], 'k')
plt.savefig("precip_"+casename+"_{:02d}".format(t)+"_hist.png", dpi=200)
