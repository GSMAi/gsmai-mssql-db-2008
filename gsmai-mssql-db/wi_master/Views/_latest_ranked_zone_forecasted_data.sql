CREATE VIEW [dbo].[_latest_ranked_zone_forecasted_data] AS SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY zone_id, metric_id, attribute_id, date_type, date ORDER BY created_on DESC)
FROM	wi_import.dbo.ds_zone_forecast_data
WHERE	approved = 1;