CREATE TABLE [dbo].[dc_organisation_data_sets] (
    [organisation_id] INT NOT NULL,
    [metric_id]       INT NOT NULL,
    [attribute_id]    INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_dc_organisation_data_sets_metrics]
    ON [dbo].[dc_organisation_data_sets]([metric_id] ASC, [organisation_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dc_organisation_data_sets_organisations]
    ON [dbo].[dc_organisation_data_sets]([organisation_id] ASC, [metric_id] ASC);

