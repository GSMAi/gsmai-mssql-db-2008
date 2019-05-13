CREATE TABLE [dbo].[_backup_dc_organisation_data] (
    [id]              BIGINT          NOT NULL,
    [organisation_id] INT             NOT NULL,
    [metric_id]       INT             NOT NULL,
    [metric_order]    INT             NULL,
    [attribute_id]    INT             NOT NULL,
    [attribute_order] INT             NULL,
    [date]            DATETIME        NOT NULL,
    [date_type]       CHAR (1)        NOT NULL,
    [val_d]           DECIMAL (22, 4) NULL,
    [val_i]           BIGINT          NULL,
    [currency_id]     INT             NOT NULL,
    [source_id]       INT             NOT NULL,
    [confidence_id]   INT             NOT NULL,
    [definition_id]   INT             NULL,
    [has_flags]       BIT             CONSTRAINT [DF_dc_organisation_data_has_flags] DEFAULT ((0)) NOT NULL,
    [flags]           NVARCHAR (MAX)  NULL,
    [location]        NVARCHAR (MAX)  NULL,
    [last_update_on]  DATETIME        CONSTRAINT [DF_dc_organisation_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]  INT             CONSTRAINT [DF_dc_organisation_data_last_update_by] DEFAULT ((0)) NOT NULL
);


GO
CREATE CLUSTERED INDEX [IX_dc_organisation_data]
    ON [dbo].[_backup_dc_organisation_data]([id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dc_organisation_data_currency_id]
    ON [dbo].[_backup_dc_organisation_data]([currency_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dc_organisation_data_organisation_id]
    ON [dbo].[_backup_dc_organisation_data]([organisation_id] ASC, [date_type] ASC, [date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dc_organisation_data_metric_id]
    ON [dbo].[_backup_dc_organisation_data]([metric_id] ASC, [attribute_id] ASC, [date_type] ASC, [date] ASC);

