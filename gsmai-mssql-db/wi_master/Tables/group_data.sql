CREATE TABLE [dbo].[group_data] (
    [id]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [fk_organisation_id] INT             NOT NULL,
    [fk_metric_id]       INT             NOT NULL,
    [fk_attribute_id]    INT             NOT NULL,
    [fk_status_id]       INT             NOT NULL,
    [fk_privacy_id]      INT             NOT NULL,
    [date]               DATETIME        NOT NULL,
    [date_type]          CHAR (1)        NOT NULL,
    [val_sum]            DECIMAL (22, 4) NOT NULL,
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
    [val_proportionate]  DECIMAL (22, 4) NOT NULL,
    [ownership]          DECIMAL (22, 4) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([fk_attribute_id]) REFERENCES [dbo].[attributes] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_confidence_id]) REFERENCES [dbo].[confidence] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_currency_id]) REFERENCES [dbo].[currencies] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_metric_id]) REFERENCES [dbo].[metrics] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_organisation_id]) REFERENCES [dbo].[organisations] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_privacy_id]) REFERENCES [dbo].[privacy] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_source_id]) REFERENCES [dbo].[sources] ([id]) ON UPDATE CASCADE,
    FOREIGN KEY ([fk_status_id]) REFERENCES [dbo].[status] ([id]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_grp_data]
    ON [dbo].[group_data]([fk_organisation_id] ASC, [fk_metric_id] ASC, [fk_attribute_id] ASC, [fk_status_id] ASC, [fk_privacy_id] ASC, [date] ASC, [date_type] ASC, [val_sum] ASC, [fk_currency_id] ASC, [fk_source_id] ASC, [fk_confidence_id] ASC, [val_proportionate] ASC, [ownership] ASC, [archive] ASC, [has_flags] ASC);

