```mermaid
erDiagram
    report_types {
        UUID id PK "Primary Key"
        TEXT name "Unique name for the report type"
        TEXT display_name "Display name for the report"
        TEXT opening_text "Opening text for the report"
        BOOLEAN display_bacteria_overview "Toggle for overview display"
        UUID displayed_bacteria_category_id FK "Optional: Specific category to display"
        UUID unidentified_bacteria_category_id FK "Optional: Category for unidentified bacteria"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    bacteria_categories {
        UUID id PK "Primary Key"
        UUID report_type_id FK "Associated report type"
        TEXT name "Name of the bacteria category"
        TEXT description "Description of the category"
        BOOLEAN display_if_null "Display category even if results are null"
        BOOLEAN display_in_summary_overview "Include category in report summary overview"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    taxons {
        UUID id PK "Primary Key"
        TEXT kingdom
        TEXT phylum
        TEXT class
        TEXT order
        TEXT family
        TEXT genus
        TEXT species
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    bacteria_display_names {
        UUID id PK "Primary Key"
        UUID report_type_id FK "Associated report type"
        UUID taxon_id FK "Associated taxon"
        TEXT display_name "Custom display name for bacterium"
        TEXT min_value "Min value (string or float)"
        TEXT max_value "Max value (string or float)"
        TEXT description "Internal description or tooltip copy"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    bacteria_display_name_categories {
        UUID bacteria_display_name_id PK,FK "Foreign key to bacteria_display_names"
        UUID bacteria_category_id PK,FK "Foreign key to bacteria_categories"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    report_types ||--o{ bacteria_categories : "has many"
    report_types ||--o{ display_names : "has many"
    report_types }o--|| bacteria_categories : "uses as 'Displayed Category'"
    report_types }o--|| bacteria_categories : "uses as 'Unidentified Category'"
    report_types ||--o{ bacteria_display_names : "has many"
    taxons ||--o{ bacteria_display_names : "has many"
    bacteria_display_names }o--o{ bacteria_display_name_categories : "has many"
    bacteria_categories }o--o{ bacteria_display_name_categories : "has many"

```

The `report_types` table has two optional foreign keys, `displayed_bacteria_category_id` and `unidentified_bacteria_category_id`, which both reference the `bacteria_categories` table. This creates a relationship where a report type can, but is not required to, specify particular bacteria categories for special display purposes.

The `bacteria_categories` and `display_names` tables are both directly related to the `report_types` table, with each record in these tables belonging to a single report type. This is enforced by the `report_type_id` foreign key in both tables. The `ON DELETE RESTRICT` clause on these foreign keys prevents a report type from being deleted if it still has associated bacteria categories or display names. This ensures data integrity.

The `taxons` table stores hierarchical taxonomic information.

The `bacteria_display_names` table links `report_types` and `taxons` to provide custom display names, min/max values, and descriptions for bacteria.

The `bacteria_display_name_categories` table is a join table that establishes a many-to-many relationship between `bacteria_display_names` and `bacteria_categories`, allowing a custom bacteria display name to belong to multiple categories.
