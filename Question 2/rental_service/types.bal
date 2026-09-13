public type PropertyRecord record {|
    readonly string propertyId;
    string hostId;
    string name;
    string location;
    string region;
    string propertyType;
    decimal pricePerNight;
    string status;
    string description = "";
|};

public type UserRecord record {|
    readonly string userId;
    string name;
    string email;
    string role;
    string region = "";
|};

public type BookingRecord record {|
    readonly string bookingId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
    decimal totalCost;
    string status;
|};

public type CartItem record {|
    readonly string cartId;
    string guestId;
    string propertyId;
    string checkIn;
    string checkOut;
|};

public type ServiceError record {|
    string message;
|};


// ============================================================================
// REMOVED BOOKING HISTORY
// ============================================================================
//
// Removed bookings are not discarded.
//
// The original booking information is copied into the PostgreSQL
// removed_bookings table before the active booking is deleted.
// ============================================================================

public type RemovedBookingRecord record {|

    readonly string bookingId;

    string propertyId;

    string guestId;

    string checkIn;

    string checkOut;

    decimal totalCost;

    string status;

    string reason;

    string removedAt = "";

|};


