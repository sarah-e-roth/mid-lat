# Script Setup----
# Reprojecting Remote Sensing Data Files (Making everything match up)
library(terra) #1.7.71
library(sf)
library(stringr)
library(rhdf5)

setwd("~/Mid-Lat_Project")

# Destination CRS
st.nad83 <- 4269
rast.nad83 <- 'EPSG:4269'

# Workflow----

## Rasters
# 1. Open original raster file
# 2. Plot to make sure it loaded in well
# 3. Transform ecoregion shapefile to match that of the original raster file
# 4. Mask the raster with the projection ecoregion shapefile
# 5. Trim the resulting masked raster
# 6. Check if the trimmed raster is able to be projected to nad83
# 7. Project to nad83
# 8. Write new raster file (trimmed and reprojected)
# 9. Remove intermediate variables
# 10. Save trimmed and reprojected raster as RData for later use

## Shapefiles
# 1. Load in shapefile as sf
# 2. Plot to make sure it is loaded well
# 3. Check if it can be transformed to NAD83
# 4. Transform to NAD83
# 5. Crop to ecor
# 6. Write new shapefile (trimmed and reprojected)
# 7. Remove intermediate variables
# 8. Save trimmed and reprojected shapefile as RData for later use


# Study AOI shapefile----
# Level 3 Ecoregions: Central Appalachia, Ridge and Valley, Blue Ridge
# Constrained to states: PA, MD, VA, WV

ecor <- read_sf('Shapefiles/Ecoregions_L3_Mid-Lat/level3_ecoregions.shp')
head(ecor) #doesn't read in with a known crs projection

st_can_transform(ecor, st.nad83) #True
ecor <- st_transform(ecor, st.nad83) #transform to NAD83
plot(ecor)




### ecor extent ----
ext(ecor) #-83.675413910869, -74.6949139877433, 36.561752832329, 41.7276755085671 (xmin, xmax, ymin, ymax)

# Write new shapefile
st_write(ecor, 'Shapefiles/Ecoregions_L3_Mid-Lat_NAD83/Ecoregions_L3_ML_NAD83.shp')

# Save as RData
save(ecor, file = "mid-lat/Mid-Lat R Project/ecor.Rdata")

# Ecoregion shapefile for later use (already set to NAD83)
ecor <- read_sf('Shapefiles/Ecoregions_L3_ML_NAD83/Ecoregions_L3_ML_NAD83.shp')
load("~/Mid-Lat_Project/mid-lat/Mid-Lat R Project/ecor.Rdata")
# TODO: NLCD----

## NLCD 2021----
nlcd_cover <- rast('Landsat_NLCD/NLCD_Land_Cover_2021/nlcd_2021_land_cover_l48_20230630.img')
plot(nlcd_cover)

# project ecor shapefile to match crs of NLCD to mask the dataset
ecor_proj <- st_transform(ecor, crs(nlcd_cover))
nlcd_cover_crop <- mask(nlcd_cover, ecor_proj)
nlcd_cover_trim <- trim(nlcd_cover_crop)
plot(nlcd_cover_trim)

# project to nad83
st_can_transform(nlcd_cover_trim, st.nad83) #True
nlcd_cover_nad83 <- project(nlcd_cover_trim, rast.nad83)
plot(nlcd_cover_nad83)

#write raster file
writeRaster(x = nlcd_cover_nad83,
            filename = 'Landsat_NLCD/NLCD_Land-Cover_ML_NAD83/NLCD_Land-Cover_ML_NAD83.tif', overwrite = TRUE)

# Save as RData
save(nlcd_cover_nad83, file = "mid-lat/Mid-Lat R Project/nlcd_2021.RData")

#Remove intermediate variables
rm(nlcd_cover, nlcd_cover_crop, nlcd_cover_trim)

#Remove main variable to clean up environment
rm(nlcd_cover_nad83)


## NLCD Land Cover Change Index----
nlcd_change <- rast("Landsat_NLCD/NLCD_Land-Cover-Change-Index_2001-2021/nlcd_2001_2021_land_cover_change_index_l48_20230630.img")
plot(nlcd_change)

ecor_proj <- st_transform(ecor, crs(nlcd_change))
nlcd_change_crop <- mask(nlcd_change, ecor_proj)
nlcd_change_trim <- trim(nlcd_change_crop)
plot(nlcd_change_trim)

#project to nad83
st_can_transform(nlcd_change_trim, st.nad83) #True
nlcd_change_nad83 <- project(nlcd_change_trim, rast.nad83)
plot(nlcd_change_nad83)

