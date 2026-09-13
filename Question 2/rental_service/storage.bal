import ballerina/sql;


// ============================================================================
// DATABASE ROW TYPES
// ============================================================================
//
// These records represent rows returned by PostgreSQL.
//
// PostgreSQL uses snake_case column names while the domain records in
// types.bal use camelCase. Conversion functions below keep the SQL details
// isolated inside this repository layer.
// ============================================================================

type UserDbRow record {|
    int id;
    string user_id;
    string name;
    string email;
    string role;
    string region;
|};


type PropertyDbRow record {|
    int id;
    string property_id;
    string host_id;
    string name;
    string location;
    string region;
    string property_type;
    decimal price_per_night;
    string status;
    string description;
|};


type CartDbRow record {|
    int id;
    string cart_id;
    string guest_id;
    string property_id;
    string check_in;
    string check_out;
|};


type BookingDbRow record {|
    int id;
    string booking_id;
    string property_id;
    string guest_id;
    string check_in;
    string check_out;
    decimal total_cost;
    string status;
|};


type RemovedBookingDbRow record {|
    int id;
    string booking_id;
    string property_id;
    string guest_id;
    string check_in;
    string check_out;
    decimal total_cost;
    string status;
    string reason;
    string removed_at;
|};


// ============================================================================
// ID FORMATTING
// ============================================================================
//
// PostgreSQL owns the numeric primary keys.
//
// Ballerina simply converts:
//
// 1 -> USR-0001
// 2 -> USR-0002
//
// etc.
// ============================================================================

function formattedId(
    string prefix,
    int number
) returns string {

    return string `${prefix}-${number.toString().padStart(4, "0")}`;
}


// ============================================================================
// DATABASE ROW -> DOMAIN RECORD CONVERSIONS
// ============================================================================

function userFromDb(
    UserDbRow row
) returns UserRecord {

    return {
        userId: row.user_id,
        name: row.name,
        email: row.email,
        role: row.role,
        region: row.region
    };
}


function propertyFromDb(
    PropertyDbRow row
) returns PropertyRecord {

    return {
        propertyId: row.property_id,
        hostId: row.host_id,
        name: row.name,
        location: row.location,
        region: row.region,
        propertyType: row.property_type,
        pricePerNight: row.price_per_night,
        status: row.status,
        description: row.description
    };
}


function cartFromDb(
    CartDbRow row
) returns CartItem {

    return {
        cartId: row.cart_id,
        guestId: row.guest_id,
        propertyId: row.property_id,
        checkIn: row.check_in,
        checkOut: row.check_out
    };
}


function bookingFromDb(
    BookingDbRow row
) returns BookingRecord {

    return {
        bookingId: row.booking_id,
        propertyId: row.property_id,
        guestId: row.guest_id,
        checkIn: row.check_in,
        checkOut: row.check_out,
        totalCost: row.total_cost,
        status: row.status
    };
}


function removedBookingFromDb(
    RemovedBookingDbRow row
) returns RemovedBookingRecord {

    return {
        bookingId: row.booking_id,
        propertyId: row.property_id,
        guestId: row.guest_id,
        checkIn: row.check_in,
        checkOut: row.check_out,
        totalCost: row.total_cost,
        status: row.status,
        reason: row.reason,
        removedAt: row.removed_at
    };
}


// ============================================================================
// USER REPOSITORY
// ============================================================================

function getUser(
    string userId
) returns UserRecord?|error {

    UserDbRow|sql:Error result = db->queryRow(
        `SELECT
            id,
            user_id,
            name,
            email,
            role,
            region
         FROM users
         WHERE user_id = ${userId}`
    );

    if result is sql:NoRowsError {
        return ();
    }

    if result is error {
        return result;
    }

    return userFromDb(result);
}


// ----------------------------------------------------------------------------
// Insert User
// ----------------------------------------------------------------------------
//
// PostgreSQL generates the numeric ID first.
//
// That value is then formatted into:
//
// USR-0001
// USR-0002
// ...
// ----------------------------------------------------------------------------

function insertUser(
    string name,
    string email,
    string role,
    string region
) returns UserRecord|error {

    int databaseId = check db->queryRow(
        `INSERT INTO users (
            name,
            email,
            role,
            region
         )
         VALUES (
            ${name},
            ${email},
            ${role},
            ${region}
         )
         RETURNING id`
    );

    string userId =
        formattedId("USR", databaseId);

    _ = check db->execute(
        `UPDATE users
         SET user_id = ${userId}
         WHERE id = ${databaseId}`
    );

    return {
        userId: userId,
        name: name,
        email: email,
        role: role,
        region: region
    };
}


