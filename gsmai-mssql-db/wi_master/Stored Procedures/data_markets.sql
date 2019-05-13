
CREATE PROCEDURE [dbo].[data_markets]

(
	@geoscheme_id int = null,
	@region_id int = null,
	@subregion_id int = null
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

CREATE TABLE #data (id int, name nvarchar(512), iso_code nvarchar(3), iso_short_code nvarchar(2), subregion_id int, subregion nvarchar(512), region_id int, region nvarchar(512), regulator_id int, regulator nvarchar(512), regulator_url nvarchar(1024))

INSERT INTO #data
SELECT	c.id,
		c.name,
		c.iso_code,
		c.iso_short_code,
		s.id,
		s.name,
		r.id,
		r.name,
		o.id,
		o.name,
		o.url

FROM	zones c INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id LEFT JOIN
		(
			organisation_zone_link oz INNER JOIN
			organisations o ON (oz.organisation_id = o.id AND o.type_id = 1227)
		) ON oz.zone_id = c.id

WHERE	s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id

ORDER BY c.name, r.name, s.name


-- Data
SELECT DISTINCT * FROM #data ORDER BY name, region, subregion

-- Counts by region
SELECT 3826 region_id, COUNT(DISTINCT id) [count] FROM #data UNION ALL
SELECT region_id, COUNT(DISTINCT id) [count] FROM #data GROUP BY region_id ORDER BY region_id


DROP TABLE #data
