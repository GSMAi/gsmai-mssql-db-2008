CREATE VIEW [dbo].[jira_network_list] AS SELECT att.name, s.id AS "statusId", s.name AS "status", RIGHT(CONVERT(VARCHAR(11), n.launch_date, 106), 8) AS "date", n.organisation_id, n.launch_date
FROM dbo.networks AS n
LEFT JOIN dbo.attributes as att ON att.id=n.technology_id
LEFT JOIN dbo.status AS s ON s.id=n.status_id
