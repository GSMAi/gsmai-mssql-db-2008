CREATE TABLE [dbo].[group_data_view_link_history] (
    [fk_group_data_id] BIGINT   NOT NULL,
    [fk_data_view_id]  INT      NOT NULL,
    [link_date]        DATETIME NOT NULL,
    CONSTRAINT [fk_dt_vw_id] FOREIGN KEY ([fk_data_view_id]) REFERENCES [dbo].[data_views] ([id]),
    CONSTRAINT [fk_grp_data_id] FOREIGN KEY ([fk_group_data_id]) REFERENCES [dbo].[group_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);

