
public type AssetStatus "AVAILABLE"|"LOANED_OUT"|"OCCUPIED"|"UNDER_MAINTENANCE"|"DISPOSED";

public type ScheduleStatus "PENDING"|"COMPLETED"|"CANCELLED";

public type WorkOrderStatus "OPEN"|"IN_PROGRESS"|"CLOSED";

public type Component record {|
    string compId;
    string name;
    string description = "";
|};

public type Schedule record {|
    string scheduleId;
    string 'type;              
    string dueDate;
    string description = "";
    ScheduleStatus status = "PENDING";
|};

public type WorkTask record {|
    string taskId;
    string description;
    boolean completed = false;
|};

public type WorkOrder record {|
    string orderId;
    WorkOrderStatus status;
    string description;
    WorkTask[] tasks = [];
|};

public type Asset record {|
    readonly string assetTag;
    string name;
    string description = "";
    string institution;
    string site;
    string dateAcquired;
    AssetStatus status;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

public type Institution record {|
    readonly string name;
    string[] sites = [];
|};

public type LoanRequest record {|
    string borrower;
    string dueDate;
    string description = "";
|};

public type BookingRequest record {|
    string bookedBy;
    string dueDate;
    string description = "";
|};

public type SiteRequest record {|
    string site;
|};

public type ErrorPayload record {|
    string message;
    string path = "";
|};
