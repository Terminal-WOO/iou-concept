"""
AI-gedreven Metadata Extractie en Context Herkenning
Implementatie van AI-componenten voor IOU-concept
"""

from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import asyncio
import json
import re

# Voor productie: OpenAI, Azure OpenAI, of local models
# Voor demo: simulatie van AI-functionaliteit

@dataclass
class MetadataSuggestion:
    """Metadata voorstel van AI"""
    field: str
    value: Any
    confidence: float  # 0.0 - 1.0
    reasoning: str

@dataclass
class ContextDetection:
    """Gedetecteerde context uit document/tekst"""
    domain_type: str  # 'zaak', 'project', 'beleid'
    subject_area: str  # 'mobiliteit', 'duurzaamheid', etc.
    relevant_laws: List[str]
    stakeholders: List[str]
    locations: List[str]
    confidence: float

class AIMetadataService:
    """
    AI Service voor automatische metadata extractie en verrijking
    Kernfunctionaliteit:
    1. Context detectie via NLP
    2. Named Entity Recognition (NER)
    3. Metadata suggesties
    4. Semantic similarity voor gerelateerde domeinen
    5. Compliance regel extractie
    """

    def __init__(self, model_provider: str = "openai"):
        self.model_provider = model_provider
        # In productie: initialiseer echte AI models
        # self.nlp_model = load_spacy_model("nl_core_news_lg")
        # self.embeddings_model = OpenAIEmbeddings()
        pass

    async def extract_metadata_from_document(
        self,
        content: str,
        filename: str,
        existing_metadata: Optional[Dict] = None
    ) -> List[MetadataSuggestion]:
        """
        Hoofdfunctie: Extract metadata uit document

        Gebruikt:
        - NLP voor tekstanalyse
        - NER voor entiteiten (personen, locaties, organisaties)
        - Pattern matching voor wet- en regelgeving
        - Context herkenning
        """
        suggestions = []

        # 1. Basis metadata uit bestandsnaam
        suggestions.extend(self._extract_from_filename(filename))

        # 2. Named Entity Recognition
        entities = await self._extract_entities(content)
        suggestions.extend(self._entities_to_suggestions(entities))

        # 3. Detecteer onderwerp/domein
        subject = await self._detect_subject_area(content)
        suggestions.append(MetadataSuggestion(
            field="subject_area",
            value=subject['area'],
            confidence=subject['confidence'],
            reasoning=f"Gedetecteerd via keyword analyse: {subject['keywords'][:3]}"
        ))

        # 4. Juridische context
        laws = self._extract_legal_references(content)
        if laws:
            suggestions.append(MetadataSuggestion(
                field="legal_basis",
                value=laws[0],
                confidence=0.95,
                reasoning=f"Gevonden expliciete verwijzing naar {laws[0]}"
            ))

        # 5. WOO relevantie
        woo_relevant = await self._assess_woo_relevance(content)
        suggestions.append(MetadataSuggestion(
            field="is_woo_relevant",
            value=woo_relevant['is_relevant'],
            confidence=woo_relevant['confidence'],
            reasoning=woo_relevant['reasoning']
        ))

        # 6. Classificatie (openbaar/intern/vertrouwelijk)
        classification = await self._classify_document(content)
        suggestions.append(MetadataSuggestion(
            field="classification",
            value=classification['level'],
            confidence=classification['confidence'],
            reasoning=classification['reasoning']
        ))

        # 7. Bewaartermijn suggestie
        retention = await self._suggest_retention_period(content, existing_metadata)
        suggestions.append(MetadataSuggestion(
            field="retention_period",
            value=retention['years'],
            confidence=retention['confidence'],
            reasoning=retention['reasoning']
        ))

        # 8. Tags genereren
        tags = await self._generate_tags(content)
        suggestions.append(MetadataSuggestion(
            field="tags",
            value=tags,
            confidence=0.85,
            reasoning=f"Gegenereerd uit {len(tags)} belangrijkste concepten"
        ))

        return suggestions

    def _extract_from_filename(self, filename: str) -> List[MetadataSuggestion]:
        """Extract hints uit bestandsnaam"""
        suggestions = []

        # Patroon: "2025-03-15_Subsidie_Windpark_v2.pdf"
        date_pattern = r'(\d{4}[-_]\d{2}[-_]\d{2})'
        version_pattern = r'[vV](\d+)'

        date_match = re.search(date_pattern, filename)
        if date_match:
            suggestions.append(MetadataSuggestion(
                field="document_date",
                value=date_match.group(1),
                confidence=0.90,
                reasoning="Datum gevonden in bestandsnaam"
            ))

        version_match = re.search(version_pattern, filename)
        if version_match:
            suggestions.append(MetadataSuggestion(
                field="version",
                value=version_match.group(1),
                confidence=0.95,
                reasoning="Versienummer gevonden in bestandsnaam"
            ))

        return suggestions

    async def _extract_entities(self, content: str) -> Dict[str, List[str]]:
        """
        Named Entity Recognition
        In productie: gebruik spaCy of Azure Text Analytics
        """
        # Simulatie - in productie:
        # doc = self.nlp_model(content)
        # entities = {
        #     "persons": [ent.text for ent in doc.ents if ent.label_ == "PER"],
        #     "organizations": [ent.text for ent in doc.ents if ent.label_ == "ORG"],
        #     "locations": [ent.text for ent in doc.ents if ent.label_ == "LOC"]
        # }

        # Simpele regex-based extraction voor demo
        entities = {
            "persons": re.findall(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b', content)[:5],
            "organizations": [],
            "locations": self._extract_dutch_cities(content)
        }

        return entities

    def _extract_dutch_cities(self, content: str) -> List[str]:
        """Helper: extract Nederlandse plaatsnamen"""
        cities = ["Amsterdam", "Rotterdam", "Utrecht", "Eindhoven", "Groningen",
                  "Almere", "Lelystad", "Dronten", "Flevoland"]
        found = [city for city in cities if city in content]
        return found

    def _entities_to_suggestions(self, entities: Dict) -> List[MetadataSuggestion]:
        """Converteer entities naar metadata suggesties"""
        suggestions = []

        if entities['persons']:
            suggestions.append(MetadataSuggestion(
                field="mentioned_persons",
                value=entities['persons'],
                confidence=0.80,
                reasoning=f"Gevonden {len(entities['persons'])} personen"
            ))

        if entities['locations']:
            suggestions.append(MetadataSuggestion(
                field="locations",
                value=entities['locations'],
                confidence=0.85,
                reasoning=f"Geografische context: {', '.join(entities['locations'][:3])}"
            ))

        return suggestions

    async def _detect_subject_area(self, content: str) -> Dict:
        """
        Detecteer vakgebied/onderwerp
        In productie: gebruik text classification model
        """
        # Keyword mapping naar domeinen
        keywords_map = {
            "mobiliteit": ["verkeer", "auto", "fiets", "ov", "openbaar vervoer", "weg"],
            "duurzaamheid": ["circulair", "duurzaam", "energie", "milieu", "klimaat", "co2"],
            "economie": ["subsidie", "bedrijf", "economisch", "werkgelegenheid", "investering"],
            "ruimte": ["ruimtelijk", "bestemmingsplan", "bouw", "woning", "ontwikkeling"],
            "sociaal": ["zorg", "welzijn", "jeugd", "onderwijs", "participatie"]
        }

        content_lower = content.lower()
        scores = {}

        for area, keywords in keywords_map.items():
            score = sum(1 for kw in keywords if kw in content_lower)
            if score > 0:
                scores[area] = score

        if not scores:
            return {"area": "algemeen", "confidence": 0.5, "keywords": []}

        best_area = max(scores, key=scores.get)
        total_keywords = sum(scores.values())
        confidence = scores[best_area] / total_keywords

        return {
            "area": best_area,
            "confidence": min(confidence, 0.95),
            "keywords": keywords_map[best_area]
        }

    def _extract_legal_references(self, content: str) -> List[str]:
        """
        Extract verwijzingen naar wet- en regelgeving
        """
        legal_patterns = [
            r'(Algemene wet bestuursrecht|Awb)',
            r'(Wet open overheid|Woo|WOO)',
            r'(Algemene verordening gegevensbescherming|AVG)',
            r'(Archiefwet)',
            r'(Omgevingswet)',
            r'(Wet milieubeheer)',
        ]

        found_laws = []
        for pattern in legal_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                # Extract de volledige naam
                match = re.search(pattern, content, re.IGNORECASE)
                found_laws.append(match.group(0))

        return list(set(found_laws))

    async def _assess_woo_relevance(self, content: str) -> Dict:
        """
        Bepaal of document WOO-relevant is
        Criteria:
        - Bevat besluitvorming?
        - Is van openbaar belang?
        - Bevat beleidsvorming?
        """
        woo_indicators = [
            "raadsvoorstel", "besluit", "advies", "bestuurlijk",
            "beleidsvoorstel", "collegevoorstel", "bestuursopdracht"
        ]

        content_lower = content.lower()
        indicator_count = sum(1 for ind in woo_indicators if ind in content_lower)

        if indicator_count >= 2:
            return {
                "is_relevant": True,
                "confidence": 0.90,
                "reasoning": f"Document bevat {indicator_count} WOO-indicatoren (besluitvorming/beleid)"
            }
        elif indicator_count == 1:
            return {
                "is_relevant": True,
                "confidence": 0.70,
                "reasoning": "Document lijkt beleidsmatig relevant"
            }
        else:
            return {
                "is_relevant": False,
                "confidence": 0.60,
                "reasoning": "Geen duidelijke WOO-indicatoren gevonden"
            }

    async def _classify_document(self, content: str) -> Dict:
        """
        Classificeer document: openbaar, intern, vertrouwelijk, geheim
        """
        confidential_indicators = [
            "vertrouwelijk", "geheim", "confidential", "niet voor publicatie",
            "bsn", "persoonsgegeven", "privacy"
        ]

        public_indicators = [
            "openbaar", "public", "publicatie", "bekendmaking"
        ]

        content_lower = content.lower()

        # Check voor expliciete markering
        if any(ind in content_lower for ind in confidential_indicators):
            return {
                "level": "vertrouwelijk",
                "confidence": 0.85,
                "reasoning": "Document bevat vertrouwelijke indicatoren"
            }
        elif any(ind in content_lower for ind in public_indicators):
            return {
                "level": "openbaar",
                "confidence": 0.80,
                "reasoning": "Document expliciet gemarkeerd als openbaar"
            }
        else:
            return {
                "level": "intern",
                "confidence": 0.65,
                "reasoning": "Geen expliciete classificatie, standaard intern"
            }

    async def _suggest_retention_period(
        self,
        content: str,
        metadata: Optional[Dict]
    ) -> Dict:
        """
        Suggereer bewaartermijn op basis van documenttype en regelgeving
        """
        # Mapping van documenttypes naar bewaartermijnen (volgens Archiefwet)
        retention_rules = {
            "besluit": (20, "Besluiten: 20 jaar conform Archiefwet"),
            "raadsvoorstel": (20, "Raadsvoorstellen: 20 jaar"),
            "advies": (7, "Adviezen: 7 jaar"),
            "subsidie": (7, "Subsidiedossiers: 7 jaar na afronding"),
            "contract": (7, "Contracten: 7 jaar na afloop"),
            "correspondentie": (5, "Reguliere correspondentie: 5 jaar"),
        }

        content_lower = content.lower()

        for doc_type, (years, reasoning) in retention_rules.items():
            if doc_type in content_lower:
                return {
                    "years": years,
                    "confidence": 0.85,
                    "reasoning": reasoning
                }

        # Default
        return {
            "years": 5,
            "confidence": 0.60,
            "reasoning": "Standaard bewaartermijn voor niet-geclassificeerde documenten"
        }

    async def _generate_tags(self, content: str) -> List[str]:
        """
        Genereer tags op basis van inhoud
        In productie: gebruik keyword extraction (RAKE, YAKE, of LLM)
        """
        # Simpele implementatie: meest voorkomende relevante woorden
        stopwords = {"de", "het", "een", "van", "voor", "en", "in", "op", "is", "aan"}

        words = re.findall(r'\b[a-zà-ÿ]{4,}\b', content.lower())
        word_freq = {}

        for word in words:
            if word not in stopwords:
                word_freq[word] = word_freq.get(word, 0) + 1

        # Top 5 meest voorkomende woorden
        top_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)[:5]
        tags = [word for word, freq in top_words]

        return tags

