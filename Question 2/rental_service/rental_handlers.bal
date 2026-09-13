import ballerina/lang.'int as ints;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function rangesOverlap(string aStart, string aEnd, string bStart, string bEnd) returns boolean {
    return aStart < bEnd && bStart < aEnd;
}

function isPropertyFreeFor(string propertyId, string checkIn, string checkOut) returns boolean {
    foreach BookingRecord b in bookingsTable {
        if b.propertyId == propertyId && b.status == "CONFIRMED" {
            if rangesOverlap(b.checkIn, b.checkOut, checkIn, checkOut) {
                return false;
            }
        }
    }
    return true;
}

function daysFromCivil(int y, int m, int d) returns int {
    int yy = y - (m <= 2 ? 1 : 0);
    int era = (yy >= 0 ? yy : yy - 399) / 400;
    int yoe = yy - era * 400;
    int doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    int doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

function nightsBetween(string checkIn, string checkOut) returns int {
    int|error y1 = ints:fromString(checkIn.substring(0, 4));
    int|error m1 = ints:fromString(checkIn.substring(5, 7));
    int|error d1 = ints:fromString(checkIn.substring(8, 10));
    int|error y2 = ints:fromString(checkOut.substring(0, 4));
    int|error m2 = ints:fromString(checkOut.substring(5, 7));
    int|error d2 = ints:fromString(checkOut.substring(8, 10));

    if y1 is error || m1 is error || d1 is error
       || y2 is error || m2 is error || d2 is error {
        return 0;
    }
    return daysFromCivil(y2, m2, d2) - daysFromCivil(y1, m1, d1);
}

// NOTE: If rental_pb.bal declares the enum variants with a prefix
// (e.g. PROPERTY_STATUS_AVAILABLE), rename the identifiers below to match.
function statusToProto(string s) returns PropertyStatus {
    match s {
        "AVAILABLE"         =>{ return AVAILABLE; }
        "BOOKED"            =>{ return BOOKED; }
        "UNDER_MAINTENANCE" =>{ return UNDER_MAINTENANCE; }
        "DELISTED"          =>{ return DELISTED; }
        _                   =>{ return PROPERTY_STATUS_UNSPECIFIED; }
    }
}

function protoToStatus(PropertyStatus s) returns string {
    match s {
        AVAILABLE         =>{ return "AVAILABLE"; }
        BOOKED            =>{ return "BOOKED"; }
        UNDER_MAINTENANCE =>{ return "UNDER_MAINTENANCE"; }
        DELISTED          =>{ return "DELISTED"; }
        _                 =>{ return "AVAILABLE"; }
    }
}

function toProtoProperty(PropertyRecord p) returns Property {
    return {
        property_id: p.propertyId,
        host_id: p.hostId,
        name: p.name,
        location: p.location,
        region: p.region,
        property_type: p.propertyType,
        price_per_night: <float>p.pricePerNight,
        status: statusToProto(p.status),
        description: p.description
    };
}

// ---------------------------------------------------------------------------
// AddProperty
// ---------------------------------------------------------------------------

function addProperty(AddPropertyRequest req) returns AddPropertyResponse {
    if req.name.trim().length() == 0 {
        return {property_id: "", success: false, message: "name is required"};
    }
    if req.host_id.trim().length() == 0 {
        return {property_id: "", success: false, message: "host_id is required"};
    }
    if req.price_per_night <= 0.0 {
        return {property_id: "", success: false, message: "price_per_night must be > 0"};
    }
    if !usersTable.hasKey(req.host_id) {
        return {property_id: "", success: false,
                message: string `Host '${req.host_id}' not registered`};
    }

    string id = nextPropertyId();
    PropertyRecord p = {
        propertyId: id,
        hostId: req.host_id,
        name: req.name,
        location: req.location,
        region: req.region,
        propertyType: req.property_type,
        pricePerNight: <decimal>req.price_per_night,
        status: "AVAILABLE",
        description: req.description
    };
    propertiesTable.add(p);
    return {property_id: id, success: true,
            message: string `Property '${req.name}' registered`};
}

// ---------------------------------------------------------------------------
// CreateUsers helper
// ---------------------------------------------------------------------------

function registerUser(User u) returns UserRecord|ServiceError {
    if u.name.trim().length() == 0 {
        return {message: "user name is required"};
    }
    if u.email.trim().length() == 0 {
        return {message: "user email is required"};
    }
    string id = u.user_id.trim().length() > 0 ? u.user_id : nextUserId();
    if usersTable.hasKey(id) {
        return {message: string `User '${id}' already exists`};
    }
    // NOTE: If the generated enum uses USER_ROLE_HOST, use that name here.
    UserRecord rec = {
        userId: id,
        name: u.name,
        email: u.email,
        role: u.role == HOST ? "HOST" : "GUEST",
        region: u.region
    };
    usersTable.add(rec);
    return rec;
}

// ---------------------------------------------------------------------------
// UpdateProperty — nullable proto fields narrowed via locals
// ---------------------------------------------------------------------------

function updateProperty(UpdatePropertyRequest req) returns UpdatePropertyResponse {
    PropertyRecord? existing = propertiesTable[req.property_id];
    if existing is () {
        return {success: false,
                message: string `Property '${req.property_id}' not found`,
                property: {}};
    }
    PropertyRecord p = existing;

    if req.price_per_night is float {
        if req.price_per_night <= 0.0 {
            return {success: false, message: "price_per_night must be > 0", property: {}};
        }
        p.pricePerNight = <decimal>req.price_per_night;
    }

    PropertyStatus? s = req.status;
    if s is PropertyStatus && s != PROPERTY_STATUS_UNSPECIFIED {
        p.status = protoToStatus(s);
    }

    string? d = req.description;
    if d is string {
        p.description = d;
    }

    propertiesTable.put(p);
    return {success: true, message: "Property updated", property: toProtoProperty(p)};
}

// ---------------------------------------------------------------------------
// RemoveProperty
// ---------------------------------------------------------------------------

function removeProperty(RemovePropertyRequest req) returns RemovePropertyResponse {
    PropertyRecord? existing = propertiesTable[req.property_id];
    if existing is () {
        return {success: false,
                message: string `Property '${req.property_id}' not found`,
                remaining_properties: []};
    }
    string region = existing.region;
    _ = propertiesTable.remove(req.property_id);

    Property[] remaining = [];
    foreach PropertyRecord p in propertiesTable {
        if p.region == region && p.status == "AVAILABLE" {
            remaining.push(toProtoProperty(p));
        }
    }
    return {
        success: true,
        message: string `Property removed. ${remaining.length()} remaining in region '${region}'.`,
        remaining_properties: remaining
    };
}

// ---------------------------------------------------------------------------
// ListAvailableProperties helper
// ---------------------------------------------------------------------------

function collectAvailable(ListAvailableRequest req) returns PropertyRecord[] {
    PropertyRecord[] out = [];
    foreach PropertyRecord p in propertiesTable {
        if p.status != "AVAILABLE" {
            continue;
        }
        if req.location_filter.trim().length() > 0
           && !p.location.toLowerAscii().includes(req.location_filter.toLowerAscii()) {
            continue;
        }
        if req.min_price > 0.0 && <float>p.pricePerNight < req.min_price {
            continue;
        }
        if req.max_price > 0.0 && <float>p.pricePerNight > req.max_price {
            continue;
        }
        out.push(p);
    }
    return out;
}

// ---------------------------------------------------------------------------
// SearchProperty
// ---------------------------------------------------------------------------

function searchProperty(SearchPropertyRequest req) returns SearchPropertyResponse {
    PropertyRecord? p = propertiesTable[req.property_id];
    if p is () {
        return {available: false, message: "Not Available", property: {}};
    }
    if p.status != "AVAILABLE" {
        return {
            available: false,
            message: string `Not Available (current status: ${p.status})`,
            property: toProtoProperty(p)
        };
    }
    return {available: true, message: "Available", property: toProtoProperty(p)};
}

// ---------------------------------------------------------------------------
// BookProperty
// ---------------------------------------------------------------------------

function bookProperty(BookPropertyRequest req) returns BookPropertyResponse {
    if req.guest_id.trim().length() == 0 {
        return {success: false, message: "guest_id is required",
                cart_id: "", estimated_cost: 0.0};
    }
    if req.dates.check_in.trim().length() == 0 || req.dates.check_out.trim().length() == 0 {
        return {success: false, message: "check_in and check_out are required",
                cart_id: "", estimated_cost: 0.0};
    }
    if req.dates.check_in >= req.dates.check_out {
        return {success: false, message: "check_out must be after check_in",
                cart_id: "", estimated_cost: 0.0};
    }
    if req.dates.check_in < todayIso() {
        return {success: false, message: "check_in must not be in the past",
                cart_id: "", estimated_cost: 0.0};
    }
    PropertyRecord? p = propertiesTable[req.property_id];
    if p is () {
        return {success: false, message: string `Property '${req.property_id}' not found`,
                cart_id: "", estimated_cost: 0.0};
    }
    if p.status != "AVAILABLE" {
        return {success: false,
                message: string `Property not available (status: ${p.status})`,
                cart_id: "", estimated_cost: 0.0};
    }

    int nights = nightsBetween(req.dates.check_in, req.dates.check_out);
    decimal estimate = p.pricePerNight * <decimal>nights;

    string cartId = nextCartId();
    cartTable.add({
        cartId: cartId,
        guestId: req.guest_id,
        propertyId: req.property_id,
        checkIn: req.dates.check_in,
        checkOut: req.dates.check_out
    });
    return {
        success: true,
        message: string `Added to cart. ${nights} night(s).`,
        cart_id: cartId,
        estimated_cost: <float>estimate
    };
}

// ---------------------------------------------------------------------------
// ConfirmBooking
// ---------------------------------------------------------------------------

function confirmBooking(ConfirmBookingRequest req) returns ConfirmBookingResponse {
    CartItem? item = cartTable[req.cart_id];
    if item is () {
        return {success: false,
                message: string `Cart '${req.cart_id}' not found`,
                booking: {}};
    }
    if item.guestId != req.guest_id {
        return {success: false,
                message: "Cart does not belong to this guest",
                booking: {}};
    }
    PropertyRecord? p = propertiesTable[item.propertyId];
    if p is () {
        return {success: false, message: "Property no longer exists", booking: {}};
    }
    if !isPropertyFreeFor(item.propertyId, item.checkIn, item.checkOut) {
        return {success: false,
                message: "Property is no longer available for the requested dates",
                booking: {}};
    }

    int nights = nightsBetween(item.checkIn, item.checkOut);
    decimal total = p.pricePerNight * <decimal>nights;

    string bookingId = nextBookingId();
    BookingRecord rec = {
        bookingId: bookingId,
        propertyId: item.propertyId,
        guestId: item.guestId,
        checkIn: item.checkIn,
        checkOut: item.checkOut,
        totalCost: total,
        status: "CONFIRMED"
    };
    bookingsTable.add(rec);
    _ = cartTable.remove(req.cart_id);

    return {
        success: true,
        message: string `Booking confirmed. Total cost: ${total.toString()} for ${nights} night(s).`,
        booking: {
            booking_id: bookingId,
            property_id: item.propertyId,
            guest_id: item.guestId,
            dates: {check_in: item.checkIn, check_out: item.checkOut},
            total_cost: <float>total,
            status: "CONFIRMED"
        }
    };
}

