import ballerina/http;

function handleGetWorkOrders(string assetTag) returns WorkOrder[]|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    return found.workOrders;
}

function handleAddWorkOrder(string assetTag, WorkOrder wo) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    foreach WorkOrder w in a.workOrders {
        if w.orderId == wo.orderId {
            return <http:Conflict>{body: <ErrorPayload>{message: string `Work order '${wo.orderId}' already exists on this asset`}};
        }
    }
    a.workOrders.push(wo);

    if wo.status != "CLOSED" {
        a.status = "UNDER_MAINTENANCE";
    }
    assetsTable.put(a);
    return a;
}

function handleUpdateWorkOrder(string assetTag, string orderId, WorkOrder updated)
        returns Asset|http:NotFound|http:BadRequest {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    if updated.orderId != orderId {
        return <http:BadRequest>{body: <ErrorPayload>{message: "orderId in payload must match the path"}};
    }
    WorkOrder[] newOrders = [];
    boolean matched = false;
    foreach WorkOrder w in a.workOrders {
        if w.orderId == orderId {
            newOrders.push(updated);
            matched = true;
        } else {
            newOrders.push(w);
        }
    }
    if !matched {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Work order '${orderId}' not found on asset '${assetTag}'`}};
    }
    a.workOrders = newOrders;
    assetsTable.put(a);
    return a;
}

function handleDeleteWorkOrder(string assetTag, string orderId) returns Asset|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    boolean orderFound = false;
    foreach WorkOrder w in a.workOrders {
        if w.orderId == orderId {
            orderFound = true;
        }
    }
    if !orderFound {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Work order '${orderId}' not found on asset '${assetTag}'`}};
    }
    a.workOrders = from WorkOrder w in a.workOrders where w.orderId != orderId select w;
    assetsTable.put(a);
    return a;
}

function handleAddTask(string assetTag, string orderId, WorkTask t) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    WorkOrder[] newOrders = [];
    boolean matched = false;
    foreach WorkOrder w in a.workOrders {
        if w.orderId == orderId {
            foreach WorkTask existingTask in w.tasks {
                if existingTask.taskId == t.taskId {
                    return <http:Conflict>{body: <ErrorPayload>{message: string `Task '${t.taskId}' already exists on work order '${orderId}'`}};
                }
            }
            w.tasks.push(t);
            matched = true;
        }
        newOrders.push(w);
    }
    if !matched {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Work order '${orderId}' not found on asset '${assetTag}'`}};
    }
    a.workOrders = newOrders;
    assetsTable.put(a);
    return a;
}

function handleUpdateTask(string assetTag, string orderId, string taskId, WorkTask updated)
        returns Asset|http:NotFound|http:BadRequest {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    if updated.taskId != taskId {
        return <http:BadRequest>{body: <ErrorPayload>{message: "taskId in payload must match the path"}};
    }
    WorkOrder[] newOrders = [];
    boolean matched = false;
    foreach WorkOrder w in a.workOrders {
        if w.orderId == orderId {
            WorkTask[] newTasks = [];
            foreach WorkTask t in w.tasks {
                if t.taskId == taskId {
                    newTasks.push(updated);
                    matched = true;
                } else {
                    newTasks.push(t);
                }
            }
            w.tasks = newTasks;
        }
        newOrders.push(w);
    }
    if !matched {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Task '${taskId}' not found on work order '${orderId}'`}};
    }
    a.workOrders = newOrders;
    assetsTable.put(a);
    return a;
}

function handleDeleteTask(string assetTag, string orderId, string taskId) returns Asset|http:NotFound {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    WorkOrder[] newOrders = [];
    boolean matched = false;
    foreach WorkOrder w in a.workOrders {
        if w.orderId == orderId {
            WorkTask[] remainingTasks = [];
            foreach WorkTask t in w.tasks {
                if t.taskId == taskId {
                    matched = true;
                } else {
                    remainingTasks.push(t);
                }
            }
            w.tasks = remainingTasks;
        }
        newOrders.push(w);
    }
    if !matched {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Task '${taskId}' not found on work order '${orderId}'`}};
    }
    a.workOrders = newOrders;
    assetsTable.put(a);
    return a;
}
