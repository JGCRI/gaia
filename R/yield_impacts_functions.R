# Crop Yield Functions


# ------------------------------------------------------------------------------
#' clean_yield
#'
#' Function to clean FAO yield data
#'
#' @param fao_yield Default = NULL. Data frame for the fao yield table
#' @param fao_to_mirca Default = NULL. Data frame for the fao to mirca crop mapping
#' @returns A data frame of formatted FAO yield data
#' @keywords internal
#' @export

clean_yield <- function(fao_yield = NULL,
                        fao_to_mirca = NULL) {
  Area <- `Area Code` <- `Item Code` <- Element <- Item <- country_code <-
    iso <- year <- var <- value <- to_mirca <- crop_id <- crop_name <-
    fao_crop_id <- crop <- area_harvest <- yield <- NULL

  # clean up FAOSTAT yield and harvest area data and left join the iso code
  df <- fao_yield %>%
    dplyr::filter(`Item Code` %in% unique(fao_to_mirca$fao_crop_id),
                  Element %in% c('Area harvested', 'Yield'),
                  # Exclude entire China because FAOSTAT distinguishes China mainland, Taiwan, and Hongkong
                  # GCAM also has Taiwan as individual region
                  !Area %in% c('China'))  %>%
    dplyr::select(country_code = `Area Code`, country_name = Area, var = Element,
                  fao_crop_name = Item, fao_crop_id = `Item Code`,
                  paste0('Y', 1961:2020)) %>%
    dplyr::left_join(fao_iso %>% dplyr::select(country_code, iso),
                     by = 'country_code') %>%
    dplyr::filter(!is.na(iso))

  # clean up the iso code which megers some FAOSTAT specific 'f' iso codes
  df <- iso_replace(df)

  # restructure data
  df <- df %>%
    tidyr::pivot_longer(cols = paste0('Y', 1961:2020),
                        names_to = 'year', values_to = 'value') %>%
    dplyr::mutate(year = as.integer(gsub('Y', '', year)),
                  var = dplyr::case_when(var == 'Yield' ~ 'yield',
                                         var == 'Area harvested' ~ 'area_harvest')) %>%
    tidyr::pivot_wider(names_from = var, values_from = value)

  # Join FAO to MIRCA2000 crops and aggregated by country, MIRCA2000 crop type
  # for harvest areas, take sum of all FAO crops for each MIRCA2000 crop
  # for yields, take mean of all FAO crops for each MIRCA2000 crop
  df_mirca <- df %>%
    dplyr::left_join(fao_to_mirca %>%
                       tidyr::pivot_longer(cols = paste('crop', sprintf('%02d', 1:26), sep = ''),
                                           names_to = 'crop_id', values_to = 'to_mirca') %>%
                       dplyr::filter(to_mirca == 'X') %>%
                       dplyr::left_join(crop_mirca %>% dplyr::select(crop_id, crop = crop_name)) %>%
                       dplyr::select(fao_crop_id, crop) %>%
                       dplyr::distinct(),
                     by = 'fao_crop_id') %>%
    dplyr::group_by(iso, crop, year) %>%
    dplyr::summarise(area_harvest = sum(area_harvest, na.rm = T),
                     yield = mean(yield, na.rm = T)) %>%
    dplyr::filter(area_harvest > 0, yield > 0)

  return(df_mirca)
}


# ------------------------------------------------------------------------------
#' weather_clean
#'
#' Function to clean the input weather files (historic and model projections) for regression analysis
#'
#' @param file Default = NULL. String for the path to the climate file
#' @param crop_name Default = NULL. String for the crop name
#' @param weather_var Default = NULL. String for the weather var name
#' @param irr_type Default = NULL. String for the irrigation type. Options: 'irr', 'rf'
#' @param time_periods Default = NULL. vector for years to subset from the climate data. If NULL, use the default climate data period
#' @returns A data frame of formatted weather data
#' @keywords internal
#' @noRd

weather_clean <- function(file = NULL,
                          crop_name = NULL,
                          weather_var = NULL,
                          irr_type = NULL,
                          time_periods = NULL) {
  country_name <- iso <- .SD <- year <- NULL

  d <- data.table::fread(file, skip = 0, stringsAsFactors = FALSE, header = TRUE)
  if (!is.null(time_periods)) {
    d <- d[year %in% time_periods, ]
  }
  cols_to_num <- names(d)[!names(d) %in% c("year", "month")]
  d <- d[, (cols_to_num) := lapply(.SD, as.numeric), .SDcols = cols_to_num]
  d <- data.table::melt(d, id.vars = c("year", "month"), variable.name = "country_id")
  d$country_id <- as.numeric(as.character(gsub("X", "", d$country_id)))
  d <- merge(d, gaia::country_id, by = "country_id", all.x = TRUE)
  d$iso <- tolower(d$iso)
  d$country_id <- NULL
  d <- subset(d, country_name != "Ashmore and Cartier Islands")
  d <- subset(d, country_name != "Coral Sea Islands")
  d$country_name <- NULL
  d$crop <- crop_name
  d <- colname_replace(d, "value", weather_var)
  d$irr_rf <- irr_type
  d <- subset(d, iso != "ala")
  d <- subset(d, iso != "umi")
  d <- subset(d, iso != "atf")
  d[[weather_var]][d[[weather_var]] == -9999.00] <- NA
  d$month <- paste("month_", d$month, sep = "")
  d <- data.table::dcast(d, crop + irr_rf + iso + year ~ month, value.var = weather_var)
  d$var <- weather_var
  return(d)
}


# ------------------------------------------------------------------------------
#' weather_agg
#'
#' Function to aggregate the cleaned temperature and precipitation data for each crop
#'
#' @param file_precip Default = NULL. String for path to the precipitation file
#' @param file_temp Default = NULL. String for path to the temperature file
#' @param crop_name Default = NULL. String for crop name
#' @param time_periods Default = NULL. Vector for years to subset from the climate data. If NULL, use the default climate data period
#' @returns A data frame of aggregated weather data
#' @keywords internal
#' @noRd

weather_agg <- function(file_precip = NULL,
                        file_temp = NULL,
                        crop_name = NULL,
                        time_periods = NULL) {
  d1 <- weather_clean(
    file = file_precip,
    crop_name = crop_name,
    weather_var = "precip",
    irr_type = "rf",
    time_periods = time_periods
  )
  d2 <- weather_clean(
    file = file_temp,
    crop_name = crop_name,
    weather_var = "temp",
    irr_type = "rf",
    time_periods = time_periods
  )
  d <- rbind(d1, d2)
  return(d)
}


