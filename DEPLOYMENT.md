# 🚀 GitHub Pages Deployment Instructies

## Stap 1: Maak GitHub Repository aan

1. Ga naar https://github.com/new
2. Vul in:
   - **Repository naam**: `iou-concept-flevoland` (of een andere naam)
   - **Zichtbaarheid**: **Public** ✓ (vereist voor gratis GitHub Pages)
   - **NIET aanvinken**: Initialize with README, .gitignore, of license
3. Klik op **"Create repository"**

## Stap 2: Push code naar GitHub

Open een terminal in de IOU-concept folder en voer uit:

```bash
# Vervang YOUR_USERNAME met je GitHub gebruikersnaam
git remote add origin https://github.com/YOUR_USERNAME/iou-concept-flevoland.git

# Push naar GitHub
git branch -M main
git push -u origin main
```

**Let op**: Je wordt gevraagd om in te loggen. Gebruik:
- **Username**: je GitHub gebruikersnaam
- **Password**: een Personal Access Token (NIET je gewone wachtwoord)

### Personal Access Token aanmaken (als je die nog niet hebt):

1. Ga naar https://github.com/settings/tokens
2. Klik op **"Generate new token"** → **"Generate new token (classic)"**
3. Vul in:
   - **Note**: `IOU Concept Deployment`
   - **Expiration**: `90 days` (of langer)
   - **Scopes**: Vink **`repo`** aan ✓
4. Klik op **"Generate token"**
5. **Kopieer het token** (je ziet het maar één keer!)
6. Gebruik dit token als wachtwoord bij `git push`

## Stap 3: Activeer GitHub Pages

1. Ga naar je repository op GitHub
2. Ga naar **Settings** (bovenaan)
3. Klik op **Pages** (links in het menu)
4. Bij **"Source"**:
   - Selecteer **"Deploy from a branch"**
5. Bij **"Branch"**:
   - Selecteer **`main`**
   - Selecteer **`/ (root)`**
6. Klik op **"Save"**

## Stap 4: Klaar! ✅

Je site wordt binnen 1-2 minuten gepubliceerd op:

```
https://YOUR_USERNAME.github.io/iou-concept-flevoland/
```

De homepage redirects automatisch naar de dashboard:
```
https://YOUR_USERNAME.github.io/iou-concept-flevoland/src/frontend/context_dashboard.html
```

---

## Alternatieve methode: GitHub CLI

Als je de GitHub CLI hebt geïnstalleerd:

```bash
# Installeer gh (als je dat nog niet hebt)
brew install gh

# Login
gh auth login

# Maak repository en push in één keer
gh repo create iou-concept-flevoland --public --source=. --push

# Activeer Pages
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/YOUR_USERNAME/iou-concept-flevoland/pages \
  -f source[branch]=main \
  -f source[path]=/
```

---

## Troubleshooting

### ❌ "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/iou-concept-flevoland.git
```

### ❌ "failed to push some refs"
```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### ❌ "Authentication failed"
- Gebruik een Personal Access Token als wachtwoord (zie Stap 2)
- Controleer of de token de `repo` scope heeft

### ❌ "404 Page Not Found" na deployment
- Wacht 1-2 minuten, GitHub Pages heeft tijd nodig om te bouwen
- Controleer of de branch `main` heet (niet `master`)
- Controleer of de repository Public is
