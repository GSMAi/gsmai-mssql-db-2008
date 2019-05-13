
CREATE PROCEDURE [dbo].[data_operators_events]

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

CREATE TABLE #data (id int, name nvarchar(512) COLLATE DATABASE_DEFAULT, country_id int, country nvarchar(512) COLLATE DATABASE_DEFAULT, iso_code nvarchar(3) COLLATE DATABASE_DEFAULT, iso_short_code nvarchar(2) COLLATE DATABASE_DEFAULT, subregion_id int, subregion nvarchar(512) COLLATE DATABASE_DEFAULT, region_id int, region nvarchar(512) COLLATE DATABASE_DEFAULT, ref_organisation_id int, ref_organisation nvarchar(512) COLLATE DATABASE_DEFAULT, ref_country_id int, ref_country nvarchar(512) COLLATE DATABASE_DEFAULT, ref_organisation_id_2 int, ref_organisation_2 nvarchar(512) COLLATE DATABASE_DEFAULT, status_id int, status nvarchar(512) COLLATE DATABASE_DEFAULT, date_type char(1) COLLATE DATABASE_DEFAULT, date datetime)

INSERT INTO #data
SELECT	DISTINCT
		o.id,
		o.name,
		c.id,
		c.name,
		c.iso_code,
		c.iso_short_code,
		s.id,
		s.name,
		r.id,
		r.name,
		o2.id,
		o2.name,
		c2.id,
		c2.name,
		o3.id,
		o3.name,
		t.id,
		t.name,
		ds.date_type,
		ds.date

FROM	organisation_events ds INNER JOIN
		status t ON ds.status_id = t.id INNER JOIN
		organisations o ON ds.organisation_id = o.id INNER JOIN
		organisation_zone_link oz ON oz.organisation_id = o.id INNER JOIN
		zones c ON oz.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id LEFT JOIN
		organisations o2 ON ds.ref_organisation_id = o2.id LEFT JOIN
		organisation_zone_link oz2 ON o2.id = oz2.organisation_id LEFT JOIN
		zones c2 ON oz2.zone_id = c2.id LEFT JOIN
		organisations o3 ON ds.ref_organisation_id_2 = o3.id

WHERE	c.id = COALESCE(@country_id, c.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id AND
		(
			(@status_id = 1577 AND t.id IN (1311,1576)) OR	-- Merged/Acquired
			(@status_id = 85 AND t.id IN (1311,1312)) OR	-- Merged/Closed
			(t.id = COALESCE(@status_id, t.id))
		)

ORDER BY ds.date DESC, c.name, o.name


-- Data
SELECT * FROM #data ORDER BY date DESC, country, name

-- Operator counts
SELECT status_id, COUNT(*) FROM #data GROUP BY status_id ORDER BY status_id


DROP TABLE #data
