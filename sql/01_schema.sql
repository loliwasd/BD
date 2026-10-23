CREATE EXTENSION IF NOT EXISTS citext;
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    email           CITEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    phone           TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT chk_users_phone CHECK (phone IS NULL OR phone ~ '^\+?[0-9]{7,15}$')
);

CREATE TABLE user_profiles (
    user_id         BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    avatar_url      TEXT,
    bio             TEXT,
    company         TEXT,
    timezone        TEXT NOT NULL DEFAULT 'UTC',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_user_profiles_bio CHECK (bio IS NULL OR char_length(bio) <= 500)
);

CREATE TABLE roles (
    id              SMALLSERIAL PRIMARY KEY,
    code            TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    description     TEXT
);

CREATE TABLE user_roles (
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id         SMALLINT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    granted_by      BIGINT REFERENCES users(id) ON DELETE SET NULL,
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE audit_log (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       BIGINT,
    old_value       JSONB,
    new_value       JSONB,
    ip              INET,
    result          TEXT NOT NULL DEFAULT 'success',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_audit_log_result CHECK (result IN ('success', 'failure'))
);

CREATE TABLE locations (
    id              BIGSERIAL PRIMARY KEY,
    parent_id       BIGINT REFERENCES locations(id) ON DELETE SET NULL,
    name            TEXT NOT NULL,
    address         TEXT NOT NULL,
    city            TEXT NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE rooms (
    id              BIGSERIAL PRIMARY KEY,
    location_id     BIGINT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    capacity        SMALLINT NOT NULL,
    has_projector   BOOLEAN NOT NULL DEFAULT FALSE,
    has_whiteboard  BOOLEAN NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_rooms_capacity CHECK (capacity > 0),
    CONSTRAINT uq_rooms_location_name UNIQUE (location_id, name)
);

CREATE TABLE workspaces (
    id              BIGSERIAL PRIMARY KEY,
    location_id     BIGINT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    room_id         BIGINT REFERENCES rooms(id) ON DELETE SET NULL,
    type            TEXT NOT NULL,
    parent_id       BIGINT REFERENCES workspaces(id) ON DELETE SET NULL,
    code            TEXT NOT NULL UNIQUE,
    capacity        SMALLINT NOT NULL DEFAULT 1,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_workspaces_type CHECK (type IN ('hot_desk', 'fixed_desk', 'meeting_room')),
    CONSTRAINT chk_workspaces_capacity CHECK (capacity > 0)
);

CREATE TABLE type_tariffs (
    id              BIGSERIAL PRIMARY KEY,
    type            TEXT NOT NULL,
    price_per_hour  NUMERIC(10,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    valid_from      DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to        DATE,

    CONSTRAINT chk_type_tariffs_type CHECK (type IN ('hot_desk', 'fixed_desk', 'meeting_room')),
    CONSTRAINT chk_type_tariffs_price CHECK (price_per_hour >= 0),
    CONSTRAINT chk_type_tariffs_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT uq_type_tariffs_type_valid UNIQUE (type, valid_from)
);

CREATE TABLE workspace_tariffs (
    id              BIGSERIAL PRIMARY KEY,
    workspace_id    BIGINT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    price_per_hour  NUMERIC(10,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    valid_from      DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to        DATE,

    CONSTRAINT chk_workspace_tariffs_price CHECK (price_per_hour >= 0),
    CONSTRAINT chk_workspace_tariffs_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT uq_workspace_tariffs_ws_valid UNIQUE (workspace_id, valid_from)
);

CREATE TABLE bookings (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    workspace_id    BIGINT NOT NULL REFERENCES workspaces(id) ON DELETE RESTRICT,
    status          TEXT NOT NULL DEFAULT 'pending',
    start_at        TIMESTAMPTZ NOT NULL,
    end_at          TIMESTAMPTZ NOT NULL,
    total_price     NUMERIC(10,2) NOT NULL,
    cancelled_at    TIMESTAMPTZ,
    cancel_reason   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_bookings_status CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
    CONSTRAINT chk_bookings_dates CHECK (end_at > start_at),
    CONSTRAINT chk_bookings_duration CHECK (end_at - start_at <= INTERVAL '8 hours'),
    CONSTRAINT chk_bookings_price CHECK (total_price >= 0)
);

CREATE TABLE payments (
    id              BIGSERIAL PRIMARY KEY,
    booking_id      BIGINT NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    method          TEXT NOT NULL,
    amount          NUMERIC(10,2) NOT NULL,
    status          TEXT NOT NULL,
    paid_at         TIMESTAMPTZ,
    refunded_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_payments_method CHECK (method IN ('card', 'cash', 'transfer')),
    CONSTRAINT chk_payments_status CHECK (status IN ('pending', 'paid', 'refunded', 'failed')),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0)
);

CREATE TABLE reviews (
    id              BIGSERIAL PRIMARY KEY,
    booking_id      BIGINT NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating          SMALLINT NOT NULL,
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_reviews_comment CHECK (comment IS NULL OR char_length(comment) <= 1000)
);


CREATE INDEX idx_user_profiles_user_id      ON user_profiles(user_id);
CREATE INDEX idx_user_roles_user_id         ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id         ON user_roles(role_id);
CREATE INDEX idx_user_roles_granted_by      ON user_roles(granted_by);
CREATE INDEX idx_audit_log_user_id          ON audit_log(user_id);
CREATE INDEX idx_audit_log_created_at       ON audit_log(created_at DESC);
CREATE INDEX idx_audit_log_entity           ON audit_log(entity_type, entity_id);
CREATE INDEX idx_locations_parent_id        ON locations(parent_id);
CREATE INDEX idx_rooms_location_id          ON rooms(location_id);
CREATE INDEX idx_workspaces_location_id     ON workspaces(location_id);
CREATE INDEX idx_workspaces_room_id         ON workspaces(room_id);
CREATE INDEX idx_workspaces_parent_id       ON workspaces(parent_id);
CREATE INDEX idx_workspace_tariffs_ws_id    ON workspace_tariffs(workspace_id);
CREATE INDEX idx_bookings_user_id           ON bookings(user_id);
CREATE INDEX idx_bookings_workspace_id      ON bookings(workspace_id);
CREATE INDEX idx_bookings_status            ON bookings(status);

CREATE INDEX idx_bookings_ws_time           ON bookings(workspace_id, start_at, end_at);

CREATE INDEX idx_users_active               ON users(id) WHERE deleted_at IS NULL;
















