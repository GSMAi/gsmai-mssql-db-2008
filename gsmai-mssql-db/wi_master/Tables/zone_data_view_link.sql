CREATE TABLE [dbo].[zone_data_view_link] (
    [fk_zone_data_id] BIGINT   NOT NULL,
    [fk_data_view_id] INT      NOT NULL,
    [created]         DATETIME NOT NULL,
    [archive]         BIT      DEFAULT ((0)) NOT NULL,
    CONSTRAINT [fk_zdid] FOREIGN KEY ([fk_zone_data_id]) REFERENCES [dbo].[zone_data] ([id]),
    CONSTRAINT [fk_zid_vid] FOREIGN KEY ([fk_data_view_id]) REFERENCES [dbo].[data_views] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_zone_view_links]
    ON [dbo].[zone_data_view_link]([fk_zone_data_id] ASC, [fk_data_view_id] ASC);

