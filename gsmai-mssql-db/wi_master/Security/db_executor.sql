﻿CREATE ROLE [db_executor]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'db_executor', @membername = N'gsmai-jira';

