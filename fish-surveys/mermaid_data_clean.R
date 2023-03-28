library(mermaidr)
library(data.world)
library(dplyr)

mermaid_projects <- mermaidr::mermaid_get_my_projects()$id
mermaid_data <- mermaidr::mermaid_get_project_data(mermaid_projects, method="fishbelt", data="observations")
mermaid_countries <- sort(unique(mermaid_data$country))

dwapi::upload_data_frame(mermaid_data, "rare", "fish-surveys", "fish-surveys-MERMAID.csv")

# For automating (so, don't have to interact with MERMAID SPA), we can download data from url's using
# the project id. Need to set the visibility of project data to public though.
# https://api.datamermaid.org/v1/projects/{project-id}/beltfishes/obstransectbeltfishes/csv"

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

footprint <- data.world::query(
  data.world::qry_sql("SELECT * FROM footprint_global"),
  "https://data.world/rare/footprint/"
)

#### Philippines 2022 survey ####
# Need to handle this separately because the geographic info has to be parsed by hand
phl22 <- mermaid_data %>% 
  dplyr::filter(
    country == "Philippines",
    lubridate::year(sample_date) == 2022
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
    transect_length,
    transect_width,
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
    transect_width = as.double(stringr::str_extract(transect_width, "\\d*")),
    transect_area = transect_length * transect_width,
    density_ind_ha = (count/transect_area)*10000,
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
  dplyr::select(-c(management, transect_length, transect_width, transect_area))

#### Honduras 2022 surveys ####
hnd22 <- mermaid_data %>% 
  dplyr::filter(
    country == "Honduras",
    lubridate::year(sample_date) == 2022
  )

hndmaa <- tibble::tibble(
  project = c("SantaFe_2022", "Guanaja_2022"),
  ma_name = c("Santa Fe", "Guanaja")
)

hnd22 <- hnd22 %>% 
  dplyr::select(
    country,
    project,
    lat = latitude,
    lon = longitude,
    location_name = site,
    location_status = management,
    transect_length,
    transect_width,
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
    transect_width = as.double(stringr::str_extract(transect_width, "\\d*")),
    transect_area = transect_length * transect_width,
    density_ind_ha = (count/transect_area)*10000,
    size_class = get_size_class(length),
    transect_no = as.character(transect_no)
  ) %>% 
  dplyr::left_join(
    hndmaa,
    by="project"
  ) %>% 
  dplyr::left_join(
    footprint %>% 
      dplyr::filter(country=="Honduras") %>% 
      dplyr::distinct(
        ma_name,
        level1_name,
        level2_name
      ),
    by = "ma_name"
  ) %>%
  dplyr::select(-c(project, transect_length, transect_width, transect_area))

df <- dplyr::bind_rows(phl22, hnd22) %>% dplyr::distinct()

df <- df %>% 
  dplyr::mutate(
    location_status = dplyr::recode(
      location_status,
      "open access" = "Managed Access",
      "access restriction" = "Managed Access",
      "Managed Access Area" = "Managed Access",
      "no take" = "Reserve"
    )
  )