CREATE TABLE [dbo].[deployment_organisation_link] (
    [deployment_id]   INT NOT NULL,
    [organisation_id] INT NOT NULL,
    [type_id]         INT NOT NULL,
    CONSTRAINT [FK_deployment_organisation_link_deployments] FOREIGN KEY ([deployment_id]) REFERENCES [dbo].[deployments] ([id]),
    CONSTRAINT [FK_deployment_organisation_link_organisations] FOREIGN KEY ([organisation_id]) REFERENCES [dbo].[organisations] ([id]),
    CONSTRAINT [FK_deployment_organisation_link_types] FOREIGN KEY ([type_id]) REFERENCES [dbo].[types] ([id]),
    CONSTRAINT [UNIQUE_KEY_DEPLOYMENT_ORGANISATION_LINK] UNIQUE NONCLUSTERED ([deployment_id] ASC, [organisation_id] ASC, [type_id] ASC)
);

