CREATE TABLE [gsma].[ic_network_tadig_codes] (
    [organisation_id] INT            NOT NULL,
    [network_id]      INT            NOT NULL,
    [tadig_code]      NVARCHAR (10)  NOT NULL,
    [type]            NVARCHAR (512) NULL,
    [ref_type_id]     INT            NULL
);

