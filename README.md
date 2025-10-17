# IOU Concept - Informatie Ondersteunde Werkomgeving

Voorbeeldimplementatie van het **Informatie Ondersteunde Werkomgeving (IOU) concept** voor de Nederlandse overheid.

## Overzicht

Dit project demonstreert hoe het IOU-concept praktisch geïmplementeerd kan worden, met focus op:

- **Context-gedreven werken**: Alle informatie georganiseerd rondom het doel (zaak, project, beleid)
- **Compliance by Design**: Wet- en regelgeving (Woo, AVG, Archiefwet) automatisch ingeregeld
- **Integraal werken**: Eén geïntegreerde omgeving in plaats van informatiesilo's
- **AI-ondersteuning**: Automatische metadata-extractie en context-herkenning
- **Flexibele app-store**: Context-aware micro-services

## Kernprincipes (uit documentatie)

### 1. Organisatorische Context als Kern
De **Organisatorische Context (OC)** fungeert als het integrerend element:
- Uniforme beschrijving van organisatie, processen en informatie
- Vastgelegd in een informatiemodel
- Inclusief regelset voor automatische compliance

### 2. Compliance by Design
Wet- en regelgeving wordt integraal "onder de motorkap" ingeregeld:
- ✅ **Archiefwet**: Automatische bewaartermijnen
- ✅ **Woo**: Metadata voor openbaarmaking by design
- ✅ **AVG**: Privacy-classificatie bij creatie
- ✅ **BIO**: Informatiebeveiliging ingebakken

### 3. Context-Aware Werken
Informatiedomeinen worden samenwerkingsdomeinen:
- **Zaken**: Uitvoering (subsidies, vergunningen, bezwaren)
- **Projecten**: Tijdelijke samenwerkingsverbanden
- **Beleid**: Beleidsontwikkeling en evaluatie
- **Expertise**: Kennisdeling en samenwerking

### 4. Wendbaarheid
- Organisatie ingericht op **doel**, niet op rigide proces
- Regelruimte voor maatwerk door professionals
- Interoperabiliteit over organisatiegrenzen

## Project Structuur

```
IOU-concept/
├── docs/                           # Originele PDF documentatie
│   ├── IOU concept vanuit 3 perspectieven.pdf
│   └── Woo-implementatie suggesties.pdf
│
├── src/
│   ├── models/
│   │   └── organizational_context.sql    # Database schema (PostgreSQL)
│   │
│   ├── api/
│   │   └── context_service.py            # FastAPI REST API
│   │
│   ├── services/
│   │   └── ai_metadata_service.py        # AI/ML componenten
│   │
│   └── frontend/
│       ├── context_dashboard.html        # Hoofddashboard
│       ├── flevoland-theme.css          # Provincie Flevoland huisstijl
│       ├── document-detail-woo.html     # Woo-voorbeeld detail pagina
│       ├── related-domains.html         # Netwerk visualisatie
│       ├── ai-suggestions.html          # AI metadata suggesties
│       └── apps/                        # Context-aware applicaties
│           ├── data-explorer.html       # Data visualisatie (OpenStreetMap)
│           ├── document-generator.html
│           ├── stakeholder-mapper.html
│           ├── compliance-checker.html
│           ├── timeline-viewer.html
│           └── collaboration-hub.html
│
├── TESTDATA.md                     # Test scenario's en SQL voorbeelden
├── DEPLOYMENT.md                   # GitHub Pages deployment guide
└── README.md
```

## Componenten

### 1. Database Schema (`organizational_context.sql`)

Volledig relationeel datamodel met:

#### Organisatiestructuur
- `organizations`: Overheidsorganisaties
- `departments`: Afdelingen
- `roles`: Rollen met fijnmazig autorisatieschema
- `users`: Medewerkers

#### Informatiedomeinen (Context)
- `information_domains`: Generieke domeinen (zaak, project, beleid)
- `cases`: Specifiek voor zaken
- `projects`: Specifiek voor projecten
- `policy_topics`: Specifiek voor beleid

