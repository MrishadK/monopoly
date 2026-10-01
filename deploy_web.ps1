# Deploy Flutter Web to GitHub Pages
Write-Host "🚀 Building Flutter Web with base-href /monopoly/..." -ForegroundColor Cyan
flutter build web --release --base-href "/monopoly/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Ensure GitHub Pages serves all directories without Jekyll filtering
New-Item -ItemType File -Path build\web\.nojekyll -Force | Out-Null

Write-Host "📦 Pushing web build to gh-pages branch..." -ForegroundColor Cyan
if (-not (Test-Path "build\web\.git")) {
    git -C build\web init
    git -C build\web checkout -b gh-pages
    git -C build\web remote add origin https://github.com/MrishadK/monopoly
}

git -C build\web add .
git -C build\web commit -m "Deploy Flutter Web to GitHub Pages"
git -C build\web push -f origin gh-pages

Write-Host "🎉 Successfully deployed! Your game is live at:" -ForegroundColor Green
Write-Host "👉 https://mrishadk.github.io/monopoly/" -ForegroundColor Yellow
