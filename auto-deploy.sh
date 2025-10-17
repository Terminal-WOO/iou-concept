#!/bin/bash

# Automatische GitHub Pages Deployment
# Dit script configureert alles automatisch

set -e

echo "🚀 IOU Concept - Automatische GitHub Pages Deploy"
echo "=================================================="
echo ""

# Git configuratie controleren
GIT_USER=$(git config user.name)
GIT_EMAIL=$(git config user.email)

echo "✓ Git configuratie:"
echo "   Gebruiker: $GIT_USER"
echo "   Email: $GIT_EMAIL"
echo ""

# Repository configuratie
REPO_NAME="iou-concept-flevoland"
GITHUB_USERNAME="marcminnee"  # Afgeleid van git email

echo "📦 Repository configuratie:"
echo "   Repository: $REPO_NAME"
echo "   GitHub user: $GITHUB_USERNAME"
echo ""

# Check huidige remote
if git remote | grep -q "^origin$"; then
    CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
    echo "⚠️  Remote 'origin' bestaat al: $CURRENT_REMOTE"
    echo "   Deze wordt bijgewerkt naar: https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    git remote set-url origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
else
    git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
fi

echo "✓ Remote geconfigureerd"
echo ""

# Branch configureren
echo "🔀 Branch configureren..."
git branch -M main
echo "✓ Branch 'main' geconfigureerd"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "📋 VOLGENDE STAPPEN - Handmatige acties vereist:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "STAP 1: Maak repository aan op GitHub"
echo "───────────────────────────────────────"
echo "   🌐 Open: https://github.com/new"
echo ""
echo "   Vul in:"
echo "   • Repository naam: $REPO_NAME"
echo "   • Visibility: PUBLIC ⚠️ (verplicht voor gratis Pages)"
echo "   • Initialize: NIETS aanvinken"
echo ""
echo "STAP 2: Push de code"
echo "────────────────────"
echo "   Voer dit commando uit in de terminal:"
echo ""
echo "   git push -u origin main"
echo ""
echo "   ⚠️ Authenticatie vereist:"
echo "   • Username: $GITHUB_USERNAME"
echo "   • Password: Personal Access Token (NIET je gewone wachtwoord)"
echo ""
echo "   Token aanmaken:"
echo "   🌐 https://github.com/settings/tokens/new"
echo "   • Note: 'IOU Concept Deploy'"
echo "   • Expiration: 90 days"
echo "   • Scopes: vink 'repo' aan ✓"
echo "   • Generate token en kopieer het"
echo ""
echo "STAP 3: Activeer GitHub Pages"
echo "──────────────────────────────"
echo "   🌐 Open: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/pages"
echo ""
echo "   Configureer:"
echo "   • Source: 'Deploy from a branch'"
echo "   • Branch: 'main'"
echo "   • Folder: '/ (root)'"
echo "   • Klik 'Save'"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✨ Je website komt beschikbaar op:"
echo "   https://$GITHUB_USERNAME.github.io/$REPO_NAME/"
echo ""
echo "   (Eerste build duurt ongeveer 1-2 minuten)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Open URLs in browser (macOS)
if command -v open > /dev/null; then
    read -p "Druk op ENTER om de GitHub nieuwe repository pagina te openen..."
    open "https://github.com/new"
fi
