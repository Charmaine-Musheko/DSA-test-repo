import ballerina/http;

function handleGetSchedules(string assetTag) returns Schedule[]|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    return found.schedules;
}

function handleAddSchedule(string assetTag, Schedule sched) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    foreach Schedule s in a.schedules {
        if s.scheduleId == sched.scheduleId {
            return <http:Conflict>{body: <ErrorPayload>{message: string `Schedule '${sched.scheduleId}' already exists on this asset`}};
        }
    }
    a.schedules.push(sched);
    assetsTable.put(a);
    return a;
}

function handleUpdateSchedule(string assetTag, string scheduleId, Schedule updated)
        returns Asset|http:NotFound|http:BadRequest {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    if updated.scheduleId != scheduleId {
        return <http:BadRequest>{body: <ErrorPayload>{message: "scheduleId in payload must match the path"}};
    }
    Schedule[] newSchedules = [];
    boolean matched = false;
    foreach Schedule s in a.schedules {
        if s.scheduleId == scheduleId {
            newSchedules.push(updated);
            matched = true;
        } else {
            newSchedules.push(s);
        }
    }
    if !matched {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Schedule '${scheduleId}' not found on asset '${assetTag}'`}};
    }
    a.schedules = newSchedules;
    assetsTable.put(a);
    return a;
}

function handleDeleteSchedule(string assetTag, string scheduleId) returns Asset|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    boolean scheduleFound = false;
    foreach Schedule s in a.schedules {
        if s.scheduleId == scheduleId {
            scheduleFound = true;
        }
    }
    if !scheduleFound {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Schedule '${scheduleId}' not found on asset '${assetTag}'`}};
    }
    a.schedules = from Schedule s in a.schedules where s.scheduleId != scheduleId select s;
    assetsTable.put(a);
    return a;
}
