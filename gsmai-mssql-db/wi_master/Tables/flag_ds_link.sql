CREATE TABLE [dbo].[flag_ds_link] (
    [ds]      VARCHAR (128) NOT NULL,
    [ds_id]   BIGINT        NOT NULL,
    [flag_id] INT           NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_flag_ds_link_ds]
    ON [dbo].[flag_ds_link]([ds] ASC, [ds_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_flag_ds_link_flag]
    ON [dbo].[flag_ds_link]([flag_id] ASC, [ds] ASC);

