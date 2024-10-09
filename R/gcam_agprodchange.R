
#' This script includes the following functions:
#' mirca_to_gcam
#' get_mirca_cropland
#' get_cropland_weight
#' get_weighted_yield_impact
#' get_agprodchange
#' gcam_agprodchange


# -----------------------------------------------------------------------------
#' mirca_to_gcam
#'
#' Mapping between GCAM region, GLU, country
#' Mapping from mirca crop to GCAM commodities
#'
#' @param gcam_version Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @keywords internal
#' @export

mirca_to_gcam <- function(gcam_version = 'gcam7',
                          climate_scenario= NULL)
{

  subRegionMap <- country_name <- AgSupplySector <- crop_type <- GCAM_commod <-
    crop_type.x <- crop_type.y <- crop <- region <- AgSupplySubsector <- glu <-
    iso <- fao_name <- glu_id <- glu_name <- lon <- lat <- regionID <-
    regionName <- basinID <- basinName <- countryID <- countryName <-
    region_code <- NULL

  # ----------------------------------------------------------------------------
  # Load data
  # ----------------------------------------------------------------------------
  # input reference ag productivity change
  # note that different GCAM versions will have different agprodchange structure
  agprodchange_ni <- agprodchange_ref(gcam_version = gcam_version,
                                      climate_scenario = climate_scenario)


  # ----------------------------------------------------------------------------
  # mapping
  # ----------------------------------------------------------------------------

  # Spatial Mapping
  # GCAM agriculture sector mapping [region, glu]
  mp_glu <- agprodchange_ni %>%
    dplyr::select(region, AgSupplySubsector) %>%
    tidyr::separate(AgSupplySubsector, into = c('crop', 'glu'), sep = '_') %>%
    dplyr::select(region, glu) %>%
    dplyr::distinct() %>%
    tibble::as_tibble()

  # GCAM mapping file [GCAM_region_ID, iso, country_name, GCAM_region_name]
  mp_iso <- mapping_gcam_iso %>%
    dplyr::mutate(country_name = dplyr::case_when(
      country_name == 'Iran, Islamic Republic of' ~ 'Iran',
      country_name == 'Korea, Democratic Peoples Republic of' ~ 'North Korea',
      country_name == 'Korea, Republic of' ~ 'South Korea',
      country_name == 'Libyan Arab Jamahiriya' ~ 'Libya',
      country_name == 'Syrian Arab Republic' ~ 'Syria',
      country_name == 'Tanzania, United Republic of' ~ 'Tanzania',
      country_name == 'United States of America' ~ 'United States',
      TRUE ~ country_name ) )

  # MIRCA country-glu intersection mapping, with iso joined
  # [iso, fao_name, glu_id, glu_nm, GCAM_region_ID, country_name, GCAM_region_name]
  mp_mirca <- grid_fao_glu %>%
    dplyr::select(iso, fao_name, glu_id, glu_name) %>%
    dplyr::mutate(iso = tolower(iso)) %>%
    dplyr::mutate(glu_name = gsub('_Basin', '', glu_name),
                  glu_name = dplyr::case_when(
                    glu_name == 'Hong_(Red_River)' ~ 'Hong_Red_River',
                    glu_name == 'HamuniMashkel' ~ 'Hamun_i_Mashkel',
                    glu_name == 'Rh(ne' ~ 'Rhone',
                    glu_name == 'Rfo_Lerma' ~ 'Rio_Lerma',
                    glu_name == 'Rfo_Verde' ~ 'Rio_Verde',
                    glu_name == 'Rfo_Balsas' ~ 'Rio_Balsas',
                    TRUE ~ glu_name )) %>%
    dplyr::distinct() %>%
    dplyr::left_join(mp_iso, by = c('iso'))

  # mapping from rmap [lon, lat, region_id, region_name, glu_id, glu_nm, ctry_id, ctry_nm]
  mp_rmap <- mapping_rmap_grid

  # mapping from rmap [region_id, region_name, glu_id, glu_nm, ctry_id, ctry_nm]
  # mp_ctry_glu_reg <- mp_rmap %>%
  #   dplyr::select(-lon, -lat) %>%
  #   dplyr::filter(!is.na(region_name)) %>%
  #   dplyr::distinct()

  # final mapping for GCAM ag
  mp_gcam <- mp_glu %>%
    dplyr::left_join(mapping_rmap_gcambasins, by = c('glu' = 'subRegion')) %>%
    dplyr::left_join(mp_mirca, by = c('region' = 'GCAM_region_name', 'subRegionMap' = 'glu_name')) %>%
    dplyr::left_join(mapping_rmap_gcamregions,
                     by = c('region')) %>%
    # dplyr::left_join(d.iso %>%  dplyr::select(iso, country_name),
    #                  by = c('iso') )%>%
    dplyr::distinct() %>%
    dplyr::select(region_id = region_code, region_name = region,
                  basin_id = glu_id, basin_name = subRegionMap, glu,
                  country_name, fao_name, iso)


  # GCAM Commodity Mapping
  # commodity extraction from the reference ag prod change data
  # this subjects to change based on the GCAM version

  gcam_commod_ref <- agprodchange_ni %>%
    tidyr::separate(AgSupplySubsector, into = c('crop_type', 'GLU')) %>%
    dplyr::select(AgSupplySector, crop_type) %>%
    dplyr::distinct() %>%
    dplyr::group_by(crop_type) %>%
    dplyr::mutate(crop_type = gsub(AgSupplySector, '', crop_type)) %>%
    dplyr::ungroup() %>%
    dplyr::rename(GCAM_commod = AgSupplySector)

  temp <- gcam_commod %>%
    dplyr::select(-crop_type) %>%
    dplyr::left_join(gcam_commod_ref %>%
                       dplyr::filter(GCAM_commod %in% GCAM_commod[crop_type %in% 'Tree']),
                     by = c('GCAM_commod'))


  gcam_commod_fill <- temp %>%
    dplyr::left_join(gcam_commod, by = c('GCAM_commod', 'crop')) %>%
    dplyr::mutate(crop_type = dplyr::if_else(is.na(crop_type.x), crop_type.y, crop_type.x)) %>%
    dplyr::select(-crop_type.x, -crop_type.y)

  # Clean input data
  gcam_commod_fill <- dplyr::filter(gcam_commod_fill, crop != "sunflower")

  return(list(mp_iso = mp_iso,
              mp_rmap = mp_rmap,
              mp_gcam = mp_gcam,
              mp_gcam_commod = gcam_commod_fill))
}


