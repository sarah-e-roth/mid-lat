# HDF4 Manipulation
## Following tutorial from: https://github.com/ornldaac/gedi_tutorials/blob/main/2_gedi_l4a_subsets.ipynb

# Importing required modules
## All required modules can be found in 'Python_Requirements.txt'
## Run this text file using pip to istall all necessary modules.

import os
import h5py
import requests
import pandas as pd
import geopandas as gpd
import contextily as ctx
import numpy as np
from glob import glob
from shapely.geometry import MultiPolygon, Polygon
from shapely.ops import orient

# Polygon Area of Interest
ecor = gpd.read_file(r'A:/mid-lat/Cropped_Projected_Remote_Sensing/Ecoregions_L3_ML_NAD83/Ecoregions_L3_ML_NAD83.shp/Ecoregions_L3_ML_NAD3.shp')

# File Paths
modis_lw_path = r'A:/mid-lat/Original_Remote_Sensing_Downloads/MODIS_VIIRS/Land_Water_Mask'
os.path.exists(modis_lw_path) #True

gedi_l4a_path = r'A:/mid-lat/Original_Remote_Sensing_Downloads/GEDI/L4A_Footprint_Level_AGB'
os.path.exists(gedi_l4a_path) #True

# Get a list of all .hdf files in each directory
modis_lw_list = [f for f in os.listdir(modis_lw_path) if f.endswith('.hdf')]

gedi_l4a_list = [f for f in os.listdir(gedi_l4a_path) if f.endswith('.h5')]

# MODIS Land Water Mask
## Open the first file in the list
gedi_file = h5py.File(os.path.join(gedi_l4a_path, gedi_l4a_list[0]), 'r')
print(list(gedi_file.keys()))