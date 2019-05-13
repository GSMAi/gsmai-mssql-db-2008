CREATE TYPE [dbo].[ordered_iterator] AS TABLE (
    [order]     INT      NULL,
    [term]      CHAR (8) NULL,
    [processed] BIT      NULL);