# ------------------------------------------------------------------------------
#' crop_month
#'
#' Function to estimate growing season for each crop and country (SAGE db)
#'
#' @param climate_data Default = NULL. Data table for climate data
#' @param crop_name Default = NULL. String for crop name
#' @param crop_calendar Default = NULL. Data table for crop calendar
#' @returns A data frame of crop growing season
#' @keywords internal
#' @noRd

crop_month <- function(climate_data = NULL,
                       crop_name = NULL,
                       crop_calendar = NULL) {
  year <- year2 <- NULL

  d <- subset(crop_calendar, crop_calendar[[crop_name]] == 1)
  d <- subset(d, select = c("iso", crop_name, "plant", "harvest"))
  d$year1 <- ifelse(d$harvest - d$plant > 0, 1, 0)
  d$year2 <- ifelse(d$harvest - d$plant < 0, 1, 0)
  monthfcn <- function(n) {
    v <- paste("grow_", n, sep = "")
    d[[v]] <- ifelse(d$year1 == 1 & (d$plant <= n & d$harvest >= n), 1, 0)
    d[[v]] <- ifelse(d$year2 == 1 & (d$plant - 12 <= n - 12 | (d$harvest - 12 >= n - 12)), 1, d[[v]])
    return(d)
  }
  months <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
  for (m in months)
  {
    d <- monthfcn(m)
  }
  d <- merge(climate_data, d, by = "iso")
  for (m in months)
  {
    monthvar <- paste("month_", m, sep = "")
    growvar <- paste("grow_", m, sep = "")
    d[[monthvar]] <- d[[monthvar]] * d[[growvar]]
    monthvar <- NULL
    growvar <- NULL
  }
  d <- subset(d, select = c(
    "iso", "year", "crop", "irr_rf", "var", "year1", "year2", "plant", "harvest",
    "month_1", "month_2", "month_3", "month_4", "month_5", "month_6",
    "month_7", "month_8", "month_9", "month_10", "month_11", "month_12"
  ))
  d <- data.table::melt(d, id.vars = 1:9)
  d <- colname_replace(d, "variable", "grow_month")
  d$grow_month <- as.numeric(as.character(gsub("month_", "", d$grow_month)))
  # Remove partial year coverage in first year for growing seasons that cover different years
  d.year2 <- subset(d, year2 == 1)
  d.year2 <- d.year2[order(d.year2$iso, d.year2$year), ]
  d.year2$year <- ifelse(d.year2$year2 == 1 & d.year2$grow_month >= d.year2$plant, d.year2$year + 1, d.year2$year)
  d.year2 <- subset(d.year2, year != 2002)
  d.year2 <- plyr::ddply(d.year2, "iso", subset, year > min(year), )
  d <- subset(d, year2 != 1)
  d <- d[order(d$iso, d$year), ]
  d <- rbind(d, d.year2)
  d <- data.table::dcast(d, iso + year + crop + irr_rf + grow_month ~ var, value.var = "value")
  d$grow_season <- ifelse(d$temp != 0 & d$precip != 0, 1, 0)
  return(d)
}


# ------------------------------------------------------------------------------
#' data_merge
#'
#' Function to merge the iso codes, FAO yield (historic), crop calendar, and weather variables
#' and select variables for regression analysis
#'
#' @param data Default = NULL. Data table for crop data created by crop_month
#' @param crop_name Default = NULL. String for crop name
#' @param yield Default = NULL. Data table for yield data
#' @param output_dir Default = NULL. String for path to output folder
#' @param co2_hist Default = NULL. Data table for historical CO2 concentration [year, co2_conc]
#' @param gdp_hist Default = gdp. Data table for historical GDP by ISO [iso, year, gdp_pcap_ppp]
#' @returns A data frame of aggregated country, crop, weather data
#' @keywords internal
#' @noRd

data_merge <- function(data = NULL,
                       crop_name = NULL,
                       yield = NULL,
                       output_dir = NULL,
                       co2_hist = NULL,
                       gdp_hist = gdp) {
  crop <- grow_season <- var <- NULL

  if (is.null(co2_hist)) {
    co2_hist <- gaia::co2_historical
  }

  yield <- subset(yield, crop == crop_name)
  d <- merge(data, yield, by = c("iso", "year", "crop"))
  d <- subset(d, !is.na(yield))
  # d$id <- NULL
  d <- merge(d, co2_hist, by = "year")
  d <- merge_data(d, gdp_hist, "iso", "year")
  d <- subset(d, select = c(
    "iso", "year", "gdp_pcap_ppp", "crop", "area_harvest",
    "irr_rf", "irr_equip", "co2_conc", "yield",
    "grow_month", "grow_season", "temp", "precip"
  ))

  # save
  gaia::output_data(
    data = d,
    save_path = file.path(output_dir, "data_processed"),
    file_name = paste0("historic_vars_", crop_name, ".csv"),
    data_info = "Merged historical yield data"
  )

  return(d)
}


# ------------------------------------------------------------------------------
#' data_trans
#'
#' Create a data frame with future monthly weather variables and iso codes for
#' projecting yields using fitted regression model
#'
#' @param data Default = NULL. Data table for crop data created by crop_month
#' @param climate_model Default = NULL. String for climate model
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param crop_name Default = NULL. String for crop name
#' @param output_dir Default = NULL. String for path to the output folder
#' @param co2_proj Default = NULL. Data table for future CO2 concentration [year, co2_conc]
#' @returns A data frame of formatted future weather data
#' @keywords internal
#' @noRd

