
CREATE PROCEDURE [dbo].[process_switch_smartphones]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

CREATE TABLE #data (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, source_id int, confidence_id int, is_decimal bit, processed bit)

-- Get reported "installed base" and "penetration" data sets
INSERT INTO #data
SELECT	null, ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, CASE WHEN ds.val_i IS null THEN ds.val_d ELSE ds.val_i END, ds.currency_id, ds.source_id, ds.confidence_id, null, 0
FROM	ds_organisation_data ds INNER JOIN organisations o ON ds.organisation_id = o.id
WHERE	ds.metric_id IN (183,184) AND ds.attribute_id = 0 AND ds.date >= @date_start AND ds.date < @date_end

-- Update metric/attribute id to connections/% connections
UPDATE #data SET metric_id = 3, attribute_id = 1432 WHERE metric_id = 183 AND attribute_id = 0
UPDATE #data SET metric_id = 53, attribute_id = 1432 WHERE metric_id = 184 AND attribute_id = 0

UPDATE #data SET is_decimal = dbo.metric_is_decimal(metric_id)


-- Overwrite with reported data that has been already updated to use the new metric/attribute ids
UPDATE	d
SET		d.value = CASE WHEN ds.val_i IS null THEN ds.val_d ELSE ds.val_i END, d.currency_id = ds.currency_id, d.source_id = ds.source_id, d.confidence_id = ds.confidence_id
FROM	#data d INNER JOIN
		ds_organisation_data ds ON (d.organisation_id = ds.organisation_id AND d.metric_id = ds.metric_id AND d.attribute_id = ds.attribute_id AND d.date = ds.date AND d.date_type = ds.date_type)
WHERE	ds.metric_id IN (3,53) AND ds.attribute_id = 1432 AND ds.is_calculated = 0


-- Fetch existing ids so we can UPDATE against these rows
UPDATE	d
SET		d.id = ds.id
FROM	#data d INNER JOIN ds_organisation_data ds ON (d.organisation_id = ds.organisation_id AND d.metric_id = ds.metric_id AND d.attribute_id = ds.attribute_id AND d.date = ds.date AND d.date_type = ds.date_type)

-- Remove any NULL data
DELETE FROM #data WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE d.is_decimal WHEN 1 THEN ROUND(d.value, 4) ELSE null END, ds.val_i = CASE d.is_decimal WHEN 1 THEN null ELSE ROUND(d.value, 0) END, ds.last_update_on = CASE WHEN ds.val_d = d.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_d = d.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_organisation_data ds INNER JOIN #data d ON ds.id = d.id

	-- INSERT the remainder
	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, created_by)
	SELECT	organisation_id, metric_id, attribute_id, date, date_type, CASE is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, currency_id, source_id, confidence_id, 11770
	FROM	#data
	WHERE	id IS null
END

IF @debug = 1
BEGIN
	SELECT * FROM #data
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: process_merge_smartphones (42s)'

DROP TABLE #data
