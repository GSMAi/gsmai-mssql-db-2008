CREATE TABLE [dbo].[zone_currency_link] (
    [zone_id]        INT      NOT NULL,
    [currency_id]    INT      NOT NULL,
    [created_on]     DATETIME CONSTRAINT [DF_zone_currency_link_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT      CONSTRAINT [DF_zone_currency_link_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME CONSTRAINT [DF_zone_currency_link_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT      CONSTRAINT [DF_zone_currency_link_last_update_by] DEFAULT ((0)) NOT NULL
);