# -----------------------------------------------------------------------------
#' get_mirca_cropland
#'
#' Calculate cropland fraction within country and glu intersection
#'
#' @param raster_brick Default = NULL. raster brick for the mirca cropland
#' @param mapping Default = NULL. data table of 0.5 degree 67420 grid cells with lat and lon of global land area
#' @keywords internal
#' @export

get_mirca_cropland <- function(raster_brick = NULL,
                               mapping = NULL)
{

  lon <- lat <- NULL


  # get lon lat from MIRCA
  lonlat <- sp::SpatialPoints(cbind(lon = mapping$lon,
                                    lat = mapping$lat))

  # get crop area by lon lat
  grid <- dplyr::bind_cols(
    raster::as.data.frame(raster::extract(x = raster_brick, y = lonlat,  sp = T))) %>%
    tibble::as_tibble()

  # update names
  name_orig <- names(raster_brick)
  name_new <- stringr::str_replace_all(name_orig, c('annual_area_harvested_|_ha_30mn'), '')

  grid <- grid %>%
    dplyr::rename(stats::setNames(c(name_orig, 'lon', 'lat'),
                           c(name_new, 'lon', 'lat')))

  # convert area unit from ha to m2
  cropland_grid <- grid %>%
    dplyr::mutate(dplyr::across(-c(lon, lat), ~. * 10000))

  out <- list(name_new = name_new,
              cropland_grid = cropland_grid)
  return(out)

}



# -----------------------------------------------------------------------------
#' get_cropland_weight
#'
#' Calculate the weight of cropland area within the intersected region-glu-country to
#' cropland area within intersected region-glu
#'
#' @param gcam_version Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @keywords internal
#' @export

