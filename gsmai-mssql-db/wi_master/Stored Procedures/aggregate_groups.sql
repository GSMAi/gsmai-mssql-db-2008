
CREATE PROCEDURE [dbo].[aggregate_groups]

(
	@date_start datetime,
	@date_end datetime,
	@is_proportionate bit = 0,
	@debug bit = 1
)

AS

DECLARE @ownership_threshold decimal(6,4)

CREATE TABLE #attributes (id int, processed bit)
CREATE TABLE #data (id bigint, group_id int, organisation_id int, ownership decimal(6,4), is_consolidated bit, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6))	-- Calculate to a greater accuracy than we store, to inform last digit rounding
CREATE TABLE #calc (id bigint, group_id int, ownership_threshold decimal(6,4), metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6), is_decimal bit, processed bit)

INSERT INTO #attributes
SELECT attribute_id, 0 FROM data_sets WHERE metric_id = 3 AND attribute_id IS NOT null AND is_aggregated = 1 AND is_aggregated_from_organisation_data = 1


-- Fetch operator-level data and ownership
INSERT INTO #data
SELECT	ds.id,
		ds2.group_id,
		ds2.organisation_id,
		ds2.value,
		ds2.is_consolidated,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		ds.val_i

FROM	ds_organisation_data ds INNER JOIN
		ds_group_ownership ds2 ON (ds.organisation_id = ds2.organisation_id AND ds.date = ds2.date AND ds.date_type = ds2.date_type)

WHERE	ds.metric_id = 3 AND
		ds.attribute_id IN (SELECT id FROM #attributes) AND
		ds2.metric_id = 72 AND
		ds2.attribute_id = 0 AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y')

ORDER BY ds2.group_id, ds2.organisation_id, ds.date, ds.date_type


-- Weight by ownership if @is_proportionate
IF @is_proportionate = 1
BEGIN
	UPDATE #data SET value = value * CAST(ownership AS decimal(22,6))
END


SET @ownership_threshold = 0.0

WHILE @ownership_threshold <= 1.0
BEGIN
	-- Create the aggregates for this @ownership_threshold

	-- Connections (3)
	INSERT INTO #calc
	SELECT	null, d.group_id, @ownership_threshold, 3, d.attribute_id, d.date, d.date_type, SUM(d.value), 0, 0
	FROM	#data d
	WHERE	d.ownership >= @ownership_threshold
	GROUP BY d.group_id, d.attribute_id, d.date, d.date_type

	IF @ownership_threshold = 0.5
	BEGIN
		-- Special additional aggregation for 'majority ownership', stored as @ownership_threshold = 0.51
		INSERT INTO #calc
		SELECT	null, d.group_id, 0.51, 3, d.attribute_id, d.date, d.date_type, SUM(d.value), 0, 0
		FROM	#data d
		WHERE	d.ownership > 0.5 OR d.is_consolidated = 1
		GROUP BY d.group_id, d.attribute_id, d.date, d.date_type
	END

	SET @ownership_threshold = @ownership_threshold + 0.1
END


-- Calculate the derivatives

-- Net additions (36)
INSERT INTO #calc
SELECT	null, c2.group_id, c2.ownership_threshold, 36, c2.attribute_id, c2.date, c2.date_type, c2.value-c1.value, 0, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.group_id = c2.group_id AND c1.ownership_threshold = c2.ownership_threshold AND c1.metric_id = c2.metric_id AND c1.attribute_id = c2.attribute_id AND c2.date = DATEADD(month, CASE c1.date_type WHEN 'Q' THEN 3 WHEN 'H' THEN 6 WHEN 'Y' THEN 12 END, c1.date) AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 3 AND c2.metric_id = 3 AND c1.value <> 0 AND c1.value IS NOT null AND c2.value <> 0 AND c2.value IS NOT null

-- % connections (53)
INSERT INTO #calc
SELECT	null, c2.group_id, c2.ownership_threshold, 53, c2.attribute_id, c2.date, c2.date_type, c2.value/c1.value, 1, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.group_id = c2.group_id AND c1.ownership_threshold = c2.ownership_threshold AND c1.metric_id = c2.metric_id AND c1.date = c2.date AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 3 AND c2.metric_id = 3 AND c1.attribute_id = 0 AND c2.attribute_id <> 0 AND c1.value <> 0 AND c1.value IS NOT null AND c2.value <> 0 AND c2.value IS NOT null

-- Growth, sequential (56)
INSERT INTO #calc
SELECT	null, c2.group_id, c2.ownership_threshold, 56, c2.attribute_id, c2.date, c2.date_type, (c2.value-c1.value)/c1.value, 1, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.group_id = c2.group_id AND c1.ownership_threshold = c2.ownership_threshold AND c1.metric_id = c2.metric_id AND c1.attribute_id = c2.attribute_id AND c2.date = DATEADD(month, CASE c1.date_type WHEN 'Q' THEN 3 WHEN 'H' THEN 6 WHEN 'Y' THEN 12 END, c1.date) AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 3 AND c2.metric_id = 3 AND c1.date_type <> 'Y' AND c1.value <> 0 AND c1.value IS NOT null AND c2.value <> 0 AND c2.value IS NOT null

-- Growth, annual (61)
INSERT INTO #calc
SELECT	null, c2.group_id, c2.ownership_threshold, 61, c2.attribute_id, c2.date, c2.date_type, (c2.value-c1.value)/c1.value, 1, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.group_id = c2.group_id AND c1.ownership_threshold = c2.ownership_threshold AND c1.metric_id = c2.metric_id AND c1.attribute_id = c2.attribute_id AND c2.date = DATEADD(month, 12, c1.date) AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 3 AND c2.metric_id = 3 AND c1.value <> 0 AND c1.value IS NOT null AND c2.value <> 0 AND c2.value IS NOT null


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_group_data ds ON (c.group_id = ds.organisation_id AND c.ownership_threshold = ds.ownership_threshold AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type AND ds.is_proportionate = @is_proportionate)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE c.is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE c.is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.source_id = 6, ds.confidence_id = 194, ds.last_update_on = CASE WHEN (c.is_decimal = 1 AND ds.val_d = ROUND(c.value, 4)) OR (c.is_decimal = 0 AND ds.val_i = ROUND(c.value, 0)) THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN (c.is_decimal = 1 AND ds.val_d = ROUND(c.value, 4)) OR (c.is_decimal = 0 AND ds.val_i = ROUND(c.value, 0)) THEN ds.last_update_by ELSE 11770 END
	FROM	ds_group_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1 AND c.processed = 0

	-- INSERT the remainder
	INSERT INTO ds_group_data (organisation_id, ownership_threshold, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_proportionate, created_by)
	SELECT	c.group_id, c.ownership_threshold, c.metric_id, c.attribute_id, c.date, c.date_type, CASE c.is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, CASE c.is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, 0, 6, 194, 1, @is_proportionate, 11770
	FROM	#calc c
	WHERE	c.id IS null AND c.processed = 0
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY group_id, ownership_threshold, metric_id, attribute_id, date, date_type
END


SELECT 'Finished: aggregate_groups (17s)'

DROP TABLE #attributes
DROP TABLE #data
DROP TABLE #calc
