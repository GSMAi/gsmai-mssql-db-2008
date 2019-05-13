
CREATE PROCEDURE [dbo].[data_groups_data]

(
	@organisation_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@ownership_threshold decimal(6,4) = 0.0,
	@is_proportionate bit = 0,
	@currency_id int = 1,
	@spot_historic bit = 1,
	@spot_quarter datetime = null
)

AS

DECLARE @current_quarter datetime
SET @current_quarter = dbo.current_reporting_quarter()

IF @spot_quarter IS NULL
BEGIN
	SET @spot_quarter = dbo.current_reporting_quarter()
END


CREATE TABLE #data (id bigint, entity_id int, is_aggregate bit, metric_id int, metric_order int, attribute_id int, attribute_order int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, value decimal(22,4), currency_id int, currency_original_id int, source_id int, confidence_id int, definition_id int, has_flags bit, flags nvarchar(max) COLLATE DATABASE_DEFAULT, location nvarchar(max) COLLATE DATABASE_DEFAULT)

-- Group data
INSERT INTO #data
SELECT	dc.id,
		dc.organisation_id,
		1,
		dc.metric_id,
		dc.metric_order,
		dc.attribute_id,
		dc.attribute_order,
		dc.date,
		dc.date_type,
		dc.val_d,
		dc.val_i,
		CASE dc.is_calculated WHEN 0 THEN (CASE WHEN dc.val_i IS NULL THEN dc.val_d * cr.value ELSE CAST(dc.val_i * cr.value AS decimal(22,4)) END) ELSE (CASE WHEN dc.val_i IS null THEN dc.val_d ELSE CAST(dc.val_i AS decimal(22,4)) END) END value,
		CASE dc.currency_id WHEN 0 THEN 0 ELSE @currency_id END currency_id,
		dc.currency_id currency_original_id,
		dc.source_id,
		dc.confidence_id, 
		dc.definition_id,
		dc.has_flags,
		dc.flags,
		dc.location
		
FROM	dc_group_data dc INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) INNER JOIN
		data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)

WHERE	dc.organisation_id = @organisation_id AND
		dc.is_proportionate = @is_proportionate AND
		dc.date >= @date_start AND
		dc.date < @date_end AND
		dc.date_type = @date_type AND
		dc.ownership_threshold = @ownership_threshold AND
		s.attribute_id IS NOT null AND 
		s.show_in_metrics_only = 0 AND
		(
			(
				-- When the group-level value is reported, currency conversions are generated in-query
				dc.is_calculated = 0 AND
				(
					(@spot_historic = 0 AND cr.date = dc.date) OR
					(@spot_historic = 1 AND cr.date = @spot_quarter)
				)
			)
			OR
			(
				-- When the group-level value is aggregated from operator data, currency conversions are pre-calculated
				dc.is_calculated = 1 AND
				dc.currency_id IN (0, @currency_id) AND
				(
					((@spot_historic = 0 OR dc.currency_id = 0) AND cr.date = dc.date AND (dc.is_spot = 0 OR dc.is_spot IS null)) OR 		-- Either null for non-currency data or 0/1 for historic/spot calculation
					((@spot_historic = 1 AND dc.currency_id <> 0) AND cr.date = @spot_quarter AND (dc.is_spot = 1 OR dc.is_spot IS null))	-- Still joined on currency_rates, so need a cr.date clause to ensure 1:1 rows returned
				)
			)
		)
		
ORDER BY dc.metric_order, dc.attribute_order, dc.date


-- Operator data
INSERT INTO #data
SELECT	dc.id,
		dc.organisation_id,
		0,
		dc.metric_id,
		dc.metric_order,
		dc.attribute_id,
		dc.attribute_order,
		dc.date,
		dc.date_type,
		dc.val_d,
		dc.val_i,
		CASE WHEN dc.val_i IS NULL THEN dc.val_d * cr.value ELSE CAST(dc.val_i * cr.value AS decimal(22,4)) END value,
		CASE WHEN dc.currency_id = 0 THEN 0 WHEN @currency_id = 0 THEN dc.currency_id ELSE @currency_id END currency_id,
		dc.currency_id currency_original_id,
		dc.source_id,
		dc.confidence_id,
		dc.definition_id,
		dc.has_flags,
		dc.flags,
		dm.location
		
