# GraphRAG Variant - Automatische Context-Relatie Ontdekking

Deze variant breidt het IOU-concept uit met **GraphRAG** (Graph Retrieval-Augmented Generation) voor automatische ontdekking van context-relaties.

## Wat is GraphRAG?

GraphRAG combineert drie technieken:

1. **Knowledge Graph**: Entiteiten (personen, organisaties, concepten) en hun relaties
2. **Community Detection**: Clustering van gerelateerde contexten via graph algorithms
3. **Retrieval-Augmented Generation**: Context-aware AI responses met graaf-kennis

## Voordelen

### Zonder GraphRAG (Basis IOU)
- **Handmatige koppelingen**: Gebruiker moet zelf relaties tussen zaken/projecten aangeven
- **Beperkte ontdekking**: Alleen directe links via stakeholders of expliciete verwijzingen
- **Statische context**: Relaties veranderen niet automatisch

### Met GraphRAG
- ✅ **Automatische ontdekking**: Relaties worden automatisch gevonden via gedeelde entiteiten
- ✅ **Verborgen patronen**: Ontdek indirecte verbindingen via multi-hop graph queries
- ✅ **Thematische clustering**: Automatische groupering van gerelateerde contexten
- ✅ **Dynamische updates**: Graaf evolueert mee met nieuwe documenten
- ✅ **Explainable AI**: Duidelijke uitleg waarom contexten gerelateerd zijn

## Architectuur

### Kennisgraaf Structuur

```
┌─────────────────────────────────────────────────────────┐
│                    GraphRAG Laag                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐      ┌──────────────┐               │
│  │  Entiteiten  │◄────►│   Relaties   │               │
│  └──────────────┘      └──────────────┘               │
│         ▲                     ▲                        │
│         │                     │                        │
│         ▼                     ▼                        │
│  ┌──────────────┐      ┌──────────────┐               │
│  │ Communities  │      │   Embeddings │               │
│  └──────────────┘      └──────────────┘               │
│                                                         │
├─────────────────────────────────────────────────────────┤
│              Basis IOU-concept (Domeinen)              │
└─────────────────────────────────────────────────────────┘
```

### Pipeline

```
Nieuw Document
     │
     ▼
┌─────────────────────┐
│ Entity Extraction   │  ← NER + Pattern Matching
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Relationship        │  ← Co-occurrence + Semantic
│ Discovery           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Graph Building      │  ← Kennisgraaf update
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Community Detection │  ← Louvain algoritme
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Domain Relations    │  ← Automatische koppelingen
└─────────────────────┘
```

## Database Schema

### Nieuwe Tabellen

Het GraphRAG schema (`src/models/graphrag_extensions.sql`) voegt toe:

1. **`graph_entities`**: Geëxtraheerde entiteiten
   - PERSON, ORGANIZATION, LOCATION, CONCEPT, EVENT, LAW
   - Canonical names voor deduplicatie
   - Confidence scores

2. **`entity_occurrences`**: Waar komen entiteiten voor?
   - Koppeling naar documenten/domeinen
   - Tekstfragment en positie
   - Salience score (hoe belangrijk)

3. **`entity_relationships`**: Kennisgraaf edges
   - Relationship types (WORKS_FOR, LOCATED_IN, REGULATES, etc.)
   - Relationship strength (0-1)
   - Evidence count

4. **`graph_communities`**: Thematische clusters
   - AI-gegenereerde samenvatting
   - Key themes
   - Hierarchische structuur (parent communities)
   - Coherence score

5. **`community_members`**: Welke domeinen/entiteiten in welke community
   - Membership score
   - Core member flag

6. **`graphrag_domain_relations`**: Automatisch ontdekte domain relaties
   - Relation reasons: SHARED_ENTITIES, SAME_COMMUNITY, SEMANTIC_SIMILARITY
   - Relation strength
   - Explanation (LLM-gegenereerd)

7. **`graph_embeddings`**: Vector embeddings voor semantic search

8. **`graphrag_processing_queue`**: Asynchrone verwerking

### Views voor Analyse

- **`v_central_entities`**: Meest verbonden entiteiten
- **`v_strongest_domain_connections`**: Sterkste automatische koppelingen
- **`v_community_overview`**: Community statistieken
- **`v_entity_cooccurrence`**: Welke entiteiten komen vaak samen voor

## Service Implementatie

### GraphRAGService

Located at `src/services/graphrag_service.py`:

#### 1. Entity Extraction
```python
service = GraphRAGService()
entities = await service.extract_entities(document_content)

# Detecteert:
# - Personen
# - Organisaties (Provincie Flevoland, Gemeente Almere)
# - Locaties (Nederlandse plaatsen/provincies)
# - Concepten (Circulaire Economie, Duurzaamheid)
# - Wetten (Woo, AVG, Omgevingswet)
```

