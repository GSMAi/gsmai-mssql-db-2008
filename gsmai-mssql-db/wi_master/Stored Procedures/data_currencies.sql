
CREATE PROCEDURE [dbo].[data_currencies]

(
	@currency_id int = null,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q'
)

AS

CREATE TABLE #data (id bigint, from_currency_id int, from_currency nvarchar(512) COLLATE DATABASE_DEFAULT, from_currency_iso_code nvarchar(5) COLLATE DATABASE_DEFAULT, to_currency_id int, to_currency nvarchar(512) COLLATE DATABASE_DEFAULT, to_currency_iso_code nvarchar(5) COLLATE DATABASE_DEFAULT, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6))

INSERT INTO #data
SELECT	cr.id,
		cf.id,
		cf.name,
		cf.iso_code,
		ct.id,
		ct.name,
		ct.iso_code,
		cr.date,
		@date_type, -- TODO: cr.date_type
		cr.value

FROM	currency_rates cr INNER JOIN
		currencies cf ON cr.from_currency_id = cf.id INNER JOIN
		currencies ct ON cr.to_currency_id = ct.id

WHERE	ct.id IN (1,2,3,73) AND
		cf.id <> 0 AND
		ct.id = COALESCE(@currency_id, ct.id) AND
		cr.date >= @date_start AND
		cr.date < @date_end AND
		cr.date_type = @date_type

ORDER BY cf.iso_code, ct.id, cr.date


-- Data
SELECT * FROM #data

-- Date combinations
SELECT	DISTINCT 
		date, 
		date_type

FROM	#data

ORDER BY date


DROP TABLE #data