#### Informatie Objecten
- `information_objects`: Documenten, emails, data
  - Automatische metadata (created_by, timestamps)
  - Compliance velden (classification, retention_period, is_woo_relevant)
  - Full-text search support

#### Regelset & Compliance
- `business_rules`: Machine-leesbare regels
- `rule_executions`: Audit trail van regeltoepassing

#### Context-Aware Apps
- `apps`: Micro-services registry
- `user_app_usage`: Gebruiksstatistieken voor aanbevelingen

#### AI/ML Support
- `ai_metadata_suggestions`: AI-voorstellen voor metadata
- `ai_context_vectors`: Embeddings voor semantic search

#### Audit & Transparantie
- `audit_log`: Volledige audit trail van alle acties

**Belangrijke features**:
- Automatische triggers voor regeltoepassing
- Full-text search in het Nederlands
- Views voor verrijkte data
- Indexen voor performance

### 2. API Service (`context_service.py`)

FastAPI-based REST API met:

#### Kern Endpoints

**GET /context/{domain_id}**
Haalt volledige context op:
- Hoofddomein (zaak/project/beleid)
- Gerelateerde domeinen (netwerk)
- Recente documenten
- Aanbevolen apps (context-aware)
- Betrokken stakeholders
- Gebruiker permissions (fijnmazig)

**POST /domains**
Creëer nieuw informatiedomein met automatische metadata

**POST /objects**
Creëer informatieobject met compliance by design

**GET /search**
Context-aware semantic search (alleen toegankelijke data)

**GET /apps/recommended**
Context-gedreven app aanbevelingen

#### Security Features
- JWT-based authenticatie
- Fijnmazig autorisatieschema op basis van rollen
- Automatische audit logging
- Permission checks per context

### 3. AI/ML Service (`ai_metadata_service.py`)

Intelligente metadata-extractie en context-herkenning:

#### AIMetadataService
```python
# Gebruik:
ai_service = AIMetadataService()
suggestions = await ai_service.extract_metadata_from_document(
    content="Raadsvoorstel subsidie...",
    filename="2025-03-15_Raadsvoorstel_v2.pdf"
)
```

**Functionaliteit**:
1. **Named Entity Recognition**: Personen, organisaties, locaties
2. **Context detectie**: Automatisch vakgebied herkennen
3. **Juridische referenties**: Extract verwijzingen naar wetten
4. **Woo-relevantie**: Bepaal of openbaarmakingsplichtig
5. **Classificatie**: Openbaar/intern/vertrouwelijk
6. **Bewaartermijn**: Suggestie op basis van documenttype
7. **Tag generatie**: Automatische keywords
8. **Patroon herkenning**: Datum, versie uit bestandsnaam

#### ContextRecommendationEngine
- App-aanbevelingen op basis van context + gebruikshistorie
- Gerelateerde domeinen via semantic similarity

#### ComplianceRuleExtractor
- Vertaal wet/regelgeving naar machine-leesbare regels
- Voorbeeld: "Besluiten moeten 20 jaar bewaard" → `{retention_period: 20}`

### 4. Frontend Dashboard

Interactieve demo van de werkomgeving met **Provincie Flevoland huisstijl**:

