For now, we just need to calculate all metrics for Nacala Porto (if data exists) and for Memba, but excluding Serissa and Simuco MA+Rs. We will eventually need to calculate for other sites too, so keep these codes handy- but we don't have the data for those other sites quite yet. So that said, the metrics we need this week are:

1.  Ecological Data
    a.  \% coral cover: This is the average % coral cover from surveys, exactly as calculated in the Ecological Dashboard. Coral cover includes both hard and soft corals. Let's do MA and R as separate numbers, since that better matches what the Ecological Dashboard produces. Nesting is by transect, survey site, MA/R, and then site.
    b.  \% seagrass cover: Exactly the same as above, but seagrass cover instead of coral.
    c.  Mangrove tree density (tree/ha) and diameter (cm): These are calculated exactly as done in the Ecological Dashboard as well, and we can keep MA and R as separate numbers. Nesting as described above. Keep in mind that the dashboard is in tree/m2, so needs to be converted to tree/ha.
2.  HHS Data
    a.  Avg household income/month from fishing (\$USD): Q84 in the new HHS, as calculated on the Socioeconomic Dashboard. Nested by community, MA, then site.
    b.  Avg household income/month from alternative livelihoods (\$USD): This is the difference between new HHS question 83 and 84, both of which can be calculated exactly as in the Socioeconomic Dashboard. Same nesting.
    c.  \% with sufficient income to meet household needs: This is slightly more complicated because I think this question changed in the new HHS. It's now Q90, and will be calculated as the % of all respondents who answered "Fairly Easy", "Easy", or "Very Easy." However, if Memba was using the previous HHS then it would be the question worded "To cover family needs your household income is..." and you would calculate the % of respondents who answered "Sufficient." Same nesting process.

## Notes

-   We do not have any data from Nacala Porto yet.
-   Memba is an LGU, a part of Nampula (SNU). In the ecological surveys, the only maa from Memba is also named Memba. But in the household surveys Baixo Pinda is also an maa under Memba.

## Parameters

-   country = Mozambique
-   maa = Memba, Baixo Pinda
-   year = ??? hhs is 2019 and 2021 only, eco surveys are 2020 only.
