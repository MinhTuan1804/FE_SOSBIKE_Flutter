# Lấy SHA-1 cho OAuth Android client (Google Cloud Console)
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore "$PSScriptRoot\debug.keystore" `
  -alias androiddebugkey `
  -storepass android `
  -keypass android
