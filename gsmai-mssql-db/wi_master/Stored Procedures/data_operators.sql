
CREATE PROCEDURE [dbo].[data_operators]

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
	-- Developed/developing split should return results from any geoscheme
	-- TODO: better solution!
	SET @geoscheme_id = 3937
END

CREATE TABLE #data (id int, name nvarchar(512), country_id int, country nvarchar(512), iso_code nvarchar(3), iso_short_code nvarchar(2), subregion_id int, subregion nvarchar(512), region_id int, region nvarchar(512), status_id int, type_id int, tadig_codes nvarchar(MAX), url nvarchar(1024), launch_date datetime, has_data bit)

INSERT INTO #data
SELECT	o.id,
		o.name,
		c.id,
		c.name,
		c.iso_code,
		c.iso_short_code,
		s.id,
		s.name,
		r.id,
		r.name,
		CASE o.status_id WHEN 1308 THEN 0 ELSE o.status_id END,
		o.type_id,
		o.tadig_codes,
		o.url,
		n.launch_date,
		CASE WHEN dc.organisation_id IS null THEN 0 ELSE 1 END has_data

FROM	organisations o INNER JOIN
		organisation_zone_link oz ON oz.organisation_id = o.id INNER JOIN
		zones c ON oz.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id LEFT JOIN
		dc_organisation_data_sets dc ON (dc.organisation_id = o.id AND dc.metric_id = 3 AND dc.attribute_id = 0) 
		LEFT JOIN
		(
			SELECT organisation_id, date AS launch_date FROM wi_master.dbo.latest_organisation_launch_dates where rank=1
		) n ON n.organisation_id = o.id

WHERE	c.id = COALESCE(@country_id, c.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id AND
		o.type_id = 1089 AND
		o.name <> 'Other' AND
		o.status_id IN (0,81,85,1308) AND
		(
			(@status_id = 0 AND o.status_id IN (0,1308)) OR -- Special case for 'live'; include 'missing'
			(o.status_id = COALESCE(@status_id, o.status_id))
		)

ORDER BY c.name, o.name


-- Data
SELECT * FROM #data ORDER BY country, name

-- Operator counts
SELECT status_id, COUNT(*) FROM #data GROUP BY status_id ORDER BY status_id


DROP TABLE #data
