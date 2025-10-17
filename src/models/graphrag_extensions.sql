-- ============================================
-- GraphRAG Extensions voor IOU Context
-- Automatische context-relatie detectie via kennisgraaf
-- ============================================

-- Dit schema breidt het basis IOU-schema uit met GraphRAG capabilities
-- voor automatische ontdekking van context-relaties

-- ============================================
-- 1. KENNISGRAAF ENTITEITEN
-- ============================================

-- Geëxtraheerde entiteiten uit documenten en contexten
CREATE TABLE graph_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(100) NOT NULL, -- 'PERSON', 'ORGANIZATION', 'LOCATION', 'CONCEPT', 'EVENT', 'LAW'
    entity_name VARCHAR(500) NOT NULL,
    canonical_name VARCHAR(500), -- Genormaliseerde naam (voor deduplicatie)
    aliases TEXT[], -- Alternatieve namen/spellingen
    description TEXT,
    entity_metadata JSONB, -- Extra eigenschappen
    confidence_score DECIMAL(3,2), -- 0.00 - 1.00
    source_count INTEGER DEFAULT 1, -- Aantal documenten waarin gevonden
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(entity_type, canonical_name)
);

-- Index voor snelle lookup
CREATE INDEX idx_graph_entities_type ON graph_entities(entity_type);
CREATE INDEX idx_graph_entities_name ON graph_entities(canonical_name);
CREATE INDEX idx_graph_entities_confidence ON graph_entities(confidence_score);

-- ============================================
-- 2. ENTITEIT-DOCUMENT KOPPELINGEN
-- ============================================

-- Welke entiteiten komen voor in welke documenten/contexten
CREATE TABLE entity_occurrences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL REFERENCES graph_entities(id) ON DELETE CASCADE,
    object_id UUID REFERENCES information_objects(id) ON DELETE CASCADE,
    domain_id UUID REFERENCES information_domains(id) ON DELETE CASCADE,
    occurrence_context TEXT, -- Tekstfragment waarin entiteit voorkomt
    position_in_text INTEGER, -- Character offset
    salience_score DECIMAL(3,2), -- Hoe belangrijk is deze entiteit in dit document (0-1)
    extracted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    extraction_method VARCHAR(50) DEFAULT 'NER', -- 'NER', 'manual', 'pattern_match'
    CHECK (object_id IS NOT NULL OR domain_id IS NOT NULL) -- Minimaal één van beide
);

CREATE INDEX idx_entity_occurrences_entity ON entity_occurrences(entity_id);
CREATE INDEX idx_entity_occurrences_object ON entity_occurrences(object_id);
CREATE INDEX idx_entity_occurrences_domain ON entity_occurrences(domain_id);

-- ============================================
-- 3. ENTITEIT RELATIES (Kennisgraaf Edges)
-- ============================================

-- Relaties tussen entiteiten (de "graaf" in GraphRAG)
CREATE TABLE entity_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_entity_id UUID NOT NULL REFERENCES graph_entities(id) ON DELETE CASCADE,
    target_entity_id UUID NOT NULL REFERENCES graph_entities(id) ON DELETE CASCADE,
    relationship_type VARCHAR(100) NOT NULL,
    -- Voorbeelden: 'WORKS_FOR', 'LOCATED_IN', 'REGULATES', 'RELATED_TO', 'PART_OF', 'MENTIONS'

    relationship_strength DECIMAL(3,2), -- 0.00 - 1.00 (hoe sterk is de relatie)
    evidence_count INTEGER DEFAULT 1, -- Aantal keer dat deze relatie is waargenomen
    description TEXT,
    properties JSONB, -- Extra relatie-eigenschappen

    first_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(source_entity_id, target_entity_id, relationship_type)
);

CREATE INDEX idx_entity_rel_source ON entity_relationships(source_entity_id);
CREATE INDEX idx_entity_rel_target ON entity_relationships(target_entity_id);
CREATE INDEX idx_entity_rel_type ON entity_relationships(relationship_type);
CREATE INDEX idx_entity_rel_strength ON entity_relationships(relationship_strength);

