################################################################################
#
# This is the data preparation file for developer, which records all the raw
# data sources and the initial clean ups of the data.
#
# Please note that this file is not meant for users to run.
#
################################################################################

# load libraries
library(tibble)
library(dplyr)
library(raster)
library(sf)
library(sp)
library(usethis)
library(ggplot2)

#-------------------------------------------------------------------------------
# Initialize
#-------------------------------------------------------------------------------

climate_data.dir <- 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data'
model_data.dir <- 'C:/WorkSpace/GCIMS/GCIMS_Yield/regression_analysis/data'
mirca.dir <- file.path(climate_data.dir, 'MIRCA2000')
gcam_boundary.dir <- file.path(climate_data.dir, 'gcam_boundaries_moirai_3p1_0p5arcmin_wgs84')
agprodchange.dir <- file.path(model_data.dir, 'data_ext')
gcam6.dir <- 'C:/WorkSpace/GCAM-Models/gcam-v6.0/input/gcamdata/outputs'
gcam7.dir <- 'C:/WorkSpace/github/gcam-core/input/gcamdata/outputs'

#===============================================================================
#'* External Data *
#===============================================================================
# Save data to data/.rds file

#-------------------------------------------------------------------------------
# Historical CO2 concentration
#-------------------------------------------------------------------------------
co2_historical <- data.table::fread(
  file = file.path(model_data.dir, 'data_raw', 'hist_co2_conc.csv'),
  skip = 1, header = T)
usethis::use_data(co2_historical, overwrite = TRUE)


#-------------------------------------------------------------------------------
# Reference Future CO2 concentration
#-------------------------------------------------------------------------------
co2 <- read.csv(
  file = file.path(model_data.dir, 'data_ext', 'gcam7', 'ref_CO2_concentrations.csv'),
  skip = 1, header = T) %>%
  dplyr::select(`X1980`:`X2100`) %>%
  tidyr::pivot_longer(tidyr::everything(), names_to = 'year', values_to = 'value') %>%
  dplyr::mutate(year = as.integer(gsub('X', '', year))) %>%
  # add 1951 value based on historical part of the co2_rcp4p5_8p5_1951_2099.csv
  dplyr::bind_rows(data.frame(year = 1951, value = 311.1)) %>%
  dplyr::arrange(year)

co2_conc <- approx(x = co2$year, y = co2$value, method = 'linear',
                   xout = seq(1951, 2100, 1))
co2_projection <- data.frame(year = co2_conc$x, co2_conc = co2_conc$y)

usethis::use_data(co2_projection, overwrite = TRUE)


#-------------------------------------------------------------------------------
# Reference Agricultural Productivity Change
#-------------------------------------------------------------------------------
# Reference APG files are from GCAM 6 and 7 depending on the version specified
# for GCAM 6 and 7 at 5-year period
for(gcam_version in c('gcam6', 'gcam7')){

  if(gcam_version == 'gcam6'){
    gcamdata.dir <- gcam6.dir
  }

  if(gcam_version == 'gcam7'){
    gcamdata.dir <- gcam7.dir
  }

  agprodchange_ni_gcam <- dplyr::bind_rows(
    data.table::fread(file.path(gcamdata.dir, 'L2052.AgProdChange_irr_high.csv')) %>%
      mutate(group = 'high'),
    data.table::fread(file.path(gcamdata.dir, 'L2052.AgProdChange_irr_low.csv')) %>%
      mutate(group = 'low'),
    data.table::fread(file.path(gcamdata.dir, 'L2052.AgProdChange_irr_ssp4.csv')) %>%
      mutate(group = 'ssp4'),
    data.table::fread(file.path(gcamdata.dir, 'L2052.AgProdChange_ag_irr_ref.csv')) %>%
      mutate(group = 'ref')
  ) %>%
    tidyr::pivot_wider(names_from = 'group', values_from = 'AgProdChange') %>%
    dplyr::bind_rows(
      data.table::fread(file.path(gcamdata.dir, 'L2052.AgProdChange_bio_irr_ref.csv')) %>%
        dplyr::mutate(high = AgProdChange,
                      low = AgProdChange,
                      ssp4 = AgProdChange,
                      ref = AgProdChange) %>%
        dplyr::select(-AgProdChange)
    )

  agprodchange_ni_gcam <- agprodchange_ni_gcam %>%
    tidyr::expand(tidyr::nesting(region, AgSupplySector, AgSupplySubsector, AgProductionTechnology),
                  year = seq(2015, 2100, 5)) %>%
    dplyr::left_join(agprodchange_ni_gcam) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~tidyr::replace_na(.x, 0))) %>%
    dplyr::mutate(year = paste0('X', year))

  if(gcam_version == 'gcam6'){
    agprodchange_ni_gcam6 <- agprodchange_ni_gcam
  }

  if(gcam_version == 'gcam7'){
    agprodchange_ni_gcam7 <- agprodchange_ni_gcam
  }

}