class ContextRecommendationEngine:
    """
    AI-gedreven aanbevelingen voor context-aware apps en gerelateerde domeinen
    """

    def __init__(self):
        # In productie: load trained model
        pass

    async def recommend_apps(
        self,
        user_id: str,
        domain_type: str,
        domain_metadata: Dict,
        user_history: List[Dict]
    ) -> List[Dict]:
        """
        Aanbevelen van apps op basis van:
        1. Context (domain type)
        2. Gebruikersgedrag (collaborative filtering)
        3. Domain metadata
        """
        # Simulatie van app recommendation logic

        app_relevance = {
            "zaak": ["document_generator", "compliance_checker", "stakeholder_mapper"],
            "project": ["data_explorer", "timeline_viewer", "collaboration_hub"],
            "beleid": ["document_generator", "stakeholder_mapper", "data_explorer"],
        }

        base_apps = app_relevance.get(domain_type, [])

        # Score op basis van gebruikshistorie
        recommendations = []
        for app in base_apps:
            usage_count = sum(1 for h in user_history if h.get('app_id') == app)
            score = 0.7 + (min(usage_count, 10) * 0.03)  # Max 1.0

            recommendations.append({
                "app_id": app,
                "relevance_score": score,
                "reason": f"Relevant voor {domain_type}" +
                         (f" | Je hebt deze {usage_count}x gebruikt" if usage_count > 0 else "")
            })

        return sorted(recommendations, key=lambda x: x['relevance_score'], reverse=True)

    async def find_related_domains(
        self,
        domain_id: str,
        domain_metadata: Dict,
        all_domains: List[Dict]
    ) -> List[Tuple[str, float]]:
        """
        Vind gerelateerde domeinen via semantic similarity
        In productie: gebruik embeddings (OpenAI, sentence-transformers)
        """
        # Simulatie - in productie:
        # embedding1 = self.embeddings_model.embed(domain_metadata['description'])
        # for domain in all_domains:
        #     embedding2 = self.embeddings_model.embed(domain['description'])
        #     similarity = cosine_similarity(embedding1, embedding2)

        # Simpele keyword overlap voor demo
        current_tags = set(domain_metadata.get('tags', []))

        related = []
        for domain in all_domains:
            if domain['id'] == domain_id:
                continue

            other_tags = set(domain.get('tags', []))
            overlap = len(current_tags & other_tags)

            if overlap > 0:
                similarity = overlap / max(len(current_tags), len(other_tags))
                related.append((domain['id'], similarity))

        return sorted(related, key=lambda x: x[1], reverse=True)[:5]

