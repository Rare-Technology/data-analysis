library(dplyr)
library(raretech)

hhs <- raretech::getData("hhs")

hhs %>% 
  filter(
    country %in% c("Indonesia", "Philippines"),
    year == 2022,
    `74a_current_regulations` != "Not Answered"
  ) %>% 
  dplyr::select(
    country,
    maa,
    `74a_current_regulations`
  ) %>% 
  group_by(country, maa) %>% 
  summarize(
    n_agree = sum(`74a_current_regulations` %in% c("Agree", "Strongly agree")),
    n_total = n()
  ) %>% 
  mutate(prop_agree = 100*n_agree/n_total) %>% 
  group_by(country) %>% 
  summarize(
    mean_prop_agree = mean(prop_agree),
    sd_prop_agree = sd(prop_agree),
    N = n()
  ) %>% 
  mutate(se_prop_agree = sd_prop_agree/sqrt(N)) %>% 
  as.data.frame()