source("mermaid_data_clean.r")

legacy_data <- data.world::query(
  data.world::qry_sql("SELECT * FROM fish_surveys_legacy"),
  "https://data.world/rare/fish-surveys"
)

df <- dplyr::bind_rows(legacy_data, df)

dwapi::upload_data_frame(df, "rare", "fish-surveys", "fish-surveys-all.csv")