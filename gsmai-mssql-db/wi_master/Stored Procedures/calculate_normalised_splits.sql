
CREATE PROCEDURE [dbo].[calculate_normalised_splits]

(
	@metric_id int,
	@attribute_id int,
	@type_id int,
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

-- Get all metric data, totals and splits for the current @metric_id/@attribute_id and @type_id
CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), new_value decimal(22,8), source_id int, confidence_id int, delta bit, total decimal(22,8), sum_estimated_values decimal(22,8), sum_reported_values decimal(22,8), weighting_value decimal(22,8), sum_new_estimated_values decimal(22,8), process bit, processed bit)

INSERT INTO #calc
SELECT	ds.id,
		ds.organisation_id,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		CAST(ds.val_i AS decimal(22,8)),
		null,
		ds.source_id,
		ds.confidence_id,
		0,
		null,
		null,
		null,
		null,
		null,
		0,
		1

FROM	ds_organisation_data ds INNER JOIN 
		organisations o ON ds.organisation_id = o.id INNER JOIN
		attributes a ON ds.attribute_id = a.id

WHERE	ds.metric_id = @metric_id AND
		(a.id = @attribute_id OR a.type_id = @type_id) AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type = 'Q' AND
		o.type_id = 1089 

ORDER BY ds.organisation_id, ds.date_type, ds.date, ds.val_i DESC


-- Create a table showing a count of the splits and any deltas
CREATE TABLE #normalisation (organisation_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, total decimal(22,8), count int, sum decimal(22,8), delta decimal(22,8))

INSERT INTO #normalisation
SELECT	c.organisation_id,
		c.date,
		c.date_type,
		null,
		COUNT(c.value),
		SUM(c.value),
		null

FROM	#calc c

WHERE	c.attribute_id <> @attribute_id

GROUP BY c.organisation_id, c.date, c.date_type

-- Update table with the "total" value and calculate split delta against it
UPDATE	n
SET		n.total = c.value
		
FROM	#normalisation n INNER JOIN
		#calc c ON (n.organisation_id = c.organisation_id AND n.date = c.date AND n.date_type = c.date_type)
		
WHERE	c.attribute_id = @attribute_id

UPDATE #normalisation SET delta = total - sum


-- Simply match value/source/confidence in any quarters in which operators have a single split
UPDATE	c1
SET		c1.new_value = c2.value, 
		c1.source_id = c2.source_id,
		c1.confidence_id = c2.confidence_id,
		c1.process = 1
		
FROM	#calc c1 INNER JOIN
		#calc c2 ON (c1.organisation_id = c2.organisation_id AND c1.date = c2.date AND c1.date_type = c2.date_type) INNER JOIN
		#normalisation n ON (c1.organisation_id = n.organisation_id AND c1.date = n.date AND c1.date_type = n.date_type)
		
WHERE	c1.attribute_id <> @attribute_id AND
		c2.attribute_id = @attribute_id AND
		n.count = 1 AND
		(
			n.delta <> 0 OR
			c1.source_id <> c2.source_id OR
			c1.confidence_id <> c2.confidence_id
		)


-- Mark operators and quarters with a flag where deltas remain
UPDATE	c
SET		c.delta = 1

FROM	#calc c INNER JOIN
		#normalisation n ON (c.organisation_id = n.organisation_id AND c.date = n.date AND c.date_type = n.date_type)
		
WHERE	n.count > 1 AND
		n.delta <> 0

-- Normalise data in quarters with 2 or more splits, netting off the largest split
-- First get the old sum of estimated splits to calculate a weighting between them which we apply to the new (total - reported splits)
UPDATE	c1
SET		c1.sum_estimated_values = c2.sum

FROM	#calc c1 INNER JOIN
		(
			SELECT	organisation_id,
					date,
					date_type,
					SUM(value) sum
					
			FROM	#calc
			
			WHERE	attribute_id <> @attribute_id AND
					confidence_id <> 192 AND -- Exclude reported split data which is simply netted off, not weighted
					delta = 1
				
			GROUP BY organisation_id, date, date_type
		) c2 ON (c1.organisation_id = c2.organisation_id AND c1.date = c2.date AND c1.date_type = c2.date_type)

WHERE	c1.attribute_id <> @attribute_id AND
		c1.delta = 1

-- Set the sum of reported splits
UPDATE	c1
SET		c1.sum_reported_values = c2.sum

FROM	#calc c1 INNER JOIN
		(
			SELECT	organisation_id,
					date,
					date_type,
					SUM(value) sum
					
			FROM	#calc
			
			WHERE	attribute_id <> @attribute_id AND
					confidence_id = 192 AND -- Only reported splits
					delta = 1
				
			GROUP BY organisation_id, date, date_type
		) c2 ON (c1.organisation_id = c2.organisation_id AND c1.date = c2.date AND c1.date_type = c2.date_type)

WHERE	c1.attribute_id <> @attribute_id AND
		c1.delta = 1

UPDATE #calc SET sum_reported_values = 0 WHERE delta = 1 AND attribute_id <> @attribute_id AND sum_reported_values IS null

