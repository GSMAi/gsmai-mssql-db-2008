
CREATE PROCEDURE [dbo].[calculate_absolute_from_percentage]

(
	@metric_id int,
	@attribute_id int,
	@absolute_metric_id int,
	@absolute_total_attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), value_percentage decimal(22,8), value_total decimal(22,8), source_id int, confidence_id int, processed bit)

-- Fetch the % shares and absolute totals
INSERT INTO #calc
SELECT	null, ds.organisation_id, @absolute_metric_id, ds.attribute_id, ds.date, ds.date_type, null, ds.val_d, null, ds.source_id, ds.confidence_id, 0
FROM	ds_organisation_data ds
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type IN ('Q','H','Y')
ORDER BY ds.organisation_id, ds.attribute_id

UPDATE	c
SET		c.value_total = CAST(ds.val_i AS decimal(22,8))
FROM	#calc c INNER JOIN ds_organisation_data ds ON (ds.organisation_id = c.organisation_id AND ds.date = c.date AND ds.date_type = c.date_type)
WHERE	ds.metric_id = @absolute_metric_id AND ds.attribute_id = @absolute_total_attribute_id AND ds.status_id = 3


-- Calculate the absolutes for the attribute
UPDATE #calc SET value = value_percentage * value_total


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_organisation_data ds ON (c.organisation_id = ds.organisation_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the _calculated_ values that already exist (ie don't overwrite reported/imported absolutes)
	UPDATE	ds
	SET		ds.val_d = null, ds.val_i = ROUND(c.value, 0), ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.last_update_on = CASE WHEN ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_organisation_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1 AND c.processed = 0

	-- INSERT the remainder
	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	organisation_id, metric_id, attribute_id, date, date_type, null, ROUND(value, 0), 0, source_id, confidence_id, 1, 11770
	FROM	#calc
	WHERE	id IS null AND processed = 0
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY organisation_id, attribute_id, date
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_absolute_from_percentage (2s)'

DROP TABLE #calc
