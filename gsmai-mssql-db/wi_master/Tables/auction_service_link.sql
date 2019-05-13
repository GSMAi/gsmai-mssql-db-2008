CREATE TABLE [dbo].[auction_service_link] (
    [auction_id]      INT NOT NULL,
    [organisation_id] INT NULL,
    [service_id]      INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_auction_service_link_auction]
    ON [dbo].[auction_service_link]([auction_id] ASC, [organisation_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_auction_service_link_organisation]
    ON [dbo].[auction_service_link]([organisation_id] ASC, [auction_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_auction_service_link_service]
    ON [dbo].[auction_service_link]([service_id] ASC);

