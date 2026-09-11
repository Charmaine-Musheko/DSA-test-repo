import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;
import ballerina/log;

// ---------------------------------------------------------------------------
// Connection
// ---------------------------------------------------------------------------

configurable string pgHost = "127.0.0.1";
configurable int pgPort = 5432;
configurable string pgUser = "library_service_user";
configurable string pgPassword = "123@Librarian!";
configurable string pgDatabase = "library_service_db";

final postgresql:Client pgClient = check new (
    host = pgHost,
    port = pgPort,
    username = pgUser,
    password = pgPassword,
    database = pgDatabase
);

// ---------------------------------------------------------------------------
// Institutions
// ---------------------------------------------------------------------------

// Upsert the institution row, then reconcile its site list.
// Sites are a child table, so we delete-and-reinsert to guarantee the DB
// matches the in-memory `inst.sites` array exactly.
function persistInstitutionSnapshot(Institution inst) returns error? {
    sql:ParameterizedQuery upsertInstitution = `
        INSERT INTO institutions (name)
        VALUES (${inst.name})
        ON CONFLICT (name) DO NOTHING
    `;
    _ = check pgClient->execute(upsertInstitution);

    sql:ParameterizedQuery clearSites = `
        DELETE FROM institution_sites WHERE institution_name = ${inst.name}
    `;
    _ = check pgClient->execute(clearSites);

    foreach string site in inst.sites {
        sql:ParameterizedQuery insertSite = `
            INSERT INTO institution_sites (institution_name, site)
            VALUES (${inst.name}, ${site})
            ON CONFLICT DO NOTHING
        `;
        _ = check pgClient->execute(insertSite);
    }
}

function removeInstitutionSnapshot(string name) returns error? {
    // Child sites are removed first; if your schema uses ON DELETE CASCADE
    // this is redundant but harmless.
    _ = check pgClient->execute(`
        DELETE FROM institution_sites WHERE institution_name = ${name}
    `);
    _ = check pgClient->execute(`
        DELETE FROM institutions WHERE name = ${name}
    `);
}

// ---------------------------------------------------------------------------
// Assets — parent row plus full reconciliation of all child collections
// ---------------------------------------------------------------------------

function persistAssetSnapshot(Asset a) returns error? {
    // 1. Parent row: upsert every mutable column.
    sql:ParameterizedQuery upsertAsset = `
        INSERT INTO assets (
            asset_tag, name, description, institution_name,
            site, status, date_acquired
        )
        VALUES (
            ${a.assetTag}, ${a.name}, ${a.description}, ${a.institution},
            ${a.site}, ${a.status}, ${a.dateAcquired}
        )
        ON CONFLICT (asset_tag) DO UPDATE SET
            name             = EXCLUDED.name,
            description      = EXCLUDED.description,
            institution_name = EXCLUDED.institution_name,
            site             = EXCLUDED.site,
            status           = EXCLUDED.status,
            date_acquired    = EXCLUDED.date_acquired
    `;
    _ = check pgClient->execute(upsertAsset);

    // 2. Child tables: wipe and re-insert. This is the simplest way to keep
    //    the DB in lock-step with the in-memory arrays without diffing.
    _ = check pgClient->execute(`
        DELETE FROM components WHERE asset_tag = ${a.assetTag}
    `);
    foreach Component c in a.components {
        _ = check pgClient->execute(`
            INSERT INTO components (asset_tag, comp_id, name, description)
            VALUES (${a.assetTag}, ${c.compId}, ${c.name}, ${c.description})
        `);
    }

    _ = check pgClient->execute(`
        DELETE FROM schedules WHERE asset_tag = ${a.assetTag}
    `);
    foreach Schedule s in a.schedules {
        _ = check pgClient->execute(`
            INSERT INTO schedules (
                asset_tag, schedule_id, schedule_type,
                due_date, description, status
            )
            VALUES (
                ${a.assetTag}, ${s.scheduleId}, ${s.'type},
                ${s.dueDate}, ${s.description}, ${s.status}
            )
        `);
    }

    // Work orders and their tasks are two levels deep. Delete tasks first
    // (in case your schema has no ON DELETE CASCADE on the FK).
    _ = check pgClient->execute(`
        DELETE FROM work_tasks WHERE asset_tag = ${a.assetTag}
    `);
    _ = check pgClient->execute(`
        DELETE FROM work_orders WHERE asset_tag = ${a.assetTag}
    `);
    foreach WorkOrder w in a.workOrders {
        _ = check pgClient->execute(`
            INSERT INTO work_orders (asset_tag, order_id, status, description)
            VALUES (${a.assetTag}, ${w.orderId}, ${w.status}, ${w.description})
        `);
        foreach WorkTask t in w.tasks {
            _ = check pgClient->execute(`
                INSERT INTO work_tasks (
                    asset_tag, order_id, task_id, description, completed
                )
                VALUES (
                    ${a.assetTag}, ${w.orderId}, ${t.taskId},
                    ${t.description}, ${t.completed}
                )
            `);
        }
    }
}

// Remove the asset and everything that hangs off it.
function removeAssetSnapshot(string assetTag) returns error? {
    _ = check pgClient->execute(`
        DELETE FROM work_tasks WHERE asset_tag = ${assetTag}
    `);
    _ = check pgClient->execute(`
        DELETE FROM work_orders WHERE asset_tag = ${assetTag}
    `);
    _ = check pgClient->execute(`
        DELETE FROM schedules WHERE asset_tag = ${assetTag}
    `);
    _ = check pgClient->execute(`
        DELETE FROM components WHERE asset_tag = ${assetTag}
    `);
    _ = check pgClient->execute(`
        DELETE FROM assets WHERE asset_tag = ${assetTag}
    `);
}

// ---------------------------------------------------------------------------
// Safe wrappers — never let a DB problem break the HTTP handler
// ---------------------------------------------------------------------------
// Your handlers do not return `error`, so they cannot use `check` directly
// on these functions. These wrappers swallow the error and log it instead.
// The in-memory Map/Table remains the source of truth; PostgreSQL is the
// best-effort mirror.

function safePersistAsset(Asset a) {
    error? result = persistAssetSnapshot(a);
    if result is error {
        log:printError("Failed to persist asset snapshot",
                       result, assetTag = a.assetTag);
    }
}

function safePersistInstitution(Institution inst) {
    error? result = persistInstitutionSnapshot(inst);
    if result is error {
        log:printError("Failed to persist institution snapshot",
                       result, name = inst.name);
    }
}

function safeRemoveAsset(string assetTag) {
    error? result = removeAssetSnapshot(assetTag);
    if result is error {
        log:printError("Failed to remove asset snapshot",
                       result, assetTag = assetTag);
    }
}

function safeRemoveInstitution(string name) {
    error? result = removeInstitutionSnapshot(name);
    if result is error {
        log:printError("Failed to remove institution snapshot",
                       result, name = name);
    }
}


