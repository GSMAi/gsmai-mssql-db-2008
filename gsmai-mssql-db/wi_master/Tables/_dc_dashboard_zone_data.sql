CREATE TABLE [dbo].[_dc_dashboard_zone_data] (
    [id]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [zone_id]        INT             NOT NULL,
    [metric_id]      INT             NOT NULL,
    [attribute_id]   INT             NOT NULL,
    [date]           DATETIME        NOT NULL,
    [date_type]      CHAR (1)        NOT NULL,
    [val_d]          DECIMAL (22, 4) NULL,
    [val_i]          BIGINT          NULL,
    [currency_id]    INT             NOT NULL,
    [source_id]      INT             NOT NULL,
    [confidence_id]  INT             NOT NULL,
    [last_update_on] DATETIME        CONSTRAINT [DF_dc_dashboard_zone_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT             CONSTRAINT [DF_dc_dashboard_zone_data_last_update_by] DEFAULT ((0)) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_dc_dashboard_zone_data]
    ON [dbo].[_dc_dashboard_zone_data]([zone_id] ASC);

