
CREATE PROCEDURE [dbo].[calculate_moving_mean_from_zone_data]

(
	@metric_id int,				-- Output metric.id
	@attribute_id int,			-- Output attribute.id
	@metric_id_2 int,			-- Input metric.id, the dividend
	@attribute_id_2 int,		-- Input attribute.id
	@metric_id_3 int,			-- Input metric.id, the divisor
	@attribute_id_3 int,		-- Input attribute.id
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@date_period int = 4,		-- Corresponds in unit to the date_type when calculating the moving average
	@debug bit = 1
)

AS

DECLARE @is_decimal bit = dbo.metric_is_decimal(@metric_id)
DECLARE @is_decimal_2 bit = dbo.metric_is_decimal(@metric_id_2)
DECLARE @is_decimal_3 bit = dbo.metric_is_decimal(@metric_id_3)

DECLARE @is_currency_based bit = dbo.metric_is_currency_based(@metric_id)
DECLARE @is_currency_based_2 bit = dbo.metric_is_currency_based(@metric_id_2)
DECLARE @is_currency_based_3 bit = dbo.metric_is_currency_based(@metric_id_3)

-- Calculation table; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #data (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit, source_id int, confidence_id int, id_2 bigint, metric_id_2 int, attribute_id_2 int, value_2 decimal(22,8), currency_id_2 int, is_spot_2 bit, source_id_2 int, confidence_id_2 int, currency_rate decimal(22,8))
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit, source_id int, confidence_id int, is_calculated bit, processed bit)

-- Collect all country, regional figures for both input metrics
INSERT INTO #data
SELECT	DISTINCT
		null,
		ds.zone_id,
		@metric_id_2,
		@attribute_id_2,
		ds.date,
		ds.date_type,
		null,
		CASE @is_currency_based_2 WHEN 0 THEN null ELSE ds.currency_id END,
		CASE @is_currency_based_2 WHEN 0 THEN null ELSE ds.is_spot END,
		null,
		null,
		null,
		@metric_id_3,
		@attribute_id_3,
		null,
		CASE @is_currency_based_3 WHEN 0 THEN null ELSE ds.currency_id END,
		CASE @is_currency_based_3 WHEN 0 THEN null ELSE ds.is_spot END,
		null,
		null,
		null
		
FROM	ds_zone_data ds

WHERE	(
			(ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2) OR
			(ds.metric_id = @metric_id_3 AND ds.attribute_id = @attribute_id_3)
		) AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type = @date_type AND
		ds.status_id = 3
		
ORDER BY ds.zone_id, ds.date_type, ds.date

IF @is_currency_based_2 = 0
BEGIN
	UPDATE	d
	SET		d.id = ds.id, d.value = CASE @is_decimal_2 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id = ds.currency_id, d.is_spot = ds.is_spot, d.source_id = ds.source_id, d.confidence_id = ds.confidence_id
	FROM	ds_zone_data ds INNER JOIN #data d ON (ds.zone_id = d.zone_id AND ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id AND ds.date = d.date AND ds.date_type = d.date_type)
	WHERE	ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2
END
ELSE
BEGIN
	UPDATE	d
	SET		d.id = ds.id, d.value = CASE @is_decimal_2 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id = ds.currency_id, d.is_spot = ds.is_spot, d.source_id = ds.source_id, d.confidence_id = ds.confidence_id
	FROM	ds_zone_data ds INNER JOIN #data d ON (ds.zone_id = d.zone_id AND ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id AND ds.date = d.date AND ds.date_type = d.date_type AND ds.currency_id = d.currency_id AND ds.is_spot = d.is_spot)
	WHERE	ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2

	-- Also clean up the combination of currency_id = 0 with a null value WHEN @metric_id_2 is currency-based, but @metric_id 3 is not, creating an additional uneeded row
	DELETE FROM #data WHERE currency_id = 0 AND value IS null
END