#### 2. Relationship Discovery
```python
relationships = await service.discover_relationships(entities)

# Types:
# - WORKS_FOR: Persoon → Organisatie
# - LOCATED_IN: Organisatie → Locatie
# - SUBJECT_TO: Organisatie → Wet
# - MANAGES: Organisatie → Concept
# - RELATED_TO: Algemene relatie
```

#### 3. Community Detection
```python
communities = await service.detect_communities(db_pool)

# Voorbeelden:
# - "Duurzaamheid & Circulaire Economie"
# - "Ruimtelijke Ordening & Vergunningen"
# - "Mobiliteit & Infrastructuur"
```

#### 4. Domain Relation Discovery
```python
relations = await service.discover_domain_relations(
    domain_id="project_123",
    db_pool=db_pool,
    min_strength=0.5
)

# Vindt relaties via:
# 1. Shared entities (gedeelde organisaties/personen)
# 2. Community membership (in dezelfde thematische cluster)
# 3. Semantic similarity (embeddings)
# 4. Temporal proximity (zelfde tijdsperiode)
# 5. Stakeholder overlap
```

#### 5. Graph Context voor RAG
```python
context = await service.get_domain_graph_context(
    domain_id="project_123",
    db_pool=db_pool
)

# Bevat:
# - Entiteiten in dit domein
# - Gerelateerde domeinen met uitleg
# - Community memberships
# - Key concepts
# - Graph summary voor LLM context
```

## Installatie & Gebruik

### 1. Database Setup

```bash
# Laad basis schema
psql -d iou_context -f src/models/organizational_context.sql

# Laad GraphRAG extensies
psql -d iou_context -f src/models/graphrag_extensions.sql
```

### 2. Dependencies

Update `requirements.txt`:
```txt
# GraphRAG specifieke libraries
spacy>=3.7.2
networkx>=3.2
python-louvain>=0.16  # Community detection
sentence-transformers>=2.2.2
scikit-learn>=1.3.0  # Clustering algorithms
```

Installeer Nederlands NER model:
```bash
python -m spacy download nl_core_news_lg
```

### 3. API Integration

Integreer GraphRAG in de API:

```python
from src.services.graphrag_service import GraphRAGService

graphrag = GraphRAGService()

@app.post("/objects")
async def create_object(obj: InformationObject, pool: Pool = Depends(get_db_pool)):
    # Maak object aan
    object_id = await store_object(obj, pool)
    
    # Queue voor GraphRAG processing
    await graphrag.process_document(
        document_id=object_id,
        content=obj.content,
        db_pool=pool
    )
    
    return {"id": object_id}

@app.get("/context/{domain_id}/graph")
async def get_graph_context(domain_id: UUID4, pool: Pool = Depends(get_db_pool)):
    """Haal GraphRAG context op voor dit domein"""
    context = await graphrag.get_domain_graph_context(
        domain_id=str(domain_id),
        db_pool=pool
    )
    return context

@app.get("/domains/{domain_id}/related")
async def get_related_domains(
    domain_id: UUID4,
    min_strength: float = 0.5,
    pool: Pool = Depends(get_db_pool)
):
    """Automatisch ontdekte gerelateerde domeinen"""
    relations = await graphrag.discover_domain_relations(
        domain_id=str(domain_id),
        db_pool=pool,
        min_strength=min_strength
    )
    return relations
```

## Use Cases

### Use Case 1: Automatische Project Koppelingen

**Scenario**: Provincie Flevoland heeft meerdere projecten rondom duurzaamheid.

**Zonder GraphRAG**:
- Projectleider moet handmatig aangeven welke projecten gerelateerd zijn
- Gemakkelijk om verbindingen te missen

**Met GraphRAG**:
```
Project: "Windpark Flevopolder Zuid"
  Entiteiten: Provincie Flevoland, Gemeente Lelystad, Groene Energie, Omgevingswet
  
Automatisch ontdekt:
  → Project: "Circulaire Economie Flevoland 2025"
     Reden: Gedeelde entiteiten (Provincie Flevoland, Duurzaamheid concept)
     Strength: 0.87
     
  → Zaak: "Subsidieaanvraag Groene Energie BV"
     Reden: Gedeelde entiteiten (Groene Energie, Provincie Flevoland)
     Strength: 0.72
     
  → Project: "Smart Grid Almere"
     Reden: Zelfde community (Energie & Duurzaamheid)
     Strength: 0.65
```

### Use Case 2: Woo-verzoek Context

**Scenario**: Journalist vraagt Woo-verzoek over landbouwsubsidies.

**GraphRAG helpt**:
```sql
-- Vind alle gerelateerde zaken/projecten
SELECT * FROM v_strongest_domain_connections
WHERE from_domain_id = 'woo_verzoek_landbouw'
  AND relation_strength > 0.6;

-- Resultaat:
-- - Alle eerdere subsidiebeschikkingen (gedeelde entiteit: "landbouw")
-- - Beleidsnota's over landbouw (zelfde community)
-- - Projecten met betrokken agrariërs (stakeholder overlap)
```

