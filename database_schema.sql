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
CREATE TABLE report_types (
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
BEFORE UPDATE ON report_types
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON COLUMN report_types.name IS 'e.g., ''Embark - Dog'', ''AB- Cat'', ''Wild horse study''';
COMMENT ON COLUMN report_types.display_bacteria_overview IS 'Controls visibility of the bacteria overview in the report summary.';


--
-- Stores bacteria categories, each associated with a single report type.
--
CREATE TABLE bacteria_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type_id UUID NOT NULL REFERENCES report_types(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensures a category name is unique within the scope of its report type
    UNIQUE(report_type_id, name)
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON bacteria_categories
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE bacteria_categories IS 'Each category is linked to one Report Type. Deleting a Report Type is blocked if categories are linked.';


--
-- Stores display names, each associated with a single report type.
--
CREATE TABLE display_names (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type_id UUID NOT NULL REFERENCES report_types(id) ON DELETE RESTRICT,
    display_name TEXT NOT NULL,

    created_at TIMESTAMTZO NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensures a display name is unique within the scope of its report type
    UNIQUE(report_type_id, display_name)
);

-- Trigger to automatically update the 'updated_at' field on change
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON display_names
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

COMMENT ON TABLE display_names IS 'Each display name is linked to one Report Type. Deleting a Report Type is blocked if display names are linked.';


--
-- Add the foreign key constraints from report_types to bacteria_categories
-- This is done after the bacteria_categories table is created to avoid circular dependencies.
--
ALTER TABLE report_types
ADD CONSTRAINT fk_displayed_bacteria_category
FOREIGN KEY (displayed_bacteria_category_id)
REFERENCES bacteria_categories(id)
ON DELETE SET NULL;

ALTER TABLE report_types
ADD CONSTRAINT fk_unidentified_bacteria_category
FOREIGN KEY (unidentified_bacteria_category_id)
REFERENCES bacteria_categories(id)
ON DELETE SET NULL;