IF @is_currency_based_3 = 0
BEGIN
	UPDATE	d
	SET		d.id_2 = ds.id, d.value_2 = CASE @is_decimal_3 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id_2 = ds.currency_id, d.is_spot_2 = ds.is_spot, d.source_id_2 = ds.source_id, d.confidence_id_2 = ds.confidence_id
	FROM	ds_zone_data ds INNER JOIN #data d ON (ds.zone_id = d.zone_id AND ds.metric_id = d.metric_id_2 AND ds.attribute_id = d.attribute_id_2 AND ds.date = d.date AND ds.date_type = d.date_type)
	WHERE	ds.metric_id = @metric_id_3 AND ds.attribute_id = @attribute_id_3
END
ELSE
BEGIN
	UPDATE	d
	SET		d.id_2 = ds.id, d.value_2 = CASE @is_decimal_3 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id_2 = ds.currency_id, d.is_spot_2 = ds.is_spot, d.source_id_2 = ds.source_id, d.confidence_id_2 = ds.confidence_id
	FROM	ds_zone_data ds INNER JOIN #data d ON (ds.zone_id = d.zone_id AND ds.metric_id = d.metric_id_2 AND ds.attribute_id = d.attribute_id_2 AND ds.date = d.date AND ds.date_type = d.date_type AND ds.currency_id = d.currency_id_2 AND ds.is_spot = d.is_spot_2)
	WHERE	ds.metric_id = @metric_id_3 AND ds.attribute_id = @attribute_id_3
END


-- Exchange rates have already been factored in aggregate data (using is_spot), so we can divide the data "as-reported"
UPDATE	#data SET currency_rate = 1 WHERE currency_rate IS null


-- Update missing values, source and confidence
UPDATE #data SET value_2 = 0 WHERE value_2 IS null
UPDATE #data SET currency_id_2 = currency_id WHERE currency_id_2 IS null
UPDATE #data SET source_id_2 = source_id WHERE source_id_2 IS null
UPDATE #data SET confidence_id_2 = confidence_id WHERE confidence_id_2 IS null


-- Calculate moving ratio based on values
IF @is_currency_based_2 = 0 AND @is_currency_based_3 = 0
BEGIN
	-- Neither @metric_id_2 or @metric_id_3 are currency_based and so we don't need to join the summed_value over currency_id or is_spot (the latter of which is null, and will return zero rows in a join)
	INSERT INTO #calc
	SELECT	null,
			d.zone_id,
			@metric_id,
			@attribute_id,
			d.date,
			d.date_type,
			CASE WHEN d3.summed_value IS null THEN null WHEN d3.summed_value = 0 THEN null ELSE d2.summed_value/d3.summed_value END,
			CASE @is_currency_based WHEN 1 THEN d.currency_id ELSE 0 END,
			CASE @is_currency_based WHEN 1 THEN d.is_spot ELSE null END,
			CASE WHEN d.source_id < d.source_id_2 THEN d.source_id ELSE d.source_id_2 END, -- MIN() only works over columns
			CASE WHEN d.confidence_id > d.confidence_id_2 THEN d.confidence_id ELSE d.confidence_id_2 END, -- MAX() only works over columns
			1,
			0

	FROM	#data d INNER JOIN
			(
				-- Moving sum 
				SELECT	d.zone_id, d.date, SUM(d2.value) summed_value
				FROM	#data d INNER JOIN #data d2 ON (d.zone_id = d2.zone_id AND d2.value <> 0 AND d2.date > DATEADD(quarter, CASE @date_type WHEN 'Q' THEN -@date_period WHEN 'H' THEN -@date_period * 2 WHEN 'Y' THEN -@date_period * 4 END, d.date) AND d2.date <= d.date)
				GROUP BY d.zone_id, d.date
				HAVING COUNT(d2.value) >= 4
			) d2 ON d.zone_id = d2.zone_id AND d.date = d2.date INNER JOIN
			(
				SELECT	d.zone_id, d.date, SUM(d2.value_2 * d2.currency_rate) summed_value
				FROM	#data d INNER JOIN #data d2 ON (d.zone_id = d2.zone_id AND d2.value_2 <> 0 AND d2.date > DATEADD(quarter, CASE @date_type WHEN 'Q' THEN -@date_period WHEN 'H' THEN -@date_period * 2 WHEN 'Y' THEN -@date_period * 4 END, d.date) AND d2.date <= d.date)
				GROUP BY d.zone_id, d.date
				HAVING COUNT(d2.value_2) >= 4
			) d3 ON d.zone_id = d3.zone_id AND d.date = d3.date

	ORDER BY d.zone_id, d.date
