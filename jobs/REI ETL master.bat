cd "%Backend_API_v2%"

:: REI_Stage load
::call %Backend_API_v2%\venv\Scripts\activate.bat
::python "%Backend_API_v2%\etl job\REI_Stage ETL.py"

:: backup
C:\"Program Files"\PostgreSQL\13\bin\pg_dump.exe -U postgres -h localhost -p 5432 -d REI_Stage --format=c --data-only > "jobs\REI_Stage backups\REI_Stage_backup.backup"

:: clear
(echo DELETE FROM public."AcceptanceCriteria"; DELETE FROM public."ExpensePercentages" ;DELETE FROM public."LoanTerms";DELETE FROM public."PurchaseTerms";DELETE FROM public."dimProperty";DELETE FROM public."dimState";DELETE FROM public."factListings"; DELETE FROM public."tempListings";) | "C:\Program Files\PostgreSQL\13\bin\psql.exe" -h localhost -p 5432 -U postgres -d REI_Prod

:: restore
C:\"Program Files"\PostgreSQL\13\bin\pg_restore.exe -U postgres -h localhost -p 5432 -d REI_Prod < "jobs\REI_Stage backups\REI_Stage_backup.backup"

:: R load
Rscript.exe eda\test.R