usethis::use_data(agprodchange_ni_gcam6, overwrite = TRUE)
usethis::use_data(agprodchange_ni_gcam7, overwrite = TRUE)



#-------------------------------------------------------------------------------
# Regression output from the default country level historical climate data
#-------------------------------------------------------------------------------

# This serves as the default regression relationship if no historical climate data
# is provided
coef_default <- data.table::data.table()
for(crop_name in mapping_mirca_sage$crop_mirca){
  coef_crop <- gaia::input_data(folder_path = 'C:/WorkSpace/GCIMS/GCIMS_Yield/regression_analysis/output/20230706_0942/data_processed',
                                input_file =  paste("reg_out_", crop_name, "_", fit_name, ".csv", sep = ""),
                                skip_number = 0 )
  coef_default <- dplyr::bind_rows(
    coef_default,
    coef_crop %>% dplyr::mutate(crop = crop_name)
  )

}

usethis::use_data(coef_default, overwrite = TRUE)


# country names and ids (from Stephanie's ag yield data)
country_id <- data.table::fread(file.path(climate_data.dir, 'country_id.csv')) %>%
  dplyr::rename(country_id = ID,
                country_name = NAME,
                iso = ISO3)

usethis::use_data(country_id, overwrite = TRUE)

#===============================================================================
#'* Internal Data *
#===============================================================================

#-------------------------------------------------------------------------------
# Country Mapping
#-------------------------------------------------------------------------------

# FAO country from gcam boundary dataset (from https://zenodo.org/record/4688451)
country_fao <- data.table::fread(file.path(gcam_boundary.dir,
                                           'spatial_input_files',
                                           'FAO_iso_VMAP0_ctry.csv')) %>%
  dplyr::mutate(iso3 = toupper(iso3_abbr)) %>%
  dplyr::select(fao_code, iso = iso3, fao_name)

# merge
mapping_country <- dplyr::full_join(country_fao, country_id, by = 'iso') %>%
  dplyr::select(country_id, country_name, iso, fao_code, fao_name) %>%
  dplyr::arrange(country_id) %>%
  dplyr::filter(!is.na(country_name)) %>%
  tibble::as_tibble()


#-------------------------------------------------------------------------------
# GCAM GLU-Country intersection Mapping
#-------------------------------------------------------------------------------

# Mapping with country defined by FAO and GLU defined by GCAM at 0.5 degree
# Note: 0.5 deg pixels fraction bounded by country and 0.5 deg pixels fraction bounded by glu (basin)
# 1. cell_area_x: 0.5 deg pixel area intersected by x
# 2. Zone fraction_x: this is the portion of the polygon x from the pixel over the entire polygon
# 3. Cell_fraction_x: this is the portion of the cell that is covered by an individual polygon x. Each cell can now be covered by multiple polygons.
# 4. We also retain lat, lon info for each pixel so that you can join with any dataset at the same resolution.
fao_glu_mapping <- data.table::fread(file.path(climate_data.dir, 'MIRCA_0.5deg_ctry_GLU.csv')) %>%
  dplyr::rename(lon = Longitude,
                lat = Latitude,
                fao_code = ctry_id,
                ctry_area = country_area) %>%
  dplyr::select(-key, -cell_id, -zone_frac) %>%
  dplyr::filter(!(cell_area_ctry == 0 & cell_area_GLU == 0)) %>%
  dplyr::distinct()

