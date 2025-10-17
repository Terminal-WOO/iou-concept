# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a demonstration implementation of the **Informatie Ondersteunde Werkomgeving (IOU)** concept for Dutch government organizations. The system provides context-driven work environments with built-in compliance for Dutch laws (Woo, AVG, Archiefwet).

**Core principle**: All information is organized around organizational contexts (cases, projects, policies) with automatic compliance and AI-assisted metadata extraction.

## Technology Stack

- **Backend**: Python 3.10+ with FastAPI (async/await pattern)
- **Database**: PostgreSQL 15+ with full-text search support
- **AI/ML**: OpenAI/Azure OpenAI for NLP, spaCy for Dutch text processing
- **Frontend**: Vanilla HTML/CSS/JavaScript (no build step required)
- **Deployment**: Docker Compose for local, GitHub Pages for demo
- **Styling**: Custom CSS with Provincie Flevoland brand colors

## Development Commands

### Database Setup

```bash
# Create database
createdb iou_context

# Load schema (385 lines, comprehensive relational model)
psql -d iou_context -f src/models/organizational_context.sql

# Optional: load test data
psql -d iou_context -f src/models/seed_data.sql
```

### Running the API

```bash
# Install dependencies
pip install -r requirements.txt

# Configure database connection
export DATABASE_URL="postgresql://iou_user:iou_password@localhost/iou_context"

# Start API server (runs on port 8000)
cd src/api
python context_service.py
# or with uvicorn directly:
uvicorn src.api.context_service:app --reload --host 0.0.0.0 --port 8000

# API docs available at: http://localhost:8000/docs
```

### Running with Docker

```bash
# Start all services (postgres, api, frontend)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down

# Reset database
docker-compose down -v
docker-compose up -d
```

### Frontend Development

The frontend is static HTML/CSS/JS with no build step:

```bash
# Option 1: Open files directly in browser
open src/frontend/context_dashboard.html

# Option 2: Use local server (avoids CORS issues)
cd src/frontend
python -m http.server 8080
# Visit: http://localhost:8080/context_dashboard.html

# Option 3: View live demo
# https://terminal-woo.github.io/iou-concept/
```

### Testing

```bash
# Run tests (if test suite exists)
pytest tests/

# Run with coverage
pytest --cov=src tests/
```

## Architecture Overview

### Three-Layer Architecture

1. **Data Layer**: PostgreSQL with rich schema modeling Dutch government information architecture
2. **Service Layer**: FastAPI with async database access and AI integration
3. **Presentation Layer**: Static HTML with context-aware micro-applications

### Core Concepts

**Organizational Context (OC)**: Central integrating element that unifies organization, processes, and information according to uniform information model with automatic compliance rules.

**Information Domains**: Four primary context types:
- `zaak` (cases): Execution work (permits, subsidies, objections)
- `project`: Temporary collaboration initiatives
- `beleid` (policy): Policy development and evaluation
- `expertise`: Knowledge sharing and collaboration

**Compliance by Design**: Legal requirements (Woo transparency, AVG privacy, Archiefwet archival) are automatically enforced through database triggers and business rules engine.

### Database Schema Structure

The schema (`src/models/organizational_context.sql`) contains:

1. **Organization Structure** (`organizations`, `departments`, `roles`, `users`):
   - Multi-tenant support for government organizations
   - Fine-grained role-based permissions (JSONB column)
   - Temporal validity for user roles

2. **Information Domains** (`information_domains`, `cases`, `projects`, `policy_topics`):
   - Polymorphic design: base table + specialized tables
   - Each domain type has specific attributes (case_number, project_code, etc.)
   - Status tracking throughout lifecycle

3. **Information Objects** (`information_objects`):
   - Documents, emails, chat messages, decisions, data
   - Automatic compliance metadata: `classification`, `retention_period`, `is_woo_relevant`
   - Full-text search with Dutch language support
   - Version tracking and audit trail

4. **Business Rules Engine** (`business_rules`, `rule_executions`):
   - Machine-readable rules stored as JSONB
   - Automatic rule application via triggers
   - Complete audit trail of rule executions

5. **Context-Aware Apps** (`apps`, `user_app_usage`):
   - Micro-services registry
   - Usage statistics for ML-based recommendations
   - Apps are context-sensitive (shown based on domain type and user role)

