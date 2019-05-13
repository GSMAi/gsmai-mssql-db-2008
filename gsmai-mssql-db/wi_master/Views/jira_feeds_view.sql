CREATE VIEW [dbo].[jira_feeds_view] AS select fe.id, fe.entry, z.name AS "zone", z.id AS "zoneId", o.name + ' (' + oz.name + ')' AS "organisationName", o.id AS "organisationId", fe.source, fe.url, RIGHT(CONVERT(VARCHAR(11), fe.created_on, 106), 8) AS "date", fe.created_on
FROM dbo.feed AS fe
LEFT JOIN dbo.feed_entity_link AS felz ON (felz.feed_id=fe.id AND felz.[table]='zones')
LEFT JOIN dbo.feed_entity_link AS felo ON (felo.feed_id=fe.id AND felo.[table]='organisations')
LEFT JOIN dbo.zones AS z ON z.id=felz.entity_id
LEFT JOIN dbo.organisations AS o ON o.id=felo.entity_id
LEFT JOIN dbo.organisation_zone_link AS ozl ON ozl.organisation_id=o.id
LEFT JOIN dbo.zones AS oz ON oz.id=ozl.zone_id
