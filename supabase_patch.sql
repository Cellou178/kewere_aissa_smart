-- ============================================================
-- PATCH SQL — KAS (Kewere Aissa Smart)
-- Exécuter dans l'éditeur SQL Supabase après supabase_missing_tables.sql
-- ============================================================

-- ── 1. Ajouter colonne description à parametres ───────────────
ALTER TABLE parametres ADD COLUMN IF NOT EXISTS description TEXT;

-- Mettre à jour les descriptions des paramètres existants
UPDATE parametres SET description = 'Titre de l''email de suspension'
    WHERE cle = 'msg_suspension_titre';
UPDATE parametres SET description = 'Corps de l''email de suspension'
    WHERE cle = 'msg_suspension_corps';
UPDATE parametres SET description = 'Titre de l''email de résiliation'
    WHERE cle = 'msg_resiliation_titre';
UPDATE parametres SET description = 'Corps de l''email de résiliation'
    WHERE cle = 'msg_resiliation_corps';
UPDATE parametres SET description = 'Durée standard d''un cycle en jours'
    WHERE cle = 'duree_cycle_standard';
UPDATE parametres SET description = 'Température idéale minimale (°C)'
    WHERE cle = 'temp_ideale_min';
UPDATE parametres SET description = 'Température idéale maximale (°C)'
    WHERE cle = 'temp_ideale_max';
UPDATE parametres SET description = 'Taux de mortalité maximum acceptable (%)'
    WHERE cle = 'taux_mortalite_max';

-- Ajouter des paramètres supplémentaires utiles
INSERT INTO parametres (cle, valeur, type, description) VALUES
  ('poids_cible_j42',    '2.5',  'float',  'Poids cible à J42 en kg (standard Cobb 500)'),
  ('ic_cible',           '1.8',  'float',  'Indice de consommation cible'),
  ('homogeneite_min',    '80',   'int',    'Homogénéité minimale acceptable (%)'),
  ('nb_sujets_max',      '20000','int',    'Capacité maximale par bâtiment (sujets)'),
  ('alerte_stock_jours', '7',    'int',    'Alerte stock épuisé dans X jours')
ON CONFLICT (cle) DO UPDATE SET
    description = EXCLUDED.description;

-- ── 2. Table equipements ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS equipements (
    id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ferme_id               UUID        NOT NULL REFERENCES fermes(id) ON DELETE CASCADE,
    batiment_nom           VARCHAR(150),
    nom                    VARCHAR(200) NOT NULL,
    type                   VARCHAR(50)  DEFAULT 'autre',
    etat                   VARCHAR(30)  DEFAULT 'bon',
    derniere_maintenance   DATE,
    prochaine_maintenance  DATE,
    heures_utilisation     INTEGER      DEFAULT 0,
    notes                  TEXT,
    created_at             TIMESTAMP    DEFAULT NOW(),
    updated_at             TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_equipements_ferme_id
    ON equipements (ferme_id);
CREATE INDEX IF NOT EXISTS idx_equipements_etat
    ON equipements (etat);
CREATE TRIGGER trg_equipements_updated
    BEFORE UPDATE ON equipements
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 3. Table commandes_vendeur ────────────────────────────────
-- Schema exact correspondant à vendeur.py _ensure_table()
CREATE TABLE IF NOT EXISTS commandes_vendeur (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    vendeur_id      UUID        NOT NULL,
    vendeur_nom     VARCHAR(150),
    partenaire_id   UUID,
    partenaire_nom  VARCHAR(150),
    produit         VARCHAR(150) NOT NULL,
    quantite        INTEGER     NOT NULL DEFAULT 1,
    notes           TEXT        DEFAULT '',
    statut          VARCHAR(20)  NOT NULL DEFAULT 'en_attente',
    created_at      TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_commandes_vendeur_vendeur
    ON commandes_vendeur (vendeur_id, statut);
CREATE INDEX IF NOT EXISTS idx_commandes_vendeur_partenaire
    ON commandes_vendeur (partenaire_id, statut);

-- ── 4. Colonne statut dans entreprises (si absente) ───────────
ALTER TABLE entreprises ADD COLUMN IF NOT EXISTS statut         VARCHAR(30) DEFAULT 'actif';
ALTER TABLE entreprises ADD COLUMN IF NOT EXISTS motif_sanction TEXT;
ALTER TABLE entreprises ADD COLUMN IF NOT EXISTS date_sanction  TIMESTAMP;

-- ── 5. Colonne description dans parametres trigger ─────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

-- ── Vérification finale ───────────────────────────────────────
-- Lancer ce SELECT pour confirmer que tout est en place :
SELECT 'parametres' as table_name, COUNT(*) as nb_lignes FROM parametres
UNION ALL SELECT 'equipements', COUNT(*) FROM equipements
UNION ALL SELECT 'commandes_vendeur', COUNT(*) FROM commandes_vendeur
UNION ALL SELECT 'taches', COUNT(*) FROM taches
UNION ALL SELECT 'batiments', COUNT(*) FROM batiments
UNION ALL SELECT 'produits_vitrine', COUNT(*) FROM produits_vitrine
UNION ALL SELECT 'actualites_marche', COUNT(*) FROM actualites_marche
UNION ALL SELECT 'prix_marche', COUNT(*) FROM prix_marche;
