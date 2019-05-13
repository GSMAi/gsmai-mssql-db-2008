
CREATE PROCEDURE [dbo].[calculate_membership]

(
	@date datetime,
	@date_type char(1) = 'Q',
	@date_spot datetime = null,
	@debug bit = 1
)

AS


DECLARE @tier_currency_id int, @dues_currency_id int, @dues_per_vote decimal(22,4), @vote_cap decimal(22,4)

SET @tier_currency_id	= 2
SET @dues_currency_id	= 3

SET @dues_per_vote		= 875
SET @vote_cap			= 500

IF @date_spot IS null
BEGIN
	SET @date_spot = dbo.current_reporting_quarter()
END


CREATE TABLE #data (organisation_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, connections decimal(22,4), connections_source int, revenue_total decimal(22,4), revenue_total_currency int, revenue_total_fx decimal(22,6), revenue_total_source int, revenue_recurring decimal(22,4), revenue_recurring_currency int, revenue_recurring_fx decimal(22,6), revenue_recurring_source int, arpu decimal(22,4), arpu_currency int, arpu_source int)
CREATE TABLE #metadata (organisation_id int, total_source int, total_source_min int, total_source_max int, recurring_source int, recurring_source_min int, recurring_source_max int)
CREATE TABLE #regional (organisation_id int, mapped_organisation_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, connections decimal(22,4), connections_source int)


IF @debug = 0
BEGIN
	SELECT * FROM gsma.ds_membership_data WHERE date = @date AND date_type = @date_type
END

-- *Specific organisation update
update dbo.organisations SET status_id = 81 where id = 6143;
update dbo.organisations SET status_id = 81 where id = 6211;
update dbo.organisations SET status_id = 81 where id = 5822;
update dbo.organisations SET status_id = 81 where id = 4405;
update dbo.organisations SET status_id = 81 where id = 3677;
update dbo.organisations SET status_id = 81 where id = 6578;
update dbo.organisations SET status_id = 81 where id = 5622;
update dbo.organisations SET status_id = 81 where id = 6154;
update dbo.organisations SET status_id = 81 where id = 6341;
-- *udpate end

-- Populate with connections data set as base data
INSERT INTO #data (organisation_id, date, date_type, connections, connections_source)
SELECT 	d.organisation_id, d.date, d.date_type, d.val_i, d.source_id
FROM 	ds_organisation_data d INNER JOIN organisations o ON d.organisation_id = o.id
WHERE	d.metric_id = 3 AND d.attribute_id = 0 AND d.date >= DATEADD(year, -1, @date) AND d.date <= @date AND d.date_type = @date_type AND o.type_id = 1089

-- Get revenue data set
UPDATE	ds
SET		ds.revenue_total = d.val_i, ds.revenue_total_currency = d.currency_id, ds.revenue_total_source = d.source_id
FROM	ds_organisation_data d INNER JOIN #data ds ON (d.organisation_id = ds.organisation_id AND d.date = ds.date AND d.date_type = ds.date_type)
WHERE	d.metric_id = 18 AND d.attribute_id = 0

-- Get recurring revenue data set
UPDATE	ds
SET		ds.revenue_recurring = d.val_i, ds.revenue_recurring_currency = d.currency_id, ds.revenue_recurring_source = d.source_id
FROM	ds_organisation_data d INNER JOIN #data ds ON (d.organisation_id = ds.organisation_id AND d.date = ds.date AND d.date_type = ds.date_type)
WHERE	d.metric_id = 18 AND d.attribute_id = 826

-- Get ARPU data set
UPDATE	ds
SET		ds.arpu = d.val_d, ds.arpu_currency = d.currency_id, ds.arpu_source = d.source_id
FROM	ds_organisation_data d INNER JOIN #data ds ON (d.organisation_id = ds.organisation_id AND d.date = ds.date AND d.date_type = ds.date_type)
WHERE	d.metric_id = 10 AND d.attribute_id = 0


