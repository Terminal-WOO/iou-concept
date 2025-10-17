#!/bin/bash

# IOU Concept - GitHub Pages Deployment Script
# Dit script helpt bij het opzetten van de GitHub repository en Pages

set -e

echo "🚀 IOU Concept - GitHub Pages Deployment"
echo "========================================="
echo ""

# Check if git is configured
if ! git config user.name > /dev/null 2>&1; then
    echo "⚠️  Git gebruikersnaam niet geconfigureerd"
    read -p "Voer je GitHub gebruikersnaam in: " git_username
    git config user.name "$git_username"
fi

if ! git config user.email > /dev/null 2>&1; then
    echo "⚠️  Git email niet geconfigureerd"
    read -p "Voer je GitHub email in: " git_email
    git config user.email "$git_email"
fi

echo "✓ Git configuratie compleet"
echo ""

# Repository naam
REPO_NAME="iou-concept-flevoland"

echo "📦 Repository naam: $REPO_NAME"
read -p "Voer je GitHub gebruikersnaam in: " GITHUB_USERNAME

echo ""
echo "📋 Volgende stappen:"
echo ""
echo "1. Maak een nieuw repository aan op GitHub:"
echo "   → Ga naar: https://github.com/new"
echo "   → Repository naam: $REPO_NAME"
echo "   → Maak het PUBLIC (vereist voor gratis GitHub Pages)"
echo "   → GEEN README, .gitignore of license toevoegen"
echo ""
echo "2. Wanneer de repository is aangemaakt, druk op ENTER om verder te gaan..."
read -p ""

# Set remote
REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo ""
echo "🔗 Configuring remote: $REPO_URL"

if git remote | grep -q "^origin$"; then
    git remote set-url origin "$REPO_URL"
    echo "✓ Remote 'origin' bijgewerkt"
else
    git remote add origin "$REPO_URL"
    echo "✓ Remote 'origin' toegevoegd"
fi

# Push to GitHub
echo ""
echo "📤 Pushing naar GitHub..."
echo "   (Je wordt mogelijk gevraagd om in te loggen)"
echo ""

git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Code succesvol gepusht naar GitHub!"
    echo ""
    echo "🌐 Laatste stap - GitHub Pages activeren:"
    echo ""
    echo "   1. Ga naar: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/pages"
    echo "   2. Bij 'Source': selecteer 'Deploy from a branch'"
    echo "   3. Bij 'Branch': selecteer 'main' en '/ (root)'"
    echo "   4. Klik op 'Save'"
    echo ""
    echo "   Je site wordt beschikbaar op:"
    echo "   https://$GITHUB_USERNAME.github.io/$REPO_NAME/"
    echo ""
    echo "   (Het kan 1-2 minuten duren voordat de site online is)"
    echo ""
else
    echo ""
    echo "❌ Er is een fout opgetreden bij het pushen."
    echo ""
    echo "Mogelijke oplossingen:"
    echo "   • Zorg dat je een Personal Access Token hebt aangemaakt:"
    echo "     https://github.com/settings/tokens"
    echo "   • Bij 'Scopes' moet 'repo' aangevinkt zijn"
    echo "   • Gebruik het token als wachtwoord bij het inloggen"
    echo ""
fi
