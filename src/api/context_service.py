"""
Context-Aware API Service
Implementatie van de Organisatorische Context API volgens IOU-principes
"""

from fastapi import FastAPI, Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, UUID4
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum
import asyncpg
from asyncpg.pool import Pool

app = FastAPI(
    title="IOU Context Service",
    description="Context-aware API voor Informatie Ondersteunde Werkomgeving",
    version="1.0.0"
)

security = HTTPBearer()

# ============================================
# MODELS (Pydantic)
# ============================================

class DomainType(str, Enum):
    ZAAK = "zaak"
    PROJECT = "project"
    BELEID = "beleid"
    EXPERTISE = "expertise"

class ObjectType(str, Enum):
    DOCUMENT = "document"
    EMAIL = "email"
    CHAT = "chat"
    BESLUIT = "besluit"
    DATA = "data"

class Classification(str, Enum):
    OPENBAAR = "openbaar"
    INTERN = "intern"
    VERTROUWELIJK = "vertrouwelijk"
    GEHEIM = "geheim"

class InformationDomain(BaseModel):
    id: Optional[UUID4] = None
    type: DomainType
    name: str
    description: Optional[str]
    status: str = "actief"
    organization_id: UUID4
    owner_user_id: Optional[UUID4]
    metadata: Optional[Dict[str, Any]] = {}
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class InformationObject(BaseModel):
    id: Optional[UUID4] = None
    domain_id: UUID4
    object_type: ObjectType
    title: str
    content_location: str
    mime_type: Optional[str]

    # Compliance metadata (automatisch)
    classification: Classification = Classification.INTERN
    retention_period: Optional[int] = None
    is_woo_relevant: bool = False
    privacy_level: Optional[str] = "normaal"

    # Vindbaarheid
    tags: List[str] = []
    metadata: Optional[Dict[str, Any]] = {}

    created_by: UUID4
    created_at: Optional[datetime] = None

class Case(BaseModel):
    id: Optional[UUID4] = None
    case_number: str
    case_type: str
    subject: str
    start_date: date
    target_date: Optional[date]
    legal_basis: Optional[str]
    retention_period: Optional[int]
    disclosure_class: Optional[str]

class App(BaseModel):
    id: UUID4
    name: str
    description: str
    app_type: str
    icon_url: Optional[str]
    endpoint_url: str
    relevant_for_domain_types: List[str]
    relevant_for_roles: List[str]

class AppRecommendation(BaseModel):
    app: App
    relevance_score: float
    reason: str

class ContextResponse(BaseModel):
    """
    Centrale response die volledige context voor gebruiker bevat
    """
    current_domain: InformationDomain
    related_domains: List[InformationDomain]
    recent_objects: List[InformationObject]
    recommended_apps: List[AppRecommendation]
    stakeholders: List[Dict[str, Any]]
    user_permissions: Dict[str, bool]

# ============================================
# DATABASE CONNECTION
# ============================================

db_pool: Optional[Pool] = None

async def get_db_pool() -> Pool:
    global db_pool
    if db_pool is None:
        db_pool = await asyncpg.create_pool(
            host="localhost",
            database="iou_context",
            user="iou_user",
            password="iou_password",
            min_size=5,
            max_size=20
        )
    return db_pool

@app.on_event("startup")
async def startup():
    await get_db_pool()

@app.on_event("shutdown")
async def shutdown():
    if db_pool:
        await db_pool.close()

# ============================================
# AUTHENTICATION & AUTHORIZATION
# ============================================

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    pool: Pool = Depends(get_db_pool)
) -> Dict[str, Any]:
    """
    Valideert token en haalt gebruiker op met rollen en permissions
    Fijnmazig autorisatieschema op basis van bedrijfslogica
    """
    token = credentials.credentials

    # In productie: valideer JWT token
    # Voor demo: simpele opzoek
    async with pool.acquire() as conn:
        user = await conn.fetchrow("""
            SELECT u.*, d.name as department_name, o.name as organization_name
            FROM users u
            JOIN departments d ON u.department_id = d.id
            JOIN organizations o ON d.organization_id = o.id
            WHERE u.id = $1 AND u.active = true
        """, token)

        if not user:
            raise HTTPException(status_code=401, detail="Invalid authentication")

        # Haal permissions op
        permissions = await conn.fetch("""
            SELECT r.name, r.permissions
            FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = $1
            AND (ur.valid_until IS NULL OR ur.valid_until > CURRENT_TIMESTAMP)
        """, user['id'])

        return {
            "id": user['id'],
            "name": user['name'],
            "email": user['email'],
            "department": user['department_name'],
            "organization": user['organization_name'],
            "permissions": {p['name']: p['permissions'] for p in permissions}
        }

