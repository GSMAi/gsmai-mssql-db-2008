
CREATE PROCEDURE [dbo].[process_update_currency_rates]

(
	@date_end datetime,
	@date_spot datetime = null,
	@debug bit = 1
)

AS

DECLARE @date datetime

IF @date_spot IS null
BEGIN
	SET @date_spot = dbo.current_reporting_quarter()
END

-- Ensure we have "forecast" exchange rates for all combinations through to @date_end where a value exists for the current period
CREATE TABLE #currencies (id int, processed bit)
CREATE TABLE #currency_rates (id int, from_currency_id int, to_currency_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, processed bit)

INSERT INTO #currencies
SELECT DISTINCT from_currency_id, 0 FROM currency_rates WHERE date = @date_spot AND date_type = 'Q'

SET @date = DATEADD(month, 3, @date_spot)

WHILE @date < @date_end
BEGIN
	INSERT INTO #currency_rates
	SELECT null, id, 1, @date, 'Q', 0 FROM #currencies UNION ALL
	SELECT null, id, 2, @date, 'Q', 0 FROM #currencies UNION ALL
	SELECT null, id, 3, @date, 'Q', 0 FROM #currencies UNION ALL
	SELECT null, id, 73, @date, 'Q', 0 FROM #currencies

	SET @date = DATEADD(month, 3, @date)
END

UPDATE	cr1
SET		cr1.id = cr2.id
FROM	#currency_rates cr1 INNER JOIN currency_rates cr2 ON (cr1.from_currency_id = cr2.from_currency_id AND cr1.to_currency_id = cr2.to_currency_id AND cr1.date = cr2.date AND cr1.date_type = cr2.date_type)


IF @debug = 0
BEGIN
	-- Insert "forecast" exchange rates that don't yet exist
	INSERT INTO currency_rates (from_currency_id, to_currency_id, date, date_type, value, created_by)
	SELECT from_currency_id, to_currency_id, date, date_type, 0, 11770 FROM #currency_rates WHERE id IS null

	-- Update all future exchange rates to the most recent reported value
	UPDATE	cr2
	SET		cr2.value = cr1.value, cr2.last_update_on = CASE WHEN cr2.value = cr1.value THEN cr2.last_update_on ELSE GETDATE() END, cr2.last_update_by = CASE WHEN cr2.value = cr1.value THEN cr2.last_update_by ELSE 11770 END
	FROM	currency_rates cr1 INNER JOIN currency_rates cr2 ON (cr1.from_currency_id = cr2.from_currency_id AND cr1.to_currency_id = cr2.to_currency_id AND cr1.date_type = cr2.date_type)
	WHERE	cr1.date = @date_spot AND cr2.date > @date_spot AND cr1.date_type = 'Q'
END

IF @debug = 1
BEGIN
	SELECT * FROM #currency_rates WHERE id IS null
END

DROP TABLE #currencies
DROP TABLE #currency_rates
