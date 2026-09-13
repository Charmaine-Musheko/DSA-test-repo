-- ============================================================================
-- RENTAL SERVICE DATABASE SCHEMA
-- ============================================================================

SET search_path TO rental, public;


-- ============================================================================
-- USERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (

    id BIGSERIAL PRIMARY KEY,

    user_id VARCHAR(30) UNIQUE,

    name VARCHAR(150) NOT NULL,

    email VARCHAR(255) NOT NULL UNIQUE,

    role VARCHAR(20) NOT NULL
        CHECK (
            role IN ('HOST', 'GUEST')
        ),

    region VARCHAR(100)
        NOT NULL
        DEFAULT ''
);


-- ============================================================================
-- PROPERTIES
-- ============================================================================

CREATE TABLE IF NOT EXISTS properties (

    id BIGSERIAL PRIMARY KEY,

    property_id VARCHAR(30) UNIQUE,

    host_id VARCHAR(30) NOT NULL,

    name VARCHAR(200) NOT NULL,

    location VARCHAR(200) NOT NULL,

    region VARCHAR(100) NOT NULL,

    property_type VARCHAR(100) NOT NULL,

    price_per_night NUMERIC(12, 2)
        NOT NULL
        CHECK (
            price_per_night > 0
        ),

    status VARCHAR(30)
        NOT NULL
        DEFAULT 'AVAILABLE'
        CHECK (
            status IN (
                'AVAILABLE',
                'BOOKED',
                'UNDER_MAINTENANCE',
                'DELISTED'
            )
        ),

    description TEXT
        NOT NULL
        DEFAULT '',

    CONSTRAINT fk_property_host
        FOREIGN KEY (host_id)
        REFERENCES users(user_id)
);


-- ============================================================================
-- CART ITEMS
-- ============================================================================

CREATE TABLE IF NOT EXISTS cart_items (

    id BIGSERIAL PRIMARY KEY,

    cart_id VARCHAR(30) UNIQUE,

    guest_id VARCHAR(30) NOT NULL,

    property_id VARCHAR(30) NOT NULL,

    check_in DATE NOT NULL,

    check_out DATE NOT NULL,

    created_at TIMESTAMPTZ
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cart_guest
        FOREIGN KEY (guest_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_cart_property
        FOREIGN KEY (property_id)
        REFERENCES properties(property_id),

    CONSTRAINT check_cart_dates
        CHECK (
            check_out > check_in
        )
);


-- ============================================================================
-- ACTIVE BOOKINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS bookings (

    id BIGSERIAL PRIMARY KEY,

    booking_id VARCHAR(30) UNIQUE,

    property_id VARCHAR(30) NOT NULL,

    guest_id VARCHAR(30) NOT NULL,

    check_in DATE NOT NULL,

    check_out DATE NOT NULL,

    total_cost NUMERIC(12, 2)
        NOT NULL
        CHECK (
            total_cost >= 0
        ),

    status VARCHAR(30)
        NOT NULL
        DEFAULT 'CONFIRMED',

    created_at TIMESTAMPTZ
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_property
        FOREIGN KEY (property_id)
        REFERENCES properties(property_id),

    CONSTRAINT fk_booking_guest
        FOREIGN KEY (guest_id)
        REFERENCES users(user_id),

    CONSTRAINT check_booking_dates
        CHECK (
            check_out > check_in
        )
);


-- ============================================================================
-- REMOVED BOOKING HISTORY
-- ============================================================================
-- //
-- // Deliberately NO foreign keys here.
-- //
-- // The history should survive even if the active property or user is later
-- // removed.
-- // ============================================================================

CREATE TABLE IF NOT EXISTS removed_bookings (

    id BIGSERIAL PRIMARY KEY,

    booking_id VARCHAR(30)
        UNIQUE
        NOT NULL,

    property_id VARCHAR(30)
        NOT NULL,

    guest_id VARCHAR(30)
        NOT NULL,

    check_in DATE
        NOT NULL,

    check_out DATE
        NOT NULL,

    total_cost NUMERIC(12, 2)
        NOT NULL,

    status VARCHAR(30)
        NOT NULL
        DEFAULT 'CANCELLED',

    reason TEXT
        NOT NULL
        DEFAULT '',

    removed_at TIMESTAMPTZ
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_role
    ON users(role);


CREATE INDEX IF NOT EXISTS idx_properties_host
    ON properties(host_id);


CREATE INDEX IF NOT EXISTS idx_properties_region
    ON properties(region);


CREATE INDEX IF NOT EXISTS idx_properties_status
    ON properties(status);


CREATE INDEX IF NOT EXISTS idx_cart_guest
    ON cart_items(guest_id);


CREATE INDEX IF NOT EXISTS idx_cart_property
    ON cart_items(property_id);


CREATE INDEX IF NOT EXISTS idx_bookings_property
    ON bookings(property_id);


CREATE INDEX IF NOT EXISTS idx_bookings_guest
    ON bookings(guest_id);


CREATE INDEX IF NOT EXISTS idx_booking_dates
    ON bookings(property_id, check_in, check_out);


CREATE INDEX IF NOT EXISTS idx_removed_booking_guest
    ON removed_bookings(guest_id);


CREATE INDEX IF NOT EXISTS idx_removed_booking_property
    ON removed_bookings(property_id);

