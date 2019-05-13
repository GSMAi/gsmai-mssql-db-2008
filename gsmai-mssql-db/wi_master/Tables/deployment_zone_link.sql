CREATE TABLE [dbo].[deployment_zone_link] (
    [deployment_id] INT NOT NULL,
    [zone_id]       INT NOT NULL,
    CONSTRAINT [FK_deployment_zone_link_deployments] FOREIGN KEY ([deployment_id]) REFERENCES [dbo].[deployments] ([id]),
    CONSTRAINT [FK_deployment_zone_link_zones] FOREIGN KEY ([zone_id]) REFERENCES [dbo].[zones] ([id]),
    CONSTRAINT [UNIQUE_KEY_DEPLOYMENT_ZONE_LINK] UNIQUE NONCLUSTERED ([deployment_id] ASC, [zone_id] ASC)
);

