

CREATE PROCEDURE [dbo].[process_calculate]

AS

DECLARE @current_quarter datetime = dbo.current_reporting_quarter()
DECLARE @next_quarter datetime = dbo.current_calendar_quarter()
DECLARE @next_quarter_if datetime = CASE WHEN (SELECT DATEDIFF(day, @next_quarter, GETDATE())) >= 45 THEN @next_quarter ELSE @current_quarter END

DECLARE @todayObject datetime = GETDATE()

-- Mark calculations as running
DECLARE @is_running bit = (SELECT is_running FROM jobs WHERE id = 1)
UPDATE jobs SET is_running = 1, last_run_started_on = GETDATE(), last_run_finished_on = null, last_run_by = 11770, last_exit_was_error = @is_running WHERE id = 1




----------------------------------
------ Collect data for TEST -----
----------------------------------
DECLARE @zoneForecastDataCount int =	(SELECT count(*) FROM (
											SELECT ds.zone_id 
											FROM wi_master.dbo.ds_zone_data AS ds 
											LEFT JOIN wi_master.dbo.zones AS z ON ds.zone_id=z.id
											WHERE ds.metric_id = 1 and ds.attribute_id = 0 and z.type_id=10 GROUP BY ds.zone_id
										) as A)

----------------------------------
--------- Collection END ---------
----------------------------------





-- Backup DS tables
BEGIN TRY
	EXEC [dbo].[backup_ds_tables] @dateObject = @todayObject
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC backup_ds_tables'
END CATCH  
-- END DS backup --


-- Track markets that have been "upgraded" to the 2017 forecast model (used to ignore certain legacy processes)
-- Commented out by [Alex] this restricts some of the future forecast of being processed
-- EXEC process_update_log_model_versions

-- TODO: rename as aggregate_summed_metric
-- TODO: rename as aggregated_weighted_metric
-- TODO: rename as aggregate_summed_metric_from_zone_data

-- Merge imports from the last 24h with master
BEGIN TRY
	EXEC process_delete_duplicates @debug = 0																				-- Delete any duplicate data points
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC process_delete_duplicates @debug = 0	'
END CATCH  

BEGIN TRY
	EXEC process_merge_data	@debug = 0																						-- Merge imported data with master
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC process_merge_data	@debug = 0	'
END CATCH

BEGIN TRY
	EXEC process_switch_unique_subscribers @debug = 0																		-- Switch draft unique subscribers for live (TODO: remove on full migration to 2017 forecast model)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC process_switch_unique_subscribers @debug = 0'
END CATCH

BEGIN TRY
	EXEC process_update_log_reporting																						-- Update data reporting statistics
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC process_update_log_reporting'
END CATCH

BEGIN TRY
	EXEC process_delete_duplicates @debug = 0																				-- Delete any duplicate data points
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC process_delete_duplicates @debug = 0'
END CATCH

-- Run each individual calculation
BEGIN TRY
	EXEC aggregate_metric_from_zone_data 43, 0, '1980-01-01', '2051-01-01', @debug = 0										-- Population aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_metric_from_zone_data 43, 0, 1980-01-01, 2051-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC process_update_currency_rates '2026-01-01', @current_quarter, @debug = 0											-- Populate "forecast" currency rates with the spot rate
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC process_update_currency_rates 2026-01-01, @current_quarter, @debug = 0'
END CATCH
--TODO: EXEC calculate_normalised_zone_splits 1, 1581, 1576, '2000-01-01', '2021-01-01', @debug = 0						-- Normalise subscribers, mobile internet technology splits against mobile internet

BEGIN TRY
	EXEC calculate_normalised_splits 3, 0, 1, '2000-01-01', '2021-01-01', @debug = 0										-- Normalise connections, tariff splits against total
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_normalised_splits 3, 0, 1, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_normalised_splits 3, 0, 10, '2000-01-01', '2021-01-01', @debug = 0										-- Normalise connections, technology splits against total
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_normalised_splits 3, 0, 10, 2000-01-01, 2021-01-01, @debug = 0	'
END CATCH
--EXEC calculate_normalised_splits 190, 1251, 22, '2000-01-01', '2021-01-01', @debug = 0									-- Normalise connections, M2M tariff splits against M2M
--EXEC calculate_normalised_splits 190, 1251, 23, '2000-01-01', '2021-01-01', @debug = 0									-- Normalise connections, M2M technology splits against M2M

