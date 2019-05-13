
CREATE PROCEDURE [dbo].[data_networks]

(
	@geoscheme_id int = null,
	@region_id int = null,
	@subregion_id int = null,
	@country_id int = null,
	@technology_id int = null,
	@status_id int = null
)
	
AS

DECLARE @technology_is_family bit
SET @technology_is_family = (SELECT COUNT(DISTINCT family_id) FROM attribute_family_link WHERE family_id = @technology_id)

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
		o.id organisation_id,
		o.name organisation,
		CASE o.status_id WHEN 1308 THEN 0 ELSE o.status_id END organisation_status_id,
		t.id technology_id,
		t.name technology,
		t.[order] technology_order,
		c.id country_id,
		c.name country,
		c.iso_code,
		c.iso_short_code,
		s.id subregion_id,
		s.name subregion,
		r.id region_id,
		r.name region,
		CASE n.status_id WHEN 1308 THEN 0 ELSE n.status_id END status_id,
		CASE n.status_id WHEN 81 THEN 0 ELSE 1 END status_order, -- Show planned networks before live as most won't have a (future) launch date
		n.launch_date,
		n.closure_date,
		n.downlink_rate,
		n.downlink_rate_unit_id,
		n.uplink_rate,
		n.uplink_rate_unit_id,
		LEFT(f.frequencies, LEN(f.frequencies)-1) frequencies,
		n.vendors
		
FROM	networks n INNER JOIN
		organisations o ON n.organisation_id = o.id INNER JOIN
		attributes t ON n.technology_id = t.id INNER JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
		zones c ON oz.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id LEFT JOIN
		(
			SELECT	DISTINCT
					nf2.network_id,
					(
						SELECT	f.name + '/' AS [text()]
						
						FROM	network_frequency_link nf1 INNER JOIN
								attributes f ON nf1.frequency_id = f.id
								
						WHERE	nf1.network_id = nf2.network_id
								
						ORDER BY f.[order]
						
						FOR XML PATH ('')
					) frequencies
					
			FROM	network_frequency_link nf2
		) f ON n.id = f.network_id
		
WHERE	c.id = COALESCE(@country_id, c.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id AND
		(
			(@technology_is_family = 0 AND t.id = COALESCE(@technology_id, t.id) AND t.published=1 AND 
				t.id IN (602,603,616,619,621,624,823,824,825,870,931,936,937,941,996,1124,1201,1238,
					1245,1293,1307,1472,1473,1474,1512,1513,1514,1515,1545,1595,1600, 1620, 1621, 
					1622, 1625, 1626, 1601, 1603, 1604, 1394, 1591, 1615, 1623, 1624)) OR
			(@technology_is_family = 1 AND t.id IN (SELECT DISTINCT attribute_id FROM attribute_family_link WHERE family_id = @technology_id))
		) AND
		(
			(@status_id = 0 AND n.status_id IN (0,1308)) OR -- Special case for 'live'; include 'missing'
			(n.status_id = COALESCE(@status_id, n.status_id))
		) AND
		n.status_id NOT IN (1309, 1574) -- No 'verified' networks (fixed-wireless etc.)

ORDER BY status_order, n.launch_date DESC, c.name, o.name, t.[order]