-- Populate regional connections (India)
INSERT INTO #regional
SELECT 	o.id, null, d.attribute_id, d.date, d.date_type, d.val_i, d.source_id
FROM	ds_organisation_data d INNER JOIN organisations o ON d.organisation_id = o.id
WHERE	d.metric_id = 3 AND d.attribute_id IN (906,907,908,909,910,911,912,913,914,915,916,917,918,919,920,921,922,923,924,925,926,927,1225) AND d.date >= DATEADD(year, -1, @date) AND d.date <= @date AND d.date_type = 'Q' AND o.type_id = 1089

-- Airtel (Bharti)
UPDATE #regional SET mapped_organisation_id = 4405 WHERE organisation_id = 47 AND attribute_id IN (917,924)
UPDATE #regional SET mapped_organisation_id = 4804 WHERE organisation_id = 47 AND attribute_id IN (906,907,908,909,910,911,912,913,914,915,916,918,919,920,921,922,923,925,927,1225)

-- Populate regional connections sums
INSERT INTO #data (organisation_id, date, date_type, connections, connections_source)
SELECT	mapped_organisation_id, date, date_type, SUM(connections), MAX(connections_source)
FROM	#regional
WHERE	mapped_organisation_id IS NOT null
GROUP BY mapped_organisation_id, date, date_type

-- Weight regional operators' revenue by their national parents' total
UPDATE	ds

SET		ds.revenue_total = ds.connections / d.connections * d.revenue_total,
		ds.revenue_recurring = ds.connections / d.connections * d.revenue_recurring,
		ds.arpu = d.arpu,
		
		ds.revenue_total_currency = d.revenue_total_currency,
		ds.revenue_recurring_currency = d.revenue_recurring_currency,
		ds.arpu_currency = d.arpu_currency,

		ds.revenue_total_source = 5,
		ds.revenue_recurring_source = 5,
		ds.arpu_source = d.arpu_source

FROM	#data ds INNER JOIN (SELECT DISTINCT organisation_id, mapped_organisation_id FROM #regional) r ON ds.organisation_id = r.mapped_organisation_id INNER JOIN #data d ON r.organisation_id = d.organisation_id

WHERE	ds.date = d.date AND ds.date_type = d.date_type

IF @debug = 1
BEGIN
	SELECT * FROM #data WHERE organisation_id IN (47,4405,4804)
	SELECT * FROM #regional
END

-- Remove the original national operators for regional subsidaries
-- [Removed by Alex - as requested by Jon Groves to expose the org 47]
-- DELETE FROM #data WHERE organisation_id = 47


-- Add recurring revenue estimates from operator ARPU
UPDATE #data SET revenue_recurring = connections * arpu * 3, revenue_recurring_currency = arpu_currency, revenue_recurring_source = 5 WHERE revenue_total IS null AND revenue_recurring IS null AND arpu IS NOT null

-- Fix mixed-currency issues, honour most recent currency
/*UPDATE	ds
SET		ds.?
FROM	#data ds INNER JOIN
		(
			SELECT	organisation_id, revenue_total_currency, RANK() OVER (PARTITION BY organisation_id, date ORDER BY date DESC) rank
			FROM	#data
			WHERE	revenue_total_currency IS NOT null
		) c
WHERE	c.rank = 1*/

-- Cross update revenue with historical exchange rates per quarter
UPDATE	ds
SET		ds.revenue_total_fx = cr.value
FROM	currency_rates cr INNER JOIN #data ds ON (ds.revenue_total_currency = cr.from_currency_id AND ds.date = cr.date AND ds.date_type = cr.date_type)
WHERE	cr.to_currency_id = @tier_currency_id

UPDATE	ds
SET		ds.revenue_recurring_fx = cr.value
FROM	currency_rates cr INNER JOIN #data ds ON (ds.revenue_recurring_currency = cr.from_currency_id AND ds.date = cr.date AND ds.date_type = cr.date_type)
WHERE	cr.to_currency_id = @tier_currency_id

