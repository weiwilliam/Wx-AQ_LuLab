import sys, os
import numpy as np
import matplotlib.pyplot as plt
import csv
import pandas as pd
from datetime import datetime, timedelta
import xarray as xa

##Td Calculation
def T2Td(T,rh):
  b = 18.678
  c = 257.14
#  if (np.isnan(T)) or (np.isnan(rh)):
#    Td = np.nan
#  else:
  garma = np.log(rh/100.0)+(b*T/(c+T))
  Td = c*garma/(b-garma)
  return Td

##Specific Humidity
def Td2q(Td,P):
   es0 = 611.2
   T0  = 273.15
   Lv  = 2501000.
   Rv  = 461.5
#   if (np.isnan(Td)) or (np.isnan(P)):
#     q = np.nan
#     r = np.nan
#   else:
   es = es0*np.exp(Lv*(Td+273.15-T0)/(Rv*(Td+273.15)*T0))
   q  = (0.622*(es/100.0)/P)*1000.0*1000.0
   r  = (0.622*(es/100.0)/(P-(es/100.0)))*1000.0
   return round(q,1),r

##WS,WD to U,V
def ws2uv(wd,ws):
#   if ((~np.isnan(wd)) and (~np.isnan(ws))):
   md = 270.-wd
   md = md*np.pi/180.
   u = ws * np.cos(md)
   v = ws * np.sin(md)
#   else:
#     u = np.nan
#     v = np.nan
   return round(u,1),round(v,1)

## Environment variables
#cdate = os.getenv('CDATE')
#cut_hour = int(os.getenv('HINT'))
#input_path = os.getenv('INPUT_PATH')
#fix_path = os.getenv('FIX_PATH')

cdate = 2022042500 
cut_hour = 1
input_path = '/network/rit/lab/lulab/NY-Meso/proc'
fix_path = '/network/rit/home/sw651133/Wx-AQ/prepdata/fix'

## Define the date of nysm file to read in
cyy=int(str(cdate)[:4]); cmm=int(str(cdate)[4:6])
cdd=int(str(cdate)[6:8]); chh=int(str(cdate)[8:10])
c_pdy=str(cdate)[:8]; c_hh=str(cdate)[8:10]
c_dtime=datetime(cyy,cmm,cdd,chh)
delta=timedelta(hours=cut_hour)
s_dtime=c_dtime-delta
e_dtime=c_dtime+delta
s_ymd=s_dtime.strftime('%Y%m%d')
s_ym=s_dtime.strftime('%Y%m')
s_y=s_dtime.strftime('%Y')
s_m=s_dtime.strftime('%m')
if (s_dtime.day != e_dtime.day):
   e_ymd=e_dtime.strftime('%Y%m%d')
   crossday=1
else:
   e_ymd=s_ymd
   crossday=0
if (s_dtime.month != e_dtime.month):
   e_ym=e_dtime.strftime('%Y%m')
   e_y=e_dtime.strftime('%Y')
   e_m=e_dtime.strftime('%m')
else:
   e_ym=s_ym
   e_y=s_y
   e_m=s_m

## Read in station information
elev_file=os.path.join(fix_path,'nysm_elev.txt')
elev=pd.read_table(elev_file,header=None,sep=' ')
elev.columns=['STID','Elev(m)','Elev(ft)']

latlon_file=os.path.join(fix_path,'nysm_latlon.txt')
latlon=pd.read_table(latlon_file,header=None,sep=' ')
latlon.columns=['STID','Lat','Lon','Flag']
latlon['Lat']=round(latlon['Lat'],2)
latlon['Lon']=round((latlon['Lon']+180)%360+180,2)

stdclass_file=os.path.join(fix_path,'standard_class1_2.txt')
stdclass=pd.read_table(stdclass_file,header=None,sep=' ')
stdclass.columns=['STID','Lat','Lon','Flag']
stdclass_stnlist=stdclass['STID'].sort_values()

