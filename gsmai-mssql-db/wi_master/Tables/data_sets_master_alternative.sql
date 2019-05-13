CREATE TABLE [dbo].[data_sets_master_alternative] (
    [fk_data_sets_master_id] INT NOT NULL,
    [fk_data_view_id]        INT NOT NULL,
    [has_organisation_data]  INT NULL,
    [has_zone_data]          INT NULL,
    [show_on_website]        INT NULL,
    [archive]                INT NULL,
    CONSTRAINT [fk_data_sets_master_to_alt] FOREIGN KEY ([fk_data_sets_master_id]) REFERENCES [dbo].[data_sets_master] ([id]),
    CONSTRAINT [fk_data_sets_view_link] FOREIGN KEY ([fk_data_view_id]) REFERENCES [dbo].[data_views] ([id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [idx_data_sets_master_alt_key]
    ON [dbo].[data_sets_master_alternative]([fk_data_sets_master_id] ASC, [fk_data_view_id] ASC);

