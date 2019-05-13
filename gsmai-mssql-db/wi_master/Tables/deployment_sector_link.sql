CREATE TABLE [dbo].[deployment_sector_link] (
    [deployment_id] INT NOT NULL,
    [sector_id]     INT NOT NULL,
    CONSTRAINT [FK_deployment_sector_link_attributes] FOREIGN KEY ([sector_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_deployment_sector_link_deployments] FOREIGN KEY ([deployment_id]) REFERENCES [dbo].[deployments] ([id]),
    CONSTRAINT [UNIQUE_KEY_DEPLOYMENT_SECTOR_LINK] UNIQUE NONCLUSTERED ([deployment_id] ASC, [sector_id] ASC)
);

