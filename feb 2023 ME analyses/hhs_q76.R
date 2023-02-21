library(dplyr)
library(raretech)

hhs <- raretech::getData("hhs")

hhs %>% 
  filter(
    country %in% c("Indonesia", "Philippines"),
    year == 2022,
    !is.na(`76_complies_reserve`)
  ) %>% 
  select(country, maa, `76_complies_reserve`) %>% 
  group_by(country, maa) %>% 
  summarize(
    n_up = sum(`76_complies_reserve` == "Go up"),
    n_total = n()
  ) %>% 
  mutate(prop_up = 100*n_up/n_total) %>% 
  group_by(country) %>% 
  summarize(
    mean_prop_up = mean(prop_up),
    sd_prop_up = sd(prop_up),
    N = n()
  ) %>% 
  mutate(se_prop_up = sd_prop_up/sqrt(N)) %>% 
  as.data.frame()