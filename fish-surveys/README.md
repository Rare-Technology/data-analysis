---
{"editor":"markdown"}
---
# About
Fish survey data that is visualized on the [Ecological dashboard](https://portal.rare.org/en/tools-and-data/ecological-data/). Includes raw data from each country and the final combined dataset that actually goes into the dashboard.

Any analysis on survey data should be performed on **fish-surveys-all.csv**. If you want to analyze data from, say Honduras, do NOT use fish-surveys-HND.csv. The raw files are here for data *cleaning*, not data *analysis*. Instead, filter **fish-surveys-all** to Honduras records.

## Indexing/grouping variables
Use any of these columns for grouping/nesting.
- country
- year
- level1_name (Subnational unit/SNU)
- level2_name (Local government unit/LGU)
- ma_name
- location_name
- location_status (managed access or reserve)
- transect_no
- family
- species

## Outcome variables
Explore any of these variables
- biomass_kg_ha
- density_ind_ha
- count
- length
- family
- species

## Misc.
The history of some of these files is a bit mysterious, although at the end of the day they all probably came from stray excel files.

Questions? Contact Angel: aumana ~at~ rare.org
