CREATE TABLE [dbo].[currency_rates_bkp_20180110] (
    [id]               INT             IDENTITY (1, 1) NOT NULL,
    [from_currency_id] INT             NOT NULL,
    [to_currency_id]   INT             NOT NULL,
    [date]             DATETIME        NOT NULL,
    [date_type]        CHAR (1)        NOT NULL,
    [value]            DECIMAL (22, 8) NOT NULL,
    [created_on]       DATETIME        NOT NULL,
    [created_by]       INT             NOT NULL,
    [last_update_on]   DATETIME        NOT NULL,
    [last_update_by]   INT             NOT NULL
);

