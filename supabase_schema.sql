-- =====================================================
-- Schema Supabase pour App Devis Carrelage
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Table USERS
-- =====================================================
CREATE TABLE users (
    uid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    entreprise VARCHAR(200) NOT NULL,
    telephone VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index sur telephone pour recherche rapide
CREATE INDEX idx_users_telephone ON users(telephone);

-- =====================================================
-- Table DESIGNATIONS
-- =====================================================
CREATE TABLE designations (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(200) UNIQUE NOT NULL,
    surface_par_carton NUMERIC(5,2) NOT NULL CHECK (surface_par_carton > 0),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index sur nom pour recherche
CREATE INDEX idx_designations_nom ON designations(nom);

-- =====================================================
-- Table QUOTES
-- =====================================================
CREATE TABLE quotes (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    total_cartons INTEGER DEFAULT 0 CHECK (total_cartons >= 0)
);

-- Index sur user_id pour récupérer les devis d'un utilisateur
CREATE INDEX idx_quotes_user_id ON quotes(user_id);
-- Index sur created_at pour tri chronologique
CREATE INDEX idx_quotes_created_at ON quotes(created_at DESC);

-- =====================================================
-- Table ROOMS
-- =====================================================
CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    quote_id INTEGER NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    nom VARCHAR(100) NOT NULL,
    superficie NUMERIC(8,2) NOT NULL CHECK (superficie > 0),
    designation_id INTEGER NOT NULL REFERENCES designations(id),
    surface_par_carton NUMERIC(5,2) NOT NULL CHECK (surface_par_carton > 0),
    cartons INTEGER NOT NULL CHECK (cartons > 0),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index sur quote_id pour récupérer les pièces d'un devis
CREATE INDEX idx_rooms_quote_id ON rooms(quote_id);
-- Index sur designation_id pour stats
CREATE INDEX idx_rooms_designation_id ON rooms(designation_id);

-- =====================================================
-- RLS (Row Level Security) - Optionnel
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Policy: utilisateur peut voir/modifier ses propres données
CREATE POLICY "Users can view own data" ON users
    FOR ALL USING (auth.uid() = uid);

CREATE POLICY "Users can view own quotes" ON quotes
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view rooms of own quotes" ON rooms
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM quotes 
            WHERE quotes.id = rooms.quote_id 
            AND quotes.user_id = auth.uid()
        )
    );

-- Designations en lecture pour tous
CREATE POLICY "Everyone can view designations" ON designations
    FOR SELECT USING (true);

-- =====================================================
-- Fonction trigger pour mise à jour total_cartons
-- =====================================================
CREATE OR REPLACE FUNCTION update_quote_total_cartons()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE quotes 
    SET total_cartons = (
        SELECT COALESCE(SUM(cartons), 0)
        FROM rooms 
        WHERE quote_id = COALESCE(NEW.quote_id, OLD.quote_id)
    )
    WHERE id = COALESCE(NEW.quote_id, OLD.quote_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Triggers sur table rooms
CREATE TRIGGER trigger_update_total_cartons_insert
    AFTER INSERT ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_quote_total_cartons();

CREATE TRIGGER trigger_update_total_cartons_update
    AFTER UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_quote_total_cartons();

CREATE TRIGGER trigger_update_total_cartons_delete
    AFTER DELETE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_quote_total_cartons();

-- =====================================================
-- Données d'exemple - DESIGNATIONS
-- =====================================================
INSERT INTO designations (nom, surface_par_carton) VALUES
('Carrelage 30x30 cm - Blanc', 1.44),
('Carrelage 60x60 cm - Gris', 2.16),
('Carrelage 45x45 cm - Beige', 1.82);

-- =====================================================
-- Vue utilitaire pour les devis complets
-- =====================================================
CREATE VIEW quotes_with_details AS
SELECT 
    q.id as quote_id,
    q.created_at as quote_date,
    q.total_cartons,
    u.nom,
    u.prenom,
    u.entreprise,
    u.telephone,
    COUNT(r.id) as nb_pieces
FROM quotes q
JOIN users u ON q.user_id = u.uid
LEFT JOIN rooms r ON q.id = r.quote_id
GROUP BY q.id, u.uid;