get_cropland_weight <- function(gcam_version = 'gcam7',
                                climate_scenario = NULL,
                                output_dir = file.path(getwd(), 'output'))
{

  region_name <- basin_name <- glu <- region_id <- glu_id <- glu_name <- crop <-
    croparea_to <- croparea_from <- country_name <- irr <- irrtype <- iso <- NULL


  # get MIRCA2000 harvested area data
  mirca_data <- gaia::get_mirca2000_data(data_dir = output_dir)

  # cropland area file list
  crop_area_list <- list.files(mirca_data, full.names = TRUE)

  # convert ASCII files to raster bick
  mirca_ras_brick <- raster::stack(crop_area_list)

  # get mapping
  mp <- mirca_to_gcam(gcam_version = gcam_version,
                      climate_scenario = climate_scenario)

  mp_iso <- mp$mp_iso
  mp_rmap <- mp$mp_rmap
  mp_gcam <- mp$mp_gcam
  mp_gcam_commod <- mp$gcam_commod_fill

  # for 67420 grid cells with country-glu-reg mapping
  grid_ctry_glu_reg <- get_mirca_cropland(raster_brick = mirca_ras_brick,
                                          mapping = mp_rmap)


  name_new <- grid_ctry_glu_reg$name_new
  grid_ctry_glu_reg <- grid_ctry_glu_reg$cropland_grid

  # get the area total for region-glu intersection
  cropland_glu_region <- grid_ctry_glu_reg %>%
    dplyr::left_join(mp_rmap, by = c('lon', 'lat')) %>%
    dplyr::left_join(mp_gcam %>%
                       dplyr::select(region_name, glu_name = basin_name, glu),
                     by = c('region_name', 'glu_name')) %>%
    dplyr::filter(!is.na(glu)) %>%
    tidyr::pivot_longer(cols = dplyr::all_of(name_new), names_to = 'crop', values_to = 'croparea_to') %>%
    dplyr::group_by(region_id, region_name, glu_id, glu_name, glu, crop) %>%
    dplyr::summarise(croparea_to = sum(croparea_to)) %>%
    dplyr::ungroup()

  # get the area total for country-glu-region intersection
  cropland_ctry_glu_region <- grid_ctry_glu_reg %>%
    dplyr::left_join(mp_rmap, by = c('lon', 'lat')) %>%
    dplyr::left_join(mp_gcam %>%
                       dplyr::select(region_name, glu_name = basin_name, glu),
                     by = c('region_name', 'glu_name')) %>%
    dplyr::filter(!is.na(glu)) %>%
    tidyr::pivot_longer(cols = dplyr::all_of(name_new), names_to = 'crop', values_to = 'croparea_from') %>%
    dplyr::group_by(region_id, region_name, country_name, glu_id, glu_name, glu, crop) %>%
    dplyr::summarise(croparea_from = sum(croparea_from)) %>%
    dplyr::ungroup()


  # calculate the weight of intersected country-glu-region to glu-region area
  weight <- cropland_ctry_glu_region %>%
    dplyr::left_join(cropland_glu_region) %>%
    dplyr::mutate(weight = ifelse(croparea_to != 0,
                                  croparea_from / croparea_to,
                                  0)) %>%
    tidyr::separate(col = crop, into = c('irr', 'crop_id'), sep = '_') %>%
    dplyr::left_join(crop_mirca, by = c('crop_id')) %>%
    dplyr::mutate(irrtype = dplyr::if_else(irr == 'irc', 'irr', 'noirr') ) %>%
    dplyr::select(region_id, region_name, glu_id, glu_name, glu, country_name, crop, irrtype, weight) %>%
    dplyr::distinct() %>%
    dplyr::filter(!is.na(region_name)) %>%
    dplyr::left_join(mp_iso %>% dplyr::select(country_name, iso),
                     by = c('country_name')) %>%
    # dplyr::rename(country_name = ctry_nm) %>%
    iso_replace() %>%
    dplyr::filter(!is.na(iso)) %>%
    dplyr::mutate(iso = tolower(iso),
                  glu_id = paste0('GLU', glu_id) ) %>%
    # check if the weight sum is 1 (0 when there is no intersection)
    dplyr::group_by(region_id, region_name, glu_id, glu_name, glu, crop, irrtype) %>%
    dplyr::mutate(weight_sum = sum(weight)) %>%
    dplyr::ungroup()

  any(is.na(weight))

  return(list(weight = weight,
              cropland_glu_region = cropland_glu_region))
}



# -----------------------------------------------------------------------------
#' get_weighted_yield_impact
#'
#' Calculate weighted yield impact by region-glu scale for each GCAM commodity
#'
#' @param data Default = NULL. output data from function yield_shock_projection, or similar format of data
#' @param gcam_version Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#'
#' @keywords internal
#' @export