-- Set the value of the "total"
UPDATE	c1
SET		c1.total = c2.value

FROM	#calc c1 INNER JOIN
		#calc c2 ON (c1.organisation_id = c2.organisation_id AND c1.date = c2.date AND c1.date_type = c2.date_type)

WHERE	c1.attribute_id <> @attribute_id AND
		c1.delta = 1 AND
		c2.attribute_id = @attribute_id
		
UPDATE #calc SET weighting_value = value / sum_estimated_values WHERE delta = 1 AND attribute_id <> @attribute_id AND confidence_id <> 192 AND sum_estimated_values <> 0
UPDATE #calc SET new_value = ROUND((total - sum_reported_values) * weighting_value, 0) WHERE delta = 1 AND attribute_id <> @attribute_id AND confidence_id <> 192 AND weighting_value <> 0

-- Now that we have correctly weighted the splits against the new total, find any rounding net-off using the largest estimated split to absorb the difference
UPDATE	c1
SET		c1.sum_new_estimated_values = c2.sum

FROM	#calc c1 INNER JOIN
		(
			SELECT	organisation_id,
					date,
					date_type,
					SUM(new_value) sum
			
			FROM	(
						SELECT	organisation_id,
								date,
								date_type,
								new_value,
								RANK() OVER (PARTITION BY organisation_id, date, date_type ORDER BY new_value DESC, attribute_id) rank -- In the event of equal value ranks, we still need distinct ranks
			
						FROM	#calc
			
						WHERE	attribute_id <> @attribute_id AND
								confidence_id <> 192 AND
								delta = 1
					) c3
			
			WHERE	rank <> 1
			
			GROUP BY organisation_id, date, date_type
		) c2 ON (c1.organisation_id = c2.organisation_id AND c1.date = c2.date AND c1.date_type = c2.date_type)

WHERE	c1.attribute_id <> @attribute_id AND
		c1.delta = 1

UPDATE #calc SET sum_new_estimated_values = 0 WHERE delta = 1 AND attribute_id <> @attribute_id AND sum_new_estimated_values IS null

-- Finally, net sum_new_estimated_values and sum_reported_values from the total using the largest estimated split
UPDATE	c1
SET		c1.processed = 0

FROM	#calc c1 INNER JOIN
		(
			SELECT	organisation_id,
					date,
					date_type,
					attribute_id
			
			FROM	(
						SELECT	organisation_id,
								date,
								date_type,
								attribute_id,
								RANK() OVER (PARTITION BY organisation_id, date, date_type ORDER BY new_value DESC, attribute_id) rank -- In the event of equal value ranks, we still need distinct ranks
			
						FROM	#calc
			
						WHERE	attribute_id <> @attribute_id AND
								confidence_id <> 192 AND
								delta = 1
					) c3
			
			WHERE	rank = 1
		) c2 ON (c1.organisation_id = c2.organisation_id AND c1.attribute_id = c2.attribute_id AND c1.date = c2.date AND c1.date_type = c2.date_type)

WHERE	c1.attribute_id <> @attribute_id AND
		c1.delta = 1

UPDATE #calc SET new_value = total - sum_reported_values - sum_new_estimated_values WHERE delta = 1 AND attribute_id <> @attribute_id AND confidence_id <> 192 AND processed = 0
UPDATE #calc SET new_value = null WHERE new_value <= 0


-- Commit all new values to database
IF @debug = 0
BEGIN
	-- Remove any NULL data
	DELETE FROM #calc WHERE new_value IS null

	-- UPDATE the values that already exist
	DECLARE @last_update_on datetime = GETDATE()
	
	UPDATE	ds
	SET		ds.val_d = null,
			ds.val_i = CAST(c.new_value AS bigint),
			ds.source_id = c.source_id,
			ds.confidence_id = c.confidence_id,
			ds.last_update_on = @last_update_on,
			ds.last_update_by = 11770
	
	FROM	ds_organisation_data ds INNER JOIN
			#calc c ON ds.id = c.id
	
	WHERE	c.attribute_id <> @attribute_id AND		-- Don't include a conf <> 192 condition as we want to update single-split values too which inherit source/confidence from total
			(
				c.new_value <> c.value OR
				c.process = 1						-- Update source/confidence only
			)
END

IF @debug = 1
BEGIN
	--SELECT * FROM #normalisation ORDER BY organisation_id, date_type, date
	--SELECT * FROM #calc ORDER BY organisation_id, date_type, date, attribute_id
	
	--SELECT * FROM #normalisation WHERE delta <> 0 ORDER BY organisation_id, date, date_type
	--SELECT * FROM #calc WHERE delta = 1 ORDER BY organisation_id, date_type, date, attribute_id
	
	--SELECT * FROM #calc WHERE new_value < 0 ORDER BY organisation_id, date_type, date, attribute_id
	SELECT * FROM #calc WHERE organisation_id = 107
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_normalised_connections (7s)'

DROP TABLE #normalisation
DROP TABLE #calc
