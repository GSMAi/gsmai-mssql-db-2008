
CREATE PROCEDURE [dbo].[data_metrics_data]

(
	@show tinyint,
	@zone_id int,
	@metric_id int,
	@attribute_id int,
	@type_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@currency_id int = 1,
	@spot_historic bit = 1,
	@spot_quarter datetime = null
)

AS

DECLARE @total_attribute_id int = 0

IF @spot_quarter IS null
BEGIN
	SET @spot_quarter = dbo.current_reporting_quarter()
END

IF @type_id IS NOT null
BEGIN
	-- Use the correct "Total" attribute for n>2 nesting of attributes
	SET @total_attribute_id = CASE @type_id WHEN 7 THEN 1629 WHEN 22 THEN 1251 WHEN 23 THEN 1251 WHEN 1576 THEN 1581 ELSE 0 END
END

CREATE TABLE #zones (id int, parent_id int, [order] int)
CREATE TABLE #organisations (id int)

CREATE TABLE #data (id bigint, entity_id int, entity nvarchar(512) COLLATE DATABASE_DEFAULT, country_id int, country nvarchar(512) COLLATE DATABASE_DEFAULT, parent_id int, [order] int, is_aggregate tinyint, metric_id int, metric_order int, attribute_id int, attribute_order int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, value decimal(22,4), currency_id int, currency_original_id int, source_id int, confidence_id int, definition_id int, has_flags bit, flags nvarchar(max) COLLATE DATABASE_DEFAULT, location nvarchar(max) COLLATE DATABASE_DEFAULT)

