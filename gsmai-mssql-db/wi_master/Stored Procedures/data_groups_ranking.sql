
CREATE PROCEDURE [dbo].[data_groups_ranking]

(
	@geoscheme_id int = null,
	@region_id int = null, 		-- Note geography will only filter
	@subregion_id int = null,	-- organisations, not group aggregates
	@metric_id int,
	@attribute_id int,
	@date datetime = null,
	@date_type char(1) = 'Q',
	@ownership_threshold decimal(6,4) = 0.0,
	@is_proportionate bit = 1,
	@currency_id int = 0,
	@spot_historic bit = 0,
	@spot_quarter datetime = null
)

AS

IF @date IS NULL
BEGIN
	SET @date = dbo.current_reporting_quarter()
END

IF @spot_quarter IS NULL
BEGIN
	SET @spot_quarter = dbo.current_reporting_quarter()
END

CREATE TABLE #data (id bigint, organisation_id int, organisation nvarchar(512) COLLATE DATABASE_DEFAULT, organisation_type_id int, country_id int, country nvarchar(512) COLLATE DATABASE_DEFAULT, subregion_id int, subregion nvarchar(512) COLLATE DATABASE_DEFAULT, region_id int, region nvarchar(512) COLLATE DATABASE_DEFAULT, metric_id int, metric_order int, attribute_id int, attribute_order int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, value decimal(22,4), currency_id int, currency_original_id int, source_id int, confidence_id int, definition_id int, has_flags bit, flags nvarchar(max) COLLATE DATABASE_DEFAULT, location nvarchar(max) COLLATE DATABASE_DEFAULT)

-- Group data
INSERT INTO #data
SELECT	dc.id,
		o.id,
		o.name,
		o.type_id,
		null,
		null,
		null,
		null,
		null,
		null,
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
		organisations o ON dc.organisation_id = o.id INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id)

WHERE	dc.ownership_threshold = @ownership_threshold AND
		dc.is_proportionate = @is_proportionate AND
		dc.metric_id = @metric_id AND
		dc.attribute_id = @attribute_id AND
		dc.date = @date AND
		dc.date_type = @date_type AND
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
				dc.currency_id = @currency_id AND
				(
					((@spot_historic = 0 OR dc.currency_id = 0) AND cr.date = dc.date AND (dc.is_spot = 0 OR dc.is_spot IS null)) OR 		-- Either null for non-currency data or 0/1 for historic/spot calculation
					((@spot_historic = 1 AND dc.currency_id <> 0) AND cr.date = @spot_quarter AND (dc.is_spot = 1 OR dc.is_spot IS null))	-- Still joined on currency_rates, so need a cr.date clause to ensure 1:1 rows returned
				)
			)
		)
		
ORDER BY value DESC


-- Operator data (where not included in a group)
INSERT INTO #data
SELECT	dc.id,
		o.id,
		o.name,
		o.type_id,
		c.id,
		c.name,
		s.id,
		s.name,
		r.id,
		r.name,
		dc.metric_id,
		dc.metric_order,
		dc.attribute_id,
		dc.attribute_order,
		dc.date,
		dc.date_type,
		dc.val_d,
		dc.val_i,
		CASE WHEN dc.val_i IS NULL THEN dc.val_d * cr.value ELSE CAST(dc.val_i * cr.value AS decimal(22,4)) END value,
		CASE WHEN dc.currency_id = 0 THEN 0 ELSE @currency_id END currency_id,
		dc.currency_id,
		dc.source_id,
		dc.confidence_id,
		dc.definition_id,
		dc.has_flags,
		dc.flags,
		dm.location

FROM	dc_organisation_data dc INNER JOIN
		organisations o ON dc.organisation_id = o.id INNER JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
		zones c ON oz.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id INNER JOIN 
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id)
	LEFT JOIN organisation_data_metadata as dm ON dc.id = dm.fk_organisation_data_id


WHERE	o.id NOT IN -- Get all the operators that haven't been captured as part of a group
		(
			SELECT	ds.organisation_id
			
			FROM 	ds_group_ownership ds

			WHERE 	ds.date = @date AND
					ds.date_type = @date_type AND
					(
						(@ownership_threshold = 0.51 AND (ds.value > 0.5 OR ds.is_consolidated = 1)) OR
						(@ownership_threshold <> 0.51 AND ds.value >= @ownership_threshold)
					)
		) AND
		g.id = @geoscheme_id AND
		r.id = COALESCE(@region_id, r.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		o.type_id = 1089 AND
		dc.metric_id = @metric_id AND
		dc.attribute_id = @attribute_id AND
		dc.date = @date AND
		dc.date_type = @date_type AND
		(
			(@spot_historic = 0 AND cr.date = dc.date) OR
			(@spot_historic = 1 AND cr.date = @spot_quarter)
		)
		
ORDER BY value DESC


-- Data
SELECT	RANK() OVER (ORDER BY value DESC) rank, * FROM #data ORDER BY value DESC

DROP TABLE #data
