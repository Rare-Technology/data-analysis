### Cleaning fish survey data
# The data cleaning process for fish surveys will go like this:
# (1) Clean Mozambique, Honduras, and 2018 Indonesia survey data.
#   These appeared together in a previous master dataset so they have the same structure.
# (2) Clean 2017, 2019, 2021 Indonesia data. These came from an excel file from the Indonesia
# team in late 2021. This file didn't have anything related to 2018 though.
# (3) Clean 2011-2021 (except 2019) Philippines data. This came from an excel file from Philippines
# team in 2022.
library(data.world)
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(rfishbase)


#### Legacy MOZ, HND, IDN data ####
# Pull moz, hnd, and idn 2018 data. Note that using the UNION operators without "ALL" removes any
# duplicate rows, which were in the moz and hnd data.
df <- data.world::query(
  data.world::qry_sql(
    "SELECT * FROM fish_surveys_moz
    UNION
    SELECT * FROM fish_surveys_hnd
    UNION
    SELECT * FROM fish_surveys_idn_2018"
  ),
  "https://data.world/rare/fish-surveys"
)

footprint <- data.world::query(
  data.world::qry_sql("SELECT * FROM footprint_global"),
  "https://data.world/rare/footprint/"
)

# Removing columns that have a lot of missing information/have no use in the dashboard.
# Also, removing `submittedon` will help to remove data that is actually duplicate but has slightly different
# submission times. This is probably user error, accidentally submitting the data twice.
df <- df %>% 
  dplyr::select(-c(submittedon, submittedby, control_site, control_site_name, diver_name, temp, transect_area, lmax))

df <- df %>% 
  dplyr::left_join(
    footprint %>%
      dplyr::filter(country %in% c("Honduras", "Mozambique", "Indonesia")) %>% 
      dplyr::mutate(
        level1_name = dplyr::case_when(
          ma_name == "Iriona and Limon" ~ "Colón",
          ma_name == "Roatan" ~ "Islas de la Bahía",
          ma_name == "Puerto Cortes" ~ "Cortés",
          TRUE ~ level1_name
        ),
        level2_name = dplyr::case_when(
          ma_name == "Iriona and Limon" ~ "Iriona and Limon", # TODO ask Cristhian about this
          ma_name == "Roatan" ~ "Roatán",
          ma_name == "Puerto Cortes" ~ "Puerto Cortés",
          TRUE ~ level2_name
        ) 
      ) %>% 
      dplyr::distinct(
        ma_name, level1_name, level2_name
      ),
    by = "ma_name"
  ) %>% 
  # IDN maa's were not in footprint data, so manually adding geo info
  dplyr::mutate(
    level1_name = dplyr::case_when(
      ma_name == "Mayalibit Bay" ~ "West Papua",
      ma_name == "Batanta and Salawati Island" ~ "West Papua",
      TRUE ~ level1_name
    ),
    level2_name = dplyr::case_when(
      ma_name == "Mayalibit Bay" ~ "Raja Ampat",
      ma_name == "Batanta and Salawati Island" ~ "Raja Ampat",
      TRUE ~ level2_name
    )
  )
  
# to get the year, for almost all records, the following does work:
df$year <- lubridate::year(df$survey_date)

# But MOZ 2020 survey was at the end of the year and about 50 records (out of 504) have a survey date that
# went into January. We will label the year on these as being 2020 as they belong to the
# 2020 survey
df$year[df$country == "MOZ" & df$year == 2021] <- 2020

#### IDN Mermaid dump ####
# Raymond provided an updated dataset that has the 2021 survey as well has historical records for 2019 and 2017
# This dataset includes the community site name for the survey sites; NTZ and UTZ correspond to Teluk Kolono
# Teluk Kolono in turn belongs to the LGU Konawe Selatan, which then belongs to SNU South East Sulawesi
# For this stage of data cleaning, we will:
# 1. Select appropriate columns from the updated dataset
# 2. Add level1_name/level2_name columns
# 3. Drop the 2019 IDN records in df
# 4. Merge the new 2017/19/21 records with df

get_size_class <- function (x) { # need to fix this for existing fish data, its a mess
  if (is.na(x)) {as.character(NA)}
  else if (x <= 5) {"0-5"}
  else if (x <= 10) {"5-10"}
  else if (x <= 20) {"10-20"}
  else if (x <= 30) {"20-30"}
  else if (x <= 40) {"30-40"}
  else if (x <= 50) {"40-50"}
  else {"50+"}
}
get_size_class <- Vectorize(get_size_class)

idn <- data.world::query(
  data.world::qry_sql(
    "SELECT * FROM fish_surveys_IDN_2017_19_21"
  ),
  "https://data.world/rare/fish-surveys"
)

