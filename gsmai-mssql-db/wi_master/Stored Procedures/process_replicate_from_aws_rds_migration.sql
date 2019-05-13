
CREATE PROCEDURE [dbo].[process_replicate_from_aws_rds_migration]

AS


-- wi_import.dbo.ds_organisation_data
SET IDENTITY_INSERT wi_import.dbo.ds_organisation_data ON

INSERT INTO wi_import.dbo.ds_organisation_data (id, organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, location, definition, notes, approved, approval_hash, import_hash, stasis, processed, created_on, created_by, last_update_on, last_update_by)
SELECT	id, organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, location, definition, notes, approved, approval_hash, import_hash, stasis, processed, created_on, created_by, last_update_on, last_update_by
FROM	[aws_rds_migration].[wi_import].[dbo].[ds_organisation_data]
WHERE	id NOT IN (SELECT id FROM wi_import.dbo.ds_organisation_data)

SET IDENTITY_INSERT wi_import.dbo.ds_organisation_data OFF

/*DELETE	ds
FROM	wi_import.dbo.ds_organisation_data ds LEFT JOIN
		[aws_rds_migration].[wi_import].[dbo].[ds_organisation_data] ds2 ON ds.id = ds2.id
WHERE	ds2.id IS null*/


-- wi_import.dbo.ds_organisation_forecast_data
SET IDENTITY_INSERT wi_import.dbo.ds_organisation_forecast_data ON

INSERT INTO wi_import.dbo.ds_organisation_forecast_data (id, organisation_id, metric_id, attribute_id, dimension_id, dimension_val_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, approved, approval_hash, import_hash, hash, created_on, created_by, last_update_on, last_update_by)
SELECT	id, organisation_id, metric_id, attribute_id, dimension_id, dimension_val_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, approved, approval_hash, import_hash, hash, created_on, created_by, last_update_on, last_update_by
FROM	[aws_rds_migration].[wi_import].[dbo].[ds_organisation_forecast_data]
WHERE	id NOT IN (SELECT id FROM wi_import.dbo.ds_organisation_forecast_data)

SET IDENTITY_INSERT wi_import.dbo.ds_organisation_forecast_data OFF


-- wi_import.dbo.ds_zone_data
SET IDENTITY_INSERT wi_import.dbo.ds_zone_data ON

INSERT INTO wi_import.dbo.ds_zone_data (id, zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, location, definition, notes, approved, approval_hash, import_hash, processed, created_on, created_by, last_update_on, last_update_by)
SELECT	id, zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, location, definition, notes, approved, approval_hash, import_hash, processed, created_on, created_by, last_update_on, last_update_by
FROM	[aws_rds_migration].[wi_import].[dbo].[ds_zone_data]
WHERE	id NOT IN (SELECT id FROM wi_import.dbo.ds_zone_data)

SET IDENTITY_INSERT wi_import.dbo.ds_zone_data OFF


-- wi_import.dbo.ds_zone_forecast_data
SET IDENTITY_INSERT wi_import.dbo.ds_zone_forecast_data ON

INSERT INTO wi_import.dbo.ds_zone_forecast_data (id, zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, approved, approval_hash, import_hash, hash, created_on, created_by, last_update_on, last_update_by)
SELECT	id, zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, privacy_id, approved, approval_hash, import_hash, hash, created_on, created_by, last_update_on, last_update_by
FROM	[aws_rds_migration].[wi_import].[dbo].[ds_zone_forecast_data]
WHERE	id NOT IN (SELECT id FROM wi_import.dbo.ds_zone_forecast_data)

SET IDENTITY_INSERT wi_import.dbo.ds_zone_forecast_data OFF




-- Cross-update mismatched user ids between the old and new user tables
CREATE TABLE #users (id int, old_id int)

INSERT INTO #users
SELECT	u.id, u2.user_id
FROM	wi_master.dbo.users u INNER JOIN [aws_rds_migration].[wi_master].[dbo].[user_migration_link] u2 ON u.email = u2.email
WHERE	u.id IN (SELECT DISTINCT user_id FROM wi_master.dbo.user_organisation_link WHERE organisation_id = 1225) AND u.id <> u2.user_id

-- Import data sets
UPDATE ds SET ds.created_by = u.id FROM wi_import.dbo.ds_organisation_data ds INNER JOIN #users u ON ds.created_by = u.old_id
UPDATE ds SET ds.last_update_by = u.id FROM wi_import.dbo.ds_organisation_data ds INNER JOIN #users u ON ds.last_update_by = u.old_id

UPDATE ds SET ds.created_by = u.id FROM wi_import.dbo.ds_organisation_forecast_data ds INNER JOIN #users u ON ds.created_by = u.old_id
UPDATE ds SET ds.last_update_by = u.id FROM wi_import.dbo.ds_organisation_forecast_data ds INNER JOIN #users u ON ds.last_update_by = u.old_id

UPDATE ds SET ds.created_by = u.id FROM wi_import.dbo.ds_service_data ds INNER JOIN #users u ON ds.created_by = u.old_id
UPDATE ds SET ds.last_update_by = u.id FROM wi_import.dbo.ds_service_data ds INNER JOIN #users u ON ds.last_update_by = u.old_id

UPDATE ds SET ds.created_by = u.id FROM wi_import.dbo.ds_zone_data ds INNER JOIN #users u ON ds.created_by = u.old_id
UPDATE ds SET ds.last_update_by = u.id FROM wi_import.dbo.ds_zone_data ds INNER JOIN #users u ON ds.last_update_by = u.old_id

UPDATE ds SET ds.created_by = u.id FROM wi_import.dbo.ds_zone_forecast_data ds INNER JOIN #users u ON ds.created_by = u.old_id
UPDATE ds SET ds.last_update_by = u.id FROM wi_import.dbo.ds_zone_forecast_data ds INNER JOIN #users u ON ds.last_update_by = u.old_id

DROP TABLE #users
