CREATE VIEW [dbo].[_research_download_counts] AS SELECT	o.name as 'organisation_name',
		z.name as 'country',
		t.name as 'organisation_type',
		COUNT(dt.id) as "downloads"

FROM	documents d INNER JOIN
		document_tracking dt ON d.id = dt.document_id INNER JOIN
		users u ON dt.user_id = u.id INNER JOIN
		user_organisation_link uo ON u.id = uo.user_id INNER JOIN
		organisations o ON uo.organisation_id = o.id LEFT JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id LEFT JOIN
		zones z ON oz.zone_id = z.id LEFT JOIN
		types t ON o.type_id = t.id


WHERE	dt.created_on >= '2016-04-01' AND
		dt.created_on < '2017-03-31'

GROUP BY o.name, z.name, t.name