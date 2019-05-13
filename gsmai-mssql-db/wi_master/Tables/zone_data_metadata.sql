CREATE TABLE [dbo].[zone_data_metadata] (
    [id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [fk_zone_data_id]    BIGINT         NOT NULL,
    [location]           NVARCHAR (MAX) NULL,
    [location_cleaned]   NVARCHAR (MAX) NULL,
    [definition]         NVARCHAR (MAX) NULL,
    [notes]              NVARCHAR (MAX) NULL,
    [approved]           TINYINT        NULL,
    [approval_hash]      NVARCHAR (64)  NULL,
    [import_hash]        NVARCHAR (64)  NULL,
    [is_held_for_review] BIT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_zid] FOREIGN KEY ([fk_zone_data_id]) REFERENCES [dbo].[zone_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);