END
ELSE IF @is_currency_based_2 = 1 AND @is_currency_based_3 = 0
BEGIN
	-- Only @metric_id_2 is currency_based and so we don't need to join the summed_value for @metric_id_3 over currency_id_2 or is_spot_2...
	INSERT INTO #calc
	SELECT	null,
			d.zone_id,
			@metric_id,
			@attribute_id,
			d.date,
			d.date_type,
			CASE WHEN d3.summed_value IS null THEN null WHEN d3.summed_value = 0 THEN null ELSE d2.summed_value/d3.summed_value END,
			CASE @is_currency_based WHEN 1 THEN d.currency_id ELSE 0 END,
			CASE @is_currency_based WHEN 1 THEN d.is_spot ELSE null END,
			CASE WHEN d.source_id < d.source_id_2 THEN d.source_id ELSE d.source_id_2 END, -- MIN() only works over columns
			CASE WHEN d.confidence_id > d.confidence_id_2 THEN d.confidence_id ELSE d.confidence_id_2 END, -- MAX() only works over columns
			1,
			0

	FROM	#data d INNER JOIN
			(
				SELECT	d.zone_id, d.date, SUM(d2.value) summed_value, d.currency_id, d.is_spot
				FROM	#data d INNER JOIN #data d2 ON (d.zone_id = d2.zone_id AND d2.value <> 0 AND d2.date > DATEADD(quarter, CASE @date_type WHEN 'Q' THEN -@date_period WHEN 'H' THEN -@date_period * 2 WHEN 'Y' THEN -@date_period * 4 END, d.date) AND d2.date <= d.date AND d.currency_id = d2.currency_id AND d.is_spot = d2.is_spot)
				GROUP BY d.zone_id, d.date, d.currency_id, d.is_spot
				HAVING COUNT(d2.value) >= 4
			) d2 ON d.zone_id = d2.zone_id AND d.date = d2.date AND d.currency_id = d2.currency_id AND d.is_spot = d2.is_spot INNER JOIN
			(
				-- ...but we still want to group by/join on the currency_id and is_spot of @metric_id_*2*, otherwise we'd over-sum the non-currency-based metric by a factor of 8
				SELECT	d.zone_id, d.date, SUM(d2.value_2 * d2.currency_rate) summed_value, d.currency_id, d.is_spot
				FROM	#data d INNER JOIN #data d2 ON (d.zone_id = d2.zone_id AND d2.value_2 <> 0 AND d2.date > DATEADD(quarter, CASE @date_type WHEN 'Q' THEN -@date_period WHEN 'H' THEN -@date_period * 2 WHEN 'Y' THEN -@date_period * 4 END, d.date) AND d2.date <= d.date AND d.currency_id = d2.currency_id AND d.is_spot = d2.is_spot)
				GROUP BY d.zone_id, d.date, d.currency_id, d.is_spot
				HAVING COUNT(d2.value_2) >= 4
			) d3 ON d.zone_id = d3.zone_id AND d.date = d3.date AND d.currency_id = d3.currency_id AND d.is_spot = d3.is_spot

	ORDER BY d.zone_id, d.date
