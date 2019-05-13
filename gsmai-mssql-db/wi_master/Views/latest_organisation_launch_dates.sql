CREATE VIEW [dbo].[latest_organisation_launch_dates] AS SELECT organisation_id, oe.date, oe.status_id, rank = ROW_NUMBER() 
OVER (PARTITION BY oe.organisation_id, oe.status_id ORDER BY oe.created_on DESC)
FROM	wi_master.dbo.organisation_events as oe
where oe.date is not null
and oe.status_id=1578