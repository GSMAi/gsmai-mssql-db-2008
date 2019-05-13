
CREATE PROCEDURE [dbo].[calculate_spectrum]

(
	@debug bit = 1
)

AS


-- Aggregate blocks and pricing
CREATE TABLE #calc (auction_id int, count int, organisations int, block decimal(22,4), block_paired decimal(22,4), block_unpaired decimal(22,4), count_block int, price decimal(22,4), price_per_mhz decimal(22,4), count_price int, price_currency_id int)

INSERT INTO #calc
SELECT	aw.auction_id, COUNT(aw.auction_id), COUNT(DISTINCT aw.organisation_id), SUM(aw.block), SUM(aw.block_paired), SUM(aw.block_unpaired), COUNT(aw.block), SUM(aw.price), SUM(CASE WHEN aw.block IS null THEN null ELSE aw.price END)/SUM(CASE WHEN aw.price IS null THEN null ELSE aw.block END), COUNT(aw.price), MIN(aw.price_currency_id)	-- Relies on having a single currency per auction
FROM	auction_awards aw
GROUP BY aw.auction_id

IF @debug = 0
BEGIN
	-- Update auction aggregates
	UPDATE	a
	SET		a.block = CASE WHEN c.count = c.count_block THEN c.block ELSE null END,						-- Only show total block/price where all individual awards have data
			a.block_paired = CASE WHEN c.count = c.count_block THEN c.block_paired ELSE null END,
			a.block_unpaired = CASE WHEN c.count = c.count_block THEN c.block_unpaired ELSE null END,
			a.winners = c.organisations,
			a.price = CASE WHEN c.count = c.count_price THEN c.price ELSE null END,
			--a.price_per_mhz = c.price_per_mhz,														-- Don't use this weighted value, instead there shouldn't be a value where all of the operator data available for all participants
			a.price_currency_id = c.price_currency_id
	FROM	auctions a INNER JOIN #calc c ON a.id = c.auction_id


	-- Calculate price per MHz per population for each award and auction (local, US$ and US$ PPP-adjusted)
	UPDATE	aw
	SET		aw.price_usd = aw.price * cr.value,
			aw.price_per_mhz = aw.price/aw.block/ds.val_i,
			aw.price_per_mhz_usd = aw.price/aw.block/ds.val_i * cr.value

	FROM	auction_awards aw INNER JOIN
			auctions a ON aw.auction_id = a.id INNER JOIN
			currency_rates cr ON (aw.price_currency_id = cr.from_currency_id AND DATEPART(year, a.date) = DATEPART(year, cr.date) AND DATEPART(quarter, a.date) = DATEPART(quarter, cr.date)) LEFT JOIN
			ds_zone_data ds ON (ds.metric_id = 43 AND ds.attribute_id = 0 AND ds.date_type = 'Q' AND a.zone_id = ds.zone_id AND DATEPART(year, a.date) = DATEPART(year, ds.date) AND DATEPART(quarter, a.date) = DATEPART(quarter, ds.date))

	WHERE	cr.to_currency_id = 2 AND
			cr.date_type = 'Q'

	UPDATE	a
	SET		a.price_usd = a.price * cr.value,
			--a.price_per_mhz = a.price_per_mhz/ds.val_i,												-- Don't use this weighted value, instead there shouldn't be a value where all of the operator data available for all participants
			--a.price_per_mhz_usd = a.price_per_mhz/ds.val_i * cr.value
			a.price_per_mhz = a.price/a.block/ds.val_i,
			a.price_per_mhz_usd = a.price/a.block/ds.val_i * cr.value
			
	
	FROM	auctions a INNER JOIN
			currency_rates cr ON (a.price_currency_id = cr.from_currency_id AND DATEPART(year, a.date) = DATEPART(year, cr.date) AND DATEPART(quarter, a.date) = DATEPART(quarter, cr.date)) LEFT JOIN
			ds_zone_data ds ON (ds.metric_id = 43 AND ds.attribute_id = 0 AND ds.date_type = 'Q' AND a.zone_id = ds.zone_id AND DATEPART(year, a.date) = DATEPART(year, ds.date) AND DATEPART(quarter, a.date) = DATEPART(quarter, ds.date))
	
	WHERE	cr.to_currency_id = 2 AND
			cr.date_type = 'Q'


	-- In many cases, PPP-adjustment rates aren't available for the exact year, so we use the closest rate
	UPDATE	aw
	SET		aw.price_per_mhz_usd_ppp = aw.price_per_mhz_usd/
			(
				SELECT	TOP 1 ds.val_d
				FROM	ds_zone_data ds
				WHERE	ds.zone_id = a.zone_id AND
						ds.metric_id = 175 AND
						ds.attribute_id = 1509 AND
						ds.date_type = 'Y' AND
						ds.date <= a.date
				ORDER BY ds.date DESC
			)
	FROM	auction_awards aw INNER JOIN auctions a ON aw.auction_id = a.id
	WHERE	aw.price_per_mhz_usd IS NOT null

	UPDATE	a
	SET		a.price_per_mhz_usd_ppp = a.price_per_mhz_usd/
			(
				SELECT	TOP 1 ds.val_d
				FROM	ds_zone_data ds
				WHERE	ds.zone_id = a.zone_id AND
						ds.metric_id = 175 AND
						ds.attribute_id = 1509 AND
						ds.date_type = 'Y' AND
						ds.date <= a.date
				ORDER BY ds.date DESC
			)
	FROM	auctions a
	WHERE	a.price_per_mhz_usd IS NOT null
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_spectrum (1s)'

DROP TABLE #calc
