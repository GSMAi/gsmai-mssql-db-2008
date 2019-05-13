CREATE PROCEDURE [dbo].[process_legacy_map_mobile_internet_subscribers] 

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- Make adjustments to imported legacy mobile internet subscriber data at the import phase
	-- TODO: remove when updating the import format/data set

	-- Add "Total" mobile internet subscribers by summing 2G and 3G+4G!
	INSERT INTO wi_import.dbo.ds_zone_forecast_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, approved, approval_hash, import_hash, created_on, created_by, last_update_on, last_update_by)
	SELECT	zone_id, metric_id, 0, date, date_type, null, SUM(val_i), 0, MIN(source_id), MAX(confidence_id), 5, 1, approval_hash, import_hash, GETDATE(), 11770, GETDATE(), 11770
	FROM	wi_import.dbo.ds_zone_forecast_data
	WHERE	metric_id IN (307,330) AND attribute_id IN (796,1554) AND approved = 1
	GROUP BY approval_hash, import_hash, zone_id, metric_id, date, date_type

	-- Move mobile internet subscriber metrics into attributes of unique subscribers
	UPDATE wi_import.dbo.ds_zone_forecast_data SET metric_id = 1, attribute_id = CASE attribute_id WHEN 0 THEN 1581 WHEN 796 THEN 1582 WHEN 1554 THEN 1583 ELSE null END WHERE metric_id = 307 AND attribute_id IN (0,796,1554)
	UPDATE wi_import.dbo.ds_zone_forecast_data SET metric_id = 305, attribute_id = CASE attribute_id WHEN 0 THEN 1581 WHEN 796 THEN 1582 WHEN 1554 THEN 1583 ELSE null END WHERE metric_id = 306 AND attribute_id IN (0,796,1554)

	UPDATE wi_import.dbo.ds_zone_forecast_data SET metric_id = 322, attribute_id = CASE attribute_id WHEN 0 THEN 1581 WHEN 796 THEN 1582 WHEN 1554 THEN 1583 ELSE null END WHERE metric_id = 330 AND attribute_id IN (0,796,1554)
	UPDATE wi_import.dbo.ds_zone_forecast_data SET metric_id = 328, attribute_id = CASE attribute_id WHEN 0 THEN 1581 WHEN 796 THEN 1582 WHEN 1554 THEN 1583 ELSE null END WHERE metric_id = 329 AND attribute_id IN (0,796,1554)

	-- TODO: add benchmark by passing a start time to an audit function
	SELECT 'Finished: process_legacy_map_mobile_internet_subscribers (3s)'
END
