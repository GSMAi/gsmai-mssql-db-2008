CREATE TABLE [dbo].[data_sets_views_link] (
    [fk_data_sets_id] INT NOT NULL,
    [fk_data_view_id] INT NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_unique_data_sets_views]
    ON [dbo].[data_sets_views_link]([fk_data_sets_id] ASC, [fk_data_view_id] ASC);

