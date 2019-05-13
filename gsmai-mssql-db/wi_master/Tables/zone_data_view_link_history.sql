CREATE TABLE [dbo].[zone_data_view_link_history] (
    [fk_zone_data_id] BIGINT   NOT NULL,
    [fk_data_view_id] INT      NOT NULL,
    [created]         DATETIME NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [PT_zone_data_view_link_history_comb]
    ON [dbo].[zone_data_view_link_history]([fk_zone_data_id] ASC, [fk_data_view_id] ASC, [created] ASC);