-- Global, regions, subregions
IF @show = 1
BEGIN
	-- Defaults
	INSERT INTO #zones
	SELECT	3826, 3826, 0 UNION ALL		-- Global
	SELECT	3899, 3938, 2 UNION ALL		-- Developed (TODO: add to zone_link against each geoscheme)
	SELECT	3900, 3938, 2				-- Developing

	IF @zone_id = 3936					-- UN Geoscheme
	BEGIN
		INSERT INTO #zones
		SELECT	3821, 3939, 3 UNION ALL	-- Custom: Asia Pacific
		SELECT	3902, 3939, 3 UNION ALL	-- Custom: European Union
		SELECT	3820, 3939, 3 UNION ALL	-- Custom: Latin America
		SELECT	3982, 3939, 3 UNION ALL -- Custom: Least Developed Countries
		SELECT	3824, 3939, 3 UNION ALL	-- Custom: Middle East
		SELECT	3896, 3939, 3			-- Custom: SSA
	END

	IF @zone_id = 3954					-- GSMA Geoscheme
	BEGIN
		INSERT INTO #zones
		SELECT	3961, 3963, 3 UNION ALL	-- Custom: Arab States
		SELECT	3902, 3963, 3 UNION ALL	-- Custom: European Union
		SELECT	3982, 3963, 3 UNION ALL -- Custom: Least Developed Countries
		SELECT	3824, 3963, 3 UNION ALL	-- Custom: Middle East
		SELECT	3964, 3963, 3			-- Custom: Pacific Islands
	END

	INSERT INTO #zones
	SELECT	DISTINCT zl.subzone_id, zl.subzone_id, 1 FROM zone_link zl WHERE zl.zone_id = @zone_id UNION ALL
	SELECT	DISTINCT zl2.subzone_id, zl2.zone_id, 1 FROM zone_link zl INNER JOIN zone_link zl2 ON zl.subzone_id = zl2.zone_id WHERE zl.zone_id = @zone_id

	INSERT INTO #data
	SELECT	dc.id,
			z.id,
			z.name,
			null,
			null,
			z2.parent_id,
			z2.[order],
			--CASE z.type_id WHEN 3 THEN 2 WHEN 42 THEN 1 ELSE CASE z.id WHEN 3899 THEN 1 WHEN 3900 THEN 1 WHEN 3821 THEN 1 WHEN 3902 THEN 1 WHEN 3820 THEN 1 WHEN 3824 THEN 1 WHEN 3896 THEN 1 ELSE 0 END END is_aggregate,
			CASE z.type_id WHEN 3 THEN 2 WHEN 42 THEN 1 WHEN 39 THEN (CASE WHEN @zone_id = 3936 AND z2.[order] = 1 THEN 0 ELSE 1 END) ELSE 0 END is_aggregate,
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
			zones z ON dc.zone_id = z.id INNER JOIN
			#zones z2 ON z.id = z2.id LEFT JOIN -- TODO: remove the direct relationship between countries and the global zone
			attributes a ON dc.attribute_id = a.id
	LEFT JOIN zone_data_metadata as dm ON dc.id = dm.fk_zone_data_id


	WHERE	z.id IN (SELECT id FROM #zones) AND
			dc.metric_id = @metric_id AND
			dc.attribute_id = COALESCE(@attribute_id, dc.attribute_id) AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			(
				(@type_id IS null AND (a.type_id IS null OR a.type_id = a.type_id)) OR
				(@type_id IS NOT null AND (a.id = @total_attribute_id OR a.type_id = @type_id)) -- Show total with type_id segments
			)
			AND
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
			
	ORDER BY parent_id, z.name, CASE dc.date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END, dc.date, dc.attribute_order
END


-- Region, countries
IF @show = 2
BEGIN
	INSERT INTO #zones
	SELECT	@zone_id, null, 0 UNION ALL
	SELECT	DISTINCT z.id, null, 1 FROM zone_link zl INNER JOIN zones z ON zl.subzone_id = z.id WHERE zl.zone_id = @zone_id AND z.type_id = 10 UNION ALL
	SELECT	DISTINCT z.id, null, 1 FROM zone_link zl INNER JOIN zone_link zl2 ON zl.subzone_id = zl2.zone_id INNER JOIN zones z ON zl2.subzone_id = z.id WHERE zl.zone_id = @zone_id AND z.type_id = 10

	INSERT INTO #data
	SELECT	dc.id,
			z.id,
			z.name,
			null,
			null,
			@zone_id,
			null,
			CASE z.type_id WHEN 10 THEN 0 ELSE 1 END is_aggregate,
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
			zones z ON dc.zone_id = z.id INNER JOIN
			currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) LEFT JOIN
			attributes a ON dc.attribute_id = a.id
	LEFT JOIN zone_data_metadata as dm ON dc.id = dm.fk_zone_data_id


	WHERE	z.id IN (SELECT id FROM #zones) AND
			dc.metric_id = @metric_id AND
			dc.attribute_id = COALESCE(@attribute_id, dc.attribute_id) AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			(
				(@type_id IS null AND (a.type_id IS null OR a.type_id = a.type_id)) OR
				(@type_id IS NOT null AND (a.id = @total_attribute_id OR a.type_id = @type_id)) -- Show total with type_id segments
			)
			AND
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
			
	ORDER BY is_aggregate DESC, z.name, CASE dc.date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END, dc.date, dc.attribute_order
END


-- Country, operators
IF @show = 3
BEGIN
	INSERT INTO #zones
	SELECT	@zone_id, null, 0 UNION ALL
	SELECT	DISTINCT z.id, null, 1 FROM zone_link zl INNER JOIN zones z ON zl.subzone_id = z.id WHERE zl.zone_id = @zone_id AND z.type_id = 10 UNION ALL
	SELECT	DISTINCT z.id, null, 1 FROM zone_link zl INNER JOIN zone_link zl2 ON zl.subzone_id = zl2.zone_id INNER JOIN zones z ON zl2.subzone_id = z.id WHERE zl.zone_id = @zone_id AND z.type_id = 10

	INSERT INTO #organisations
	SELECT	DISTINCT oz.organisation_id FROM organisation_zone_link oz WHERE oz.zone_id = @zone_id UNION ALL
	SELECT	DISTINCT oz.organisation_id FROM zone_link zl INNER JOIN organisation_zone_link oz ON zl.subzone_id = oz.zone_id WHERE zl.zone_id = @zone_id UNION ALL
	SELECT	DISTINCT oz.organisation_id FROM zone_link zl INNER JOIN zone_link zl2 ON zl.subzone_id = zl2.zone_id INNER JOIN organisation_zone_link oz ON zl2.subzone_id = oz.zone_id WHERE zl.zone_id = @zone_id

	INSERT INTO #data
	SELECT	dc.id,
			z.id,
			z.name,
			CASE z.type_id WHEN 10 THEN z.id ELSE null END,
			CASE z.type_id WHEN 10 THEN z.name ELSE null END,
			@zone_id,
			null,
			CASE z.type_id WHEN 10 THEN 1 ELSE 2 END,
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
			zones z ON dc.zone_id = z.id INNER JOIN
			currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id) LEFT JOIN
			attributes a ON dc.attribute_id = a.id
	LEFT JOIN zone_data_metadata as dm ON dc.id = dm.fk_zone_data_id


	WHERE	z.id IN (SELECT id FROM #zones) AND
			dc.metric_id = @metric_id AND
			dc.attribute_id = COALESCE(@attribute_id, dc.attribute_id) AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			(
				(@type_id IS null AND (a.type_id IS null OR a.type_id = a.type_id)) OR
				(@type_id IS NOT null AND (a.id = @total_attribute_id OR a.type_id = @type_id)) -- Show total with type_id segments
			)
			AND
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
			
	ORDER BY z.name, CASE dc.date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END, dc.date, dc.attribute_order

	INSERT INTO #data
	SELECT	dc.id,
			o.id,
			o.name,
			z.id,
			z.name,
			z.id,
			null,
			0,
			dc.metric_id,
			dc.metric_order,
			dc.attribute_id,
			dc.attribute_order,
			dc.date datetime,
			dc.date_type,
			dc.val_d,
			dc.val_i,
			CASE WHEN dc.val_i IS NULL THEN dc.val_d * (CASE @currency_id WHEN 0 THEN 1 ELSE cr.value END) ELSE CAST(dc.val_i * (CASE @currency_id WHEN 0 THEN 1 ELSE cr.value END) AS decimal(22,4)) END value,
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
			organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
			zones z ON oz.zone_id = z.id INNER JOIN
			currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = CASE @currency_id WHEN 0 THEN 1 ELSE @currency_id END) LEFT JOIN
			attributes a ON dc.attribute_id = a.id
	LEFT JOIN organisation_data_metadata as dm ON dc.id = dm.fk_organisation_data_id


	WHERE	o.id IN (SELECT id FROM #organisations) AND
			o.type_id = 1089 AND
			dc.metric_id = @metric_id AND
			dc.attribute_id = COALESCE(@attribute_id, dc.attribute_id) AND
			dc.date >= @date_start AND
			dc.date < @date_end AND
			dc.date_type = @date_type AND
			(
				(@type_id IS null AND (a.type_id IS null OR a.type_id = a.type_id)) OR
				(@type_id IS NOT null AND (a.id = @total_attribute_id OR a.type_id = @type_id)) -- Show total with type_id segments
			)
			AND
			(
				(@spot_historic = 0 AND cr.date = dc.date) OR
				(@spot_historic = 1 AND cr.date = @spot_quarter)
			)
			
	ORDER BY z.name, o.name, CASE dc.date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END, dc.date, dc.attribute_order
END


-- Remove data that should only show in single metric/attribute views
IF @attribute_id IS null
BEGIN
	-- Can show data for a single type_id where all attributes of that type are hidden
	DECLARE @show_data bit
	SET @show_data = CASE WHEN (SELECT COUNT(*) FROM data_sets WHERE metric_id = @metric_id AND type_id = @type_id AND is_live = 1 AND show_in_metrics_only = 0) > 0 THEN 0 ELSE 1 END

	IF @show_data = 0
	BEGIN
		DELETE	ds
		FROM	#data ds INNER JOIN data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id)
		WHERE	s.show_in_metrics_only = 1
	END
END


-- Data
SELECT * FROM #data ORDER BY [order], CASE @show WHEN 1 THEN parent_id END, country, is_aggregate DESC, entity

-- Date combinations
SELECT	DISTINCT
		date,
		date_type,
		CASE date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END date_type_order

FROM	#data

ORDER BY date, date_type_order


DROP TABLE #data
DROP TABLE #zones