#### Hoofddashboard (`context_dashboard.html`)
- Context-switcher (wissel tussen zaak/project/beleid)
- Context-aware app grid (6 klikbare apps)
- Recente documenten met automatische metadata
- Stakeholder overzicht
- Compliance status dashboard
- Gerelateerde projecten/zaken
- **Flevoland branding**: Blauw (#0066CC) en groen (#7CB342) kleurenschema

#### Detail Pagina's
- **`document-detail-woo.html`**: Real-world Woo-besluit met volledige metadata, timeline en compliance status
- **`related-domains.html`**: Netwerk visualisatie van gerelateerde domeinen met vis-network.js
- **`ai-suggestions.html`**: Interactieve AI metadata suggesties met accept/reject/modify functionaliteit

#### Context-Aware Apps (in `/apps`)
- **📊 Data Explorer**: OpenStreetMap visualisatie met Leaflet.js, interactieve provinciedata
- **📝 Document Generator**: Template-based document generatie met metadata
- **👥 Stakeholder Mapper**: Netwerk visualisatie van betrokken partijen
- **✅ Compliance Checker**: Automatische controle op Woo, AVG, Archiefwet
- **📅 Timeline Viewer**: Chronologisch overzicht van alle activiteiten
- **💬 Collaboration Hub**: Real-time samenwerking binnen context

#### Styling (`flevoland-theme.css`)
- CSS variabelen voor consistente huisstijl
- Gradient backgrounds met Flevoland kleuren
- Responsive design voor desktop en tablet
- Province-specific branding elementen

## Voordelen per Perspectief

### Voor de Ambtelijke Professional

✅ **Administratieve lasten verdwenen**
- Geen dubbele invoer
- Automatische compliance
- Metadata by design

✅ **Integraal en intuïtief werken**
- Alles binnen handbereik
- Eén geïntegreerde omgeving
- Niet constant inloggen

✅ **Vrijheid en flexibiliteit**
- Regelruimte voor maatwerk
- Organiseren op doel, niet op rigide proces

✅ **Naadloze samenwerking**
- Werken in context (zaak/project)
- Organisatieonafhankelijk

### Voor de Organisatie

✅ **Compliance by design**
- Woo, AVG, Archiefwet automatisch
- Intrinsiek veilige informatiehuishouding
- Fijnmazig autorisatieschema

✅ **Wendbaarheid**
- Complexe taken in eenvoudige organisatie
- Flexibel en aanpasbaar
- Effectieve uitvoering door ontzorging

✅ **Interoperabiliteit**
- Uniforme beschrijving over organisaties heen
- Samenwerking in ketens

### Voor de Architectuur

✅ **Modelgedreven architectuur**
- Organisatorische Context als kern
- Kenbaar en bestuurbaar (AL-5)
- Intelligentie in model, niet in code

✅ **Integratie zonder sanering**
- Information middleware over bestaand landschap
- Geen grote migratie nodig
- Verbindt silo's via model

✅ **Governance & compliance**
- Automatische metadatering (AL-6)
- Fijnmazig IAM
- Betrouwbare stuurinformatie

## Implementatie Roadmap

### Fase 1: Demonstrator ✅ (Voltooid)
- ✅ Database schema (PostgreSQL met volledige relaties)
- ✅ Basis API (FastAPI met JWT authenticatie)
- ✅ Frontend (volledig interactief met Flevoland huisstijl)
- ✅ Context-aware apps (6 werkende applicaties)
- ✅ OpenStreetMap integratie (Leaflet.js)
- ✅ Real-world Woo use case geïmplementeerd
- ✅ GitHub Pages deployment gereed

**Doel**: ✅ Visualiseren van het concept - **BEREIKT**

**Live demo**: [https://terminal-woo.github.io/iou-concept/](https://terminal-woo.github.io/iou-concept/)

### Fase 2: Proof of Concept (6 maanden)
- Eerste ML-model voor app recommendations
- Azure Form Recognizer voor PDF metadata
- Cognitive Search voor 1 informatiedomein
- Koppeling met 2-3 bestaande systemen

**Doel**: Valideren technische haalbaarheid

### Fase 3: Configureerbaar Platform (12 maanden)
- Custom models getraind op organisatie-data
- Feedback loops: AI leert van correcties
- Cross-domain synthese
- Volledige regelset-engine

**Doel**: Productie-ready systeem

## Technologie Stack

### Aanbevolen (Microsoft/Azure)
- **Database**: Azure PostgreSQL / Cosmos DB
- **API**: Azure Functions / App Service (Python FastAPI)
- **AI/ML**: 
  - Azure OpenAI (GPT-4) voor NLP
  - Azure Form Recognizer voor document parsing
  - Azure Cognitive Search voor semantic search
- **Frontend**: React/Vue.js met Azure Static Web Apps
- **Auth**: Azure AD B2C
- **Storage**: Azure Blob Storage

### Alternatieven
- **Database**: AWS RDS PostgreSQL
- **API**: AWS Lambda / ECS
- **AI/ML**:
  - Anthropic Claude voor NLP
  - AWS Textract voor documents
  - Elasticsearch + embeddings
- **Frontend**: Vercel/Netlify
- **Auth**: Auth0 / Cognito

## Installatie & Gebruik

### Vereisten
- PostgreSQL 14+
- Python 3.10+
- Node.js 18+ (voor frontend build tools)

### Database Setup
```bash
# Maak database aan
createdb iou_context

# Import schema
psql -d iou_context -f src/models/organizational_context.sql

# Optioneel: seed data
psql -d iou_context -f src/models/seed_data.sql
```

### API Starten
```bash
cd src/api
pip install -r requirements.txt

# Configureer database connectie
export DATABASE_URL="postgresql://user:pass@localhost/iou_context"

# Start API
python context_service.py
```

API beschikbaar op: `http://localhost:8000`

Swagger docs: `http://localhost:8000/docs`

### Frontend Openen

**Optie 1: GitHub Pages (aanbevolen)**
```bash
# Live demo direct beschikbaar:
https://terminal-woo.github.io/iou-concept/
```

**Optie 2: Lokaal - HTML direct openen**
```bash
# Hoofddashboard
open src/frontend/context_dashboard.html

# Woo detail pagina
open src/frontend/document-detail-woo.html

# Data Explorer met OpenStreetMap
open src/frontend/apps/data-explorer.html
```

**Optie 3: Lokaal - Met webserver**
```bash
# Start lokale server
cd src/frontend
python -m http.server 8080

# Open in browser:
# - Dashboard: http://localhost:8080/context_dashboard.html
# - Apps: http://localhost:8080/apps/data-explorer.html
# - Alle pagina's zijn klikbaar en volledig functioneel
```

### AI Service Testen
```bash
cd src/services
python ai_metadata_service.py
```

## Configuratie

### Database Connectie
Pas aan in `src/api/context_service.py`:
```python
db_pool = await asyncpg.create_pool(
    host="localhost",
    database="iou_context",
    user="iou_user",
    password="iou_password"
)
```

### AI Model Provider
In `src/services/ai_metadata_service.py`:
```python
# Voor productie: gebruik echte AI
ai_service = AIMetadataService(model_provider="openai")

# Of Azure:
ai_service = AIMetadataService(model_provider="azure")
```

## Use Cases (uit documentatie)

### 1. Subsidieaanvraag Windpark
**Context**: Zaak
- Automatisch juiste formulieren en werkproces
- Alle relevante wet- en regelgeving beschikbaar
- Stakeholders (aanvrager, adviseurs) automatisch gekoppeld
- Woo-relevantie gedetecteerd
- Bewaartermijn: 7 jaar na afronding

### 2. Project Circulaire Economie
**Context**: Project
- Data Explorer toont relevante cijfers
- Gerelateerde beleidsstukken automatisch getoond
- Samenwerking met andere organisaties (Gemeente Almere)
- Timeline van alle activiteiten
- Alle documentatie automatisch gearchiveerd

### 3. Beleidsontwikkeling Mobiliteit
**Context**: Beleid
- Overzicht van alle gerelateerde projecten en zaken
- Stakeholder netwerk (burgers, bedrijven, andere overheden)
- Historisch overzicht eerdere beleidsperiodes
- Automatische links naar uitvoering

### 4. Woo-verzoek Basiskaart Agrarische Bedrijfssituatie 2021

**Context**: Zaak (Woo-procedure)

**Real-world voorbeeld**: [Rijksoverheid.nl - Woo-besluit Basiskaart Agrarische Bedrijfssituatie](https://www.rijksoverheid.nl/documenten/publicaties/2025/10/07/openbaargemaakt-document-bij-besluit-woo-verzoek-over-basiskaart-agrarische-bedrijfssituatie-2021)

**Achtergrond**:
In februari 2023 ontvingen journalisten van NRC, Follow the Money en Omroep Gelderland toegang tot de Basiskaart Agrarische Bedrijfssituatie (BAB) van 2021 via een Woo-verzoek. De Rijksdienst voor Ondernemend Nederland (RVO) moest afwegen tussen openbaarheid en privacy van agrariërs.

**Hoe IOU dit ondersteunt**:

**Automatische Woo-herkenning**:
- AI detecteert formele Woo-verzoeken automatisch
- Classificatie: `is_woo_relevant = true`
- Wettelijke termijn bewaking (4 weken standaard, 8 weken met verlenging)
- UUID-generatie voor traceerbaarheid: `140b872e-26a2-433e-96d5-3d74f7fa981d`

**Compliance by Design workflow**:
1. **Ontvangst** (14-02-2023):
   - Verzoek automatisch geregistreerd als zaak
   - Derde-belanghebbenden (agrariërs) geïdentificeerd
   - Privacy Impact Assessment (PIA) getriggerd

2. **Beoordeling**:
   - AI suggereert welke gegevens openbaar kunnen
   - AVG-afweging: persoonsgegevens anonimiseren
   - Bedrijfsgevoelige informatie markeren voor weglakking
   - Juridisch advies automatisch gekoppeld

3. **Bekendmaking** (12-03-2023):
   - Voornemen gepubliceerd in Staatscourant (2023/4842)
   - Derde-belanghebbenden automatisch geïnformeerd
   - Bezwaartermijn (2 weken) ingepland

4. **Besluit** (04-05-2023):
   - Formeel Woo-besluit genomen
   - Metadata volledig: documenttype, wettelijke grondslag, bewaartermijn (permanent)
   - Gerelateerde documenten automatisch gekoppeld

5. **Publicatie** (07-10-2025):
   - Dataset (3.8 MB XLSX) openbaar gemaakt op rijksoverheid.nl
   - Open Data licentie: hergebruik toegestaan met bronvermelding
   - Automatische archivering als archiefwaardig document

**Betrokken stakeholders** (automatisch gekoppeld):
- Ministerie van Landbouw, Natuur en Voedselkwaliteit (verantwoordelijk)
- Rijksdienst voor Ondernemend Nederland (uitvoerend)
- Journalisten: NRC, Follow the Money, Omroep Gelderland (verzoekers)
- Agrarische sector (derde-belanghebbenden)

**AI-suggesties tijdens proces**:
- **Metadata-extractie**: Onderwerp (landbouw, diergezondheid, dierenwelzijn), tags
- **Classificatie**: Woo-besluit met dataset, publicatieplicht actief openbaar
- **Compliance-check**: AVG-waarborgen (geanonimiseerd), bewaartermijn permanent
- **Relatie-detectie**: Koppeling met eerdere Woo-besluiten over landbouwdata

**Meetbare resultaten**:
- ✅ Volledige compliance met Wet open overheid
- ✅ Privacy gewaarborgt (AVG)
- ✅ Transparantie: alle stappen gedocumenteerd en traceerbaar
- ✅ Tijdsbesparing: automatische metadata en relaties
- ✅ Herbruikbare data: Open Data formaat (XLSX)

**Lessons learned**:
- Balans tussen openbaarheid en privacy vereist zorgvuldige afweging
- Derde-belanghebbenden vroegtijdig betrekken cruciaal
- Anonimisering technisch complex bij grote datasets
- Juristen en data-specialisten moeten nauw samenwerken
- Automatische metadata versnelt proces aanzienlijk

Dit voorbeeld toont hoe het IOU-concept een complexe Woo-procedure ondersteunt van begin tot eind, met automatische compliance, stakeholder-management en transparante besluitvorming.

## Kritische Succesfactoren

### Wel doen ✅
1. Apps zijn context-sensitief, niet generiek
2. Metamodel-gedreven: apps volgen structuur
3. Opt-in: medewerkers kiezen eigen apps
4. Telemetrie: analyseren welke apps nuttig zijn
5. Start simpel, bouw incrementeel
6. Meet constant de toegevoegde waarde

### Niet doen ❌
1. Niet nog een applicatie-laag toevoegen (gebruik bestaande)
2. Niet apps verplicht stellen (keuzevrijheid)
3. Niet apps loskoppelen van compliance
4. Niet aparte login per app
5. Niet big-bang migratie
6. Niet AI als black box (explainability!)

## Risico's & Mitigatie

### AI Hallucination Risk
**Risico**: AI genereert onjuiste metadata
**Mitigatie**:
- Altijd bronverwijzingen tonen
- Confidence scores per suggestie
- Menselijke validatie voor kritische zaken
- Audit logs van alle AI-acties

### Privacy & Security
**Risico**: AI ziet gevoelige data
**Mitigatie**:
- On-premise AI-modellen (Azure OpenAI private)
- Data minimization: AI ziet metadata, niet content
- Volledige audit trail

### Black Box Beslissingen
**Risico**: Onduidelijk waarom AI iets aanbeveelt
**Mitigatie**:
- Explainable AI: "Deze app omdat [redenen]"
- Altijd override mogelijk door gebruiker
- Transparante regelset

## Meetbare Resultaten (KPI's)

1. **Time-to-information**: 50% sneller de juiste data vinden
2. **Metadata compliance**: 95%+ documenten met complete metadata
3. **App adoption**: 70% van aanbevelingen daadwerkelijk gebruikt
4. **Manual overrides**: <10% (AI is accuraat genoeg)
5. **Compliance violations**: 0 (by design)
6. **User satisfaction**: 8+/10

## Referenties

### Documentatie
- `IOU concept vanuit 3 perspectieven.pdf`: Kernprincipes
- `Woo-implementatie suggesties.pdf`: AI/ML implementatie
- `TESTDATA.md`: Test scenario's en SQL voorbeelden
- Real-world Woo voorbeeld: [Rijksoverheid.nl - Basiskaart Agrarische Bedrijfssituatie](https://www.rijksoverheid.nl/documenten/publicaties/2025/10/07/openbaargemaakt-document-bij-besluit-woo-verzoek-over-basiskaart-agrarische-bedrijfssituatie-2021)

### Architectuurprincipes
- **AL-0**: Wendbare architectuur
- **AL-2**: Compliance by design
- **AL-5**: Kenbaar en bestuurbaar
- **AL-6**: Automatische metadatering
- **IL-3**: Ontzorgen van professionals
- **OL-2**: Organiseren op doel
- **GL-1**: Optimale ondersteuning medewerkers

### Kernwaarden (Nationaal Archief)
1. Openheid en transparantie
2. Vindbaarheid
3. Toegankelijkheid
4. Integriteit en authenticiteit
5. Bestuurbaarheid

## Licentie

Dit is een demonstrator/proof of concept voor educatieve doeleinden.

## Contact & Bijdragen

Voor vragen over het IOU-concept of deze implementatie:
- Zie originele documentatie in `/docs`
- Architectuurprincipes zijn afgeleid uit officiële documenten

## Conclusie

Deze implementatie toont hoe het IOU-concept praktisch gerealiseerd kan worden:

- ✅ **Context-gedreven**: Alles georganiseerd rondom zaak/project/beleid
- ✅ **Compliance by design**: Woo, AVG, Archiefwet automatisch
- ✅ **AI-ondersteuning**: Metadata-extractie zonder extra werk
- ✅ **Wendbaar**: Bouw op bestaand landschap
- ✅ **Meetbaar**: Concrete KPI's voor succes
- ✅ **Visueel aantrekkelijk**: Provincie Flevoland huisstijl volledig geïmplementeerd
- ✅ **Direct toegankelijk**: Live demo beschikbaar via GitHub Pages

Het systeem ontlast professionals van administratieve taken en zorgt dat zij zich kunnen focussen op hun vakmanschap, terwijl de organisatie volledig compliant blijft.

### 🌐 Probeer de Live Demo

Bekijk de werkende demonstrator op: **[https://terminal-woo.github.io/iou-concept/](https://terminal-woo.github.io/iou-concept/)**

Alle features zijn volledig functioneel:
- 🏛️ Interactief dashboard met Flevoland branding
- 📊 OpenStreetMap data visualisatie
- 📄 Real-world Woo-voorbeeld
- 🔗 6 context-aware applicaties
- 🤖 AI metadata suggesties

**Testdata basis**: Het Woo-voorbeeld is gebaseerd op een echt besluit van de Nederlandse overheid voor transparantie in de landbouwsector.
