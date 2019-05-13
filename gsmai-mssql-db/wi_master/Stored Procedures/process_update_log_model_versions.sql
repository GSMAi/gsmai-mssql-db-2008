
CREATE PROCEDURE [dbo].[process_update_log_model_versions]

AS

-- Track markets that have been "upgraded" to the 2017 forecast model (used to ignore certain legacy processes from v4 onwards)
INSERT INTO log_model_versions (zone_id, version, created_on)
SELECT DISTINCT zone_id, 4, GETDATE() FROM ds_zone_data WHERE zone_id NOT IN (SELECT zone_id FROM log_model_versions) AND metric_id = 3 AND attribute_id = 0 AND date >= '2021-01-01'