#write raster file
writeRaster(x = nlcd_change_nad83,
            filename = 'Landsat_NLCD/NLCD_Land-Cover-Change-Index_ML_NAD83/NLCD_Land-Cover-Change-Index_ML_NAD83.tif')

#Save as RData
save(nlcd_change_nad83, file = "mid-lat/Mid-Lat R Project/nlcd_change-index.RData")

#Remove intermediate variables
rm(nlcd_change, nlcd_change_crop, nlcd_change_trim)

#Remove final variable to clean up environment
rm(nlcd_change_nad83)



# USDA Forest Type----

## Forest Group----
forest_grp <- rast("USDA_Forest_Type/conus_forest-group/conus_forestgroup.img")

ecor_proj <- st_transform(ecor, crs(forest_grp))
forest_grp_crop <- mask(forest_grp, ecor_proj)
forest_grp_trim <- trim(forest_grp_crop)
plot(forest_grp_trim)

#project to nad83
st_can_transform(forest_grp_trim, st.nad83) #True
forest_grp_nad83 <- project(forest_grp_trim, rast.nad83)
plot(forest_grp_nad83)

#write raster file
writeRaster(x = forest_grp_nad83,
            filename = 'USDA_Forest_Type/USDA_Forest-Group_ML_NAD83/USDA_Forest-Group_ML_NAD83.tif')

#Save as RData
save(forest_grp_nad83, file = "mid-lat/Mid-Lat R Project/forest_grp.RData")

# remove intermediate variables
rm(forest_grp, forest_grp_crop, forest_grp_trim)

#remove final variable to clean up environment
rm(forest_grp_nad83)


## Forest Type----
forest_type <- rast("USDA_Forest_Type/conus_forest-type/conus_foresttype.img")

ecor_proj <- st_transform(ecor, crs(forest_type))
forest_type_crop <- mask(forest_type, ecor_proj)
forest_type_trim <- trim(forest_type_crop)
plot(forest_type_trim)

#project to nad83
st_can_transform(forest_type_trim, st.nad83) #True
forest_type_nad83 <- project(forest_type_trim, rast.nad83)
plot(forest_type_nad83)

#write raster file
writeRaster(x = forest_type_nad83,
            filename = 'USDA_Forest_Type/USDA_Forest-Type_ML_NAD83/USDA_Forest-Type_ML_NAD83.tif')

#Save as RData
save(forest_type_nad83, file = "mid-lat/Mid-Lat R Project/forest_type.RData")

# remove intermediate variables
rm(forest_type, forest_type_crop, forest_type_trim)

#remove final variable to clean up environment
rm(forest_type_nad83)


# State Boundaries----
states <- read_sf('Shapefiles/State_Boundaries_WGS84')

# Removing noncontiguous territories: 'PR', 'AS', 'VI', 'HI', 'AK', 'GU', 'MP')

# PR = 14
# AK = 28
# AS = 38
# VI = 39
# HI = 43
# GU = 45
# MP = 46

states1 <- states[c(1:13, 15:27, 29:37, 40:42, 44, 47:56),]

states_nad83 <- st_transform(states1, st.nad83)
plot(states_nad83)

# Variable with only mid-latitude states (VA, MD, WV, PA, DC)
states_ML_nad83 <- states_nad83[c(4,5,19,35,37),]
plot(states_ML_nad83[1])

#write new shapefile
st_write(states_ML_nad83, 'Shapefiles/Census_State-Boundaries_ML_NAD83/Census_State-Boundaries_ML_NAD83.shp')

#save as RData
save(states_ML_nad83, file = "mid-lat/Mid-Lat R Project/states_ML_nad83.RData")

#Remove intermediate variables
rm(states, states1, states_nad83)

#Remove final variable to clean up environment
rm(states_ML_nad83)

# MTBS----

## Burned Area Perimeters----
# Load
mtbs_bap <- read_sf('MTBS/Burned_Area_Perimeters/mtbs_perims_DD.shp')
plot(mtbs_bap)

#Project
st_can_transform(mtbs_bap, st.nad83)
mtbs_bap_proj <- st_transform(mtbs_bap, st.nad83)

#Crop
mtbs_bap_nad83 <- st_join(mtbs_bap_proj, ecor, join = st_intersects)

sf_use_s2(FALSE)
mtbs_bap_nad83 <- st_intersection(mtbs_bap_proj, ecor)
plot(mtbs_bap_nad83)