BEGIN TRY
	EXEC calculate_connections_families '2000-01-01', '2021-01-01', @debug = 0												-- Connections, family/generation sums
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_connections_families 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_sum 190, 0, 3, 0, 190, 1251, '2000-01-01', '2021-01-01', @use_null_as_zero = 1, @debug = 0				-- Connections, M2M sum
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_sum 190, 0, 3, 0, 190, 1251, 2000-01-01, 2021-01-01, @use_null_as_zero = 1, @debug = 0'
END CATCH
--EXEC calculate_sum 190, 796, 3, 796, 190, 1546, '2000-01-01', '2021-01-01', @use_null_as_zero = 1, @debug = 0			-- Connections, M2M 2G sum
--EXEC calculate_sum 190, 755, 3, 755, 190, 1547, '2000-01-01', '2021-01-01', @use_null_as_zero = 1, @debug = 0			-- Connections, M2M 3G sum
--EXEC calculate_sum 190, 799, 3, 799, 190, 1548, '2000-01-01', '2021-01-01', @use_null_as_zero = 1, @debug = 0			-- Connections, M2M 4G sum

BEGIN TRY
	EXEC aggregate_connections '2000-01-01', '2021-01-01', @debug = 0														-- Connections aggregation (first pass; ensures aggregates are current in order to apply percentages to absolutes)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_connections 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_absolute_from_percentage 53, 1432, 3, 0, '2000-01-01', '2021-01-01', @debug = 0							-- Smartphones
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_absolute_from_percentage 53, 1432, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_absolute_from_percentage 53, 1556, 3, 0, '2000-01-01', '2021-01-01', @debug = 0							-- Basic/feature phones
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_absolute_from_percentage 53, 1556, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_absolute_from_percentage 53, 1555, 3, 0, '2000-01-01', '2021-01-01', @debug = 0							-- Non-handsets
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_absolute_from_percentage 53, 1555, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_absolute_from_percentage_from_zone_data 53, 1432, 3, 0, '2000-01-01', '2021-01-01', @debug = 0			-- Country-level, smartphones
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_absolute_from_percentage_from_zone_data 53, 1432, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_absolute_from_percentage_from_zone_data 53, 1556, 3, 0, '2000-01-01', '2021-01-01', @debug = 0			-- Country-level, basic/feature phones
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_absolute_from_percentage_from_zone_data 53, 1556, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_absolute_from_percentage_from_zone_data 53, 1555, 3, 0, '2000-01-01', '2021-01-01', @debug = 0			-- Country-level, non-handsets
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_absolute_from_percentage_from_zone_data 53, 1555, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_connections '2000-01-01', '2021-01-01', @debug = 0														-- Connections aggregation (second pass; aggregates the absolutes that were just updated)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_connections 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_mobile_internet_absolute_from_percentage_from_zone_data 305, 1581, 1, 0, '2000-01-01', '2026-01-01', @debug = 0	-- Calculate absolute mobile internet subscribers
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_mobile_internet_absolute_from_percentage_from_zone_data 305, 1581, 1, 0, 2000-01-01, 2026-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_subscribers '2000-01-01', '2026-01-01', @debug = 0														-- Subscriber aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_subscribers 2000-01-01, 2026-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_connections_subscribers '2000-01-01', '2021-01-01', @debug = 0											-- Connections, subscriber calculations
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_connections_subscribers 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 18, 0, '2000-01-01', '2021-01-01', @debug = 0								-- Revenue, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 18, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 18, 826, '2000-01-01', '2021-01-01', @debug = 0								-- Revenue, recurring aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 18, 826, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 18, 834, '2000-01-01', '2021-01-01', @debug = 0								-- Revenue, non-recurring aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 18, 834, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH


BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 187, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Revenue, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 187, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 187, 826, '2000-01-01', '2021-01-01', @debug = 0							-- DRAFT: Revenue, recurring aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 187, 826, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 187, 834, '2000-01-01', '2021-01-01', @debug = 0							-- DRAFT: Revenue, non-recurring aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 187, 834, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 187, 827, '2000-01-01', '2021-01-01', @debug = 0							-- DRAFT: Revenue, voice aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 187, 827, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 187, 828, '2000-01-01', '2021-01-01', @debug = 0							-- DRAFT: Revenue, non-voice aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 187, 828, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 187, 436, '2000-01-01', '2021-01-01', @debug = 0							-- DRAFT: Revenue, data aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_summed_currency_based_metric 187, 436, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 10, 0, 3, 0, '2000-01-01', '2021-01-01', @debug = 0								-- ARPU, blended aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 10, 0, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 10, 99, 3, 0, '2000-01-01', @next_quarter_if, @debug = 0							-- ARPU, prepaid aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 10, 99, 3, 0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 10, 822, 3, 0, '2000-01-01', @next_quarter_if, @debug = 0							-- ARPU, contract aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 10, 822, 3, 0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 10, 827, 3, 0, '2000-01-01', @next_quarter_if, @debug = 0							-- ARPU, voice aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 10, 827, 3, 0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 10, 828, 3, 0, '2000-01-01', @next_quarter_if, @debug = 0							-- ARPU, non-voice aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 10, 828, 3, 0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 10, 436, 3, 0, '2000-01-01', @next_quarter_if, @debug = 0							-- ARPU, data aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 10, 436, 3, 0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH


BEGIN TRY
	EXEC aggregate_currency_based_metric 188, 0, 3, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: ARPU, blended aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 188, 0, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 188, 827, 3, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: ARPU, voice aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 188, 827, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 188, 828, 3, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: ARPU, non-voice aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 188, 828, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_currency_based_metric 188, 436, 3, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: ARPU, data aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 188, 436, 3, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH


BEGIN TRY
	EXEC aggregate_metric_by_division 189, 0, 18, 826, 1, 0, '2000-01-01', '2021-01-01', @debug = 0							-- ARPU, by subscriber, blended calculation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_metric_by_division 189, 0, 18, 826, 1, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_metric_by_division 339, 0, 18, 826, 322, 0, '2000-01-01', '2021-01-01', @debug = 0						-- DRAFT: ARPU, by subscriber, blended calculation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_metric_by_division 339, 0, 18, 826, 322, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH


BEGIN TRY
	EXEC aggregate_metric 19, 0, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0											-- Churn, blended aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_metric 19, 0, 3,  0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_metric 19, 99, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0											-- Churn, prepaid aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_metric 19, 99, 3,  0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH

BEGIN TRY
	EXEC aggregate_metric 19, 822, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0										-- Churn, contract aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_metric 19, 822, 3,  0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH


BEGIN TRY
	EXEC aggregate_currency_based_metric 27, 0, 3, 0, '2000-01-01', @next_quarter_if, @debug = 0							-- SACs aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC aggregate_currency_based_metric 27, 0, 3, 0, 2000-01-01, @next_quarter_if, @debug = 0'
END CATCH



--EXEC calculate_product_quotient_pair 58, 0, 37, 0, 3, 0, '2000-01-01', '2021-01-01', @debug = 0						-- Minutes of use/per user paired calculation
BEGIN TRY
	EXEC calculate_product 59, 0, 3, 0, 19, 0, '2000-01-01', '2021-01-01', @debug = 0										-- Disconnections calculation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_product 59, 0, 3, 0, 19, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_sum 60, 0, 36, 0, 59, 0, '2000-01-01', '2021-01-01', @debug = 0											-- Gross additions calculation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_sum 60, 0, 36, 0, 59, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_moving_mean 57, 0, 10, 0, 37, 0, '2000-01-01', '2021-01-01', @debug = 0									-- Effective price per minute calculation (operators)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_moving_mean 57, 0, 10, 0, 37, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_moving_mean_from_zone_data 57, 0, 10, 0, 37, 0, '2000-01-01', '2021-01-01', @debug = 0					-- Effective price per minute calculation (countries, regions)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_moving_mean_from_zone_data 57, 0, 10, 0, 37, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

