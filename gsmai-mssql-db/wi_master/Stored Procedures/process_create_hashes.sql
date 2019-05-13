CREATE PROCEDURE [dbo].[process_create_hashes] 

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- Add new data point and metadata hashes
	UPDATE	wi_import.dbo.ds_organisation_data
	SET 	index_hash 	= HASHBYTES('MD5', CAST(organisation_id AS nvarchar(max)) + '-' + CAST(metric_id AS nvarchar(max)) + '-' + CAST(attribute_id AS nvarchar(max)) + '-' + CONVERT(nvarchar, date, 120) + '-' + CAST(date_type AS nvarchar(max))),
			hash 		= HASHBYTES('MD5', CAST(organisation_id AS nvarchar(max)) + '-' + CAST(metric_id AS nvarchar(max)) + '-' + CAST(attribute_id AS nvarchar(max)) + '-' + CONVERT(nvarchar, date, 120) + '-' + CAST(date_type AS nvarchar(max)) + CASE WHEN val_d IS null THEN ' ' ELSE CAST(val_d AS nvarchar(max)) END + CASE WHEN val_i IS null THEN ' ' ELSE CAST(val_i AS nvarchar(max)) END + CAST(currency_id AS nvarchar(max)) + CAST(source_id AS nvarchar(max)) + CAST(confidence_id AS nvarchar(max)) + CASE WHEN location IS null THEN ' ' ELSE CAST(location AS nvarchar(max)) END + CASE WHEN definition IS null THEN ' ' ELSE CAST(definition AS nvarchar(max)) END + CASE WHEN notes IS null THEN ' ' ELSE CAST(notes AS nvarchar(max)) END)
	WHERE 	hash IS null OR index_hash IS null

	UPDATE	wi_import.dbo.ds_zone_data
	SET 	index_hash 	= HASHBYTES('MD5', CAST(zone_id AS nvarchar(max)) + '-' + CAST(metric_id AS nvarchar(max)) + '-' + CAST(attribute_id AS nvarchar(max)) + '-' + CONVERT(nvarchar, date, 120) + '-' + CAST(date_type AS nvarchar(max))),
			hash 		= HASHBYTES('MD5', CAST(zone_id AS nvarchar(max)) + '-' + CAST(metric_id AS nvarchar(max)) + '-' + CAST(attribute_id AS nvarchar(max)) + '-' + CONVERT(nvarchar, date, 120) + '-' + CAST(date_type AS nvarchar(max)) + CASE WHEN val_d IS null THEN ' ' ELSE CAST(val_d AS nvarchar(max)) END + CASE WHEN val_i IS null THEN ' ' ELSE CAST(val_i AS nvarchar(max)) END + CAST(currency_id AS nvarchar(max)) + CAST(source_id AS nvarchar(max)) + CAST(confidence_id AS nvarchar(max)) + CASE WHEN location IS null THEN ' ' ELSE CAST(location AS nvarchar(max)) END + CASE WHEN definition IS null THEN ' ' ELSE CAST(definition AS nvarchar(max)) END + CASE WHEN notes IS null THEN ' ' ELSE CAST(notes AS nvarchar(max)) END)
	WHERE 	hash IS null OR index_hash IS null
END