# Mapping of intersection between country defined by FAO and GLU defined by GCAM at 0.5 degree
# Note: 0.5 deg pixels fraction bounded by country and glu (basin) intersection
# 1. Zone fraction: this is the portion of the intersected polygon from the pixel over the entire polygon
# 2. Cell_fraction: this is the portion of the cell that is covered by an individual intersected polygon. Each cell can now be covered by multiple polygons.
# 3. polygon_area: area of the intersected polygon
fao_glu_intersect_mapping <- data.table::fread(file.path(climate_data.dir, 'MIRCA_GCAM_Intersections_0.5deg.csv')) %>%
  dplyr::rename(lon = Longitude,
                lat = Latitude,
                fao_code = ctry_id,
                intersect_area = polygon_area,
                cell_area_intersect = part_area) %>%
  dplyr::left_join(country_fao %>% dplyr::mutate(fao_name = gsub(' ', '', fao_name)),
                   by = 'fao_code') %>%
  dplyr::mutate(ctry_nm = ifelse(ctry_nm == '#N/A', fao_name, ctry_nm)) %>%
  dplyr::select(-key, -cell_id, -cell_area, -zone_frac)

grid_fao_glu <- fao_glu_intersect_mapping %>%
  dplyr::select(lon, lat, iso, fao_name, glu_id, glu_name = glu_nm) %>%
  dplyr::distinct()

# merge them together
# glu is gcam basin, ctry_nm is GCAM country name
mapping_fao_glu <- fao_glu_intersect_mapping %>%
  dplyr::inner_join(fao_glu_mapping,
                   by = c('lon', 'lat', 'glu_id', 'glu_nm', 'fao_code'),
                   suffix = c('_intersect', '')) %>%
  # dplyr::filter(!is.na(ctry_nm)) %>%
  dplyr::group_by(fao_code) %>%
  tidyr::fill(ctry_nm, .direction = 'downup') %>%
  dplyr::ungroup() %>%
  dplyr::select(lat, lon, glu_id, glu_name = glu_nm, fao_code, fao_name, country_name = ctry_nm, iso,
                cell_area, glu_area = GLU_area, ctry_area, intersect_area,
                cell_area_glu = cell_area_GLU, cell_area_ctry, cell_area_intersect,
                cell_frac_glu = cell_frac_GLU, cell_frac_ctry, cell_frac_intersect = cell_frac) %>%
  tidyr::replace_na(list(intersect_area = 0, cell_area_intersect = 0, cell_frac_intersect = 0))


#-------------------------------------------------------------------------------
# MIRCA cropland area (m2)
#-------------------------------------------------------------------------------

# MIRCA2000
# Portmann, F. T., Siebert, S., & Döll, P. (2010). MIRCA2000 (1.1) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.7422506
# cropland area file list
crop_area_list <- list.files(
  file.path(climate_data.dir, 'MIRCA2000', 'harvested_area_grids_26crops_30mn'),
  full.names = TRUE)

# convert ASCII files to raster bick
ras_brick <- raster::stack(crop_area_list)

# get lon lat from MIRCA
lonlat <- sp::SpatialPoints(cbind(lon = fao_glu_mapping$lon,
                                  lat = fao_glu_mapping$lat))

# get crop area by lon lat
grid <- dplyr::bind_cols(
  raster::as.data.frame(raster::extract(x = ras_brick, y = lonlat,  sp = T))) %>%
  tibble::as_tibble()

# update names
name_orig <- names(ras_brick)
name_new <- stringr::str_replace_all(name_orig, c('annual_area_harvested_|_ha_30mn'), '')

