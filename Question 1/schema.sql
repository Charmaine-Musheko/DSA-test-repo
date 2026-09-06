/*
===============================================================================
 EDUOSK / LIBRARY SERVICE DATABASE
===============================================================================

This database belongs to the Ballerina Library Service.

Django should NOT insert/update/delete these tables directly.

The Ballerina REST API is the owner of this data and provides the business
rules controlling assets, lending, booking, maintenance, components, etc.
===============================================================================
*/

BEGIN;


-- ============================================================================
-- INSTITUTIONS
-- ============================================================================

CREATE TABLE institutions (
    name VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- INSTITUTION SITES
-- ============================================================================

CREATE TABLE institution_sites (
    institution_name VARCHAR(255) NOT NULL,
    site VARCHAR(255) NOT NULL,

    PRIMARY KEY (institution_name, site),

    CONSTRAINT fk_site_institution
        FOREIGN KEY (institution_name)
        REFERENCES institutions(name)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


-- ============================================================================
-- ASSETS
-- ============================================================================

CREATE TABLE assets (
    asset_tag VARCHAR(100) PRIMARY KEY,

    name VARCHAR(255) NOT NULL,

    description TEXT NOT NULL DEFAULT '',

    institution_name VARCHAR(255) NOT NULL,

    site VARCHAR(255) NOT NULL,

    date_acquired DATE NOT NULL,

    status VARCHAR(40) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,


    /*
     * Assets may only belong to sites which actually belong to the selected
     * institution.
     */
    CONSTRAINT fk_asset_site
        FOREIGN KEY (institution_name, site)
        REFERENCES institution_sites(institution_name, site)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,


    /*
     * These values match AssetStatus in types.bal.
     */
    CONSTRAINT chk_asset_status
        CHECK (
            status IN (
                'AVAILABLE',
                'LOANED_OUT',
                'OCCUPIED',
                'UNDER_MAINTENANCE',
                'DISPOSED'
            )
        )
);


-- ============================================================================
-- COMPONENTS
-- ============================================================================

CREATE TABLE components (
    asset_tag VARCHAR(100) NOT NULL,

    comp_id VARCHAR(100) NOT NULL,

    name VARCHAR(255) NOT NULL,

    description TEXT NOT NULL DEFAULT '',

    PRIMARY KEY (asset_tag, comp_id),

    CONSTRAINT fk_component_asset
        FOREIGN KEY (asset_tag)
        REFERENCES assets(asset_tag)
        ON DELETE CASCADE
);


-- ============================================================================
-- SCHEDULES
-- ============================================================================

CREATE TABLE schedules (
    asset_tag VARCHAR(100) NOT NULL,

    schedule_id VARCHAR(100) NOT NULL,

    schedule_type VARCHAR(50) NOT NULL,

    due_date DATE NOT NULL,

    description TEXT NOT NULL DEFAULT '',

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    PRIMARY KEY (asset_tag, schedule_id),

    CONSTRAINT fk_schedule_asset
        FOREIGN KEY (asset_tag)
        REFERENCES assets(asset_tag)
        ON DELETE CASCADE,

    CONSTRAINT chk_schedule_status
        CHECK (
            status IN (
                'PENDING',
                'COMPLETED',
                'CANCELLED'
            )
        )
);


-- ============================================================================
-- WORK ORDERS
-- ============================================================================

CREATE TABLE work_orders (
    asset_tag VARCHAR(100) NOT NULL,

    order_id VARCHAR(100) NOT NULL,

    status VARCHAR(30) NOT NULL,

    description TEXT NOT NULL,

    PRIMARY KEY (asset_tag, order_id),

    CONSTRAINT fk_workorder_asset
        FOREIGN KEY (asset_tag)
        REFERENCES assets(asset_tag)
        ON DELETE CASCADE,

    CONSTRAINT chk_workorder_status
        CHECK (
            status IN (
                'OPEN',
                'IN_PROGRESS',
                'CLOSED'
            )
        )
);


-- ============================================================================
-- WORK ORDER TASKS
-- ============================================================================

CREATE TABLE work_tasks (
    asset_tag VARCHAR(100) NOT NULL,

    order_id VARCHAR(100) NOT NULL,

    task_id VARCHAR(100) NOT NULL,

    description TEXT NOT NULL,

    completed BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (asset_tag, order_id, task_id),

    CONSTRAINT fk_task_workorder
        FOREIGN KEY (asset_tag, order_id)
        REFERENCES work_orders(asset_tag, order_id)
        ON DELETE CASCADE
);


-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_assets_institution
ON assets(institution_name);


CREATE INDEX idx_assets_institution_site
ON assets(institution_name, site);


CREATE INDEX idx_assets_status
ON assets(status);


CREATE INDEX idx_schedules_due
ON schedules(due_date);


CREATE INDEX idx_schedules_overdue
ON schedules(status, due_date);


COMMIT;


