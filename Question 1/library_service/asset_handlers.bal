import ballerina/http;
function handleCreateAsset(Asset newAsset) returns http:Created|http:Conflict|http:BadRequest {
    if newAsset.assetTag.trim().length() == 0 {
        return <http:BadRequest>{body: <ErrorPayload>{message: "assetTag is required", path: "/library/assets"}};
    }
    if !institutions.hasKey(newAsset.institution) {
        return <http:BadRequest>{
            body: <ErrorPayload>{message: string `Unknown institution '${newAsset.institution}'. Register it first via POST /library/institutions`, path: "/library/assets"}
        };
    }
    if assetsTable.hasKey(newAsset.assetTag) {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset '${newAsset.assetTag}' already exists`, path: "/library/assets"}};
    }
    assetsTable.add(newAsset);
    return <http:Created>{body: newAsset};
}

function handleListAssets() returns Asset[] {
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
    if updated.assetTag != assetTag {
        return <http:BadRequest>{body: <ErrorPayload>{message: "assetTag in payload must match the path"}};
    }
    assetsTable.put(updated);
    return updated;
}

function handleDeleteAsset(string assetTag) returns http:Ok|http:NotFound {
    if !assetsTable.hasKey(assetTag) {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    _ = assetsTable.remove(assetTag);
    return <http:Ok>{body: <ErrorPayload>{message: string `Asset '${assetTag}' deleted`}};
}

function handleAssetsByInstitution(string institution) returns Asset[] {
    return from Asset a in assetsTable
        where a.institution == institution
        select a;
}

function handleAssetsByInstitutionSite(string institution, string site) returns Asset[] {
    return from Asset a in assetsTable
        where a.institution == institution && a.site == site
        select a;
}

function handleAssetStatus(string assetTag) returns record {| string assetTag; AssetStatus status; boolean overdue; |}|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    return {assetTag: found.assetTag, status: found.status, overdue: assetHasOverdueSchedule(found)};
}

function handleOverdueAssets() returns Asset[] {
    return from Asset a in assetsTable
        where assetHasOverdueSchedule(a)
        select a;
}
