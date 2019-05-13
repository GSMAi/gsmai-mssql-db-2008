CREATE VIEW [dbo].[_latest_ranked_forecast_data] AS SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY organisation_id, metric_id, attribute_id, date_type, date ORDER BY created_on DESC)
FROM	wi_import.dbo.ds_organisation_forecast_data
WHERE	approved = 1