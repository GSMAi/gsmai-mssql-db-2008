CREATE TABLE [dbo].[data_views] (
    [id]          INT            IDENTITY (1, 1) NOT NULL,
    [name]        VARCHAR (256)  NOT NULL,
    [term]        VARCHAR (256)  NOT NULL,
    [description] VARCHAR (1024) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