grid <- grid %>%
  dplyr::rename(setNames(c(name_orig, 'lon', 'lat'),
                         c(name_new, 'lon', 'lat')))

# convert area unit from ha to m2
mirca_harvest_area <- grid %>%
  dplyr::mutate(dplyr::across(-c(lon, lat), ~. * 10000))

attr(mirca_harvest_area, 'unit') <- 'm2'


#-------------------------------------------------------------------------------
# ISO Mapping
#-------------------------------------------------------------------------------
mapping_gcam_iso <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_raw'),
  input_file = 'iso_GCAM_regID_name.csv',
  skip_number = 0)


#-------------------------------------------------------------------------------
# rmap Mapping
#-------------------------------------------------------------------------------

# mapping from rmap [lon, lat, region_id, region_name, glu_id, glu_nm, ctry_id, ctry_nm]
mapping_rmap_grid <- rmap::mapping_tethys_grid_basin_region_country %>%
  dplyr::select(lon, lat,
                region_id = regionID, region_name = regionName,
                glu_id = basinID, glu_name = basinName,
                country_id = countryID, country_name = countryName)

mapping_rmap_gcambasins <- rmap::mapping_gcambasins

mapping_rmap_gcamregions <- rmap::mapping_country_gcam32 %>% dplyr::select(region_code, region) %>% dplyr::distinct()


#-------------------------------------------------------------------------------
# SAGE Data
#-------------------------------------------------------------------------------
# crop calendar dataset
# https://sage.nelson.wisc.edu/data-and-models/datasets/crop-calendar-dataset/
sage <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_raw'),
  input_file = 'SAGE_All_data_with_climate.csv',
  skip_number = 0)

sage <- sage %>%
  dplyr::select(-V1)


#-------------------------------------------------------------------------------
# FAO Data - Irrigation Equip
#-------------------------------------------------------------------------------
fao_irr_equip <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_raw'),
  input_file = 'fao_irr_equip.csv',
  skip_number = 0
)

fao_irr_equip <- fao_irr_equip %>%
  dplyr::rename(irr_equip = value) %>%
  dplyr::select(-V1)


#-------------------------------------------------------------------------------
# GDP
#-------------------------------------------------------------------------------
gdp <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_raw'),
  input_file = "pwt_gdp_pcap_ppp.csv",
  skip_number = 0)

gdp <- gdp %>%
  dplyr::rename(gdp_pcap_ppp = gdp_pcap_ppp_thous) %>%
  dplyr::select(-V1)

#-------------------------------------------------------------------------------
# Mapping of FAO crops to MIRCA2000
#-------------------------------------------------------------------------------

# Source: supporting information from Portmann, F. T., Siebert, S., & Döll, P. (2010). MIRCA2000—Global monthly irrigated and rainfed crop areas around the year 2000: A new high‐resolution data set for agricultural and hydrological modeling. Global biogeochemical cycles, 24(1). https://doi.org/10.1029/2008GB003435
# Manually added the FAO Item Code based on the FAOSTAT data https://www.fao.org/faostat/en/#data/QCL, accessed Feb 2025
# Note that FAOSTAT has updated the crop names/groups since MIRCA2000, so there are few FAO crops listed in Portmann et al., 2010 are not available from the latest FAOSTAT.
fao_to_mirca <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_ext'),
  input_file = 'mirca2000_fao_crop_mapping_edit.csv',
  skip_number = 0) %>%
  dplyr::filter(!is.na(fao_crop_id))
# colnames(fao_to_mirca) <- c('fao_crop', paste('crop', sprintf('%02d', 1:26), sep = ''))

#-------------------------------------------------------------------------------
# FAOSTAT Country ISO mapping
#-------------------------------------------------------------------------------
# FAOSTAT data https://www.fao.org/faostat/en/#data/QCL
fao_iso <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_ext', 'FAO_Production_Crops_Livestock_E_All_Data'),
  input_file = 'FAOSTAT_Area_Code.csv',
  skip_number = 0) %>%
  dplyr::select(country_code = `Country Code`,
                country_name = Country,
                iso = `ISO3 Code`) %>%
  dplyr::mutate(iso = tolower(iso)) %>%
  dplyr::distinct()


