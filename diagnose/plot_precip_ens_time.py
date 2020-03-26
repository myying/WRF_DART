#!/usr/bin/env python3
import numpy as np
import pygrib
import wrf_functions as wrf
import matplotlib
import matplotlib.pyplot as plt

plt.switch_backend('Agg')
plt.figure(figsize=(9, 5))

workdir = "/glade/scratch/mying/MPD/"
timestart = "201906140000"
nt = 48
nens = 40

##target area
y1,y2=35.1,38.8
x1,x2=-98.2,-96.1

var_out = np.zeros((nt))
for t in range(1, nt):
  timestr = wrf.advance_time(timestart, t*15)
  hh = int(timestr[8:10])
  ###obs from stage4
  f = pygrib.open("/glade/work/mying/data/MPD/stage4_precip/ST4.20190614{:02d}.01h".format(hh))
  dat = f.read(1)[0]
  lat, lon = dat.latlons()
  var = dat.values.data
  var[np.where(var==9999.)] = None
  var = 0.0393701*var ##mm to inch
  var = var/4 ##hourly to 15min
  nx, ny = var.shape
  var_out[t] = 0.0
  count = 0
  for i in range(nx):
    for j in range(ny):
      if(lat[i,j]>y1 and lat[i,j]<y2 and lon[i,j]>x1 and lon[i,j]<x2):
        count += 1
        var_out[t] += var[i,j]
  var_out[t] = var_out[t]/count

lat1 = wrf.getvar(workdir+"NoDA/fc/201906140000/wrfinput_d02", "XLAT")[0, :, :]
lon1 = wrf.getvar(workdir+"NoDA/fc/201906140000/wrfinput_d02", "XLONG")[0, :, :]
ny1, nx1 = lat1.shape

casename = "NoDA"
var1 = np.zeros((nt, nens, ny1, nx1))
var1_out = np.zeros((nt, nens))
for t in range(1, nt):
  timestr = wrf.advance_time(timestart, t*15)
  timestr1 = wrf.advance_time(timestart, (t-1)*15)
  tmp = np.zeros((nens, ny, nx))
  for m in range(nens):
    mem_id = "{:03d}".format(m+1)
    ###for NoDA (continuous run so RAINNC is cumulative)
    tmp = wrf.getvar(workdir+casename+"/fc/"+timestr+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
    tmp -= wrf.getvar(workdir+casename+"/fc/"+timestr1+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
    var1[t, m, :, :] = 0.0393701*tmp/9*16
count = 0
for i in range(nx1):
  for j in range(ny1):
    if(lat1[i,j]>y1 and lat1[i,j]<y2 and lon1[i,j]>x1 and lon1[i,j]<x2):
      count += 1
      var1_out += var1[:, :, i, j]
var1_out = var1_out/count

casename = "assim_MPD"
var2 = np.zeros((nt, nens, ny1, nx1))
var2_out = np.zeros((nt, nens))
for t in range(13, 33):
  timestr = wrf.advance_time(timestart, t*15)
  tmp = np.zeros((nens, ny, nx))
  for m in range(nens):
    mem_id = "{:03d}".format(m+1)
    ###for assim_MPD (RAINNC is 15-min cycling period cumulated rain)
    tmp = wrf.getvar(workdir+casename+"/fc/"+timestr+"/wrfinput_d02_"+mem_id, "RAINNC")[0, :, :]
    var2[t, m, :, :] = 0.0393701*tmp/9*16
count = 0
for i in range(nx1):
  for j in range(ny1):
    if(lat1[i,j]>y1 and lat1[i,j]<y2 and lon1[i,j]>x1 and lon1[i,j]<x2):
      count += 1
      var2_out += var2[:, :, i, j]
var2_out = var2_out/count

ax = plt.subplot(111)
##NoDA ensemble
for m in range(nens):
  ax.plot(var1_out[:, m], 'c')
ax.plot(np.mean(var1_out, axis=1), 'b', linewidth=2)
##assim_MPD ensemble
for m in range(nens):
  ax.plot(var2_out[0:32, m], 'y')
ax.plot(np.mean(var2_out[0:32, :], axis=1), 'r', linewidth=2)
##obs
ax.plot(var_out, 'k', linewidth=2)
ax.set_xticks(np.arange(0, nt, 4))
ax.set_xticklabels(np.arange(0, 13))
ax.set_ylim(0, 0.03)
plt.savefig("precip_time.png", dpi=200)
