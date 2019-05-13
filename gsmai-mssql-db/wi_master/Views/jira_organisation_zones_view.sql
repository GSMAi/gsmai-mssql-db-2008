CREATE VIEW [dbo].[jira_organisation_zones_view] AS select org.id, org.name + ' (' + z.name + ')' AS name, z.id AS zone_id
FROM dbo.organisations AS org
LEFT JOIN dbo.organisation_zone_link AS ozl ON ozl.organisation_id=org.id
LEFT JOIN dbo.zones AS z ON z.id=ozl.zone_id
WHERE org.name IS NOT NULL AND z.name IS NOT NULL 
AND org.published=1
AND z.fk_type_id=38
