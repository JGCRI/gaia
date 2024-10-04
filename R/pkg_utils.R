# Helper Functions

# ------------------------------------------------------------------------------
#' pkg_example
#'
#' list example file paths
#'
#' @param path Default = NULL. String for path to example files
#' @export

pkg_example <- function(path = NULL) {

  if (is.null(path)) {
    dir(system.file('extras', package = 'gaia'))
  } else {
    system.file('extras', path, package = 'gaia', mustWork = TRUE)
  }

}

# ------------------------------------------------------------------------------
#' path_check
#'
#' check if file format is correct and file exists
#'
#' @param path Path to the file
#' @param file_type extension of the file
#' @keywords internal
#' @export

path_check <- function(path = NULL, file_type = NULL) {


  is_file <- FALSE
  file_exist <- FALSE

  is_folder <- FALSE
  folder_exist <- FALSE

  if(utils::file_test('-f', path)){

    is_file <- TRUE
    file_exist <- TRUE

    # check if file is NetCDF
    if (!is.null(file_type)) {
      if(!any(grepl(file_type, path))) {
        stop(paste0("Please provide", file_type, " file."))
      }
    }

  } else if (utils::file_test('-d', path)) {
    is_folder <- TRUE
    folder_exist <- TRUE
  } else {

    stop(paste0("Path: ", path, " does not exist. Please provide valid path."))
  }


}

# ------------------------------------------------------------------------------
#' get_nc_time
#'
#' get the netcdf file time series
#'
#' @param nc_file string for path to the nc file
#' @keywords internal
#' @export

get_nc_time <- function(nc_file = NULL)
{
  nc <- ncdf4::nc_open(nc_file)

  # get netcdf dimensions
  ncdims <- names(nc$dim)

  # find time variable
  timevar <- ncdims[which(ncdims %in% c("time", "Time", "datetime", "Datetime", "date", "Date"))[1]]
  times <- ncdf4::ncvar_get(nc, timevar)

  if (length(timevar) == 0) {
    stop("ERROR! Could not identify the correct time variable")
  }

  # use CFtime package to get the time information from ncdf
  cf <- CFtime::CFtime(
    definition = nc$dim[timevar]$time$units,
    calendar = nc$dim[timevar]$time$calendar,
    offsets = nc$dim[timevar]$time$vals
  )

  # get start and end year
  start_yr <- range(cf, '%Y')[1]
  end_yr <- range(cf, '%Y')[2]

  # time period
  time_period <- seq(start_yr, end_yr, 1)

  return(time_period)
}

# ------------------------------------------------------------------------------
#' input_data
#'
#' read in data and output number of rows and columns and variable names
#'
#' @param folder_path Default = NULL. string for the folder path
#' @param input_file Default = NULL. string for the name of the csv file to be read in
#' @param skip_number Default = 0. integer for the number of rows to skip
#' @param quietly Default= FALSE. Logical. TRUE to output input data information; FALSE to silent.
#' @keywords internal
#' @export
input_data <- function(folder_path = NULL,
                       input_file = NULL,
                       skip_number = 0,
                       quietly = FALSE) {
  if(!quietly){
    message("Reading data... ", input_file)
  }

  # d <- utils::read.csv(file = file.path(folder_path, input_file),
  #                      skip = skip_number,
  #                      stringsAsFactors = FALSE, header = TRUE)
  d <- data.table::fread(
    file = file.path(folder_path, input_file),
    skip = skip_number,
    stringsAsFactors = FALSE,
    header = TRUE
  )

  if('V1' %in% colnames(d)){
    d$V1 <- NULL
  }

  if(!quietly){
    message(nrow(d), " rows")
    message(ncol(d), " columns")
    message('column names: ', paste(colnames(d), collapse = ", "))
  }

  return(d)
}


