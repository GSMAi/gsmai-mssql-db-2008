CREATE TABLE [dbo].[data_sets_master_website_link] (
    [fk_data_sets_master_id] INT NOT NULL,
    [has_zone_data]          BIT DEFAULT ((0)) NOT NULL,
    [has_organisation_data]  BIT DEFAULT ((0)) NOT NULL,
    [has_regional_data]      BIT DEFAULT ((0)) NOT NULL,
    [has_group_data]         BIT DEFAULT ((0)) NOT NULL,
    [has_forecasts]          BIT DEFAULT ((0)) NOT NULL,
    [has_organisation_rank]  BIT DEFAULT ((0)) NOT NULL,
    [has_group_rank]         BIT DEFAULT ((0)) NOT NULL,
    [has_country_rank]       BIT DEFAULT ((0)) NOT NULL,
    [has_region_rank]        BIT DEFAULT ((0)) NOT NULL
);