#-------------------------------------------------------------------------------
# FAO Data - Harvested Area
#-------------------------------------------------------------------------------
# fao_yield <- gaia::input_data(
#   folder_path = file.path(model_data.dir, 'data_raw'),
#   input_file = 'FAO_yield_ha.csv',
#   skip_number = 0
# )

# Latest full FAO production data from https://www.fao.org/faostat/en/#data/QCL, accessed Feb 2025
fao_yield <- gaia::input_data(
  folder_path = file.path(model_data.dir, 'data_ext', 'FAO_Production_Crops_Livestock_E_All_Data'),
  input_file = 'Production_Crops_Livestock_E_All_Data_NOFLAG.csv',
  skip_number = 0
)

fao_yield <- gaia::clean_yield(fao_yield = fao_yield,
                               fao_to_mirca = fao_to_mirca)

#-------------------------------------------------------------------------------
# MIRCA Crop Mapping
#-------------------------------------------------------------------------------
crop_mirca <- tibble::tribble(
  ~ crop_id, ~ crop,              ~ crop_name,        ~ crop_sage,
  "crop01", "wheat",              "wheat",            "wheat",
  "crop02", "maize",              "maize",            "maize",
  "crop03", "rice",               "rice",             "rice",
  "crop04", "barley",             "barley",           "barley",
  "crop05", "rye",                "rye",              "rye",
  "crop06", "millet",             "millet",           "millet",
  "crop07", "sorghum",            "sorghum",          "sorghum",
  "crop08", "soybean",            "soybean",          "soybeans",
  "crop09", "sunflower",          "sunflower",        "sunflower",
  "crop10", "potatoes",           "root_tuber",       "potatoes",
  "crop11", "cassava",            "cassava",          "cassava",
  "crop12", "sugarcane",          "sugarcane",        "sugarcane",
  "crop13", "sugarbeet",          "sugarbeet",        "sugarbeets",
  "crop14", "oil palm",           "oil_palm",         NA,
  "crop15", "rape seed,canola",   "rape_seed",        "rapeseed",
  "crop16", "groundnuts,peanuts", "groundnuts",       "groundnuts",
  "crop17", "pulses",             "pulses",           "pulses",
  "crop18", "citrus",             "citrus",           NA,
  "crop19", "date palm",          "date_palm",        NA,
  "crop20", "grapes,vine",        "grapes",           NA,
  "crop21", "cotton",             "cotton",           "cotton",
  "crop22", "cocoa",              "cocoa",            NA,
  "crop23", "coffee",             "coffee",           NA,
  "crop24", "others perennial",   "others_perennial", NA,
  "crop25", "fodder grasses",     "fodder_grasses",   NA,
  "crop26", "others annual",      "others_annual",    NA
)


