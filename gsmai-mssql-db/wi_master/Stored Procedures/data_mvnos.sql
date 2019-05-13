
CREATE PROCEDURE [dbo].[data_mvnos]

(
	@geoscheme_id int = null,
	@region_id int = null,
	@subregion_id int = null,
	@country_id int = null,
	@status_id int = null
)
	
AS

IF @geoscheme_id IS NULL
BEGIN
	SET @geoscheme_id = dbo.default_geoscheme_id()
END

IF @subregion_id IN (3899,3900)
BEGIN
	-- Developed/developing split can return results from any geosceheme
	-- TODO: better solution!
	SET @geoscheme_id = 3937
END


SELECT	DISTINCT
		o.id,
		o.name,
		o.status_id,
		h.id host_id,
		h.name host,
		u.id group_id,
		u.name [group],
		c.id country_id,
		c.name country,
		c.iso_code,
		c.iso_short_code,
		s.id subregion_id,
		s.name subregion,
		r.id region_id,
		r.name region,
		a.id category_id,
		t.id tariff_type_id,
		ds.launch_date,
		ds.url,
		ds.is_brand,
		ds.is_data_only,
		ds.has_data,
		ds.has_group_data

FROM	ds_mvnos ds INNER JOIN
		organisations o ON ds.mvno_id = o.id INNER JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
		zones c ON oz.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id LEFT JOIN
		mvno_group_link mg ON ds.mvno_id = mg.mvno_id LEFT JOIN
		organisations u ON mg.group_id = u.id LEFT JOIN
		mvno_host_link mh ON ds.mvno_id = mh.mvno_id LEFT JOIN
		organisations h ON mh.host_id = h.id LEFT JOIN
		attributes a ON ds.category_id = a.id LEFT JOIN
		attributes t ON ds.tariff_type_id = t.id
	
WHERE	o.status_id = COALESCE(@status_id, o.status_id) AND
		o.status_id <> 1309 AND -- No 'verified' operators
		c.id = COALESCE(@country_id, c.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id

ORDER BY ds.launch_date DESC, c.name, o.name, h.name
