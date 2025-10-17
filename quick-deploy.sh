#!/bin/bash

# Quick GitHub Pages Deployment Script
# Voer dit script uit en volg de instructies

set -e

echo "🚀 IOU Concept - GitHub Pages Quick Deploy"
echo "==========================================="
echo ""

# Check git status
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Geen git repository gevonden"
    exit 1
fi

echo "✓ Git repository gevonden"
echo ""

# Get GitHub username
echo "Voer je GitHub gebruikersnaam in:"
read -r GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ Gebruikersnaam is vereist"
    exit 1
fi

# Repository name
REPO_NAME="iou-concept-flevoland"

echo ""
echo "📋 Deployment configuratie:"
echo "   GitHub gebruiker: $GITHUB_USERNAME"
echo "   Repository naam: $REPO_NAME"
echo "   Repository URL: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "   Website URL: https://$GITHUB_USERNAME.github.io/$REPO_NAME/"
echo ""

# Check if repository exists on GitHub
echo "Controleren of repository al bestaat op GitHub..."
if curl -s "https://github.com/$GITHUB_USERNAME/$REPO_NAME" | grep -q "404"; then
    echo ""
    echo "⚠️  Repository bestaat nog niet op GitHub"
    echo ""
    echo "🌐 Open de volgende URL in je browser om de repository aan te maken:"
    echo "   https://github.com/new"
    echo ""
    echo "Vul in:"
    echo "   • Repository naam: $REPO_NAME"
    echo "   • Zichtbaarheid: PUBLIC"
    echo "   • GEEN README, .gitignore, of license toevoegen"
    echo ""
    echo "Druk op ENTER wanneer je de repository hebt aangemaakt..."
    read -r
fi

# Configure remote
echo ""
echo "🔗 Git remote configureren..."

if git remote | grep -q "^origin$"; then
    echo "   Remote 'origin' bestaat al, wordt bijgewerkt..."
    git remote set-url origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
else
    git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
fi

echo "✓ Remote geconfigureerd"

# Push to GitHub
echo ""
echo "📤 Code pushen naar GitHub..."
echo ""
echo "⚠️  BELANGRIJK: Wanneer je wordt gevraagd om een wachtwoord:"
echo "   → Gebruik NIET je gewone GitHub wachtwoord"
echo "   → Gebruik een Personal Access Token"
echo ""
echo "   Token aanmaken: https://github.com/settings/tokens/new"
echo "   → Note: 'IOU Concept Deploy'"
echo "   → Scopes: vink 'repo' aan"
echo ""
echo "Druk op ENTER om te pushen..."
read -r

git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Code succesvol gepusht!"
    echo ""
    echo "🌐 Laatste stap - GitHub Pages activeren:"
    echo ""
    echo "   Open: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/pages"
    echo ""
    echo "   Configuratie:"
    echo "   1. Source: 'Deploy from a branch'"
    echo "   2. Branch: 'main' + '/ (root)'"
    echo "   3. Klik 'Save'"
    echo ""
    echo "   Je website komt beschikbaar op:"
    echo "   → https://$GITHUB_USERNAME.github.io/$REPO_NAME/"
    echo ""
    echo "   (Eerste build duurt 1-2 minuten)"
    echo ""

    # Open browser automatically
    if command -v open > /dev/null; then
        echo "Browser openen voor GitHub Pages settings..."
        open "https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/pages"
    fi
else
    echo ""
    echo "❌ Push is mislukt"
    echo ""
    echo "Lees DEPLOYMENT.md voor gedetailleerde instructies"
    exit 1
fi
