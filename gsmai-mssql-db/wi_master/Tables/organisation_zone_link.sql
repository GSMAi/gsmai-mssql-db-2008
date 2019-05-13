CREATE TABLE [dbo].[organisation_zone_link] (
    [organisation_id] INT NOT NULL,
    [zone_id]         INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [PT_organisation_zone_link_comb]
    ON [dbo].[organisation_zone_link]([organisation_id] ASC, [zone_id] ASC);

