
CREATE PROCEDURE [dbo].[api_counter]

(
	@technology_id int = 0,
	@zone_id int = 3826
)
	
AS

DECLARE @quarter datetime, @begin bigint, @end bigint, @days_in_quarter int, @is_leap_year bit

SET @quarter			= dbo.current_reporting_quarter()
SET @is_leap_year		= dbo.is_leap_year(DATEPART(year, DATEADD(month, 3, @quarter)))
SET @days_in_quarter	= CASE DATEPART(month, DATEADD(month, 3, @quarter)) WHEN 1 THEN (CASE @is_leap_year WHEN 1 THEN 91 ELSE 90 END) WHEN 4 THEN 91 WHEN 7 THEN 92 WHEN 10 THEN 92 END

SET @begin				= (SELECT TOP 1 val_i FROM dc_zone_data WHERE zone_id = @zone_id AND metric_id = 3 AND attribute_id = @technology_id AND date = @quarter)
SET @end				= (SELECT TOP 1 val_i FROM dc_zone_data WHERE zone_id = @zone_id AND metric_id = 3 AND attribute_id = @technology_id AND date = DATEADD(month, 3, @quarter))

IF @begin > 0 OR @end > 0
BEGIN
	SELECT	z.id zone_id,
			z.name zone,
			t.id technology_id,
			t.name technology,
			@quarter current_quarter,
			@begin [begin],
			@end [end],
			@days_in_quarter days_in_quarter
			
	FROM	zones z, 
			attributes t

	WHERE	z.id = @zone_id AND
			t.id = @technology_id
END
