
CREATE PROCEDURE [dbo].[data_markets_data]

(
	@zone_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@currency_id int = 1,
	@spot_historic bit = 1,
	@spot_quarter datetime = null,
	@include_countries bit = 0,
	@include_operators bit = 0
)

AS

DECLARE @zone_type_id int

IF @spot_quarter IS NULL
BEGIN
	SET @spot_quarter = dbo.current_reporting_quarter()
END

SET @zone_type_id = (SELECT type_id FROM zones WHERE id = @zone_id)

CREATE TABLE #data (id bigint, entity_id int, is_aggregate bit, metric_id int, metric_order int, attribute_id int, attribute_order int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, value decimal(22,4), currency_id int, currency_original_id int, source_id int, confidence_id int, definition_id int, has_flags bit, flags nvarchar(max) COLLATE DATABASE_DEFAULT, location nvarchar(max) COLLATE DATABASE_DEFAULT)

-- Zone data
INSERT INTO #data
SELECT	dc.id,
		dc.zone_id,
		1,
		dc.metric_id,
		dc.metric_order,
		dc.attribute_id,
		dc.attribute_order,
		dc.date datetime,
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
		dm.location
		
FROM	dc_zone_data dc INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) INNER JOIN
		data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)
	LEFT JOIN zone_data_metadata as dm ON dc.id = dm.fk_zone_data_id


WHERE	dc.zone_id = @zone_id AND
		dc.date >= @date_start AND
		dc.date < @date_end AND
		dc.date_type = @date_type AND
		s.attribute_id IS NOT null AND 
		s.show_in_metrics_only = 0 AND
		(
			(
				-- When the market-level value is reported, currency conversions are generated in-query
				dc.is_calculated = 0 AND
				(
					(@spot_historic = 0 AND cr.date = dc.date) OR
					(@spot_historic = 1 AND cr.date = @spot_quarter)
				)
			)
			OR
			(
				-- When the market-level value is aggregated from operator data, currency conversions are pre-calculated
				dc.is_calculated = 1 AND
				dc.currency_id IN (0, @currency_id) AND
				(
					((@spot_historic = 0 OR dc.currency_id = 0) AND cr.date = dc.date AND (dc.is_spot = 0 OR dc.is_spot IS null)) OR 		-- Either null for non-currency data or 0/1 for historic/spot calculation
					((@spot_historic = 1 AND dc.currency_id <> 0) AND cr.date = @spot_quarter AND (dc.is_spot = 1 OR dc.is_spot IS null))	-- Still joined on currency_rates, so need a cr.date clause to ensure 1:1 rows returned
				)
			)
		)
		
ORDER BY dc.metric_order, dc.attribute_order, dc.date


IF @zone_type_id = 39 AND @include_countries = 1
BEGIN
	-- Country data for a region
	INSERT INTO #data
	SELECT	dc.id,
			dc.zone_id,
			0,
			dc.metric_id,
			dc.metric_order,
			dc.attribute_id,
			dc.attribute_order,
			dc.date datetime,
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
			
	FROM	dc_zone_data dc INNER JOIN
			zones z ON dc.zone_id = z.id INNER JOIN
			currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) INNER JOIN
			data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)

	WHERE	dc.zone_id IN (SELECT subzone_id FROM zone_link WHERE zone_id = @zone_id) AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			s.attribute_id IS NOT null AND 
			s.show_in_metrics_only = 0 AND
			(
				(
					-- When the market-level value is reported, currency conversions are generated in-query
					dc.is_calculated = 0 AND
					(
						(@spot_historic = 0 AND cr.date = dc.date) OR
						(@spot_historic = 1 AND cr.date = @spot_quarter)
					)
				)
				OR
				(
					-- When the market-level value is aggregated from operator data, currency conversions are pre-calculated
					dc.is_calculated = 1 AND
					dc.currency_id IN (0, @currency_id) AND
					(
						((@spot_historic = 0 OR dc.currency_id = 0) AND cr.date = dc.date AND (dc.is_spot = 0 OR dc.is_spot IS null)) OR 		-- Either null for non-currency data or 0/1 for historic/spot calculation
						((@spot_historic = 1 AND dc.currency_id <> 0) AND cr.date = @spot_quarter AND (dc.is_spot = 1 OR dc.is_spot IS null))	-- Still joined on currency_rates, so need a cr.date clause to ensure 1:1 rows returned
					)
				)
			)
			
	ORDER BY dc.metric_order, dc.attribute_order, z.name, dc.date
END


IF @zone_type_id = 39 AND @include_operators = 1
BEGIN
	-- Organisation data for a region
	INSERT INTO #data
	SELECT	dc.id,
			dc.organisation_id,
			0,
			dc.metric_id,
			dc.metric_order,
			dc.attribute_id,
			dc.attribute_order,
			dc.date datetime,
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
			dc.location
			
	FROM	dc_organisation_data dc INNER JOIN
			organisations o ON dc.organisation_id = o.id INNER JOIN
			organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
			zones z ON oz.zone_id = z.id INNER JOIN
			zone_link zl ON z.id = zl.subzone_id INNER JOIN
			currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) INNER JOIN
			data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)

	WHERE	zl.zone_id = @zone_id AND
			o.type_id = 1089 AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			s.attribute_id IS NOT null AND 
			s.show_in_metrics_only = 0 AND
			(
				(@spot_historic = 0 AND cr.date = dc.date) OR
				(@spot_historic = 1 AND cr.date = @spot_quarter)
			)
			
	ORDER BY dc.metric_order, dc.attribute_order, o.name, dc.date
END


IF @zone_type_id = 10
BEGIN
	-- Organisation data for a country
	INSERT INTO #data
	SELECT	dc.id,
			dc.organisation_id,
			0,
			dc.metric_id,
			dc.metric_order,
			dc.attribute_id,
			dc.attribute_order,
			dc.date datetime,
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
			dc.location
			
	FROM	dc_organisation_data dc INNER JOIN
			organisations o ON dc.organisation_id = o.id INNER JOIN
			organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
			zones z ON oz.zone_id = z.id INNER JOIN
			currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) INNER JOIN
			data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)

	WHERE	z.id = @zone_id AND
			o.type_id = 1089 AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			s.attribute_id IS NOT null AND 
			s.show_in_metrics_only = 0 AND
			(
				(@spot_historic = 0 AND cr.date = dc.date) OR
				(@spot_historic = 1 AND cr.date = @spot_quarter)
			)
			
	ORDER BY dc.metric_order, dc.attribute_order, o.name, dc.date
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
