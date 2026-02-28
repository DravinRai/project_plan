# ============================================================
#  Project Plan — Flutter Setup Script
#  Run this AFTER installing Flutter SDK and adding to PATH
# ============================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Project Plan — Flutter Setup Script    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1 — Check Flutter
Write-Host "▶ Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Flutter not found. Please install Flutter and add to PATH." -ForegroundColor Red
    Write-Host "  Download: https://docs.flutter.dev/get-started/install/windows/mobile" -ForegroundColor Gray
    exit 1
}
Write-Host "✓ Flutter found." -ForegroundColor Green

# Step 2 — Initialize Flutter project (preserves existing lib/ files)
Write-Host ""
Write-Host "▶ Initializing Flutter project (platform boilerplate)..." -ForegroundColor Yellow
flutter create --org com.projectplan --project-name project_plan . --overwrite
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ flutter create failed." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Flutter project scaffold created." -ForegroundColor Green

# Step 3 — Create assets directory
Write-Host ""
Write-Host "▶ Creating assets directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path ".\assets\images" | Out-Null
Write-Host "✓ assets/images/ created." -ForegroundColor Green

# Step 4 — Get packages
Write-Host ""
Write-Host "▶ Installing packages (flutter pub get)..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ flutter pub get failed. Check pubspec.yaml." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Packages installed." -ForegroundColor Green

# Step 5 — Run flutter doctor
Write-Host ""
Write-Host "▶ Running flutter doctor..." -ForegroundColor Yellow
flutter doctor

# Done
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║             Setup Complete! ✓            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Install FlutterFire CLI:" -ForegroundColor White
Write-Host "       dart pub global activate flutterfire_cli" -ForegroundColor Gray
Write-Host "  2. Configure Firebase (requires Firebase project):" -ForegroundColor White
Write-Host "       flutterfire configure" -ForegroundColor Gray
Write-Host "  3. Place google-services.json  → android/app/" -ForegroundColor White
Write-Host "  4. Place GoogleService-Info.plist → ios/Runner/" -ForegroundColor White
Write-Host "  5. Run the app:" -ForegroundColor White
Write-Host "       flutter run" -ForegroundColor Gray
Write-Host ""
