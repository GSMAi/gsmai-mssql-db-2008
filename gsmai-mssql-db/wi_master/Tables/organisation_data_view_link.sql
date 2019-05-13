CREATE TABLE [dbo].[organisation_data_view_link] (
    [fk_organisation_data_id] BIGINT   NOT NULL,
    [fk_data_view_id]         INT      NOT NULL,
    [link_date]               DATETIME NOT NULL,
    [archive]                 BIT      DEFAULT ((0)) NOT NULL,
    CONSTRAINT [fk_org_data_vw_id] FOREIGN KEY ([fk_data_view_id]) REFERENCES [dbo].[data_views] ([id]),
    CONSTRAINT [fk_organisation_data_id] FOREIGN KEY ([fk_organisation_data_id]) REFERENCES [dbo].[organisation_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE UNIQUE CLUSTERED INDEX [PT_organisation_data_view_id]
    ON [dbo].[organisation_data_view_link]([fk_organisation_data_id] ASC, [fk_data_view_id] ASC, [link_date] ASC);

