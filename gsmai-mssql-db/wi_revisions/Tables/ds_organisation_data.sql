CREATE TABLE [dbo].[ds_organisation_data] (
    [id]              BIGINT          IDENTITY (1, 1) NOT NULL,
    [revision_id]     INT             NOT NULL,
    [revision]        DATETIME        NOT NULL,
    [organisation_id] INT             NOT NULL,
    [metric_id]       INT             NOT NULL,
    [attribute_id]    INT             NOT NULL,
    [status_id]       INT             NOT NULL,
    [privacy_id]      INT             NOT NULL,
    [date]            DATETIME        NOT NULL,
    [date_type]       CHAR (1)        NOT NULL,
    [val_d]           DECIMAL (22, 4) NULL,
    [val_i]           BIGINT          NULL,
    [currency_id]     INT             NOT NULL,
    [source_id]       INT             NOT NULL,
    [confidence_id]   INT             NOT NULL,
    [has_flags]       BIT             NOT NULL,
    [is_calculated]   BIT             NOT NULL,
    [created_on]      DATETIME        NOT NULL,
    [created_by]      INT             NOT NULL,
    [last_update_on]  DATETIME        NOT NULL,
    [last_update_by]  INT             NOT NULL,
    CONSTRAINT [PK_ds_organisation_data] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data_revision]
    ON [dbo].[ds_organisation_data]([revision] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data_revision_id_revision]
    ON [dbo].[ds_organisation_data]([revision_id] DESC, [revision] DESC);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data]
    ON [dbo].[ds_organisation_data]([revision_id] DESC, [organisation_id] ASC, [metric_id] ASC, [attribute_id] ASC, [date_type] ASC, [date] ASC);

