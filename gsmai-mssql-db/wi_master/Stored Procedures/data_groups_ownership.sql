
CREATE PROCEDURE [dbo].[data_groups_ownership]

(
	@group_id int = null,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@ownership_threshold decimal(6,4) = 0.0
)

AS

DECLARE @id int, @current_quarter datetime = dbo.current_reporting_quarter()

CREATE TABLE #data (id bigint, metric_id int, attribute_id int, group_id int, parent_group_id int, organisation_id int, country_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(6,4), is_compound bit, is_consolidated bit, is_group bit, is_joint_venture bit, processed bit)

INSERT INTO #data
SELECT	ds.id,
		ds.metric_id,
		ds.attribute_id,
		ds.group_id,
		null,
		ds.organisation_id,
		oz.zone_id,
		ds.date,
		ds.date_type,
		ds.value,
		ds.is_compound,
		ds.is_consolidated,
		ds.is_group,
		ds.is_joint_venture,
		0

FROM	ds_group_ownership ds LEFT JOIN
		organisation_zone_link oz ON ds.organisation_id = oz.organisation_id

WHERE	ds.group_id = COALESCE(@group_id, ds.group_id) AND
		ds.metric_id = 72 AND
		ds.attribute_id = 0 AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		(
			(@ownership_threshold = 0.51 AND (ds.value > 0.5 OR ds.is_consolidated = 1)) OR
			(@ownership_threshold <> 0.51 AND ds.value >= @ownership_threshold)
		)


WHILE EXISTS (SELECT * FROM #data WHERE processed = 0)
BEGIN
	SET @id = (SELECT TOP 1 group_id FROM #data WHERE processed = 0)

	-- Join on each primary group, so we can show compound subsidiaries
	UPDATE	d
	SET		d.parent_group_id = r.group_id
	FROM	#data d INNER JOIN
			(
				SELECT	RANK() OVER (PARTITION BY ds.organisation_id ORDER BY date DESC, ds.value DESC) rank, -- Most recent, highest shareholding
						ds.group_id,
						ds.organisation_id,
						ds.value

				FROM	ds_group_ownership ds

				WHERE	ds.group_id IN (SELECT @id UNION ALL SELECT DISTINCT organisation_id FROM #data WHERE group_id = @id AND is_group = 1) AND -- Only compound subgroups of this group, provided their share is larger than the top-level group
						ds.metric_id = 72 AND
						ds.attribute_id = 0 AND
						ds.date_type = @date_type AND
						ds.is_group = 0
			) r ON (d.group_id = @id AND d.organisation_id = r.organisation_id AND r.rank = 1)

	-- Take direct ownership of non-subgroup subsidiaries
	UPDATE #data SET parent_group_id = group_id WHERE group_id = @id AND parent_group_id IS null

	UPDATE #data SET processed = 1 WHERE group_id = @id
END

UPDATE #data SET parent_group_id = organisation_id WHERE is_group = 1


-- Data
SELECT * FROM #data ORDER BY group_id, organisation_id, date_type, date

-- Distinct groups, operators
SELECT	DISTINCT
		g.id group_id,
		g.name [group],
		p.id parent_group_id,
		p.name parent_group,
		o.id organisation_id,
		o.name organisation,
		c.id country_id,
		c.name country,
		d.is_group,
		CASE WHEN p.id = g.id THEN 1 ELSE 0 END is_direct

FROM 	#data d INNER JOIN
		organisations g ON d.group_id = g.id INNER JOIN
		organisations p ON d.parent_group_id = p.id INNER JOIN
		organisations o ON d.organisation_id = o.id LEFT JOIN
		zones c ON d.country_id = c.id

ORDER BY g.name, is_direct DESC, p.name, d.is_group DESC, o.name, c.name

-- Date combinations
SELECT DISTINCT date, date_type, CASE date_type WHEN 'Q' THEN 1 WHEN 'H' THEN 2 WHEN 'Y' THEN 3 ELSE 4 END date_type_order FROM #data ORDER BY date, date_type_order


DROP TABLE #data
