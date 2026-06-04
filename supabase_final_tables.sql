-- ================================================================
-- TABLES FINALES — KAS (Kewere Aissa Smart)
-- Coller et exécuter EN ENTIER dans Supabase → SQL Editor
-- ================================================================

-- ── transactions (écran Finances) ────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    entreprise_id  UUID         NOT NULL,
    ferme_id       UUID,
    cycle_id       UUID,
    libelle        VARCHAR(255) NOT NULL,
    montant        DECIMAL(12,2) NOT NULL,
    type           VARCHAR(30)  NOT NULL DEFAULT 'depense',  -- revenu | depense
    categorie      VARCHAR(100) NOT NULL DEFAULT 'autre',
    note           TEXT,
    created_at     TIMESTAMP    DEFAULT NOW(),
    updated_at     TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_transactions_entreprise
    ON transactions (entreprise_id, type, created_at DESC);

-- ── alertes (dashboard) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS alertes (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ferme_id       UUID         NOT NULL,
    cycle_id       UUID,
    type           VARCHAR(100) NOT NULL,
    message        TEXT         NOT NULL,
    niveau         VARCHAR(20)  DEFAULT 'info',  -- info | warning | critique
    lu             BOOLEAN      DEFAULT false,
    date_creation  TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_alertes_ferme_id
    ON alertes (ferme_id, niveau, date_creation DESC);

-- ── plans (abonnements) ───────────────────────────────────────
-- La table existe déjà sans contrainte UNIQUE — on utilise UPDATE + INSERT
ALTER TABLE plans ADD COLUMN IF NOT EXISTS description    TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS prix_annuel    DECIMAL(10,2) DEFAULT 0;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS nb_fermes_max  INTEGER DEFAULT 1;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS nb_users_max   INTEGER DEFAULT 3;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS fonctionnalites TEXT[];
ALTER TABLE plans ADD COLUMN IF NOT EXISTS created_at     TIMESTAMP DEFAULT NOW();

UPDATE plans SET description='Plan gratuit — 1 ferme, 3 utilisateurs',
    prix_mensuel=0, nb_fermes_max=1, nb_users_max=3 WHERE nom='gratuit';
UPDATE plans SET description='Plan Pro — 5 fermes, 10 utilisateurs',
    prix_mensuel=15000, nb_fermes_max=5, nb_users_max=10 WHERE nom='pro';
UPDATE plans SET description='Plan Entreprise — illimité',
    prix_mensuel=50000, nb_fermes_max=99, nb_users_max=99 WHERE nom='enterprise';

INSERT INTO plans (nom, description, prix_mensuel, nb_fermes_max, nb_users_max, actif)
    SELECT 'gratuit','Plan gratuit — 1 ferme, 3 utilisateurs',0,1,3,true
    WHERE NOT EXISTS (SELECT 1 FROM plans WHERE nom='gratuit');
INSERT INTO plans (nom, description, prix_mensuel, nb_fermes_max, nb_users_max, actif)
    SELECT 'pro','Plan Pro — 5 fermes, 10 utilisateurs',15000,5,10,true
    WHERE NOT EXISTS (SELECT 1 FROM plans WHERE nom='pro');
INSERT INTO plans (nom, description, prix_mensuel, nb_fermes_max, nb_users_max, actif)
    SELECT 'enterprise','Plan Entreprise — illimité',50000,99,99,true
    WHERE NOT EXISTS (SELECT 1 FROM plans WHERE nom='enterprise');

-- ── vaccinations (santé) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS vaccinations (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_id    UUID         NOT NULL,
    vaccin      VARCHAR(150) NOT NULL,
    maladie     VARCHAR(150) NOT NULL,
    age_jours   INTEGER      NOT NULL,
    voie        VARCHAR(50)  DEFAULT 'eau',
    lot         VARCHAR(100),
    dose        VARCHAR(100),
    notes       TEXT,
    created_at  TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_vaccinations_cycle
    ON vaccinations (cycle_id, age_jours);

-- ── traitements (santé) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS traitements (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_id     UUID         NOT NULL,
    produit      VARCHAR(150) NOT NULL,
    motif        VARCHAR(200) NOT NULL,
    age_jours    INTEGER      NOT NULL,
    duree_jours  INTEGER      DEFAULT 3,
    posologie    VARCHAR(200),
    notes        TEXT,
    created_at   TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_traitements_cycle
    ON traitements (cycle_id, age_jours);

-- ── mortalite_causes (santé) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS mortalite_causes (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_id        UUID         NOT NULL,
    date_releve     DATE         NOT NULL,
    nombre          INTEGER      NOT NULL DEFAULT 0,
    cause           VARCHAR(200) NOT NULL,
    symptomes       TEXT,
    mesures_prises  TEXT,
    created_at      TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_mortalite_causes_cycle
    ON mortalite_causes (cycle_id, date_releve DESC);

-- ── conges (RH) ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conges (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    entreprise_id UUID         NOT NULL,
    employe_id    UUID         NOT NULL,
    type          VARCHAR(50)  DEFAULT 'conge',
    date_debut    DATE         NOT NULL,
    date_fin      DATE         NOT NULL,
    motif         TEXT,
    statut        VARCHAR(30)  DEFAULT 'approuve',
    approuve_par  UUID,
    created_at    TIMESTAMP    DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_conges_entreprise
    ON conges (entreprise_id, statut);
CREATE INDEX IF NOT EXISTS idx_conges_employe
    ON conges (employe_id, date_debut DESC);

-- ── role_permissions (accès & rôles) ─────────────────────────
CREATE TABLE IF NOT EXISTS role_permissions (
    id            SERIAL       PRIMARY KEY,
    entreprise_id UUID         NOT NULL,
    role_id       INTEGER      NOT NULL,
    permission    VARCHAR(100) NOT NULL,
    valeur        BOOLEAN      DEFAULT true,
    UNIQUE (entreprise_id, role_id, permission)
);
CREATE INDEX IF NOT EXISTS idx_role_permissions_entreprise
    ON role_permissions (entreprise_id, role_id);

-- ── vue_tableau_bord_fermes (dashboard) ───────────────────────
CREATE OR REPLACE VIEW vue_tableau_bord_fermes AS
SELECT
    e.nom                                               AS entreprise,
    f.id                                                AS ferme_id,
    f.nom                                               AS ferme,
    f.localisation,
    COUNT(DISTINCT emp.id)                              AS nb_employes,
    COUNT(DISTINCT c.id) FILTER (WHERE c.statut = 'actif') AS cycles_actifs,
    COUNT(DISTINCT c.id)                                AS cycles_total,
    COALESCE(SUM(dj.mortalite), 0)                      AS mortalite_totale,
    MAX(dj.date_releve)                                 AS derniere_saisie
FROM fermes f
JOIN entreprises e ON e.id = f.entreprise_id
LEFT JOIN employes emp ON emp.ferme_id = f.id
LEFT JOIN cycles c ON c.ferme_id = f.id
LEFT JOIN donnees_journalieres dj ON dj.cycle_id = c.id
GROUP BY e.nom, f.id, f.nom, f.localisation;

-- ── vue_abonnements_paiements (dashboard) ─────────────────────
CREATE OR REPLACE VIEW vue_abonnements_paiements AS
SELECT
    a.id,
    a.entreprise_id,
    e.nom                   AS entreprise_nom,
    a.plan,
    a.statut,
    a.prix,
    a.date_debut            AS date_paiement,
    a.date_fin,
    a.created_at
FROM abonnements a
JOIN entreprises e ON e.id = a.entreprise_id
ORDER BY a.created_at DESC;

-- ── Triggers updated_at pour transactions ─────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_transactions_updated ON transactions;
CREATE TRIGGER trg_transactions_updated
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Vérification finale ───────────────────────────────────────
SELECT table_name, COUNT(*) as nb_lignes FROM (
    SELECT 'transactions'     AS table_name FROM transactions     UNION ALL
    SELECT 'alertes'          FROM alertes                        UNION ALL
    SELECT 'plans'            FROM plans                          UNION ALL
    SELECT 'vaccinations'     FROM vaccinations                   UNION ALL
    SELECT 'traitements'      FROM traitements                    UNION ALL
    SELECT 'mortalite_causes' FROM mortalite_causes               UNION ALL
    SELECT 'conges'           FROM conges                         UNION ALL
    SELECT 'role_permissions' FROM role_permissions
) t GROUP BY table_name ORDER BY table_name;
