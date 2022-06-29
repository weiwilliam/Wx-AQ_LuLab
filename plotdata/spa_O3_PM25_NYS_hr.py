"""
spatial distribution of hourly O3  and over NYS 
@author: Clin
"""
import numpy as np
from netCDF4 import Dataset
import os, fnmatch
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as cls
from mpl_toolkits.basemap import Basemap
import scipy.io
from matplotlib.cm import get_cmap
from wrf import to_np, getvar, smooth2d, get_basemap, latlon_coords
import pandas as pd
import datetime


''' ==== Settings ==== '''
path1 = os.getenv('OUT_PATH')
path2  = os.getenv('IMG_PATH')
print(path1)
print(path2)
shp_USA = '/network/rit/lab/lulab/chinan/CODE/mfile/map/Political_Boundaries_Area/Political_Boundaries_Area'
shp_USA1= '/network/rit/lab/lulab/chinan/CODE/mfile/map/gadm36_USA_2'

colors = [[1.,1.,1.],[196/255,213/255,1.],[138/255,171/255,1.],[98/255,176/255,207/255],[73/255,218/255,125/255],[62/255,255/255,51/255],[145/255,255/255,51/255],[228/255,255/255,51/255],[255/255,230/255,51/255],[255/255,194/255,51/255],[255/255,159/255,51/255],[255/255,123/255,51/255],[255/255,87/255,51/255],[255/255,51/255,51/255],[131/255,51/255,255/255]]
my_cmap = cls.ListedColormap(colors,name='my_name')

#set domain boundary
lon_lim = [-84, -65]    # NYS
lat_lim = [38, 46.0]

## reading WRF-Chem data 
filename = []
date = []
for root, dirs, files in os.walk(path1+'/'):
    for name in fnmatch.filter(files, '*wrfout_d02_2022-*'):
        filename = np.append(filename, os.path.join(root, name))
        date = np.append(date, name[11:19])
del [root, dirs, files, name]
NN = len(filename)

countn=0  
while (countn<NN):
  print(countn)
# Open the NetCDF file
  readin = Dataset(filename[countn])
  Time= getvar(readin, "times")
  date=str(Time)[37:47]
  hh=str(Time)[48:54]
  O3 = np.array(readin.variables['o3'])[0,0,:,:]*1000      # time x level xlat x lon,   ppm -> ppb
  NO2 = np.array(readin.variables['no2'])[0,0,:,:]
  CO = np.array(readin.variables['co'])[0,0,:,:]
  PM25 = np.array(readin.variables['PM2_5_DRY'])[0,0,:,:] #ug  m^-3
  COORD = getvar(readin, "o3") # for mapping

# Get the latitude and longitude points
  lats, lons = latlon_coords(COORD)
  #---- plot  
  fig, ax = plt.subplots(figsize=(12,9))    # unit=100pixel
  h = ax.get_position()
  ax.set_position([h.x0-0.04, h.y0, h.width+0.01, h.height])

  for axis in ['top','bottom','left','right']:
    ax.spines[axis].set_linewidth(2.5)
  
  # Get the basemap object
  bm = Basemap(llcrnrlon=lon_lim[0],urcrnrlon=lon_lim[-1],llcrnrlat=lat_lim[0],urcrnrlat=lat_lim[-1], projection='lcc',lat_1=33.,lat_2=45,lat_0=45.57,lon_0=-94.46, resolution='h')
  
  # Add geographic outlines
  bm.drawcoastlines(linewidth=0.5)
  bm.drawstates(linewidth=0.5)
  bm.drawcountries(linewidth=0.5)
  #bm.readshapefile(shp_USA, 'USA', color='k')
  bm.drawmeridians(np.arange(lon_lim[0], lon_lim[1]+2, 2.0), color='none', labels=[0,0,0,1], fontsize=18)
  bm.drawparallels(np.arange(lat_lim[0], lat_lim[1]+2, 2.0), color='none', labels=[1,0,0,0], fontsize=18)
  
  x, y = bm(to_np(lons), to_np(lats))
  
  clevs=np.linspace(0,120,16);#clevs=np.concatenate((clevs,[120]),axis=0)
  cs=bm.contourf(x, y, O3, levels=clevs, cmap=my_cmap,extend='max')
  cs.cmap.set_over([77/255,0/255,153/255]) 
  labelsize=18
  plt.yticks(fontsize=labelsize)
  plt.xticks(fontsize=labelsize)
  # Add a color bar
  cb = plt.colorbar(cs, extend='max', orientation='vertical',shrink=0.9,drawedges=True)
  cb.ax.tick_params(labelsize=18)
  plt.title(date +" " + hh+ "Z surface O3 mixing ratio (ppbv)",fontsize=20)
  
  #plt.show()
  plt.savefig(path2+'/spa_O3_'+date+'_'+hh+'_NYS.png',dpi=200,bbox_inches='tight')
  plt.close()

#------ plot spatial PM 
  fig, ax = plt.subplots(figsize=(12,9))    # unit=100pixel
  h = ax.get_position()
  ax.set_position([h.x0-0.04, h.y0, h.width+0.01, h.height])
  for axis in ['top','bottom','left','right']:
    ax.spines[axis].set_linewidth(2.5)
  # Get the basemap object
  bm = Basemap(llcrnrlon=lon_lim[0],urcrnrlon=lon_lim[-1],llcrnrlat=lat_lim[0],urcrnrlat=lat_lim[-1], projection='lcc',lat_1=33.,lat_2=45,lat_0=45.57,lon_0=-94.46, resolution='h')
  # Add geographic outlines
  bm.drawcoastlines(linewidth=0.5)
  bm.drawstates(linewidth=0.5)
  bm.drawcountries(linewidth=0.5)
  bm.drawmeridians(np.arange(lon_lim[0], lon_lim[1]+2, 2.0), color='none', labels=[0,0,0,1], fontsize=18)
  bm.drawparallels(np.arange(lat_lim[0], lat_lim[1]+2, 2.0), color='none', labels=[1,0,0,0], fontsize=18)

  x, y = bm(to_np(lons), to_np(lats))

  clevs=np.linspace(0,45,16);
  clevs_tick=[]
  for i in clevs: clevs_tick.append(str(i))
  norm = cls.BoundaryNorm(boundaries=clevs, ncolors=17)
  cs=bm.contourf(x, y, to_np(PM25), levels=clevs, cmap=my_cmap,extend='both',norm=norm)

  cs.cmap.set_over([77/255,0/255,153/255])
  labelsize=18
  plt.yticks(fontsize=labelsize)
  plt.xticks(fontsize=labelsize)
  # Add a color bar
  cb = plt.colorbar(cs, extend='both',ticks=clevs, orientation='vertical',shrink=0.9,drawedges=True)
  cb.ax.tick_params(labelsize=18);
  cb.ax.set_yticklabels(clevs_tick)  #

  plt.title(date +" " + hh+ "Z surface PM2.5 concentration $(\mu g m^{-3})$",fontsize=20)

  #plt.show()
  plt.savefig(path2+'/spa_PM25_'+date+'_'+hh+'_NYS.png',dpi=200,bbox_inches='tight')
  plt.close()

  countn+=1