-- ============================================
-- 4. CONTEXT COMMUNITIES (GraphRAG Clustering)
-- ============================================

-- GraphRAG gebruikt community detection om gerelateerde contexten te vinden
CREATE TABLE graph_communities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_name VARCHAR(255),
    summary TEXT, -- AI-gegenereerde samenvatting van deze community
    key_themes TEXT[], -- Hoofdthema's in deze community
    community_level INTEGER DEFAULT 0, -- 0=finest grain, higher=more abstract
    parent_community_id UUID REFERENCES graph_communities(id),
    member_count INTEGER DEFAULT 0,
    coherence_score DECIMAL(3,2), -- Hoe coherent is deze community (0-1)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_communities_level ON graph_communities(community_level);
CREATE INDEX idx_communities_parent ON graph_communities(parent_community_id);

-- ============================================
-- 5. COMMUNITY MEMBERSHIPS
-- ============================================

-- Welke domeinen/entiteiten zitten in welke communities
CREATE TABLE community_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES graph_communities(id) ON DELETE CASCADE,
    entity_id UUID REFERENCES graph_entities(id) ON DELETE CASCADE,
    domain_id UUID REFERENCES information_domains(id) ON DELETE CASCADE,
    membership_score DECIMAL(3,2), -- Hoe sterk behoort dit lid tot deze community (0-1)
    is_core_member BOOLEAN DEFAULT false, -- Is dit een centrale node in de community?
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (entity_id IS NOT NULL OR domain_id IS NOT NULL)
);

CREATE INDEX idx_community_members_community ON community_members(community_id);
CREATE INDEX idx_community_members_entity ON community_members(entity_id);
CREATE INDEX idx_community_members_domain ON community_members(domain_id);

-- ============================================
-- 6. GRAPHRAG GEGENEREERDE CONTEXT RELATIES
-- ============================================

-- Automatisch ontdekte relaties tussen information domains via GraphRAG
CREATE TABLE graphrag_domain_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_domain_id UUID NOT NULL REFERENCES information_domains(id) ON DELETE CASCADE,
    to_domain_id UUID NOT NULL REFERENCES information_domains(id) ON DELETE CASCADE,

    -- Waarom zijn deze domeinen gerelateerd?
    relation_reason VARCHAR(100),
    -- 'SHARED_ENTITIES', 'SAME_COMMUNITY', 'SEMANTIC_SIMILARITY',
    -- 'TEMPORAL_PROXIMITY', 'STAKEHOLDER_OVERLAP'

    relation_strength DECIMAL(3,2), -- 0.00 - 1.00
    shared_entity_count INTEGER DEFAULT 0,
    community_id UUID REFERENCES graph_communities(id),

    -- Evidence voor deze relatie
    supporting_entities UUID[], -- Array van entity IDs die deze relatie ondersteunen
    semantic_similarity DECIMAL(3,2), -- Cosine similarity van embeddings

    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_confirmed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_by_user BOOLEAN DEFAULT false, -- Gebruiker heeft deze relatie bevestigd

    explanation TEXT, -- LLM-gegenereerde uitleg waarom deze relatie bestaat

    UNIQUE(from_domain_id, to_domain_id, relation_reason)
);

CREATE INDEX idx_graphrag_relations_from ON graphrag_domain_relations(from_domain_id);
CREATE INDEX idx_graphrag_relations_to ON graphrag_domain_relations(to_domain_id);
CREATE INDEX idx_graphrag_relations_strength ON graphrag_domain_relations(relation_strength);
CREATE INDEX idx_graphrag_relations_community ON graphrag_domain_relations(community_id);

-- ============================================
-- 7. GRAPHRAG EMBEDDINGS
-- ============================================

