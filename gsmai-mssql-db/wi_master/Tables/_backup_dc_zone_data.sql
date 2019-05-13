CREATE TABLE [dbo].[_backup_dc_zone_data] (
    [id]              BIGINT          NOT NULL,
    [zone_id]         INT             NOT NULL,
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
    [has_flags]       BIT             CONSTRAINT [DF_dc_zone_data_has_flags] DEFAULT ((0)) NOT NULL,
    [is_calculated]   BIT             CONSTRAINT [DF_dc_zone_data_is_calculated] DEFAULT ((0)) NOT NULL,
    [is_spot]         BIT             NULL,
    [flags]           NVARCHAR (MAX)  NULL,
    [location]        NVARCHAR (MAX)  NULL,
    [last_update_on]  DATETIME        CONSTRAINT [DF_dc_zone_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]  INT             CONSTRAINT [DF_dc_zone_data_last_update_by] DEFAULT ((0)) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_dc_zone_data]
    ON [dbo].[_backup_dc_zone_data]([id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dc_zone_data_metric_id]
    ON [dbo].[_backup_dc_zone_data]([metric_id] ASC, [attribute_id] ASC, [date_type] ASC, [date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dc_zone_data_zone_id]
    ON [dbo].[_backup_dc_zone_data]([zone_id] ASC, [date_type] ASC, [date] ASC);