# ------------------------------------------------------------------------------
#' output_data
#'
#' write output
#'
#' @param data Default = NULL. data frame
#' @param save_path Default = NULL. string for path to the output folder
#' @param file_name Default = NULL. string for file name
#' @param is_figure Default = FALSE. binary for saving figure
#' @param data_info Default = 'Data'. string for describing the data information
#' @keywords internal
#' @export
output_data <- function(data = NULL,
                        save_path = file.path(getwd(), 'output'),
                        file_name = NULL,
                        is_figure = FALSE,
                        data_info = 'Data')
{

  if(!dir.exists(save_path)){
    dir.create(save_path, recursive = TRUE)
  }

  if(!is_figure){

    utils::write.csv( data, file.path(save_path, file_name) )

  } else {

    ggplot2::ggsave(
      plot = data,
      filename = file.path(save_path, file_name), width = 400, height = 300, units = "mm"  )

  }

  print(paste0(data_info, ' saved to: ', file.path(save_path, file_name)))

}

# ------------------------------------------------------------------------------
#' colname_replace
#'
#' Shorter command to replace column names
#'
#' @param d data frame
#' @param x string to be replaced
#' @param y replacing string
#' @keywords internal
#' @export
colname_replace <- function ( d, x, y )
{
  colnames( d )[ colnames( d ) == x ] <- y
  return( d )
}

# -----------------------------------------------------------------------------
#' merge_data
#'
#' Merge columns from two data frames using two variables
#'
#' @param d1 data frame
#' @param d2 data frame
#' @param x1 string for column name in d1
#' @param x2 string for column name in d2
#' @keywords internal
#' @export

merge_data <- function( d1, d2, x1, x2 )
{
  d1$id <- paste( d1[[x1]], d1[[x2]], sep = "_" )
  d2$id <- paste( d2[[x1]], d2[[x2]], sep = "_" )
  d1 <- merge( d1, d2, by = "id", all.x = TRUE )
  x1.x <- paste( x1, "x", sep = "." )
  x2.x <- paste( x2, "x", sep = "." )
  x1.y <- paste( x1, "y", sep = "." )
  x2.y <- paste( x2, "y", sep = "." )
  d1[[x1.y]] <- NULL
  d1[[x2.y]] <- NULL
  d1 <- gaia::colname_replace( d1, x1.x, x1 )
  d1 <- gaia::colname_replace( d1, x2.x, x2 )
  d1$id <- NULL
  return( d1 )
}


# ------------------------------------------------------------------------------
#' agprodchange_ref
#'
#' Get the reference agricultural productivity change based GCAM version
#'
#' @param gcam_version Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @param gcamdata_dir Default = NULL. string for directory to the gcamdata folder within the specific GCAM version. The gcamdata need to be run with drake to have the CSV outputs beforehand.
#' @keywords internal
#' @export

agprodchange_ref <- function(gcam_version = 'gcam7',
                             climate_scenario = NULL,
                             gcamdata_dir = NULL)
{

  year <- AgProdChange <- AgProdChange_ni <- region <- AgSupplySector <-
    AgSupplySubsector <- AgProductionTechnology <- high <- low <- ssp4 <- ref <- NULL

  if(!is.null(gcamdata_dir)){

    # If user provide their own gcamdata dirctory, then use user provided data
    gaia::path_check(gcamdata_dir)

    if(grepl('ssp1|ssp5', climate_scenario)){
      agprodchange_ag <- data.table::fread(file.path(gcamdata_dir, 'outputs', 'L2052.AgProdChange_irr_high.csv'))
    }else if(grepl('ssp3', climate_scenario)){
      agprodchange_ag <- data.table::fread(file.path(gcamdata_dir, 'outputs', 'L2052.AgProdChange_irr_low.csv'))
    }else if(grepl('ssp4', climate_scenario)){
      agprodchange_ag <- data.table::fread(file.path(gcamdata_dir, 'outputs', 'L2052.AgProdChange_irr_ssp4.csv'))
    }else{
      agprodchange_ag <- data.table::fread(file.path(gcamdata_dir, 'outputs', 'L2052.AgProdChange_ag_irr_ref.csv'))
    }

    agprodchange_ni <- dplyr::bind_rows(
      data.table::fread(file.path(gcamdata_dir, 'outputs', 'L2052.AgProdChange_bio_irr_ref.csv')),
      agprodchange_ag
      ) %>%
      dplyr::mutate(year = paste0('X', year)) %>%
      dplyr::rename(AgProdChange_ni = AgProdChange)

    agprodchange_ni <- dplyr::bind_rows(
      agprodchange_ni,
      agprodchange_ni %>%
        dplyr::select(-year, -AgProdChange_ni) %>%
        dplyr::distinct() %>%
        dplyr::mutate(year = 'X2015',
                      AgProdChange_ni = 0)
    )

  } else {

    # if user doesn't provide any gcamdata, then use default
    if(gcam_version == 'gcam6'){
      agprodchange_ni <- gaia::agprodchange_ni_gcam6
    }

    if(gcam_version == 'gcam7'){
      agprodchange_ni <- gaia::agprodchange_ni_gcam7
    }

    # filter based on the scenario
    if(grepl('ssp1|ssp5', climate_scenario)){
      # for ssp1 and ssp5
      agprodchange_ni <- agprodchange_ni %>%
        dplyr::select(region, AgSupplySector, AgSupplySubsector, AgProductionTechnology, year, AgProdChange_ni = high)

    }else if(grepl('ssp3', climate_scenario)){
      # for ssp3
      agprodchange_ni <- agprodchange_ni %>%
        dplyr::select(region, AgSupplySector, AgSupplySubsector, AgProductionTechnology, year, AgProdChange_ni = low)

    }else if(grepl('ssp4', climate_scenario)){
      # for ssp4
      agprodchange_ni <-agprodchange_ni %>%
        dplyr::select(region, AgSupplySector, AgSupplySubsector, AgProductionTechnology, year, AgProdChange_ni = ssp4)

    }else{
      # for both ssp2 and other non-ssp related climate scenarios (e.g., rcp45)
      agprodchange_ni <- agprodchange_ni %>%
        dplyr::select(region, AgSupplySector, AgSupplySubsector, AgProductionTechnology, year, AgProdChange_ni = ref)
    }

  }

  return(agprodchange_ni)
}

