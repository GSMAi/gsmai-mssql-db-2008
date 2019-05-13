
CREATE PROCEDURE [dbo].[data_groups]

(
	@status_id int = null
)

AS

CREATE TABLE #data (id int, name nvarchar(512), status_id int, type_id int, url nvarchar(1024), has_data bit)

INSERT INTO #data
SELECT	DISTINCT
		o.id,
		o.name,
		CASE o.status_id WHEN 1308 THEN 0 ELSE o.status_id END,
		o.type_id,
		o.url,
		CASE WHEN dc.organisation_id IS null THEN 0 ELSE 1 END has_data

FROM	organisations o INNER JOIN
		ds_group_ownership ds ON o.id = ds.group_id LEFT JOIN												-- Must have ownership data
		dc_group_data_sets dc ON (dc.organisation_id = o.id AND dc.metric_id = 3 AND dc.attribute_id = 0)	-- But don't require data sets

WHERE	o.type_id = 9 AND
		o.status_id IN (0,81,85,1308) AND
		(
			(@status_id = 0 AND o.status_id IN (0,1308)) OR -- Special case for 'live'; include 'missing'
			(o.status_id = COALESCE(@status_id, o.status_id))
		)

ORDER BY o.name


-- Data
SELECT * FROM #data ORDER BY name

-- Operator counts
SELECT status_id, COUNT(*) FROM #data GROUP BY status_id ORDER BY status_id


DROP TABLE #data
