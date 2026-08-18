import ballerina/http;

function handleGetComponents(string assetTag) returns Component[]|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    return found.components;
}

function handleAddComponent(string assetTag, Component comp) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    foreach Component c in a.components {
        if c.compId == comp.compId {
            return <http:Conflict>{body: <ErrorPayload>{message: string `Component '${comp.compId}' already exists on this asset`}};
        }
    }
    a.components.push(comp);
    assetsTable.put(a);
    return a;
}

function handleDeleteComponent(string assetTag, string compId) returns Asset|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    boolean componentFound = false;
    foreach Component c in a.components {
        if c.compId == compId {
            componentFound = true;
        }
    }
    if !componentFound {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Component '${compId}' not found on asset '${assetTag}'`}};
    }
    a.components = from Component c in a.components where c.compId != compId select c;
    assetsTable.put(a);
    return a;
}
