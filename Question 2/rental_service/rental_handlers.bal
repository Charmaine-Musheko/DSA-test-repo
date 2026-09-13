import ballerina/lang.'int as ints;
import ballerina/time;


// ============================================================================
// DATE HELPERS
// ============================================================================

function daysFromCivil(
    int y,
    int m,
    int d
) returns int {

    int yy =
        y - (m <= 2 ? 1 : 0);

    int era =
        (yy >= 0 ? yy : yy - 399) / 400;

    int yoe =
        yy - era * 400;

    int doy =
        (
            153 *
            (
                m + (m > 2 ? -3 : 9)
            )
            + 2
        ) / 5
        + d
        - 1;

    int doe =
        yoe * 365
        + yoe / 4
        - yoe / 100
        + doy;

    return era * 146097
        + doe
        - 719468;
}


function nightsBetween(
    string checkIn,
    string checkOut
) returns int {

    // Basic ISO yyyy-mm-dd length protection.
    if checkIn.length() != 10 ||
        checkOut.length() != 10 {

        return 0;
    }

    int|error y1 =
        ints:fromString(
            checkIn.substring(0, 4)
        );

    int|error m1 =
        ints:fromString(
            checkIn.substring(5, 7)
        );

    int|error d1 =
        ints:fromString(
            checkIn.substring(8, 10)
        );

    int|error y2 =
        ints:fromString(
            checkOut.substring(0, 4)
        );

    int|error m2 =
        ints:fromString(
            checkOut.substring(5, 7)
        );

    int|error d2 =
        ints:fromString(
            checkOut.substring(8, 10)
        );


    if y1 is error ||
        m1 is error ||
        d1 is error ||
        y2 is error ||
        m2 is error ||
        d2 is error {

        return 0;
    }


    return daysFromCivil(
        y2,
        m2,
        d2
    ) - daysFromCivil(
        y1,
        m1,
        d1
    );
}


function todayIso() returns string {

    time:Utc now =
        time:utcNow();

    time:Civil civil =
        time:utcToCivil(now);

    string mm =
        civil.month < 10
        ? string `0${civil.month}`
        : civil.month.toString();

    string dd =
        civil.day < 10
        ? string `0${civil.day}`
        : civil.day.toString();

    return string `${civil.year}-${mm}-${dd}`;
}


// ============================================================================
// PROPERTY STATUS CONVERSION
// ============================================================================

function statusToProto(
    string status
) returns PropertyStatus {

    match status {

        "AVAILABLE" => {
            return AVAILABLE;
        }

        "BOOKED" => {
            return BOOKED;
        }

        "UNDER_MAINTENANCE" => {
            return UNDER_MAINTENANCE;
        }

        "DELISTED" => {
            return DELISTED;
        }

        _ => {
            return PROPERTY_STATUS_UNSPECIFIED;
        }
    }
}


function protoToStatus(
    PropertyStatus status
) returns string {

    match status {

        AVAILABLE => {
            return "AVAILABLE";
        }

        BOOKED => {
            return "BOOKED";
        }

        UNDER_MAINTENANCE => {
            return "UNDER_MAINTENANCE";
        }

        DELISTED => {
            return "DELISTED";
        }

        _ => {
            return "AVAILABLE";
        }
    }
}


// ============================================================================
// PROTO CONVERSION HELPERS
// ============================================================================

function toProtoUser(
    UserRecord user
) returns User {

    UserRole role =
        user.role == "HOST"
        ? HOST
        : GUEST;

    return {
        user_id: user.userId,
        name: user.name,
        email: user.email,
        role: role,
        region: user.region
    };
}


function toProtoProperty(
    PropertyRecord property
) returns Property {

    return {
        property_id: property.propertyId,
        host_id: property.hostId,
        name: property.name,
        location: property.location,
        region: property.region,
        property_type: property.propertyType,
        price_per_night: <float>property.pricePerNight,
        status: statusToProto(
            property.status
        ),
        description: property.description
    };
}


function toProtoBooking(
    BookingRecord booking
) returns Booking {

    return {
        booking_id: booking.bookingId,
        property_id: booking.propertyId,
        guest_id: booking.guestId,

        dates: {
            check_in: booking.checkIn,
            check_out: booking.checkOut
        },

        total_cost:
            <float>booking.totalCost,

        status:
            booking.status
    };
}


function toProtoRemovedBooking(
    RemovedBookingRecord removed
) returns RemovedBooking {

    Booking booking = {
        booking_id: removed.bookingId,
        property_id: removed.propertyId,
        guest_id: removed.guestId,

        dates: {
            check_in: removed.checkIn,
            check_out: removed.checkOut
        },

        total_cost:
            <float>removed.totalCost,

        status:
            removed.status
    };

    return {
        booking: booking,
        reason: removed.reason,
        removed_at: removed.removedAt
    };
}


