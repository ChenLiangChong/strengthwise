# Firestore Rules Deployment Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firestore Rules Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
$firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue

if (-not $firebaseInstalled) {
    Write-Host "Firebase CLI not installed. Installing..." -ForegroundColor Yellow
    npm install -g firebase-tools
} else {
    Write-Host "Firebase CLI is installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 1: Login to Firebase" -ForegroundColor Yellow
Write-Host "Please complete login in the browser..." -ForegroundColor Cyan
Write-Host ""

# Login to Firebase (requires browser authorization)
firebase login

Write-Host ""
Write-Host "Step 2: Deploy Firestore Rules" -ForegroundColor Yellow
Write-Host ""

# Deploy rules
firebase deploy --only firestore:rules

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

