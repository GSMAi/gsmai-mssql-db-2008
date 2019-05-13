CREATE VIEW [dbo].[_latest_ranked_reported_data] AS SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY organisation_id, metric_id, attribute_id, date, date_type ORDER BY last_update_on DESC)
FROM	wi_import.dbo.ds_organisation_data
WHERE	approved = 1