infile0=os.path.join(input_path,s_y,s_m,s_ymd+'.nc')
print(infile0,flush=1)

if (crossday):
   infile1=os.path.join(input_path,e_y,e_m,e_ymd+'.nc')
   print(infile1,flush=1)

if ( os.path.exists(infile0) ):
   ds0=xa.open_dataset(infile0)
   df0=ds0.to_dataframe()
   if ( crossday and os.path.exists(infile1) ):
      ds1=xa.open_dataset(infile1)
      df1=ds1.to_dataframe()
      df0=pd.concat([df0,df1])
   else:
      print('Error: '+infile1+' does not exist!',flush=1)
   df0=df0.reset_index()
   df0_datetime=pd.to_datetime(df0['time_5M'],format="%Y-%m-%d %H:%M:%S UTC")
   df0['time_5M']=df0_datetime
   filter=((df0['time_5M']<=e_dtime)&(df0['time_5M']>=s_dtime))
   tmpdf=df0.loc[filter,:]
   
   tmpdf=tmpdf[['station','time_5M','tair','relh',
                'wspd_prop','wdir_prop','wspd_sonic','wmax_sonic',
                'wdir_sonic','pres']]

   measure_time = tmpdf['time_5M']
   dhr          = round((measure_time-c_dtime)/np.timedelta64(1, 'h'),1)

   press        = tmpdf['pres']
   T_2m         = tmpdf['tair']
   rh           = tmpdf['relh']

   avg_ws_sonic = tmpdf['wspd_sonic']
   max_ws_sonic = tmpdf['wmax_sonic']
   wd_sonic     = tmpdf['wdir_sonic']
   avg_ws_prop  = tmpdf['wspd_prop']
   wd_prop      = tmpdf['wdir_prop']

   Td_2m             = T2Td(T_2m,rh)
   specific_q, mixr  = Td2q(Td_2m,press)
   u_sonic,v_sonic   = ws2uv(wd_sonic,avg_ws_sonic)
   u_prop,v_prop     = ws2uv(wd_prop,avg_ws_prop)

   output_df    = tmpdf[['station']]
   output_df.insert(1,'v_sonic',v_sonic)
   output_df.insert(1,'u_sonic',u_sonic)
   output_df.insert(1,'specific_q',specific_q)
   output_df.insert(1,'T_2m',T_2m)
   output_df.insert(1,'press',press)
   output_df.insert(1,'dhr',dhr)
   output_df.insert(1,'elev',press)
   output_df.insert(1,'lon',press)
   output_df.insert(1,'lat',press)
 
   for station in elev['STID']:
       filter=(output_df['station']==station)
       elev_filter=(elev['STID']==station)
       latlon_filter=(latlon['STID']==station)
       output_df.loc[filter,'elev']=elev.loc[elev_filter,'Elev(m)'].values[0]
       output_df.loc[filter,'lon']=latlon.loc[latlon_filter,'Lon'].values[0]
       output_df.loc[filter,'lat']=latlon.loc[latlon_filter,'Lat'].values[0]

   nan_filter=~(( output_df['press'].isna()      )|
                ( output_df['T_2m'].isna()       )|
                ( output_df['specific_q'].isna() )|
                ( output_df['u_sonic'].isna()    )|
                ( output_df['v_sonic'].isna()    ))

   output_df=output_df.loc[nan_filter,:]
   output_df=output_df.reset_index(drop=1)
   output_df=output_df.sort_values(by=['dhr','station'])
   #output_df.to_csv('nysm_'+c_pdy+'_t'+c_hh+'z.txt',sep=' ',header=0,index=0)

   inter_filter=(output_df['station'].isin(stdclass_stnlist))
   inter_df=output_df.loc[inter_filter,:]
   inter_df.to_csv('./intermediate.csv',sep=' ',header=0,index=0)
else:
   print('Error: '+infile0+' does not exist!',flush=1)