get_weighted_yield_impact <- function(data = NULL,
                                      gcam_version = 'gcam7',
                                      climate_scenario = NULL,
                                      diagnostics = TRUE,
                                      output_dir = file.path(getwd(), 'output'))
{

  glu <- cropmodel <- climatemodel <- scenario <- region_id <- region_name <-
    glu_id <- iso <- crop <- irrtype <- weight_sum <- croparea_to <- GCAM_commod <-
    crop_type <- count <- NULL

  # get weight of cropland area within the intersected region-glu-country to
  # cropland area within intersected region-glu
  out_list <- get_cropland_weight(gcam_version = gcam_version,
                                  climate_scenario = climate_scenario,
                                  output_dir = output_dir)

  weight <- out_list$weight
  cropland_glu_region <- out_list$cropland_glu_region

  # ----------------------------------------------------------------------------
  # Calculate yield impacts for aggregate GCAM commodities and regions
  # ----------------------------------------------------------------------------


  years <- paste0('X', c(2015, seq(2020, 2090, 10)))

  # join weight to the data
  yield_impact_clean <- dplyr::bind_rows(
    data,
    data %>% dplyr::mutate(irrtype = 'irr')) %>%
    dplyr::left_join(weight, by = c('iso', 'crop', 'irrtype')) %>%
    dplyr::filter(!is.na(glu)) %>%
    dplyr::select(cropmodel, climatemodel, scenario,
                  region_id, region_name, glu_id, glu, iso,
                  crop, irrtype, dplyr::all_of(years), weight) %>%
    dplyr::distinct()
  any(is.na(yield_impact_clean))


  # calculate weighted yield impact by glu
  # there are several cases where the cropland weight calculated based on MIRCA cropland is 0,
  # but there are crop impact multiplier values, handle the cases as follows:
  # case 1: if all the weights are 0 by crop and glu, then take mean
  # case 2" root tuber are all 1s for all glus, but croplands are NA, keep multipliers as 1
  # case 3: if weight_sum by glu is < 1, it means the yield impact does not include all the countries that intersected with this glu,
  #         adjust the weight by multiplying (1/weight_sum)so weight_sum will = 1
  yield_impact_clean <- yield_impact_clean %>%
    dplyr::select(-iso) %>%
    dplyr::distinct() %>%
    dplyr::group_by(cropmodel, climatemodel, scenario, region_id, region_name, glu_id, glu, crop, irrtype) %>%
    dplyr::mutate(count = dplyr::n(),
                  weight_sum = sum(weight),
                  weight = dplyr::case_when(weight_sum == 0 ~ 1/count,
                                     weight_sum < 1 ~ weight * (1/weight_sum),
                                     TRUE ~ weight),
                  weight_sum = sum(weight)) %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(years), ~ ifelse(is.na(weight),
                                                               .x,
                                                               .x * weight))) %>%
    dplyr::ungroup() %>%
    dplyr::select(-weight, -count, -weight_sum) %>%
    dplyr::distinct() %>%
    dplyr::group_by(cropmodel, climatemodel, scenario, region_id, region_name, glu_id, glu, crop, irrtype) %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(years), ~ ifelse(crop == 'root_tuber', mean(.), sum(.)))) %>%
    dplyr::ungroup() %>%
    dplyr::distinct() %>%
    dplyr::mutate(X2015 = 1,
                  irrtype = ifelse(irrtype == 'irr', 'IRR', 'RFD'))

  # calculate yield shocks for each GCAM commodity based on the weighted crop areas within the Region-basin intersection
  yield_impact_clean <- yield_impact_clean %>%
    dplyr::left_join(gcam_commod, by = 'crop', relationship = 'many-to-many') %>%
    dplyr::left_join(cropland_glu_region %>%
                       tidyr::separate(crop, into = c('irrtype', 'crop_id'), sep = '_') %>%
                       dplyr::left_join(crop_mirca, by = c('crop_id')) %>%
                       dplyr::mutate(irrtype = ifelse(irrtype == 'irc', 'IRR', 'RFD')) %>%
                       dplyr::select(region_id, glu, crop, irrtype, croparea_to),
                     by = c('region_id', 'glu', 'crop', 'irrtype')) %>%
    dplyr::filter(!is.na(GCAM_commod)) %>%
    dplyr::mutate(harvested_area = dplyr::if_else(croparea_to == 0, 1, croparea_to)) %>%
    dplyr::group_by(cropmodel, climatemodel, scenario, region_id, region_name, glu_id, glu, GCAM_commod, crop_type, irrtype) %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(years), ~ stats::weighted.mean(., harvested_area))) %>%
    dplyr::ungroup()
  any(is.na(yield_impact_clean))


  # ----------------------------------------------------------------------------
  # plot diagnostic plots
  # ----------------------------------------------------------------------------
  if(diagnostics == TRUE){

    ag_subsector <- gcam_commod %>%
      dplyr::select(GCAM_commod, crop_type) %>%
      dplyr::distinct()

    for(i in 1: nrow(ag_subsector)){

      plot_yield_impact(data = yield_impact_clean,
                        commodity = ag_subsector$GCAM_commod[i],
                        crop_type = ag_subsector$crop_type[i],
                        output_dir = output_dir)
    }

  }

  return(yield_impact_clean)


}



