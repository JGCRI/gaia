#' weighted_climate
#'
#' Processes CMIP6 daily or monthly climate NetCDF data formatted in accordance with the ISIMIP simulation protocols (more details here) and calculates cropland-weighted precipitation and temperature at the country level, differentiated by crop type and irrigation type.
#'
#' @param pr_ncdf Default = NULL. List of paths for precipitation NetCDF files from ISIMIP
#' @param tas_ncdf Default = NULL. List of paths for temperature NetCDF files from ISIMIP
#' @param timestep Default = 'monthly'. String for input climate data time step (e.g., 'monthly', 'daily')
#' @param climate_model Default = NULL. String for climate model (e.g., 'CanESM5')
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param time_periods Default = NULL. Vector for years to subset from the climate data. If NULL, use the default climate data period
#' @param crop_names Default = NULL. String vector for selected crops id names from MIRCA2000. If NULL, use all MIRCA 26 crops. Crop names should be strings like 'irc_crop01', 'rfc_crop01', ..., 'irc_crop26', 'rfc_crop26'
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @param name_append Default = NULL. String for name append to the output folder
#' @returns No return value, called for the side effects of processing and writing output files. The output files include columns `[year, month, 1, 2, 3, ..., 265]`, where the numbers correspond to country IDs. To view the country names associated with these IDs, simply type gaia::country_id in the R console after loading the gaia package.
#' @export