-- Embeddings voor entiteiten en communities (voor semantic search)
CREATE TABLE graph_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID REFERENCES graph_entities(id) ON DELETE CASCADE,
    community_id UUID REFERENCES graph_communities(id) ON DELETE CASCADE,
    embedding VECTOR(1536), -- OpenAI embeddings dimensie
    embedding_model VARCHAR(50) DEFAULT 'text-embedding-ada-002',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (entity_id IS NOT NULL OR community_id IS NOT NULL)
);

CREATE INDEX idx_graph_embeddings_entity ON graph_embeddings(entity_id);
CREATE INDEX idx_graph_embeddings_community ON graph_embeddings(community_id);

-- ============================================
-- 8. GRAPHRAG PROCESSING QUEUE
-- ============================================

-- Queue voor asynchrone GraphRAG verwerking
CREATE TABLE graphrag_processing_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    object_id UUID REFERENCES information_objects(id) ON DELETE CASCADE,
    domain_id UUID REFERENCES information_domains(id) ON DELETE CASCADE,
    processing_type VARCHAR(50) NOT NULL,
    -- 'ENTITY_EXTRACTION', 'RELATIONSHIP_DISCOVERY',
    -- 'COMMUNITY_DETECTION', 'EMBEDDING_GENERATION'

    status VARCHAR(50) DEFAULT 'PENDING',
    -- 'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'

    priority INTEGER DEFAULT 5, -- 1-10 (10=highest)
    attempts INTEGER DEFAULT 0,
    error_message TEXT,

    queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    CHECK (object_id IS NOT NULL OR domain_id IS NOT NULL)
);

CREATE INDEX idx_graphrag_queue_status ON graphrag_processing_queue(status, priority DESC);
CREATE INDEX idx_graphrag_queue_type ON graphrag_processing_queue(processing_type);

-- ============================================
-- 9. VIEWS VOOR GRAPHRAG ANALYSE
-- ============================================

-- View: Meest centrale entiteiten (hoogste connectiviteit)
CREATE VIEW v_central_entities AS
SELECT
    e.id,
    e.entity_name,
    e.entity_type,
    COUNT(DISTINCT er.id) as relationship_count,
    COUNT(DISTINCT eo.object_id) as document_count,
    COUNT(DISTINCT eo.domain_id) as domain_count,
    AVG(er.relationship_strength) as avg_relationship_strength
FROM graph_entities e
LEFT JOIN entity_relationships er ON e.id = er.source_entity_id OR e.id = er.target_entity_id
LEFT JOIN entity_occurrences eo ON e.id = eo.entity_id
GROUP BY e.id, e.entity_name, e.entity_type
ORDER BY relationship_count DESC, document_count DESC;

-- View: Sterkste domain relaties via GraphRAG
CREATE VIEW v_strongest_domain_connections AS
SELECT
    gdr.id,
    d1.name as from_domain_name,
    d1.type as from_domain_type,
    d2.name as to_domain_name,
    d2.type as to_domain_type,
    gdr.relation_reason,
    gdr.relation_strength,
    gdr.shared_entity_count,
    gc.community_name,
    gdr.explanation,
    gdr.confirmed_by_user
FROM graphrag_domain_relations gdr
JOIN information_domains d1 ON gdr.from_domain_id = d1.id
JOIN information_domains d2 ON gdr.to_domain_id = d2.id
LEFT JOIN graph_communities gc ON gdr.community_id = gc.id
WHERE gdr.relation_strength > 0.5
ORDER BY gdr.relation_strength DESC;

-- View: Community overzicht met statistieken
CREATE VIEW v_community_overview AS
SELECT
    gc.id,
    gc.community_name,
    gc.community_level,
    gc.summary,
    gc.coherence_score,
    COUNT(DISTINCT cm.domain_id) as domain_count,
    COUNT(DISTINCT cm.entity_id) as entity_count,
    parent.community_name as parent_community_name
FROM graph_communities gc
LEFT JOIN community_members cm ON gc.id = cm.community_id
LEFT JOIN graph_communities parent ON gc.parent_community_id = parent.id
GROUP BY gc.id, gc.community_name, gc.community_level, gc.summary,
         gc.coherence_score, parent.community_name
