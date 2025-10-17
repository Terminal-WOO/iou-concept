-- Organisatorische Context Database Schema
-- Gebaseerd op IOU-concept: Informatie Ondersteunde Werkomgeving

-- ============================================
-- 1. ORGANISATIE STRUCTUUR
-- ============================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'gemeente', 'provincie', 'rijk', etc.
    parent_org_id UUID REFERENCES organizations(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    parent_dept_id UUID REFERENCES departments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    department_id UUID REFERENCES departments(id),
    permissions JSONB, -- Fijnmazig autorisatieschema
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    department_id UUID REFERENCES departments(id),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

-- ============================================
-- 2. INFORMATIEDOMEINEN (Context)
-- ============================================

CREATE TABLE information_domains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL, -- 'zaak', 'project', 'beleid', 'expertise'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50), -- 'actief', 'afgerond', 'gearchiveerd'
    organization_id UUID NOT NULL REFERENCES organizations(id),
    owner_user_id UUID REFERENCES users(id),
    metadata JSONB, -- Automatische metadata volgens OC
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Zaken (Cases)
CREATE TABLE cases (
    id UUID PRIMARY KEY REFERENCES information_domains(id),
    case_number VARCHAR(50) UNIQUE NOT NULL,
    case_type VARCHAR(100) NOT NULL, -- 'subsidie', 'vergunning', 'bezwaar', etc.
    subject VARCHAR(500) NOT NULL,
    citizen_id UUID, -- Link naar betrokken burger
    start_date DATE NOT NULL,
    target_date DATE,
    completion_date DATE,
    legal_basis VARCHAR(255), -- Juridische grondslag
    retention_period INTEGER, -- Bewaartermijn (jaren)
    disclosure_class VARCHAR(50) -- WOO classificatie
);

-- Projecten
CREATE TABLE projects (
    id UUID PRIMARY KEY REFERENCES information_domains(id),
    project_code VARCHAR(50) UNIQUE NOT NULL,
    budget DECIMAL(12,2),
    start_date DATE,
    end_date DATE,
    project_phase VARCHAR(50) -- 'initiatief', 'definitie', 'ontwerp', 'realisatie', 'nazorg'
);

-- Beleidsonderwerpen
CREATE TABLE policy_topics (
    id UUID PRIMARY KEY REFERENCES information_domains(id),
    policy_area VARCHAR(100), -- 'mobiliteit', 'duurzaamheid', 'economie', etc.
    policy_cycle VARCHAR(50), -- 'voorbereiding', 'vaststelling', 'uitvoering', 'evaluatie'
    responsible_department_id UUID REFERENCES departments(id)
);

-- ============================================
-- 3. INFORMATIE OBJECTEN
-- ============================================

CREATE TABLE information_objects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES information_domains(id),
    object_type VARCHAR(50) NOT NULL, -- 'document', 'email', 'chat', 'besluit', 'data'
    title VARCHAR(500) NOT NULL,
    content_location VARCHAR(1000), -- URL of pad naar werkelijke content
    mime_type VARCHAR(100),
    size_bytes BIGINT,
    checksum VARCHAR(64), -- SHA-256 voor integriteit

    -- Automatische metadata (by design)
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES users(id),
    modified_at TIMESTAMP,

    -- Compliance metadata (automatisch toegepast)
    classification VARCHAR(50), -- 'openbaar', 'intern', 'vertrouwelijk', 'geheim'
    retention_period INTEGER, -- In jaren
    retention_trigger VARCHAR(100), -- 'afsluiting zaak', 'projecteinde', etc.
    destruction_date DATE,
    is_woo_relevant BOOLEAN DEFAULT false,
    woo_publication_date DATE,
    privacy_level VARCHAR(50), -- AVG classificatie

    -- Vindbaarheid
    full_text_search TSVECTOR,
    tags VARCHAR(100)[],

    metadata JSONB -- Extra context-specifieke metadata
);

