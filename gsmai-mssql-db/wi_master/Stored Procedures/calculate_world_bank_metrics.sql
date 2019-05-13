

CREATE PROCEDURE [dbo].[calculate_world_bank_metrics]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

-- Calculation table
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_calculated bit, is_spot bit, source_id int, confidence_id int, processed bit)


-- Get all imported World Bank metrics as a reference set
INSERT INTO #calc
SELECT	ds.id, ds.zone_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, CASE WHEN ds.val_i IS null THEN ds.val_d ELSE ds.val_i END, ds.currency_id, ds.is_calculated, ds.is_spot, ds.source_id, ds.confidence_id, 1
FROM	ds_zone_data ds INNER JOIN metric_import_link mi ON (ds.metric_id = mi.metric_id AND ds.attribute_id = mi.attribute_id)
WHERE	mi.source_organisation_id = 1002 AND mi.is_calculated = 0 AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = 'Y'

-- Calculate matching values (urban/rural, male/female)

-- % population, urban/male FROM % population, rural/female
INSERT INTO #calc
SELECT	null, zone_id, metric_id, CASE attribute_id WHEN 1359 THEN 1360 WHEN 1362 THEN 1361 ELSE null END, date, date_type, 1 - value, currency_id, 1, is_spot, source_id, confidence_id, 0
FROM	#calc
WHERE	metric_id = 99 AND attribute_id IN (1359,1362)

-- % population, economically active FROM population, economically active
INSERT INTO #calc
SELECT	null, c1.zone_id, 99, c1.attribute_id, c1.date, c1.date_type, c1.value/c2.value, c1.currency_id, 1, c1.is_spot, c1.source_id, c1.confidence_id, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.zone_id = c2.zone_id AND c1.date = c2.date AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 43 AND c1.attribute_id = 1506 AND c2.metric_id = 176 AND c2.attribute_id = 0

-- Population, urban/rural/male/female/0-14/14-64/65+ FROM % population, urban/rural/male/female/0-14/14-64/65+
INSERT INTO #calc
SELECT	null, c1.zone_id, 43, c1.attribute_id, c1.date, c1.date_type, c1.value * c2.value, c1.currency_id, 1, c1.is_spot, c1.source_id, c1.confidence_id, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.zone_id = c2.zone_id AND c1.date = c2.date AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 99 AND c1.attribute_id IN (1359,1360,1361,1362,1503,1504,1505,1506) AND c2.metric_id = 176 AND c2.attribute_id = 0


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)
WHERE	c.id IS null

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- Delete existing calculated data
	DELETE ds FROM ds_zone_data ds INNER JOIN metric_import_link mi ON (ds.metric_id = mi.metric_id AND ds.attribute_id = mi.attribute_id AND mi.is_calculated = 1)

	-- Update any existing values
	UPDATE	ds
	SET		ds.val_d = CASE m.type_id WHEN 856 THEN c.value ELSE null END, ds.val_i = CASE m.type_id WHEN 857 THEN ROUND(c.value, 0) ELSE null END, ds.currency_id = c.currency_id, ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.is_calculated = c.is_calculated, ds.is_spot = c.is_spot, ds.last_update_on = GETDATE(), ds.last_update_by = 11770
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id INNER JOIN metrics m ON ds.metric_id = m.id
	WHERE	c.processed = 0 AND c.id IS NOT null AND c.value IS NOT null

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_spot, created_by)
	SELECT	c.zone_id, c.metric_id, c.attribute_id, c.date, c.date_type, CASE m.type_id WHEN 856 THEN c.value ELSE null END, CASE m.type_id WHEN 857 THEN ROUND(c.value, 0) ELSE null END, c.currency_id, c.source_id, c.confidence_id, c.is_calculated, c.is_spot, 11770
	FROM	#calc c INNER JOIN metrics m ON c.metric_id = m.id
	WHERE	c.processed = 0 AND c.id IS null AND c.value IS NOT null

	UPDATE #calc SET processed = 1 WHERE processed = 0
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY zone_id, metric_id, attribute_id, date
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_world_bank_metrics (17s)'

DROP TABLE #calc

