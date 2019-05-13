CREATE TABLE [dbo].[zone_data_flags_link] (
    [id]              INT    IDENTITY (1, 1) NOT NULL,
    [fk_zone_data_id] BIGINT NOT NULL,
    [fk_flag_id]      INT    NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_fg_zd_id] FOREIGN KEY ([fk_flag_id]) REFERENCES [dbo].[flags] ([id]),
    CONSTRAINT [fk_zd_dt_id] FOREIGN KEY ([fk_zone_data_id]) REFERENCES [dbo].[zone_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);