-- Full-text search index
CREATE INDEX idx_info_objects_fts ON information_objects USING GIN(full_text_search);
CREATE INDEX idx_info_objects_domain ON information_objects(domain_id);
CREATE INDEX idx_info_objects_type ON information_objects(object_type);

-- ============================================
-- 4. RELATIES & NETWERK
-- ============================================

CREATE TABLE stakeholders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL, -- 'burger', 'bedrijf', 'organisatie', 'intern'
    name VARCHAR(255) NOT NULL,
    contact_details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE domain_stakeholders (
    domain_id UUID REFERENCES information_domains(id),
    stakeholder_id UUID REFERENCES stakeholders(id),
    role VARCHAR(100), -- 'aanvrager', 'adviseur', 'belanghebbende', etc.
    PRIMARY KEY (domain_id, stakeholder_id)
);

CREATE TABLE domain_relations (
    from_domain_id UUID REFERENCES information_domains(id),
    to_domain_id UUID REFERENCES information_domains(id),
    relation_type VARCHAR(100), -- 'gerelateerd_aan', 'voortvloeit_uit', 'onderdeel_van'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (from_domain_id, to_domain_id, relation_type)
);

-- ============================================
-- 5. REGELSET (Compliance by Design)
-- ============================================

CREATE TABLE business_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name VARCHAR(255) NOT NULL,
    rule_category VARCHAR(100), -- 'archivering', 'woo', 'avg', 'bio', 'autorisatie'
    legal_basis VARCHAR(500), -- Verwijzing naar wet/regelgeving
    rule_logic JSONB, -- Machine-leesbare regel
    applies_to_domain_types VARCHAR(50)[], -- ['zaak', 'project']
    applies_to_object_types VARCHAR(50)[], -- ['document', 'email']
    active BOOLEAN DEFAULT true,
    valid_from DATE,
    valid_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Voorbeeld regellogica in JSONB:
-- {
--   "conditions": [
--     {"field": "case.case_type", "operator": "equals", "value": "subsidie"},
--     {"field": "case.completion_date", "operator": "is_not_null"}
--   ],
--   "actions": [
--     {"set_field": "retention_period", "value": 7},
--     {"set_field": "retention_trigger", "value": "afsluiting zaak"},
--     {"set_field": "is_woo_relevant", "value": true}
--   ]
-- }

CREATE TABLE rule_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES business_rules(id),
    object_id UUID REFERENCES information_objects(id),
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_result JSONB, -- Logging van wat er gebeurd is
    success BOOLEAN
);

-- ============================================
-- 6. APPS & SERVICES (Context-Aware Appstore)
-- ============================================

CREATE TABLE apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    app_type VARCHAR(100), -- 'data_explorer', 'document_generator', 'compliance_checker'
    icon_url VARCHAR(500),
    endpoint_url VARCHAR(500), -- Micro-service endpoint

    -- Context-relevantie
    relevant_for_domain_types VARCHAR(50)[],
    relevant_for_roles VARCHAR(100)[],
    required_permissions JSONB,

    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_app_usage (
    user_id UUID REFERENCES users(id),
    app_id UUID REFERENCES apps(id),
    domain_id UUID REFERENCES information_domains(id), -- Context waarin app gebruikt werd
    usage_count INTEGER DEFAULT 1,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, app_id, domain_id)
);

-- ============================================
-- 7. AI/ML METADATA & LEARNING
-- ============================================