idn <- idn %>%
  # 1
  dplyr::select(
    country,
    year,
    month,
    day,
    lat = latitude,
    lon = longitude,
    ma_name = mar_name,
    location_name = site,
    location_status = management_name,
    transect_no = transect_number,
    count,
    family = fish_family,
    species = fish_taxon,
    density_ind_ha = density_countha,
    biomass_kg_ha = biomass_kgha,
    length = size,
    a,
    b,
    reef_slope,
    reef_zone,
    water_depth = depth
  ) %>% 
  # 2
  dplyr::mutate(
    country = "IDN",
    survey_date = lubridate::ymd(paste(year, month, day, sep = "-")),
    size_class = get_size_class(length)
  ) %>% 
  dplyr::left_join(
    footprint %>% 
      dplyr::filter(country=="Indonesia") %>% 
      dplyr::distinct(ma_name, level1_name, level2_name),
    by = "ma_name"
  ) %>% 
  dplyr::select(
    -c(month, day)
  )

# drop 2019 Indonesia records
df <- df %>%
  dplyr::filter(country != "IDN" | year == 2018)

# 4
df <- dplyr::bind_rows(df, idn)

##### PHL fish surveys, 2011-2021 #####
phl <- data.world::query(
  data.world::qry_sql("SELECT * FROM fish_surveys_phl"),
  "https://data.world/rare/fish-surveys"
)

# 186,764 records
phl <- phl %>% dplyr::select(
  country = country,
  year = year,
  lat = latitude, # along with lon, 13,881 are NA
  lon = longitude,
  ma_name = management_secondary_name,
  location_name = site,
  location_status = management_name,
  transect_no = transect_number,
  count = count,
  family = fish_family,
  species = fish_taxon,
  biomass_kg_ha = biomass_kgha,
  length = size,
  a,
  b,
  reef_slope,
  reef_zone
)

# The family taxonomy is missing for all records in 2019-21.
# We'll use the species column and fishbase to get this info
phl1921 <- phl %>% 
  dplyr::filter(year %in% c(2019, 2020, 2021)) %>% 
  dplyr::select(-family)
taxa <- rfishbase::load_taxa() %>% 
  dplyr::select(species = Species, family = Family)
phl1921 <- dplyr::left_join(phl1921, taxa, by = "species")

phl <- phl %>% 
  dplyr::filter(year < 2019) %>% 
  dplyr::bind_rows(phl1921)
rm(phl1921, taxa)

# Columns missing:
# - density_ind_ha (to be calculated)
# - survey_date (insufficient data to process; that are Year, Month, Day columns but
#   only about 15k records out of 127k have Month and Day recorded
# - size_class (to be calculated but not important)
# - level1_name (could try to process using existing geographic level info, but not sure if
#   the info we have is historically accurate)

phl <- phl %>%
  dplyr::mutate(
    # Transects are 500m^2
    density_ind_ha = (count / 500) * 10000,
    survey_date = NA,
    size_class = get_size_class(length)
  )

### level1/level2_name
# The dataset is missing snu/lgu names. The ma_name is in the form
# snu_ma. For example, Negros_Oriental_Ayungon is the ma Ayungon from snu
# Negros Oriental.
# So, we can rewrite some of these ma_name's like
# Negros Oriental_Ayungon
# Then use tidyr::separate on "_" to create the level1_name col and a new ma_name col
# We will have to manually edit a few (like Sta. Monica -> Santa Monica)

