CREATE TABLE [dbo].[organisation_data] (
    [id]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [fk_organisation_id] INT             NOT NULL,
    [fk_metric_id]       INT             NOT NULL,
    [fk_attribute_id]    INT             NOT NULL,
    [fk_status_id]       INT             NOT NULL,
    [fk_privacy_id]      INT             NOT NULL,
    [date]               DATETIME        NOT NULL,
    [date_type]          CHAR (1)        NOT NULL,
    [val]                DECIMAL (22, 4) NOT NULL,
    [fk_currency_id]     INT             NOT NULL,
    [fk_source_id]       INT             NOT NULL,
    [fk_confidence_id]   INT             NOT NULL,
    [has_flags]          BIT             NOT NULL,
    [is_calculated]      BIT             NOT NULL,
    [created_on]         DATETIME        NOT NULL,
    [created_by]         INT             NOT NULL,
    [archive]            BIT             DEFAULT ((0)) NOT NULL,
    [is_forecast_upload] BIT             NOT NULL,
    [file_source]        VARCHAR (128)   NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_attr_id] FOREIGN KEY ([fk_attribute_id]) REFERENCES [dbo].[attributes] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_conf_id] FOREIGN KEY ([fk_confidence_id]) REFERENCES [dbo].[confidence] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_curr_id] FOREIGN KEY ([fk_currency_id]) REFERENCES [dbo].[currencies] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_met_id] FOREIGN KEY ([fk_metric_id]) REFERENCES [dbo].[metrics] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_org_id] FOREIGN KEY ([fk_organisation_id]) REFERENCES [dbo].[organisations] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_priv_id] FOREIGN KEY ([fk_privacy_id]) REFERENCES [dbo].[privacy] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_srce_id] FOREIGN KEY ([fk_source_id]) REFERENCES [dbo].[sources] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [fk_stat_id] FOREIGN KEY ([fk_status_id]) REFERENCES [dbo].[status] ([id]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_orgdata_row_check]
    ON [dbo].[organisation_data]([fk_organisation_id] ASC, [fk_metric_id] ASC, [fk_attribute_id] ASC, [date] ASC, [date_type] ASC, [val] ASC, [fk_currency_id] ASC, [fk_source_id] ASC, [fk_confidence_id] ASC, [is_forecast_upload] ASC, [is_calculated] ASC, [fk_status_id] ASC, [archive] ASC, [has_flags] ASC);


GO
CREATE NONCLUSTERED INDEX [PT_organisation_data_comb]
    ON [dbo].[organisation_data]([fk_organisation_id] ASC, [fk_metric_id] ASC, [fk_attribute_id] ASC, [fk_status_id] ASC, [fk_privacy_id] ASC, [date] ASC, [date_type] ASC, [fk_currency_id] ASC, [fk_source_id] ASC, [fk_confidence_id] ASC, [has_flags] ASC, [is_calculated] ASC, [archive] ASC, [is_forecast_upload] ASC);