ORDER BY gc.community_level, gc.coherence_score DESC;

-- View: Entiteit co-occurrence matrix (welke entiteiten komen vaak samen voor)
CREATE VIEW v_entity_cooccurrence AS
SELECT
    e1.entity_name as entity_1,
    e2.entity_name as entity_2,
    COUNT(DISTINCT eo1.object_id) as shared_documents,
    COUNT(DISTINCT eo1.domain_id) as shared_domains,
    AVG(eo1.salience_score + eo2.salience_score) / 2 as avg_combined_salience
FROM entity_occurrences eo1
JOIN entity_occurrences eo2 ON (
    (eo1.object_id = eo2.object_id AND eo1.object_id IS NOT NULL) OR
    (eo1.domain_id = eo2.domain_id AND eo1.domain_id IS NOT NULL)
)
JOIN graph_entities e1 ON eo1.entity_id = e1.id
JOIN graph_entities e2 ON eo2.entity_id = e2.id
WHERE eo1.entity_id < eo2.entity_id -- Voorkom duplicaten
GROUP BY e1.entity_name, e2.entity_name
HAVING COUNT(DISTINCT COALESCE(eo1.object_id, eo1.domain_id)) >= 2
ORDER BY shared_documents DESC, shared_domains DESC;

-- ============================================
-- 10. FUNCTIES VOOR GRAPHRAG OPERATIES
-- ============================================

-- Functie: Update community statistics
CREATE OR REPLACE FUNCTION update_community_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE graph_communities
    SET
        member_count = (
            SELECT COUNT(*)
            FROM community_members
            WHERE community_id = NEW.community_id
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.community_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_community_stats
AFTER INSERT OR DELETE ON community_members
FOR EACH ROW
EXECUTE FUNCTION update_community_stats();

-- Functie: Update entity source count
CREATE OR REPLACE FUNCTION update_entity_source_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE graph_entities
    SET
        source_count = (
            SELECT COUNT(DISTINCT COALESCE(object_id, domain_id))
            FROM entity_occurrences
            WHERE entity_id = NEW.entity_id
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.entity_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_entity_count
AFTER INSERT ON entity_occurrences
FOR EACH ROW
EXECUTE FUNCTION update_entity_source_count();

-- Functie: Auto-queue nieuwe documenten voor GraphRAG processing
CREATE OR REPLACE FUNCTION queue_new_document_for_graphrag()
RETURNS TRIGGER AS $$
BEGIN
    -- Queue entity extraction
    INSERT INTO graphrag_processing_queue (object_id, processing_type, priority)
    VALUES (NEW.id, 'ENTITY_EXTRACTION', 7);

    -- Queue embedding generation
    INSERT INTO graphrag_processing_queue (object_id, processing_type, priority)
    VALUES (NEW.id, 'EMBEDDING_GENERATION', 5);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_queue_graphrag
AFTER INSERT ON information_objects
FOR EACH ROW
EXECUTE FUNCTION queue_new_document_for_graphrag();

-- ============================================
-- 11. INDEXES VOOR GRAPHRAG PERFORMANCE
-- ============================================

-- GIN index voor array searches
CREATE INDEX idx_graphrag_relations_entities ON graphrag_domain_relations USING GIN(supporting_entities);
CREATE INDEX idx_graph_entities_aliases ON graph_entities USING GIN(aliases);

-- Composite indexes voor veelvoorkomende queries
CREATE INDEX idx_entity_occurrences_composite ON entity_occurrences(entity_id, domain_id, salience_score);
CREATE INDEX idx_community_members_composite ON community_members(community_id, membership_score DESC);

-- ============================================
-- EINDE GRAPHRAG EXTENSIONS
-- ============================================

-- Om deze extensies te gebruiken, run eerst het basis organizational_context.sql schema
-- en daarna dit bestand:
-- psql -d iou_context -f src/models/organizational_context.sql
-- psql -d iou_context -f src/models/graphrag_extensions.sql