// ============================================================================
// CREATE / REGISTER USER
// ============================================================================

function registerUser(
    User user
) returns UserRecord|ServiceError|error {

    if user.name.trim().length() == 0 {

        return {
            message:
                "user name is required"
        };
    }


    if user.email.trim().length() == 0 {

        return {
            message:
                "user email is required"
        };
    }


    if user.role != HOST &&
        user.role != GUEST {

        return {
            message:
                "user role must be HOST or GUEST"
        };
    }


    string role =
        user.role == HOST
        ? "HOST"
        : "GUEST";


    UserRecord created =
        check insertUser(
            user.name,
            user.email,
            role,
            user.region
        );


    return created;
}


// ============================================================================
// LIST USERS
//
// role_filter:
//
// USER_ROLE_UNSPECIFIED -> all users
// HOST                  -> hosts only
// GUEST                 -> guests only
// ============================================================================

function collectUsers(
    ListUsersRequest request
) returns User[]|error {

    string roleFilter = "";

    if request.role_filter == HOST {

        roleFilter = "HOST";

    } else if request.role_filter == GUEST {

        roleFilter = "GUEST";
    }


    UserRecord[] userRecords =
        check listUserRecords(
            roleFilter
        );


    User[] users = [];


    foreach UserRecord userRecord
        in userRecords {

        users.push(
            toProtoUser(
                userRecord
            )
        );
    }


    return users;
}

// ============================================================================
// SEARCH USER
// ============================================================================

function searchUser(
    SearchUserRequest request
) returns SearchUserResponse|error {

    if request.user_id.trim().length() == 0 {

        return {
            found: false,
            message: "user_id is required",
            user: {}
        };
    }


    UserRecord? existing =
        check getUser(
            request.user_id
        );


    if existing is () {

        return {
            found: false,
            message: string
                `User '${request.user_id}' not found`,
            user: {}
        };
    }


    return {
        found: true,
        message: "User found",
        user: toProtoUser(existing)
    };
}


// ============================================================================
// ADD PROPERTY
// ============================================================================

function addProperty(
    AddPropertyRequest request
) returns AddPropertyResponse|error {

    if request.name.trim().length() == 0 {

        return {
            property_id: "",
            success: false,
            message: "name is required"
        };
    }


    if request.host_id.trim().length() == 0 {

        return {
            property_id: "",
            success: false,
            message: "host_id is required"
        };
    }


    if request.price_per_night <= 0.0 {

        return {
            property_id: "",
            success: false,
            message:
                "price_per_night must be > 0"
        };
    }


    UserRecord? host =
        check getUser(
            request.host_id
        );


    if host is () {

        return {
            property_id: "",
            success: false,

            message: string
                `Host '${request.host_id}' not registered`
        };
    }


    if host.role != "HOST" {

        return {
            property_id: "",
            success: false,

            message: string
                `User '${request.host_id}' is not a HOST`
        };
    }


    PropertyRecord property =
        check insertProperty(
            request.host_id,
            request.name,
            request.location,
            request.region,
            request.property_type,
            <decimal>request.price_per_night,
            request.description
        );


    return {
        property_id:
            property.propertyId,

        success:
            true,

        message: string
            `Property '${request.name}' registered`
    };
}


// ============================================================================
// UPDATE PROPERTY
// ============================================================================

function updateProperty(
    UpdatePropertyRequest request
) returns UpdatePropertyResponse|error {

    PropertyRecord? existing =
        check getProperty(
            request.property_id
        );


    if existing is () {

        return {
            success: false,

            message: string
                `Property '${request.property_id}' not found`,

            property: {}
        };
    }


    PropertyRecord property =
        existing;


    // -----------------------------------------------------------------------
    // Price update.
    // -----------------------------------------------------------------------

    if request.price_per_night is float {

        if request.price_per_night <= 0.0 {

            return {
                success: false,
                message:
                    "price_per_night must be > 0",
                property: {}
            };
        }

        property.pricePerNight =
            <decimal>request.price_per_night;
    }


    // -----------------------------------------------------------------------
    // Status update.
    // -----------------------------------------------------------------------

    PropertyStatus? requestedStatus =
        request.status;


    if requestedStatus is PropertyStatus &&
        requestedStatus != PROPERTY_STATUS_UNSPECIFIED {

        property.status =
            protoToStatus(
                requestedStatus
            );
    }


    // -----------------------------------------------------------------------
    // Description update.
    // -----------------------------------------------------------------------

    string? requestedDescription =
        request.description;


    if requestedDescription is string {

        property.description =
            requestedDescription;
    }


    check updatePropertyRecord(
        property
    );


    return {
        success: true,
        message: "Property updated",
        property:
            toProtoProperty(property)
    };
}


