import ballerina/http;

listener http:Listener libraryListener = new (8080);

service /library on libraryListener {

    resource function post assets(@http:Payload Asset newAsset)
            returns http:Created|http:Conflict|http:BadRequest {
        return handleCreateAsset(newAsset);
    }

    resource function get assets() returns Asset[] {
        return handleListAssets();
    }

    resource function get assets/[string assetTag]() returns Asset|http:NotFound {
        return handleGetAsset(assetTag);
    }

    resource function put assets/[string assetTag](@http:Payload Asset updated)
            returns Asset|http:NotFound|http:BadRequest {
        return handleUpdateAsset(assetTag, updated);
    }

    resource function delete assets/[string assetTag]() returns http:Ok|http:NotFound {
        return handleDeleteAsset(assetTag);
    }

    resource function get assets/institution/[string institution]() returns Asset[] {
        return handleAssetsByInstitution(institution);
    }

    resource function get assets/institution/[string institution]/site/[string site]() returns Asset[] {
        return handleAssetsByInstitutionSite(institution, site);
    }

    resource function get assets/[string assetTag]/status()
            returns record {| string assetTag; AssetStatus status; boolean overdue; |}|http:NotFound {
        return handleAssetStatus(assetTag);
    }

    resource function get assets/overdue() returns Asset[] {
        return handleOverdueAssets();
    }

    resource function post assets/[string assetTag]/loan(@http:Payload LoanRequest req)
            returns Asset|http:NotFound|http:Conflict {
        return handleLoanAsset(assetTag, req);
    }

    resource function post assets/[string assetTag]/'return()
            returns Asset|http:NotFound|http:Conflict {
        return handleReturnAsset(assetTag);
    }

    resource function post assets/[string assetTag]/book(@http:Payload BookingRequest req)
            returns Asset|http:NotFound|http:Conflict {
        return handleBookAsset(assetTag, req);
    }

    resource function post assets/[string assetTag]/release()
            returns Asset|http:NotFound|http:Conflict {
        return handleReleaseAsset(assetTag);
    }

    resource function get assets/[string assetTag]/components() returns Component[]|http:NotFound {
        return handleGetComponents(assetTag);
    }

    resource function post assets/[string assetTag]/components(@http:Payload Component comp)
            returns Asset|http:NotFound|http:Conflict {
        return handleAddComponent(assetTag, comp);
    }

    resource function delete assets/[string assetTag]/components/[string compId]() returns Asset|http:NotFound {
        return handleDeleteComponent(assetTag, compId);
    }

    resource function get assets/[string assetTag]/schedules() returns Schedule[]|http:NotFound {
        return handleGetSchedules(assetTag);
    }

    resource function post assets/[string assetTag]/schedules(@http:Payload Schedule sched)
            returns Asset|http:NotFound|http:Conflict {
        return handleAddSchedule(assetTag, sched);
    }

    resource function put assets/[string assetTag]/schedules/[string scheduleId](@http:Payload Schedule updated)
            returns Asset|http:NotFound|http:BadRequest {
        return handleUpdateSchedule(assetTag, scheduleId, updated);
    }

    resource function delete assets/[string assetTag]/schedules/[string scheduleId]() returns Asset|http:NotFound {
        return handleDeleteSchedule(assetTag, scheduleId);
    }

    resource function get assets/[string assetTag]/workorders() returns WorkOrder[]|http:NotFound {
        return handleGetWorkOrders(assetTag);
    }

    resource function post assets/[string assetTag]/workorders(@http:Payload WorkOrder wo)
            returns Asset|http:NotFound|http:Conflict {
        return handleAddWorkOrder(assetTag, wo);
    }

    resource function put assets/[string assetTag]/workorders/[string orderId](@http:Payload WorkOrder updated)
            returns Asset|http:NotFound|http:BadRequest {
        return handleUpdateWorkOrder(assetTag, orderId, updated);
    }

    resource function delete assets/[string assetTag]/workorders/[string orderId]() returns Asset|http:NotFound {
        return handleDeleteWorkOrder(assetTag, orderId);
    }

    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(@http:Payload WorkTask t)
            returns Asset|http:NotFound|http:Conflict {
        return handleAddTask(assetTag, orderId, t);
    }

    resource function put assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId](@http:Payload WorkTask updated)
            returns Asset|http:NotFound|http:BadRequest {
        return handleUpdateTask(assetTag, orderId, taskId, updated);
    }

    resource function delete assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId]()
            returns Asset|http:NotFound {
        return handleDeleteTask(assetTag, orderId, taskId);
    }

    resource function get institutions() returns Institution[] {
        return handleListInstitutions();
    }

    resource function get institutions/[string name]() returns Institution|http:NotFound {
        return handleGetInstitution(name);
    }

    resource function post institutions(@http:Payload Institution inst)
            returns http:Created|http:Conflict|http:BadRequest {
        return handleAddInstitution(inst);
    }

    resource function delete institutions/[string name]() returns http:Ok|http:NotFound|http:Conflict {
        return handleDeleteInstitution(name);
    }

    resource function post institutions/[string name]/sites(@http:Payload SiteRequest req)
            returns Institution|http:NotFound|http:Conflict {
        return handleAddSite(name, req);
    }

    resource function delete institutions/[string name]/sites/[string site]()
            returns Institution|http:NotFound {
        return handleDeleteSite(name, site);
    }
}
