#' crop_calendars
#'
#' Generate planting months for each country
#' Data from SAGE
#'
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @importFrom magrittr %>%
#' @importFrom data.table :=
#' @export

crop_calendars <- function(output_dir = file.path(getwd(), 'output')){

  iso <- crop <- NULL

  message('Starting Step: crop_calendars')

  # load SAGE data
  d <- sage

  # format, subset data and replace location name
  d$Location <- ifelse( d$Location == "Georgia" & d$Source == "USDA UPHD", "Georgia_USA", d$Location )
  d <- subset( d, select = c( "Data.ID", "Location", "Crop", "Qualifier", "Plant.start", "Plant.end", "Harvest.start", "Harvest.end" ) )
  d <- gaea::colname_replace( d, "Location", "country_name" )
  d <- gaea::colname_replace( d, "Crop", "crop" )
  d$crop <- tolower( d$crop )

  # Average plant and harvest month
  d$plant <- ifelse( d$Plant.start < d$Plant.end, ( ( d$Plant.start + d$Plant.end ) / 2 / 30 ), ( ( d$Plant.start + d$Plant.end + 365 ) / 2 / 30 ) )
  d$plant <- ceiling( ifelse( d$plant > 12, d$plant - 12, d$plant ) )
  d$plant <- ifelse( d$crop == "sugarcane", 1, d$plant ) # Sugarcane is a multiyear crop, will assume that 12 months preceding annual value equals growing season.
  d$harvest <- ifelse( d$Harvest.start < d$Harvest.end, ( ( d$Harvest.start + d$Harvest.end ) / 2 ) / 30, ( ( d$Harvest.start + d$Harvest.end + 365 ) / 2 ) / 30 )
  d$harvest <- ceiling( ifelse( d$harvest > 12, d$harvest - 12, d$harvest ) )
  d$harvest <- ifelse( d$crop == "sugarcane", 12, d$harvest ) # Sugarcane is a multiyear crop, will assume that 12 months preceding annual value equals growing season.

  # Country codes
  d <- merge( d, mapping_gcam_iso, by = "country_name", all.x = TRUE )
  d <- gaea::iso_replace( d )

  # Indicators for crops
  crops <- tibble::tibble(
    crop_mirca = c('wheat', 'sorghum', 'maize', 'rice', 'soybean', 'sugarcane', 'sugarbeet', 'cotton', 'cassava', 'root_tuber', 'sunflower'),
    crop_sage = c('wheat', 'sorghum', 'maize', 'rice', 'soybeans', 'sugarcane', 'sugarbeets', 'cotton', 'cassava', 'potatoes', 'sunflower')
  )

  for(i in 1:nrow(crops)){

    d <- d %>%
      dplyr::mutate(!!paste0(crops$crop_mirca[i]) := ifelse( !is.na( iso ) & (crop == crops$crop_sage[i]), 1, 0 ))
  }


  # ----------------------------------------------------------------------------
  # Deal with exceptions (countries by states or regions)
  # ----------------------------------------------------------------------------
  # Let USA be represented by state with most production in each crop
  d$iso <- ifelse( d$country_name == "Iowa" & d$crop == "maize", "usa", d$iso )
  d$maize <- ifelse( d$country_name == "Iowa" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( d$country_name == "North Dakota" & d$crop == "wheat" & d$Qualifier == "", "usa", d$iso )
  d$wheat <- ifelse( d$country_name == "North Dakota" & d$crop == "wheat" & d$Qualifier == "", 1, d$wheat )
  d$iso <- ifelse( ( d$country_name == "Illinois" & d$crop == "soybeans" ), "usa", d$iso )
  d$soybean <- ifelse( d$country_name == "Illinois" & d$crop == "soybeans", 1, d$soybean )
  d$iso <- ifelse( ( d$country_name == "Arkansas" & d$crop == "rice" ), "usa", d$iso )
  d$rice <- ifelse( d$country_name == "Arkansas" & d$crop == "rice", 1, d$rice )
  d$iso <- ifelse( ( d$country_name == "Florida" & d$crop == "sugarcane" ), "usa", d$iso )
  d$sugarcane <- ifelse( d$country_name == "Florida" & d$crop == "sugarcane", 1, d$sugarcane )
  d$iso <- ifelse( ( d$country_name == "Minnesota" & d$crop == "sugarbeets" ), "usa", d$iso )
  d$sugarbeet <- ifelse( d$country_name == "Minnesota" & d$crop == "sugarbeets", 1, d$sugarbeet )
  d$iso <- ifelse( ( d$country_name == "Kansas" & d$crop == "sorghum" ), "usa", d$iso )
  d$sorghum <- ifelse( d$country_name == "Kansas" & d$crop == "sorghum", 1, d$sorghum )
  d$iso <- ifelse( ( d$country_name == "Texas" & d$crop == "cotton" ), "usa", d$iso )
  d$cotton <- ifelse( d$country_name == "Texas" & d$crop == "cotton", 1, d$cotton )
  d$iso <- ifelse( ( d$country_name == "Idaho" & d$crop == "potatoes" ), "usa", d$iso )
  d$root_tuber <- ifelse( d$country_name == "Idaho" & d$crop == "potatoes", 1, d$root_tuber )
  d$iso <- ifelse( ( d$country_name == "North Dakota" & d$crop == "sunflower" ), "usa", d$iso ) #North Dakota or Kansas
  d$sunflower <- ifelse( d$country_name == "North Dakota" & d$crop == "sunflower", 1, d$sunflower )

  # Mexico (http://www.pecad.fas.usda.gov/highlights/2012/08/Mexico_corn/)
  d$iso <- ifelse( d$country_name == "Mexico (not northwest)" & d$crop == "maize", "mex", d$iso )
  d$maize <- ifelse( d$country_name == "Mexico (not northwest)" & d$crop == "maize", 1, d$maize )
  # Duplicate listing for Mexico (iso ID -- mex)
  # Sorghum seasonality in Mexico: http://gain.fas.usda.gov/Recent%20GAIN%20Publications/Grain%20and%20Feed%20Annual_Mexico%20City_Mexico_3-18-2015.pdf
  d$sorghum <- ifelse( d$country_name == "Mexico" & d$crop == "sorghum" & d$Data.ID != 733, 0, d$sorghum )

  # India
  d$iso <- ifelse( ( d$country_name == "West Bengal" & d$crop == "rice" & d$Data.ID == 1527 ), "ind", d$iso )
  d$rice <- ifelse( d$country_name == "West Bengal" & d$crop == "rice" & d$Data.ID == 1527, 1, d$rice )
  d$iso <- ifelse( ( d$country_name == "Gujarat" & d$crop == "wheat" & d$Data.ID == 1342 ), "ind", d$iso )
  d$wheat <- ifelse( d$country_name == "Gujarat" & d$crop == "wheat" & d$Data.ID == 1342, 1, d$wheat )
  d$iso <- ifelse( ( d$country_name == "India (North)" & d$crop == "cotton" ), "ind", d$iso )
  d$cotton <- ifelse( d$country_name == "India (North)" & d$crop == "cotton", 1, d$cotton )
  d$iso <- ifelse( ( d$country_name == "Maharashtra" & d$crop == "sugarcane" ), "ind", d$iso )
  d$sugarcane <- ifelse( d$country_name == "Maharashtra" & d$crop == "sugarcane", 1, d$sugarcane )
  # West Bengal is the largest producer of potatoes among the states listed in India
  d$iso <- ifelse( ( d$country_name == "West Bengal" & d$crop == "potatoes" & d$Data.ID == 1540 ), "ind", d$iso )
  d$root_tuber <- ifelse( d$country_name == "West Bengal" & d$crop == "potatoes" & d$Data.ID == 1540, 1, d$root_tuber )
  # Maharashtra has the highest production of sorghum than all other Indian provinces (Rajasthan, Tamil Nadu, Andhra Pradesh, and Karnataka)
  d$iso <- ifelse( ( d$country_name == "Maharashtra" & d$crop == "sorghum" & d$Data.ID == 1407 ), "ind", d$iso )
  d$sorghum <- ifelse( d$country_name == "Maharashtra" & d$crop == "sorghum" & d$Data.ID == 1407, 1, d$sorghum )
  d$iso <- ifelse( ( d$country_name == "Maharashtra" & d$crop == "sunflower" ), "ind", d$iso ) # Only Indian state with crop calendar info for sunflower
  d$sunflower <- ifelse( d$country_name == "Maharashtra" & d$crop == "sunflower", 1, d$sunflower )

  # China
  d$iso <- ifelse( d$country_name == "China" & d$crop == "rice" & ( d$Data.ID == 692 | d$Data.ID == 691 ), NA, d$iso ) # Three rice entries for China, remove two extremes of plant/harvest months (3-6 & 7-11)
  d$rice <- ifelse( d$country_name == "China" & d$crop == "rice" & d$Data.ID == 690, 1, d$rice ) # Keep observation with mid-range of planting/harvesting months (5-9)
  d$iso <- ifelse( ( d$country_name == "China (north)" & d$crop == "wheat" ), "chn", d$iso ) # Use non-winter wheat months
  d$wheat <- ifelse( d$country_name == "China (north)" & d$crop == "wheat", 1, d$wheat )
  d$iso <- ifelse( d$country_name == "China" & d$crop == "cotton", NA, d$iso ) # Remove "China" cotton months, use "China (Sichuan, Hubei and Hunan)"
  d$iso <- ifelse( ( d$country_name == "China (Sichuan, Hubei and Hunan)" & d$crop == "cotton" ), "chn", d$iso )
  d$cotton <- ifelse( d$country_name == "China (Sichuan, Hubei and Hunan)" & d$crop == "cotton", 1, d$cotton )
  d$iso <- ifelse( ( d$country_name == "China (North China Plain and Manchuria)" & d$crop == "soybeans" ), "chn", d$iso )
  d$soybean <- ifelse( d$country_name == "China (North China Plain and Manchuria)" & d$crop == "soybeans", 1, d$soybean )
  d$iso <- ifelse( ( d$country_name == "China (North China Plain and Manchuria)" & d$crop == "maize" ), "chn", d$iso )
  d$maize <- ifelse( d$country_name == "China (North China Plain and Manchuria)" & d$crop == "maize", 1, d$maize )

  # Australia
  d$iso <- ifelse( ( d$country_name == "Queensland" & d$crop == "maize" ), "aus", d$iso )
  d$maize <- ifelse( d$country_name == "Queensland" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Queensland" & d$crop == "cotton" ), "aus", d$iso )
  d$cotton <- ifelse( d$country_name == "Queensland" & d$crop == "cotton", 1, d$cotton )
  d$iso <- ifelse( ( d$country_name == "Western Australia" & d$crop == "wheat" ), "aus", d$iso )
  d$wheat <- ifelse( d$country_name == "Western Australia" & d$crop == "wheat", 1, d$wheat )
  d$iso <- ifelse( ( d$country_name == "South Australia" & d$crop == "potatoes" ), "aus", d$iso )
  d$root_tuber <- ifelse( d$country_name == "South Australia" & d$crop == "potatoes" & d$Qualifier == "Early", 1, d$root_tuber )
  # Queensland, a state of Australia (iso ID == aus), accounts for 60% of sorghum production (New South Wales delimited)
  d$iso <- ifelse( ( d$country_name == "Queensland" & d$crop == "sorghum" ), "aus", d$iso )
  d$sorghum <- ifelse( d$country_name == "Queensland" & d$crop == "sorghum", 1, d$sorghum )

  # Thailand
  d$iso <- ifelse( ( d$country_name == "Thailand (NE)" & d$crop == "sugarcane" ), "tha", d$iso )
  d$sugarcane <- ifelse( d$country_name == "Thailand (NE)" & d$crop == "sugarcane", 1, d$sugarcane )

  # Vietnam
  d$iso <- ifelse( ( d$country_name == "Vietnam (South)" & d$crop == "rice" ), "vnm", d$iso )
  d$rice <- ifelse( d$country_name == "Vietnam (South)" & d$crop == "rice", 1, d$rice )

  # Brazil (http://www.pecad.fas.usda.gov/rssiws/al/br_cropprod_s.htm;
  # http://www.pecad.fas.usda.gov/rssiws/al/br_cropprod_s.htm?commodity=Wheat&country=Brazil;
  # http://www.pecad.fas.usda.gov/highlights/2007/03/brazil_rice_30mar2007/RiceProductionMap.htm)
  d$iso <- ifelse( ( d$country_name == "Brazil (Center-South)" & d$crop == "rice" ), "bra", d$iso )
  d$rice <- ifelse( d$country_name == "Brazil (Center-South)" & d$crop == "rice", 1, d$rice )
  d$iso <- ifelse( ( d$country_name == "Brazil (Northeast)" & d$crop == "cotton" ), "bra", d$iso )
  d$cotton <- ifelse( d$country_name == "Brazil (Northeast)" & d$crop == "cotton", 1, d$cotton )
  d$iso <- ifelse( ( d$country_name == "Brazil (Center-South)" & d$crop == "maize" ), "bra", d$iso )
  d$maize <- ifelse( d$country_name == "Brazil (Center-South)" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Brazil (Northeast)" & d$crop == "sugarcane" ), "bra", d$iso )
  d$sugarcane <- ifelse( d$country_name == "Brazil (Northeast)" & d$crop == "sugarcane", 1, d$sugarcane )
  d$iso <- ifelse( ( d$country_name == "Brazil (Rio Grande do Sul)" & d$crop == "wheat" ), "bra", d$iso )
  d$wheat <- ifelse( d$country_name == "Brazil (Rio Grande do Sul)" & d$crop == "wheat", 1, d$wheat )

  # Congo Dem Rep
  d$iso <- ifelse( ( d$country_name == "Congo Dem. Rep." & d$crop == "sorghum" ), "cod", d$iso )
  d$sorghum <- ifelse( d$country_name == "Congo Dem. Rep" & d$crop == "sorghum", 1, d$sorghum )
  d$iso <- ifelse( ( d$country_name == "Congo Dem. Rep. (South)" & d$crop == "maize" ), "cod", d$iso )
  d$maize <- ifelse( d$country_name == "Congo Dem. Rep. (South)" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Congo Dem. Rep. (South)" & d$crop == "rice" ), "cod", d$iso )
  d$rice <- ifelse( d$country_name == "Congo Dem. Rep. (South)" & d$crop == "rice", 1, d$rice )
  # Congo iso ID is "cod" -- the problem country-crop combination is with yams
  d$iso <- ifelse( ( d$country_name == "Congo Dem. Rep." & d$crop == "yam" ), "cod", d$iso )
  d$root_tuber <- ifelse( d$country_name == "Congo Dem. Rep." & d$crop == "yam", 1, d$root_tuber )
  # The Northern region of the Democtratic Republic of the Congo has a majority of cassava production by acres planted and harvested
  d$iso <- ifelse( ( d$country_name == "Congo Dem. Rep. (North)" & d$crop == "cassava" ), "cod", d$iso )
  d$cassava <- ifelse( d$country_name == "Congo Dem. Rep. (North)" & d$crop == "cassava", 1, d$cassava )
  d$cassava <- ifelse( ( d$country_name == "Congo Dem. Rep. (South)" & d$crop == "cassava" ), 0, d$cassava )

  # Ghana
  d$iso <- ifelse( ( d$country_name == "Ghana (South)" & d$crop == "rice" ), "gha", d$iso )
  d$rice <- ifelse( d$country_name == "Ghana (South)" & d$crop == "rice", 1, d$rice )
  d$iso <- ifelse( ( d$country_name == "Ghana (North)" & d$crop == "maize" ), "gha", d$iso )
  d$maize <- ifelse( d$country_name == "Ghana (North)" & d$crop == "maize", 1, d$maize )

  # Uganda
  d$iso <- ifelse( ( d$country_name == "Uganda (North)" & d$crop == "maize" ), "uga", d$iso )
  d$maize <- ifelse( d$country_name == "Uganda (North)" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Uganda (South)" & d$crop == "cassava" ), "uga", d$iso )
  d$cassava <- ifelse( d$country_name == "Uganda (South)" & d$crop == "cassava", 1, d$cassava )
  # # Uganda (iso ID == uga) listed as Uganda (North) for sweet_potato
  # d$iso <- ifelse( ( d$country_name == "Uganda (North)" & d$crop == "sweet.potatoes" ), "uga", d$iso )
  # d$root_tuber <- ifelse( d$country_name == "Uganda (North)" & d$crop == "sweet.potatoes", 1, d$root_tuber )

  # Indonesia
  d$iso <- ifelse( ( d$country_name == "Indonesia (S. Sumatra & E. Java)" & d$crop == "maize" ), "idn", d$iso )
  d$maize <- ifelse( d$country_name == "Indonesia (S. Sumatra & E. Java)" & d$crop == "maize", 1, d$maize )
  d$maize <- ifelse( d$country_name == "Indonesia", 0, d$maize ) # "Indonesia" planting dates are opposite from subregion dates and from what they would be expected to be in S. hemisphere
  d$iso <- ifelse( ( d$country_name == "Indonesia (Sumatra)" & d$crop == "rice" ), "idn", d$iso )
  d$rice <- ifelse( d$country_name == "Indonesia (Sumatra)" & d$crop == "rice" & d$Qualifier == "", 1, d$rice )

  # Malaysia
  d$iso <- ifelse( d$country_name == "Malaysia (Sarawak prov.)" & d$crop == "rice", d$iso == "mys", d$iso )
  d$rice <- ifelse( d$country_name == "Malaysia (Sarawak prov.)" & d$crop == "rice", 1, d$rice )

  # Russia: All Russian regions have missing harvest end dates
  # "Saratov", "Voronezh", "Stavropol Krai", "Orenburg", "Novosibirsk and Omsk", "Altai Krai", "Bashkir ASSR", "Chelyabinsk", "Kursk"
  d$iso <- ifelse( ( d$country_name == "Saratov" & d$crop == "wheat" & d$Qualifier == "Winter" ), "rus", d$iso ) # Russian wheat is ~2/3 winter wheat
  d$wheat <- ifelse( d$country_name == "Saratov" & d$crop == "wheat", 1, d$wheat )
  # Assume harvest month = plant month (9) + 5 months www.usda.gov/oce/.../russia/russia_wheat.pdf
  d$harvest <- ifelse( d$iso == "rus" & d$wheat == 1, d$plant + 4 - 12, d$harvest )

  # Ukraine: All subregions in Ukraine have missing harvest end dates. Use only country_name == "Ukraine"
  # http://www.pecad.fas.usda.gov/highlights/2009/02/ukr_12feb2009/; http://wdc.org.ua/en/node/29
  # "Ukraine" planting season in these data is summer time, 95% of wheat is winter wheat, use "Eastern and Southern Ukraine" crop calendar instead
  d$wheat <- ifelse( ( d$country_name == "Ukraine" & d$crop == "wheat" ), 0, d$wheat )
  d$iso <- ifelse( ( d$country_name == "Eastern and Southern Ukraine" & d$crop == "wheat" ), "ukr", d$iso ) # Major wheat producing region
  d$wheat <- ifelse( d$country_name == "Eastern and Southern Ukraine" & d$crop == "wheat", 1, d$wheat )
  d$harvest <- ifelse( d$iso == "ukr" & d$wheat == 1, d$plant + 8 - 12, d$harvest ) # http://wdc.org.ua/en/node/29
  d$iso <- ifelse( ( d$country_name == "Eastern and Southern Ukraine" & d$crop == "maize" ), "ukr", d$iso ) # Major maize producing region
  d$maize <- ifelse( d$country_name == "Eastern and Southern Ukraine" & d$crop == "maize", 1, d$maize )
  d$harvest <- ifelse( d$iso == "ukr" & d$maize == 1, d$plant + 5, d$harvest  )

  # Tanzania
  d$iso <- ifelse( ( d$country_name == "Tanzania (South)" & d$crop == "maize" ), "tza", d$iso )
  d$maize <- ifelse( d$country_name == "Tanzania (South)" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Tanzania (North)" & d$crop == "wheat" ), "tza", d$iso )
  d$wheat <- ifelse( d$country_name == "Tanzania (North)" & d$crop == "wheat", 1, d$wheat )
  # Northern regional sorghum production in Tanzania (iso ID == tza) accounts for the most harvested area and yields compared to Tanzania (South)
  d$iso <- ifelse( ( d$country_name == "Tanzania (North)" & d$crop == "sorghum" & d$Data.ID == 577 ), "tza", d$iso )
  d$sorghum <- ifelse( d$country_name == "Tanzania (North)" & d$crop == "sorghum" & d$Data.ID == 577, 1, d$sorghum )
  # Two seasons: http://pecad.fas.usda.gov/highlights/2015/09/TZ/index.htm
  # Cotton is generally planted in northwestern Tanzania in December, with harvesting and marketing beginning in late June or early July.
  d$cotton <- ifelse( d$country_name == "Tanzania" & d$crop == "cotton" & d$Data.ID == 1766, 0, d$cotton )

  # Canada
  d$iso <- ifelse( ( d$country_name == "Canadian Prairies (Alberta, Saskatchewan, Manitoba)" & d$crop == "wheat" ), "can", d$iso )
  d$wheat <- ifelse( d$country_name == "Canadian Prairies (Alberta, Saskatchewan, Manitoba)" & d$crop == "wheat", 1, d$wheat )
  d$iso <- ifelse( ( d$country_name == "Ontario & Quebec" & d$crop == "maize" ), "can", d$iso )
  d$maize <- ifelse( d$country_name == "Ontario & Quebec" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Ontario & Quebec" & d$crop == "soybeans" ), "can", d$iso )
  d$soybean <- ifelse( d$country_name == "Ontario & Quebec" & d$crop == "soybeans", 1, d$soybean )

  # South Africa
  d$iso <- ifelse( ( d$country_name == "South Africa (East)" & d$crop == "maize" ), "zaf", d$iso )
  d$maize <- ifelse( d$country_name == "South Africa (East)" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "South Africa (except Western Cape)" & d$crop == "wheat" ), "zaf", d$iso )
  d$wheat <- ifelse( d$country_name == "South Africa (except Western Cape)" & d$crop == "wheat", 1, d$wheat )

  # Central African Republic
  d$iso <- ifelse( d$country_name == "Central African Republic (South)" & d$crop == "maize" & d$Qualifier == "", "caf", d$iso )
  d$maize <- ifelse( d$country_name == "Central African Republic (South)" & d$crop == "maize" & d$Qualifier == "", 1, d$maize )

  # Sudan
  d$iso <- ifelse( ( d$country_name == "Sudan (South)" & d$crop == "maize" ), "sdn", d$iso )
  d$maize <- ifelse( d$country_name == "Sudan (South)" & d$crop == "maize", 1, d$maize )
  d$iso <- ifelse( ( d$country_name == "Sudan (South)" & d$crop == "sorghum" ), "sdn", d$iso )
  d$sorghum <- ifelse( d$country_name == "Sudan (South)" & d$crop == "sorghum", 1, d$sorghum )

  # Nigeria
  d$iso <- ifelse( ( d$country_name == "Nigeria (North)" & d$Data.ID == 457 & d$crop == "maize" ), "nga", d$iso )
  d$maize <- ifelse( d$country_name == "Nigeria (North)" & d$Data.ID != 457, 0, d$maize )
  d$rice <- ifelse( d$country_name == "Nigeria" & d$crop == "rice" & d$Data.ID != 1723, 0, d$rice )
  # d$cotton <- ifelse( d$country_name == "Nigeria" & d$crop == "cotton" & d$Data.ID == 1727, 1, d$cotton )
  d$cotton <- ifelse( d$country_name == "Nigeria" & d$crop == "cotton" & d$Qualifier == "South", 0, d$cotton )
  d$cotton <- ifelse( d$country_name == "Nigeria" & d$crop == "cotton" & d$Qualifier == "East", 0, d$cotton )
  d$soybean <- ifelse( d$country_name == "Nigeria" & d$crop == "soybeans" & d$Data.ID == 1731, 0, d$soybean )
  # # Highest production by planting and harvesting months: https://research.cip.cgiar.org/confluence/display/WSA/Nigeria
  # d$iso <- ifelse( ( d$country_name == "Nigeria" & d$crop == "sweet.potatoes" & d$Data.ID == 1735 ), "nga", d$iso )
  # d$root_tuber <- ifelse( d$country_name == "Nigeria" & d$crop == "sweet.potatoes" & d$Data.ID == 1735, 1, d$root_tuber )
  # Nigeria (South) should be affiliated with iso ID == nga
  d$iso <- ifelse( ( d$country_name == "Nigeria (South)" & d$crop == "cassava" ), "nga", d$iso )
  d$cassava <- ifelse( d$country_name == "Nigeria (South)" & d$crop == "cassava", 1, d$cassava )

  # Burundi (two listings, use the one with southern hemisphere summer (October-January) months)
  d$sorghum <- ifelse( d$country_name == "Burundi" & d$crop == "sorghum" & d$Qualifier == "2", 0, d$sorghum )

  # Zimbabwe
  d$wheat <- ifelse( d$country_name == "Zimbabwe" & d$Qualifier == "Winter", 0, d$wheat )

  # Turkey
  d$wheat <- ifelse( d$country_name == "Turkey" & d$Qualifier == "Winter", 0, d$wheat )

  # Italy
  d$wheat <- ifelse( d$country_name == "Italy" & d$Qualifier == "Winter", 0, d$wheat )

  # Spain
  d$wheat <- ifelse( d$country_name == "Spain" & d$crop == "wheat" & d$Data.ID == 761, 0, d$wheat )

  # Argentina
  d$soybean <- ifelse( d$country_name == "Argentina" & d$crop == "soybeans" & d$Qualifier == "", 0, d$soybean )

  # Somalia (two seasons, use the one with no qualifier code)
  d$cotton <- ifelse( d$country_name == "Somalia" & d$crop == "cotton" & d$Qualifier == 2, 0, d$cotton )

  # Kenya (two obs, nearly the same)
  d$cotton <- ifelse( d$country_name == "Kenya" & d$crop == "cotton" & d$Data.ID == 1711, 0, d$cotton )

  # SORGHUM CORRECTIONS
  # Dominican Republic (iso ID -- dom) listed thrice for sorghum
  # Seasonality of Dominican Republic sorghum production: http://www.pecad.fas.usda.gov/cropexplorer/pecad_stories.aspx?regionid=ca
  d$sorghum <- ifelse( d$country_name == "Dominican Republic" & d$crop == "sorghum" & d$Data.ID != 170, 0, d$sorghum )
  # Duplicate listing for Guatemala (iso ID == gtm)
  # Sorghum production by season: https://knoema.com/FAOPRDSC2012Aug/production-statistics-crops-and-crops-processed-2012?tsId=1194040
  d$sorghum <- ifelse( d$country_name == "Guatemala" & d$crop == "sorghum" & d$Data.ID != 253, 0, d$sorghum )
  # Duplicate listing for Kenya (iso ID -- ken)
  # Seasonal production of sorghum: http://www.fao.org/fileadmin/templates/mafap/documents/technical_notes/KENYA/KENYA_Technical_Note_SORGHUM_EN_Feb2013.pdf
  d$sorghum <- ifelse( d$country_name == "Kenya" & d$crop == "sorghum" & d$Data.ID != 337, 0, d$sorghum )
  # Duplicate listing for Nicaragua (iso ID -- nic)
  # Case study of sorghum production in Nicaragua: http://www.agriculturesnetwork.org/magazines/global/dealing-with-climate-change/farmers-sorghum-nicaragua
  d$sorghum <- ifelse( d$country_name == "Nicaragua" & d$crop == "sorghum" & d$Data.ID != 441, 0, d$sorghum )
  # Duplicate listing for Rwanda (iso ID -- rwa)
  # Southern hemisphere; Seasonal production of sorghum in Rwanda: http://global-growing.org/en/content/rwanda-new-sorghum-varieties-increase-farmers-production-rab-allafrica
  d$sorghum <- ifelse( d$country_name == "Rwanda" & d$crop == "sorghum" & d$Data.ID != 509, 0, d$sorghum )
  # Duplicate listing for Somalia (iso ID -- som)
  # Somalia sorghum production: http://www.fao.org/somalia/programmes-and-projects/agriculture/en/
  d$sorghum <- ifelse( d$country_name == "Somalia" & d$crop == "sorghum" & d$Data.ID != 1794, 0, d$sorghum )
  # Gadarif State, part of South Sudan (iso ID == sdn), is the largest producer of sorghum by region (Sudan (North) delimited)
  d$iso <- ifelse( ( d$country_name == "Sudan (South)" & d$crop == "sorghum" ), "sdn", d$iso )
  d$sorghum <- ifelse( d$country_name == "Sudan (South)" & d$crop == "sorghum", 1, d$sorghum )

  # Azerbaijan potato seasonality: http://www.potatopro.com/azerbaijan/potato-statistics
  d$root_tuber <- ifelse( d$country_name == "Azerbaijan" & d$crop == "potatoes" & d$Qualifier == "early", 0, d$root_tuber)

  # North Korea (central bowl) is the major agricultural area
  d$iso <- ifelse( ( d$country_name == "North Korea (central bowl)" & d$crop == "potatoes" ), "prk", d$iso )
  d$root_tuber <- ifelse( d$country_name == "North Korea (central bowl)" & d$crop == "potatoes" & d$Qualifier == "", 1, d$root_tuber )
  d$root_tuber <- ifelse( d$country_name == "North Korea" & ( d$crop == "potatoes" ), 0, d$root_tuber )
  d$iso <- ifelse( ( d$country_name == "North Korea (central bowl)" & d$crop == "wheat" ), "prk", d$iso )
  d$wheat <- ifelse( d$country_name == "North Korea (central bowl)" & d$crop == "wheat" & d$Qualifier == "", 1, d$wheat )
  d$wheat <- ifelse( d$country_name == "North Korea", 0, d$wheat )
  d$iso <- ifelse( ( d$country_name == "North Korea (central bowl)" & d$crop == "soybeans" ), "prk", d$iso )
  d$soybean <- ifelse( d$country_name == "North Korea (central bowl)" & d$crop == "soybeans", 1, d$soybean )

  # # PULSES CORRECTIONS
  # # Duplicate listing for Burundi (iso ID -- bdi)
  # # Seasonal production of pulses in Burundi: http://www.fao.org/docrep/004/w5956e/w5956e00.htm
  # d$iso <- ifelse( ( d$country_name == "Burundi" & d$crop == "pulses" & d$Data.ID == 83 ), "bdi", d$iso )
  # d$pulses <- ifelse( d$country_name == "Burundi" & d$crop == "pulses" & d$Data.ID == 83, 1, d$pulses )
  # # Duplicate listing for Ethiopia (iso ID -- eth)
  # # Ethiopia pulse production by month: http://www.fao.org/3/a-at305e.pdf
  # d$iso <- ifelse( ( d$country_name == "Ethiopia" & d$crop == "pulses" & d$Data.ID == 1695 ), "eth", d$iso )
  # d$pulses <- ifelse( d$country_name == "Ethiopia" & d$crop == "pulses" & d$Data.ID == 1695, 1, d$pulses )
  # # Duplicate listing for Haiti (iso ID -- hti)
  # # Haiti seasonality for pulse production: https://www.worldpulse.com/fr/node/9391
  # d$iso <- ifelse( ( d$country_name == "Haiti" & d$crop == "pulses" & d$Data.ID == 275 ), "hti", d$iso )
  # d$pulses <- ifelse( d$country_name == "Haiti" & d$crop == "pulses" & d$Data.ID == 275, 1, d$pulses )
  # # Duplicate listing for Kenya (iso ID -- ken)
  # # Case study of Kenya pulse production: https://www.investinkenya.co.ke/main/view_article/330
  # d$iso <- ifelse( ( d$country_name == "Kenya" & d$crop == "pulses" & d$Data.ID == 341 ), "ken", d$iso )
  # d$pulses <- ifelse( d$country_name == "Kenya" & d$crop == "pulses" & d$Data.ID == 341, 1, d$pulses )
  # # Duplicate listing for Nicaragua (iso ID -- nic)
  # # Pulse production by month in Nicaragua: http://www.fas.usda.gov/regions/nicaragua
  # d$iso <- ifelse( ( d$country_name == "Nicaragua" & d$crop == "pulses" & d$Data.ID == 446 ), "nic", d$iso )
  # d$pulses <- ifelse( d$country_name == "Nicaragua" & d$crop == "pulses" & d$Data.ID == 446, 1, d$pulses )
  # # Duplicate listing for Rwanda (iso ID -- rwa)
  # # Southern hemisphere; Rwanda pulse seasonality: http://allafrica.com/stories/201410090778.html
  # d$iso <- ifelse( ( d$country_name == "Rwanda" & d$crop == "pulses" & d$Data.ID == 504 ), "rwa", d$iso )
  # d$pulses <- ifelse( d$country_name == "Rwanda" & d$crop == "pulses" & d$Data.ID == 504, 1, d$pulses )
  # # Duplicate listing for El Salvador (iso ID -- slv)
  # # Pulse study in Central America: https://www.goift.com/market/americas/central-america/el-salvador-central-america/page/7/
  # d$iso <- ifelse( ( d$country_name == "El Salvador" & d$crop == "pulses" & d$Data.ID == 211 ), "slv", d$iso )
  # d$pulses <- ifelse( d$country_name == "El Salvador" & d$crop == "pulses" & d$Data.ID == 211, 1, d$pulses )
  # # Duplicate listing for Somalia (iso ID -- som)
  # # Seasonality of pulse production in Somalia: https://conservancy.umn.edu/bitstream/handle/11299/163161/JohnsonBrittney.pdf?sequence=1&isAllowed=y
  # d$iso <- ifelse( ( d$country_name == "Somalia" & d$crop == "pulses" & d$Data.ID == 1747 ), "som", d$iso )
  # d$pulses <- ifelse( d$country_name == "Somalia" & d$crop == "pulses" & d$Data.ID == 1747, 1, d$pulses )
  # # California has the largest pulse production of all states
  # d$iso <- ifelse( ( d$country_name == "California" & d$crop == "pulses" & d$Data.ID == 1007 ), "usa", d$iso )
  # d$pulses <- ifelse( d$country_name == "California" & d$crop == "pulses" & d$Data.ID == 1007, 1, d$pulses )
  # # Maharashtra, of all Indian states listed (Gujarat, Himachal Pradesh, Kerala, Orissa, Rajasthan, Tamil Nadu), has 34% share of pulse production
  # d$iso <- ifelse( ( d$country_name == "Maharashtra" & d$crop == "pulses" & d$Data.ID == 1424 ), "ind", d$iso )
  # d$pulses <- ifelse( d$country_name == "Maharashtra" & d$crop == "pulses" & d$Data.ID == 1424, 1, d$pulses )
  # # Uganda (South) should be associate with iso ID == uga and Data.ID == 611
  # d$iso <- ifelse( ( d$country_name == "Uganda (South)" & d$crop == "pulses" & d$Data.ID == 611 ), "uga", d$iso )
  # d$pulses <- ifelse( d$country_name == "Uganda (South)" & d$crop == "pulses" & d$Data.ID == 611, 1, d$pulses )

  # TODO Revisit irrigated crops later
  # Remove irrigated and other subcrops
  d$maize <- ifelse( d$maize == 1 & d$Qualifier != "", 0, d$maize ) # Remove irrigated and other subcrops
  d$rice <- ifelse( d$rice == 1 & d$Qualifier != "", 0, d$rice ) # Remove irrigated and other subcrops

  # # Combine potatoes and cassava (small number of observations for cassava gives little precision), but estimate R&T from potatoes and cassava separatelt
  # d$root_tuber <- ifelse( d$cassava == 1, 1, d$root_tuber )
  # # only Kenya has both cassava and potato production. Potato production ~ 2x higher than cassava, so use cassava
  # d$root_tuber <- ifelse( d$iso == "ken" & d$crop == "cassava", 0, d$root_tuber )

  d.crop.cal <- subset( d, select = c( "iso", "wheat", "rice", "maize", "cassava", "soybean", "sugarcane", "sugarbeet", "cotton", "sorghum", "root_tuber", "sunflower", "plant", "harvest" ) )
  d.crop.cal <- subset( d.crop.cal, !is.na( iso ) )
  d <- NULL

  save_dir <- file.path( output_dir, "data_processed" )
  if(!dir.exists(save_dir)){
    dir.create(save_dir, recursive = TRUE)
  }
  utils::write.csv( d.crop.cal, file = file.path(save_dir, "crop_calendar.csv" ))

  return(d.crop.cal)
}
