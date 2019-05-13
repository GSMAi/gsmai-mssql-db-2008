
CREATE PROCEDURE [dbo].[process_recalculate_smartphones] 

AS

EXEC calculate_absolute_from_percentage 53, 1432, 3, 0, '2000-01-01', '2021-01-01', @debug = 0			-- Smartphones
EXEC calculate_absolute_from_percentage 53, 1556, 3, 0, '2000-01-01', '2021-01-01', @debug = 0			-- Basic/feature phones
EXEC calculate_absolute_from_percentage 53, 1555, 3, 0, '2000-01-01', '2021-01-01', @debug = 0			-- Non-handsets

EXEC calculate_absolute_from_zone_percentage 53, 1432, 3, 0, '2000-01-01', '2021-01-01', @debug = 0		-- Country-level, smartphones
EXEC calculate_absolute_from_zone_percentage 53, 1556, 3, 0, '2000-01-01', '2021-01-01', @debug = 0		-- Country-level, basic/feature phones
EXEC calculate_absolute_from_zone_percentage 53, 1555, 3, 0, '2000-01-01', '2021-01-01', @debug = 0		-- Country-level, non-handsets

EXEC aggregate_connections '2000-01-01', '2021-01-01', @debug = 0										-- Connections aggregation
EXEC aggregate_subscribers '2000-01-01', '2021-01-01', @debug = 0										-- Subscriber aggregation

EXEC calculate_connections_subscribers '2000-01-01', '2021-01-01', @debug = 0							-- Connections, subscriber calculations

-- Copy smartphone % of connections into smartphone adoption
DELETE FROM ds_organisation_data WHERE metric_id = 308 AND attribute_id = 1432
DELETE FROM ds_zone_data WHERE metric_id = 308 AND attribute_id = 1432

INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, import_id, created_on, created_by, last_update_on, last_update_by)
SELECT	organisation_id, 308, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, import_id, created_on, created_by, last_update_on, last_update_by
FROM	ds_organisation_data
WHERE	metric_id = 53 AND attribute_id = 1432

INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, import_id, created_on, created_by, last_update_on, last_update_by)
SELECT	zone_id, 308, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, import_id, created_on, created_by, last_update_on, last_update_by
FROM	ds_zone_data
WHERE	metric_id = 53 AND attribute_id = 1432


SELECT 'Finished: process_recalculate_smartphones (2m 3s)'
