-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- A function to automatically update the 'updated_at' timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--
-- Main table to store different types of reports.
--
CREATE TABLE animal_biome_production.report_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    display_name TEXT,
    opening_text TEXT,
    display_bacteria_overview BOOLEAN NOT NULL DEFAULT false,

    -- Foreign keys to specific categories for display purposes.
    -- These are nullable and set to NULL if the referenced category is deleted.
    displayed_bacteria_category_id UUID,
    unidentified_bacteria_category_id UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON animal_biome_production.report_types
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON COLUMN animal_biome_production.report_types.name IS 'e.g., ''Embark - Dog'', ''AB- Cat'', ''Wild horse study''';
COMMENT ON COLUMN animal_biome_production.report_types.display_bacteria_overview IS 'Controls visibility of the bacteria overview in the report summary.';


--
-- Stores bacteria categories, each associated with a single report type.
--
CREATE TABLE animal_biome_production.bacteria_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type_id UUID NOT NULL REFERENCES animal_biome_production.report_types(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    description TEXT,
    display_if_null BOOLEAN NOT NULL DEFAULT false,
    display_in_summary_overview BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensures a category name is unique within the scope of its report type
    UNIQUE(report_type_id, name)
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON animal_biome_production.bacteria_categories
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE animal_biome_production.bacteria_categories IS 'Each category is linked to one Report Type. Deleting a Report Type is blocked if categories are linked.';


--
-- Stores taxonomic information.
--
CREATE TABLE animal_biome_production.taxons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kingdom TEXT,
    phylum TEXT,
    class TEXT,
    "order" TEXT,
    family TEXT,
    genus TEXT,
    species TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensures uniqueness for a given taxonomic classification
    UNIQUE(kingdom, phylum, class, "order", family, genus, species)
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON animal_biome_production.taxons
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE animal_biome_production.taxons IS 'Stores hierarchical taxonomic information for bacteria.';


--
-- Stores custom display names for bacteria, linked to report types and taxons.
--
CREATE TABLE animal_biome_production.bacteria_display_names (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type_id UUID NOT NULL REFERENCES animal_biome_production.report_types(id) ON DELETE RESTRICT,
    taxon_id UUID NOT NULL REFERENCES animal_biome_production.taxons(id) ON DELETE RESTRICT,
    display_name TEXT NOT NULL,
    min_value TEXT, -- Stored as TEXT as per requirements (can be string or float)
    max_value TEXT, -- Stored as TEXT as per requirements (can be string or float)
    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensures a unique display name entry for a given report type and taxon
    UNIQUE(report_type_id, taxon_id)
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON animal_biome_production.bacteria_display_names
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE animal_biome_production.bacteria_display_names IS 'Custom display names for bacteria, specific to report types and taxons.';


--
-- Join table for many-to-many relationship between bacteria_display_names and bacteria_categories.
--
CREATE TABLE animal_biome_production.bacteria_display_name_categories (
    bacteria_display_name_id UUID NOT NULL REFERENCES animal_biome_production.bacteria_display_names(id) ON DELETE CASCADE,
    bacteria_category_id UUID NOT NULL REFERENCES animal_biome_production.bacteria_categories(id) ON DELETE CASCADE,

    PRIMARY KEY (bacteria_display_name_id, bacteria_category_id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON animal_biome_production.bacteria_display_name_categories
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE animal_biome_production.bacteria_display_name_categories IS 'Links custom bacteria display names to their associated categories.';


--
-- Stores display names, each associated with a single report type.
--
CREATE TABLE animal_biome_production.display_names (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type_id UUID NOT NULL REFERENCES animal_biome_production.report_types(id) ON DELETE RESTRICT,
    display_name TEXT NOT NULL,

    created_at TIMESTAMTZO NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensures a display name is unique within the scope of its report type
    UNIQUE(report_type_id, display_name)
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON animal_biome_production.display_names
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE animal_biome_production.display_names IS 'Each display name is linked to one Report Type. Deleting a Report Type is blocked if display names are linked.';


--
-- Add the foreign key constraints from report_types to bacteria_categories
-- This is done after the bacteria_categories table is created to avoid circular dependencies.
--
ALTER TABLE animal_biome_production.report_types
ADD CONSTRAINT fk_displayed_bacteria_category
FOREIGN KEY (displayed_bacteria_category_id)
REFERENCES animal_biome_production.bacteria_categories(id)
ON DELETE SET NULL;

ALTER TABLE animal_biome_production.report_types
ADD CONSTRAINT fk_unidentified_bacteria_category
FOREIGN KEY (unidentified_bacteria_category_id)
REFERENCES animal_biome_production.bacteria_categories(id)
ON DELETE SET NULL;
