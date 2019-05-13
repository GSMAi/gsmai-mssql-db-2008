
CREATE PROCEDURE [dbo].[calculate_connections_families]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, attribute_family_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value bigint, source_id int, confidence_id int, processed bit)

INSERT INTO #calc
SELECT	ds.id,
		ds.organisation_id,
		ds.metric_id,
		ds.attribute_id,
		af.family_id,
		ds.date,
		ds.date_type,
		ds.val_i,
		ds.source_id,
		ds.confidence_id,
		0

FROM	ds_organisation_data ds INNER JOIN
		attribute_family_link af ON ds.attribute_id = af.attribute_id

WHERE	ds.metric_id = 3 AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y')

ORDER BY ds.organisation_id, af.family_id, ds.attribute_id

-- Normalise historicly used source values to supress odd source/conf combinations later
UPDATE #calc SET source_id = 5 WHERE source_id IN (6,8,13,21)
UPDATE #calc SET source_id = 11 WHERE source_id IN (17,19)

-- Sum the families
INSERT INTO #calc
SELECT	null, organisation_id, metric_id, attribute_family_id, attribute_family_id, date, date_type, SUM(value), SUM(source_id), SUM(confidence_id), 0
FROM	#calc
GROUP BY organisation_id, metric_id, attribute_family_id, date, date_type

-- Remove operator data and normalise source/confidence
DELETE FROM #calc WHERE attribute_id <> attribute_family_id

UPDATE #calc SET confidence_id = 192 WHERE confidence_id % 192 = 0
UPDATE #calc SET confidence_id = 194 WHERE confidence_id <> 192

UPDATE #calc SET source_id = 11 WHERE source_id % 11 = 0 AND confidence_id = 192
UPDATE #calc SET source_id = 20 WHERE source_id % 20 = 0 AND confidence_id = 192
UPDATE #calc SET source_id = 6 WHERE source_id NOT IN (11,20) OR confidence_id = 194


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_organisation_data ds ON (c.organisation_id = ds.organisation_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = null, ds.val_i = ROUND(c.value, 0), ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.is_calculated = 1, ds.last_update_on = CASE WHEN ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_organisation_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	c.processed = 0

	-- INSERT the remainder
	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	organisation_id, metric_id, attribute_id, date, date_type, null, ROUND(value, 0), 0, source_id, confidence_id, 1, 11770
	FROM	#calc
	WHERE	id IS null AND processed = 0
	
	
	-- Update the families that share single technologies (to eliminate double-counting)
	
	-- Remove "Family + 4G" numbers where they are only equal to 4G
	DELETE	ds

	FROM	ds_organisation_data ds INNER JOIN
			ds_organisation_data ds2 ON (ds.organisation_id = ds2.organisation_id AND ds.metric_id = ds2.metric_id AND ds.date = ds2.date AND ds.date_type = ds2.date_type)
			
	WHERE	ds.metric_id = 3 AND
			ds.attribute_id IN (1538,1540,1541) AND
			ds2.metric_id = 3 AND
			ds2.attribute_id = 799 AND
			ds.val_i = ds2.val_i
			
	-- Adjust "CDMA (Family) + 4G" numbers so we don't double count connections where operators run CDMA and WCDMA as well as 4G
	UPDATE	ds

	SET		ds.val_i = ds.val_i - ds2.val_i

	FROM	ds_organisation_data ds INNER JOIN
			ds_organisation_data ds2 ON (ds.organisation_id = ds2.organisation_id AND ds.metric_id = ds2.metric_id AND ds.date = ds2.date AND ds.date_type = ds2.date_type) INNER JOIN
			(
				SELECT	organisation_id,
						date,
						date_type
						
				FROM	ds_organisation_data

				WHERE	metric_id = 3 AND
						attribute_id IN (1538,1540,1541,799)
						
				GROUP BY organisation_id, date, date_type
				HAVING COUNT(val_i) = 3
			) ds3 ON (ds.organisation_id = ds3.organisation_id AND ds.date = ds3.date AND ds.date_type = ds3.date_type)
			
	WHERE	ds.metric_id = 3 AND
			ds.attribute_id = 1538 AND
			ds2.metric_id = 3 AND
			ds2.attribute_id = 799

	-- Finally, "4G-only" should exist for those that don't have "Family + 4G" figures (over the time series!)
	DELETE	ds
	
	FROM	ds_organisation_data ds INNER JOIN
			ds_organisation_data ds2 ON (ds.organisation_id = ds2.organisation_id AND ds.metric_id = ds2.metric_id AND ds.date = ds2.date AND ds.date_type = ds2.date_type)
			
	WHERE	ds.metric_id = 3 AND
			ds.attribute_id = 1543 AND
			ds2.attribute_id IN (1538,1540,1541)
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY organisation_id, attribute_id, date
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_connections_families (17s)'

DROP TABLE #calc
