cd "%dw-rei%"

:: REI_Stage load
call %dw-rei%\venv\Scripts\activate.bat
python "%dw-rei%\jobs\REI_Stage ETL.py"

:: backup
C:\"Program Files"\PostgreSQL\14\bin\pg_dump.exe -U postgres -h localhost -p 5432 -d REI_Stage --format=c --data-only > "jobs\REI_Stage backups\REI_Stage_backup.backup"

:: clear
(echo DELETE FROM public."AcceptanceCriteria"; DELETE FROM public."ExpensePercentages" ;DELETE FROM public."LoanTerms";DELETE FROM public."PurchaseTerms";DELETE FROM public."dimProperty";DELETE FROM public."dimState";DELETE FROM public."factListings"; DELETE FROM public."tempListings";) | "C:\Program Files\PostgreSQL\14\bin\psql.exe" -h localhost -p 5432 -U postgres -d REI_Prod

:: restore
C:\"Program Files"\PostgreSQL\14\bin\pg_restore.exe -U postgres -h localhost -p 5432 -d REI_Prod < "jobs\REI_Stage backups\REI_Stage_backup.backup"

:: R load
:: Rscript.exe "jobs\dimProperty geocode.R" - disabled 18-06-2022