#-------------------------------------------------------------------------------
# GCAM Commodity Mapping
#-------------------------------------------------------------------------------
# only mapped MIRCA crops to GCAM commodity
gcam_commod <- tibble::tribble(
  ~GCAM_commod, ~crop, ~crop_type,
  "biomass", "maize", "Grass",
  "biomass", "sorghum", "Grass",
  "biomass", "sugarcane", "Grass",
  "biomass", "fodder_grasses", "Grass",
  "Corn", "maize", "C4",
  "FiberCrop", "cotton", "",
  "FodderHerb", "maize", "C4",
  "FodderHerb", "sorghum", "C4",
  "Fruits", "rice", "",
  "Fruits", "wheat", "",
  "Fruits", "citrus", "Tree",
  "Fruits", "date_palm", "Tree",
  "Fruits", "grapes", "",
  "Legumes", "maize", "",
  "Legumes", "wheat", "",
  "Legumes", "pulses", "",
  "MiscCrop", "rice", "",
  "MiscCrop", "wheat", "",
  "MiscCrop", "coffee", "Tree",
  "MiscCrop", "cocoa", "Tree",
  "MiscCrop", "others_perennial", "",
  "MiscCrop", "others_annual", "",
  "NutsSeeds", "rice", "",
  "NutsSeeds", "wheat", "",
  "NutsSeeds", "groundnuts", "",
  "OilCrop", "soybean", "",
  "OilCrop", "sunflower", "",
  "OilCrop", "rape_seed", "",
  "OilCrop", "groundnuts", "",
  "OilPalm", "rice", "",
  "OilPalm", "wheat", "",
  "OilPalm", "oil_palm", "Tree",
  "OtherGrain", "rice", "",
  "OtherGrain", "sorghum", "C4",
  "OtherGrain", "wheat", "",
  "OtherGrain", "barley", "",
  "OtherGrain", "rye", "",
  "OtherGrain", "millet", "C4",
  "Rice", "rice", "",
  "RootTuber", "root_tuber", "",
  "RootTuber", "potato", "",
  "RootTuber", "cassava", "",
  "Soybean", 'soybean', "",
  "SugarCrop", "sugarcane", "C4",
  "SugarCrop", "sugarbeet", "",
  "Vegetables", "rice", "",
  "Vegetables", "wheat", "",
  "Wheat", "wheat", ""
)

#-------------------------------------------------------------------------------
# Selected Crops
#-------------------------------------------------------------------------------
mapping_mirca_sage <- tibble::tibble(
  crop_mirca = c('wheat', 'sorghum', 'maize', 'rice', 'soybean', 'sugarcane', 'sugarbeet', 'cotton', 'cassava', 'root_tuber', 'sunflower'),
  crop_sage = c('wheat', 'sorghum', 'maize', 'rice', 'soybeans', 'sugarcane', 'sugarbeets', 'cotton', 'cassava', 'potatoes', 'sunflower')
)


#-------------------------------------------------------------------------------
# Default Regression Formula
#-------------------------------------------------------------------------------

# default formula from Waldhoff et al., 2020 DOI: 10.1088/1748-9326/abadcb
waldhoff_formula <- "ln_yield ~ year + temp_mean + temp_mean_2 + temp_max + temp_max_2 + temp_min + temp_min_2 +
precip_mean + precip_mean_2 + precip_max + precip_max_2 + precip_min + precip_min_2 + factor( iso )"

# yield equation
y_hat <- "temp_mean*(d$temp_mean) + temp_mean_2*(d$temp_mean_2) +
          temp_max*(d$temp_max) + temp_max_2*(d$temp_max_2) +
          temp_min*(d$temp_min) + temp_min_2*(d$temp_min_2) +
          precip_mean*(d$precip_mean) + precip_mean_2*(d$precip_mean_2) +
          precip_max*(d$precip_max) + precip_max_2*(d$precip_max_2) +
          precip_min*(d$precip_min) + precip_min_2*(d$precip_min_2)"

# regression variables
reg_vars <- c( "iso", "GCAM_region_name", "area_harvest", "yield", "ln_yield", "year", #"gdp_pcap_ppp", #"co2_conc", #"co2_conc_2",
               "temp_mean", "temp_mean_2", #"temp_mean_3", "temp_mean_4",
               "temp_max", "temp_max_2", #"temp_max_3", "temp_max_4",
               "temp_min", "temp_min_2", #"temp_min_3", "temp_min_4",
               "precip_mean", "precip_mean_2", #"precip_mean_3", "precip_mean_4")#,
               "precip_max", "precip_max_2", #"precip_max_3", "precip_max_4",
               "precip_min", "precip_min_2")#, "precip_min_3", "precip_min_4" )

# variable to be used to weight
weight_var <- "area_harvest"

# p value for including variables
n_sig <- 0.1

# fit name to label the fitting specifications
fit_name <- "fit_lnyield_mmm_quad_noco2_nogdp"



