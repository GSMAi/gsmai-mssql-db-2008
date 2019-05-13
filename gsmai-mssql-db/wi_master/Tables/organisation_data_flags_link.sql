CREATE TABLE [dbo].[organisation_data_flags_link] (
    [id]                      BIGINT IDENTITY (1, 1) NOT NULL,
    [fk_organisation_data_id] BIGINT NOT NULL,
    [fk_flag_id]              INT    NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_fg_id] FOREIGN KEY ([fk_flag_id]) REFERENCES [dbo].[flags] ([id]),
    CONSTRAINT [fk_orgs_dt_fl_lk] FOREIGN KEY ([fk_organisation_data_id]) REFERENCES [dbo].[organisation_data] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);