weighted_climate <- function(pr_ncdf = NULL,
                             tas_ncdf = NULL,
                             timestep = "monthly",
                             climate_model = "gcm",
                             climate_scenario = "rcp",
                             time_periods = NULL,
                             crop_names = NULL,
                             output_dir = file.path(getwd(), "output"),
                             name_append = NULL) {
  # ----------------------------------------------------------------------------
  # Initialization
  # ----------------------------------------------------------------------------

  NULL -> ncvar_get -> fao_code -> country_id -> country_name -> lon -> lat ->
  country_name.final -> year -> month -> value

  # create output folder
  save_dir <- file.path(output_dir, "weighted_climate", paste0(climate_model, name_append))
  if (!dir.exists(save_dir)) {
    dir.create(save_dir, recursive = TRUE)
  }

  if(is.null(crop_names)){
    crop_names <- names(mirca_harvest_area)
    crop_names <- crop_names[!(crop_names %in% c("lon", "lat"))]
  }

  # check if pr_ncdf is provided
  if (!is.null(pr_ncdf)) {
    pr_exists <- TRUE
  } else {
    pr_exists <- FALSE
    message("No precipitation files provided. Skipping.")
  }

  # check if tas_ncdf is provided
  if (!is.null(tas_ncdf)) {
    tas_exists <- TRUE
  } else {
    tas_exists <- FALSE
    message("No temperature files provided. Skipping.")
  }

  # check if timestep is valid
  if (!timestep %in% c("daily", "monthly")) {
    stop('Please provide a valid value for the "timestep" argument: choose either "daily" or "monthly".')
  }

  # check if climate_model is default or provided by user
  if (climate_model == "gcm") {
    message('Using the default `climate_model` value: "gcm". Please specify the `climate_model` argument as needed.')
  }

  # check if climate_scenario is default or provided by user
  if (climate_scenario == "rcp") {
    message('Using the default `climate_scenario` value: "rcp". Please specify `climate_scenario` argument as needed.')
  }


  # ----------------------------------------------------------------------------
  # Mapping
  # ----------------------------------------------------------------------------
  # get gridded GCAM country with lat lon and reference country id and name
  grid_country <- mapping_fao_glu %>%
    dplyr::left_join(
      mapping_country %>%
        dplyr::select(fao_code, country_id, country_name) %>%
        dplyr::filter(!country_name %in% c(
          "Ashmore and Cartier Islands",
          "Coral Sea Islands"
        )),
      by = c("fao_code"),
      suffix = c("", ".final")
    ) %>%
    dplyr::select(lon, lat, country_id, country_name = country_name.final) %>%
    dplyr::distinct()


  # ----------------------------------------------------------------------------
  # Calculate weighted each cropland area over total cropland area bounded by country
  # ----------------------------------------------------------------------------
  # merge mirca crop area with country area and calculate sum of the crop area within country
  crop_area_total <- grid_country %>%
    dplyr::left_join(mirca_harvest_area, by = c("lon", "lat")) %>%
    dplyr::group_by(country_id, country_name) %>%
    dplyr::mutate(dplyr::across(dplyr::starts_with(c("irc", "rfc")), sum)) %>%
    dplyr::ungroup() %>%
    dplyr::distinct()

  # calculate weighted crop area of total crop area in country
  crop_area_weight <- grid_country %>%
    dplyr::left_join(mirca_harvest_area, by = c("lon", "lat")) %>%
    dplyr::left_join(crop_area_total,
      by = c("lon", "lat", "country_id", "country_name"),
      suffix = c("", ".total")
    ) %>%
    dplyr::distinct()


  # ----------------------------------------------------------------------------
  # load climate data
  # ----------------------------------------------------------------------------
  # process precipitation
  # precipitation (input in mm/s, output in mm/month)
  pr <- tibble::tibble()
  if (pr_exists) {
    all_periods <- c()

    # loop through all pr files
    for (pr_file in pr_ncdf) {
      # check if pr file is valid
      path_check(path = pr_file, file_type = "nc")

      # precipitation
      message(paste0("Processing: ", pr_file))

      # get time periods of the nc file
      nc_time <- get_nc_time(pr_file)

      # check if the data periods is within the selected periods
      if (!is.null(time_periods)) {
        # check if the data periods is within the selected periods
        nc_time_subset <- nc_time[nc_time %in% time_periods]

        if (is.null(nc_time_subset)) {
          stop("Selected time periods are beyond the available precipitation data.")
        }
      } else {
        nc_time_subset <- nc_time
      }


      # convert ncdf to table
      pr_temp <- nc_to_tbl(
        nc_file = pr_file,
        var = "pr",
        time_periods = nc_time_subset,
        timestep = timestep
      )

      # merge all periods
      pr <- dplyr::bind_rows(pr, pr_temp)
      all_periods <- c(all_periods, nc_time_subset)
    } # end of for(pr_file in pr_ncdf)

    # convert precipitation from mm/s to mm/month
    pr <- pr %>%
      tidyr::pivot_wider(names_from = date, values_from = value) %>%
      dplyr::mutate(dplyr::across(-c(lon, lat), ~ .x * 60 * 60 * 24 * 30))

    # get final start and end year
    pr_period <- paste0(min(all_periods), "_", max(all_periods))
  } # end of if(is.null(pr_ncdf))


  # process temperature
  # temperature (input in K, output in C)
  tas <- tibble::tibble()

  if (tas_exists) {
    all_periods <- c()

    # loop through all tas files
    for (tas_file in tas_ncdf) {
      # check if pr file is valid
      path_check(path = tas_file, file_type = "nc")

      # precipitation
      message(paste0("Processing: ", tas_file))

      # get time periods of the nc file
      nc_time <- get_nc_time(tas_file)

      # check if the data periods is within the selected periods
      if (!is.null(time_periods)) {
        # check if the data periods is within the selected periods
        nc_time_subset <- nc_time[nc_time %in% time_periods]

        if (is.null(nc_time_subset)) {
          stop("Selected time periods are beyond the available temperature data.")
        }
      } else {
        nc_time_subset <- nc_time
      }

      # convert ncdf to table
      tas_temp <- nc_to_tbl(
        nc_file = tas_file,
        var = "tas",
        time_periods = nc_time_subset,
        timestep = timestep
      )

      # merge all periods
      tas <- dplyr::bind_rows(tas, tas_temp)
      all_periods <- c(all_periods, nc_time_subset)
    } # end of for(i in nrow(tas_ncdf))

    # convert temperature from K to C
    tas <- tas %>%
      tidyr::pivot_wider(names_from = date, values_from = value) %>%
      dplyr::mutate(dplyr::across(-c(lon, lat), ~ .x - 273.15))

    # get final start and end year
    tas_period <- paste0(min(all_periods), "_", max(all_periods))
  }


  # ----------------------------------------------------------------------------
  # Calculate weighted precipitation (mm/month) and temperature (C)
  # ----------------------------------------------------------------------------

  # Calculating crop harvest area weighted precipitation and temperature
  for (crop in crop_names) {
    message(paste0("Processing ", crop))

    # Precipitation -------------------
    if (pr_exists & nrow(pr) > 0) {
      # calculate weighted monthly precipitation using cropland weights within country
      pr_weighted <- weight_by_crop_area(tbl = pr, crop = crop, crop_area_weight = crop_area_weight)

      # write output
      utils::write.table(
        pr_weighted,
        file = file.path(
          save_dir,
          paste0(paste(climate_model, climate_scenario, "month_precip_country", crop, pr_period, sep = "_"), ".txt")
        ),
        quote = FALSE, row.names = FALSE
      )
    } else {
      warning("No precipitation output is generated.")
    }

    # temperature -------------------
    if (tas_exists & nrow(tas) > 0) {
      # calculate weighted monthly precipitation using cropland weights within country
      tas_weighted <- weight_by_crop_area(tbl = tas, crop = crop, crop_area_weight = crop_area_weight)

      # write output
      utils::write.table(
        tas_weighted,
        file = file.path(
          save_dir,
          paste0(paste(climate_model, climate_scenario, "month_tmean_country", crop, tas_period, sep = "_"), ".txt")
        ),
        quote = FALSE, row.names = FALSE
      )
    } else {
      warning("No temperature output is generated.")
    }
  } # end of for(crop in names(gaia::mirca_harvest_area))

  # output the data periods
  if(all(tas_exists, pr_exists, tas_period == pr_period)){

    period_split <- strsplit(tas_period, "_")
    start_end_year <- c(period_split[[1]][1], period_split[[1]][2])

  } else if (all(tas_exists, !pr_exists)){

    period_split <- strsplit(tas_period, "_")
    start_end_year <- c(period_split[[1]][1], period_split[[1]][2])

  } else if (all(!tas_exists, pr_exists)){

    period_split <- strsplit(pr_period, "_")
    start_end_year <- c(period_split[[1]][1], period_split[[1]][2])

  } else {

    stop(paste0("Precipitation (", pr_period, ") and Temperature (", tas_period, ") time periods are not identical."))
  }

  return(start_end_year)

  message("The function weighted_climate is complete.")
} # end of function weighted_climate


