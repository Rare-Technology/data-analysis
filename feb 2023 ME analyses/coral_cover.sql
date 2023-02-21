# Get average coral cover at each country
SELECT country, AVG(coral_cover_percent) AS coral_cover_percent
FROM (
    # Get average coral cover at each maa
    SELECT country, ma_name, AVG(coral_cover_percent) AS coral_cover_percent
    FROM (
        # Get average coral cover at each survey location
        SELECT country, ma_name, location_name, AVG(coral_cover_percent) AS coral_cover_percent
        FROM (
            # Get total coral cover at each transect
            SELECT country, ma_name, location_name, transect_no, SUM(percentage) AS coral_cover_percent
            FROM benthicmaster
            WHERE country IN ("Indonesia", "Philippines") AND year=2021 AND category IN ("Hard coral", "Soft coral")
            GROUP BY country, ma_name, location_name, transect_no
        ) AS tbl1
        GROUP BY country, ma_name, location_name
    ) AS tbl2
    GROUP BY country, ma_name
) as tbl3
GROUP BY country
ORDER BY country