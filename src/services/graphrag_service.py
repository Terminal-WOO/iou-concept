"""
GraphRAG Service voor IOU-concept
Automatische context-relatie detectie via kennisgraaf en RAG

GraphRAG combineert:
1. Knowledge Graph: Entiteiten en hun relaties
2. Community Detection: Clustering van gerelateerde contexten
3. RAG: Retrieval-Augmented Generation voor context-aware responses
4. Embeddings: Semantic similarity tussen contexten

Gebruik:
    service = GraphRAGService()
    await service.process_document(document_id)
    relations = await service.discover_domain_relations(domain_id)
"""

from typing import List, Dict, Any, Optional, Tuple, Set
from dataclasses import dataclass
from datetime import datetime
import asyncio
import json
import re
from collections import defaultdict
import numpy as np

# Voor productie: echte libraries
# import spacy  # NER
# from sentence_transformers import SentenceTransformer  # Embeddings
# import networkx as nx  # Graph algorithms
# from community import community_louvain  # Community detection


@dataclass
class Entity:
    """Geëxtraheerde entiteit uit document"""
    entity_type: str  # PERSON, ORGANIZATION, LOCATION, CONCEPT, EVENT, LAW
    entity_name: str
    canonical_name: str
    confidence: float
    context: str
    position: int


@dataclass
class EntityRelationship:
    """Relatie tussen twee entiteiten"""
    source_entity_id: str
    target_entity_id: str
    relationship_type: str
    strength: float
    evidence: List[str]


@dataclass
class Community:
    """GraphRAG community van gerelateerde contexten"""
    id: str
    name: str
    summary: str
    key_themes: List[str]
    member_domains: List[str]
    coherence_score: float


@dataclass
class DomainRelation:
    """Ontdekte relatie tussen twee domeinen"""
    from_domain_id: str
    to_domain_id: str
    relation_reason: str
    relation_strength: float
    shared_entities: List[str]
    explanation: str


