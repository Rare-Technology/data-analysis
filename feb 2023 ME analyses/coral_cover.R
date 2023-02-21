load("benthic.surveys.rda")
library(dplyr)

benthic.surveys %>% 
  filter(
    country %in% c("Indonesia", "Philippines"),
    year == 2021,
    category %in% c("Hard coral", "Soft coral")
  ) %>% 
  select(country, ma_name, location_name, transect_no, percentage) %>% 
  group_by(country, ma_name, location_name, transect_no) %>% 
  summarize(coral_cover_percent = sum(percentage)) %>% 
  group_by(country, ma_name, location_name) %>% 
  summarize(coral_cover_percent = mean(coral_cover_percent)) %>% 
  group_by(country, ma_name) %>% 
  summarize(coral_cover_percent = mean(coral_cover_percent)) %>% 
  group_by(country) %>% 
  summarize(
    mean_coral_cover_percent = mean(coral_cover_percent),
    sd_coral_cover_percent = sd(coral_cover_percent),
    N = n()
  ) %>% 
  mutate(se_coral_cover_percent = sd_coral_cover_percent / sqrt(N)) %>% 
  as.data.frame()
  