data_trans <- function(data = NULL,
                       climate_model = NULL,
                       climate_scenario = NULL,
                       crop_name = NULL,
                       output_dir = NULL,
                       co2_proj = NULL) {
  grow_season <- var <- NULL

  if (is.null(co2_proj)) {
    co2_proj <- gaia::co2_projection
  }

  d <- subset(data, grow_season == 1)
  d$grow_season <- NULL
  d <- data.table::melt(d, id.vars = c("iso", "year", "crop", "irr_rf", "grow_month"))
  d <- colname_replace(d, "variable", "var")
  d <- data.table::dcast(d, iso + year + crop + var ~ grow_month, value.var = "value")

  # temperature
  d1 <- subset(d, var == "temp")
  d1$temp_mean <- rowMeans(d1[, 5:ncol(d)], na.rm = TRUE)
  d1$temp_max <- apply(d1[, 5:ncol(d)], 1, FUN = max, na.rm = TRUE)
  d1$temp_min <- apply(d1[, 5:ncol(d)], 1, FUN = min, na.rm = TRUE)
  d1 <- subset(d1, select = c("iso", "year", "crop", "temp_mean", "temp_max", "temp_min"))
  d1 <- data.table::melt(d1, id.vars = c("iso", "year", "crop"))

  # precipitation
  d2 <- subset(d, var == "precip")
  d2$precip_mean <- rowMeans(d2[, 5:ncol(d)], na.rm = TRUE)
  d2$precip_max <- apply(d2[, 5:ncol(d)], 1, FUN = max, na.rm = TRUE)
  d2$precip_min <- apply(d2[, 5:ncol(d)], 1, FUN = min, na.rm = TRUE)
  d2 <- subset(d2, select = c("iso", "year", "crop", "precip_mean", "precip_max", "precip_min"))
  d2 <- data.table::melt(d2, id.vars = c("iso", "year", "crop"))

  # bind temperature and precipitation
  d <- rbind(d1, d2)
  d <- data.table::dcast(d, iso + year + crop ~ variable, value.var = "value")
  d <- merge(d, mapping_gcam_iso, by = "iso")
  d <- merge(d, co2_proj, by = "year")
  d$country_name <- NULL
  d$GCAM_region_ID <- NULL
  d <- d[order(d$iso, d$year), ]

  # save
  gaia::output_data(
    data = d,
    save_path = file.path(output_dir, "data_processed"),
    file_name = paste0("weather_", climate_model, "_", climate_scenario, "_", crop_name, ".csv"),
    data_info = "Future monthly weather"
  )

  return(d)
}


# ------------------------------------------------------------------------------
#' prep_regression
#'
#' Prepare historic dataframe for regression analysis, create all variables that
#' may be used in model specifications
#'
#' @param data Default = NULL. Data frame for crop data
#' @returns A data frame of formatted historical weather and crop data
#' @keywords internal
#' @noRd

prep_regression <- function(data = NULL) {
  grow_season <- variable <- NULL

  d <- subset(data, grow_season == 1)
  d$grow_season <- NULL
  d$irr_rf <- NULL
  d <- data.table::melt(d, id.vars = 1:9)
  d <- data.table::dcast(
    d,
    iso + year + gdp_pcap_ppp + crop + area_harvest + irr_equip + co2_conc + yield + variable ~ grow_month,
    value.var = "value"
  )
  d1 <- subset(d, variable == "temp")
  d1$temp_mean <- rowMeans(d1[, 10:ncol(d)], na.rm = TRUE)
  d1$temp_max <- apply(d1[, 10:ncol(d)], 1, FUN = max, na.rm = TRUE)
  d1$temp_min <- apply(d1[, 10:ncol(d)], 1, FUN = min, na.rm = TRUE)
  d1 <- subset(d1, select = c(
    "iso", "year", "gdp_pcap_ppp", "crop", "area_harvest", "irr_equip",
    "co2_conc", "yield", "temp_mean", "temp_max", "temp_min"
  ))
  d1 <- data.table::melt(d1, id.vars = 1:8)
  d2 <- subset(d, variable == "precip")
  d2$precip_mean <- rowMeans(d2[, 10:ncol(d)], na.rm = TRUE)
  d2$precip_max <- apply(d2[, 10:ncol(d)], 1, FUN = max, na.rm = TRUE)
  d2$precip_min <- apply(d2[, 10:ncol(d)], 1, FUN = min, na.rm = TRUE)
  d2 <- subset(d2, select = c(
    "iso", "year", "gdp_pcap_ppp", "crop", "area_harvest", "irr_equip",
    "co2_conc", "yield", "precip_mean", "precip_max", "precip_min"
  ))
  d2 <- data.table::melt(d2, id.vars = 1:8)
  d <- rbind(d1, d2)
  d <- data.table::dcast(
    d,
    iso + year + gdp_pcap_ppp + crop + area_harvest + irr_equip + co2_conc + yield ~ variable,
    value.var = "value"
  )
  d <- merge(d, mapping_gcam_iso, by = "iso")
  d$area_harvest <- as.numeric(as.character(d$area_harvest))
  d$ln_gdp_pcap <- log(d$gdp_pcap_ppp)
  d$ln_co2_conc <- log(d$co2_conc)
  d$co2_conc_2 <- (d$co2_conc)^2
  d$temp_mean_2 <- (d$temp_mean)^2
  d$temp_max_2 <- (d$temp_max)^2
  d$temp_min_2 <- (d$temp_min)^2
  d$ln_temp_mean <- suppressWarnings(log(d$temp_mean))
  d$ln_temp_max <- suppressWarnings(log(d$temp_max))
  d$ln_temp_min <- suppressWarnings(log(d$temp_min))
  d$precip_mean_2 <- (d$precip_mean)^2
  d$precip_max_2 <- (d$precip_max)^2
  d$precip_min_2 <- (d$precip_min)^2
  d$ln_precip_mean <- log(d$precip_mean)
  d$ln_precip_max <- log(d$precip_max)
  d$ln_precip_min <- log(d$precip_min)
  d$temp_precip_mean <- d$temp_mean * d$precip_mean
  d$temp_co2 <- d$temp_mean * d$co2_conc
  d$precip_co2 <- d$precip_mean * d$co2_conc
  d$ln_year <- log(d$year)
  d$year_2 <- (d$year)^2
  d$ln_yield <- log(d$yield)
  d$country_name <- NULL
  d <- d[order(d$iso, d$year), ]

  return(d)
}


# ------------------------------------------------------------------------------
#' regression_fixed_effects
#'
#' Estimate regression
#' Regression and estimation of y_hat to compare to historic data.
#'
#' The regression is based on country fixed effects that control for heterogeneous
#' unobserved time-invariant influences that vary across countries (e.g., the
#' distribution of soil quality), and a time-trend that controls for
#' temporally-varying influences common to all countries (e.g., improved cultivars)
#'
#' @param data Default = NULL. Data frame for crop data
#' @param crop_name Default = NULL. String for crop name
#' @param formula Default = NULL. String for regression fomular. Default is waldhoff_formula
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns A data frame of historical weather variables used in the regression model
#' @keywords internal
#' @noRd