6. **AI/ML Support** (`ai_metadata_suggestions`, `ai_context_vectors`):
   - Store AI-generated metadata suggestions with confidence scores
   - Vector embeddings for semantic search
   - User feedback loop (accept/reject/modify suggestions)

7. **Audit & Transparency** (`audit_log`):
   - Comprehensive audit trail for all actions
   - Required for Woo compliance and AVG accountability

### API Architecture

The FastAPI service (`src/api/context_service.py`) provides:

**Key Endpoints**:
- `GET /context/{domain_id}`: Retrieve complete context with related domains, documents, stakeholders, and recommended apps
- `POST /domains`: Create new information domain with automatic metadata
- `POST /objects`: Create information object with compliance by design
- `GET /search`: Context-aware semantic search (filtered by permissions)
- `GET /apps/recommended`: Context-driven app recommendations

**Security Model**:
- JWT-based authentication (Bearer token)
- Fine-grained authorization based on user roles and domain access
- Automatic audit logging for all mutations
- Permission checks enforce least-privilege access

**Async Pattern**: All database operations use `asyncpg` for non-blocking I/O.

### AI/ML Service

The `src/services/ai_metadata_service.py` provides three main components:

1. **AIMetadataService**: Extracts metadata from documents
   - Named Entity Recognition (persons, organizations, locations)
   - Subject area detection via keyword analysis
   - Legal reference extraction (e.g., "Wet open overheid")
   - Woo relevance assessment
   - Classification recommendation (openbaar/intern/vertrouwelijk)
   - Retention period suggestion based on document type
   - Tag generation

2. **ContextRecommendationEngine**: Suggests relevant apps
   - Based on current context (domain type, subject area)
   - User history and usage patterns
   - Collaborative filtering

3. **ComplianceRuleExtractor**: Converts legal text to machine-readable rules
   - Example: "Besluiten moeten 20 jaar bewaard" → `{"retention_period": 20}`

**Note**: Current implementation contains simulation logic. For production, integrate with Azure OpenAI or Anthropic Claude API.

### Frontend Architecture

Static HTML files with no build process. Key pages:

- `context_dashboard.html`: Main dashboard with context switcher
- `document-detail-woo.html`: Real-world Woo decision example
- `related-domains.html`: Network visualization (vis-network.js)
- `ai-suggestions.html`: Interactive AI metadata review interface
- `apps/*.html`: Six context-aware applications