#' -----------------------------------------------------------------------------
#' get_agprodchange
#'
#' Calculate agricultural productivity change based on yield impact multiplier and no impact yield
#'
#' @param data Default = NULL. output data from function yield_shock_projection, or similar format of data
#' @param from_year Default = NULL. integer for 'from' year to calculate agricultural productivity change
#' @param to_year Default = NULL. integer for 'to' year to calculate agricultural productivity change
#'
#' @keywords internal
#' @export


get_agprodchange <- function(data = NULL,
                             from_year = NULL,
                             to_year = NULL)
{

  year <- yield_multiplier <- AgProdChange_ni <- AgProdChange <- NULL

  y1 <- paste0('X', from_year)
  y2 <- paste0('X', to_year)

  df <- data %>%
    dplyr::mutate(AgProdChange = ifelse(
      year == y2,
      ((yield_multiplier[year == y2] / yield_multiplier[year == y1])^(1/5)) * (1 + AgProdChange_ni[year == y2]) - 1,
      AgProdChange)) %>%
    dplyr::mutate(AgProdChange = ifelse(is.na(AgProdChange) & is.na(yield_multiplier), AgProdChange_ni, AgProdChange))

  return(df)

}



# -----------------------------------------------------------------------------
#' gcam_agprodchange
#'
#' Map country level yield impacts to GCAM region-GLU level
#' Calculate agricultural productivity change by region GLU
#' Output agprodchange XML
#'
#' @param data Default = NULL. output data from function yield_shock_projection, or similar format of data
#' @param climate_model Default = 'gcm'. string for climate model name (e.g., 'CanESM5')
#' @param climate_scenario Default = 'rcp'. string for climate scenario name (e.g., 'ssp245')
#' @param member Default = 'member'. string for the ensemble member name
#' @param bias_adj Default = 'ba'. string for the dataset used for climate data bias adjustment
#' @param cfe Default = 'no-cfe'. string for whether the yield impact formula implimented CO2 fertilization effect.
#' @param gcam_version Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#'
#' @export