regression_fixed_effects <- function(data = NULL,
                                     crop_name = NULL,
                                     formula = NULL,
                                     output_dir = file.path(getwd(), "output")) {
  iso <- NULL

  d <- subset(data, select = reg_vars)
  d <- d[stats::complete.cases(d), ]
  # print( crop_name )
  # print( paste( "Regression:", formula, sep = " " ) )
  n1 <- nrow(d)
  # print( paste( n1, "observations", sep = " " ) )
  f <- stats::as.formula(formula)
  n_vars <- length(attr(stats::terms(f), "term.labels"))
  reg <- stats::lm(f, data = d, weights = d[[weight_var]])
  sum <- stats::summary.lm(reg)
  d[[fit_name]] <- stats::predict.lm(reg, level = (1 - n_sig))
  sum$coefficients <- sum$coefficients[1:n_vars, ]
  # print( sum$coefficients )
  print(lmtest::bptest(f, data = d), studentize = TRUE)
  sandwich::sandwich(reg)
  # reg$se_robust <- sandwich::vcovHC(reg, type = "HC", weights = iso)
  reg$se_robust <- sandwich::vcovCL(reg, cluster = ~iso)
  sum.fit <- broom::tidy(reg)
  # print( sum.fit )

  message(paste0(crop_name, " regression: r_squared = ", summary(reg)$r.squared))
  d[[fit_name]] <- exp(d[[fit_name]])

  # save
  gaia::output_data(
    data = sum.fit,
    save_path = file.path(output_dir, "data_processed"),
    file_name = paste("reg_out_", crop_name, "_", fit_name, ".csv", sep = ""),
    data_info = "Summary for the regression analysis"
  )

  # print( paste0("Statistics for regression analysis saved to: ", file.path(save_path, file_name)) )

  # save weather file
  gaia::output_data(
    data = d,
    save_path = file.path(output_dir, "data_processed"),
    file_name = paste0("weather_yield_", crop_name, ".csv"),
    data_info = "Weather variables for regression analysis"
  )

  return(d)
}


# ------------------------------------------------------------------------------
#' plot_fit
#'
#' Figure of fitted regression estimates compared to FAO yields
#'
#' @param data Default = NULL. Data frame for crop data
#' @param crop_name Default = NULL. String for crop name
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns No return value, called for the side effects of plotting fitted regression
#' @keywords internal
#' @noRd

plot_fit <- function(data = NULL,
                     crop_name = NULL,
                     output_dir = file.path(getwd(), "output")) {
  yield <- .data <- area_harvest <- GCAM_region_name <- NULL

  d <- data

  p <- ggplot2::ggplot(d, ggplot2::aes(x = yield, y = .data[[fit_name]], size = area_harvest, color = GCAM_region_name)) +
    ggplot2::geom_point(shape = 21, stroke = 0.5, na.rm = T) +
    ggplot2::scale_size_area(max_size = 20) +
    ggplot2::guides(color = ggplot2::guide_legend(ncol = 1)) +
    col_scale_region +
    ggplot2::geom_abline(slope = 1, intercept = 0, color = "black", linewidth = 1) +
    theme_basic +
    ggplot2::xlab("FAO yield") +
    ggplot2::ylab("model fitted yield") +
    ggplot2::ggtitle(paste("FAO vs. model ", crop_name, " country yields", sep = ""))

  # x and y axis limits
  x_max <- max(d[["yield"]], na.rm = TRUE)
  y_max <- max(d[[fit_name]], na.rm = TRUE)
  x_y_max <- plyr::round_any(max(x_max, y_max), 0.25, f = ceiling)
  x_min <- min(d[["yield"]], na.rm = TRUE)
  y_min <- min(d[[fit_name]], na.rm = TRUE)
  x_y_min <- plyr::round_any(min(x_min, y_min), 0.25, f = ceiling)

  p <- p +
    ggplot2::scale_x_continuous(limits = c(x_y_min, x_y_max)) +
    ggplot2::scale_y_continuous(limits = c(x_y_min, x_y_max)) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 50, vjust = 0.5)) +
    ggplot2::coord_equal(ratio = 1)

  # save
  gaia::output_data(
    data = p,
    save_path = file.path(output_dir, "figures"),
    file_name = paste("model_", crop_name, "_", fit_name, ".pdf", sep = ""),
    is_figure = T,
    data_info = "Fitted regression figure"
  )
}


# ------------------------------------------------------------------------------
#' z_estimate
#'
#' Estimate Z_t = ln(Y_t) w/o constants
#'
#' @param use_default_coeff Default = FALSE. Binary for using default regression coefficients. Set to TRUE will use the default coefficients instead of calculating coefficients from the historical climate data.
#' @param climate_model Default = NULL. String for climate model name
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param crop_name Default = NULL. String for crop name
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns A data frame of variables in the regression model
#' @keywords internal
#' @noRd

