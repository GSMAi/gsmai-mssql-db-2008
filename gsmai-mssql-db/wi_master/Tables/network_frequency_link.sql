CREATE TABLE [dbo].[network_frequency_link] (
    [network_id]   INT NOT NULL,
    [frequency_id] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_network_frequency_link_frequency_id]
    ON [dbo].[network_frequency_link]([frequency_id] ASC, [network_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_network_frequency_link_network_id]
    ON [dbo].[network_frequency_link]([network_id] ASC, [frequency_id] ASC);

