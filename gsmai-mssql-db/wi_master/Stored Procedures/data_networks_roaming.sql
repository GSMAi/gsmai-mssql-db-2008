
CREATE PROCEDURE [dbo].[data_networks_roaming]

(
	@geoscheme_id int = null,
	@region_id int = null,
	@subregion_id int = null,
	@country_id int = null,
	@technology_id int = null,
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
		o3.id organisation_id,
		o3.name organisation,
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
		nrr.ref_status_id status_id,
		COUNT(DISTINCT c2.id) count_countries,
		COUNT(DISTINCT o4.id) count_organisations
		
FROM	gsma.ic_network_roaming_relationship_link nrr INNER JOIN
		gsma.ic_network_link n ON nrr.network_id = n.id INNER JOIN
		gsma.ic_organisation_link o ON n.organisation_id = o.id INNER JOIN
		gsma.ic_network_link n2 ON nrr.rel_network_id = n2.id INNER JOIN
		gsma.ic_organisation_link o2 ON n2.organisation_id = o2.id INNER JOIN
		attributes t ON n.ref_technology_id = t.id INNER JOIN
		organisations o3 ON o.ref_organisation_id = o3.id INNER JOIN
		organisations o4 ON o2.ref_organisation_id = o4.id INNER JOIN
		organisation_zone_link oz ON o3.id = oz.organisation_id INNER JOIN
		organisation_zone_link oz2 ON o4.id = oz2.organisation_id INNER JOIN
		zones c ON oz.zone_id = c.id INNER JOIN
		zones c2 ON oz2.zone_id = c2.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN 
		zones r ON zl2.zone_id = r.id INNER JOIN
		zone_link zl3 ON r.id = zl3.subzone_id INNER JOIN
		zones g ON zl3.zone_id = g.id

		
WHERE	t.id = COALESCE(@technology_id, t.id) AND
		c.id = COALESCE(@country_id, c.id) AND
		s.id = COALESCE(@subregion_id, s.id) AND
		r.id = COALESCE(@region_id, r.id) AND
		g.id = @geoscheme_id AND
		(
			(@status_id = 0 AND nrr.ref_status_id IN (0,33)) OR			-- Special case for 'Live'; include 'Agreement'
			(nrr.ref_status_id = COALESCE(@status_id, nrr.ref_status_id))
		)

GROUP BY o3.id, o3.name, t.id, t.name, t.[order], c.id, c.name, c.iso_code, c.iso_short_code, s.id, s.name, r.id, r.name, nrr.ref_status_id
ORDER BY c.name, o3.name, t.[order], nrr.ref_status_id