--EXEC calculate_product_quotient_pair 58, 0, 37, 0, 3, 0, '2000-01-01', '2021-01-01', @debug = 0						-- SMS/per user paired calculation

BEGIN TRY
	EXEC calculate_difference 65, 0, 18, 0, 29, 0, '2000-01-01', '2021-01-01', @debug = 0									-- Opex calculation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_difference 65, 0, 18, 0, 29, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_difference 66, 0, 29, 0, 34, 0, '2000-01-01', '2021-01-01', @debug = 0									-- Operating free cash flow calculation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_difference 66, 0, 29, 0, 34, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH


BEGIN TRY
	EXEC calculate_moving_mean 52, 0, 34, 0, 18, 0, '2000-01-01', '2021-01-01', @debug = 0									-- Capex/revenue, annual ratio
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_moving_mean 52, 0, 34, 0, 18, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH

BEGIN TRY
	EXEC calculate_moving_mean 67, 0, 65, 0, 18, 0, '2000-01-01', '2021-01-01', @debug = 0									-- Opex/revenue, annual ratio
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'EXEC calculate_moving_mean 67, 0, 65, 0, 18, 0, 2000-01-01, 2021-01-01, @debug = 0'
END CATCH


BEGIN TRY
	EXEC calculate_moving_mean 341, 0, 333, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Capex/revenue, annual ratio
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC calculate_moving_mean 341, 0, 333, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH

BEGIN TRY
	EXEC calculate_moving_mean 342, 0, 334, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Opex/revenue, annual ratio
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC calculate_moving_mean 342, 0, 334, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH


BEGIN TRY
	EXEC calculate_hhi '2000-01-01', '2021-01-01', @debug = 0																-- Herfindahl-Hirschman Index
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC calculate_hhi '2000-01-01', '2021-01-01', @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric 37, 0, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0											-- MoU per connection, blended aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 37, 0, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric 37, 99, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0											-- MoU per connection, prepaid aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 37, 99, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric 37, 822, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0										-- MoU per connection, contract aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 37, 822, 3,  0, '2000-01-01', @next_quarter_if, @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 333, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Capex, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_summed_currency_based_metric 333, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 334, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Opex, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_summed_currency_based_metric 334, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 335, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: EBITDA, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_summed_currency_based_metric 335, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 337, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Net profit, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_summed_currency_based_metric 337, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_summed_currency_based_metric 338, 0, '2000-01-01', '2021-01-01', @debug = 0								-- DRAFT: Operating free cash flow, total aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_summed_currency_based_metric 338, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric 52, 0, 18, 0, '2000-01-01', @next_quarter_if, @debug = 0											-- Capex/revenue, annual aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 52, 0, 18, 0, '2000-01-01', @next_quarter_if, @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric 67, 0, 18, 0, '2000-01-01', @next_quarter_if, @debug = 0											-- Opex/revenue, annual aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 67, 0, 18, 0, '2000-01-01', @next_quarter_if, @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric 30, 0, 18, 0, '2000-01-01', @next_quarter_if, @debug = 0											-- EBITDA margin aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 30, 0, 18, 0, '2000-01-01', @next_quarter_if, @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric 341, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0											-- DRAFT: Capex/revenue aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 341, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric 342, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0											-- DRAFT: Opex/revenue aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 342, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric 336, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0											-- DRAFT: EBITDA margin aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric 336, 0, 187, 0, '2000-01-01', '2021-01-01', @debug = 0"
END CATCH



