# Concatenar Migrations em Ordem
$outputFile = "deploy-schema.sql"
if (Test-Path $outputFile) { Remove-Item $outputFile }

Get-ChildItem -Path "migrations" -Filter "*.sql" | Sort-Object Name | ForEach-Object {
    Write-Host "Adicionando: $($_.Name)"
    Get-Content $_.FullName | Add-Content $outputFile
    Add-Content $outputFile "`n`n-- END OF $($_.Name) --`n`n"
}

Write-Host "Schema criado em: $outputFile" -ForegroundColor Green