**Voordeel**: Ambtenaar krijgt automatisch volledig overzicht van relevante context zonder handmatig zoeken.

### Use Case 3: Thematische Dashboards

**GraphRAG communities** worden automatisch thematische dashboards:

```
Community: "Circulaire Economie & Duurzaamheid"
  Coherence: 0.87
  
  Projecten:
  - Circulaire Economie Flevoland 2025
  - Windpark Flevopolder Zuid
  - Afvalreductie Almere
  
  Zaken:
  - 15 subsidieaanvragen voor groene energie
  - 8 vergunningen voor duurzame bouw
  
  Key entiteiten:
  - Provincie Flevoland
  - Gemeente Almere
  - Omgevingswet
  - Klimaatakkoord
  
  Gerelateerde communities:
  - "Mobiliteit & Infrastructuur" (strength: 0.42)
  - "Ruimtelijke Ordening" (strength: 0.38)
```

## Performance Overwegingen

### Indexering

GraphRAG voegt significante indexering toe:
- GIN indexes op array columns (supporting_entities)
- B-tree indexes op UUID foreign keys
- Composite indexes voor veelvoorkomende queries

### Asynchrone Processing

Gebruik `graphrag_processing_queue` voor:
- Entity extraction (kan enkele seconden duren)
- Embedding generation (OpenAI API calls)
- Community detection (computationally intensive)

```python
# Document wordt direct opgeslagen
# GraphRAG processing gebeurt asynchroon
INSERT INTO graphrag_processing_queue (object_id, processing_type, priority)
VALUES ('doc_123', 'ENTITY_EXTRACTION', 7);
```

Background worker haalt items uit queue:
```python
async def process_queue():
    while True:
        job = await get_next_job()
        if job.processing_type == 'ENTITY_EXTRACTION':
            await graphrag.process_document(job.object_id, ...)
        await mark_job_complete(job.id)
```

### Caching

Cache resultaten van:
- Community detection (run 1x per dag)
- Embeddings (permanent, alleen update bij wijziging)
- Domain relations (cache 1 uur)

## Monitoring & Analytics

### KPI's

1. **Entity Coverage**: % documenten met geëxtraheerde entiteiten
2. **Relationship Density**: Gemiddeld aantal relaties per entiteit
3. **Community Quality**: Gemiddelde coherence score
4. **Auto-discovery Rate**: % relaties automatisch ontdekt vs handmatig
5. **User Acceptance**: % automatische relaties door gebruiker bevestigd

### Queries voor Monitoring

```sql
-- Entity extraction coverage
SELECT 
    COUNT(DISTINCT io.id) as total_documents,
    COUNT(DISTINCT eo.object_id) as documents_with_entities,
    ROUND(COUNT(DISTINCT eo.object_id)::numeric / COUNT(DISTINCT io.id) * 100, 2) as coverage_pct
FROM information_objects io
LEFT JOIN entity_occurrences eo ON io.id = eo.object_id;

-- Top entiteiten (meest voorkomend)
SELECT 
    entity_name,
    entity_type,
    source_count,
    confidence_score
FROM graph_entities
ORDER BY source_count DESC
LIMIT 20;

-- Community health
SELECT 
    community_name,
    member_count,
    coherence_score,
    array_length(key_themes, 1) as theme_count
FROM graph_communities
WHERE community_level = 0
ORDER BY coherence_score DESC;
```

## Toekomstige Uitbreidingen

### Versie 2.0
- [ ] Real-time graph updates (via triggers)
- [ ] Multi-hop reasoning (vind relaties via 2-3 hops)
- [ ] Temporal graphs (hoe evolueert de graaf over tijd)
- [ ] Cross-organization graphs (inter-gemeente relaties)

### Versie 3.0
- [ ] LLM-based entity extraction (GPT-4 via Azure OpenAI)
- [ ] Dynamic relationship types (leer nieuwe types uit data)
- [ ] Predictive linking (voorspel toekomstige relaties)
- [ ] Graph visualization API (D3.js/Cytoscape.js frontend)

## Vergelijking met Alternatieven

### vs. Traditionele RAG
- **Traditionele RAG**: Zoek relevante chunks, voeg toe aan prompt
- **GraphRAG**: Zoek via graaf, inclusief multi-hop relaties en community context

### vs. Vector Search Only
- **Vector Search**: Semantische similarity tussen documenten
- **GraphRAG**: Semantic similarity + explicit relationships + community structure

### vs. Handmatige Tags
- **Handmatige Tags**: Gebruiker moet tags invoeren
- **GraphRAG**: Automatische extractie + ontdekking van verborgen patronen

## References

- Microsoft GraphRAG paper: https://arxiv.org/abs/2404.16130
- NetworkX documentation: https://networkx.org/
- Louvain community detection: https://en.wikipedia.org/wiki/Louvain_method
- spaCy NER: https://spacy.io/usage/linguistic-features#named-entities

## License

Onderdeel van IOU Concept demonstrator - Educatieve doeleinden.
