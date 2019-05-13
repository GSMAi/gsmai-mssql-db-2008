
CREATE PROCEDURE [dbo].[process_populate_report_metadata]

AS

DECLARE @id int, @sp nvarchar(128), @fk_id int, @fk nvarchar(128), @fk_id_2 int, @fk_2 nvarchar(128)

CREATE TABLE #reports (id int, sp nvarchar(128), processed bit)

-- Fetch all entries without fk metadata
INSERT INTO #reports
SELECT	r.id, r.sp, 0
FROM	reports r LEFT JOIN report_fk_link rf ON r.id = rf.report_id
WHERE	r.serialized IS NOT null AND r.sp <> '_content' AND r.sp = 'data_metrics_data' AND rf.report_id IS null
ORDER BY r.id DESC

--/markets/n/data/
SET @sp	= 'data_markets_data'
SET @fk = 'zone_id'

WHILE EXISTS (SELECT * FROM #reports WHERE sp = @sp AND processed = 0)
BEGIN
	SET @id		= (SELECT TOP 1 id FROM #reports WHERE sp = @sp AND processed = 0)
	SET @fk_id	= (SELECT TOP 1 s.value_int FROM reports r CROSS APPLY php_unserialize(r.serialized) s WHERE r.id = @id AND s.var_name = @fk)

	INSERT INTO report_fk_link (report_id, fk, fk_id) VALUES (@id, @fk, @fk_id)
	UPDATE #reports SET processed = 1 WHERE id = @id
END


--/metrics/n/n/data/
SET @sp	  = 'data_metrics_data'
SET @fk	  = 'metric_id'
SET @fk_2 = 'attribute_id'

WHILE EXISTS (SELECT * FROM #reports WHERE sp = @sp AND processed = 0)
BEGIN
	SET @id		 = (SELECT TOP 1 id FROM #reports WHERE sp = @sp AND processed = 0)
	SET @fk_id	 = (SELECT TOP 1 s.value_int FROM reports r CROSS APPLY php_unserialize(r.serialized) s WHERE r.id = @id AND s.var_name = @fk)
	SET @fk_id_2 = (SELECT TOP 1 s.value_int FROM reports r CROSS APPLY php_unserialize(r.serialized) s WHERE r.id = @id AND s.var_name = @fk_2)

	INSERT INTO report_fk_link (report_id, fk, fk_id, fk_2, fk_id_2) VALUES (@id, @fk, @fk_id, @fk_2, @fk_id_2)
	UPDATE #reports SET processed = 1 WHERE id = @id
END


DROP TABLE #reports