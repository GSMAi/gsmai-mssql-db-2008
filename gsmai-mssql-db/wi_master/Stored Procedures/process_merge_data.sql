
CREATE PROCEDURE [dbo].[process_merge_data]

(
	@debug bit = 1
)

AS

DECLARE @today datetime, @yesterday datetime, @ds varchar(128), @hash nvarchar(128)

SET @today		= GETDATE()
SET @yesterday	= DATEADD(day, -1, @today)


-- Auto-unapproval conditions
EXEC wi_import.dbo.process_legacy_hold_data @debug

-- Map legacy data (pre metric_id/attribute_id combinations)
EXEC wi_import.dbo.process_legacy_map_dimvals @debug

-- Map legacy M2M data imports (TODO: remove when updating data _and_ forecast import files)
EXEC wi_import.dbo.process_legacy_map_m2m_connections @debug

-- Add new data point and metadata hashes
EXEC wi_import.dbo.process_create_hashes @debug

-- For partial time series stores, delete any duplicate data points
EXEC wi_import.dbo.process_delete_duplicates @debug


-- Delete existing data set for full time series imports (ie forecasting team imports)
CREATE TABLE #zones (triggered_by_import varchar(128), id int)
CREATE TABLE #organisations (triggered_by_import varchar(128), id int)
CREATE TABLE #data (ds varchar(128), id int)

