
CREATE PROCEDURE [dbo].[data_markets_ranking]

(
	@geoscheme_id int,
	@region_id int = null,
	@subregion_id int = null,
	@metric_id int,
	@attribute_id int,
	@date datetime = null,
	@date_type char(1) = 'Q',
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

SELECT	RANK() OVER (ORDER BY CASE dc.is_calculated WHEN 0 THEN (CASE WHEN dc.val_i IS NULL THEN dc.val_d * cr.value ELSE CAST(dc.val_i * cr.value AS decimal(22,4)) END) ELSE (CASE WHEN dc.val_i IS null THEN dc.val_d ELSE CAST(dc.val_i AS decimal(22,4)) END) END DESC) rank,
		dc.id,
		c.id country_id,
		c.name country,
		s.id subregion_id,
		s.name subregion,
		r.id region_id,
		r.name region,
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
		zones c ON dc.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id)
	LEFT JOIN zone_data_metadata as dm ON dc.id = dm.fk_zone_data_id


WHERE	s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id AND
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
				dc.currency_id IN (0, @currency_id) AND
				(
					((@spot_historic = 0 OR dc.currency_id = 0) AND cr.date = dc.date AND (dc.is_spot = 0 OR dc.is_spot IS null)) OR 		-- Either null for non-currency data or 0/1 for historic/spot calculation
					((@spot_historic = 1 AND dc.currency_id <> 0) AND cr.date = @spot_quarter AND (dc.is_spot = 1 OR dc.is_spot IS null))	-- Still joined on currency_rates, so need a cr.date clause to ensure 1:1 rows returned
				)
			)
		)
		
ORDER BY value DESC
