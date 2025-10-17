-- IOU Concept - Test Data
-- Complete testdata voor alle sectoren van de Informatie Ondersteunde Werkomgeving

-- ============================================
-- 1. ORGANISATIES
-- ============================================

INSERT INTO organizations (id, name, type) VALUES
('a0000000-0000-0000-0000-000000000001', 'Provincie Flevoland', 'provincie'),
('a0000000-0000-0000-0000-000000000002', 'Gemeente Almere', 'gemeente'),
('a0000000-0000-0000-0000-000000000003', 'Gemeente Lelystad', 'gemeente'),
('a0000000-0000-0000-0000-000000000004', 'Waterschap Zuiderzeeland', 'waterschap'),
('a0000000-0000-0000-0000-000000000005', 'Ministerie van Infrastructuur en Waterstaat', 'rijk');

-- ============================================
-- 2. AFDELINGEN
-- ============================================

INSERT INTO departments (id, organization_id, name) VALUES
-- Provincie Flevoland
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Mobiliteit & Bereikbaarheid'),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Economie & Duurzaamheid'),
('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Ruimte & Leefomgeving'),
('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Juridische Zaken'),
('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'ICT & Digitalisering'),
-- Gemeente Almere
('b0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000002', 'Stadsontwikkeling'),
('b0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000002', 'Vergunningen & Handhaving'),
-- Gemeente Lelystad
('b0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000003', 'Haven & Logistiek');

-- ============================================
-- 3. ROLLEN
-- ============================================

INSERT INTO roles (id, name, description, department_id, permissions) VALUES
('c0000000-0000-0000-0000-000000000001', 'Beleidsmedewerker', 'Ontwikkelt en evalueert beleid', 'b0000000-0000-0000-0000-000000000002',
 '{"can_read": true, "can_write": true, "can_delete": false, "can_share": true}'::jsonb),
('c0000000-0000-0000-0000-000000000002', 'Projectleider', 'Leidt complexe projecten', 'b0000000-0000-0000-0000-000000000002',
 '{"can_read": true, "can_write": true, "can_delete": true, "can_share": true}'::jsonb),
('c0000000-0000-0000-0000-000000000003', 'Juridisch Adviseur', 'Geeft juridisch advies', 'b0000000-0000-0000-0000-000000000004',
 '{"can_read": true, "can_write": true, "can_delete": false, "can_share": false}'::jsonb),
('c0000000-0000-0000-0000-000000000004', 'Data Analist', 'Analyseert data en trends', 'b0000000-0000-0000-0000-000000000005',
 '{"can_read": true, "can_write": true, "can_delete": false, "can_share": true}'::jsonb),
('c0000000-0000-0000-0000-000000000005', 'Vergunningverlener', 'Behandelt vergunningaanvragen', 'b0000000-0000-0000-0000-000000000012',
 '{"can_read": true, "can_write": true, "can_delete": false, "can_share": false}'::jsonb);

-- ============================================
-- 4. GEBRUIKERS
-- ============================================

INSERT INTO users (id, email, name, department_id) VALUES
-- Provincie Flevoland
('d0000000-0000-0000-0000-000000000001', 'maria.jansen@flevoland.nl', 'Maria Jansen', 'b0000000-0000-0000-0000-000000000002'),
('d0000000-0000-0000-0000-000000000002', 'jan.bakker@flevoland.nl', 'Jan Bakker', 'b0000000-0000-0000-0000-000000000004'),
('d0000000-0000-0000-0000-000000000003', 'sophie.devries@flevoland.nl', 'Sophie de Vries', 'b0000000-0000-0000-0000-000000000005'),
('d0000000-0000-0000-0000-000000000004', 'peter.vandenberg@flevoland.nl', 'Peter van den Berg', 'b0000000-0000-0000-0000-000000000001'),
('d0000000-0000-0000-0000-000000000005', 'lisa.vermeulen@flevoland.nl', 'Lisa Vermeulen', 'b0000000-0000-0000-0000-000000000003'),
-- Gemeente Almere
('d0000000-0000-0000-0000-000000000011', 'tom.hendriks@almere.nl', 'Tom Hendriks', 'b0000000-0000-0000-0000-000000000011'),
('d0000000-0000-0000-0000-000000000012', 'anna.dejong@almere.nl', 'Anna de Jong', 'b0000000-0000-0000-0000-000000000012'),
-- Gemeente Lelystad
('d0000000-0000-0000-0000-000000000021', 'mark.peters@lelystad.nl', 'Mark Peters', 'b0000000-0000-0000-0000-000000000021');

-- ============================================
-- 5. GEBRUIKER-ROLLEN KOPPELING
-- ============================================

INSERT INTO user_roles (user_id, role_id) VALUES
('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001'), -- Maria = Beleidsmedewerker
('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002'), -- Maria = ook Projectleider
('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003'), -- Jan = Juridisch Adviseur
('d0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000004'), -- Sophie = Data Analist
('d0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000002'), -- Peter = Projectleider
('d0000000-0000-0000-0000-000000000012', 'c0000000-0000-0000-0000-000000000005'); -- Anna = Vergunningverlener

-- ============================================
-- 6. INFORMATIEDOMEINEN - PROJECTEN
-- ============================================

INSERT INTO information_domains (id, type, name, description, status, organization_id, owner_user_id, metadata) VALUES
('e0000000-0000-0000-0000-000000000001', 'project', 'Circulaire Economie Flevoland 2025',
 'Transitie naar circulaire economie met focus op afvalreductie en hergebruik',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
 '{"tags": ["circulair", "duurzaamheid", "innovatie"], "budget": 2500000, "priority": "hoog"}'::jsonb),

('e0000000-0000-0000-0000-000000000002', 'project', 'Digitale Transformatie Provincie',
 'Modernisering van ICT-infrastructuur en digitale dienstverlening',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000003',
 '{"tags": ["digitalisering", "ict", "dienstverlening"], "budget": 1800000, "priority": "hoog"}'::jsonb),

('e0000000-0000-0000-0000-000000000003', 'project', 'Windpark Flevopolder Zuid',
 'Ontwikkeling van 50 MW windpark voor duurzame energie',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000004',
 '{"tags": ["energie", "windenergie", "duurzaam"], "budget": 75000000, "priority": "hoog"}'::jsonb),

('e0000000-0000-0000-0000-000000000004', 'project', 'Smart Mobility Almere',
 'Slimme mobiliteitsoplossingen en verkeersgeleiding',
 'actief', 'a0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000011',
 '{"tags": ["mobiliteit", "smart city", "verkeer"], "budget": 950000, "priority": "middel"}'::jsonb);

-- Project details
INSERT INTO projects (id, project_code, budget, start_date, end_date, project_phase) VALUES
('e0000000-0000-0000-0000-000000000001', 'CE-2025-01', 2500000, '2025-01-01', '2027-12-31', 'definitie'),
('e0000000-0000-0000-0000-000000000002', 'DT-2025-02', 1800000, '2025-02-01', '2026-12-31', 'ontwerp'),
('e0000000-0000-0000-0000-000000000003', 'WE-2024-15', 75000000, '2024-06-01', '2028-12-31', 'realisatie'),
('e0000000-0000-0000-0000-000000000004', 'SM-2025-08', 950000, '2025-03-01', '2026-06-30', 'initiatief');

-- ============================================
-- 7. INFORMATIEDOMEINEN - ZAKEN
-- ============================================

INSERT INTO information_domains (id, type, name, description, status, organization_id, owner_user_id, metadata) VALUES
('e0000000-0000-0000-0000-000000000011', 'zaak', 'Subsidieaanvraag Groene Energie BV',
 'Aanvraag subsidie voor zonnepanelen op bedrijfspand',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
 '{"tags": ["subsidie", "energie", "zonnepanelen"], "urgency": "normaal"}'::jsonb),

('e0000000-0000-0000-0000-000000000012', 'zaak', 'Omgevingsvergunning Windturbine Dronten',
 'Vergunningaanvraag voor plaatsing 3 windturbines',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000005',
 '{"tags": ["vergunning", "windenergie", "omgevingsrecht"], "urgency": "hoog"}'::jsonb),

('e0000000-0000-0000-0000-000000000013', 'zaak', 'Bezwaar Afwijzing Bouwvergunning Almere',
 'Bezwaar tegen afwijzing bouwvergunning woning',
 'actief', 'a0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000012',
 '{"tags": ["bezwaar", "bouwvergunning", "juridisch"], "urgency": "hoog"}'::jsonb),

('e0000000-0000-0000-0000-000000000014', 'zaak', 'WOO-verzoek Windpark Communicatie',
 'Openbaarmaking documenten over windparkproject',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002',
 '{"tags": ["woo", "openbaarmaking", "windenergie"], "urgency": "hoog"}'::jsonb);

-- Zaak details
INSERT INTO cases (id, case_number, case_type, subject, start_date, target_date, legal_basis, retention_period, disclosure_class) VALUES
('e0000000-0000-0000-0000-000000000011', 'SUB-2025-0142', 'subsidie', 'Subsidie zonnepanelen bedrijven', '2025-01-15', '2025-04-15', 'Subsidieregeling Duurzame Energie Flevoland 2025', 7, 'openbaar'),
('e0000000-0000-0000-0000-000000000012', 'OMV-2025-0089', 'vergunning', 'Omgevingsvergunning windturbines', '2025-02-01', '2025-08-01', 'Omgevingswet', 10, 'openbaar'),
('e0000000-0000-0000-0000-000000000013', 'BZW-2025-0023', 'bezwaar', 'Bezwaar afwijzing bouwvergunning', '2025-02-10', '2025-04-10', 'Algemene wet bestuursrecht', 20, 'deels_openbaar'),
('e0000000-0000-0000-0000-000000000014', 'WOO-2025-0008', 'woo-verzoek', 'WOO verzoek windpark', '2025-02-20', '2025-03-20', 'Wet open overheid', 5, 'openbaar');

-- ============================================
-- 8. INFORMATIEDOMEINEN - BELEID
-- ============================================

INSERT INTO information_domains (id, type, name, description, status, organization_id, owner_user_id, metadata) VALUES
('e0000000-0000-0000-0000-000000000021', 'beleid', 'Mobiliteitsvisie Flevoland 2030',
 'Langetermijnvisie op bereikbaarheid en duurzame mobiliteit',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000004',
 '{"tags": ["mobiliteit", "visie", "bereikbaarheid"], "policy_cycle": "vaststelling"}'::jsonb),

('e0000000-0000-0000-0000-000000000022', 'beleid', 'Energietransitie Strategie',
 'Provinciale strategie voor transitie naar duurzame energie',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
 '{"tags": ["energie", "duurzaamheid", "klimaat"], "policy_cycle": "uitvoering"}'::jsonb),

('e0000000-0000-0000-0000-000000000023', 'beleid', 'Circulaire Economie Actieplan',
 'Concrete acties voor circulaire economie 2025-2030',
 'actief', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
 '{"tags": ["circulair", "afval", "grondstoffen"], "policy_cycle": "voorbereiding"}'::jsonb);

-- Beleid details
INSERT INTO policy_topics (id, policy_area, policy_cycle, responsible_department_id) VALUES
('e0000000-0000-0000-0000-000000000021', 'mobiliteit', 'vaststelling', 'b0000000-0000-0000-0000-000000000001'),
('e0000000-0000-0000-0000-000000000022', 'duurzaamheid', 'uitvoering', 'b0000000-0000-0000-0000-000000000002'),
('e0000000-0000-0000-0000-000000000023', 'economie', 'voorbereiding', 'b0000000-0000-0000-0000-000000000002');

-- ============================================
-- 9. INFORMATIE OBJECTEN (Documenten)
-- ============================================

INSERT INTO information_objects (
    id, domain_id, object_type, title, content_location, mime_type,
    classification, retention_period, is_woo_relevant, privacy_level,
    tags, created_by, metadata
) VALUES
-- Project Circulaire Economie
('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'document',
 'Projectplan Circulaire Economie Q1 2025', '/docs/projectplan-ce-q1-2025.pdf', 'application/pdf',
 'intern', 7, false, 'normaal',
 ARRAY['projectplan', 'circulair', 'planning'], 'd0000000-0000-0000-0000-000000000001',
 '{"version": "2.0", "status": "definitief", "pages": 45}'::jsonb),

('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'document',
 'Data-analyse Afvalstromen Flevoland 2024', '/docs/afvalstromen-analyse-2024.xlsx', 'application/vnd.ms-excel',
 'openbaar', 10, true, 'normaal',
 ARRAY['data', 'analyse', 'afval', 'statistiek'], 'd0000000-0000-0000-0000-000000000003',
 '{"rows": 1250, "datasets": 5, "period": "2024"}'::jsonb),

('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 'document',
 'Raadsvoorstel Circulaire Inkoop', '/docs/raadsvoorstel-circulaire-inkoop.pdf', 'application/pdf',
 'openbaar', 20, true, 'normaal',
 ARRAY['besluit', 'inkoop', 'circulair', 'raad'], 'd0000000-0000-0000-0000-000000000001',
 '{"decision_date": "2025-03-15", "status": "vastgesteld"}'::jsonb),

-- Project Digitale Transformatie
('f0000000-0000-0000-0000-000000000011', 'e0000000-0000-0000-0000-000000000002', 'document',
 'ICT Architectuur Blauwdruk 2025', '/docs/ict-architectuur-2025.pdf', 'application/pdf',
 'intern', 10, false, 'vertrouwelijk',
 ARRAY['architectuur', 'ict', 'technisch'], 'd0000000-0000-0000-0000-000000000003',
 '{"version": "1.5", "review_date": "2025-06-01"}'::jsonb),

('f0000000-0000-0000-0000-000000000012', 'e0000000-0000-0000-0000-000000000002', 'document',
 'Business Case Digitale Dienstverlening', '/docs/business-case-digitaal.docx', 'application/msword',
 'intern', 7, false, 'normaal',
 ARRAY['business case', 'digitaal', 'financieel'], 'd0000000-0000-0000-0000-000000000003',
 '{"investment": 1800000, "roi_years": 4}'::jsonb),

-- Zaak Subsidieaanvraag
('f0000000-0000-0000-0000-000000000021', 'e0000000-0000-0000-0000-000000000011', 'document',
 'Subsidieaanvraag Groene Energie BV', '/docs/subsidie-groene-energie-aanvraag.pdf', 'application/pdf',
 'intern', 7, false, 'vertrouwelijk',
 ARRAY['subsidie', 'aanvraag', 'zonnepanelen'], 'd0000000-0000-0000-0000-000000000001',
 '{"amount_requested": 125000, "applicant": "Groene Energie BV"}'::jsonb),

('f0000000-0000-0000-0000-000000000022', 'e0000000-0000-0000-0000-000000000011', 'document',
 'Advies Subsidieregeling Duurzame Energie', '/docs/advies-subsidie-duurzaam.pdf', 'application/pdf',
 'intern', 7, false, 'normaal',
 ARRAY['advies', 'subsidie', 'juridisch'], 'd0000000-0000-0000-0000-000000000002',
 '{"advice": "positief", "conditions": ["monitoring CO2 reductie", "publicatie resultaten"]}'::jsonb),

-- Zaak Omgevingsvergunning
('f0000000-0000-0000-0000-000000000031', 'e0000000-0000-0000-0000-000000000012', 'document',
 'Aanvraag Omgevingsvergunning Windturbines', '/docs/omv-windturbines-dronten.pdf', 'application/pdf',
 'openbaar', 10, true, 'normaal',
 ARRAY['vergunning', 'windenergie', 'aanvraag'], 'd0000000-0000-0000-0000-000000000005',
 '{"turbines": 3, "height_meters": 150, "capacity_mw": 12}'::jsonb),

('f0000000-0000-0000-0000-000000000032', 'e0000000-0000-0000-0000-000000000012', 'document',
 'MER Windturbines Dronten', '/docs/mer-windturbines-dronten.pdf', 'application/pdf',
 'openbaar', 10, true, 'normaal',
 ARRAY['mer', 'milieu', 'windenergie'], 'd0000000-0000-0000-0000-000000000005',
 '{"pages": 156, "conclusion": "geen significant negatieve effecten"}'::jsonb),

-- Zaak WOO-verzoek
('f0000000-0000-0000-0000-000000000041', 'e0000000-0000-0000-0000-000000000014', 'document',
 'WOO-verzoek Windpark Communicatie', '/docs/woo-verzoek-windpark.pdf', 'application/pdf',
 'openbaar', 5, true, 'normaal',
 ARRAY['woo', 'verzoek', 'windpark'], 'd0000000-0000-0000-0000-000000000002',
 '{"requester": "Stichting Natuur Flevoland", "period": "2023-2025"}'::jsonb),

('f0000000-0000-0000-0000-000000000042', 'e0000000-0000-0000-0000-000000000014', 'document',
 'Inventarisatie WOO-documenten Windpark', '/docs/woo-inventarisatie.xlsx', 'application/vnd.ms-excel',
 'intern', 5, false, 'normaal',
 ARRAY['woo', 'inventarisatie', 'intern'], 'd0000000-0000-0000-0000-000000000002',
 '{"documents_found": 47, "fully_public": 32, "partially_public": 12, "confidential": 3}'::jsonb),

-- Beleid Mobiliteitsvisie
('f0000000-0000-0000-0000-000000000051', 'e0000000-0000-0000-0000-000000000021', 'document',
 'Mobiliteitsvisie Flevoland 2030 - Concept', '/docs/mobiliteitsvisie-2030-concept.pdf', 'application/pdf',
 'openbaar', 20, true, 'normaal',
 ARRAY['visie', 'mobiliteit', 'beleid'], 'd0000000-0000-0000-0000-000000000004',
 '{"version": "concept", "consultation_period": "2025-03-01 tot 2025-04-30"}'::jsonb),

('f0000000-0000-0000-0000-000000000052', 'e0000000-0000-0000-0000-000000000021', 'data',
 'Verkeerscijfers Flevoland 2020-2024', '/data/verkeerscijfers-2020-2024.csv', 'text/csv',
 'openbaar', 10, true, 'normaal',
 ARRAY['data', 'verkeer', 'statistiek'], 'd0000000-0000-0000-0000-000000000003',
 '{"records": 50000, "sources": ["NDW", "Provincie tellingen"], "format": "CSV"}'::jsonb),

-- Beleid Energietransitie
('f0000000-0000-0000-0000-000000000061', 'e0000000-0000-0000-0000-000000000022', 'document',
 'Energietransitie Strategie 2025-2035', '/docs/energietransitie-strategie.pdf', 'application/pdf',
 'openbaar', 20, true, 'normaal',
 ARRAY['energie', 'strategie', 'klimaat'], 'd0000000-0000-0000-0000-000000000001',
 '{"approved_date": "2024-12-15", "status": "vastgesteld"}'::jsonb);

-- ============================================
-- 10. STAKEHOLDERS
-- ============================================

INSERT INTO stakeholders (id, type, name, contact_details) VALUES
('g0000000-0000-0000-0000-000000000001', 'bedrijf', 'Groene Energie BV',
 '{"email": "info@groene-energie.nl", "phone": "036-1234567", "address": "Energieweg 12, Almere"}'::jsonb),
('g0000000-0000-0000-0000-000000000002', 'organisatie', 'Circulair Nederland',
 '{"email": "contact@circulair.nl", "website": "www.circulair.nl"}'::jsonb),
('g0000000-0000-0000-0000-000000000003', 'organisatie', 'Stichting Natuur Flevoland',
 '{"email": "info@natuurflevoland.nl", "phone": "0320-123456"}'::jsonb),
('g0000000-0000-0000-0000-000000000004', 'burger', 'Familie Smit',
 '{"address": "Bouwstraat 45, Almere", "case_id": "BZW-2025-0023"}'::jsonb),
('g0000000-0000-0000-0000-000000000005', 'organisatie', 'WindPower Nederland BV',
 '{"email": "info@windpower.nl", "phone": "020-9876543", "website": "www.windpower.nl"}'::jsonb);

-- ============================================
-- 11. DOMAIN - STAKEHOLDER RELATIES
-- ============================================

INSERT INTO domain_stakeholders (domain_id, stakeholder_id, role) VALUES
-- Circulaire Economie project
('e0000000-0000-0000-0000-000000000001', 'g0000000-0000-0000-0000-000000000002', 'kennispartner'),
-- Subsidieaanvraag
('e0000000-0000-0000-0000-000000000011', 'g0000000-0000-0000-0000-000000000001', 'aanvrager'),
-- Omgevingsvergunning windturbines
('e0000000-0000-0000-0000-000000000012', 'g0000000-0000-0000-0000-000000000005', 'initiatiefnemer'),
('e0000000-0000-0000-0000-000000000012', 'g0000000-0000-0000-0000-000000000003', 'belanghebbende'),
-- Bezwaar bouwvergunning
('e0000000-0000-0000-0000-000000000013', 'g0000000-0000-0000-0000-000000000004', 'bezwaarmaker'),
-- WOO-verzoek
('e0000000-0000-0000-0000-000000000014', 'g0000000-0000-0000-0000-000000000003', 'verzoeker');

-- ============================================
-- 12. DOMAIN RELATIES (Gerelateerde domeinen)
-- ============================================

INSERT INTO domain_relations (from_domain_id, to_domain_id, relation_type, description) VALUES
-- Circulaire Economie project gerelateerd aan beleid
('e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000023', 'uitvoering_van', 'Project voert actieplan uit'),
-- Windpark project gerelateerd aan vergunningzaak
('e0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000012', 'gerelateerd_aan', 'Vergunning voor windpark'),
-- WOO-verzoek gerelateerd aan windpark
('e0000000-0000-0000-0000-000000000014', 'e0000000-0000-0000-0000-000000000003', 'betreft', 'WOO-verzoek over windparkproject'),
-- Mobiliteitsvisie gerelateerd aan Smart Mobility project
('e0000000-0000-0000-0000-000000000021', 'e0000000-0000-0000-0000-000000000004', 'basis_voor', 'Visie is basis voor project'),
-- Energietransitie strategie gerelateerd aan Circulaire Economie
('e0000000-0000-0000-0000-000000000022', 'e0000000-0000-0000-0000-000000000001', 'gerelateerd_aan', 'Beide onderdeel duurzaamheidsagenda');

-- ============================================
-- 13. APPS (Context-Aware Applications)
-- ============================================

INSERT INTO apps (id, name, description, app_type, icon_url, endpoint_url, relevant_for_domain_types, relevant_for_roles) VALUES
('h0000000-0000-0000-0000-000000000001', 'Data Explorer',
 'Analyseer en visualiseer data, GIS-kaarten en statistieken',
 'data_explorer', '/icons/data.svg', 'http://apps.iou.local/data-explorer',
 ARRAY['project', 'beleid'], ARRAY['Data Analist', 'Beleidsmedewerker']),

('h0000000-0000-0000-0000-000000000002', 'Document Generator',
 'Genereer documenten met automatische metadata en compliance check',
 'document_generator', '/icons/document.svg', 'http://apps.iou.local/doc-generator',
 ARRAY['zaak', 'project', 'beleid'], ARRAY['Beleidsmedewerker', 'Projectleider', 'Juridisch Adviseur']),

('h0000000-0000-0000-0000-000000000003', 'Stakeholder Mapper',
 'Visualiseer netwerk van betrokken partijen en relaties',
 'stakeholder_mapper', '/icons/stakeholder.svg', 'http://apps.iou.local/stakeholder-map',
 ARRAY['project', 'zaak'], ARRAY['Projectleider', 'Beleidsmedewerker']),

('h0000000-0000-0000-0000-000000000004', 'Compliance Checker',
 'Controleer WOO-relevantie, archivering en AVG compliance',
 'compliance_checker', '/icons/compliance.svg', 'http://apps.iou.local/compliance',
 ARRAY['zaak', 'beleid'], ARRAY['Juridisch Adviseur', 'Beleidsmedewerker']),

('h0000000-0000-0000-0000-000000000005', 'Timeline Viewer',
 'Chronologisch overzicht van alle gebeurtenissen in een domein',
 'timeline_viewer', '/icons/timeline.svg', 'http://apps.iou.local/timeline',
 ARRAY['project', 'zaak'], ARRAY['Projectleider', 'Vergunningverlener']),

('h0000000-0000-0000-0000-000000000006', 'Collaboration Hub',
 'Chat, videobellen en gezamenlijk werken aan documenten',
 'collaboration_hub', '/icons/collab.svg', 'http://apps.iou.local/collab',
 ARRAY['project', 'zaak', 'beleid'], ARRAY['Projectleider', 'Beleidsmedewerker']),

('h0000000-0000-0000-0000-000000000007', 'GEO Visualizer',
 'Geografische weergave van projecten en ruimtelijke data',
 'geo_visualizer', '/icons/geo.svg', 'http://apps.iou.local/geo',
 ARRAY['project', 'zaak', 'beleid'], ARRAY['Beleidsmedewerker', 'Projectleider']),

('h0000000-0000-0000-0000-000000000008', 'Subsidie Calculator',
 'Bereken subsidiebedragen en controleer voorwaarden',
 'subsidie_calculator', '/icons/calculator.svg', 'http://apps.iou.local/subsidie',
 ARRAY['zaak'], ARRAY['Beleidsmedewerker', 'Vergunningverlener']);

-- ============================================
-- 14. USER APP USAGE (voor aanbevelingen)
-- ============================================

INSERT INTO user_app_usage (user_id, app_id, domain_id, usage_count, last_used_at) VALUES
-- Maria (Beleidsmedewerker) gebruikt veel Document Generator en Data Explorer
('d0000000-0000-0000-0000-000000000001', 'h0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 25, NOW() - INTERVAL '2 hours'),
('d0000000-0000-0000-0000-000000000001', 'h0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 18, NOW() - INTERVAL '1 day'),
('d0000000-0000-0000-0000-000000000001', 'h0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 12, NOW() - INTERVAL '3 days'),
-- Sophie (Data Analist) gebruikt vooral Data Explorer en GEO
('d0000000-0000-0000-0000-000000000003', 'h0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002', 45, NOW() - INTERVAL '3 hours'),
('d0000000-0000-0000-0000-000000000003', 'h0000000-0000-0000-0000-000000000007', 'e0000000-0000-0000-0000-000000000002', 22, NOW() - INTERVAL '1 day'),
-- Jan (Juridisch) gebruikt Compliance Checker en Document Generator
('d0000000-0000-0000-0000-000000000002', 'h0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000014', 30, NOW() - INTERVAL '5 hours'),
('d0000000-0000-0000-0000-000000000002', 'h0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000014', 15, NOW() - INTERVAL '2 days'),
-- Anna (Vergunningverlener) gebruikt Timeline en Compliance
('d0000000-0000-0000-0000-000000000012', 'h0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000013', 20, NOW() - INTERVAL '6 hours'),
('d0000000-0000-0000-0000-000000000012', 'h0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000013', 16, NOW() - INTERVAL '1 day');

-- ============================================
-- 15. BUSINESS RULES (Compliance Regelset)
-- ============================================

INSERT INTO business_rules (id, rule_name, rule_category, legal_basis, rule_logic, applies_to_domain_types, applies_to_object_types, active) VALUES
('i0000000-0000-0000-0000-000000000001', 'Bewaartermijn Besluiten', 'archivering', 'Archiefwet art. 3',
 '{"conditions": [{"field": "object_type", "operator": "equals", "value": "besluit"}], "actions": [{"set_field": "retention_period", "value": 20}]}'::jsonb,
 ARRAY['zaak', 'beleid'], ARRAY['document'], true),

('i0000000-0000-0000-0000-000000000002', 'WOO-relevantie Raadsvoorstellen', 'woo', 'Wet open overheid art. 3.1',
 '{"conditions": [{"field": "title", "operator": "contains", "value": "raadsvoorstel"}], "actions": [{"set_field": "is_woo_relevant", "value": true}, {"set_field": "disclosure_class", "value": "openbaar"}]}'::jsonb,
 ARRAY['beleid'], ARRAY['document'], true),

('i0000000-0000-0000-0000-000000000003', 'Bewaartermijn Subsidiedossiers', 'archivering', 'Archiefwet',
 '{"conditions": [{"field": "case_type", "operator": "equals", "value": "subsidie"}], "actions": [{"set_field": "retention_period", "value": 7}]}'::jsonb,
 ARRAY['zaak'], ARRAY['document'], true),

('i0000000-0000-0000-0000-000000000004', 'Privacy Bescherming Persoonsgegevens', 'avg', 'AVG art. 5',
 '{"conditions": [{"field": "content", "operator": "contains_any", "value": ["BSN", "geboortedatum", "adres"]}], "actions": [{"set_field": "privacy_level", "value": "hoog"}, {"set_field": "classification", "value": "vertrouwelijk"}]}'::jsonb,
 ARRAY['zaak'], ARRAY['document', 'email'], true),

('i0000000-0000-0000-0000-000000000005', 'WOO-relevantie Omgevingsvergunningen', 'woo', 'Wet open overheid',
 '{"conditions": [{"field": "case_type", "operator": "equals", "value": "vergunning"}], "actions": [{"set_field": "is_woo_relevant", "value": true}]}'::jsonb,
 ARRAY['zaak'], ARRAY['document'], true);

-- ============================================
-- 16. AI METADATA SUGGESTIES (Demo data)
-- ============================================

INSERT INTO ai_metadata_suggestions (object_id, suggestion_type, suggested_value, confidence_score, model_version, accepted) VALUES
('f0000000-0000-0000-0000-000000000001', 'tag', 'duurzaamheid', 0.92, 'gpt-4-1.0', true),
('f0000000-0000-0000-0000-000000000001', 'classification', 'intern', 0.88, 'gpt-4-1.0', true),
('f0000000-0000-0000-0000-000000000002', 'tag', 'milieu', 0.85, 'gpt-4-1.0', null),
('f0000000-0000-0000-0000-000000000002', 'retention_period', '10', 0.90, 'gpt-4-1.0', null),
('f0000000-0000-0000-0000-000000000021', 'classification', 'vertrouwelijk', 0.95, 'gpt-4-1.0', true),
('f0000000-0000-0000-0000-000000000031', 'tag', 'windenergie', 0.98, 'gpt-4-1.0', true);

-- ============================================
-- 17. AUDIT LOG (Recente activiteit)
-- ============================================

INSERT INTO audit_log (user_id, action, object_type, object_id, domain_id, timestamp) VALUES
('d0000000-0000-0000-0000-000000000001', 'create', 'document', 'f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '2 days'),
('d0000000-0000-0000-0000-000000000001', 'update', 'document', 'f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day'),
('d0000000-0000-0000-0000-000000000003', 'create', 'document', 'f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '5 hours'),
('d0000000-0000-0000-0000-000000000002', 'read', 'document', 'f0000000-0000-0000-0000-000000000041', 'e0000000-0000-0000-0000-000000000014', NOW() - INTERVAL '3 hours'),
('d0000000-0000-0000-0000-000000000001', 'read', 'domain', 'e0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 hour'),
('d0000000-0000-0000-0000-000000000003', 'access', 'app', 'h0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002', NOW() - INTERVAL '30 minutes');

-- ============================================
-- KLAAR! Testdata succesvol aangemaakt
-- ============================================

-- Overzicht van aangemaakte data:
SELECT 'Organizations' as entity, COUNT(*) as count FROM organizations
UNION ALL
SELECT 'Departments', COUNT(*) FROM departments
UNION ALL
SELECT 'Roles', COUNT(*) FROM roles
UNION ALL
SELECT 'Users', COUNT(*) FROM users
UNION ALL
SELECT 'Information Domains', COUNT(*) FROM information_domains
UNION ALL
SELECT 'Projects', COUNT(*) FROM projects
UNION ALL
SELECT 'Cases', COUNT(*) FROM cases
UNION ALL
SELECT 'Policy Topics', COUNT(*) FROM policy_topics
UNION ALL
SELECT 'Information Objects', COUNT(*) FROM information_objects
UNION ALL
SELECT 'Stakeholders', COUNT(*) FROM stakeholders
UNION ALL
SELECT 'Apps', COUNT(*) FROM apps
UNION ALL
SELECT 'Business Rules', COUNT(*) FROM business_rules
UNION ALL
SELECT 'Audit Log Entries', COUNT(*) FROM audit_log;
