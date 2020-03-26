###WRF utility functions
import numpy as np

def advance_time(timestart, incr_minute):
  import datetime
  ccyy = int(timestart[0:4])
  mm = int(timestart[4:6])
  dd = int(timestart[6:8])
  hh = int(timestart[8:10])
  ii = int(timestart[10:12])
  t1 = datetime.datetime(ccyy, mm, dd, hh, ii, 0)
  t2 = t1 + datetime.timedelta(minutes=incr_minute)
  ccyy = t2.year
  mm = t2.month
  dd = t2.day
  hh = t2.hour
  ii = t2.minute
  timeout = "{:04d}{:02d}{:02d}{:02d}{:02d}".format(ccyy, mm, dd, hh, ii)
  return timeout

def ncread(filename, varname):
  import netCDF4
  f = netCDF4.Dataset(filename)
  dat = f.variables[varname]
  return np.array(dat)


def getvar(infile, varname):
  Rd = 287.0
  Rv = 461.6
  Cp = 1004.5
  g = 9.81
  svp1 = 0.6112
  svp2 = 17.67
  svp3 = 29.65
  ep2 = Rd/Rv
  ep3 = 0.622
  t0 = 273.15

  if (varname == 'ua'):
    dat = ncread(infile, 'U')
    nt, nz, ny, nx = dat.shape
    var = 0.5*(dat[:, :, :, 0:nx-1] + dat[:, :, :, 1:nx])

  elif (varname == 'va'):
    dat = ncread(infile, 'V')
    nt, nz, ny, nx = dat.shape
    var = 0.5*(dat[:, :, 0:ny-1, :] + dat[:, :, 1:ny, :])

  elif (varname == 'wa'):
    dat = ncread(infile, 'W')
    nt, nz, ny, nx = dat.shape
    var = 0.5*(dat[:, 0:nz-1, :, :] + dat[:, 1:nz, :, :])

  elif (varname == 'p'):
    var = ncread(infile, 'P') + ncread(infile, 'PB')

  elif (varname == 'z'):
    dat = (ncread(infile, 'PH') + ncread(infile, 'PHB')) / g
    nt, nz, ny, nx = dat.shape
    var = 0.5*(dat[:, 0:nz-1, :, :] + dat[:, 1:nz, :, :])

  elif (varname == 'th'):
    var = ncread(infile, 'T') + 300

  elif (varname == 'tk'):
    th = ncread(infile, 'T') + 300
    p = ncread(infile, 'P') + ncread(infile, 'PB')
    var = th * (p/100000.0) ** (Rd/Cp)

  elif (varname == 'abs_humidity'):
    th = ncread(infile, 'T') + 300
    p = ncread(infile, 'P') + ncread(infile, 'PB')
    tk = th * (p/100000.0) ** (Rd/Cp)
    qvapor = ncread(infile, 'QVAPOR')
    tv = tk * (1.0 + qvapor * Rv / Rd)
    rho_dry = p / (Rd * tv)
    var = qvapor * rho_dry * 1000

  else:
    var = ncread(infile, varname)

  return var