z_estimate <- function(use_default_coeff = FALSE,
                       climate_model = NULL,
                       climate_scenario = NULL,
                       crop_name = NULL,
                       output_dir = file.path(getwd(), "output")) {
  crop <- NULL

  print(paste("Extract coefficient values", n_sig, sep = " "))

  if (!use_default_coeff) {
    check_reg_out <- list.files(
      path = file.path(output_dir, "data_processed"),
      pattern = "reg_out_"
    )

    if (length(check_reg_out) == 0) {
      use_default_coeff <- TRUE
    }
  }


  # Extract significant coefficient values
  if (use_default_coeff) {
    coef <- gaia::coef_default %>%
      dplyr::filter(crop == crop_name) %>%
      dplyr::select(-crop)
  } else {
    coef <- gaia::input_data(
      folder_path = file.path(output_dir, "data_processed"),
      input_file = paste("reg_out_", crop_name, "_", fit_name, ".csv", sep = ""),
      skip_number = 0
    )
  }


  # Function to create coefficient values used for analysis (based on p value)
  est_fn <- function(x, n_sig) {
    term <- NULL
    value <- subset(coef, term == x)
    x <- ifelse(value$p.value < n_sig, value$estimate, 0)
    return(x)
  }

  co2_conc <- est_fn("co2_conc", n_sig)
  co2_conc_2 <- est_fn("co2_conc_2", n_sig)
  ln_co2_conc <- est_fn("ln_co2_conc", n_sig)
  ln_temp_mean <- est_fn("ln_temp_mean", n_sig)
  temp_mean <- est_fn("temp_mean", n_sig)
  temp_mean_2 <- est_fn("temp_mean_2", n_sig)
  ln_temp_max <- est_fn("ln_temp_max", n_sig)
  temp_max <- est_fn("temp_max", n_sig)
  temp_max_2 <- est_fn("temp_max_2", n_sig)
  ln_temp_min <- est_fn("ln_temp_min", n_sig)
  temp_min <- est_fn("temp_min", n_sig)
  temp_min_2 <- est_fn("temp_min_2", n_sig)
  ln_precip_mean <- est_fn("ln_precip_mean", n_sig)
  precip_mean <- est_fn("precip_mean", n_sig)
  precip_mean_2 <- est_fn("precip_mean_2", n_sig)
  ln_precip_max <- est_fn("ln_precip_max", n_sig)
  precip_max <- est_fn("precip_max", n_sig)
  precip_max_2 <- est_fn("precip_max_2", n_sig)
  ln_precip_min <- est_fn("ln_precip_min", n_sig)
  precip_min <- est_fn("precip_min", n_sig)
  precip_min_2 <- est_fn("precip_min_2", n_sig)

  # Estimate y_hat for each year
  d <- gaia::input_data(
    folder_path = file.path(output_dir, "data_processed"),
    input_file = paste0("weather_", climate_model, "_", climate_scenario, "_", crop_name, ".csv"),
    skip_number = 0
  )

  # First year has only partial coverage due to crop growing seasons spread over calendar years, note CCSM begins in 2006
  # d <- subset( d, year > 2005 )

  ## Generate transformed variables
  d$ln_co2_conc <- log(d$co2_conc)
  d$co2_conc_2 <- (d$co2_conc)^2
  d$temp_mean_2 <- (d$temp_mean)^2
  d$temp_max_2 <- (d$temp_max)^2
  d$temp_min_2 <- (d$temp_min)^2
  d$ln_temp_mean <- suppressWarnings(log(d$temp_mean))
  d$ln_temp_max <- suppressWarnings(log(d$temp_max))
  d$ln_temp_min <- suppressWarnings(log(d$temp_min))
  d$precip_mean_2 <- (d$precip_mean)^2
  d$precip_max_2 <- (d$precip_max)^2
  d$precip_min_2 <- (d$precip_min)^2
  d$ln_precip_mean <- log(d$precip_mean)
  d$ln_precip_max <- log(d$precip_max)
  d$ln_precip_min <- log(d$precip_min)

  # Estimated ln(yield_t)
  d$ln_yield <- eval(parse(text = y_hat))
  d$year <- paste("X", d$year, sep = "")
  d <- data.table::dcast(d, GCAM_region_name + iso + crop ~ year, value.var = "ln_yield")

  return(d)
}


# ------------------------------------------------------------------------------
#' climate_impact
#'
#' Estimate climate impacts (ratio future to each base year, then average)
#'
#' @param use_default_coeff Default = FALSE. Binary for using default regression coefficients. Set to TRUE will use the default coefficients instead of calculating coefficients from the historical climate data.
#' @param climate_model Default = NULL. String for climate model name
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param crop_name Default = NULL. String for crop name
#' @param base_year Default = NULL. Integer for the base year (for GCAM)
#' @param start_year Default = NULL. Integer for the  start year of the data
#' @param end_year Default = NULL. Integer for the end year of the data
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns A data frame of projected climate impacts on annual yield shocks at the country level
#' @keywords internal
#' @noRd

climate_impact <- function(use_default_coeff = FALSE,
                           climate_model = NULL,
                           climate_scenario = NULL,
                           crop_name = NULL,
                           base_year = NULL,
                           start_year = NULL,
                           end_year = NULL,
                           output_dir = file.path(getwd(), "output")) {
  # estimate z hat
  d <- z_estimate(
    use_default_coeff = use_default_coeff,
    climate_model = climate_model,
    climate_scenario = climate_scenario,
    crop_name = crop_name,
    output_dir = output_dir
  )

  # create base year vector
  baseYears <- c(paste("X", (start_year:end_year), sep = ""))

  # check if the base year exists at all
  missing_year <- setdiff(baseYears, colnames(d))
  if(length(missing_year) > 0){

    for(missing_year_i in missing_year){
      d[[missing_year_i]] <- NA
    }

  }

  # subset data within start and end years
  d <- subset(d, select = c('GCAM_region_name', 'iso', 'crop', baseYears))

  # if start year from the available data is 9 years or earlier before the base year
  # then historical years are determined as (base_year - 9) to base_year
  # else historical years are determined as start_year to base year
  if ((base_year - 9) >= start_year) {
    histYears <- c(paste("X", ((base_year - 9):base_year), sep = ""))
  } else if (((base_year - 9) < start_year) & (base_year > start_year)) {
    histYears <- c(paste("X", (start_year:base_year), sep = ""))
  } else if (base_year + 5 > start_year) {
    histYears <- c(paste("X", (start_year:(base_year + 5)), sep = ""))
  } else {
    stop(paste0("Climate data does not cover historical period: ", base_year))
  }

  # calculate the mean of the exp(year_target - historical_year_i)
  for (x in baseYears)
  {
    x1 <- paste("avg_impact_", x, sep = "")

    d.hist <- subset(d, select = histYears)
    d.impact <- exp(d[[x]] - d.hist)
    d[[x1]] <- as.vector(ifelse(apply(d.impact, 1, function(x) all(is.na(x))),
                                NA,
                                rowSums(d.impact, na.rm = T) / rowSums(!is.na(d.impact))
                                )
                         )
  }

  # clean up the data
  d <- dplyr::select(d, -(paste0("X", start_year:end_year)))
  d <- data.table::melt(d, id.vars = 1:3)
  d <- colname_replace(d, "variable", "year")
  d$year <- gsub("avg_impact_X", "", d$year)
  d$year <- as.numeric(as.character(d$year))
  d <- colname_replace(d, "value", "yield_impact")

  # save
  gaia::output_data(
    data = d,
    save_path = file.path(output_dir, "yield_impacts_annual"),
    file_name = paste0("yield_", climate_model, "_", climate_scenario, "_", crop_name, ".csv"),
    data_info = "Estimated yield impacts data"
  )

  return(d)
}


