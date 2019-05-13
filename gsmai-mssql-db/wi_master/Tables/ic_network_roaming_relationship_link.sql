CREATE TABLE [gsma].[ic_network_roaming_relationship_link] (
    [network_id]         INT            NOT NULL,
    [tadig_code]         NVARCHAR (10)  NOT NULL,
    [rel_network_id]     INT            NULL,
    [rel_tadig_code]     NVARCHAR (10)  NOT NULL,
    [rel_hub_network_id] INT            NULL,
    [rel_hub_tadig_code] NVARCHAR (10)  NULL,
    [status]             NVARCHAR (512) NOT NULL,
    [ref_status_id]      INT            NOT NULL,
    [is_hubbed]          BIT            CONSTRAINT [DF_ic_network_roaming_relationship_link_is_hubbed] DEFAULT ((0)) NOT NULL
);

