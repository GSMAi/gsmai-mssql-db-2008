CREATE PROCEDURE [dbo].[process_log_reported_data] 

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- Imports for ds_organisation_data
	INSERT INTO wi_import.dbo.log_organisation_data_reporting (organisation_id, metric_id, attribute_id, date, date_type, created_on)

	SELECT	ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, MIN(ds.created_on)
	
	FROM	wi_import.dbo.ds_organisation_data ds LEFT JOIN
			wi_import.dbo.log_organisation_data_reporting lr ON (lr.organisation_id = ds.organisation_id AND lr.metric_id = ds.metric_id AND lr.attribute_id = ds.attribute_id AND lr.date = ds.date AND lr.date_type = ds.date_type)
	
	WHERE	ds.approved = 1 AND
			lr.id IS null
	
	GROUP BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type
	ORDER BY MIN(ds.created_on), ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date

	
	-- Imports for ds_zone_data
	INSERT INTO wi_import.dbo.log_zone_data_reporting (zone_id, metric_id, attribute_id, date, date_type, created_on)

	SELECT	ds.zone_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, MIN(ds.created_on)

	FROM	wi_import.dbo.ds_zone_data ds LEFT JOIN
			wi_import.dbo.log_zone_data_reporting lr ON (lr.zone_id = ds.zone_id AND lr.metric_id = ds.metric_id AND lr.attribute_id = ds.attribute_id AND lr.date = ds.date AND lr.date_type = ds.date_type)
	
	WHERE	ds.approved = 1 AND
			lr.id IS null
	
	GROUP BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type
	ORDER BY MIN(ds.created_on), ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
END