phl <- phl %>% 
  dplyr::rename(snu_maa = ma_name) %>% 
  dplyr::mutate(
    snu_maa = dplyr::recode(
      snu_maa,
      "Camarines_Norte_Mercedes" = "Camarines Norte_Mercedes",
      "Camarines_Sur_Sagnay" = "Camarines Sur_Sagnay",
      "Camarines_Sur_Tinambac" = "Camarines Sur_Tinambac",
      "Cebu_San_Francisco" = "Cebu_San Francisco",
      "Negros Occidental_San_Carlos" = "Negros Occidental_San Carlos",
      "Negros Occidental_Tayasan" = "Negros Oriental_Tayasan", # original data had typo
      "Negros_Oriental_Ayungon" = "Negros Oriental_Ayungon",
      "Negros_Oriental_Bindoy" = "Negros Oriental_Bindoy",
      "Negros_Oriental_Manjuyod" = "Negros Oriental_Manjuyod",
      "Occidental_Mindoro_Looc" = "Occidental Mindoro_Looc",
      "Occidental_Mindoro_Lubang" = "Occidental Mindoro_Lubang",
      "Surigao_del_Norte_Burgos" = "Surigao Del Norte_Burgos",
      "Surigao_del_Norte_Del_Carmen" = "Surigao Del Norte_Del Carmen",
      "Surigao_del_Norte_Dapa" = "Surigao Del Norte_Dapa",
      "Surigao_del_Norte_General_Luna" = "Surigao Del Norte_General Luna",
      "Surigao_del_Norte_Pilar" = "Surigao Del Norte_Pilar",
      "Surigao_del_Norte_San_Benito" = "Surigao Del Norte_San Benito",
      "Surigao_del_Norte_San_Isidro" = "Surigao Del Norte_San Isidro",
      "Surigao_del_Norte_Socorro" = "Surigao Del Norte_Socorro",
      "Surigao_del_Norte_Sta. Monica" = "Surigao Del Norte_Santa Monica",
      "Surigao_Del_Sur_Cantilan" = "Surigao Del Sur_Cantilan",
      "Surigao_Del_Sur_Cortes" = "Surigao Del Sur_Cortes",
      "Zamboanga _Ibugay_Ipil" = "Zamboanga Sibugay_Ipil"
    )
  ) %>% 
  tidyr::separate(snu_maa, c("level1_name", "ma_name"), "_") %>% 
  dplyr::left_join(
    footprint %>% 
      dplyr::filter(country == "Philippines") %>% 
      dplyr::distinct(ma_name, level1_name, level2_name),
    by=c("level1_name", "ma_name")) %>%
  # A couple lgu names did not match with anything on the footprint table
  # Since nearly all the other lgu names match the ma name, we'll just fill in
  # the missing lgu names to match their ma name.
  dplyr::mutate(
    level2_name = dplyr::recode(
      level2_name,
      .missing = ma_name
    )
  )

# Transect numbers in the Philippines data are, unfortunately, not just 1,2,3 etc.
# They look like "NAYU2R0712". So, we will have to convert transect numbers from the rest of the 
# fish survey data into characters.
df <- df %>% 
  dplyr::filter(country != "PHL") %>% 
  dplyr::mutate(transect_no = as.character(transect_no)) %>% 
  dplyr::bind_rows(phl)

#### Philippines 2022 survey ####
phl22 <- data.world::query(
  data.world::qry_sql("SELECT * FROM fish_surveys_phl_2022"),
  "https://data.world/rare/fish-surveys"
)

# Hand-edited table converting `management` to `ma_name`
phlmaa <- readr::read_csv("phl22-maa.csv")

phl22 <- phl22 %>% 
  dplyr::select(
    country,
    lat = latitude,
    lon = longitude,
    location_name = site,
    location_status = management_rules,
    management,
    transect_no = transect_number,
    family = fish_family,
    species = fish_taxon,
    count,
    biomass_kg_ha = biomass_kgha,
    length = size,
    a = biomass_constant_a,
    b = biomass_constant_b,
    reef_slope,
    reef_zone,
    survey_date = sample_date,
  ) %>% 
  dplyr::mutate(
    year = lubridate::year(survey_date),
    density_ind_ha = (count/500)*10000, # transects are 50m x 10m
    size_class = get_size_class(length),
    transect_no = as.character(transect_no)
  ) %>% 
  # Get ma_name
  dplyr::left_join(
    phlmaa,
    by="management"
  ) %>% 
  # Get level1/2 names
  dplyr::left_join(
    footprint %>% 
      dplyr::filter(country=="Philippines") %>% 
      dplyr::distinct(
        ma_name,
        level1_name,
        level2_name
      ),
    by = "ma_name"
  ) %>%
  dplyr::select(-management)

df <- dplyr::bind_rows(df, phl22)


#### Wrapping up ####

# Change iso3 codes to country names
df <- df %>% 
  dplyr::mutate(
    country = dplyr::recode(
      country,
      "HND" = "Honduras",
      "IDN" = "Indonesia",
      "MOZ" = "Mozambique"
    )
  )

# Fix location_status
df <- df %>% 
  dplyr::mutate(
    location_status = dplyr::recode(
      location_status,
      "ma" = "Managed Access",
      "MA" = "Managed Access",
      "outside" = "Managed Access",
      "Outside" = "Managed Access",
      "TURF" = "Managed Access",
      "open access" = "Managed Access",
      "access restriction" = "Managed Access",
      "reserve" = "Reserve",
      "Inside" = "Reserve",
      "no take" = "Reserve"
    )
  )

df$year <- as.integer(df$year)

# Drop duplicates
df <- dplyr::distinct(df)

# Export locally and upload to data.world
readr::write_csv(df, "fish-surveys-all.csv")
dwapi::upload_file("rare", "fish-surveys", "fish-surveys-all.csv", "fish-surveys-all.csv")