END
ELSE
BEGIN
	-- Otherwise, both @metric_id_2 and @metric_id_3 are currency based, and a full join over both currency_ids and is_spots should be made
	INSERT INTO #calc
	SELECT	null,
			d.zone_id,
			@metric_id,
			@attribute_id,
			d.date,
			d.date_type,
			CASE WHEN d3.summed_value IS null THEN null WHEN d3.summed_value = 0 THEN null ELSE d2.summed_value/d3.summed_value END,
			CASE @is_currency_based WHEN 1 THEN d.currency_id ELSE 0 END,
			CASE @is_currency_based WHEN 1 THEN d.is_spot ELSE null END,
			CASE WHEN d.source_id < d.source_id_2 THEN d.source_id ELSE d.source_id_2 END, -- MIN() only works over columns
			CASE WHEN d.confidence_id > d.confidence_id_2 THEN d.confidence_id ELSE d.confidence_id_2 END, -- MAX() only works over columns
			1,
			0

	FROM	#data d INNER JOIN
			(
				SELECT	d.zone_id, d.date, SUM(d2.value) summed_value, d.currency_id, d.is_spot
				FROM	#data d INNER JOIN #data d2 ON (d.zone_id = d2.zone_id AND d2.value <> 0 AND d2.date > DATEADD(quarter, CASE @date_type WHEN 'Q' THEN -@date_period WHEN 'H' THEN -@date_period * 2 WHEN 'Y' THEN -@date_period * 4 END, d.date) AND d2.date <= d.date AND d.currency_id = d2.currency_id AND d.is_spot = d2.is_spot)
				GROUP BY d.zone_id, d.date, d.currency_id, d.is_spot
				HAVING COUNT(d2.value) >= 4
			) d2 ON d.zone_id = d2.zone_id AND d.date = d2.date AND d.currency_id = d2.currency_id AND d.is_spot = d2.is_spot INNER JOIN
			(
				SELECT	d.zone_id, d.date, SUM(d2.value_2 * d2.currency_rate) summed_value, d.currency_id_2, d.is_spot_2
				FROM	#data d INNER JOIN #data d2 ON (d.zone_id = d2.zone_id AND d2.value_2 <> 0 AND d2.date > DATEADD(quarter, CASE @date_type WHEN 'Q' THEN -@date_period WHEN 'H' THEN -@date_period * 2 WHEN 'Y' THEN -@date_period * 4 END, d.date) AND d2.date <= d.date AND d.currency_id = d2.currency_id AND d.is_spot = d2.is_spot)
				GROUP BY d.zone_id, d.date, d.currency_id_2, d.is_spot_2
				HAVING COUNT(d2.value_2) >= 4
			) d3 ON d.zone_id = d3.zone_id AND d.date = d3.date AND d.currency_id = d3.currency_id_2 AND d.is_spot = d3.is_spot_2

	ORDER BY d.zone_id, d.date
END

-- Update with corresponding existing data point ids
IF @is_currency_based = 0
BEGIN
	UPDATE	c
	SET		c.id = ds.id, c.is_calculated = ds.is_calculated
	FROM	ds_zone_data ds INNER JOIN #calc c ON (ds.zone_id = c.zone_id AND ds.metric_id = c.metric_id AND ds.attribute_id = c.attribute_id AND ds.date = c.date AND ds.date_type = c.date_type)
	WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id
END
ELSE
BEGIN
	UPDATE	c
	SET		c.id = ds.id, c.is_calculated = ds.is_calculated
	FROM	ds_zone_data ds INNER JOIN #calc c ON (ds.zone_id = c.zone_id AND ds.metric_id = c.metric_id AND ds.attribute_id = c.attribute_id AND ds.date = c.date AND ds.date_type = c.date_type AND ds.currency_id = c.currency_id AND ds.is_spot = c.is_spot)
	WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id
END

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the _calculated_ values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.currency_id = c.currency_id, ds.is_calculated = c.is_calculated, ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.last_update_on = CASE WHEN CAST(ds.val_i AS decimal(22,8)) = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN CAST(ds.val_i AS decimal(22,8)) = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1 AND c.value IS NOT null

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, is_spot, source_id, confidence_id, is_calculated, created_by)
	SELECT	c.zone_id, c.metric_id, c.attribute_id, c.date, c.date_type, CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, c.currency_id, c.is_spot, c.source_id, c.confidence_id, 1, 11770
	FROM	#calc c
	WHERE	c.id IS null AND c.value IS NOT null
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY zone_id, date, currency_id, is_spot
END


-- TODO: add benchmark by passing a start time t5o an audit function
SELECT 'Finished: calculate_moving_mean_from_zone_data (17s)'

DROP TABLE #data
DROP TABLE #calc
