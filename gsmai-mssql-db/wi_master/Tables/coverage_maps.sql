CREATE TABLE [dbo].[coverage_maps] (
    [id]                    INT            IDENTITY (1, 1) NOT NULL,
    [organisation_id]       INT            NOT NULL,
    [technology_id]         INT            NOT NULL,
    [status_id]             INT            NOT NULL,
    [frequencies]           NVARCHAR (128) NULL,
    [launch_date]           DATETIME       NULL,
    [has_map]               BIT            CONSTRAINT [DF_coverage_maps_has_map] DEFAULT ((0)) NOT NULL,
    [layer_id]              INT            NULL,
    [is_frequency_specific] BIT            CONSTRAINT [DF_coverage_maps_is_frequency_specific] DEFAULT ((0)) NOT NULL,
    [last_update_on]        DATETIME       CONSTRAINT [DF_coverage_maps_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]        INT            CONSTRAINT [DF_coverage_maps_last_update_by] DEFAULT ((0)) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_coverage_maps]
    ON [dbo].[coverage_maps]([organisation_id] ASC, [status_id] ASC);