-- Establish the correct sourcing to use for each operator
INSERT INTO #metadata
SELECT	organisation_id,
		null,
		MIN(revenue_total_source),
		MAX(revenue_total_source),
		null,
		MIN(revenue_recurring_source),
		MAX(revenue_recurring_source)
FROM	#data
WHERE	revenue_total IS NOT null OR revenue_recurring IS NOT null
GROUP BY organisation_id

UPDATE #metadata SET total_source = total_source_min WHERE total_source_min = total_source_max
UPDATE #metadata SET total_source = 20 WHERE total_source_min = 11 AND total_source_max = 20
UPDATE #metadata SET total_source = 5 WHERE total_source IS null
UPDATE #metadata SET recurring_source = recurring_source_min WHERE recurring_source_min = recurring_source_max
UPDATE #metadata SET recurring_source = 20 WHERE recurring_source_min = 11 AND recurring_source_max = 20
UPDATE #metadata SET recurring_source = 5 WHERE recurring_source IS null


IF @debug = 1
BEGIN
	SELECT 'Revenue data points with missing FX rates:'
	SELECT * FROM #data WHERE (revenue_total IS NOT null and revenue_total_fx IS null) OR (revenue_recurring IS NOT null and revenue_recurring_fx IS null)
END

IF @debug = 0
BEGIN
	-- Take a revision of this data
	DECLARE @revision_id int, @revision datetime

	SET @revision 		= GETDATE()
	SET @revision_id	= (SELECT MAX(revision_id) FROM wi_revisions.gsma.ds_membership_data) + 1

	INSERT INTO wi_revisions.gsma.ds_membership_data (revision_id, revision, organisation_id, group_id, date, date_type, connections, connections_source, connections_tier, revenue, revenue_currency, revenue_source, revenue_attribute, revenue_normalised, revenue_tier, tier, votes, votes_adjusted, dues, dues_adjusted, dues_currency, is_member, is_special_case, created_on, created_by, last_update_on, last_update_by)
	SELECT	@revision_id, @revision, organisation_id, group_id, date, date_type, connections, connections_source, connections_tier, revenue, revenue_currency, revenue_source, revenue_attribute, revenue_normalised, revenue_tier, tier, votes, votes_adjusted, dues, dues_adjusted, dues_currency, is_member, is_special_case, created_on, created_by, last_update_on, last_update_by
	FROM	gsma.ds_membership_data
	WHERE	date = @date AND date_type = @date_type

	-- Remove existing data set for this period
	DELETE FROM gsma.ds_membership_data WHERE date = @date


	-- Repopulate the data set from these calculations
	INSERT INTO gsma.ds_membership_data (organisation_id, date, date_type, connections, connections_source)
	SELECT	organisation_id, date, date_type, connections, connections_source
	FROM	#data
	WHERE	date = @date
	
	
	-- Now populate revenue... prefer recurring revenue first for the period (n-3)–n quarters (and excluding any figures from country/region/world ARPU at this stage; source > 0)
	UPDATE	ds
	SET		ds.revenue = d.revenue, ds.revenue_normalised = d.revenue_normalised, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -9, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 4
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	-- Or the (n-4)–(n-1) period if n has yet to be reported
	UPDATE	ds
	SET		ds.revenue = d.revenue, ds.revenue_normalised = d.revenue_normalised, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= DATEADD(month, -3, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 4
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	-- Then either the (n-1)–n or (n-2)–(n-1) or (n-3)–(n-2) or (n-4)–(n-3) period (HY) multiplied by two (prefer more recent data)
	UPDATE	ds
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -3, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -6, @date) AND date <= DATEADD(month, -3, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -9, @date) AND date <= DATEADD(month, -6, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= DATEADD(month, -9, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	-- If all else, still prefer any single quarterly recurring revenue multiplied by four
	UPDATE	ds
	SET		ds.revenue = d.revenue * 4, ds.revenue_normalised = d.revenue_normalised * 4, ds.revenue_source = 5, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, SUM(revenue_recurring * revenue_recurring_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 1
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	
	-- Then use the same four rules for total revenue instead of recurring
	UPDATE	ds -- FY
	SET		ds.revenue = d.revenue, ds.revenue_normalised = d.revenue_normalised, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -9, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 4
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- FY from n-1 quarter
	SET		ds.revenue = d.revenue, ds.revenue_normalised = d.revenue_normalised, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= DATEADD(month, -3, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 4
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- HY * 2
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -3, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- HY * 2
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -6, @date) AND date <= DATEADD(month, -3, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- HY * 2
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -9, @date) AND date <= DATEADD(month, -6, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- HY * 2
	SET		ds.revenue = d.revenue * 2, ds.revenue_normalised = d.revenue_normalised * 2, ds.revenue_source = 5, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= DATEADD(month, -9, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 2
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- Q * 4
	SET		ds.revenue = d.revenue * 4, ds.revenue_normalised = d.revenue_normalised * 4, ds.revenue_source = 5, ds.revenue_attribute = 0
	FROM	(
				SELECT	organisation_id, SUM(revenue_total) revenue, SUM(revenue_total * revenue_total_fx) revenue_normalised
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_total) = 1
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	
	-- Add source information for fully reported data
	UPDATE	ds
	SET		ds.revenue_source = CASE ds.revenue_attribute WHEN 0 THEN m.total_source WHEN 826 THEN m.recurring_source ELSE 5 END
	FROM	#metadata m INNER JOIN gsma.ds_membership_data ds ON m.organisation_id = ds.organisation_id
	WHERE	ds.revenue IS NOT null AND ds.revenue_source IS null AND ds.date = @date
END


-- Nullify revenue data set for operators using country/region/global ARPU revenue approximations
UPDATE #data SET revenue_total = null, revenue_total_currency = null, revenue_total_fx = null, revenue_total_source = null, revenue_recurring = null, revenue_recurring_currency = null, revenue_recurring_fx = null, revenue_recurring_source = null, arpu = null, arpu_currency = null, arpu_source = null

-- Get country ARPU data set
UPDATE	ds
SET		ds.arpu = d.val_d, ds.arpu_currency = d.currency_id, ds.arpu_source = -1
FROM	ds_zone_data d INNER JOIN organisation_zone_link oz ON d.zone_id = oz.zone_id INNER JOIN #data ds ON (oz.organisation_id = ds.organisation_id AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	d.metric_id = 10 AND d.attribute_id = 0 AND ds.arpu IS null AND ds.revenue_recurring IS null AND d.currency_id = @tier_currency_id AND d.is_spot = 0

UPDATE #data SET revenue_recurring = connections * arpu * 3, revenue_recurring_currency = arpu_currency, revenue_recurring_source = arpu_source WHERE revenue_recurring IS null AND arpu IS NOT null

-- Get regional ARPU data set
UPDATE	ds
SET		ds.arpu = d.val_d, ds.arpu_currency = d.currency_id, ds.arpu_source = -2
FROM	ds_zone_data d INNER JOIN zone_link zl ON d.zone_id = zl.zone_id INNER JOIN zone_link zl2 ON zl.subzone_id = zl2.zone_id INNER JOIN organisation_zone_link oz ON zl2.subzone_id = oz.zone_id INNER JOIN #data ds ON (oz.organisation_id = ds.organisation_id AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	d.metric_id = 10 AND d.attribute_id = 0 AND ds.arpu IS null AND ds.revenue_recurring IS null AND d.currency_id = @tier_currency_id AND d.is_spot = 0 AND d.zone_id BETWEEN 3908 AND 3912

UPDATE #data SET revenue_recurring = connections * arpu * 3, revenue_recurring_currency = arpu_currency, revenue_recurring_source = arpu_source WHERE revenue_recurring IS null AND arpu IS NOT null

-- Get global ARPU data set
UPDATE	ds
SET		ds.arpu = d.val_d, ds.arpu_currency = d.currency_id, ds.arpu_source = -3
FROM	ds_zone_data d INNER JOIN zone_link zl ON d.zone_id = zl.zone_id INNER JOIN organisation_zone_link oz ON zl.subzone_id = oz.zone_id INNER JOIN #data ds ON (oz.organisation_id = ds.organisation_id AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	d.metric_id = 10 AND d.attribute_id = 0 AND ds.arpu IS null AND ds.revenue_recurring IS null AND d.currency_id = @tier_currency_id AND d.is_spot = 0 AND d.zone_id = 3826

UPDATE #data SET revenue_recurring = connections * arpu * 3, revenue_recurring_currency = arpu_currency, revenue_recurring_source = arpu_source WHERE revenue_recurring IS null AND arpu IS NOT null


IF @debug = 1
BEGIN
	SELECT 'All data:'
	SELECT * FROM #data ORDER BY organisation_id
END

IF @debug = 0
BEGIN
	-- Overwrite calculations with any (private) imported data
	UPDATE	ds
	SET		ds.connections = ds2.connections, ds.connections_source = ds2.connections_source, ds.revenue = ds2.revenue, ds.revenue_source = ds2.revenue_source, ds.revenue_currency = ds2.revenue_currency, ds.revenue_attribute = ds2.revenue_attribute, ds.revenue_normalised = ds2.revenue_normalised
	FROM	gsma.ds_membership_data ds INNER JOIN wi_import.gsma.ds_membership_data ds2 ON (ds.organisation_id = ds2.organisation_id AND ds.date = ds2.date AND ds.date_type = ds2.date_type)
	WHERE	ds.date = @date


	-- Use country/region/global ARPU revenue estimates for operators without any revenue data
	UPDATE	ds -- (n-3)–n period
	SET		ds.revenue = d.revenue, ds.revenue_normalised = d.revenue, ds.revenue_source = d.source, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, MIN(revenue_recurring_source) source -- Potential for mixed global, regional, country ARPU; set worse-case source
				FROM	#data
				WHERE	date >= DATEADD(month, -9, @date) AND date <= @date
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 4
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date
	
	UPDATE	ds -- (n-4)–(n-1) period
	SET		ds.revenue = d.revenue, ds.revenue_normalised = d.revenue, ds.revenue_source = d.source, ds.revenue_attribute = 826
	FROM	(
				SELECT	organisation_id, SUM(revenue_recurring) revenue, MIN(revenue_recurring_source) source
				FROM	#data
				WHERE	date >= DATEADD(month, -12, @date) AND date <= DATEADD(month, -3, @date)
				GROUP BY organisation_id HAVING COUNT(revenue_recurring) = 4
			) d INNER JOIN gsma.ds_membership_data ds ON ds.organisation_id = d.organisation_id
	WHERE	ds.revenue IS null AND ds.date = @date

	
	-- Add regulators
	INSERT INTO gsma.ds_membership_data (organisation_id, date, date_type, connections, connections_source, revenue_source)
	SELECT	o.id, @date, @date_type, null, 1227, 1227
	FROM	organisations o
	WHERE	o.type_id = 1227 AND o.status_id = 0 AND o.id NOT IN (SELECT organisation_id FROM gsma.ds_membership_data WHERE date = @date AND date_type = @date_type)
	
	-- Add operators from USA 'Other'
	INSERT INTO gsma.ds_membership_data (organisation_id, date, date_type, connections, connections_source, revenue_source)
	SELECT	DISTINCT o.id, @date, @date_type, null, 836, 836
	FROM	gsma.ic_organisation_link ic INNER JOIN organisations o ON ic.organisation_id = o.id
	WHERE	ic.mapped_organisation_id = 901 AND o.status_id IN (0,1309) AND o.id NOT IN (SELECT organisation_id FROM gsma.ds_membership_data WHERE date = @date AND date_type = @date_type)
	
	-- Add operators that aren't yet merged in Infocentre
	INSERT INTO gsma.ds_membership_data (organisation_id, date, date_type, connections, connections_source, revenue_source, is_special_case)
	SELECT	ic.organisation_id, @date, @date_type, ds.value, CASE WHEN ds.source IS null THEN 85 ELSE ds.source END, 85, 1
	FROM	gsma.ic_organisation_link ic LEFT JOIN
			(
				SELECT 	o.id organisation_id, d.date, d.val_i value, d.source_id source, RANK() OVER (PARTITION BY o.id ORDER BY d.date DESC) rank
				FROM 	ds_organisation_data d INNER JOIN organisations o ON d.organisation_id = o.id
				WHERE	d.metric_id = 3 AND d.attribute_id = 0 AND d.date_type = @date_type AND o.id IN (SELECT organisation_id FROM gsma.ic_organisation_link WHERE is_member = 1 AND is_special_case = 1)
			) ds ON (ic.organisation_id = ds.organisation_id AND ds.rank = 1)
	WHERE	ic.is_member = 1 AND ic.is_special_case = 1 AND ic.organisation_id NOT IN (SELECT organisation_id FROM gsma.ds_membership_data WHERE date = @date)

	-- Add any (private) imported data due to delayed Infocentre mergers
	UPDATE	ds
	SET		ds.connections			= CASE WHEN ds2.connections IS NOT null THEN ds2.connections ELSE ds.connections END,
			ds.connections_source	= CASE WHEN ds2.connections IS NOT null THEN ds2.connections_source ELSE ds.connections_source END,
			ds.revenue				= CASE WHEN ds2.revenue IS NOT null THEN ds2.revenue ELSE ds.revenue END,
			ds.revenue_source		= CASE WHEN ds2.revenue IS NOT null THEN ds2.revenue_source ELSE ds.revenue_source END,
			ds.revenue_currency		= CASE WHEN ds2.revenue IS NOT null THEN ds2.revenue_currency ELSE ds.revenue_currency END,
			ds.revenue_attribute	= CASE WHEN ds2.revenue IS NOT null THEN ds2.revenue_attribute ELSE ds.revenue_attribute END,
			ds.revenue_normalised	= CASE WHEN ds2.revenue IS NOT null THEN ds2.revenue_normalised ELSE ds.revenue_normalised END
	FROM	gsma.ds_membership_data ds INNER JOIN wi_import.gsma.ds_membership_data ds2 ON (ds.organisation_id = ds2.organisation_id AND ds.date = ds2.date AND ds.date_type = ds2.date_type)
	WHERE	ds.date = @date AND ds.is_special_case = 1
	
	-- Add "missing" operators
	INSERT INTO gsma.ds_membership_data (organisation_id, date, date_type, connections, connections_source, revenue_source)
	SELECT	o.id, @date, @date_type, null, 1308, 1308
	FROM	organisations o
	WHERE	o.type_id = 1089 AND o.status_id = 1308 AND o.id NOT IN (SELECT organisation_id FROM gsma.ds_membership_data WHERE date = @date AND date_type = @date_type)
	
	-- Add planned operators
	INSERT INTO gsma.ds_membership_data (organisation_id, date, date_type, connections, connections_source, revenue, revenue_source, revenue_attribute, revenue_normalised)
	SELECT	o.id, @date, @date_type, 0, 81, 0, 81, 0, 0
	FROM	organisations o
	WHERE	o.status_id = 81 AND o.type_id = 1089 AND o.id NOT IN (SELECT organisation_id FROM gsma.ds_membership_data WHERE date = @date AND date_type = @date_type)

	-- Finally, add operators that launch _after_ Q3, but are no longer planned!
	-- ...

	
	-- Round data to the nearest unit
	UPDATE gsma.ds_membership_data SET connections = ROUND(connections, 0)
	UPDATE gsma.ds_membership_data SET revenue = ROUND(revenue, 0)
	UPDATE gsma.ds_membership_data SET revenue_normalised = ROUND(revenue_normalised, 0)
	
	
	-- Set connections tier
	UPDATE gsma.ds_membership_data SET connections_tier = null WHERE date = @date AND date_type = @date_type
	
	UPDATE gsma.ds_membership_data SET connections_tier = 0 WHERE connections >= 200000000 AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 1 WHERE connections >= 125000000 AND connections_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 2 WHERE connections >=  75000000 AND connections_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 3 WHERE connections >=  35000000 AND connections_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 4 WHERE connections >=  15000000 AND connections_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 5 WHERE connections >=   5000000 AND connections_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 6 WHERE connections >=   1000000 AND connections_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET connections_tier = 7 WHERE connections_tier IS null AND date = @date AND date_type = @date_type
	
	-- Set revenue tier
	UPDATE gsma.ds_membership_data SET revenue_tier = null WHERE date = @date AND date_type = @date_type
	
	UPDATE gsma.ds_membership_data SET revenue_tier = 0 WHERE revenue_normalised >= 25000000000 AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 1 WHERE revenue_normalised >= 15000000000 AND revenue_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 2 WHERE revenue_normalised >= 10000000000 AND revenue_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 3 WHERE revenue_normalised >=  6000000000 AND revenue_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 4 WHERE revenue_normalised >=  4000000000 AND revenue_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 5 WHERE revenue_normalised >=  2000000000 AND revenue_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 6 WHERE revenue_normalised >=  1000000000 AND revenue_tier IS null AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET revenue_tier = 7 WHERE revenue_tier IS null AND date = @date AND date_type = @date_type
	
	-- Set tier, votes, dues
	UPDATE gsma.ds_membership_data SET tier  = CASE WHEN connections_tier < revenue_tier THEN connections_tier ELSE revenue_tier END WHERE date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET votes = CASE tier WHEN 0 THEN 500 WHEN 1 THEN 230 WHEN 2 THEN 155 WHEN 3 THEN 95 WHEN 4 THEN 60 WHEN 5 THEN 30 WHEN 6 THEN 15 ELSE 10 END WHERE date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET dues  = votes * @dues_per_vote, dues_currency = @dues_currency_id WHERE date = @date AND date_type = @date_type	-- WIR008
	
	-- Mark members/non-members
	UPDATE	ds
	SET		ds.is_member = CASE WHEN ic.is_member IS null THEN 0 ELSE ic.is_member END
	FROM	gsma.ds_membership_data ds LEFT JOIN (SELECT * FROM gsma.ic_organisation_link WHERE is_member = 1) ic ON ds.organisation_id = ic.organisation_id -- Avoid joining on multiple entries for is_member = 0 and 1
	WHERE	ds.date = @date AND ds.date_type = @date_type

	-- Mark membership for those currently considered to be regional
	UPDATE gsma.ds_membership_data SET is_member = 1 WHERE date = @date AND date_type = @date_type AND organisation_id IN (47)
	
	-- Set group affinity (require economic ownership of 50% plus one share)
	UPDATE	ds
	SET		ds.group_id = w.group_id
	FROM	(
				SELECT	organisation_id, group_id, RANK() OVER (PARTITION BY organisation_id, date, date_type ORDER BY value DESC) rank
				FROM	ds_group_ownership
				WHERE	date = @date AND date_type = @date_type AND (value > 0.5 OR is_consolidated = 1) -- Majority ownership
		 	) w INNER JOIN gsma.ds_membership_data ds ON w.organisation_id = ds.organisation_id
	WHERE	ds.date = @date AND ds.date_type = @date_type AND w.rank LIKE 
	CASE WHEN (w.organisation_id = 464) THEN 2 ELSE 1 END

	-- TODO: Compound exclusions via group_id NOT IN (920,922,923,1441,1455,2094,4497,5283)
	
	-- Set group affinity for regional operators
	UPDATE	ds
	SET		ds.group_id = w.group_id
	FROM	(
				SELECT	ic.organisation_id, w.group_id, RANK() OVER (PARTITION BY w.organisation_id, w.date, w.date_type ORDER BY w.value DESC) rank
				FROM	ds_group_ownership w INNER JOIN gsma.ic_organisation_link ic ON w.organisation_id = ic.mapped_organisation_id
				WHERE	ic.mapped_organisation_id IN (47) AND w.date = @date AND w.date_type = @date_type AND (w.value > 0.5 OR w.is_consolidated = 1) -- Majority ownership
			) w INNER JOIN gsma.ds_membership_data ds ON w.organisation_id = ds.organisation_id
	WHERE	ds.date = @date AND ds.date_type = @date_type AND w.rank = 1

	-- "Fix" regional operators so their votes only count for the equivalent of a single merged entity (TODO: programatic update based on current parent figures)

	-- Airtel (Bharti)
	UPDATE gsma.ds_membership_data SET votes = 21 WHERE organisation_id = 4405 AND date = @date AND date_type = @date_type
	UPDATE gsma.ds_membership_data SET votes = 209 WHERE organisation_id = 4804 AND date = @date AND date_type = @date_type

	
	-- Finally, impose a group cap of 500 votes by weighting their subsidaries and adjusting for the delta
	UPDATE	ds
	SET		ds.votes_adjusted = FLOOR(CAST(ds.votes AS decimal(22,4)) * @vote_cap/v.sum_votes) -- Floor here to arrive under the @vote_cap
	FROM	(
				SELECT	group_id, CAST(SUM(votes) AS decimal(22,4)) sum_votes
				FROM	gsma.ds_membership_data
				WHERE	date = @date AND date_type = @date_type AND is_member = 1
				GROUP BY group_id HAVING SUM(votes) > @vote_cap
			) v INNER JOIN gsma.ds_membership_data ds ON (v.group_id = ds.group_id)
	WHERE	ds.date = @date AND ds.date_type = @date_type AND ds.group_id IS NOT null
	
	UPDATE	ds
	SET		ds.votes_adjusted = ds.votes_adjusted + 1 -- Add one vote...
	FROM	gsma.ds_membership_data ds INNER JOIN
			(
				SELECT	organisation_id, group_id, RANK() OVER (PARTITION BY group_id ORDER BY connections DESC) rank
				FROM	gsma.ds_membership_data
				WHERE	date = @date AND date_type = @date_type AND group_id IS NOT null AND is_member = 1
			) r ON (ds.group_id = r.group_id AND ds.organisation_id = r.organisation_id) INNER JOIN
			(
				SELECT	group_id, SUM(votes_adjusted) sum_votes, @vote_cap - SUM(votes_adjusted) deficit_votes
				FROM	gsma.ds_membership_data
				WHERE	date = @date AND date_type = @date_type AND group_id IS NOT null AND is_member = 1
				GROUP BY group_id HAVING SUM(votes) > @vote_cap AND SUM(votes_adjusted) <> @vote_cap
			) v ON (r.group_id = v.group_id AND r.rank <= v.deficit_votes) -- ... to each of the largest subsidaries up to a limit equal to the current deficit from @vote_cap
	WHERE	ds.date = @date AND ds.date_type = @date_type
	
	UPDATE gsma.ds_membership_data SET dues_adjusted = votes_adjusted * @dues_per_vote WHERE votes_adjusted IS NOT null AND date = @date AND date_type = @date_type

	
	-- *Specific organisation update
	update dbo.organisations SET status_id = 0 where id = 6143;
	update dbo.organisations SET status_id = 0 where id = 6211;
	update dbo.organisations SET status_id = 0 where id = 5822;
	update dbo.organisations SET status_id = 1309 where id = 4405;
	update dbo.organisations SET status_id = 0 where id = 3677;
	update dbo.organisations SET status_id = 0 where id = 6578;
	update dbo.organisations SET status_id = 0 where id = 5622;
	update dbo.organisations SET status_id = 0 where id = 6154;
	update dbo.organisations SET status_id = 0 where id = 6341;
	-- *udpate end
	
	-- *Specific organisation delete (deleting international organisations)
	delete from gsma.ds_membership_data where organisation_id IN (6322, 4776, 3281);
	-- *delete end


END

SELECT 'Done'

DROP TABLE #data
DROP TABLE #metadata
DROP TABLE #regional
