
CREATE PROCEDURE [dbo].[process_switch_unique_subscribers]

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	DECLARE @last_update_on datetime = GETDATE()

	-- This switch only needs to happen for markets that don't yet use the new 2017 forecast model; once transitioned, the stored procedure can be removed entirely

	-- Remove existing metrics to force a full re-calculation
	DELETE FROM ds_zone_data WHERE zone_id NOT IN (SELECT zone_id FROM log_model_versions) AND metric_id IN (1,178,179,180,181,182,305) AND attribute_id NOT IN (1581,1582,1583)

	-- Copy over absolute unique subscriber figures
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, import_id, created_on, created_by, last_update_on, last_update_by)
	SELECT	zone_id, 1, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, import_id, created_on, created_by, @last_update_on, 3302
	FROM	ds_zone_data
	WHERE	zone_id NOT IN (SELECT zone_id FROM log_model_versions) AND metric_id = 322 AND attribute_id NOT IN (1581,1582,1583)
END