BEGIN TRY
	EXEC aggregate_metric_by_maximum_minimum 162, 755, '2000-01-01', '2021-01-01', 1, @debug = 0							-- Country-level 3G population coverage aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_by_maximum_minimum 162, 755, '2000-01-01', '2021-01-01', 1, @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric_by_maximum_minimum 162, 799, '2000-01-01', '2021-01-01', 1, @debug = 0							-- Country-level 4G population coverage aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_by_maximum_minimum 162, 799, '2000-01-01', '2021-01-01', 1, @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric_from_zone_data_weighted 162, 755, 43, 0, '2000-01-01', '2021-01-01', @threshold = 0, @debug = 0	-- Regional 3G population coverage aggregation (doesn't require an aggregation threshold!)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_zone_data_weighted 162, 755, 43, 0, '2000-01-01', '2021-01-01', @threshold = 0, @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_zone_data_weighted 162, 799, 43, 0, '2000-01-01', '2021-01-01', @threshold = 0, @debug = 0	-- Regional 4G population coverage aggregation (doesn't require an aggregation threshold!)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_zone_data_weighted 162, 799, 43, 0, '2000-01-01', '2021-01-01', @threshold = 0, @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_groups '2000-01-01', '2021-01-01', 0, @debug = 0															-- Group connections, summed aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_groups '2000-01-01', '2021-01-01', 0, @debug = 0"
END CATCH

BEGIN TRY
	EXEC aggregate_groups '2000-01-01', '2021-01-01', 1, @debug = 0															-- Group connections, proportional aggregation
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_groups '2000-01-01', '2021-01-01', 1, @debug = 0"
END CATCH


BEGIN TRY
	EXEC calculate_world_bank_metrics '1950-01-01', '2021-01-01', @debug = 0												-- World Bank metrics
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC calculate_world_bank_metrics '1950-01-01', '2021-01-01', @debug = 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric_from_service_data 191, 1551, '2000-01-01', '2031-01-01', null, 'Q', 0								-- MMU: Accounts, registered
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 191, 1551, '2000-01-01', '2031-01-01', null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 191, 1552, '2000-01-01', '2031-01-01', null, 'Q', 0								-- MMU: Accounts, 30-day active
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 191, 1552, '2000-01-01', '2031-01-01', null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 191, 1553, '2000-01-01', '2031-01-01', null, 'Q', 0								-- MMU: Accounts, 90-day active
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 191, 1553, '2000-01-01', '2031-01-01', null, 'Q', 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric_from_service_data 192, 1551, '2000-01-01', '2031-01-01', null, 'Q', 0								-- MMU: Agents, registered
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 192, 1551, '2000-01-01', '2031-01-01', null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 192, 1552, '2000-01-01', '2031-01-01', null, 'Q', 0								-- MMU: Agents, 30-day active
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 192, 1552, '2000-01-01', '2031-01-01', null, 'Q', 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1565, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, P2P (domestic)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1565, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1566, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, Airtime top-up
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1566, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1567, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, Bulk payments
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1567, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1568, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, Bill payments
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1568, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1569, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, Merchant payments
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1569, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1570, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, International remittances
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1570, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1571, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, Cash-in
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1571, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 301, 1572, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional volume, Cash-out
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 301, 1572, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH


BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1565, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, P2P (domestic)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1565, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1566, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, Airtime top-up
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1566, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1567, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, Bulk payments
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1567, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1568, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, Bill payments
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1568, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1569, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, Merchant payments
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1569, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1570, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, International remittances
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1570, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1571, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, Cash-in
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1571, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH

BEGIN TRY
	EXEC aggregate_metric_from_service_data 302, 1572, '2000-01-01', @current_quarter, null, 'Q', 0							-- MMU: Transactional value, Cash-out
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "EXEC aggregate_metric_from_service_data 302, 1572, '2000-01-01', @current_quarter, null, 'Q', 0"
END CATCH


