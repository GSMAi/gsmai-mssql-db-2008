
CREATE PROCEDURE [dbo].[aggregate_metric_by_maximum_minimum]

(
	@metric_id int,
	@attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@max_or_min bit = 1,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit
SET @is_decimal = dbo.metric_is_decimal(@metric_id)


-- Calculation tables; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #data (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, source_id int, confidence_id int, zone_id int)
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit, source_id int, confidence_id int, is_calculated bit, processed bit)


-- Fetch all organisation-level values for each distinct organisation_zone_link relationship
INSERT INTO #data
SELECT	DISTINCT
		ds.id,
		ds.organisation_id,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END,
		ds.currency_id, 
		ds.source_id,
		ds.confidence_id,
		oz.zone_id
		
FROM	ds_organisation_data ds INNER JOIN
		organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
		zones z ON oz.zone_id = z.id

WHERE	ds.metric_id = @metric_id AND
		ds.attribute_id = @attribute_id AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y') AND
		ds.status_id = 3 AND
		z.type_id = 10


-- Calculate country aggregates
INSERT INTO #calc
SELECT	null, zone_id, metric_id, attribute_id, date, date_type, CASE @max_or_min WHEN 0 THEN MIN(value) ELSE MAX(value) END, 0, null, MIN(source_id), MAX(confidence_id), 1, 0
FROM	#data
GROUP BY zone_id, metric_id, attribute_id, date, date_type
ORDER BY zone_id, metric_id, attribute_id, date, date_type


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.last_update_on = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_spot, created_by)
	SELECT	zone_id, metric_id, attribute_id, date, date_type, CASE @is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, currency_id, 6, 194, 1, is_spot, 11770
	FROM	#calc
	WHERE	id IS null
END

IF @debug = 1
BEGIN
	--SELECT * FROM #data
	SELECT * FROM #calc ORDER BY zone_id, date_type, date, is_spot, currency_id
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: aggregate_metric_by_maximum_minimum (3s)'

DROP TABLE #data
DROP TABLE #calc
