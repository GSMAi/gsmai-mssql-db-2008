CREATE FUNCTION [dbo].[curve_best_fit]
(
	@xy_data xy_data READONLY,
	@xy_forecasts xy_data READONLY,
	@return_best_fit_only bit = 0
)

-- Returns mapped time series data for given curve fits; to return only the fitted curve formulae, see curve_best_fit_coefficients_only

-- See curve_fit_coefficients() for coefficient labels
RETURNS @ds TABLE (type char(8), x float, y float)

AS

BEGIN
	DECLARE @types iterator, @type char(8), @coefficients xy_coefficients, @xy_coefficients xy_coefficients

	INSERT INTO @types
	SELECT 'linear', 0 UNION ALL
	SELECT 'poly2', 0 UNION ALL
	SELECT 'poly3', 0 UNION ALL
	SELECT 'exp', 0 UNION ALL
	--SELECT 'log', 0 UNION ALL
	SELECT 'power', 0


	WHILE EXISTS (SELECT * FROM @types WHERE processed = 0)
	BEGIN
		SET @type = (SELECT TOP 1 term FROM @types WHERE processed = 0)

		INSERT INTO @xy_coefficients									-- Get coefficients for this type
		SELECT	@type, a, b, c, d, r2
		FROM	dbo.curve_fit_coefficients(@xy_data, @type)

		INSERT INTO @coefficients										-- Keep track of all coefficients (and fit) for all types
		SELECT * FROM @xy_coefficients

		INSERT INTO @ds													-- Get the fitted data set for this type and coefficients
		SELECT	@type, x, y
		FROM	dbo.curve_fit_data(@xy_data, @xy_coefficients, @type)

		IF (SELECT COUNT(x) FROM @xy_forecasts) > 0
		BEGIN
			INSERT INTO @ds												-- Also fit the predicted forecast data set, if passed
			SELECT	@type, x, y
			FROM	dbo.curve_fit_data(@xy_forecasts, @xy_coefficients, @type)
		END

		DELETE FROM @xy_coefficients
		UPDATE @types SET processed = 1 WHERE term = @type
	END


	IF @return_best_fit_only = 1
	BEGIN
		DELETE
		FROM	@ds
		WHERE	type <> (SELECT TOP 1 type FROM @coefficients WHERE r2 = (SELECT MAX(r2) FROM @coefficients))
	END

	RETURN
END
