
CREATE FUNCTION [dbo].[curve_fit_polynomial_coefficients]
(
        @xy_data xy_data READONLY,
		@order int = null
)

RETURNS @p TABLE (power_x int, coefficient float, r2 float)

AS
BEGIN
	-- Step 1: Convert @xy_data into a matrix
	DECLARE @matrix TABLE (m_row int, m_col int, m_value float)
	DECLARE @r int = 0, @c int = 0

	IF @order > 0
	BEGIN
		-- Find the optimal solution for a polynomial fit of order n = @order
		WHILE @r <= @order
		BEGIN
			SET @c = 0

			WHILE @c <= @order
			BEGIN
				-- Create an n x n matrix for this order
				INSERT INTO @matrix
				SELECT	@r, @c, (SELECT SUM(POWER(x, @c + @r)) FROM @xy_data)		-- SUM(x^n) as row, column iterator

				SET @c = @c + 1

				IF @c > @order
				BEGIN
					-- Append y values as column n
					INSERT INTO @matrix
					SELECT @r, @c, (SELECT SUM(POWER(x, @r) * y) FROM @xy_data)		-- SUM(x^n) * y as row, column iterator (appended, but treated as prepend logic of @c = 0 to avoid matrix transforms below)
				END
			END

			SET @r = @r + 1
		END
	END
	ELSE
	BEGIN
		-- Else, find the optimal solution for a polynomial of order n = @total_points (ie perfect fit polynomial)
		DECLARE @total_points int = (SELECT COUNT(1) FROM @xy_data);

		WITH num_projection(current_number) AS
		(
				SELECT 1
				UNION ALL
				SELECT 1+current_number FROM num_projection WHERE current_number < @total_points
		)
        
		INSERT INTO @matrix
		SELECT	seq-1,									-- Single row per point
				np.current_number-1,					-- Column per power of x
				CASE
					WHEN np.current_number = 1 THEN 1	-- First column is always x^0 = 1
					ELSE POWER(x, np.current_number-1)  -- Raise nth column to power n-1
				END
		FROM	num_projection np,						-- Cross join numeric point data and column indexes
				(
					SELECT  ROW_NUMBER() OVER (ORDER BY x, y) seq, x, y
					FROM    @xy_data
				) vals;

		-- Append y values as nth column
		INSERT INTO @matrix
		SELECT  ROW_NUMBER() OVER (ORDER BY x, y) - 1 seq, @total_points, y
		FROM    @xy_data
	END

	-- Step 2: Compute row echelon form of matrix
	DECLARE @lead int = 0, @index int = 0, @current float

	DECLARE @rows int = (SELECT MAX(m_row) FROM @matrix)
	DECLARE @cols int = (SELECT MAX(m_col) FROM @matrix)
        
	DECLARE @solved int	-- 0 = unsolvable #sadface, 1 = solved #party

	SET @r = 0
	WHILE @r <= @rows
	BEGIN
			IF @cols <= @lead
			BEGIN
				-- Cannot solve this one
				SET @solved = 0
				BREAK
			END

			SET @index = @r

			-- Determine if any row swaps are needed.
			WHILE (SELECT m_value FROM @matrix WHERE m_row = @index AND m_col = @lead) = 0
					BEGIN
						SET @index = @index + 1
						IF @rows = @index
						BEGIN
							SET @index = @r
							SET @lead = @lead + 1
							IF @cols = @lead
								BEGIN
									-- Cannot solve
									SET @solved = 0
									BREAK
								END
						END
					END

			-- Move this row to the correct position if needed.
			IF @index <> @r
			BEGIN
				-- Swap rows
				UPDATE @matrix
				SET m_row = CASE m_row
								WHEN @r THEN @index
								WHEN @index THEN @r
							END
				WHERE m_row IN (@index, @r)
			END

			-- Divide this row by its lead column value, so that the row's lead is 1 (this will actually multiply/increase the value if lead < 0)
			DECLARE @divisor float = (SELECT m_value FROM @matrix WHERE m_row = @r AND m_col = @lead)
			If @divisor <> 1
			BEGIN
				UPDATE @matrix SET m_value = m_value / @divisor WHERE m_row = @r
			END

			-- Update other rows and divide them by the appropriate multiple of this row in order to zero the current lead column.
			UPDATE  i
			SET     m_value = i.m_value - (m.m_value * r.m_value)
			FROM    @matrix i INNER JOIN
					@matrix m ON m.m_row = i.m_row AND m.m_col = @lead INNER JOIN
					@matrix r ON r.m_col = i.m_col AND r.m_row = @r AND r.m_row <> i.m_row

			SET @lead = @lead + 1

			-- Move to next
			SET @r = @r + 1
	END

	-- If we didn't BREAK, @matrix has a solution
	IF @solved IS null
	BEGIN
		SET @solved = 1
	END


	-- Step 3: Produce coefficients list (final column in ref)
	IF @solved = 1
	BEGIN
		INSERT INTO @p (power_x, coefficient, r2)
		SELECT  m_row, m_value, null
		FROM    @matrix
		WHERE   m_col = @cols

		-- Add R-squared value for this fit
		DECLARE @xy_data_fit TABLE (x float, y float, y_fit float)

		INSERT INTO @xy_data_fit
		SELECT x, y, 0 FROM @xy_data

		DECLARE @y_bar float = (SELECT AVG(y) FROM @xy_data_fit)

		DECLARE @n int = 0
		WHILE @n < @cols
		BEGIN
			UPDATE @xy_data_fit SET y_fit = y_fit + (POWER(x, @n) * (SELECT coefficient FROM @p WHERE power_x = @n))
			SET @n = @n + 1
		END

		UPDATE	@p
		SET		r2 = 1 - (SELECT SUM(SQUARE(y - y_fit)) FROM @xy_data_fit) / (SELECT SUM(SQUARE(y - @y_bar)) FROM @xy_data_fit)
		WHERE	power_x = 0
	END

	RETURN
END