class ComplianceRuleExtractor:
    """
    Extract regellogica uit wet- en regelgeving teksten
    Vertaal naar machine-leesbare regels
    """

    async def extract_rules_from_law_text(self, law_text: str) -> List[Dict]:
        """
        Parse wet/regelgeving en extract regellogica
        Voorbeeld: "Besluiten moeten 20 jaar bewaard worden"
        → {"object_type": "besluit", "retention_period": 20}
        """
        rules = []

        # Patroon: "[documenttype] moet/moeten [X] jaar bewaard worden"
        retention_pattern = r'(\w+)\s+moet(?:en)?\s+(\d+)\s+jaar\s+bewaard'

        matches = re.finditer(retention_pattern, law_text.lower())
        for match in matches:
            doc_type = match.group(1)
            years = int(match.group(2))

            rules.append({
                "rule_type": "retention",
                "applies_to": doc_type,
                "retention_years": years,
                "confidence": 0.90,
                "source_text": match.group(0)
            })

        return rules

# ============================================
# USAGE EXAMPLE
# ============================================

async def example_usage():
    """Voorbeeld van hoe de AI service gebruikt wordt"""

    # Initialiseer service
    ai_service = AIMetadataService(model_provider="openai")

    # Voorbeeld document content
    document_content = """
    Raadsvoorstel: Subsidieregeling Circulaire Economie Flevoland

    Datum: 15 maart 2025
    Versie: 2.0

    Aan de gemeenteraad van Flevoland,

    Hierbij bieden wij u het voorstel aan voor een nieuwe subsidieregeling
    gericht op het stimuleren van circulaire economie in de provincie Flevoland.

    De regeling valt onder de Algemene wet bestuursrecht en is openbaar
    conform de Wet open overheid (Woo).

    Contactpersoon: Maria Jansen
    Locatie: Almere, Lelystad
    """

    # Extract metadata
    suggestions = await ai_service.extract_metadata_from_document(
        content=document_content,
        filename="2025-03-15_Raadsvoorstel_Subsidie_Circulair_v2.pdf"
    )

    # Print resultaten
    print("AI Metadata Suggesties:")
    print("=" * 60)
    for suggestion in suggestions:
        print(f"\nVeld: {suggestion.field}")
        print(f"Waarde: {suggestion.value}")
        print(f"Confidence: {suggestion.confidence:.2%}")
        print(f"Reden: {suggestion.reasoning}")

    # Context recommendation
    rec_engine = ContextRecommendationEngine()
    app_recs = await rec_engine.recommend_apps(
        user_id="user123",
        domain_type="beleid",
        domain_metadata={"tags": ["circulair", "subsidie"]},
        user_history=[{"app_id": "document_generator"}]
    )

    print("\n" + "=" * 60)
    print("App Aanbevelingen:")
    for rec in app_recs:
        print(f"- {rec['app_id']}: {rec['relevance_score']:.2%} ({rec['reason']})")

if __name__ == "__main__":
    asyncio.run(example_usage())
