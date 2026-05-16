# In SHA-1/SHA-256 vào Firebase Console (app Android com.example.fe_moblie_flutter)
Set-Location $PSScriptRoot
.\gradlew.bat signingReport 2>&1 | Select-String -Pattern "SHA1:|SHA-256:" | Select-Object -First 4
