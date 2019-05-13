
CREATE PROCEDURE [dbo].[calculate_hhi]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit
SET @is_decimal = dbo.metric_is_decimal(155)

CREATE TABLE #data (zone_id int, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8))
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, number_of_operators decimal(22,8), value decimal(22,8), currency_id int, source_id int, confidence_id int, is_calculated bit, processed bit)


-- Get all operator market share data as a reference data set
INSERT INTO #data
SELECT	oz.zone_id, ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, ds.val_d
FROM	ds_organisation_data ds INNER JOIN organisations o ON ds.organisation_id = o.id INNER JOIN organisation_zone_link oz ON o.id = oz.organisation_id
WHERE	ds.metric_id = 41 AND ds.attribute_id = 0 AND ds.date >= @date_start AND ds.date < @date_end AND o.type_id = 1089

-- Create the HHI for all countries
INSERT INTO #calc
SELECT	DISTINCT null, zone_id, 155, 0, date, date_type, COUNT(organisation_id), SUM(SQUARE(value * 100)), 0, 6, 194, 1, 0
FROM	#data
GROUP BY zone_id, date, date_type


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
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.currency_id = c.currency_id, ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.is_calculated = c.is_calculated, ds.last_update_on = CASE WHEN CAST(ds.val_i AS decimal(22,8)) = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN CAST(ds.val_i AS decimal(22,8)) = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	c.value IS NOT null

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	c.zone_id, c.metric_id, c.attribute_id, c.date, c.date_type, CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, c.currency_id, c.source_id, c.confidence_id, c.is_calculated, 11770
	FROM	#calc c
	WHERE	c.id IS null AND c.value IS NOT null
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY zone_id, date_type, date
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_hhi (3s)'

DROP TABLE #calc
DROP TABLE #data
