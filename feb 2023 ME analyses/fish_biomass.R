library(dplyr)
load("fish.surveys.rda")

fish.surveys %>% 
  filter(
    country %in% c("Indonesia", "Philippines"),
    year == 2021,
  ) %>% 
  select(country, ma_name, location_name, transect_no, biomass_kg_ha) %>% 
  group_by(country, ma_name, location_name, transect_no) %>% 
  summarize(biomass_kg_ha = sum(biomass_kg_ha, na.rm=TRUE)) %>%
  group_by(country, ma_name, location_name) %>%
  summarize(biomass_kg_ha = mean(biomass_kg_ha, na.rm=TRUE)) %>%
  group_by(country, ma_name) %>%
  summarize(biomass_kg_ha = mean(biomass_kg_ha, na.rm=TRUE)) %>%
  group_by(country) %>%
  summarize(
    mean_biomass_kg_ha = mean(biomass_kg_ha, na.rm=TRUE),
    sd_biomass_kg_ha = sd(biomass_kg_ha, na.rm=TRUE),
    N = n()
  ) %>%
  mutate(se_biomass_kg_ha = sd_biomass_kg_ha / sqrt(N)) %>% 
  as.data.frame() # to see more digits