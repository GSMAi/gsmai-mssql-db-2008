CREATE TABLE [gsma].[ic_network_link] (
    [id]                INT            NOT NULL,
    [organisation_id]   INT            NOT NULL,
    [licence]           NVARCHAR (512) NOT NULL,
    [ref_network_id]    INT            NULL,
    [ref_technology_id] INT            NOT NULL,
    [ref_status_id]     INT            NOT NULL,
    [launch_date]       DATETIME       NULL,
    [frequencies]       NVARCHAR (512) NULL,
    [created_by]        INT            CONSTRAINT [DF_ic_network_link_created_by] DEFAULT ((0)) NOT NULL,
    [created_on]        DATETIME       CONSTRAINT [DF_ic_network_link_created_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]    INT            NULL,
    [last_update_on]    DATETIME       NULL
);

