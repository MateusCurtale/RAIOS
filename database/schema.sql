PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS stations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    site_limit_kw REAL NOT NULL CHECK (site_limit_kw > 0),
    alert_percent INTEGER NOT NULL DEFAULT 90 CHECK (alert_percent BETWEEN 50 AND 100),
    tariff_brl_kwh REAL NOT NULL DEFAULT 0 CHECK (tariff_brl_kwh >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chargers (
    id TEXT PRIMARY KEY,
    station_id TEXT NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 1 CHECK (priority >= 1),
    enabled INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0, 1))
);

CREATE TABLE IF NOT EXISTS telemetry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_id TEXT NOT NULL REFERENCES stations(id),
    captured_at TEXT NOT NULL,
    demand_kw REAL NOT NULL CHECK (demand_kw >= 0),
    solar_kw REAL NOT NULL DEFAULT 0 CHECK (solar_kw >= 0),
    grid_kw REAL NOT NULL DEFAULT 0 CHECK (grid_kw >= 0),
    source TEXT NOT NULL DEFAULT 'mqtt'
        CHECK (source IN ('mqtt', 'demo', 'manual'))
);

CREATE INDEX IF NOT EXISTS idx_telemetry_station_time
    ON telemetry(station_id, captured_at DESC);

CREATE TABLE IF NOT EXISTS charger_telemetry (
    telemetry_id INTEGER NOT NULL REFERENCES telemetry(id) ON DELETE CASCADE,
    charger_id TEXT NOT NULL REFERENCES chargers(id),
    requested_kw REAL NOT NULL CHECK (requested_kw >= 0),
    allocated_kw REAL NOT NULL CHECK (allocated_kw >= 0),
    status TEXT NOT NULL DEFAULT 'available'
        CHECK (status IN ('charging', 'waiting', 'available', 'paused', 'error')),
    PRIMARY KEY (telemetry_id, charger_id)
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_id TEXT NOT NULL REFERENCES stations(id),
    code TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    state TEXT NOT NULL DEFAULT 'active' CHECK (state IN ('active', 'resolved')),
    started_at TEXT NOT NULL,
    resolved_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_station_state_time
    ON alerts(station_id, state, started_at DESC);

CREATE TABLE IF NOT EXISTS management_decisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_id TEXT NOT NULL REFERENCES stations(id),
    created_at TEXT NOT NULL,
    operator_name TEXT,
    trigger_code TEXT NOT NULL,
    strategy TEXT NOT NULL CHECK (strategy IN ('priority', 'proportional', 'solar_first', 'no_action')),
    target_percent INTEGER NOT NULL CHECK (target_percent BETWEEN 50 AND 100),
    demand_before_kw REAL NOT NULL,
    demand_after_kw REAL NOT NULL,
    reduction_kw REAL NOT NULL DEFAULT 0,
    estimated_savings_brl_hour REAL NOT NULL DEFAULT 0,
    outcome TEXT NOT NULL DEFAULT 'simulated'
        CHECK (outcome IN ('simulated', 'confirmed', 'sent', 'rejected')),
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_decisions_station_time
    ON management_decisions(station_id, created_at DESC);

-- Initial demonstration station. Safe to execute repeatedly.
INSERT OR IGNORE INTO stations
    (id, name, site_limit_kw, alert_percent, tariff_brl_kwh)
VALUES
    ('posto-01', 'Posto RAIOS · Unidade demonstração', 10.0, 90, 0.0);

INSERT OR IGNORE INTO chargers (id, station_id, name, priority)
VALUES
    ('c1', 'posto-01', 'Carregador 01', 1),
    ('c2', 'posto-01', 'Carregador 02', 2);
