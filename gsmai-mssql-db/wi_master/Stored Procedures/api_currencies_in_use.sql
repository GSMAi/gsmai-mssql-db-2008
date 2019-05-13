
CREATE PROCEDURE [dbo].[api_currencies_in_use]

(
	@q int,
	@show tinyint,
	@zone_id int,
	@currency_id int
)

AS

DECLARE @date_start datetime, @date_end datetime, @date_type char(1), @xml xml 

SET @date_start	= '2000-01-01'
SET @date_end	= '2021-01-01'
SET @date_type	= 'Q'


IF @q = 2
BEGIN
	-- Financial model
	CREATE TABLE #currencies (organisation_id int, currency_id int)

	;WITH r AS
	(
		SELECT	DISTINCT
				ds.organisation_id,
				ds.currency_id,
				DENSE_RANK() OVER (PARTITION BY ds.organisation_id ORDER BY ds.metric_order, ds.attribute_order, ds.date DESC) rank

		FROM	dc_organisation_data ds INNER JOIN
				organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
				currencies c ON ds.currency_id = c.id

		WHERE	oz.zone_id = @zone_id AND
				(
					-- Financial metrics only
					(ds.metric_id IN (10,18,29,34,65,66) AND ds.attribute_id IN (0,69,436,826,827,828,834,1518))
				) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
	)

	INSERT INTO #currencies
	SELECT organisation_id, currency_id FROM r WHERE rank = 1

	
	IF @show = 1
	BEGIN
		-- Most recent currency id by operator
		SELECT * FROM #currencies
	END


	IF @show = 2
	BEGIN
		-- Exchange rates for above currencies
		SELECT	cr.from_currency_id currency_id,
				cr.date,
				cr.date_type,
				CASE WHEN cr.value = 0 THEN 0 ELSE 1/cr.value END value

		FROM	currency_rates cr

		WHERE	cr.date >= @date_start AND
				cr.date < @date_end AND
				cr.to_currency_id = @currency_id AND
				cr.from_currency_id IN (SELECT DISTINCT currency_id FROM #currencies) -- Because we only store all:major and not vice-versa

		ORDER BY cr.from_currency_id, cr.date_type, cr.date
	END


	DROP TABLE #currencies
END
