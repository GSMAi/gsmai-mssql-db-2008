CREATE TABLE [dbo].[group_data_view_link] (
    [fk_group_data_id] BIGINT   NOT NULL,
    [fk_data_view_id]  INT      NOT NULL,
    [link_date]        DATETIME NOT NULL,
    [archive]          BIT      DEFAULT ((0)) NOT NULL,
    FOREIGN KEY ([fk_data_view_id]) REFERENCES [dbo].[data_views] ([id]),
    CONSTRAINT [FK__organisat__fk_or__034C7B9C] FOREIGN KEY ([fk_group_data_id]) REFERENCES [dbo].[group_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE UNIQUE CLUSTERED INDEX [PT_organisation_data_view_id]
    ON [dbo].[group_data_view_link]([fk_group_data_id] ASC, [fk_data_view_id] ASC);