FROM	dc_organisation_data dc INNER JOIN
		organisations o ON dc.organisation_id = o.id INNER JOIN
		ds_group_ownership ds ON (dc.organisation_id = ds.organisation_id AND dc.date = ds.date AND dc.date_type = ds.date_type) INNER JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
		zones z ON oz.zone_id = z.id INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) INNER JOIN
		data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)
	LEFT JOIN organisation_data_metadata as dm ON dc.id = dm.fk_organisation_data_id

WHERE	ds.group_id = @organisation_id AND
		o.type_id = 1089 AND
		dc.date >= @date_start AND
		dc.date < @date_end AND
		dc.date_type = @date_type AND
		s.attribute_id IS NOT null AND 
		s.show_in_metrics_only = 0 AND
		(
			(@ownership_threshold = 0.51 AND (ds.value > 0.5 OR ds.is_consolidated = 1)) OR
			(@ownership_threshold <> 0.51 AND ds.value >= @ownership_threshold)
		) AND
		(
			(@spot_historic = 0 AND cr.date = dc.date) OR
			(@spot_historic = 1 AND cr.date = @spot_quarter)
		)
		
ORDER BY dc.metric_order, dc.attribute_order, o.name, z.name, dc.date


-- Ownership data
INSERT INTO #data
SELECT	ds.id,
		ds.organisation_id,
		0,
		m.id,
		m.[order],
		a.id,
		a.[order],
		ds.date,
		ds.date_type,
		ds.value,
		null,
		ds.value,
		0,
		0,
		ds.source_id,
		ds.confidence_id,
		ds.definition_id,
		0,
		null,
		null

FROM	ds_group_ownership ds INNER JOIN
		metrics m ON ds.metric_id = m.id INNER JOIN
		attributes a ON ds.attribute_id = a.id LEFT JOIN
		organisations o ON ds.organisation_id = o.id LEFT JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id LEFT JOIN
		zones c ON oz.zone_id = c.id

WHERE	ds.group_id = @organisation_id AND
		ds.metric_id = 72 AND
		ds.attribute_id = 0 AND
		ds.date >= @date_start AND
		ds.date < CASE WHEN @date_end < @current_quarter THEN @date_end ELSE DATEADD(month, 3, @current_quarter) END AND -- Don't show 'forecast' ownership!
		ds.date_type = @date_type AND
		ds.is_group = 0 AND
		(
			(@ownership_threshold = 0.51 AND (ds.value > 0.5 OR ds.is_consolidated = 1)) OR
			(@ownership_threshold <> 0.51 AND ds.value >= @ownership_threshold)
		)

ORDER BY o.name, c.name, ds.date


-- Proportional adjustments
IF @is_proportionate = 1
BEGIN
	-- Update operator metrics to make them proportional (except where metrics are already per-connection averages, shares or margins)
	UPDATE 	d
	SET		d.value = d.value * ds.value
	FROM	#data d INNER JOIN ds_group_ownership ds ON (d.entity_id = ds.organisation_id AND d.date = ds.date AND d.date_type = ds.date_type AND ds.group_id = @organisation_id)
	WHERE	d.metric_id NOT IN (10,19,27,30,32,37,40,52,57,67,70,72,85,116,125,162,167) AND d.is_aggregate = 0

	-- Delete meaningless metrics: market share, market penetration
	DELETE FROM #data WHERE metric_id IN (41,44) AND is_aggregate = 0

	-- Delete incorrect metrics: net additions, gross additions, disconnections, ported_connections, sequential and annual growth, % connections
	DELETE FROM #data WHERE metric_id IN (9, 36,42,53,56,59,60,61) AND is_aggregate = 0
END


-- Data
SELECT * FROM #data ORDER BY metric_order, attribute_order, is_aggregate DESC, date, date_type

-- Metric, attribute combinations
SELECT	DISTINCT 
		metric_id,
		metric_order,
		attribute_id,
		attribute_order
		
FROM	#data

GROUP BY metric_id, metric_order, attribute_id, attribute_order
ORDER BY metric_order, attribute_order

-- Date combinations
SELECT	DISTINCT 
		date, 
		date_type,
		CASE date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END date_type_order

FROM	#data

ORDER BY date, date_type_order


DROP TABLE #data
