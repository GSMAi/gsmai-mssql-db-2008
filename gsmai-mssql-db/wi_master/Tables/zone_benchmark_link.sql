CREATE TABLE [dbo].[zone_benchmark_link] (
    [zone_id]           INT NOT NULL,
    [benchmark_zone_id] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_zone_benchmark_link]
    ON [dbo].[zone_benchmark_link]([zone_id] ASC);