# Write new shapefile
st_write(mtbs_bap_nad83, 'MTBS/MTBS_Burned-Area-Perimeters_ML_NAD83/MTBS_Burned-Area-Perimeters_ML_NAD83.shp')

# Save as RData
save(mtbs_bap_nad83, file = "mid-lat/Mid-Lat R Project/mtbs_bap_nad83.RData")

#Remove intermediate variables
rm(mtbs_bap, mtbs_bap_proj)

#Remove final variable to clean up environment
rm(mtbs_bap_nad83)


## Fire Occurrence----
# Load
mtbs_fo <- read_sf('MTBS/Fire_Occurrence/mtbs_FODpoints_DD.shp')
plot(mtbs_fo)

#Project
st_can_transform(mtbs_fo, st.nad83)
mtbs_fo_proj <- st_transform(mtbs_fo, st.nad83)

#Crop
mtbs_fo_nad83 <- st_intersection(mtbs_fo_proj, ecor)
plot(mtbs_fo_nad83)

# Write new shapefile
st_write(mtbs_fo_nad83, 'MTBS/MTBS_Fire-Occurrence_ML_NAD83/MTBS_Fire-Occcurrence_ML_NAD83.shp')

# Save as RData
save(mtbs_fo_nad83, file = "mid-lat/Mid-Lat R Project/mtbs_fo_nad83.RData")

#Remove intermediate variables
rm(mtbs_fo, mtbs_fo_proj)

#Remove final variable to clean up environment
rm(mtbs_fo_nad83)


## TODO: Burn Severity Mosaics----
all_list <- list.files(path = 'MTBS/Burn_Severity_Mosaics', pattern = '.tif')
all_list #39 files

aux_list <- list.files(path = 'MTBS/Burn_Severity_Mosaics', pattern = '.aux')
ovr_list <- list.files(path = 'MTBS/Burn_Severity_Mosaics', pattern = '.ovr')

file_list <- setdiff(all_list, aux_list)
file_list <- setdiff(file_list, ovr_list)
file_list

# extract years
years <- NULL
for (i in 1:length(file_list)){
  yr <- str_sub(string = file_list[i], start = -8, end = -5)
  years <- c(years,yr)
}

#reproject ecor to match mtbs
mtbs_proj <- rast('MTBS/Burn_Severity_Mosaics/mtbs_CONUS_1984.tif')
ecor_proj <- st_transform(ecor, crs(mtbs_proj))


#loop to load, crop, and project all of the files
for (i in 36:length(file_list)){
  nam <- paste('mtbs_nad83', years[i], sep = '_')
  nam <- paste(nam, '.tif', sep = '')
  rast <- rast(paste('MTBS/Burn_Severity_Mosaics', file_list[i], sep = '/'))
  rast_crop <- mask(rast, ecor_proj)
  rast_nad83 <- project(rast_crop, rast.nad83)
  writeRaster(rast_nad83, paste('MTBS/MTBS_Burn-Severity-Mosaics_ML_NAD83', nam, sep = '/'))
}


#remove intermediate files
rm(file_list, mtbs_proj, mtbs_bs, mtbs_bs_nad83, mtbs_proj, years, yr, nam, aux_list, all_list, ovr_list, rast, rast_crop, rast_nad83)



#GEDI----
## L3 Gridded Land Surface Metrics V2----
all_list <- list.files('GEDI/L3_Gridded_Land_Surface_Metrics_V2', pattern = '.tif')
all_list #includes aux.xml files and .sha256

aux_list <- list.files('GEDI/L3_Gridded_Land_Surface_Metrics_V2', pattern = '.aux')
sha256_list <- list.files('GEDI/L3_Gridded_Land_Surface_Metrics_V2', pattern = '.sha256')

file_list1 <- setdiff(all_list, aux_list)
file_list <- setdiff(file_list1, sha256_list)
file_list

rm(all_list, file_list1, aux_list, sha256_list)

gedi_L3 <- rast(paste('GEDI/L3_Gridded_Land_Surface_Metrics_V2', file_list[1], sep = '/'))
ecor_proj <- st_transform(ecor, crs(gedi_L3))

for (i in 2:length(file_list)){
  rast <- rast(paste('GEDI/L3_Gridded_Land_Surface_Metrics_V2', file_list[i], sep = '/'))
  rast_crop <- mask(rast, ecor_proj)
  rast_nad83 <- project(rast_crop, rast.nad83)
  writeRaster(rast_nad83, paste('GEDI/GEDI_L3_ML_NAD83', file_list[i], sep = '/'))
}

