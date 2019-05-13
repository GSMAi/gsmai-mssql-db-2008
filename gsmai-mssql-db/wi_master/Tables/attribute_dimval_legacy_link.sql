CREATE TABLE [dbo].[attribute_dimval_legacy_link] (
    [dimval_id]    INT IDENTITY (1915749, 1) NOT NULL,
    [dimension_id] INT NOT NULL,
    [metric_id]    INT NOT NULL,
    [attribute_id] INT NOT NULL,
    CONSTRAINT [PK_attribute_dimval_legacy_link] PRIMARY KEY CLUSTERED ([dimval_id] ASC)
);