// ----------------------------------------------------------------------------
// List Users
// ----------------------------------------------------------------------------
//
// role == ""
//      -> all users
//
// role == "HOST"
//      -> hosts only
//
// role == "GUEST"
//      -> guests only
// ----------------------------------------------------------------------------

function listUserRecords(
    string role
) returns UserRecord[]|error {

    UserRecord[] users = [];

    stream<UserDbRow, sql:Error?> rows = db->query(
        `SELECT
            id,
            user_id,
            name,
            email,
            role,
            region
         FROM users
         WHERE (
            ${role} = ''
            OR role = ${role}
         )
         ORDER BY id`
    );

    error? queryError =
        from UserDbRow row in rows
        do {
            users.push(
                userFromDb(row)
            );
        };

    if queryError is error {
        return queryError;
    }

    return users;
}


// ============================================================================
// PROPERTY REPOSITORY
// ============================================================================

function getProperty(
    string propertyId
) returns PropertyRecord?|error {

    PropertyDbRow|sql:Error result = db->queryRow(
        `SELECT
            id,
            property_id,
            host_id,
            name,
            location,
            region,
            property_type,
            price_per_night,
            status,
            description
         FROM properties
         WHERE property_id = ${propertyId}`
    );

    if result is sql:NoRowsError {
        return ();
    }

    if result is error {
        return result;
    }

    return propertyFromDb(result);
}


// ----------------------------------------------------------------------------
// Insert Property
// ----------------------------------------------------------------------------

function insertProperty(
    string hostId,
    string name,
    string location,
    string region,
    string propertyType,
    decimal pricePerNight,
    string description
) returns PropertyRecord|error {

    int databaseId = check db->queryRow(
        `INSERT INTO properties (
            host_id,
            name,
            location,
            region,
            property_type,
            price_per_night,
            status,
            description
         )
         VALUES (
            ${hostId},
            ${name},
            ${location},
            ${region},
            ${propertyType},
            ${pricePerNight},
            'AVAILABLE',
            ${description}
         )
         RETURNING id`
    );

    string propertyId =
        formattedId("PROP", databaseId);

    _ = check db->execute(
        `UPDATE properties
         SET property_id = ${propertyId}
         WHERE id = ${databaseId}`
    );

    return {
        propertyId: propertyId,
        hostId: hostId,
        name: name,
        location: location,
        region: region,
        propertyType: propertyType,
        pricePerNight: pricePerNight,
        status: "AVAILABLE",
        description: description
    };
}


// ----------------------------------------------------------------------------
// Update Property
// ----------------------------------------------------------------------------

function updatePropertyRecord(
    PropertyRecord property
) returns error? {

    _ = check db->execute(
        `UPDATE properties
         SET
            price_per_night = ${property.pricePerNight},
            status = ${property.status},
            description = ${property.description}
         WHERE property_id = ${property.propertyId}`
    );

    return;
}


// ----------------------------------------------------------------------------
// Delete Property
// ----------------------------------------------------------------------------

function deletePropertyRecord(
    string propertyId
) returns error? {

    _ = check db->execute(
        `DELETE FROM properties
         WHERE property_id = ${propertyId}`
    );

    return;
}


// ----------------------------------------------------------------------------
// List Available Properties
// ----------------------------------------------------------------------------

function listAvailablePropertyRecords(
    string locationFilter,
    float minPrice,
    float maxPrice
) returns PropertyRecord[]|error {

    PropertyRecord[] properties = [];

    stream<PropertyDbRow, sql:Error?> rows = db->query(
        `SELECT
            id,
            property_id,
            host_id,
            name,
            location,
            region,
            property_type,
            price_per_night,
            status,
            description
         FROM properties
         WHERE status = 'AVAILABLE'

           AND (
                ${locationFilter} = ''
                OR LOWER(location)
                   LIKE LOWER('%' || ${locationFilter} || '%')
           )

           AND (
                ${minPrice} <= 0
                OR price_per_night >= ${minPrice}
           )

           AND (
                ${maxPrice} <= 0
                OR price_per_night <= ${maxPrice}
           )

         ORDER BY id`
    );

    error? queryError =
        from PropertyDbRow row in rows
        do {
            properties.push(
                propertyFromDb(row)
            );
        };

    if queryError is error {
        return queryError;
    }

    return properties;
}


