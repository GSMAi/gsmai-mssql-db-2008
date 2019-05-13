
CREATE PROCEDURE [dbo].[api_data]

(
	@q int,
	@show tinyint,
	@zone_id int,
	@zone_ids varchar(max),
	@organisation_id int,
	@organisation_ids varchar(max),
	@currency_id int
)

AS

DECLARE @date_start datetime, @date_end datetime, @date_spot datetime, @date_type char(1), @xml xml 

SET @date_start	= '2000-01-01'
SET @date_end	= '2021-01-01'
SET @date_spot	= dbo.current_reporting_quarter()
SET @date_type	= 'Q'


IF @q = 1
BEGIN
	-- M2M
	IF @show = 2
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	dc_zone_data ds

		WHERE	ds.zone_id = @zone_id AND
				ds.metric_id = 3 AND
				ds.attribute_id = 0 AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END


	IF @show = 3
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value,
				c.iso_code currency_iso_code

		FROM	dc_organisation_data ds INNER JOIN
				organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
				currencies c ON ds.currency_id = c.id

		WHERE	oz.zone_id = @zone_id AND
				ds.metric_id = 3 AND
				ds.attribute_id IN (0,755,796,799,99,822,1251) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END


IF @q = 2
BEGIN
	-- Financials
	IF @show = 2
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	dc_zone_data ds

		WHERE	ds.zone_id = @zone_id AND
				ds.metric_id IN (3,43,286) AND
				ds.attribute_id = 0 AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = CASE ds.metric_id WHEN 286 THEN 'Y' ELSE @date_type END
				
		ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END


	IF @show = 3
	BEGIN
		IF @currency_id IS null
		BEGIN
			-- Local currencies (as reported)
			SELECT	ds.*,
					CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value,
					c.iso_code currency_iso_code

			FROM	ds_organisation_data ds INNER JOIN
					organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
					currencies c ON ds.currency_id = c.id

			WHERE	oz.zone_id = @zone_id AND
					(
						-- Financial metrics only
						(ds.metric_id IN (10,18,29,34,65,66) AND ds.attribute_id IN (0,69,436,826,827,828,834,1518) AND ds.source_id NOT IN (3,22))
					) AND
					ds.date >= @date_start AND
					ds.date < @date_end AND
					ds.date_type = @date_type
				
			ORDER BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
		END
		ELSE
		BEGIN
			-- Currency conversion
			SELECT	ds.*,
					CASE WHEN ds.val_i IS null THEN ds.val_d * cr.value ELSE CAST(ds.val_i * cr.value AS DECIMAL(22,4)) END value,
					c.iso_code currency_iso_code

			FROM	ds_organisation_data ds INNER JOIN
					organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
					currency_rates cr ON ds.currency_id = cr.from_currency_id INNER JOIN
					currencies c ON cr.to_currency_id = c.id

			WHERE	oz.zone_id = @zone_id AND
					(
						(ds.metric_id IN (3,53,162) AND ds.attribute_id IN (0,755,799,1292)) OR
						(ds.metric_id IN (10,18,29,34,65,66) AND ds.attribute_id IN (0,69,436,826,827,828,834,1518) AND ds.source_id NOT IN (3,22)) OR
						(ds.metric_id IN (58,24) AND ds.attribute_id = 0)
					) AND
					ds.date >= @date_start AND
					ds.date < @date_end AND
					ds.date_type = @date_type AND
					cr.date = @date_spot AND -- Spot
					cr.date_type = 'Q' AND
					cr.to_currency_id = @currency_id
				
			ORDER BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
		END
	END
END


IF @q = 3
BEGIN
	-- MMU
	IF @show = 2
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	dc_zone_data ds

		WHERE	ds.zone_id = @zone_id AND
				ds.metric_id IN (1,3) AND
				ds.attribute_id = 0 AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END


	IF @show = 3
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value,
				c.iso_code currency_iso_code

		FROM	dc_organisation_data ds INNER JOIN
				organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
				currencies c ON ds.currency_id = c.id

		WHERE	oz.zone_id = @zone_id AND
				ds.metric_id = 3 AND
				ds.attribute_id = 0 AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END


