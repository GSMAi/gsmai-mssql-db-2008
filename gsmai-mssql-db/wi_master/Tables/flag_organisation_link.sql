CREATE TABLE [dbo].[flag_organisation_link] (
    [organisation_id] INT NOT NULL,
    [flag_id]         INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_flag_organisation_link]
    ON [dbo].[flag_organisation_link]([organisation_id] ASC, [flag_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_flag_organisation_link_flag]
    ON [dbo].[flag_organisation_link]([flag_id] ASC);

