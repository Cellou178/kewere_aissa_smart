-- ============================================================
-- TABLES MANQUANTES — KAS (Kewere Aissa Smart)
-- Exécuter dans l'éditeur SQL Supabase
-- ============================================================

-- ── actualites_marche ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS actualites_marche (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    titre       VARCHAR(200) NOT NULL,
    description TEXT,
    categorie   VARCHAR(50)  DEFAULT 'Info',
    urgent      BOOLEAN      DEFAULT false,
    icon        VARCHAR(10)  DEFAULT '📰',
    actif       BOOLEAN      DEFAULT true,
    created_at  TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_actualites_marche_actif
    ON actualites_marche (actif, created_at DESC);

-- ── prix_marche ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prix_marche (
    id           SERIAL       PRIMARY KEY,
    categorie    VARCHAR(50)  NOT NULL,
    produit      VARCHAR(150) NOT NULL,
    unite        VARCHAR(50)  DEFAULT 'unité',
    prix         DECIMAL(10,2) NOT NULL,
    pays         VARCHAR(100) DEFAULT 'Sénégal',
    ville        VARCHAR(100) DEFAULT 'Dakar',
    tendance     VARCHAR(20)  DEFAULT 'stable',
    variation    DECIMAL(5,2) DEFAULT 0,
    derniere_maj TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_prix_marche_categorie
    ON prix_marche (categorie);

-- ── batiments ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batiments (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ferme_id            UUID        NOT NULL REFERENCES fermes(id) ON DELETE CASCADE,
    nom                 VARCHAR(150) NOT NULL,
    capacite            INTEGER     DEFAULT 0,
    type                VARCHAR(50) DEFAULT 'poulailler',
    statut              VARCHAR(30) DEFAULT 'actif',
    surface_m2          DECIMAL(8,2),
    date_construction   DATE,
    dernier_nettoyage   DATE,
    notes               TEXT,
    created_at          TIMESTAMP   DEFAULT NOW(),
    updated_at          TIMESTAMP   DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_batiments_ferme_id
    ON batiments (ferme_id);

-- ── taches ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS taches (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    entreprise_id  UUID        NOT NULL,
    titre          VARCHAR(200) NOT NULL,
    description    TEXT,
    date_echeance  DATE,
    type           VARCHAR(50) DEFAULT 'autre',
    priorite       VARCHAR(20) DEFAULT 'normale',
    statut         VARCHAR(30) DEFAULT 'en_cours',
    cycle_id       UUID,
    ferme_id       UUID,
    assignee_id    UUID,
    created_by     UUID,
    created_at     TIMESTAMP   DEFAULT NOW(),
    updated_at     TIMESTAMP   DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_taches_entreprise_id
    ON taches (entreprise_id, statut);
CREATE INDEX IF NOT EXISTS idx_taches_date_echeance
    ON taches (date_echeance);

-- ── produits_vitrine ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS produits_vitrine (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    entreprise_id  UUID        NOT NULL,
    nom            VARCHAR(150) NOT NULL,
    categorie      VARCHAR(50) DEFAULT 'Volaille',
    prix           DECIMAL(10,2) NOT NULL,
    unite          VARCHAR(50) DEFAULT 'par tête',
    quantite       DECIMAL(10,2) DEFAULT 0,
    description    TEXT,
    disponible     BOOLEAN     DEFAULT true,
    icon           VARCHAR(10) DEFAULT '🐔',
    created_at     TIMESTAMP   DEFAULT NOW(),
    updated_at     TIMESTAMP   DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_produits_vitrine_entreprise
    ON produits_vitrine (entreprise_id, disponible);

-- ── parametres ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parametres (
    id         SERIAL      PRIMARY KEY,
    cle        VARCHAR(100) UNIQUE NOT NULL,
    valeur     TEXT        NOT NULL,
    type       VARCHAR(30) DEFAULT 'string',
    updated_at TIMESTAMP   DEFAULT NOW()
);

-- ── Triggers updated_at ──────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_batiments_updated
    BEFORE UPDATE ON batiments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_taches_updated
    BEFORE UPDATE ON taches
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_produits_vitrine_updated
    BEFORE UPDATE ON produits_vitrine
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Seed: Prix du marché (données réalistes Afrique de l'Ouest) ──
INSERT INTO prix_marche (categorie, produit, unite, prix, pays, ville, tendance, variation) VALUES
  ('poulet',  'Poulet vif',                   'par kg',     2800,  'Sénégal', 'Dakar',       'hausse',  5.2),
  ('poulet',  'Poulet vif',                   'par kg',     2650,  'Sénégal', 'Thiès',       'stable',  0.5),
  ('poulet',  'Poulet vif',                   'par kg',     2700,  'Sénégal', 'Mbour',       'hausse',  3.1),
  ('poulet',  'Poulet vif',                   'par kg',     3200,  'Côte d''Ivoire', 'Abidjan', 'baisse', -2.3),
  ('poulet',  'Poulet vif',                   'par kg',     2400,  'Mali',    'Bamako',      'stable',  1.0),
  ('aliment', 'Sac aliment démarrage 50kg',   'par sac',   18500,  'Sénégal', 'Dakar',       'hausse',  8.3),
  ('aliment', 'Sac aliment croissance 50kg',  'par sac',   17000,  'Sénégal', 'Dakar',       'hausse',  6.1),
  ('aliment', 'Sac aliment finition 50kg',    'par sac',   16500,  'Sénégal', 'Dakar',       'stable',  0.8),
  ('aliment', 'Poussin Cobb 500',             'par poussin', 650,  'Sénégal', 'Dakar',       'hausse',  4.2),
  ('aliment', 'Poussin Ross 308',             'par poussin', 700,  'Sénégal', 'Dakar',       'hausse',  3.8),
  ('aliment', 'Maïs grain',                  'par kg',       280,  'Sénégal', 'Dakar',       'baisse', -2.1),
  ('aliment', 'Soja tourteau',               'par kg',       420,  'Sénégal', 'Dakar',       'hausse',  5.5),
  ('medicament', 'Vaccin Newcastle 100 doses','par boîte',  3500,  'Sénégal', 'Dakar',       'stable',  0.5),
  ('medicament', 'Vaccin Gumboro 100 doses',  'par boîte',  4200,  'Sénégal', 'Dakar',       'hausse',  2.3),
  ('medicament', 'Antibiotique Tétracycline', 'par 500g',   8500,  'Sénégal', 'Dakar',       'stable',  0.0),
  ('medicament', 'Vitamines & Électrolytes',  'par kg',     6500,  'Sénégal', 'Dakar',       'baisse', -1.8),
  ('medicament', 'Désinfectant Virkon',       'par kg',    12000,  'Sénégal', 'Dakar',       'hausse',  3.2)
ON CONFLICT DO NOTHING;

-- ── Seed: Actualités du marché ────────────────────────────────
INSERT INTO actualites_marche (titre, description, categorie, urgent, icon) VALUES
  ('Hausse des prix des poussins',
   'Les couvoirs signalent une augmentation de 4-6% sur le prix des poussins d''un jour.',
   'Prix', true, '🐥'),
  ('Nouveau programme de subvention avicole',
   'Le gouvernement sénégalais annonce un programme de soutien aux éleveurs.',
   'Politique', false, '🏛️'),
  ('Alerte sanitaire: Grippe aviaire',
   'Des cas de grippe aviaire H5N1 détectés dans la région de Kayes. Renforcer la biosécurité.',
   'Santé', true, '⚠️'),
  ('Foire avicole de Dakar - Juin 2026',
   'La grande foire avicole annuelle se tiendra du 15 au 18 juin 2026.',
   'Événement', false, '🎪'),
  ('Prix du maïs en baisse en Afrique de l''Ouest',
   'La bonne saison des pluies 2025 a permis une récolte abondante, faisant baisser le maïs.',
   'Prix', false, '🌽')
ON CONFLICT DO NOTHING;

-- ── Seed: Paramètres système ───────────────────────────────────
INSERT INTO parametres (cle, valeur, type) VALUES
  ('msg_suspension_titre',  'Compte suspendu',            'string'),
  ('msg_suspension_corps',  'Votre compte est suspendu. Contactez l''administration.', 'string'),
  ('msg_resiliation_titre', 'Abonnement résilié',         'string'),
  ('msg_resiliation_corps', 'Votre abonnement a été résilié. Contactez l''administration.', 'string'),
  ('duree_cycle_standard',  '45',  'int'),
  ('temp_ideale_min',       '25',  'float'),
  ('temp_ideale_max',       '32',  'float'),
  ('taux_mortalite_max',    '3.0', 'float')
ON CONFLICT (cle) DO NOTHING;
