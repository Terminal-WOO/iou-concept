#!/bin/bash

# Script om Engelse termen te vervangen door Nederlandse equivalenten

echo "🌐 Vertaling Engelse termen naar Nederlands..."
echo ""

# Bestandsnaam verwijzingen updaten
echo "1. Updaten bestandsnaam verwijzingen..."
find . -type f \( -name "*.html" -o -name "*.md" \) -exec sed -i '' \
    -e 's/collaboration-hub\.html/samenwerkingscentrum.html/g' \
    -e 's/stakeholder-mapper\.html/belanghebbenden-kaart.html/g' \
    -e 's/compliance-checker\.html/nalevingscontrole.html/g' \
    -e 's/data-explorer\.html/data-verkenner.html/g' \
    {} \;

# Engelse termen vervangen
echo "2. Vertalen app namen..."
find . -type f \( -name "*.html" -o -name "*.md" \) -exec sed -i '' \
    -e 's/Collaboration Hub/Samenwerkingscentrum/g' \
    -e 's/Stakeholder Mapper/Belanghebbenden Kaart/g' \
    -e 's/Compliance Checker/Nalevingscontrole/g' \
    -e 's/Data Explorer/Data Verkenner/g' \
    -e 's/Timeline Viewer/Tijdlijn Weergave/g' \
    -e 's/Document Generator/Document Generator/g' \
    {} \;

# Meer algemene termen
echo "3. Vertalen algemene termen..."
find . -type f \( -name "*.html" -o -name "*.md" \) -exec sed -i '' \
    -e 's/Real-time collaboration/Real-time samenwerking/g' \
    -e 's/Network visualization/Netwerk visualisatie/g' \
    -e 's/Automatic compliance/Automatische naleving/g' \
    -e 's/Template-based/Op basis van sjablonen/g' \
    {} \;

echo ""
echo "✅ Vertaling voltooid!"
echo ""
echo "Gewijzigde bestanden:"
git status --short | grep "M "