# ------------------------------------------------------------------------------
#' smooth_impacts
#'
#' Smooth annual impacts using moving average and output certain time step
#' E.g., 2020_avg = mean(2011:2030)
#'
#' @param climate_model Default = NULL. String for climate model name
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param crop_name Default = NULL. String for crop name
#' @param base_year Default = NULL. Integer for the base year (for GCAM)
#' @param start_year Default = NULL. Integer for the  start year of the data
#' @param end_year Default = NULL. Integer for the end year of the data
#' @param smooth_window Default = 20. Integer for smoothing window in years
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns A data frame of projected and smoothed climate impacts on annual yield shocks at the country level
#' @keywords internal
#' @noRd

smooth_impacts <- function(data = NULL,
                           climate_model = NULL,
                           climate_scenario = NULL,
                           crop_name = NULL,
                           base_year = NULL,
                           start_year = NULL,
                           end_year = NULL,
                           smooth_window = 20,
                           output_dir = file.path(getwd(), "output")) {
  GCAM_region_name <- iso <- variable <- .SD <- NULL

  d <- data

  d$year <- paste("X", d$year, sep = "")
  baseYear <- paste0("X", base_year)
  d <- data.table::dcast(d, GCAM_region_name + iso ~ year, value.var = "yield_impact")


  # Default 10-year intervals
  year_min <- min(data$year)
  year_max <- max(data$year)
  year_all <- unique(data$year)

  if (smooth_window != 1) {
    window_pre <- round(smooth_window / 2) - 1
    window_post <- round(smooth_window / 2)

    period_first <- plyr::round_any(base_year, 10, f = ceiling)
    period_last <- plyr::round_any(year_max - window_post, 10, f = ceiling)

    selectYears <- sort(year_all[year_all %in% unique(c(base_year, seq(period_first, period_last, window_post), year_max))])

    for (y in selectYears) {
      if (y == base_year) {
        d[[baseYear]] <- 1
      } else if (y == year_max) {
        window <- paste0("X", seq(selectYears[length(selectYears) - 1], selectYears[length(selectYears)], 1)) # 20 year window
        Year <- paste0("X", y)
        d[[Year]] <- d[, rowMeans(.SD), .SDcols = window]
      } else {
        window <- paste0("X", seq(max(start_year, (y - window_pre)), min(end_year, (y + window_post)), 1)) # 20 year window
        Year <- paste0("X", y)
        d[[Year]] <- d[, rowMeans(.SD, na.rm = T), .SDcols = window]
      }
    }
  } else {
    selectYears <- sort(year_all[year_all %in% unique(seq(base_year, year_max, 1))])

    d[[baseYear]] <- 1
  }


  # new method for linear interpolation (more flexible with years) by MZ
  d <- subset(d, select = c("GCAM_region_name", "iso", paste0("X", selectYears)))
  d <- data.table::melt(d, id.vars = 1:2)
  groups <- d %>%
    dplyr::select(GCAM_region_name, iso) %>%
    dplyr::distinct()
  groups <- split(groups, 1:nrow(groups))
  out <- data.frame()

  for (group in groups) {
    df <- d %>%
      dplyr::filter(
        GCAM_region_name == group$GCAM_region_name,
        iso == group$iso
      ) %>%
      dplyr::mutate(year = as.numeric(gsub("X", "", variable)))

    interp <- stats::approx(
      x = df$year, y = df$value, method = "linear",
      xout = seq(base_year, year_max, 1)
    )

    append <- data.frame(
      GCAM_region_name = group$GCAM_region_name,
      iso = group$iso,
      year = interp$x,
      yield_impact = interp$y
    )

    out <- rbind(out, append)
  }

  d <- out

  d$model <- climate_model
  d$scenario <- climate_scenario
  d$crop <- crop_name

  d.out <- d

  d <- d[order(d$iso, d$year), ]
  d <- d %>% data.table::as.data.table()
  d <- data.table::dcast(d, crop + model + scenario + iso ~ year, value.var = "yield_impact")

  # save smoothed output
  gaia::output_data(
    data = d,
    save_path = file.path(output_dir, "yield_impacts_smooth"),
    file_name = paste0("yield_", climate_model, "_", climate_scenario, "_", crop_name, ".csv"),
    data_info = "Smoothed yield impacts"
  )

  return(d.out)
}


# ------------------------------------------------------------------------------
#' format_projection
#'
#' Format smoothed yield impact projection to wider
#'
#' @param data Default = NULL. Data frame from yield_shock_projection with columns [crop, model, iso, years]
#' @param base_year Default = NULL. Integer for the base year (for GCAM)
#' @param gcam_timestep Default = NULL. Integer for the time step of GCAM (Select either 1 or 5 years for GCAM use)
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns A data frame of formatted and smoothed yield impact projection
#' @keywords internal
#' @noRd

format_projection <- function(data = NULL,
                              base_year = NULL,
                              gcam_timestep = NULL,
                              output_dir = file.path(getwd(), "output")) {
  year <- cropmodel <- model <- scenario <- iso <- crop <- irrtype <-
    harvested_area <- yield_impact <- NULL

  # get the harvest area (ha) from FAO data
  d_ha <- subset(fao_yield, year == 2014)
  d_ha <- subset(d_ha, select = c("crop", "iso", "area_harvest"))
  d_ha <- colname_replace(d_ha, "area_harvest", "harvested_area")

  # set up the years to filter out
  if (is.null(gcam_timestep)) {
    select_years <- c(base_year, seq(2020, 2100, 5))
  } else {
    select_years <- c(base_year, seq(base_year + gcam_timestep, 2100, gcam_timestep))
  }

  # format data
  d <- data[order(data$iso, data$year), ]
  d$cropmodel <- "regression"
  d$irrtype <- "noirr"

  d <- d %>%
    dplyr::left_join(d_ha, by = c("iso", "crop")) %>%
    dplyr::select(cropmodel, model, scenario, iso, crop, irrtype, year, harvested_area, yield_impact) %>%
    dplyr::filter(year %in% select_years) %>%
    dplyr::mutate(year = paste0("X", year)) %>%
    tidyr::pivot_wider(values_from = "yield_impact", names_from = "year") %>%
    dplyr::rename(climatemodel = model)

  # write output
  gaia::output_data(
    data = d,
    save_path = file.path(output_dir, "data_processed"),
    file_name = paste0("format_yield_change_rel", base_year, ".csv"),
    data_info = "Formatted smoothed yield"
  )

  return(d)
}


