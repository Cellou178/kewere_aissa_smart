-- ================================================================
-- SEED prix_marche — Afrique de l'Ouest (multi-pays)
-- Exécuter dans Supabase → SQL Editor
-- ================================================================

-- Vider les anciennes données pour réinsérer proprement
TRUNCATE TABLE prix_marche RESTART IDENTITY;

INSERT INTO prix_marche (categorie, produit, unite, prix, pays, ville, tendance, variation) VALUES
-- ── Sénégal ────────────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     2800,  'Sénégal',        'Dakar',       'hausse',  5.2),
('poulet',  'Poulet vif',                   'par kg',     2650,  'Sénégal',        'Thiès',       'stable',  0.5),
('poulet',  'Poulet vif',                   'par kg',     2700,  'Sénégal',        'Mbour',       'hausse',  3.1),
('poulet',  'Poulet vif',                   'par kg',     2600,  'Sénégal',        'Saint-Louis',  'stable',  1.0),
('poulet',  'Poulet vif',                   'par kg',     2750,  'Sénégal',        'Ziguinchor',  'hausse',  2.8),

-- ── Côte d'Ivoire ──────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     3200,  'Côte d''Ivoire', 'Abidjan',     'baisse', -2.3),
('poulet',  'Poulet vif',                   'par kg',     3000,  'Côte d''Ivoire', 'Bouaké',      'stable',  0.8),
('poulet',  'Poulet vif',                   'par kg',     3100,  'Côte d''Ivoire', 'Yamoussoukro','stable',  1.2),

-- ── Mali ───────────────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     2400,  'Mali',           'Bamako',      'stable',  1.0),
('poulet',  'Poulet vif',                   'par kg',     2300,  'Mali',           'Sikasso',     'baisse', -1.5),

-- ── Guinée ────────────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     2500,  'Guinée',         'Conakry',     'hausse',  4.0),
('poulet',  'Poulet vif',                   'par kg',     2350,  'Guinée',         'Kindia',      'stable',  0.3),

-- ── Burkina Faso ──────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     2550,  'Burkina Faso',   'Ouagadougou', 'hausse',  3.5),
('poulet',  'Poulet vif',                   'par kg',     2450,  'Burkina Faso',   'Bobo-Dioulasso','stable', 1.1),

-- ── Gambie ────────────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     2900,  'Gambie',         'Banjul',      'hausse',  6.0),

-- ── Ghana ─────────────────────────────────────────────────────
('poulet',  'Poulet vif',                   'par kg',     3050,  'Ghana',          'Accra',       'stable',  0.9),

-- ── Aliments & Intrants (Sénégal) ─────────────────────────────
('aliment', 'Sac aliment démarrage 50kg',   'par sac',   18500,  'Sénégal',        'Dakar',       'hausse',  8.3),
('aliment', 'Sac aliment croissance 50kg',  'par sac',   17000,  'Sénégal',        'Dakar',       'hausse',  6.1),
('aliment', 'Sac aliment finition 50kg',    'par sac',   16500,  'Sénégal',        'Dakar',       'stable',  0.8),
('aliment', 'Poussin Cobb 500',             'par poussin', 650,  'Sénégal',        'Dakar',       'hausse',  4.2),
('aliment', 'Poussin Ross 308',             'par poussin', 700,  'Sénégal',        'Dakar',       'hausse',  3.8),
('aliment', 'Maïs grain',                  'par kg',       280,  'Sénégal',        'Dakar',       'baisse', -2.1),
('aliment', 'Soja tourteau',               'par kg',       420,  'Sénégal',        'Dakar',       'hausse',  5.5),

-- ── Médicaments & Vaccins (Sénégal) ───────────────────────────
('medicament', 'Vaccin Newcastle 100 doses','par boîte',  3500,  'Sénégal',        'Dakar',       'stable',  0.5),
('medicament', 'Vaccin Gumboro 100 doses',  'par boîte',  4200,  'Sénégal',        'Dakar',       'hausse',  2.3),
('medicament', 'Antibiotique Tétracycline', 'par 500g',   8500,  'Sénégal',        'Dakar',       'stable',  0.0),
('medicament', 'Vitamines & Électrolytes',  'par kg',     6500,  'Sénégal',        'Dakar',       'baisse', -1.8),
('medicament', 'Désinfectant Virkon',       'par kg',    12000,  'Sénégal',        'Dakar',       'hausse',  3.2);

-- Vérification
SELECT pays, COUNT(*) as nb FROM prix_marche GROUP BY pays ORDER BY pays;