# ============================================
# API ENDPOINTS
# ============================================

@app.get("/")
async def root():
    return {
        "service": "IOU Context Service",
        "version": "1.0.0",
        "description": "Context-aware API voor Informatie Ondersteunde Werkomgeving"
    }

@app.get("/context/{domain_id}", response_model=ContextResponse)
async def get_context(
    domain_id: UUID4,
    user: Dict = Depends(get_current_user),
    pool: Pool = Depends(get_db_pool)
):
    """
    Kernendpoint: Haalt volledige context op voor een informatiedomein
    Principe: "Alles binnen handbereik" - integraal en op maat
    """
    async with pool.acquire() as conn:
        # 1. Haal hoofddomein op
        domain = await conn.fetchrow("""
            SELECT * FROM information_domains WHERE id = $1
        """, domain_id)

        if not domain:
            raise HTTPException(status_code=404, detail="Domain not found")

        # Autorisatie check
        has_access = await check_domain_access(conn, domain_id, user['id'])
        if not has_access:
            raise HTTPException(status_code=403, detail="Access denied")

        # 2. Gerelateerde domeinen (netwerk)
        related = await conn.fetch("""
            SELECT id.*, dr.relation_type
            FROM domain_relations dr
            JOIN information_domains id ON dr.to_domain_id = id.id
            WHERE dr.from_domain_id = $1
            LIMIT 10
        """, domain_id)

        # 3. Recente informatieobjecten in deze context
        objects = await conn.fetch("""
            SELECT * FROM v_enriched_information_objects
            WHERE domain_id = $1
            ORDER BY created_at DESC
            LIMIT 20
        """, domain_id)

        # 4. Context-aware app recommendations
        apps = await get_recommended_apps(conn, domain['type'], user['id'], domain_id)

        # 5. Betrokken stakeholders
        stakeholders = await conn.fetch("""
            SELECT s.*, ds.role
            FROM domain_stakeholders ds
            JOIN stakeholders s ON ds.stakeholder_id = s.id
            WHERE ds.domain_id = $1
        """, domain_id)

        # 6. Gebruiker permissions voor deze context
        permissions = await get_context_permissions(conn, domain_id, user['id'])

        # Log access (audit trail)
        await conn.execute("""
            INSERT INTO audit_log (user_id, action, object_type, object_id, domain_id)
            VALUES ($1, 'read', 'domain', $2, $2)
        """, user['id'], domain_id)

        return ContextResponse(
            current_domain=InformationDomain(**dict(domain)),
            related_domains=[InformationDomain(**dict(r)) for r in related],
            recent_objects=[InformationObject(**dict(o)) for o in objects],
            recommended_apps=apps,
            stakeholders=[dict(s) for s in stakeholders],
            user_permissions=permissions
        )

@app.post("/domains", response_model=InformationDomain)
async def create_domain(
    domain: InformationDomain,
    user: Dict = Depends(get_current_user),
    pool: Pool = Depends(get_db_pool)
):
    """
    Creëer nieuw informatiedomein (zaak, project, etc.)
    Metadata wordt automatisch toegepast (by design)
    """
    async with pool.acquire() as conn:
        # Automatische metadata via regelset
        enriched_metadata = await apply_domain_rules(conn, domain)

        result = await conn.fetchrow("""
            INSERT INTO information_domains
            (type, name, description, status, organization_id, owner_user_id, metadata)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
        """, domain.type, domain.name, domain.description, domain.status,
            domain.organization_id, user['id'], enriched_metadata)

        # Audit log
        await conn.execute("""
            INSERT INTO audit_log (user_id, action, object_type, object_id, domain_id)
            VALUES ($1, 'create', 'domain', $2, $2)
        """, user['id'], result['id'])

        return InformationDomain(**dict(result))

