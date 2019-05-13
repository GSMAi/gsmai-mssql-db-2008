CREATE TABLE [gsma].[sf_zone_link] (
    [zone_id] INT            NOT NULL,
    [fk_name] NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_sf_zone_link] PRIMARY KEY CLUSTERED ([zone_id] ASC)
);

