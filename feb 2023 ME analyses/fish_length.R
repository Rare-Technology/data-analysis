load("fish.surveys.rda")
library(dplyr)

fish.surveys %>% 
  filter(
    country %in% c("Indonesia", "Philippines"),
    year == 2021,
    length > 0,
    count > 0
  ) %>% 
  select(country, ma_name, location_name, transect_no, count, length) %>%
  mutate(weighted_length = count*length) %>% 
  group_by(country, ma_name, location_name, transect_no) %>% 
  summarize(length = sum(weighted_length) / sum(count)) %>%
  group_by(country, ma_name, location_name) %>% 
  summarize(length = mean(length)) %>% 
  group_by(country, ma_name) %>% 
  summarize(length = mean(length)) %>% 
  group_by(country) %>% 
  summarize(
    mean_length = mean(length),
    sd_length = sd(length),
    N = n()
  ) %>% 
  mutate(se_length = sd_length / sqrt(N)) %>% 
  as.data.frame()
  