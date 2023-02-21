library(dplyr)
library(raretech)

hhs <- raretech::getData("hhs")

hhs %>% 
  filter(
    country %in% c("Indonesia", "Philippines"),
    year == 2022,
    `77_fishing_in_reserve` != "Not Answered"
  ) %>% 
  select(country, maa, `77_fishing_in_reserve`) %>% 
  group_by(country, maa) %>% 
  summarize(
    n_never = sum(`77_fishing_in_reserve` %in% c("Never", "0")),
    n_total = n()
  ) %>% 
  mutate(prop_never = 100*n_never/n_total) %>% 
  group_by(country) %>% 
  summarize(
    mean_never = mean(prop_never),
    sd_prop_never = sd(prop_never),
    N = n()
  ) %>% 
  mutate(se_prop_never = sd_prop_never/sqrt(N)) %>% 
  as.data.frame()