CREATE TABLE [dbo].[auction_frequency_link] (
    [auction_id]           INT            NOT NULL,
    [organisation_id]      INT            NULL,
    [frequency_id]         INT            NOT NULL,
    [frequency_3gpp_bands] NVARCHAR (256) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_auction_frequency_link_auction]
    ON [dbo].[auction_frequency_link]([auction_id] ASC, [organisation_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_auction_frequency_link_frequency]
    ON [dbo].[auction_frequency_link]([frequency_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_auction_frequency_link_organisation]
    ON [dbo].[auction_frequency_link]([organisation_id] ASC, [auction_id] ASC);