// ============================================================================
// REMOVE PROPERTY
// ============================================================================

function removeProperty(
    RemovePropertyRequest request
) returns RemovePropertyResponse|error {

    PropertyRecord? existing =
        check getProperty(
            request.property_id
        );


    if existing is () {

        return {
            success: false,

            message: string
                `Property '${request.property_id}' not found`,

            remaining_properties: []
        };
    }


    string region =
        existing.region;


    check deletePropertyRecord(
        request.property_id
    );


    PropertyRecord[] remainingRecords =
        check listAvailablePropertiesInRegion(
            region
        );


    Property[] remaining = [];


    foreach PropertyRecord property
        in remainingRecords {

        remaining.push(
            toProtoProperty(property)
        );
    }


    return {
        success: true,

        message: string
            `Property removed. ${remaining.length()} remaining in region '${region}'.`,

        remaining_properties:
            remaining
    };
}


// ============================================================================
// LIST AVAILABLE PROPERTIES
// ============================================================================

function collectAvailable(
    ListAvailableRequest request
) returns Property[]|error {

    PropertyRecord[] records =
        check listAvailablePropertyRecords(
            request.location_filter,
            request.min_price,
            request.max_price
        );


    Property[] properties = [];


    foreach PropertyRecord property
        in records {

        properties.push(
            toProtoProperty(property)
        );
    }


    return properties;
}


// ============================================================================
// SEARCH PROPERTY
// ============================================================================

function searchProperty(
    SearchPropertyRequest request
) returns SearchPropertyResponse|error {

    PropertyRecord? property =
        check getProperty(
            request.property_id
        );


    if property is () {

        return {
            available: false,
            message: "Not Available",
            property: {}
        };
    }


    if property.status != "AVAILABLE" {

        return {
            available: false,

            message: string
                `Not Available (current status: ${property.status})`,

            property:
                toProtoProperty(property)
        };
    }


    return {
        available: true,
        message: "Available",
        property:
            toProtoProperty(property)
    };
}


// ============================================================================
// BOOK PROPERTY
// ============================================================================

