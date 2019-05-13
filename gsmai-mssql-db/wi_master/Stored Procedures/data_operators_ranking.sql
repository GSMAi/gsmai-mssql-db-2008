
CREATE PROCEDURE [dbo].[data_operators_ranking]

(
	@geoscheme_id int = null,
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

IF @geoscheme_id IS NULL
BEGIN
	SET @geoscheme_id = dbo.default_geoscheme_id()
END

IF @subregion_id IN (3899,3900)
BEGIN
	-- Developed/developing split should return results from any geoscheme
	-- TODO: better solution!
	SET @geoscheme_id = 3937
END

IF @date IS NULL
BEGIN
	SET @date = dbo.current_reporting_quarter()
END

IF @spot_quarter IS NULL
BEGIN
	SET @spot_quarter = dbo.current_reporting_quarter()
END

SELECT	RANK() OVER (ORDER BY CASE WHEN dc.val_i IS NULL THEN dc.val_d * cr.value ELSE CAST(dc.val_i * cr.value AS decimal(22,4)) END DESC) rank,
		dc.id,
		o.id organisation_id,
		o.name organisation,
		c.id country_id,
		c.name country,
		c.iso_code,
		c.iso_short_code,
		s.id subregion_id,
		s.name subregion,
		r.id region_id,
		r.name region,
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
		zones c ON oz.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = @currency_id)
	LEFT JOIN organisation_data_metadata as dm ON dc.id = dm.fk_organisation_data_id


WHERE	g.id = @geoscheme_id AND
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