IF @q = 4
BEGIN
	-- Smartphones (legacy v1 model)
	IF @show = 2
	BEGIN
		IF @zone_ids IS NOT null
		BEGIN
			-- Multiple zone query
			SET @xml = CAST('<a>' + REPLACE(@zone_ids, ',', '</a><a>') + '</a>' AS xml)
			
			SELECT	ds.*,
					CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

			FROM	dc_zone_data ds

			WHERE	ds.zone_id IN (SELECT t.value('.', 'int') value FROM @xml.nodes('/a') as x(t)) AND
					(
						(ds.metric_id = 3 AND ds.attribute_id = 0) OR
						(ds.metric_id = 53 AND ds.attribute_id = 1554)
					) AND
					ds.date >= @date_start AND
					ds.date < @date_end AND
					ds.date_type = @date_type
					
			ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
		END
		ELSE
		BEGIN
			-- Single zone query
			SELECT	ds.*,
					CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

			FROM	dc_zone_data ds

			WHERE	ds.zone_id = @zone_id AND
					ds.metric_id = 3 AND
					ds.attribute_id = 0 AND
					ds.date >= @date_start AND
					ds.date < @date_end AND
					ds.date_type = @date_type
					
			ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
		END
	END


	IF @show = 3
	BEGIN
		SELECT	ds.*,
				CASE ds.metric_id WHEN 184 THEN 53 ELSE ds.metric_id END metric_id,
				CASE ds.metric_id WHEN 184 THEN 1432 ELSE ds.attribute_id END attribute_id,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value,
				c.iso_code currency_iso_code

		FROM	ds_organisation_data ds INNER JOIN
				organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
				currencies c ON ds.currency_id = c.id

		WHERE	oz.zone_id = @zone_id AND
				(
					(ds.metric_id IN (3,53) AND ds.attribute_id = 1432 AND ds.source_id IN (11,20) AND ds.confidence_id = 192) OR	-- Reported smartphone data points
					(ds.metric_id = 53 AND ds.attribute_id = 1554) OR																-- % 3G/4G connections
					(ds.metric_id IN (3,184) AND ds.attribute_id = 0)																-- Total connections, smartphone adoption
				) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END


IF @q = 5
BEGIN
	-- Mobile Internet subscribers
	IF @show = 2
	BEGIN
		SET @xml = CAST('<a>' + REPLACE(@zone_ids, ',', '</a><a>') + '</a>' AS xml)
		
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	dc_zone_data ds

		WHERE	ds.zone_id IN (SELECT t.value('.', 'int') value FROM @xml.nodes('/a') as x(t)) AND
				(
					(ds.metric_id IN (43,322) AND ds.attribute_id = 0) OR
					(ds.metric_id = 3 AND ds.attribute_id IN (0,204,755,796,798,799,1529))
				) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END


IF @q = 6
BEGIN
	-- Vision 2025 data sets
	IF @show = 2
	BEGIN
		SET @date_start	= '2012-01-01'
		SET @date_end	= '2021-01-01'

		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	dc_zone_data ds

		WHERE	(
					(ds.metric_id IN (322,3,18,43) AND ds.attribute_id = 0) OR					-- NEW total subscribers, connections, revenue and population
					(ds.metric_id = 3 AND ds.attribute_id IN (798,796,755,799,1432,1556)) OR	-- Connections by technology generation and smartphone connections
					(ds.metric_id = 190 AND ds.attribute_id IN (1251,1546,1547,1548))			-- Total M2M connections and by generation
				) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type AND
				ds.currency_id IN (0,2) AND
				(ds.is_spot IS null OR ds.is_spot = 1)
				
		ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END


IF @q = 7
BEGIN
	-- Smartphones (v2 model)
	IF @show = 2
	BEGIN
		IF @zone_ids IS NOT null
		BEGIN
			-- Multiple zone query
			SET @xml = CAST('<a>' + REPLACE(@zone_ids, ',', '</a><a>') + '</a>' AS xml)
		
			SELECT	ds.*,
					CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

			FROM	dc_zone_data ds

			WHERE	ds.zone_id IN (SELECT t.value('.', 'int') value FROM @xml.nodes('/a') as x(t)) AND
					(
						(ds.metric_id = 3 AND ds.attribute_id = 0) OR
						(ds.metric_id IN (53) AND ds.attribute_id IN (1432,1554,1555,1556))	-- % smartphones/feature phones/data terminals, 3G/4G
					) AND
					ds.date >= @date_start AND
					ds.date < @date_end AND
					ds.date_type = @date_type
				
			ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
		END
		ELSE
		BEGIN
			-- Single zone query
			SELECT 'Not implemented'
		END
	END


	IF @show = 3
	BEGIN
		SELECT 'Not implemented'
	END
END


IF @q = 8
BEGIN
	SET @date_start	= '2000-01-01'
	SET @date_end	= '2031-01-01'

	-- Subscribers/connections (v4 model)
	IF @show = 2
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	ds_zone_data ds

		WHERE	ds.zone_id = @zone_id AND
				(
					(ds.metric_id IN (43,181) AND ds.attribute_id = 0) OR					-- Population, unique susbcriber penetration
					(ds.metric_id = 305 AND ds.attribute_id = 1581)							-- % internet subscribers
				) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END


IF @q = 9
BEGIN
	SET @date_start	= '2000-01-01'
	SET @date_end	= '2021-01-01'
	
	-- Subscribers/connections raw data (v4 model); used only to build the historic data set
	IF @show = 3
	BEGIN
		SELECT	ds.*,
				CASE WHEN ds.val_i IS null THEN ds.val_d ELSE CAST(ds.val_i AS DECIMAL(22,4)) END value

		FROM	ds_organisation_data ds INNER JOIN
				organisation_zone_link oz ON ds.organisation_id = oz.organisation_id

		WHERE	oz.zone_id = @zone_id AND
				ds.metric_id IN (3,53,190,162) AND
				ds.attribute_id IN (0,283,1251,99,822,603,616,619,621,755,796,799,825,870,929,936,1124,1384,1385,1432,1472,1529,1554,1555,1556) AND
				ds.date >= @date_start AND
				ds.date < @date_end AND
				ds.date_type = @date_type
				
		ORDER BY ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date_type, ds.date
	END
END