function bookProperty(
    BookPropertyRequest request
) returns BookPropertyResponse|error {

    if request.guest_id.trim().length() == 0 {

        return {
            success: false,
            message: "guest_id is required",
            cart_id: "",
            estimated_cost: 0.0
        };
    }


    // -----------------------------------------------------------------------
    // Validate guest.
    // -----------------------------------------------------------------------

    UserRecord? guest =
        check getUser(
            request.guest_id
        );


    if guest is () {

        return {
            success: false,

            message: string
                `Guest '${request.guest_id}' not found`,

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    if guest.role != "GUEST" {

        return {
            success: false,

            message: string
                `User '${request.guest_id}' is not a GUEST`,

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    if request.dates.check_in.trim().length() == 0 ||
        request.dates.check_out.trim().length() == 0 {

        return {
            success: false,

            message:
                "check_in and check_out are required",

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    if request.dates.check_in >=
        request.dates.check_out {

        return {
            success: false,

            message:
                "check_out must be after check_in",

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    if request.dates.check_in <
        todayIso() {

        return {
            success: false,

            message:
                "check_in must not be in the past",

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    PropertyRecord? property =
        check getProperty(
            request.property_id
        );


    if property is () {

        return {
            success: false,

            message: string
                `Property '${request.property_id}' not found`,

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    if property.status != "AVAILABLE" {

        return {
            success: false,

            message: string
                `Property not available (status: ${property.status})`,

            cart_id: "",
            estimated_cost: 0.0
        };
    }


    int nights =
        nightsBetween(
            request.dates.check_in,
            request.dates.check_out
        );


    if nights <= 0 {

        return {
            success: false,
            message: "Invalid booking dates",
            cart_id: "",
            estimated_cost: 0.0
        };
    }


    decimal estimate =
        property.pricePerNight *
        <decimal>nights;


    CartItem cart =
        check insertCartItem(
            request.guest_id,
            request.property_id,
            request.dates.check_in,
            request.dates.check_out
        );


    return {
        success: true,

        message: string
            `Added to cart. ${nights} night(s).`,

        cart_id:
            cart.cartId,

        estimated_cost:
            <float>estimate
    };
}


// ============================================================================
// CONFIRM BOOKING
// ============================================================================

function confirmBooking(
    ConfirmBookingRequest request
) returns ConfirmBookingResponse|error {

    CartItem? existingCart =
        check getCartItem(
            request.cart_id
        );


    if existingCart is () {

        return {
            success: false,

            message: string
                `Cart '${request.cart_id}' not found`,

            booking: {}
        };
    }


    CartItem cart =
        existingCart;


    if cart.guestId !=
        request.guest_id {

        return {
            success: false,

            message:
                "Cart does not belong to this guest",

            booking: {}
        };
    }


    PropertyRecord? property =
        check getProperty(
            cart.propertyId
        );


    if property is () {

        return {
            success: false,
            message:
                "Property no longer exists",
            booking: {}
        };
    }


    boolean overlapping =
        check hasOverlappingBooking(
            cart.propertyId,
            cart.checkIn,
            cart.checkOut
        );


    if overlapping {

        return {
            success: false,

            message:
                "Property is no longer available for the requested dates",

            booking: {}
        };
    }


    int nights =
        nightsBetween(
            cart.checkIn,
            cart.checkOut
        );


    if nights <= 0 {

        return {
            success: false,
            message: "Invalid booking dates",
            booking: {}
        };
    }


    decimal total =
        property.pricePerNight *
        <decimal>nights;


    BookingRecord booking =
        check insertBooking(
            cart.propertyId,
            cart.guestId,
            cart.checkIn,
            cart.checkOut,
            total,
            "CONFIRMED"
        );


    // Remove cart only after booking was successfully persisted.
    check deleteCartItem(
        request.cart_id
    );


    return {
        success: true,

        message: string
            `Booking confirmed. Total cost: ${total.toString()} for ${nights} night(s).`,

        booking:
            toProtoBooking(booking)
    };
}


// ============================================================================
// LIST ACTIVE BOOKINGS
// ============================================================================

function collectBookings(
    ListBookingsRequest request
) returns Booking[]|error {

    BookingRecord[] records =
        check listBookingRecords(
            request.guest_id,
            request.property_id
        );


    Booking[] bookings = [];


    foreach BookingRecord booking
        in records {

        bookings.push(
            toProtoBooking(booking)
        );
    }


    return bookings;
}


// ============================================================================
// SEARCH BOOKING
// ============================================================================
//
// Search order:
//
// 1. Active bookings
// 2. Removed booking archive
// ============================================================================

function searchBooking(
    SearchBookingRequest request
) returns SearchBookingResponse|error {

    if request.booking_id.trim().length() == 0 {

        return {
            found: false,
            removed: false,
            message: "booking_id is required",
            booking: {},
            removed_booking: {}
        };
    }


    BookingRecord? active =
        check getBooking(
            request.booking_id
        );


    if active is BookingRecord {

        return {
            found: true,
            removed: false,
            message:
                "Active booking found",
            booking:
                toProtoBooking(active),
            removed_booking: {}
        };
    }


    RemovedBookingRecord? removed =
        check getRemovedBooking(
            request.booking_id
        );


    if removed is RemovedBookingRecord {

        return {
            found: true,
            removed: true,
            message:
                "Booking found in removed booking history",
            booking: {},
            removed_booking:
                toProtoRemovedBooking(removed)
        };
    }


    return {
        found: false,
        removed: false,

        message: string
            `Booking '${request.booking_id}' not found`,

        booking: {},
        removed_booking: {}
    };
}


// ============================================================================
// REMOVE BOOKING
// ============================================================================

function removeBooking(
    RemoveBookingRequest request
) returns RemoveBookingResponse|error {

    if request.booking_id.trim().length() == 0 {

        return {
            success: false,
            message: "booking_id is required",
            removed_booking: {}
        };
    }


    string reason =
        request.reason.trim().length() > 0
        ? request.reason
        : "No reason supplied";


    RemovedBookingRecord? removed =
        check archiveAndDeleteBooking(
            request.booking_id,
            reason
        );


    if removed is () {

        return {
            success: false,

            message: string
                `Active booking '${request.booking_id}' not found`,

            removed_booking: {}
        };
    }


    return {
        success: true,

        message: string
            `Booking '${request.booking_id}' removed and archived`,

        removed_booking:
            toProtoRemovedBooking(removed)
    };
}


// ============================================================================
// LIST REMOVED BOOKINGS
// ============================================================================

function collectRemovedBookings(
    ListRemovedBookingsRequest request
) returns RemovedBooking[]|error {

    RemovedBookingRecord[] records =
        check listRemovedBookingRecords(
            request.guest_id,
            request.property_id
        );


    RemovedBooking[] removedBookings = [];


    foreach RemovedBookingRecord removed
        in records {

        removedBookings.push(
            toProtoRemovedBooking(removed)
        );
    }


    return removedBookings;
}