**Styling**: `flevoland-theme.css` defines Provincie Flevoland brand (blue #0066CC, green #7CB342).

**JavaScript pattern**: Inline scripts with API calls to `http://localhost:8000`. Update API base URL for different environments.

## Important Patterns and Conventions

### Database Patterns

**Always use UUIDs** for primary keys: `gen_random_uuid()`

**Automatic timestamps**: Use triggers for `updated_at`:
```sql
CREATE TRIGGER update_timestamp
BEFORE UPDATE ON table_name
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**JSONB for flexible metadata**: Use for extensibility without schema changes:
```sql
metadata JSONB DEFAULT '{}'::jsonb
```

**Full-text search**: Use `tsvector` with Dutch configuration:
```sql
CREATE INDEX idx_fts ON information_objects 
USING gin(to_tsvector('dutch', title || ' ' || coalesce(content_text, '')));
```

### API Patterns

**Async everywhere**: All endpoints and database calls use `async`/`await`:
```python
@app.get("/context/{domain_id}")
async def get_context(domain_id: UUID4, pool: Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.fetchrow(query, domain_id)
```

**Dependency injection for DB pool**:
```python
async def get_db_pool() -> Pool:
    return db_pool

@app.get("/endpoint")
async def endpoint(pool: Pool = Depends(get_db_pool)):
    # use pool
```

**JWT authentication** on protected endpoints:
```python
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> Dict:
    token = credentials.credentials
    # validate and decode JWT
    return user_data
```

**Pydantic models** for validation: Define request/response models with type hints.

### AI/ML Patterns

**Always return confidence scores** with AI suggestions:
```python
@dataclass
class MetadataSuggestion:
    field: str
    value: Any
    confidence: float  # 0.0 - 1.0
    reasoning: str
```

**Store AI suggestions separately**: Don't auto-apply. Let users review and approve via `ai_metadata_suggestions` table.

**Feedback loop**: Track user accepts/rejects to improve model:
```sql
UPDATE ai_metadata_suggestions 
SET user_feedback = 'accepted'
WHERE id = $1;
```

## Compliance Requirements

### Woo (Wet open overheid)

Documents must have metadata for public disclosure:
- `is_woo_relevant`: Boolean flag
- `disclosure_class`: Classification (openbaar/gedeeltelijk_openbaar/niet_openbaar)
- Legal basis for non-disclosure if applicable
- 4-week response deadline (8 weeks with extension)

### AVG (GDPR)

Personal data requires:
- `privacy_level`: normaal/bijzonder/strafrechtelijk
- `data_subjects`: List of categories
- Legal basis for processing
- Retention period based on purpose

### Archiefwet

All information objects need:
- `retention_period`: Years to retain
- `archival_value`: permanent/temporary
- Automated calculation based on business rules

## Key Files to Know

- `src/models/organizational_context.sql` (385 lines): Complete database schema with triggers and indexes
- `src/api/context_service.py` (500+ lines): Main API service with all endpoints
- `src/services/ai_metadata_service.py` (400+ lines): AI/ML integration logic
- `src/frontend/context_dashboard.html`: Primary user interface
- `src/frontend/flevoland-theme.css`: Brand styling
- `TESTDATA.md`: Test scenarios and example SQL queries
- `requirements.txt`: Python dependencies (FastAPI, asyncpg, OpenAI, spaCy, etc.)
- `docker-compose.yml`: Container orchestration

## Deployment

### GitHub Pages (Current Demo)

Static HTML files deployed via `deploy-github-pages.sh`:
```bash
./deploy-github-pages.sh
```

See `DEPLOYMENT.md` for details.

### Production Deployment

Recommended Azure stack:
- **Database**: Azure PostgreSQL Flexible Server
- **API**: Azure Container Apps or App Service
- **AI**: Azure OpenAI Service (GPT-4)
- **Search**: Azure Cognitive Search
- **Storage**: Azure Blob Storage for documents
- **Auth**: Azure AD B2C

Environment variables:
```bash
DATABASE_URL=postgresql://...
AZURE_OPENAI_ENDPOINT=https://...
AZURE_OPENAI_KEY=...
JWT_SECRET=...
```

## Testing Strategy

Use `TESTDATA.md` for test scenarios:
- 5 organizations (Provincie Flevoland, Gemeente Almere, etc.)
- 8 users with different roles
- 4 projects, 5 cases, 3 policy topics
- Real-world Woo example: "Basiskaart Agrarische Bedrijfssituatie 2021"

## Common Pitfalls

1. **Don't forget database connection pooling**: Use `asyncpg.create_pool()`, not individual connections
2. **Dutch language models**: Use `nl_core_news_lg` for spaCy, not English models
3. **Permission checks**: Always verify user has access to domain before returning data
4. **Audit everything**: Insert audit log entry for all create/update/delete operations
5. **UUID handling**: Convert between string and UUID4 types correctly in Pydantic models
6. **CORS**: Configure FastAPI CORS middleware if frontend is on different domain
7. **Full-text search**: Use `to_tsvector('dutch', ...)` for proper Dutch language support

## Language and Terminology

This is a Dutch government project. Use Dutch terminology:
- Zaak (case), niet "case"
- Informatiedomein (information domain)
- Wet open overheid (Woo), not WOO
- Organisatorische Context (OC)
- Compliance by Design (keep English)

Code comments and documentation should be in Dutch for authenticity, but English is acceptable for technical implementation details.

## Related Documentation

- Original concept PDF: `docs/IOU concept vanuit 3 perspectieven.pdf`
- Woo implementation guide: `docs/Woo-implementatie suggesties.pdf`
- Architecture principles referenced: AL-0, AL-2, AL-5, AL-6, IL-3, OL-2, GL-1
- Real Woo example: https://www.rijksoverheid.nl/documenten/publicaties/2025/10/07/openbaargemaakt-document-bij-besluit-woo-verzoek-over-basiskaart-agrarische-bedrijfssituatie-2021
