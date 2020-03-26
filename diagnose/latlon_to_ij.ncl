begin
   opt = True
   opt@MAP_PROJ          = 1
   opt@TRUELAT1          = 40
   opt@TRUELAT2          = 30
   opt@STAND_LON         = -97.5
   opt@REF_LAT           = 36.3605
   opt@REF_LON           = -98.50882
   opt@KNOWNI            = 200
   opt@KNOWNJ            = 200
   opt@DX                = 3000
   opt@DY                = 3000
   loc=wrf_ll_to_ij(-97.49,36.61,opt)
   asciiwrite("ij",round(loc, 3))
end