gcam_agprodchange <- function(data = NULL,
                              climate_model = 'gcm',
                              climate_scenario = 'rcp',
                              member = 'member',
                              bias_adj = 'ba',
                              gcam_version = 'gcam7',
                              cfe = 'no-cfe',
                              diagnostics = TRUE,
                              output_dir = file.path(getwd(), 'output'))
{

  X2020 <- X2030 <- X2040 <- X2050 <- X2060 <- X2070 <- X2080 <- X2090 <-
    GCAM_commod <- crop_type <- glu <- GLU <-  year <- irrtype <- mgmt <-
    yield_multiplier <- region_name <- region <- AgProdChange <-
    AgProductionTechnology <- AgSupplySubsector <- AgSupplySector <- NULL

  message(paste0('Starting step: gcam_agprodchange'))

  output_dir <- file.path(output_dir, paste(gcam_version, 'agprodchange', cfe, sep = '_'))
  if(!dir.exists(output_dir)){
    dir.create(output_dir, recursive = T)
  }

  yield_impact_clean <- get_weighted_yield_impact(data = data,
                                                  gcam_version = gcam_version,
                                                  climate_scenario = climate_scenario,
                                                  diagnostics = diagnostics,
                                                  output_dir = output_dir)

  # input reference ag productivity change without climate impact
  # note that different GCAM versions will have different agprodchange structure
  agprodchange_ni <- agprodchange_ref(gcam_version = gcam_version,
                                      climate_scenario = climate_scenario)

  # linear interpolate at 5 year interval
  yield_impact <- dplyr::bind_rows(
    yield_impact_clean %>% dplyr::mutate(mgmt = 'hi'),
    yield_impact_clean %>% dplyr::mutate(mgmt = 'lo')) %>%
    dplyr::mutate(X2025 = ((X2020 + X2030) / 2),
                  X2035 = ((X2030 + X2040) / 2),
                  X2045 = ((X2040 + X2050) / 2),
                  X2055 = ((X2050 + X2060) / 2),
                  X2065 = ((X2060 + X2070) / 2),
                  X2075 = ((X2070 + X2080) / 2),
                  X2085 = ((X2080 + X2090) / 2),
                  X2095 = X2090,
                  X2100 = X2090) %>%
    tidyr::pivot_longer(cols = dplyr::all_of(paste0('X', seq(2015, 2100, 5))),
                        names_to = 'year', values_to = 'yield_multiplier') %>%
    dplyr::mutate(AgSupplySubsector = paste(paste0(GCAM_commod, crop_type), glu, sep = '_'),
                  AgProductionTechnology = paste(paste0(GCAM_commod, crop_type), glu, irrtype, mgmt, sep = '_')) %>%
    dplyr::select(region = region_name, AgSupplySector = GCAM_commod,
                  AgSupplySubsector, AgProductionTechnology, year, yield_multiplier)

  yield_impact_gcam <- agprodchange_ni %>%
    dplyr::left_join(yield_impact,
                     by = c('region', 'AgSupplySector', 'AgSupplySubsector', 'AgProductionTechnology', 'year')) %>%
    # dplyr::mutate(AgProdChange_ni = ifelse(year == 'X2015', 0, AgProdChange_ni)) %>%
    dplyr::group_by(region, AgProductionTechnology) %>%
    dplyr::mutate(AgProdChange = as.numeric("")) %>%
    get_agprodchange(2015, 2020) %>%
    get_agprodchange(2020, 2025) %>%
    get_agprodchange(2025, 2030) %>%
    get_agprodchange(2030, 2035) %>%
    get_agprodchange(2035, 2040) %>%
    get_agprodchange(2040, 2045) %>%
    get_agprodchange(2045, 2050) %>%
    get_agprodchange(2050, 2055) %>%
    get_agprodchange(2055, 2060) %>%
    get_agprodchange(2060, 2065) %>%
    get_agprodchange(2065, 2070) %>%
    get_agprodchange(2070, 2075) %>%
    get_agprodchange(2075, 2080) %>%
    get_agprodchange(2080, 2085) %>%
    get_agprodchange(2085, 2090) %>%
    get_agprodchange(2090, 2095) %>%
    get_agprodchange(2095, 2100) %>%
    dplyr::ungroup() %>%
    # dplyr::distinct() %>%
    dplyr::mutate(year = as.integer(gsub('X', '', year)),
                  AgProdChange = round(AgProdChange, digits = 6)) %>%
    dplyr::filter(year != 2015) %>%
    dplyr::select(region, AgSupplySector, AgSupplySubsector, AgProductionTechnology, year, AgProdChange) %>%
    dplyr::arrange(region, AgSupplySector, AgSupplySubsector, year)

  any(is.na(yield_impact_gcam))

  # ----------------------------------------------------------------------------
  # plot ag productivity change
  # ----------------------------------------------------------------------------

  if(diagnostics == TRUE){

    ag_subsector_gcam <- yield_impact_gcam %>%
      dplyr::select(AgSupplySubsector) %>%
      tidyr::separate(AgSupplySubsector, into = c('commod', 'GLU')) %>%
      dplyr::select(-GLU) %>%
      dplyr::distinct()

    # plot climate impact scenarios
    for(i in 1:nrow(ag_subsector_gcam)){

      plot_agprodchange(data = yield_impact_gcam %>% dplyr::mutate(cropmodel = 'regression',
                                                                   climatemodel = climate_model,
                                                                   scenario = climate_scenario),
                        commodity = ag_subsector_gcam$commod[i],
                        output_dir = output_dir)
    }

  }


  # ----------------------------------------------------------------------------
  # Convert to XML
  # ----------------------------------------------------------------------------

  out_xml_name <- tolower(paste0(paste('agyield_impact', climate_model, member, bias_adj, climate_scenario, sep = '_'), '.xml'))
  gcam_file <- file.path(output_dir, out_xml_name)

  gcamdata::create_xml(gcam_file) %>%
    gcamdata::add_xml_data(yield_impact_gcam, "AgProdChange")%>%
    gcamdata::run_xml_conversion()

  return(yield_impact_gcam)

}
