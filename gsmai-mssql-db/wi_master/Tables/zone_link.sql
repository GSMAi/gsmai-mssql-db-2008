CREATE TABLE [dbo].[zone_link] (
    [zone_id]    INT NOT NULL,
    [subzone_id] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_zone_link]
    ON [dbo].[zone_link]([zone_id] ASC, [subzone_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_zone_link_subzone]
    ON [dbo].[zone_link]([subzone_id] ASC, [zone_id] ASC);