@app.post("/objects", response_model=InformationObject)
async def create_information_object(
    obj: InformationObject,
    user: Dict = Depends(get_current_user),
    pool: Pool = Depends(get_db_pool)
):
    """
    Creëer informatieobject binnen een domein
    Compliance metadata wordt automatisch toegepast (by design)
    """
    async with pool.acquire() as conn:
        # Check domain access
        has_access = await check_domain_access(conn, obj.domain_id, user['id'])
        if not has_access:
            raise HTTPException(status_code=403, detail="Access denied to domain")

        # Haal domain op voor context
        domain = await conn.fetchrow("""
            SELECT * FROM information_domains WHERE id = $1
        """, obj.domain_id)

        # Pas automatisch regelset toe (Compliance by Design)
        compliance_data = await apply_compliance_rules(
            conn, obj, domain['type']
        )

        result = await conn.fetchrow("""
            INSERT INTO information_objects (
                domain_id, object_type, title, content_location, mime_type,
                classification, retention_period, is_woo_relevant, privacy_level,
                tags, metadata, created_by
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING *
        """, obj.domain_id, obj.object_type, obj.title, obj.content_location,
            obj.mime_type, compliance_data['classification'],
            compliance_data['retention_period'], compliance_data['is_woo_relevant'],
            obj.privacy_level, obj.tags, obj.metadata, user['id'])

        # Audit log
        await conn.execute("""
            INSERT INTO audit_log (user_id, action, object_type, object_id, domain_id)
            VALUES ($1, 'create', 'information_object', $2, $3)
        """, user['id'], result['id'], obj.domain_id)

        return InformationObject(**dict(result))

@app.get("/search")
async def search_information(
    q: str,
    domain_id: Optional[UUID4] = None,
    object_type: Optional[ObjectType] = None,
    user: Dict = Depends(get_current_user),
    pool: Pool = Depends(get_db_pool)
):
    """
    Context-aware semantic search
    Zoekt alleen in domeinen waar gebruiker toegang tot heeft
    """
    async with pool.acquire() as conn:
        query = """
            SELECT io.*, id.name as domain_name, id.type as domain_type
            FROM information_objects io
            JOIN information_domains id ON io.domain_id = id.id
            WHERE full_text_search @@ to_tsquery('dutch', $1)
        """
        params = [q]

        if domain_id:
            query += " AND io.domain_id = $2"
            params.append(domain_id)

        if object_type:
            query += f" AND io.object_type = ${len(params) + 1}"
            params.append(object_type.value)

        # Alleen resultaten waar gebruiker toegang toe heeft
        query += """
            AND EXISTS (
                SELECT 1 FROM check_domain_access(id.id, $1)
            )
        """
        params[0] = user['id']

        query += " ORDER BY ts_rank(full_text_search, to_tsquery('dutch', $1)) DESC LIMIT 50"

        results = await conn.fetch(query, *params)

        return {"results": [dict(r) for r in results], "count": len(results)}

@app.get("/apps/recommended")
async def get_recommended_apps_endpoint(
    domain_id: Optional[UUID4] = None,
    user: Dict = Depends(get_current_user),
    pool: Pool = Depends(get_db_pool)
):
    """
    Context-aware app recommendations
    Apps worden voorgesteld op basis van context, rol en gebruikshistorie
    """
    async with pool.acquire() as conn:
        domain_type = None
        if domain_id:
            domain = await conn.fetchrow(
                "SELECT type FROM information_domains WHERE id = $1", domain_id
            )
            domain_type = domain['type'] if domain else None

        apps = await get_recommended_apps(conn, domain_type, user['id'], domain_id)
        return {"recommendations": apps}

# ============================================
# HELPER FUNCTIONS
# ============================================

async def check_domain_access(conn, domain_id: UUID4, user_id: UUID4) -> bool:
    """
    Fijnmazige autorisatie: check of gebruiker toegang heeft tot domein
    Op basis van rollen, permissions en domein-specifieke regels
    """
    result = await conn.fetchval("""
        SELECT EXISTS(
            SELECT 1 FROM information_domains id
            JOIN organizations o ON id.organization_id = o.id
            JOIN departments d ON o.id = d.organization_id
            JOIN users u ON d.id = u.department_id
            WHERE id.id = $1 AND u.id = $2
        )
    """, domain_id, user_id)
    return result