CREATE TABLE ai_metadata_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    object_id UUID REFERENCES information_objects(id),
    suggestion_type VARCHAR(100), -- 'tag', 'classification', 'related_domain', 'retention'
    suggested_value TEXT,
    confidence_score DECIMAL(3,2), -- 0.00 - 1.00
    model_version VARCHAR(50),
    accepted BOOLEAN,
    accepted_by UUID REFERENCES users(id),
    accepted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ai_context_vectors (
    domain_id UUID PRIMARY KEY REFERENCES information_domains(id),
    embedding VECTOR(1536), -- Voor semantic search (bijv. OpenAI embeddings)
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 8. AUDIT & TRANSPARANTIE
-- ============================================

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- 'create', 'read', 'update', 'delete', 'access'
    object_type VARCHAR(50),
    object_id UUID,
    domain_id UUID REFERENCES information_domains(id),
    ip_address INET,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_domain ON audit_log(domain_id);
CREATE INDEX idx_audit_timestamp ON audit_log(timestamp);

-- ============================================
-- 9. VIEWS VOOR GEBRUIKSGEMAK
-- ============================================

-- Context-rijke view van informatieobjecten
CREATE VIEW v_enriched_information_objects AS
SELECT
    io.*,
    id_domain.name as domain_name,
    id_domain.type as domain_type,
    u_created.name as created_by_name,
    u_modified.name as modified_by_name,
    org.name as organization_name
FROM information_objects io
JOIN information_domains id_domain ON io.domain_id = id_domain.id
JOIN users u_created ON io.created_by = u_created.id
LEFT JOIN users u_modified ON io.modified_by = u_modified.id
JOIN organizations org ON id_domain.organization_id = org.id;

-- Aanbevolen apps per gebruiker/context
CREATE VIEW v_recommended_apps AS
SELECT
    u.id as user_id,
    u.name as user_name,
    a.id as app_id,
    a.name as app_name,
    a.description,
    COUNT(uau.usage_count) as total_usage,
    MAX(uau.last_used_at) as last_used
FROM users u
CROSS JOIN apps a
LEFT JOIN user_app_usage uau ON u.id = uau.user_id AND a.id = uau.app_id
WHERE a.active = true
GROUP BY u.id, u.name, a.id, a.name, a.description
ORDER BY total_usage DESC;

-- ============================================
-- 10. FUNCTIES VOOR REGELTOEPASSING
-- ============================================

-- Functie om automatisch metadata toe te passen op basis van regelset
CREATE OR REPLACE FUNCTION apply_business_rules()
RETURNS TRIGGER AS $$
DECLARE
    rule RECORD;
BEGIN
    -- Loop door alle actieve regels die van toepassing zijn
    FOR rule IN
        SELECT * FROM business_rules
        WHERE active = true
        AND (valid_from IS NULL OR valid_from <= CURRENT_DATE)
        AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
        AND NEW.object_type = ANY(applies_to_object_types)
    LOOP
        -- Hier zou de regellogica worden toegepast
        -- Dit is vereenvoudigd; in productie zou dit complexer zijn
        INSERT INTO rule_executions (rule_id, object_id, success, execution_result)
        VALUES (rule.id, NEW.id, true, '{"applied": true}'::jsonb);
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_apply_rules
AFTER INSERT ON information_objects
FOR EACH ROW
EXECUTE FUNCTION apply_business_rules();

-- Functie voor automatische full-text search vector
CREATE OR REPLACE FUNCTION update_fts_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.full_text_search := to_tsvector('dutch',
        coalesce(NEW.title, '') || ' ' ||
        coalesce(array_to_string(NEW.tags, ' '), '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fts
BEFORE INSERT OR UPDATE ON information_objects
FOR EACH ROW
EXECUTE FUNCTION update_fts_vector();

-- ============================================
-- 11. INDEXEN VOOR PERFORMANCE
-- ============================================

CREATE INDEX idx_domains_org ON information_domains(organization_id);
CREATE INDEX idx_domains_type ON information_domains(type);
CREATE INDEX idx_domains_status ON information_domains(status);
CREATE INDEX idx_users_dept ON users(department_id);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_cases_type ON cases(case_type);
CREATE INDEX idx_cases_dates ON cases(start_date, completion_date);
CREATE INDEX idx_projects_dates ON projects(start_date, end_date);

-- ============================================
-- EINDE SCHEMA
-- ============================================