# ------------------------------------------------------------------------------
#' nc_to_tbl
#'
#' Process standard NetCDF files and convert to tibble
#'
#' @param nc_file Default = NULL. String for paths for precipitation
#' @param var Default = NULL. String for climate variable
#' @param time_periods Default = NULL. Vector for years to subset from the climate data. If NULL, use the default climate data period
#' @param timestep Default = 'monthly'. String for input climate data time step (e.g., 'monthly', 'daily')
#' @returns A data frame of the processed NetCDF data
#' @noRd
nc_to_tbl <- function(nc_file = NULL,
                      var = NULL,
                      time_periods = NULL,
                      timestep = "monthly") {
  lon <- lat <- year <- month <- value <- NULL

  tbl <- helios::read_ncdf(
    ncdf = nc_file,
    var = var,
    model = "cmip",
    time_periods = time_periods
  )

  # pivot longer
  tbl <- reshape2::melt(tbl, id.vars = c("lon", "lat"), variable.name = "date", value.name = "value")

  # calculate monthly mean for temperature
  if (timestep == "daily") {
    tbl <- tbl %>%
      dplyr::mutate(
        date = as.Date(date),
        year = lubridate::year(date),
        month = lubridate::month(date)
      ) %>%
      dplyr::group_by(lon, lat, year, month) %>%
      dplyr::summarise(value = mean(value)) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(date = as.Date(paste(year, month, "01", sep = "-"), format = "%Y-%m-%d")) %>%
      dplyr::select(-year, -month)
  }

  return(tbl)
}


# ------------------------------------------------------------------------------
#' weight_by_crop_area
#'
#' weight the table by crop area
#'
#' @param tbl Default = NULL. Data table for gridded monthly climate data, with columns like [lon, lat, 2010-01-01, 2010-02-01, ...]
#' @param crop Default = NULL. String for crop name (e.g., 'irr_crop01')
#' @param crop_area_weight Default = NULL. Data table for weight of crop harvest area within country
#' @returns A data frame of cropland weight
#' @noRd
weight_by_crop_area <- function(tbl = NULL,
                                crop = NULL,
                                crop_area_weight = NULL) {
  lon <- lat <- country_id <- country_name <- value <- NULL

  # capture and quote the unevaluated crop names expressions
  # crop_area <- dplyr::enquo(crop)
  #
  # crop_area_total <- paste0(crop, ".total")
  # crop_area_total <- dplyr::enquo(crop_area_total)

  crop_area <- as.character(crop)
  crop_area_total <- paste0(crop, ".total")

  # calculate weighted monthly precipitation using cropland weights within country
  tbl_weighted <- crop_area_weight %>%
    dplyr::select(lon, lat, country_id, country_name, all_of(c(crop_area, crop_area_total))) %>%
    dplyr::left_join(tbl, by = c("lon", "lat")) %>%
    dplyr::mutate(crop_area_weight = .data[[crop_area]] / .data[[crop_area_total]]) %>%
    dplyr::mutate(dplyr::across(-c(lon, lat, country_id, country_name), ~ .x * crop_area_weight)) %>%
    dplyr::group_by(country_id, country_name) %>%
    dplyr::summarise(dplyr::across(-c(lon, lat), ~ sum(.x, na.rm = TRUE))) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(dplyr::across(
      -c(country_id, country_name, !!crop_area, !!crop_area_total),
      ~ dplyr::na_if(.x, 0)
    ))

  # transpose to required format
  tbl_transpose <- data.frame(country_id = seq(1, 265, 1)) %>%
    dplyr::left_join(tbl_weighted, by = "country_id") %>%
    # dplyr::select(-country_name, -!!crop_area, -!!crop_area_total, -crop_area_weight) %>%
    dplyr::select(-country_name, -all_of(c(crop_area, crop_area_total)), -crop_area_weight) %>%
    dplyr::mutate(
      dplyr::across(-c(country_id), ~ tidyr::replace_na(.x, as.numeric(-9999))),
      dplyr::across(-c(country_id), ~ round(.x, digits = 2))
    ) %>%
    tidyr::pivot_longer(cols = !country_id, names_to = "date") %>%
    dplyr::mutate(
      date = as.Date(date),
      year = lubridate::year(date),
      month = lubridate::month(date)
    ) %>%
    dplyr::select(-date) %>%
    tidyr::pivot_wider(names_from = country_id, values_from = value)

  return(tbl_transpose)
}