// ----------------------------------------------------------------------------
// Available Properties in Region
// ----------------------------------------------------------------------------

function listAvailablePropertiesInRegion(
    string region
) returns PropertyRecord[]|error {

    PropertyRecord[] properties = [];

    stream<PropertyDbRow, sql:Error?> rows = db->query(
        `SELECT
            id,
            property_id,
            host_id,
            name,
            location,
            region,
            property_type,
            price_per_night,
            status,
            description
         FROM properties
         WHERE region = ${region}
           AND status = 'AVAILABLE'
         ORDER BY id`
    );

    error? queryError =
        from PropertyDbRow row in rows
        do {
            properties.push(
                propertyFromDb(row)
            );
        };

    if queryError is error {
        return queryError;
    }

    return properties;
}


// ============================================================================
// CART REPOSITORY
// ============================================================================

function insertCartItem(
    string guestId,
    string propertyId,
    string checkIn,
    string checkOut
) returns CartItem|error {

    int databaseId = check db->queryRow(
        `INSERT INTO cart_items (
            guest_id,
            property_id,
            check_in,
            check_out
         )
         VALUES (
            ${guestId},
            ${propertyId},
            CAST(${checkIn} AS DATE),
            CAST(${checkOut} AS DATE)
         )
         RETURNING id`
    );

    string cartId =
        formattedId("CART", databaseId);

    _ = check db->execute(
        `UPDATE cart_items
         SET cart_id = ${cartId}
         WHERE id = ${databaseId}`
    );

    return {
        cartId: cartId,
        guestId: guestId,
        propertyId: propertyId,
        checkIn: checkIn,
        checkOut: checkOut
    };
}


function getCartItem(
    string cartId
) returns CartItem?|error {

    CartDbRow|sql:Error result = db->queryRow(
        `SELECT
            id,
            cart_id,
            guest_id,
            property_id,
            check_in::text AS check_in,
            check_out::text AS check_out
         FROM cart_items
         WHERE cart_id = ${cartId}`
    );

    if result is sql:NoRowsError {
        return ();
    }

    if result is error {
        return result;
    }

    return cartFromDb(result);
}


function deleteCartItem(
    string cartId
) returns error? {

    _ = check db->execute(
        `DELETE FROM cart_items
         WHERE cart_id = ${cartId}`
    );

    return;
}


// ============================================================================
// BOOKING REPOSITORY
// ============================================================================

function hasOverlappingBooking(
    string propertyId,
    string checkIn,
    string checkOut
) returns boolean|error {

    int count = check db->queryRow(
        `SELECT COUNT(*)
         FROM bookings
         WHERE property_id = ${propertyId}
           AND status = 'CONFIRMED'
           AND check_in < CAST(${checkOut} AS DATE)
           AND check_out > CAST(${checkIn} AS DATE)`
    );

    return count > 0;
}


// ----------------------------------------------------------------------------
// Insert Booking
// ----------------------------------------------------------------------------

function insertBooking(
    string propertyId,
    string guestId,
    string checkIn,
    string checkOut,
    decimal totalCost,
    string status
) returns BookingRecord|error {

    int databaseId = check db->queryRow(
        `INSERT INTO bookings (
            property_id,
            guest_id,
            check_in,
            check_out,
            total_cost,
            status
         )
         VALUES (
            ${propertyId},
            ${guestId},
            CAST(${checkIn} AS DATE),
            CAST(${checkOut} AS DATE),
            ${totalCost},
            ${status}
         )
         RETURNING id`
    );

    string bookingId =
        formattedId("BKG", databaseId);

    _ = check db->execute(
        `UPDATE bookings
         SET booking_id = ${bookingId}
         WHERE id = ${databaseId}`
    );

    return {
        bookingId: bookingId,
        propertyId: propertyId,
        guestId: guestId,
        checkIn: checkIn,
        checkOut: checkOut,
        totalCost: totalCost,
        status: status
    };
}


// ----------------------------------------------------------------------------
// Get Active Booking
// ----------------------------------------------------------------------------

