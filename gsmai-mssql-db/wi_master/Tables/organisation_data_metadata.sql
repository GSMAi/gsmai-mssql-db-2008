CREATE TABLE [dbo].[organisation_data_metadata] (
    [id]                      BIGINT         IDENTITY (1, 1) NOT NULL,
    [fk_organisation_data_id] BIGINT         NOT NULL,
    [location]                NVARCHAR (MAX) NULL,
    [location_cleaned]        NVARCHAR (MAX) NULL,
    [definition]              NVARCHAR (MAX) NULL,
    [notes]                   NVARCHAR (MAX) NULL,
    [approved]                TINYINT        NULL,
    [approval_hash]           NVARCHAR (64)  NULL,
    [import_hash]             NVARCHAR (64)  NULL,
    [is_held_for_review]      BIT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [od_fk_org_data_id] FOREIGN KEY ([fk_organisation_data_id]) REFERENCES [dbo].[organisation_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[organisation_data_metadata] NOCHECK CONSTRAINT [od_fk_org_data_id];