async def apply_domain_rules(conn, domain: InformationDomain) -> Dict[str, Any]:
    """
    Pas automatisch regelset toe bij aanmaken domein
    """
    metadata = domain.metadata or {}

    # Haal toepasselijke regels op
    rules = await conn.fetch("""
        SELECT * FROM business_rules
        WHERE active = true
        AND $1 = ANY(applies_to_domain_types)
    """, domain.type.value)

    for rule in rules:
        # Voer regel uit (vereenvoudigd)
        if rule['rule_category'] == 'archivering':
            metadata['archiving_applied'] = True

    return metadata

async def apply_compliance_rules(
    conn, obj: InformationObject, domain_type: str
) -> Dict[str, Any]:
    """
    Compliance by Design: pas automatisch wet- en regelgeving toe
    - Archivering
    - WOO
    - AVG
    - BIO
    """
    rules = await conn.fetch("""
        SELECT * FROM business_rules
        WHERE active = true
        AND $1 = ANY(applies_to_object_types)
        AND (applies_to_domain_types IS NULL OR $2 = ANY(applies_to_domain_types))
        ORDER BY rule_category
    """, obj.object_type.value, domain_type)

    compliance = {
        'classification': obj.classification.value,
        'retention_period': obj.retention_period,
        'is_woo_relevant': obj.is_woo_relevant
    }

    # Pas regels toe
    for rule in rules:
        logic = rule['rule_logic']
        if rule['rule_category'] == 'archivering':
            compliance['retention_period'] = logic.get('retention_years', 7)
        elif rule['rule_category'] == 'woo':
            compliance['is_woo_relevant'] = True

    return compliance

async def get_recommended_apps(
    conn, domain_type: Optional[str], user_id: UUID4, domain_id: Optional[UUID4]
) -> List[AppRecommendation]:
    """
    Context-aware app recommendations
    Op basis van:
    1. Domain type
    2. Gebruikersrol
    3. Gebruikshistorie
    4. AI-voorspelling (toekomstig)
    """
    query = """
        SELECT
            a.*,
            COALESCE(SUM(uau.usage_count), 0) as usage_count,
            CASE
                WHEN $1::text = ANY(a.relevant_for_domain_types) THEN 10
                ELSE 0
            END as domain_relevance
        FROM apps a
        LEFT JOIN user_app_usage uau ON a.id = uau.app_id AND uau.user_id = $2
        WHERE a.active = true
        GROUP BY a.id
        ORDER BY domain_relevance DESC, usage_count DESC
        LIMIT 5
    """

    apps = await conn.fetch(query, domain_type, user_id)

    recommendations = []
    for app in apps:
        score = (app['domain_relevance'] + app['usage_count']) / 15.0
        reason = []
        if app['domain_relevance'] > 0:
            reason.append(f"Relevant voor {domain_type}")
        if app['usage_count'] > 0:
            reason.append(f"Je hebt deze {app['usage_count']}x gebruikt")

        recommendations.append(AppRecommendation(
            app=App(**dict(app)),
            relevance_score=min(score, 1.0),
            reason=" | ".join(reason) if reason else "Populaire app"
        ))

    return recommendations

async def get_context_permissions(
    conn, domain_id: UUID4, user_id: UUID4
) -> Dict[str, bool]:
    """
    Bepaal wat gebruiker mag doen binnen deze context
    Fijnmazig autorisatieschema
    """
    permissions = await conn.fetchrow("""
        SELECT
            bool_or(r.permissions->>'can_read' = 'true') as can_read,
            bool_or(r.permissions->>'can_write' = 'true') as can_write,
            bool_or(r.permissions->>'can_delete' = 'true') as can_delete,
            bool_or(r.permissions->>'can_share' = 'true') as can_share
        FROM user_roles ur
        JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = $1
        AND (ur.valid_until IS NULL OR ur.valid_until > CURRENT_TIMESTAMP)
    """, user_id)

    return {
        "can_read": permissions['can_read'] or False,
        "can_write": permissions['can_write'] or False,
        "can_delete": permissions['can_delete'] or False,
        "can_share": permissions['can_share'] or False
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
