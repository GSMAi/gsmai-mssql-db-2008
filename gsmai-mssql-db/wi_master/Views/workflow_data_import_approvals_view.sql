CREATE VIEW [dbo].[workflow_data_import_approvals_view] AS SELECT	ds.*,
		z.id country_id,
		z.name country,
		m.name metric,
		a.name attribute,
		c.name currency,
		c.iso_code currency_iso_code,
		s.name source,
		c2.name confidence,
		o.name organisationName,
		m.[order] metricOrder,
		a.[order] attributeOrder,
		ds.date_type orgDataDataType,
		ds.date orgDataDate

FROM	wi_import.dbo.ds_organisation_data ds INNER JOIN
		organisations o ON ds.organisation_id = o.id INNER JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
		zones z ON oz.zone_id = z.id INNER JOIN
		metrics m ON ds.metric_id = m.id INNER JOIN
		attributes a ON ds.attribute_id = a.id INNER JOIN
		currencies c ON ds.currency_id = c.id INNER JOIN
		sources s ON ds.source_id = s.id INNER JOIN
		confidence c2 ON ds.confidence_id = c2.id

WHERE	ds.approved IS null