#remove variables to keep environment clean
rm(gedi_L3, file_list, rast, rast_crop, rast_nad83)

## TODO: L4A Footprint Level AGB----
all_list <- list.files('GEDI/L4A_Footprint_Level_AGB', pattern = '.h5')
all_list #includes .sha256

sha256_list <- list.files('GEDI/L4A_Footprint_Level_AGB', pattern = '.sha256')

file_list <- setdiff(all_list, sha256_list)
file_list

rm(all_list, sha256_list)


## TODO: L4B Gridded ABG Density----

# MODIS-VIIRS----
## Burned Area Monthly----
file_list <- list.files('MODIS_VIIRS/Burned_Area_Monthly', pattern = '.hdf') #original file name
file_names <- paste(str_sub(file_list, start = 1, end = -5), '.tif', sep = '') #destination file name

#load in one file to set projection
bam <- rast('MODIS_VIIRS/Burned_Area_Monthly/MCD64A1.A2000306.h11v05.061.2021307220204.hdf')
ecor_proj <- st_transform(ecor, crs(bam))

for (i in 1:length(file_list)){
  bam <- rast(paste('MODIS_VIIRS/Burned_Area_Monthly', file_list[i], sep = '/'))
  bam_mask <- mask(bam, ecor_proj)
  bam_trim <- trim(bam_mask)
  bam_nad83 <- project(bam_trim, rast.nad83)
  writeRaster(x = bam_nad83,
              filename = paste('MODIS_VIIRS/MODIS_Burned-Area-Monthly_ML_NAD83', file_names[i], sep = '/'))
}

# Not saving this one as RData since it is a lot of separate files, and extents/nrow/ncol were not wanting to match up to stack the rasters

#Remove variables to clean up environment
rm(bam, bam_mask, bam_trim, bam_nad83)

## Global Fire Atlas----
all_list <- list.files('MODIS_VIIRS/Global_Fire_Atlas', pattern = '.tif') #includes .sha256 files
sha256_list <- list.files('MODIS_VIIRS/Global_Fire_Atlas', pattern = '.sha256')
file_list <- setdiff(all_list, sha256_list)
file_list

#not working to transform, so going to have to project before cropping
##gfa <- rast('MODIS_VIIRS/Global_Fire_Atlas/Global_fire_atlas_day_of_burn_yearly_2003.tif')
##ecor_proj <- st_transform(ecor, crs(gfa))


for (i in 36:length(file_list)){
  gfa <- rast(paste('MODIS_VIIRS/Global_Fire_Atlas', file_list[i], sep = '/'))
  gfa_nad83 <- project(gfa, rast.nad83)
  gfa_mask <- mask(gfa_nad83, ecor)
  writeRaster(x = gfa_mask,
  filename = paste('MODIS_VIIRS/MODIS_Global-Fire-Atlas_ML_NAD83', file_list[i], sep = '/'))
}

#had to remove trim() step because some of them had NA's only which prompted an error on the trim.

#Remove variables to clean up environment
rm(all_list, file_list, sha256_list, gfa, gfa_mask, gfa_nad83)


## TODO: Land Water Mask----
file_list <- list.files('MODIS_VIIRS/Land_Water_Mask', pattern = '.hdf') #original file name
file_names <- paste(str_sub(file_list, start = 1, end = -5), '.tif', sep = '') #destination file name

#load in one file to set projection
lwm <- rast('MODIS_VIIRS/Land_Water_Mask/MOD44W.A2000001.h11v05.006.2018033150712.hdf')
ecor_proj <- st_transform(ecor, crs(lwm))

for (i in 1:length(file_list)){
  lwm <- rast(paste('MODIS_VIIRS/Land_Water_Mask', file_list[i], sep = '/'))
  lwm_mask <- mask(lwm, ecor_proj)
  lwm_trim <- trim(lwm_mask)
  lwm_nad83 <- project(lwm_trim, rast.nad83)
  writeRaster(x = lwm_nad83,
              filename = paste('MODIS_VIIRS/MODIS_Land-Water-Mask_ML_NAD83', file_names[i], sep = '/'))
}

# Not saving this one as RData since it is a lot of separate files, and extents/nrow/ncol were not wanting to match up to stack the rasters

#Remove variables to clean up environment
rm(lwm, lwm_mask, lwm_trim, lwm_nad83)