#-------------------------------------------------------------------------------
# GCAM region color definition
#-------------------------------------------------------------------------------
## GCAM region color definition
region_color <- c( "Africa_Eastern" = "olivedrab2",
                   "Africa_Northern" = "darkgreen",
                   "Africa_Southern" = "green4",
                   "Africa_Western" = "olivedrab3",
                   "Argentina" = "mediumpurple",
                   "Australia_NZ" = "cornflowerblue",
                   "Brazil" = "mediumpurple4",
                   "Canada" = "chocolate1",
                   "Central America and Caribbean" = "darkorchid4",
                   "Central Asia" = "firebrick1",
                   "China" = "firebrick4",
                   "Colombia" = "magenta4",
                   "EU-12" = "dodgerblue4",
                   "EU-15" = "dodgerblue3",
                   "Europe_Eastern" = "deepskyblue3",
                   "Europe_Non_EU" = "cadetblue2",
                   "European Free Trade Association" = "cadetblue",
                   "India" = "indianred",
                   "Indonesia" = "firebrick2",
                   "Japan" = "deeppink4",
                   "Mexico" = "orchid4",
                   "Middle East" = "darkolivegreen3",
                   "Pakistan" = "indianred4",
                   "Russia" = "red4",
                   "South Africa" = "olivedrab4",
                   "South America_Northern" = "purple4",
                   "South America_Southern" = "purple2",
                   "South Asia" = "indianred2",
                   "South Korea" = "deeppink3",
                   "Southeast Asia" = "red3",
                   "Taiwan" = "deeppink3",
                   "USA" = "chocolate3" )

# color scale
col_scale_region <- ggplot2::scale_color_manual( name = "gcam_region", values = region_color )

# fill scale
col_fill_region <- ggplot2::scale_fill_manual( name = "gcam_region", values = region_color )

# define theme
theme_basic <- ggplot2::theme_bw() +
  ggplot2::theme(
    legend.text = ggplot2::element_text( size = 16, vjust = .5 ),
    legend.title = ggplot2::element_text( size = 16, vjust = 2 ),
    axis.text = ggplot2::element_text( size = 16 ),
    axis.title = ggplot2::element_text( size = 20, face = "bold" ),
    plot.title = ggplot2::element_text( size = 24, face = "bold", vjust = 1 ),
    strip.text = ggplot2::element_text( size = 14 ) )


#-------------------------------------------------------------------------------
# World map: countries
#-------------------------------------------------------------------------------

library(rnaturalearth)

sf_country <- rnaturalearth::ne_countries(returnclass = "sf", scale = 'medium')

sf_country <- sf_country %>%
  dplyr::select(country_name = admin,
                iso = adm0_a3) %>%
  dplyr::mutate(source = "rnaturalearth::ne_countries()",
                country_name = as.character(country_name),
                country_name = ifelse(country_name == "United States of America", "USA", country_name))

sf_country <- sf_country[!grepl("Antarctica", sf_country$country_name), ]

area_thresh <- units::set_units(50, km^2)
sf::sf_use_s2(FALSE)
area <- sf::st_area(sf_country)
sf_country <- sf_country %>%
  dplyr::mutate(area = area)

map_country <- sf_country %>%
  dplyr::select(country_name, iso, area, source, geometry)

sf::st_crs(map_country) <- 4326




#'*Save All Internal Data*
#'=========================
usethis::use_data(mapping_country, grid_fao_glu, mapping_fao_glu, mapping_gcam_iso,
                  crop_mirca, gcam_commod, mapping_mirca_sage,
                  mapping_rmap_grid, mapping_rmap_gcambasins, mapping_rmap_gcamregions,
                  mirca_harvest_area, sage, fao_yield, fao_irr_equip, gdp,
                  waldhoff_formula, y_hat, reg_vars, weight_var, n_sig, fit_name,
                  col_scale_region, col_fill_region, theme_basic,
                  map_country, fao_to_mirca, fao_iso,
                  internal = TRUE, overwrite = TRUE )
