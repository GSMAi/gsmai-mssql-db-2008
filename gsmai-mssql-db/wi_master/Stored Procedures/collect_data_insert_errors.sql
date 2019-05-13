CREATE PROCEDURE [dbo].[collect_data_insert_errors]  
(
	@query_string char(2000) = null
)
AS  
insert into [dbo].[data_sp_run_error_log]
SELECT  
    ERROR_NUMBER() AS errorNumber  
    ,ERROR_SEVERITY() AS errorSeverity  
    ,ERROR_STATE() AS errorState  
    ,ERROR_PROCEDURE() AS errorProcedure  
    ,ERROR_LINE() AS errorLine  
    ,ERROR_MESSAGE() AS errorMessage,
    getdate() as "date",
    @query_string as "queryString"; 