# ------------------------------------------------------------------------------
#' iso_replace
#'
#' ISO replacements for countries with non-standard names (can ad to as they come up)
#'
#' @param d data frame with country_name column
#' @keywords internal
#' @export
iso_replace <- function( d ){

  iso <- function( d, x, y )
  {
    d$iso <- ifelse( d$country_name == x, y, d$iso )
    return( d )
  }
  d <- iso( d, "Brunei", "brn" )
  d <- iso( d, "Burma (Myanmar)", "mmr" )
  d <- iso( d, "China, mainland", "chn")
  d <- iso( d, "China, Hong Kong SAR", "hkg" )
  d <- iso( d, "China, Taiwan Province of", "twn" )
  d <- iso( d, "Congo (Brazzaville)", "cog" )
  d <- iso( d, "Congo (Kinshasa)", "cod" )
  d <- iso( d, "Congo Rep.", "cog" ) # MZ
  d <- iso( d, "Cote dIvoire (IvoryCoast)", "civ" )
  d <- iso( d, "Cote Divoire", "civ" )
  d <- iso( d, "Cote d'Ivoire", "civ" )
  d <- iso( d, "C\x99te d'Ivoire", "civ" )
  d <- iso( d, "C\x92\x82te d'Ivoire", "civ" )
  d <- iso( d, "C\xed\xc7te d'Ivoire", "civ" )
  d <- iso( d, "C\xc8te d'Ivoire", "civ" )
  # d <- iso( d, "CÌ«te d'Ivoire", "civ" )
  d <- iso( d, "C\u00cc\u00abte d'Ivoire", "civ" )
  # d <- iso( d, "CÍte d'Ivoire", "civ" )
  d <- iso( d, "C\u00cd\u0089te d'Ivoire", "civ" )
  d <- iso( d, "Ethiopia PDR", "eth" )
  d <- iso( d, "Gambia, The", "gmb" )
  d <- iso( d, "Iran", "irn" )
  d <- iso( d, "Korea, North", "prk" )
  d <- iso( d, "Democratic People's Republic of Korea", "prk" )
  d <- iso( d, "Democratic Peoples Republic of Korea", "prk" )
  d <- iso( d, "North Korea", "prk" )
  d <- iso( d, "Korea, South", "kor" )
  d <- iso( d, "Korea", "kor" )
  d <- iso( d, "Republic of Korea", "kor" )
  d <- iso( d, "South Korea", "kor" )
  d <- iso( d, "Laos", "lao" )
  d <- iso( d, "Libya", "lby" )
  d <- iso( d, "Palestinian Territories", "pse" )
  d <- iso( d, "Russia", "rus" )
  d <- iso( d, "Sudan and South Sudan", "sdn" )
  d <- iso( d, "Syria", "syr" )
  d <- iso( d, "Tanzania", "tza" )
  d <- iso( d, "Vietnam", "vnm" )
  d <- iso( d, "Bel-lux", "bel" )
  d <- iso( d, "Belgium-Luxembourg", "bel" )
  d <- iso( d, "Bosnia Herzg", "bih" )
  d <- iso( d, "Brunei Darsm", "brn" )
  d <- iso( d, "Cent Afr Rep", "caf" )
  d <- iso( d, "Czech Rep", "cze" )
  d <- iso( d, "Czech Rep.", "cze" )
  d <- iso( d, "Former Czechoslovakia", "cze" )
  d <- iso( d, "Czechoslovakia", "cze" )
  d <- iso( d, "Dominican Rp", "dom" )
  d <- iso( d, "Eq Guinea", "gnq" )
  d <- iso( d, "Fr Guiana", "guf" )
  d <- iso( d, "Guineabissau", "gnb" )
  d <- iso( d, "Iran", "irn" )
  d <- iso( d, "Laos", "lao" )
  d <- iso( d, "Libya", "lby" )
  d <- iso( d, "Macedonia", "mkd" )
  d <- iso( d, "Moldova Rep", "mda" )
  d <- iso( d, "Papua N Guin", "png" )
  d <- iso( d, "Russian Fed", "rus" )
  d <- iso( d, "Syria", "syr" )
  d <- iso( d, "Tanzania", "tza" )
  d <- iso( d, "Trinidad Tob", "tto" )
  d <- iso( d, "Uk", "gbr" )
  d <- iso( d, "Great Britain", "gbr" )
  d <- iso( d, "Untd Arab Em", "are" )
  d <- iso( d, "United States", "usa" )
  d <- iso( d, "Usa", "usa" )
  d <- iso( d, "USA", "usa" )
  d <- iso( d, "Yugoslav Fr", "yug" )
  d <- iso( d, "Zaire", "cod" )
  d <- iso( d, "Brunei", "brn" )
  d <- iso( d, "Central African Rep.", "caf" )
  d <- iso( d, "Congo DRC", "cod" )
  d <- iso( d, "Moldova", "mda" )
  d <- iso( d, "Russia", "rus" )
  d <- iso( d, "Vietnam", "vnm" )
  d <- iso( d, "Bosnia & Herzegovina", "bih" )
  d <- iso( d, "Cayman Is.", "cym" )
  d <- iso( d, "Cook Is.", "cok" )
  d <- iso( d, "Falkland Is.", "flk" )
  d <- iso( d, "Faroe Is.", "fro" )
  d <- iso( d, "Marshall Is.", "mhl" )
  d <- iso( d, "Micronesia", "fsm" )
  d <- iso( d, "Occupied Palestinian Territory", "pse" )
  d <- iso( d, "Sao Tome & Principe", "stp" )
  d <- iso( d, "Solomon Is.", "slb" )
  d <- iso( d, "St. Kitts & Nevis", "kna" )
  d <- iso( d, "St. Kitts and Nevis", "kna" )
  d <- iso( d, "St. Lucia", "lca" )
  d <- iso( d, "St. Vincent & the Grenadines", "vct" )
  d <- iso( d, "St.Vincent and Grenadines", "vct" )
  d <- iso( d, "Saint Vincent/Grenadines", "vct" )
  d <- iso( d, "Svalbard", "sjm" )
  d <- iso( d, "Jan Mayen", "sjm" ) # MZ
  d <- iso( d, "The Bahamas", "bhs" )
  d <- iso( d, "The Gambia", "gmb" )
  d <- iso( d, "Timor-Leste", "tls" )
  d <- iso( d, "Trinidad & Tobago", "tto" )
  d <- iso( d, "Turks & Caicos Is.", "tca" )
  d <- iso( d, "Virgin Is.", "vir" )
  d <- iso( d, "Bahamas, The", "bhs" )
  d <- iso( d, "Falkland Islands (Islas Malvinas)", "flk" )
  # d <- iso( d, "Former Serbia and Montenegro", "" )
  # d <- iso( d, "Former U.S.S.R.", "" )
  d <- iso( d, "Former Yugoslavia", "yug" )
  d <- iso( d, "Yugoslav SFR", "yug" )
  # d <- iso( d, "Germany, East", "" )
  # d <- iso( d, "Germany, West", "" )
  # d <- iso( d, "Hawaiian Trade Zone", "" )
  d <- iso( d, "Timor-Leste (East Timor)", "tls" )
  d <- iso( d, "Turks and Caicos Islands", "tca" )
  #   d <- iso( d, "U.S. Pacific Islands", "" )
  d <- iso( d, "Virgin Islands,  U.S.", "vir" )
  d <- iso( d, "Antigua and Barbuda", "atg" )
  d <- iso( d, "Bolivia (Plurinational State of)", "bol" )
  d <- iso( d, "British Virgin Islands", "vgb" )
  d <- iso( d, "Cabo Verde", "cpv" )
  d <- iso( d, "Democratic Republic of the Congo", "cod" )
  d <- iso( d, "Iran (Islamic Republic of)", "irn" )
  d <- iso( d, "Lao People's Democratic Republic", "lao" )
  d <- iso( d, "Libya", "lby" )
  d <- iso( d, "Micronesia (Federated States of)", "fsm" )
  d <- iso( d, "R\x8eunion", "reu" )
  d <- iso( d, "RÌ©union", "reu" )
  d <- iso( d, "R\x92\xa9union", "reu" )
  d <- iso( d, "R\xed\xa9union", "reu" )
  d <- iso( d, "RÍ©union", "reu" ) # MZ
  d <- iso( d, "Republic of Moldova", "mda" )
  d <- iso( d, "Saint Helena, Ascension and Tristan da Cunha", "shn" )
  d <- iso( d, "St. Helena", "shn" ) # MZ
  d <- iso( d, "St. Pierre & Miquelon", "spm" )  # MZ
  d <- iso( d, "South Sudan", "ssd" )
  d <- iso( d, "Sudan (former)", "sdn" )
  d <- iso( d, "The former Yugoslav Republic of Macedonia", "mkd" )
  d <- iso( d, "Turks and Caicos Islands", "tca" )
  d <- iso( d, "United Republic of Tanzania", "tza" )
  d <- iso( d, "United States Virgin Islands", "vir" )
  d <- iso( d, "USSR", "svu" )
  d <- iso( d, "Venezuela (Bolivarian Republic of)", "ven" )
  d <- iso( d, "Wallis and Futuna Islands", "wlf" )
  d <- iso( d, "Wallis & Futuna", "wlf" ) # MZ
  d <- iso( d, "West Bank and Gaza Strip", "pse" )
  d <- iso( d, "West Bank", "pse" ) # MZ
  d <- iso( d, "Gaza Strip", "pse" ) # MZ
  d <- iso( d, "Pitcairn Is.", "pcn" ) # MZ
  # d <- iso( d, "Wake Insland", "" )
  ## Country code for Romania is sometimes "rom" and sometimes "rou"
  d <- iso( d, "Romania", "rou" )
  return ( d )
}


# ------------------------------------------------------------------------------
#' get_example_data
#'
#' @param download_url Link to the downloadable dataset
#' @param file_extension String of file extension without "."
#' @param data_dir Path of desired location to download data
#'
#' @export

get_example_data <- function(download_url = '',
                             file_extension = 'zip',
                             data_dir = file.path(getwd(), 'example')){


  # Download
  message('Starting download.')

  # seek and construct filename from extension
  base_filename <- basename(download_url) %>%
    tolower()

  fname <- strsplit(base_filename, split = tolower(file_extension))[[1]][1] %>%
    paste0(file_extension)

  dest_file <- file.path(data_dir, fname)
  out_dir <- file.path(data_dir, strsplit(fname, split = paste0('.', file_extension)))[[1]][1]

  if(!dir.exists(file.path(out_dir))){

    utils::download.file(url = download_url,
                         destfile = dest_file,
                         mode = 'wb')

    message('Download complete.')

    # Unzip
    message('Starting unzip.')

    utils::unzip(zipfile = file.path(data_dir, fname),
                 exdir = out_dir)

    file.remove(dest_file)

    message(paste0('Data unzipped to: ', out_dir))

  } else {

    message('Example data already exists.')

  }

  return(out_dir)


}
