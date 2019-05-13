CREATE FUNCTION [dbo].[curve_best_fit_coefficients_only]
(
	@xy_data xy_data READONLY,
	@return_best_fit_only bit = 0
)

-- Variant of curve_best_fit that returns only the coefficients

-- Must match dbo.xy_coefficients (but T-SQL doesn't allow you to return a user-definied data type)
-- See curve_fit_coefficients() for coefficient labels
RETURNS @coefficients TABLE (type char(8), a float, b float, c float, d float, r2 float)

AS

BEGIN
	INSERT INTO @coefficients
	SELECT	'linear', a, b, c, d, r2
	FROM	dbo.curve_fit_coefficients(@xy_data, 'linear')

	INSERT INTO @coefficients
	SELECT	'poly2', a, b, c, d, r2
	FROM	dbo.curve_fit_coefficients(@xy_data, 'poly2')

	INSERT INTO @coefficients
	SELECT	'poly3', a, b, c, d, r2
	FROM	dbo.curve_fit_coefficients(@xy_data, 'poly3')

	INSERT INTO @coefficients
	SELECT	'exp', a, b, c, d, r2
	FROM	dbo.curve_fit_coefficients(@xy_data, 'exp')

	--INSERT INTO @coefficients
	--SELECT	'log', a, b, c, d, r2
	--FROM	dbo.curve_fit_coefficients(@xy_data, 'log')

	INSERT INTO @coefficients
	SELECT	'power', a, b, c, d, r2
	FROM	dbo.curve_fit_coefficients(@xy_data, 'power')

	IF @return_best_fit_only = 1
	BEGIN
		DELETE
		FROM	@coefficients
		WHERE	r2 <> (SELECT MAX(r2) FROM @coefficients)
	END

	RETURN
END