# ------------------------------------------------------------------------------
#' plot_projection
#'
#' Figure of (raw) annual predicted values (shows interannual variability)
#'
#' @param data Default = NULL. Data frame for the data to plot
#' @param climate_model Default = NULL. String for climate model name
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param crop_name Default = NULL. String for crop name
#' @param base_year Default = NULL. Integer for the base year (for GCAM)
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns No return value, called for the side effects of plotting projected annual yield shocks
#' @keywords internal
#' @noRd

plot_projection <- function(data = NULL,
                            climate_model = NULL,
                            climate_scenario = NULL,
                            crop_name = NULL,
                            base_year = NULL,
                            output_dir = file.path(getwd(), "output")) {
  year <- iso <- NULL

  data <- data %>%
    dplyr::filter(!is.na(yield_impact))

  p <- ggplot2::ggplot(data, ggplot2::aes(x = year, y = yield_impact, color = iso)) +
    ggplot2::geom_line() +
    ggplot2::facet_wrap(~GCAM_region_name, scales = "free_y") +
    ggplot2::guides(col = ggplot2::guide_legend(ncol = 3)) +
    ggplot2::labs(
      x = "year",
      y = paste0("CC yield impact relative to avg (", base_year, "_2020)"),
      title = paste(climate_model, "|", climate_scenario, "| temp and precip impacts on",
        crop_name, "yields by country, relative to ", base_year, "_avg",
        sep = " "
      )
    ) +
    theme_basic +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 50, vjust = 0.5)
    )

  # save
  gaia::output_data(
    data = p,
    save_path = file.path(output_dir, "figures"),
    file_name = paste0(paste("annual_projected_climate_impacts", climate_model, climate_scenario, crop_name, fit_name, sep = "_"), ".pdf"),
    is_figure = T,
    data_info = "Projected annual yield figure"
  )
}


# ------------------------------------------------------------------------------
#' plot_projection_smooth
#'
#' Figure of (smoothed) predicted values
#'
#' @param data Default = NULL. Data frame for the data to plot
#' @param climate_model Default = NULL. String for climate model name
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param crop_name Default = NULL. String for crop name
#' @param base_year Default = NULL. Integer for the base year (for GCAM)
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns No return value, called for the side effects of plotting projected and smoothed annual yield shocks
#' @keywords internal
#' @noRd

plot_projection_smooth <- function(data = NULL,
                                   climate_model = NULL,
                                   climate_scenario = NULL,
                                   crop_name = NULL,
                                   base_year = NULL,
                                   output_dir = file.path(getwd(), "output")) {
  year <- yield_impact <- iso <- NULL

  p <- ggplot2::ggplot(data, ggplot2::aes(x = year, y = yield_impact, color = iso)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::facet_wrap(~GCAM_region_name) +
    ggplot2::guides(col = ggplot2::guide_legend(ncol = 3)) +
    ggplot2::labs(
      x = "year",
      y = paste(crop_name, "yield change relative to ", base_year, "_2020 avg", sep = " "),
      title = paste(climate_model, "|", climate_scenario, "| 20 year averages and interpolated yield impacts for", crop_name, sep = " ")
    ) +
    theme_basic +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 50, vjust = 0.5)
    )

  # save
  gaia::output_data(
    data = p,
    save_path = file.path(output_dir, "figures"),
    file_name = paste0(paste("smooth_projected_climate_impacts", climate_model, climate_scenario, crop_name, fit_name, sep = "_"), ".pdf"),
    is_figure = T,
    data_info = "Projected and smoothed yield figure"
  )
}


# ------------------------------------------------------------------------------
#' plot_map
#'
#' Plot maps by year, model, scenari, and crop
#'
#' @param data Default = NULL. Data frame for the data to plot
#' @param plot_years Default = NULL. Integer for the years to plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns No return value, called for the side effects of plotting map of yield shocks at selected years
#' @import sf
#' @keywords internal
#' @noRd

plot_map <- function(data = NULL,
                     plot_years = NULL,
                     output_dir = file.path(getwd(), "output")) {
  model <- scenario <- year <- crop <- iso <- yield_impact <- yield_impact_group <- NULL

  data$iso <- gsub("rom", "rou", data$iso)
  data$iso <- toupper(data$iso)

  if (is.null(plot_years)) {
    plot_years <- max(unique(data$year))
  }


  pal_fill <- c(
    "#A71B4BFF", "#CD463CFF", "#E96F02FF", "#F39B29FF", "#F9C25CFF", "#FDE48FFF", "#FEFDBEFF",
    "#C7F1AFFF", "#81DEADFF", "#22C4B3FF", "#00A3B6FF", "#0D7CB1FF", "#584B9FFF"
  )

  for (m in unique(data$model))
  {
    for (r in unique(data$scenario))
    {
      for (y in plot_years)
      {
        for (cp in unique(data$crop))
        {
          print(paste("Spatial map plot:", m, r, cp, y, sep = " "))

          # filter by model, rcp, and year
          df_plot <- data %>%
            dplyr::filter(
              model == m,
              scenario == r,
              year == y,
              crop == cp
            ) %>%
            dplyr::select(model, scenario, iso, crop, year, yield_impact)

          # breaks for the data
          breaks <- c(-Inf, seq(0.5, 1.5, 0.1), Inf)

          # convert to sf
          sf_plot <- map_country %>%
            dplyr::left_join(df_plot, by = "iso") %>%
            dplyr::mutate(yield_impact_group = cut(yield_impact, breaks, right = F))

          # plot
          p <-
            ggplot2::ggplot(data = sf_plot) +
            ggplot2::geom_sf(ggplot2::aes(fill = yield_impact_group),
              color = "grey30", linetype = 1, lwd = 0.25
            ) +
            ggplot2::scale_fill_manual(
              values = pal_fill,
              labels = c("<0.5", "0.6", "0.7", "0.8", "0.9", "1.0", "1.1", "1.2", "1.3", "1.4", ">1.5"),
              drop = F,
              guide = ggplot2::guide_colorsteps(
                barwidth = 40,
                barheight = 1.5,
                draw.llim = TRUE,
                frame.colour = "gray50",
                direction = "horizontal",
                label.position = "bottom",
                ticks = TRUE,
                ticks.linewidth = 1.0,
                ticks.colour = "gray30",
                show.limits = F,
                title = NULL
              )
            ) +
            ggplot2::labs(title = paste0("Projected ", y, " yield impacts for ", cp, " | ", m, " | ", r)) +
            ggplot2::theme_void() +
            ggplot2::theme(
              legend.position = "bottom",
              legend.title = ggplot2::element_text(size = 16),
              legend.text = ggplot2::element_text(size = 14),
              plot.title = ggplot2::element_text(size = 18, hjust = 0.5)
            )


          # save plot
          gaia::output_data(
            data = p,
            save_path = file.path(output_dir, "maps"),
            file_name = paste0(paste("map", m, r, cp, y, sep = "_"), ".pdf"),
            is_figure = T,
            data_info = "Projected yield impact map"
          )
        }
      }
    }
  }
}



