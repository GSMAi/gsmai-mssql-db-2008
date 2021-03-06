﻿CREATE TABLE [dbo].[ds_survey_data] (
    [id]                    INT            NOT NULL,
    [survey_id]             INT            NOT NULL,
    [zone_id]               INT            NOT NULL,
    [respondent_id]         INT            NOT NULL,
    [acquisition_type_id]   INT            NOT NULL,
    [question_number_major] INT            NOT NULL,
    [question_number_minor] INT            NOT NULL,
    [val_i]                 INT            NULL,
    [val_t]                 NVARCHAR (MAX) NULL,
    [inserted_on]           DATETIME       NOT NULL
);

