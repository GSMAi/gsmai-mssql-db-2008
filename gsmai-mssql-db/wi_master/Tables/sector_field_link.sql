CREATE TABLE [dbo].[sector_field_link] (
    [sector_id]   INT NOT NULL,
    [field_id]    INT NOT NULL,
    [is_required] BIT CONSTRAINT [DF_sector_field_link_is_required] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [FK_sector_field_link_attributes] FOREIGN KEY ([sector_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_sector_field_link_fields] FOREIGN KEY ([field_id]) REFERENCES [dbo].[fields] ([id])
);