-- Total subscribers
INSERT INTO #zones
SELECT DISTINCT 'subscribers-total', zone_id FROM wi_import.dbo.ds_zone_forecast_data WHERE metric_id IN (1,322) AND attribute_id = 0 AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #zones WHERE triggered_by_import = 'subscribers-total') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id IN (1,178,179,180,181,182,322,323,324,325,326,327) AND
			attribute_id = 0 AND
			(
				zone_id IN (SELECT id FROM #zones WHERE triggered_by_import = 'subscribers-total') OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)
END

-- Internet subscribers
INSERT INTO #zones
SELECT DISTINCT 'subscribers-internet', zone_id FROM wi_import.dbo.ds_zone_forecast_data WHERE metric_id IN (1,322) AND attribute_id = 1581 AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #zones WHERE triggered_by_import = 'subscribers-internet') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id IN (1,178,179,180,181,182,305,306,307,322,323,324,325,326,327,328,329,330) AND -- Includes % subscribers, unlike total
			attribute_id IN (1581,1582,1583) AND
			(
				zone_id IN (SELECT id FROM #zones WHERE triggered_by_import = 'subscribers-internet') OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)
END

-- Active connections
INSERT INTO #zones
SELECT DISTINCT 'connections-active', zone_id FROM wi_import.dbo.ds_zone_forecast_data WHERE metric_id = 3 AND attribute_id = 204 AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #zones WHERE triggered_by_import = 'connections-active') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id IN (3,36,41,42,44,53,56,61) AND
			attribute_id = 204 AND
			(
				zone_id IN (SELECT id FROM #zones WHERE triggered_by_import = 'connections-active') OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)
END

-- Population
INSERT INTO #zones
SELECT DISTINCT 'population-total', zone_id FROM wi_import.dbo.ds_zone_forecast_data WHERE metric_id = 43 AND attribute_id = 0 AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #zones WHERE triggered_by_import = 'population-total') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id = 43 AND
			attribute_id = 0 AND
			(
				zone_id IN (SELECT id FROM #zones WHERE triggered_by_import = 'population-total') OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)
END

-- Total connections
INSERT INTO #organisations
SELECT DISTINCT 'connections-total', organisation_id FROM wi_import.dbo.ds_organisation_forecast_data WHERE metric_id = 3 AND attribute_id = 0 AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #organisations WHERE triggered_by_import = 'connections-total') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id IN (3,36,41,42,44,53,56,61,190,309,310,311,312) AND -- Deleting both including and excluding M2M metrics, _except_ the actual M2M connection split (below)
			attribute_id IN (0,99,822,836,1198,602,603,616,619,621,624,823,824,825,870,929,931,936,996,1124,1201,1245,1293,1307,1397,1399,1401,1403,1405,1407,1409,1411,1413,1472,1473,1474,755,796,799,951,952,959,1120,1292,1384,1385,1615,1616,1617,1618) AND
			(
				zone_id IN (SELECT DISTINCT zone_id FROM organisation_zone_link WHERE organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'connections-total')) OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)

	INSERT INTO #data
	SELECT	'ds_organisation_data', id
	FROM	ds_organisation_data
	WHERE	metric_id IN (3,36,41,42,44,53,56,61,190,309,310,311,312) AND -- Deleting both including and excluding M2M metrics, _except_ the actual M2M connection split (below)
			attribute_id IN (0,99,822,836,1198,602,603,616,619,621,624,823,824,825,870,929,931,936,996,1124,1201,1245,1293,1307,1397,1399,1401,1403,1405,1407,1409,1411,1413,1472,1473,1474,755,796,799,951,952,959,1120,1292,1384,1385,1615,1616,1617,1618) AND
			organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'connections-total') AND
			date_type = 'Q'
END

-- M2M connections
INSERT INTO #organisations
SELECT DISTINCT 'connections-m2m', organisation_id FROM wi_import.dbo.ds_organisation_forecast_data WHERE metric_id = 190 AND attribute_id = 1251 AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #organisations WHERE triggered_by_import = 'connections-m2m') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id IN (190,309,310,311,312) AND
			attribute_id IN (1251,1546,1547,1548,1549,1550,1619) AND
			(
				zone_id IN (SELECT DISTINCT zone_id FROM organisation_zone_link WHERE organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'connections-m2m')) OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)

	INSERT INTO #data
	SELECT	'ds_organisation_data', id
	FROM	ds_organisation_data
	WHERE	metric_id IN (190,309,310,311,312) AND
			attribute_id IN (1251,1546,1547,1548,1549,1550,1619) AND
			organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'connections-m2m') AND
			date_type = 'Q'
END

-- Device connections
INSERT INTO #organisations
SELECT DISTINCT 'connections-devices', organisation_id FROM wi_import.dbo.ds_organisation_forecast_data WHERE metric_id = 3 AND attribute_id IN (1432,1555,1556) AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #organisations WHERE triggered_by_import = 'connections-devices') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id IN (3,36,41,42,44,53,56,61) AND
			attribute_id IN (1432,1555,1556) AND
			(
				zone_id IN (SELECT DISTINCT zone_id FROM organisation_zone_link WHERE organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'connections-devices')) OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)

	INSERT INTO #data
	SELECT	'ds_organisation_data', id
	FROM	ds_organisation_data
	WHERE	metric_id IN (3,36,41,42,44,53,56,61) AND
			attribute_id IN (1432,1555,1556) AND
			organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'connections-devices') AND
			date_type = 'Q'
END

-- Coverage
INSERT INTO #organisations
SELECT DISTINCT 'coverage', organisation_id FROM wi_import.dbo.ds_organisation_forecast_data WHERE metric_id = 162 AND attribute_id IN (755,799,1615,1615) AND approved = 1 AND last_update_on >= @yesterday

IF (SELECT COUNT(*) FROM #organisations WHERE triggered_by_import = 'coverage-3g') > 0
BEGIN
	INSERT INTO #data
	SELECT	'ds_zone_data', id
	FROM	ds_zone_data
	WHERE	metric_id = 162 AND
			attribute_id IN (755,799,1615,1615) AND
			(
				zone_id IN (SELECT DISTINCT zone_id FROM organisation_zone_link WHERE organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'coverage')) OR
				zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (3,39,42,43,44))
			)

	INSERT INTO #data
	SELECT	'ds_organisation_data', id
	FROM	ds_organisation_data
	WHERE	metric_id = 162 AND
			attribute_id IN (755,799,1615,1615) AND
			organisation_id IN (SELECT id FROM #organisations WHERE triggered_by_import = 'coverage') AND
			date_type = 'Q'
END

IF @debug = 1
BEGIN
	SELECT * FROM #zones
	SELECT * FROM #organisations
	--SELECT * FROM #data
END

IF @debug = 0
BEGIN
	-- Delete superset of data
	DELETE	ds
	FROM	ds_zone_data ds INNER JOIN #data d ON (ds.id = d.id AND d.ds = 'ds_zone_data')

	DELETE	ds
	FROM	ds_organisation_data ds INNER JOIN #data d ON (ds.id = d.id AND d.ds = 'ds_organisation_data')
END

DROP TABLE #zones
DROP TABLE #organisations
DROP TABLE #data


-- Now merge each import table in turn with new data (those ordered last overwrite former imports)
CREATE TABLE #approval_hashes (ds varchar(128), hash nvarchar(128), processed bit)

-- Organisation-level forecast imports (full time series)
INSERT INTO #approval_hashes
SELECT 'ds_organisation_forecast_data', approval_hash, 0 FROM wi_import.dbo.ds_organisation_forecast_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @yesterday GROUP BY approval_hash ORDER BY MAX(created_on)

-- Country-level forecast imports (full time series)
INSERT INTO #approval_hashes
SELECT 'ds_zone_forecast_data', approval_hash, 0 FROM wi_import.dbo.ds_zone_forecast_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @yesterday GROUP BY approval_hash ORDER BY MAX(created_on)

-- Organisation-level imports
INSERT INTO #approval_hashes
SELECT 'ds_organisation_data', approval_hash, 0 FROM wi_import.dbo.ds_organisation_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @yesterday GROUP BY approval_hash ORDER BY MAX(created_on)

-- Country-level imports
INSERT INTO #approval_hashes
SELECT 'ds_zone_data', approval_hash, 0 FROM wi_import.dbo.ds_zone_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @yesterday GROUP BY approval_hash ORDER BY MAX(created_on)

IF @debug = 1
BEGIN
	SELECT * FROM #approval_hashes
END

IF @debug = 0
BEGIN
	-- Organisation-level forecast imports (full time series)
	SET @ds = 'ds_organisation_forecast_data'

	WHILE EXISTS (SELECT * FROM #approval_hashes WHERE ds = @ds AND processed = 0)
	BEGIN
		SET @hash = (SELECT TOP 1 hash FROM #approval_hashes WHERE ds = @ds AND processed = 0)
		EXEC process_merge_import_organisation_forecast_data @hash, @debug

		UPDATE #approval_hashes SET processed = 1 WHERE ds = @ds AND hash = @hash
	END

	-- Country-level forecast imports (full time series)
	SET @ds = 'ds_zone_forecast_data'

	WHILE EXISTS (SELECT * FROM #approval_hashes WHERE ds = @ds AND processed = 0)
	BEGIN
		SET @hash = (SELECT TOP 1 hash FROM #approval_hashes WHERE ds = @ds AND processed = 0)
		EXEC process_merge_import_zone_forecast_data @hash, @debug

		UPDATE #approval_hashes SET processed = 1 WHERE ds = @ds AND hash = @hash
	END

	-- Organisation-level imports
	SET @ds = 'ds_organisation_data'

	WHILE EXISTS (SELECT * FROM #approval_hashes WHERE ds = @ds AND processed = 0)
	BEGIN
		SET @hash = (SELECT TOP 1 hash FROM #approval_hashes WHERE ds = @ds AND processed = 0)
		EXEC process_merge_import_organisation_data @hash, @debug

		UPDATE #approval_hashes SET processed = 1 WHERE ds = @ds AND hash = @hash
	END

	-- Country-level forecast imports (full time series)
	SET @ds = 'ds_zone_data'

	WHILE EXISTS (SELECT * FROM #approval_hashes WHERE ds = @ds AND processed = 0)
	BEGIN
		SET @hash = (SELECT TOP 1 hash FROM #approval_hashes WHERE ds = @ds AND processed = 0)
		EXEC process_merge_import_zone_data @hash, @debug

		UPDATE #approval_hashes SET processed = 1 WHERE ds = @ds AND hash = @hash
	END
END

DROP TABLE #approval_hashes


-- Finally, map master to the latest import ids
EXEC wi_import.dbo.process_map_imports @debug
