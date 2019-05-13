CREATE TABLE [dbo].[organisation_data_view_link_history] (
    [fk_organisation_data_id] BIGINT   NOT NULL,
    [fk_data_view_id]         INT      NOT NULL,
    [link_date]               DATETIME NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [PT_organisation_data_link_history_comb]
    ON [dbo].[organisation_data_view_link_history]([fk_organisation_data_id] ASC, [fk_data_view_id] ASC, [link_date] ASC);

