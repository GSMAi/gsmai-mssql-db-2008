CREATE VIEW [dbo].[workflow_data_history_simple_view] AS SELECT	ds.id, ds.val_d, ds.val_i, ds.currency_id, ds.privacy_id, ds.location, ds.approved, ds.import_hash,
		z.id country_id,
		z.name country,
		o.id organisationId,
		o.name organisationName,
		m.id metricId,
		m.name metric,
		a.id attributeId,
		a.name attribute,
		c.name currency,
		c.iso_code currency_iso_code,
		s.name source,
		c2.name confidence,
		ds.created_on,
		ds.date reported_date,
		ds.date_type,
		u.name unit_name, 
		u.symbol, 
		u.quantity
FROM	wi_import.dbo.ds_organisation_data ds INNER JOIN
		organisations o ON ds.organisation_id = o.id INNER JOIN
		organisation_zone_link oz ON o.id = oz.organisation_id INNER JOIN
		zones z ON oz.zone_id = z.id INNER JOIN
		metrics m ON ds.metric_id = m.id INNER JOIN
		attributes a ON ds.attribute_id = a.id INNER JOIN
		currencies c ON ds.currency_id = c.id INNER JOIN
		sources s ON ds.source_id = s.id INNER JOIN
		confidence c2 ON ds.confidence_id = c2.id INNER JOIN 
		units u ON u.id = m.unit_id