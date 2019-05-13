
CREATE PROCEDURE [dbo].[data_auctions_pricing]

(
	@show tinyint,
	@geoscheme_id int = null,
	@region_id int = null,
	@subregion_id int = null,
	@country_id int = null,
	@auction_id int = null,
	@frequency_id int = null,
	@technology_id int = null,
	@status_id int = null
)
	
AS

DECLARE @frequency_is_family bit, @status_is_family bit

--SET @frequency_is_family = (SELECT COUNT(DISTINCT family_id) FROM attribute_family_link WHERE family_id = @frequency_id)
SET @status_is_family = (SELECT COUNT(DISTINCT family_id) FROM attribute_family_link WHERE family_id = @status_id)

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


CREATE TABLE #auctions (id int, zone_id int, date datetime, status_id int)
CREATE TABLE #auction_awards (id int, auction_id int, organisation_id int, status_id int)

-- Country-level data for auctions
INSERT INTO #auctions
SELECT	a.id,
		a.zone_id,
		a.date,
		a.status_id
		
FROM	auctions a INNER JOIN
		zones c ON a.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id
		
WHERE	a.price IS NOT null AND -- Pricing
		a.id = COALESCE(@auction_id, a.id) AND
		c.id = COALESCE(@country_id, c.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id AND
		(
			(@status_is_family = 0 AND a.status_id = COALESCE(@status_id, a.status_id)) OR
			(@status_is_family = 1 AND a.status_id IN (SELECT DISTINCT attribute_id FROM attribute_family_link WHERE family_id = @status_id))
		)


IF @show = 2
BEGIN
	-- Operator-level data for awards
	INSERT INTO #auction_awards
	SELECT	aw.id,
			aw.auction_id,
			aw.organisation_id,
			aw.status_id
			
	FROM	auction_awards aw INNER JOIN
			auctions a ON aw.auction_id = a.id INNER JOIN
			zones c ON a.zone_id = c.id INNER JOIN
			zone_link zl ON c.id = zl.subzone_id INNER JOIN
			zones s ON zl.zone_id = s.id INNER JOIN
			zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
			zones r ON zl2.zone_id = r.id INNER JOIN
			zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
			zones g ON zl3.zone_id = g.id
			
	WHERE	a.id = COALESCE(@auction_id, a.id) AND
			c.id = COALESCE(@country_id, c.id) AND
			s.id = COALESCE(@subregion_id, s.id) AND
			r.id = COALESCE(@region_id, r.id) AND
			g.id = @geoscheme_id AND
			(
				(@status_is_family = 0 AND aw.status_id = COALESCE(@status_id, aw.status_id)) OR
				(@status_is_family = 1 AND aw.status_id IN (SELECT DISTINCT attribute_id FROM attribute_family_link WHERE family_id = @status_id))
			)
END

-- Apply filters that don't JOIN efficiently
IF @frequency_id IS NOT null
BEGIN
	DELETE FROM	#auctions WHERE id NOT IN (SELECT auction_id FROM auction_frequency_link WHERE frequency_id = @frequency_id)
	DELETE FROM	#auction_awards WHERE auction_id NOT IN (SELECT auction_id FROM auction_frequency_link WHERE frequency_id = @frequency_id)
END

IF @technology_id IS NOT null
BEGIN
	DELETE FROM	#auctions WHERE id NOT IN (SELECT auction_id FROM auction_service_link WHERE service_id = @technology_id)
	DELETE FROM	#auction_awards WHERE auction_id NOT IN (SELECT auction_id FROM auction_service_link WHERE service_id = @technology_id)
END


-- Data
SELECT	id
FROM 	#auctions

SELECT	id
FROM 	#auction_awards


-- Stats
SELECT	COUNT(*) count
FROM	(SELECT DISTINCT zone_id, date FROM #auctions) a

UNION ALL

SELECT	COUNT(*) count
FROM	#auction_awards

UNION ALL

SELECT	COUNT(DISTINCT zone_id) count
FROM	#auctions

UNION ALL

SELECT	COUNT(DISTINCT organisation_id) count
FROM	#auction_awards


DROP TABLE #auction_awards
DROP TABLE #auctions
