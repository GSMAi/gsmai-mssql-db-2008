CREATE TABLE [dbo].[currency_rates] (
    [id]               INT             IDENTITY (1, 1) NOT NULL,
    [from_currency_id] INT             NOT NULL,
    [to_currency_id]   INT             NOT NULL,
    [date]             DATETIME        NOT NULL,
    [date_type]        CHAR (1)        NOT NULL,
    [value]            DECIMAL (22, 8) NOT NULL,
    [created_on]       DATETIME        DEFAULT (getdate()) NOT NULL,
    [created_by]       INT             DEFAULT ((0)) NOT NULL,
    [last_update_on]   DATETIME        DEFAULT (getdate()) NOT NULL,
    [last_update_by]   INT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_currency_rates] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_currency_rates_from]
    ON [dbo].[currency_rates]([from_currency_id] ASC, [to_currency_id] ASC, [date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_currency_rates_to]
    ON [dbo].[currency_rates]([to_currency_id] ASC, [from_currency_id] ASC, [date] ASC);

