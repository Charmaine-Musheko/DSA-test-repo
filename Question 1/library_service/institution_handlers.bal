import ballerina/http;

function handleListInstitutions() returns Institution[] {
    return institutions.toArray();
}

function handleGetInstitution(string name) returns Institution|http:NotFound {
    Institution? found = institutions[name];
    if found is Institution {
        return found;
    }
    return <http:NotFound>{body: <ErrorPayload>{message: string `Institution '${name}' not found`}};
}

function handleAddInstitution(Institution inst) returns http:Created|http:Conflict|http:BadRequest {
    if inst.name.trim().length() == 0 {
        return <http:BadRequest>{body: <ErrorPayload>{message: "institution name is required"}};
    }
    if institutions.hasKey(inst.name) {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Institution '${inst.name}' already exists`}};
    }
    institutions[inst.name] = inst;
    // Mirror the new institution into PG.
    safePersistInstitution(inst);
    return <http:Created>{body: inst};
}

function handleDeleteInstitution(string name) returns http:Ok|http:NotFound|http:Conflict {
    if !institutions.hasKey(name) {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Institution '${name}' not found`}};
    }
    // Referential integrity: refuse deletion while any asset still points at this institution.
    Asset[] linkedAssets = from Asset a in assetsTable where a.institution == name select a;
    if linkedAssets.length() > 0 {
        return <http:Conflict>{
            body: <ErrorPayload>{message: string `Cannot remove '${name}': ${linkedAssets.length()} asset(s) still reference it`}
        };
    }
    _ = institutions.remove(name);
    safeRemoveInstitution(name);
    return <http:Ok>{body: <ErrorPayload>{message: string `Institution '${name}' removed`}};
}

function handleAddSite(string name, SiteRequest req) returns Institution|http:NotFound|http:Conflict {
    Institution? found = institutions[name];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Institution '${name}' not found`}};
    }
    Institution inst = found;
    // Site names must be unique within one institution.
    foreach string s in inst.sites {
        if s == req.site {
            return <http:Conflict>{body: <ErrorPayload>{message: string `Site '${req.site}' already exists for '${name}'`}};
        }
    }
    inst.sites.push(req.site);
    institutions[name] = inst;
    // Re-persist the whole institution because sites is stored as a JSONB array.
    safePersistInstitution(inst);
    return inst;
}

function handleDeleteSite(string name, string site) returns Institution|http:NotFound {
    Institution? found = institutions[name];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Institution '${name}' not found`}};
    }
    Institution inst = found;
    // Rebuild the array without the target site.
    inst.sites = from string s in inst.sites where s != site select s;
    institutions[name] = inst;
    safePersistInstitution(inst);
    return inst;
}