# ------------------------------------------------------------------------------
#' plot_yield_impact
#'
#' Plot projected yield impact by GCAM commodity
#'
#' @param data Default = NULL. Data frame for the data to plot
#' @param commodity Default = NULL. String for GCAM commodity
#' @param crop_type Default = NULL. String for mirca crop type
#' @param output_dir Default = NULL. String for path to the output folder
#' @returns No return value, called for the side effects of plotting projected yield impact by GCAM commodity
#' @keywords internal
#' @noRd


plot_yield_impact <- function(data = NULL,
                              commodity = NULL,
                              crop_type = NULL,
                              output_dir = NULL) {
  GCAM_commod <- year <- glu <- irrtype <- yield_multiplier <- region_name <-
    AgProductionTechnology <- NULL

  save_path <- file.path(output_dir, "figures_yield_impacts")
  if (!dir.exists(save_path)) {
    dir.create(save_path, recursive = TRUE)
  }


  print(paste0(
    "Plotting Yield Shock for ", commodity, crop_type, " to: ",
    file.path(save_path, paste0(commodity, crop_type, ".png"))
  ))

  select_years <- colnames(data)[grepl("X", colnames(data))]

  df_plot <- data %>%
    dplyr::filter(GCAM_commod == commodity, crop_type %in% crop_type) %>%
    # dplyr::mutate(X2025 = ((X2020 + X2030) / 2),
    #               X2035 = ((X2030 + X2040) / 2),
    #               X2045 = ((X2040 + X2050) / 2),
    #               X2055 = ((X2050 + X2060) / 2),
    #               X2065 = ((X2060 + X2070) / 2),
    #               X2075 = ((X2070 + X2080) / 2),
    #               X2085 = ((X2080 + X2090) / 2),
    #               X2095 = X2090,
    #               X2100 = X2090) %>%
    # tidyr::pivot_longer(cols = dplyr::all_of(paste0('X', seq(2015, 2100, 5))),
    #                     names_to = 'year', values_to = 'yield_multiplier') %>%
    tidyr::pivot_longer(
      cols = dplyr::all_of(select_years),
      names_to = "year", values_to = "yield_multiplier"
    ) %>%
    dplyr::mutate(
      year = as.integer(gsub("X", "", year)),
      AgProductionTechnology = paste(glu, paste0(GCAM_commod, crop_type), irrtype, sep = "_")
    )

  cropmodel <- unique(df_plot$cropmodel)
  climatemodel <- unique(df_plot$climatemodel)
  scenario <- unique(df_plot$scenario)

  p <- ggplot2::ggplot(
    data = df_plot,
    ggplot2::aes(
      x = year, y = yield_multiplier,
      group = interaction(region_name, AgProductionTechnology, irrtype)
    )
  ) +
    ggplot2::geom_line(ggplot2::aes(color = irrtype), show.legend = T) +
    ggplot2::facet_wrap(~region_name) +
    ggplot2::labs(
      title = paste(cropmodel, climatemodel, scenario, paste0(commodity, crop_type), sep = " | "),
      x = NULL,
      y = "Yield Change Relative to the Average of 2015 - 2020"
    ) +
    ggplot2::scale_color_manual(values = c(
      "IRR" = "#FFB900",
      "RFD" = "#5773CC"
    )) +
    ggplot2::theme_bw()


  ggplot2::ggsave(p,
    filename = file.path(save_path, paste0(commodity, crop_type, ".png")),
    height = 10, width = 10, dpi = 150
  )
}


# ------------------------------------------------------------------------------
#' plot_agprodchange
#'
#' Plot projected ag productivity change by GCAM commodity
#'
#' @param data Default = NULL. Data frame for the data to plot
#' @param commodity Default = NULL. String for GCAM commodity
#' @param output_dir Default = NULL. String for path to the output folder
#' @returns No return value, called for the side effects of plotting agricultural productivity change by GCAM commodity
#' @keywords internal
#' @noRd

plot_agprodchange <- function(data = NULL,
                              commodity = NULL,
                              output_dir = NULL) {
  AgProductionTechnology <- crop <- mgmt <- year <- AgProdChange <- region <-
    irrtype <- NULL

  save_path <- file.path(output_dir, "figures_agprodchange")
  if (!dir.exists(save_path)) {
    dir.create(save_path, recursive = TRUE)
  }

  print(paste0("Plotting Productivity Change for ", commodity, " to: ", file.path(save_path, paste0(commodity, ".png"))))


  data.table::setDT(data)
  df_plot <- data[
    , c("crop", "GLU", "irrtype", "mgmt") := data.table::tstrsplit(AgProductionTechnology, "_", fixed = TRUE)
  ][
    crop == commodity  # Apply filtering condition
  ]

  cropmodel <- unique(df_plot$cropmodel)
  climatemodel <- unique(df_plot$climatemodel)
  scenario <- unique(df_plot$scenario)


  if (nrow(df_plot > 0)) {
    p <- ggplot2::ggplot(
      data = df_plot,
      ggplot2::aes(
        x = year, y = AgProdChange,
        group = interaction(region, GLU, irrtype, mgmt)
      )
    ) +
      ggplot2::geom_line(ggplot2::aes(color = irrtype, linetype = mgmt), show.legend = T) +
      ggplot2::facet_wrap(~region) +
      ggplot2::labs(
        title = paste(cropmodel, climatemodel, scenario, commodity, sep = " | "),
        x = NULL,
        y = "Agriculture Productivity Change"
      ) +
      ggplot2::scale_color_manual(values = c(
        "IRR" = "#FFB900",
        "RFD" = "#5773CC"
      )) +
      ggplot2::scale_linetype_manual(values = c(
        "hi" = "solid",
        "lo" = "dashed"
        )) +
      ggplot2::theme_bw()


    ggplot2::ggsave(p,
      filename = file.path(save_path, paste0(commodity, ".png")),
      height = 10, width = 10, dpi = 150
    )
  } else {
    print(paste0("No data for ", commodity))
  }
}
