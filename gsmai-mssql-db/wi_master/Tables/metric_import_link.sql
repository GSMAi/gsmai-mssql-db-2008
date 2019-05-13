CREATE TABLE [dbo].[metric_import_link] (
    [metric_id]              INT            NOT NULL,
    [attribute_id]           INT            NOT NULL,
    [currency_id]            INT            CONSTRAINT [DF_metric_import_link_currency_id] DEFAULT ((0)) NOT NULL,
    [unit_id]                INT            CONSTRAINT [DF_metric_import_link_unit_id] DEFAULT ((0)) NOT NULL,
    [is_calculated]          BIT            CONSTRAINT [DF_metric_import_link_is_calculated] DEFAULT ((0)) NOT NULL,
    [source_organisation_id] INT            NOT NULL,
    [code]                   NVARCHAR (64)  NULL,
    [note]                   NVARCHAR (MAX) NULL
);

