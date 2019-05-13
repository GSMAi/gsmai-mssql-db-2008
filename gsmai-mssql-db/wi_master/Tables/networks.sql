CREATE TABLE [dbo].[networks] (
    [id]                    INT            IDENTITY (1, 1) NOT NULL,
    [organisation_id]       INT            NOT NULL,
    [technology_id]         INT            NOT NULL,
    [status_id]             INT            NOT NULL,
    [launch_date]           DATETIME       NULL,
    [closure_date]          DATETIME       NULL,
    [frequencies]           NVARCHAR (512) NULL,
    [downlink_rate]         FLOAT (53)     NULL,
    [downlink_rate_unit_id] INT            NULL,
    [uplink_rate]           FLOAT (53)     NULL,
    [uplink_rate_unit_id]   INT            NULL,
    [is_upgrade]            BIT            CONSTRAINT [DF_networks_is_upgrade] DEFAULT ((0)) NOT NULL,
    [vendors]               NVARCHAR (MAX) NULL,
    [note]                  NVARCHAR (MAX) NULL,
    [created_on]            DATETIME       CONSTRAINT [DF_networks_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]            INT            CONSTRAINT [DF_networks_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]        DATETIME       CONSTRAINT [DF_networks_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]        INT            CONSTRAINT [DF_networks_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_networks] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_networks]
    ON [dbo].[networks]([technology_id] ASC, [status_id] ASC);