function getBooking(
    string bookingId
) returns BookingRecord?|error {

    BookingDbRow|sql:Error result = db->queryRow(
        `SELECT
            id,
            booking_id,
            property_id,
            guest_id,
            check_in::text AS check_in,
            check_out::text AS check_out,
            total_cost,
            status
         FROM bookings
         WHERE booking_id = ${bookingId}`
    );

    if result is sql:NoRowsError {
        return ();
    }

    if result is error {
        return result;
    }

    return bookingFromDb(result);
}


// ----------------------------------------------------------------------------
// List Active Bookings
// ----------------------------------------------------------------------------

function listBookingRecords(
    string guestId,
    string propertyId
) returns BookingRecord[]|error {

    BookingRecord[] bookings = [];

    stream<BookingDbRow, sql:Error?> rows = db->query(
        `SELECT
            id,
            booking_id,
            property_id,
            guest_id,
            check_in::text AS check_in,
            check_out::text AS check_out,
            total_cost,
            status
         FROM bookings
         WHERE (
            ${guestId} = ''
            OR guest_id = ${guestId}
         )
         AND (
            ${propertyId} = ''
            OR property_id = ${propertyId}
         )
         ORDER BY id`
    );

    error? queryError =
        from BookingDbRow row in rows
        do {
            bookings.push(
                bookingFromDb(row)
            );
        };

    if queryError is error {
        return queryError;
    }

    return bookings;
}


// ============================================================================
// REMOVED BOOKING REPOSITORY
// ============================================================================
//
// Removal is implemented as:
//
// Active booking
//      ↓
// Copy into removed_bookings
//      ↓
// Delete from bookings
//
// This preserves booking history.
// ============================================================================

function archiveAndDeleteBooking(
    string bookingId,
    string reason
) returns RemovedBookingRecord?|error {

    BookingRecord? existing =
        check getBooking(bookingId);

    if existing is () {
        return ();
    }

    BookingRecord booking = existing;

    // -----------------------------------------------------------------------
    // Archive the original booking before deleting it.
    // -----------------------------------------------------------------------

    _ = check db->execute(
        `INSERT INTO removed_bookings (
            booking_id,
            property_id,
            guest_id,
            check_in,
            check_out,
            total_cost,
            status,
            reason
         )
         VALUES (
            ${booking.bookingId},
            ${booking.propertyId},
            ${booking.guestId},
            CAST(${booking.checkIn} AS DATE),
            CAST(${booking.checkOut} AS DATE),
            ${booking.totalCost},
            'CANCELLED',
            ${reason}
         )`
    );

    // -----------------------------------------------------------------------
    // Remove from active bookings only after the archive succeeds.
    // -----------------------------------------------------------------------

    _ = check db->execute(
        `DELETE FROM bookings
         WHERE booking_id = ${bookingId}`
    );

    return check getRemovedBooking(bookingId);
}


// ----------------------------------------------------------------------------
// Get Removed Booking
// ----------------------------------------------------------------------------

function getRemovedBooking(
    string bookingId
) returns RemovedBookingRecord?|error {

    RemovedBookingDbRow|sql:Error result = db->queryRow(
        `SELECT
            id,
            booking_id,
            property_id,
            guest_id,
            check_in::text AS check_in,
            check_out::text AS check_out,
            total_cost,
            status,
            reason,
            removed_at::text AS removed_at
         FROM removed_bookings
         WHERE booking_id = ${bookingId}`
    );

    if result is sql:NoRowsError {
        return ();
    }

    if result is error {
        return result;
    }

    return removedBookingFromDb(result);
}


// ----------------------------------------------------------------------------
// List Removed Bookings
// ----------------------------------------------------------------------------

function listRemovedBookingRecords(
    string guestId,
    string propertyId
) returns RemovedBookingRecord[]|error {

    RemovedBookingRecord[] removedBookings = [];

    stream<RemovedBookingDbRow, sql:Error?> rows = db->query(
        `SELECT
            id,
            booking_id,
            property_id,
            guest_id,
            check_in::text AS check_in,
            check_out::text AS check_out,
            total_cost,
            status,
            reason,
            removed_at::text AS removed_at
         FROM removed_bookings
         WHERE (
            ${guestId} = ''
            OR guest_id = ${guestId}
         )
         AND (
            ${propertyId} = ''
            OR property_id = ${propertyId}
         )
         ORDER BY id`
    );

    error? queryError =
        from RemovedBookingDbRow row in rows
        do {
            removedBookings.push(
                removedBookingFromDb(row)
            );
        };

    if queryError is error {
        return queryError;
    }

    return removedBookings;
}