BEGIN TRY
	UPDATE ds_zone_data SET currency_id = 2 WHERE metric_id = 302															-- MMU transactional value data set currency correction

	-- Run clean-up, flagging routines

	-- Copy smartphone % of connections into smartphone adoption
	DELETE FROM ds_organisation_data WHERE metric_id = 308 AND attribute_id IN (1432,1579,1580)
	DELETE FROM ds_zone_data WHERE metric_id = 308 AND attribute_id IN (1432,1579,1580)

	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, import_id, created_on, created_by, last_update_on, last_update_by)
	SELECT	organisation_id, 308, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, import_id, created_on, created_by, last_update_on, last_update_by
	FROM	ds_organisation_data
	WHERE	metric_id = 53 AND attribute_id IN (1432,1579,1580)

	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, import_id, created_on, created_by, last_update_on, last_update_by)
	SELECT	zone_id, 308, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, import_id, created_on, created_by, last_update_on, last_update_by
	FROM	ds_zone_data
	WHERE	metric_id = 53 AND attribute_id IN (1432,1579,1580)


	-- Hide operator financial data points from the cache where only modelled sourcing is used
	UPDATE	ds_organisation_data SET privacy_id = 5 WHERE metric_id IN (10,18) AND attribute_id IN (0,826,834)

	UPDATE	ds
	SET		ds.privacy_id = 7
	FROM	ds_organisation_data ds
	WHERE	ds.metric_id IN (10,18) AND ds.attribute_id IN (0,826,834) AND ds.organisation_id NOT IN (SELECT DISTINCT organisation_id FROM ds_organisation_data WHERE metric_id IN (10,18) AND attribute_id IN (0,826,834) AND source_id NOT IN (3,22))

	-- Hide forecast operator-level financial data points
	UPDATE	ds
	SET		ds.privacy_id = 7
	FROM	ds_organisation_data ds
	WHERE	ds.metric_id IN (10,18) AND ds.attribute_id IN (0,826,834) AND (date > @current_quarter OR (date = @current_quarter AND source_id = 3))

	-- Hide operator coverage data points where only modelled sourcing is used
	UPDATE	ds_organisation_data SET privacy_id = 5 WHERE metric_id = 162 AND attribute_id IN (755,799)

	UPDATE	ds
	SET		ds.privacy_id = 7
	FROM	ds_organisation_data ds
	WHERE	ds.metric_id = 162 AND ds.attribute_id = 755 AND ds.organisation_id NOT IN (SELECT DISTINCT organisation_id FROM ds_organisation_data WHERE metric_id = 162 AND attribute_id = 755 AND source_id NOT IN (3,22))

	UPDATE	ds
	SET		ds.privacy_id = 7
	FROM	ds_organisation_data ds
	WHERE	ds.metric_id = 162 AND ds.attribute_id = 799 AND ds.organisation_id NOT IN (SELECT DISTINCT organisation_id FROM ds_organisation_data WHERE metric_id = 162 AND attribute_id = 799 AND source_id NOT IN (3,22))


	-- Update forecast-sourced data points (excluding financials)
	UPDATE ds_organisation_data SET source_id = 22, confidence_id = 873 WHERE date > @current_quarter
	UPDATE ds_group_data SET source_id = 22, confidence_id = 873 WHERE date > @current_quarter
	UPDATE ds_zone_data SET source_id = 22, confidence_id = 873 WHERE date > @current_quarter

	UPDATE ds_organisation_data SET source_id = 5, confidence_id = 194 WHERE date <= @current_quarter AND source_id = 22 and metric_id NOT IN (10, 18, 34)
	UPDATE ds_group_data SET source_id = 5, confidence_id = 194 WHERE date <= @current_quarter AND source_id = 22 and metric_id NOT IN (10, 18, 34)
	UPDATE ds_zone_data SET source_id = 5, confidence_id = 194 WHERE date <= @current_quarter AND source_id = 22
	
	-- For financial metrics 10, 18, 34 change source_id to 3 for current quarter and historical
	UPDATE ds_organisation_data SET source_id = 3, confidence_id = 194 WHERE date <= @current_quarter and metric_id IN (10, 18, 34) and source_id = 22 and confidence_id=873
	UPDATE ds_organisation_data SET source_id = 3, confidence_id = 194 WHERE date <= @current_quarter and metric_id IN (10, 18, 34) and source_id = 5 and confidence_id=194
	UPDATE ds_group_data SET source_id = 3, confidence_id = 194 WHERE date <= @current_quarter and metric_id IN (10, 18, 34) and source_id = 22 and confidence_id=873
	UPDATE ds_group_data SET source_id = 3, confidence_id = 194 WHERE date <= @current_quarter and metric_id IN (10, 18, 34) and source_id = 5 and confidence_id=194
	

	-- Delete pre-2000 technology/tariff aggregates
	DELETE FROM ds_zone_data WHERE metric_id IN (1,3,190,322) AND attribute_id <> 0 AND date < '2000-01-01'


	-- Delete nonsensical MVNO data
	DELETE FROM ds_organisation_data WHERE metric_id IN (41,42,44) AND organisation_id IN (SELECT DISTINCT id FROM organisations WHERE type_id IN (283,1217))

	-- Set the has_data flag in ds_mvnos for those who have operator or group data in the cache
	UPDATE ds_mvnos SET has_data = 0, has_group_data = 0

	UPDATE ds_mvnos SET has_data = 1 WHERE mvno_id IN (SELECT DISTINCT o.id FROM ds_organisation_data ds INNER JOIN organisations o ON ds.organisation_id = o.id WHERE o.type_id = 283)
	UPDATE ds_mvnos SET has_group_data = 1 WHERE mvno_id IN (SELECT DISTINCT mvno_id FROM mvno_group_link WHERE group_id IN (SELECT DISTINCT o.id FROM ds_organisation_data ds INNER JOIN organisations o ON ds.organisation_id = o.id WHERE o.type_id = 1217))


	-- Set calculation run state (using prior @is_running value ensures bad calculation results don't sync until manually cleared)
	UPDATE jobs SET is_running = @is_running, last_run_finished_on = GETDATE(), last_exit_was_error = 0 WHERE id = 1
	
	
	-- PLATFORM TEAM updates
	--update wi_master.dbo.ds_zone_data set val_i=1 where id IN (select zd.id from wi_master.dbo.ds_zone_data as zd
	--where zd.zone_id IN (
	--1,10,41,42,43,80,93,113,137,157,158,236,239,240,305,316,362,372,385,394,399,409,482,500,507,522,523,580,597,598,623,657,726,750,775,828,943,1024,1031,1037,1134,1204,1205,1294,1295,1337,1338,1392,1439,1479,1488,1531,1564,1666,1685,1811,1887,1926,1935,1948,3191,3854,3907
	--)
	--and zd.metric_id in (1, 322) and zd.attribute_id=0
	--and zd.is_spot=0)
	-- END
	

	SELECT 'Finished: process_calculate (42m 13s)'
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "Last batch of queries"
END CATCH







--------------------
------ TESTS -------
--------------------

BEGIN TRY

	DECLARE @testDuplicateOrg int = ( select COUNT(*) from wi_master.dbo.ds_organisation_data where organisation_id IN (SELECT o.id FROM wi_master.dbo.organisations AS o WHERE o.status_id=1310) )
	-- Check if any organisations marked as duplicate have data exposed
		IF @testDuplicateOrg > 0
		BEGIN
			execute [dbo].[collect_errors] @query_string = 'Organisations marked as Duplicate are present in DS'
		END
	--------------------------------------------------------------------

	DECLARE @testZoneForecastDataCount int = (select COUNT(*) FROM (SELECT ds.zone_id FROM wi_master.dbo.ds_zone_data AS ds LEFT JOIN wi_master.dbo.zones AS z ON ds.zone_id=z.id WHERE ds.metric_id = 1 and ds.attribute_id = 0 and z.type_id=10 GROUP BY ds.zone_id) as A)
	-- Check existing country zone data Unique subscribers (Total) is not lower then previous set
		IF @zoneForecastDataCount > @testZoneForecastDataCount
		BEGIN
			DECLARE @message char = 'Zone Data Unique subscribers set is smaller then previoius set of ' + CAST(@zoneForecastDataCount as char)
			execute [dbo].[collect_errors] @query_string = @message
		END
	--------------------------------------------------------------------

END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = "Capturing TESTS failed"
END CATCH




