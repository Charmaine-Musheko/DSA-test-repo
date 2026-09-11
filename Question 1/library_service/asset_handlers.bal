import ballerina/http;

function handleCreateAsset(Asset newAsset) returns http:Created|http:Conflict|http:BadRequest {
    // Guard: assetTag is the unique key and must never be blank.
    if newAsset.assetTag.trim().length() == 0 {
        return <http:BadRequest>{body: <ErrorPayload>{message: "assetTag is required", path: "/library/assets"}};
    }
    // Guard: the institution must already be registered; otherwise we would have dangling references.
    if !institutions.hasKey(newAsset.institution) {
        return <http:BadRequest>{
            body: <ErrorPayload>{message: string `Unknown institution '${newAsset.institution}'. Register it first via POST /library/institutions`, path: "/library/assets"}
        };
    }
    // Guard: uniqueness enforced by the in-memory table's key(assetTag).
    if assetsTable.hasKey(newAsset.assetTag) {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset '${newAsset.assetTag}' already exists`, path: "/library/assets"}};
    }
    assetsTable.add(newAsset);
    // Mirror the new record into PostgreSQL. Non-fatal: if PG is down, the API still works.
    safePersistAsset(newAsset);
    return <http:Created>{body: newAsset};
}

function handleListAssets() returns Asset[] {
    // Global view: return the entire in-memory table as an array.
    return assetsTable.toArray();
}

function handleGetAsset(string assetTag) returns Asset|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is Asset {
        return found;
    }
    return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`, path: string `/library/assets/${assetTag}`}};
}

function handleUpdateAsset(string assetTag, Asset updated) returns Asset|http:NotFound|http:BadRequest {
    if !assetsTable.hasKey(assetTag) {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    // Prevent renaming via PUT; assetTag is immutable by contract.
    if updated.assetTag != assetTag {
        return <http:BadRequest>{body: <ErrorPayload>{message: "assetTag in payload must match the path"}};
    }
    assetsTable.put(updated);
    // Overwrite the snapshot in PG; upsert handles both insert and update.
    safePersistAsset(updated);
    return updated;
}

function handleDeleteAsset(string assetTag) returns http:Ok|http:NotFound {
    if !assetsTable.hasKey(assetTag) {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    _ = assetsTable.remove(assetTag);
    // Drop the corresponding row in PG as well.
    safeRemoveAsset(assetTag);
    return <http:Ok>{body: <ErrorPayload>{message: string `Asset '${assetTag}' deleted`}};
}

function handleAssetsByInstitution(string institution) returns Asset[] {
    // Campus view: filter by institution name.
    return from Asset a in assetsTable
        where a.institution == institution
        select a;
}

function handleAssetsByInstitutionSite(string institution, string site) returns Asset[] {
    // Narrower campus view: filter by institution AND site.
    return from Asset a in assetsTable
        where a.institution == institution && a.site == site
        select a;
}

function handleAssetStatus(string assetTag) returns record {| string assetTag; AssetStatus status; boolean overdue; |}|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    // `overdue` is derived, not stored: any PENDING schedule whose dueDate is in the past.
    return {assetTag: found.assetTag, status: found.status, overdue: assetHasOverdueSchedule(found)};
}

function handleOverdueAssets() returns Asset[] {
    // Overdue dashboard: every asset with at least one overdue PENDING schedule.
    return from Asset a in assetsTable
        where assetHasOverdueSchedule(a)
        select a;
}