class GraphRAGService:
    """
    GraphRAG Service voor automatische context-relatie ontdekking

    Pipeline:
    1. Entity Extraction: Haal entiteiten uit documenten
    2. Relationship Discovery: Vind relaties tussen entiteiten
    3. Graph Building: Bouw kennisgraaf
    4. Community Detection: Cluster gerelateerde contexten
    5. Relation Discovery: Ontdek domain relaties via graaf
    """

    def __init__(self, model_provider: str = "openai"):
        self.model_provider = model_provider
        # In productie: laad echte models
        # self.nlp = spacy.load("nl_core_news_lg")
        # self.embedder = SentenceTransformer('paraphrase-multilingual-mpnet-base-v2')
        # self.graph = nx.Graph()
        pass

    # ============================================
    # 1. ENTITY EXTRACTION
    # ============================================

    async def extract_entities(
        self,
        content: str,
        document_id: Optional[str] = None
    ) -> List[Entity]:
        """
        Extraheer entiteiten uit tekst via NER en pattern matching

        Detecteert:
        - PERSON: Namen van personen
        - ORGANIZATION: Organisaties, ministeries, gemeentes
        - LOCATION: Plaatsen, provincies, landen
        - CONCEPT: Beleidsterreinen, projectnamen
        - EVENT: Gebeurtenissen, vergaderingen
        - LAW: Wetten en regelgeving
        """
        entities = []

        # In productie: gebruik spaCy NER
        # doc = self.nlp(content)
        # for ent in doc.ents:
        #     entities.append(Entity(...))

        # Demo: pattern matching voor Nederlandse overheidsentiteiten
        entities.extend(self._extract_dutch_gov_entities(content))
        entities.extend(self._extract_laws(content))
        entities.extend(self._extract_locations(content))

        return entities

    def _extract_dutch_gov_entities(self, text: str) -> List[Entity]:
        """Extract Nederlandse overheidsorganisaties"""
        entities = []

        # Patronen voor overheidsorganisaties
        patterns = [
            (r'Provincie\s+(\w+)', 'ORGANIZATION'),
            (r'Gemeente\s+(\w+)', 'ORGANIZATION'),
            (r'Ministerie\s+van\s+([A-Z][a-zA-Z\s]+)', 'ORGANIZATION'),
            (r'Waterschap\s+(\w+)', 'ORGANIZATION'),
            (r'Rijksdienst\s+voor\s+([A-Z][a-zA-Z\s]+)', 'ORGANIZATION'),
        ]

        for pattern, entity_type in patterns:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                full_name = match.group(0)
                entities.append(Entity(
                    entity_type=entity_type,
                    entity_name=full_name,
                    canonical_name=full_name.lower(),
                    confidence=0.90,
                    context=text[max(0, match.start()-50):match.end()+50],
                    position=match.start()
                ))

        return entities

    def _extract_laws(self, text: str) -> List[Entity]:
        """Extract verwijzingen naar Nederlandse wetgeving"""
        entities = []

        # Nederlandse wetten
        laws = [
            'Wet open overheid', 'Woo', 'Algemene verordening gegevensbescherming',
            'AVG', 'GDPR', 'Archiefwet', 'Omgevingswet', 'Wet ruimtelijke ordening',
            'Wet milieubeheer', 'Algemene wet bestuursrecht', 'Awb'
        ]

        for law in laws:
            pattern = re.escape(law)
            for match in re.finditer(pattern, text, re.IGNORECASE):
                entities.append(Entity(
                    entity_type='LAW',
                    entity_name=match.group(0),
                    canonical_name=law.lower(),
                    confidence=0.95,
                    context=text[max(0, match.start()-50):match.end()+50],
                    position=match.start()
                ))

        return entities

    def _extract_locations(self, text: str) -> List[Entity]:
        """Extract Nederlandse locaties"""
        entities = []

        # Nederlandse provincies en grote steden
        locations = [
            'Flevoland', 'Noord-Holland', 'Zuid-Holland', 'Utrecht', 'Gelderland',
            'Overijssel', 'Drenthe', 'Friesland', 'Groningen', 'Zeeland',
            'Noord-Brabant', 'Limburg',
            'Amsterdam', 'Rotterdam', 'Den Haag', 'Utrecht', 'Eindhoven',
            'Groningen', 'Tilburg', 'Almere', 'Lelystad'
        ]

        for location in locations:
            pattern = r'\b' + re.escape(location) + r'\b'
            for match in re.finditer(pattern, text, re.IGNORECASE):
                entities.append(Entity(
                    entity_type='LOCATION',
                    entity_name=match.group(0),
                    canonical_name=location.lower(),
                    confidence=0.85,
                    context=text[max(0, match.start()-50):match.end()+50],
                    position=match.start()
                ))

        return entities

    # ============================================
    # 2. RELATIONSHIP DISCOVERY
    # ============================================

    async def discover_relationships(
        self,
        entities: List[Entity],
        window_size: int = 100
    ) -> List[EntityRelationship]:
        """
        Ontdek relaties tussen entiteiten

        Methoden:
        1. Co-occurrence: Entiteiten die dicht bij elkaar staan
        2. Pattern matching: "X werkt voor Y", "X in Y"
        3. Semantic: Via embeddings en similarity
        """
        relationships = []

        # Co-occurrence based relationships
        for i, ent1 in enumerate(entities):
            for ent2 in entities[i+1:]:
                # Als entiteiten dicht bij elkaar staan
                distance = abs(ent1.position - ent2.position)
                if distance < window_size:
                    rel_type = self._infer_relationship_type(ent1, ent2, distance)
                    if rel_type:
                        strength = 1.0 - (distance / window_size)
                        relationships.append(EntityRelationship(
                            source_entity_id=ent1.canonical_name,
                            target_entity_id=ent2.canonical_name,
                            relationship_type=rel_type,
                            strength=strength,
                            evidence=[ent1.context, ent2.context]
                        ))

        return relationships

    def _infer_relationship_type(
        self,
        ent1: Entity,
        ent2: Entity,
        distance: int
    ) -> Optional[str]:
        """Bepaal type relatie op basis van entiteit types"""
        type_pair = (ent1.entity_type, ent2.entity_type)

        # Heuristics voor relatie types
        if type_pair == ('PERSON', 'ORGANIZATION'):
            return 'WORKS_FOR'
        elif type_pair == ('ORGANIZATION', 'LOCATION'):
            return 'LOCATED_IN'
        elif type_pair == ('ORGANIZATION', 'LAW'):
            return 'SUBJECT_TO'
        elif type_pair == ('CONCEPT', 'ORGANIZATION'):
            return 'MANAGED_BY'
        elif ent1.entity_type == ent2.entity_type:
            return 'RELATED_TO'
        else:
            return 'MENTIONS'

    # ============================================
    # 3. COMMUNITY DETECTION
    # ============================================

    async def detect_communities(
        self,
        db_pool
    ) -> List[Community]:
        """
        Detecteer communities in de kennisgraaf via Louvain algoritme

        Communities = clusters van sterk verbonden entiteiten/domeinen
        Gebruikt voor:
        - Vinden van gerelateerde contexten
        - Thematische clustering
        - Hierarchische organisatie
        """
        # In productie: gebruik networkx + community detection
        # graph = await self._build_graph_from_db(db_pool)
        # partition = community_louvain.best_partition(graph)
        # communities = self._partition_to_communities(partition, graph)

        # Demo: simulatie
        communities = await self._simulate_community_detection(db_pool)
        return communities

    async def _simulate_community_detection(self, db_pool) -> List[Community]:
        """Demo implementatie van community detection"""
        # Query voor domains met gedeelde entiteiten
        query = """
        SELECT
            d1.id as domain1_id,
            d1.name as domain1_name,
            d2.id as domain2_id,
            d2.name as domain2_name,
            COUNT(DISTINCT eo1.entity_id) as shared_entities
        FROM information_domains d1
        JOIN information_domains d2 ON d1.id < d2.id
        JOIN entity_occurrences eo1 ON d1.id = eo1.domain_id
        JOIN entity_occurrences eo2 ON d2.id = eo2.domain_id
        WHERE eo1.entity_id = eo2.entity_id
        GROUP BY d1.id, d1.name, d2.id, d2.name
        HAVING COUNT(DISTINCT eo1.entity_id) >= 3
        ORDER BY shared_entities DESC
        """

        # Simuleer communities
        return [
            Community(
                id="community_1",
                name="Duurzaamheid & Circulaire Economie",
                summary="Projecten en zaken gerelateerd aan duurzaamheid, circulaire economie en groene energie",
                key_themes=["duurzaamheid", "circulair", "energie", "klimaat"],
                member_domains=[],
                coherence_score=0.87
            ),
            Community(
                id="community_2",
                name="Ruimtelijke Ordening & Vergunningen",
                summary="Vergunningverlening, ruimtelijke plannen en omgevingswet",
                key_themes=["vergunning", "ruimtelijk", "bouw", "omgevingswet"],
                member_domains=[],
                coherence_score=0.82
            )
        ]

    # ============================================
    # 4. DOMAIN RELATION DISCOVERY
    # ============================================

    async def discover_domain_relations(
        self,
        domain_id: str,
        db_pool,
        min_strength: float = 0.5
    ) -> List[DomainRelation]:
        """
        Ontdek gerelateerde domeinen via GraphRAG

        Methoden:
        1. Shared entities: Domeinen met gedeelde entiteiten
        2. Community membership: Domeinen in dezelfde community
        3. Semantic similarity: Via embeddings
        4. Temporal proximity: Domeinen uit dezelfde periode
        5. Stakeholder overlap: Gedeelde stakeholders
        """
        relations = []

        # 1. Via gedeelde entiteiten
        shared_entity_relations = await self._find_shared_entity_relations(
            domain_id, db_pool, min_strength
        )
        relations.extend(shared_entity_relations)

        # 2. Via community membership
        community_relations = await self._find_community_relations(
            domain_id, db_pool, min_strength
        )
        relations.extend(community_relations)

        # 3. Via semantic similarity
        semantic_relations = await self._find_semantic_relations(
            domain_id, db_pool, min_strength
        )
        relations.extend(semantic_relations)

        # Deduplicate en sort
        relations = self._deduplicate_relations(relations)
        relations.sort(key=lambda r: r.relation_strength, reverse=True)

        return relations

    async def _find_shared_entity_relations(
        self,
        domain_id: str,
        db_pool,
        min_strength: float
    ) -> List[DomainRelation]:
        """Vind domeinen die entiteiten delen"""
        query = """
        WITH domain_entities AS (
            SELECT entity_id
            FROM entity_occurrences
            WHERE domain_id = $1
        ),
        related_domains AS (
            SELECT
                eo.domain_id,
                COUNT(DISTINCT eo.entity_id) as shared_count,
                array_agg(DISTINCT ge.entity_name) as shared_entity_names
            FROM entity_occurrences eo
            JOIN domain_entities de ON eo.entity_id = de.entity_id
            JOIN graph_entities ge ON eo.entity_id = ge.id
            WHERE eo.domain_id != $1
            GROUP BY eo.domain_id
            HAVING COUNT(DISTINCT eo.entity_id) >= 2
        )
        SELECT
            rd.domain_id,
            id.name as domain_name,
            rd.shared_count,
            rd.shared_entity_names
        FROM related_domains rd
        JOIN information_domains id ON rd.domain_id = id.id
        ORDER BY rd.shared_count DESC
        LIMIT 10
        """

        # Demo: simulatie
        return [
            DomainRelation(
                from_domain_id=domain_id,
                to_domain_id="related_domain_1",
                relation_reason="SHARED_ENTITIES",
                relation_strength=0.85,
                shared_entities=["Provincie Flevoland", "Gemeente Almere", "Circulaire Economie"],
                explanation="Deze domeinen delen 3 belangrijke entiteiten, waaronder organisaties en concepten"
            )
        ]

    async def _find_community_relations(
        self,
        domain_id: str,
        db_pool,
        min_strength: float
    ) -> List[DomainRelation]:
        """Vind domeinen in dezelfde community"""
        # Demo: simulatie
        return []

    async def _find_semantic_relations(
        self,
        domain_id: str,
        db_pool,
        min_strength: float
    ) -> List[DomainRelation]:
        """Vind semantisch gerelateerde domeinen via embeddings"""
        # In productie: cosine similarity van embeddings
        # domain_embedding = await self._get_domain_embedding(domain_id, db_pool)
        # similar_domains = await self._find_similar_embeddings(domain_embedding, db_pool)

        # Demo: simulatie
        return []

    def _deduplicate_relations(
        self,
        relations: List[DomainRelation]
    ) -> List[DomainRelation]:
        """Verwijder duplicate relaties, behoud hoogste strength"""
        seen = {}
        for rel in relations:
            key = (rel.from_domain_id, rel.to_domain_id)
            if key not in seen or rel.relation_strength > seen[key].relation_strength:
                seen[key] = rel
        return list(seen.values())

    # ============================================
    # 5. GRAPH QUERYING & ANALYTICS
    # ============================================

    async def get_entity_network(
        self,
        entity_id: str,
        db_pool,
        max_depth: int = 2
    ) -> Dict[str, Any]:
        """
        Haal netwerk van gerelateerde entiteiten op
        Voor visualisatie van kennisgraaf
        """
        query = """
        WITH RECURSIVE entity_network AS (
            -- Start node
            SELECT
                id as entity_id,
                entity_name,
                entity_type,
                0 as depth
            FROM graph_entities
            WHERE id = $1

            UNION

            -- Gerelateerde entiteiten
            SELECT
                ge.id,
                ge.entity_name,
                ge.entity_type,
                en.depth + 1
            FROM entity_network en
            JOIN entity_relationships er ON
                en.entity_id = er.source_entity_id OR
                en.entity_id = er.target_entity_id
            JOIN graph_entities ge ON
                (er.source_entity_id = ge.id OR er.target_entity_id = ge.id)
                AND ge.id != en.entity_id
            WHERE en.depth < $2
        )
        SELECT * FROM entity_network
        """

        # Demo: return netwerk structuur voor visualisatie
        return {
            "nodes": [
                {"id": entity_id, "label": "Provincie Flevoland", "type": "ORGANIZATION"},
                {"id": "entity_2", "label": "Circulaire Economie", "type": "CONCEPT"},
                {"id": "entity_3", "label": "Gemeente Almere", "type": "ORGANIZATION"}
            ],
            "edges": [
                {"from": entity_id, "to": "entity_2", "type": "MANAGES", "strength": 0.9},
                {"from": "entity_2", "to": "entity_3", "type": "COLLABORATES", "strength": 0.7}
            ]
        }

    async def get_domain_graph_context(
        self,
        domain_id: str,
        db_pool
    ) -> Dict[str, Any]:
        """
        Haal volledige GraphRAG context voor een domein
        Gebruikt voor RAG: context-aware responses
        """
        # 1. Entiteiten in dit domein
        entities = await self._get_domain_entities(domain_id, db_pool)

        # 2. Gerelateerde domeinen
        relations = await self.discover_domain_relations(domain_id, db_pool)

        # 3. Community membership
        communities = await self._get_domain_communities(domain_id, db_pool)

        # 4. Key concepts
        key_concepts = await self._extract_key_concepts(domain_id, db_pool)

        return {
            "domain_id": domain_id,
            "entities": entities,
            "related_domains": relations,
            "communities": communities,
            "key_concepts": key_concepts,
            "graph_summary": self._generate_graph_summary(entities, relations, communities)
        }

    def _generate_graph_summary(
        self,
        entities: List[Entity],
        relations: List[DomainRelation],
        communities: List[Community]
    ) -> str:
        """Genereer tekstuele samenvatting van graaf context"""
        summary_parts = []

        if entities:
            entity_types = defaultdict(list)
            for e in entities:
                entity_types[e.entity_type].append(e.entity_name)

            for etype, names in entity_types.items():
                summary_parts.append(f"{etype}: {', '.join(names[:3])}")

        if relations:
            summary_parts.append(f"{len(relations)} gerelateerde domeinen gevonden")

        if communities:
            summary_parts.append(f"Onderdeel van communities: {', '.join([c.name for c in communities])}")

        return " | ".join(summary_parts)

    # ============================================
    # 6. PROCESSING PIPELINE
    # ============================================

    async def process_document(
        self,
        document_id: str,
        content: str,
        db_pool
    ) -> Dict[str, Any]:
        """
        Volledige GraphRAG pipeline voor een document

        Steps:
        1. Extract entities
        2. Store entities in database
        3. Discover relationships
        4. Generate embeddings
        5. Update graph
        6. Trigger community re-detection
        """
        results = {
            "document_id": document_id,
            "entities_extracted": 0,
            "relationships_discovered": 0,
            "processing_time_ms": 0
        }

        start_time = datetime.now()

        # 1. Entity extraction
        entities = await self.extract_entities(content, document_id)
        results["entities_extracted"] = len(entities)

        # 2. Store entities (in productie: insert in DB)
        # await self._store_entities(entities, document_id, db_pool)

        # 3. Relationship discovery
        relationships = await self.discover_relationships(entities)
        results["relationships_discovered"] = len(relationships)

        # 4. Store relationships (in productie: insert in DB)
        # await self._store_relationships(relationships, db_pool)

        # 5. Queue for community re-detection
        # await self._queue_community_update(db_pool)

        end_time = datetime.now()
        results["processing_time_ms"] = (end_time - start_time).total_seconds() * 1000

        return results

    async def _get_domain_entities(self, domain_id: str, db_pool) -> List[Entity]:
        """Helper: haal entiteiten voor domein op"""
        return []

    async def _get_domain_communities(self, domain_id: str, db_pool) -> List[Community]:
        """Helper: haal communities voor domein op"""
        return []

    async def _extract_key_concepts(self, domain_id: str, db_pool) -> List[str]:
        """Helper: extract belangrijkste concepten"""
        return []


# ============================================
# USAGE EXAMPLE
# ============================================

async def example_usage():
    """Voorbeeld gebruik van GraphRAG service"""
    service = GraphRAGService()

    # 1. Proces nieuw document
    document_content = """
    Provincie Flevoland start een nieuw project voor Circulaire Economie.
    In samenwerking met Gemeente Almere worden innovatieve oplossingen
    ontwikkeld conform de Wet milieubeheer en Omgevingswet.
    """

    results = await service.process_document(
        document_id="doc_123",
        content=document_content,
        db_pool=None  # In productie: echte DB pool
    )
    print(f"Extracted {results['entities_extracted']} entities")

    # 2. Ontdek gerelateerde domeinen
    relations = await service.discover_domain_relations(
        domain_id="domain_123",
        db_pool=None,
        min_strength=0.5
    )

    for rel in relations:
        print(f"Related to {rel.to_domain_id}: {rel.explanation}")

    # 3. Haal graaf context voor RAG
    context = await service.get_domain_graph_context(
        domain_id="domain_123",
        db_pool=None
    )
    print(f"Graph context: {context['graph_summary']}")


if __name__ == "__main__":
    asyncio.run(example_usage())
