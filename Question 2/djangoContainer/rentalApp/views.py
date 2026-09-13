import grpc

from django.contrib import messages
from django.shortcuts import render, redirect

from .grpc_generated import rental_pb2

from .grpc_client import (
    # Users
    create_users,
    list_users,
    search_user,

    # Properties
    add_property,
    list_available_properties,
    search_property,
    update_property,
    remove_property,

    # Bookings
    book_property,
    confirm_booking,
    list_bookings,
    search_booking,
    remove_booking,
    list_removed_bookings,
)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def grpc_error_message(exc):
    """
    Return a user-friendly message for gRPC or connection errors.
    """

    if isinstance(exc, grpc.RpcError):
        return exc.details() or str(exc)

    return str(exc)


def user_role_name(role):
    """
    Convert the protobuf UserRole enum into a readable string.
    """

    try:
        return rental_pb2.UserRole.Name(role)
    except Exception:
        return "UNKNOWN"


def property_status_name(status):
    """
    Convert the protobuf PropertyStatus enum into a readable string.
    """

    try:
        return rental_pb2.PropertyStatus.Name(status)
    except Exception:
        return "UNKNOWN"


def proto_user_to_dict(user):
    """
    Convert a protobuf User into a normal Python dictionary.
    """

    return {
        "user_id": user.user_id,
        "name": user.name,
        "email": user.email,
        "role": user_role_name(user.role),
        "region": user.region,
    }


def proto_property_to_dict(property_obj):
    """
    Convert a protobuf Property into a dictionary.

    This keeps protobuf objects out of the templates and makes the
    Django templates easier to work with.
    """

    return {
        "property_id": property_obj.property_id,
        "host_id": property_obj.host_id,
        "name": property_obj.name,
        "location": property_obj.location,
        "region": property_obj.region,
        "property_type": property_obj.property_type,
        "price_per_night": property_obj.price_per_night,
        "status": property_status_name(property_obj.status),
        "description": property_obj.description,
    }


def proto_booking_to_dict(booking):
    """
    Convert protobuf Booking into a normal dictionary.
    """

    return {
        "booking_id": booking.booking_id,
        "property_id": booking.property_id,
        "guest_id": booking.guest_id,
        "check_in": booking.dates.check_in,
        "check_out": booking.dates.check_out,
        "total_cost": booking.total_cost,
        "status": booking.status,
    }


def get_hosts():
    """
    Retrieve hosts from Ballerina.

    Used by the Add Property form so that the user selects a host
    instead of manually entering USR-0001, USR-0002, etc.
    """

    hosts = []

    stream = list_users("HOST")

    for user in stream:
        hosts.append(
            proto_user_to_dict(user)
        )

    return hosts


def get_guests():
    """
    Retrieve guests from Ballerina.

    Used by the Book Property form.
    """

    guests = []

    stream = list_users("GUEST")

    for user in stream:
        guests.append(
            proto_user_to_dict(user)
        )

    return guests


def get_available_properties():
    """
    Retrieve all currently available properties.
    """

    properties = []

    stream = list_available_properties()

    for property_obj in stream:
        properties.append(
            proto_property_to_dict(property_obj)
        )

    return properties


# =============================================================================
# DASHBOARD
# =============================================================================

def dashboard(request):
    """
    Main Rental System dashboard.

    No gRPC request is needed just to display the dashboard.
    """

    return render(
        request,
        "rentalApp/dashboard.html",
    )


# =============================================================================
# USER MANAGEMENT
# =============================================================================


# -----------------------------------------------------------------------------
# CREATE USERS
# -----------------------------------------------------------------------------

def user_create(request):
    """
    Create one or more users using the CreateUsers client-streaming RPC.

    IMPORTANT:
    Django does NOT create the user ID.

    The form sends:
        name
        email
        role
        region

    Ballerina/PostgreSQL creates IDs such as:
        USR-0001
        USR-0002
        USR-0003
    """

    response_data = None

    if request.method == "POST":

        users = []

        try:
            user_count = int(
                request.POST.get(
                    "user_count",
                    "1"
                )
            )
        except ValueError:
            user_count = 1


        # ---------------------------------------------------------------------
        # Build the list of users from the dynamic form fields.
        # ---------------------------------------------------------------------

        for number in range(
            1,
            user_count + 1
        ):

            name = request.POST.get(
                f"name_{number}",
                ""
            ).strip()

            email = request.POST.get(
                f"email_{number}",
                ""
            ).strip()

            role = request.POST.get(
                f"role_{number}",
                ""
            ).strip()

            region = request.POST.get(
                f"region_{number}",
                ""
            ).strip()


            # Ignore completely empty rows.
            if not name and not email and not role:
                continue


            if not name or not email or not role:

                messages.error(
                    request,
                    f"User {number} is incomplete."
                )

                continue


            users.append({
                "name": name,
                "email": email,
                "role": role,
                "region": region,
            })


        if not users:

            messages.error(
                request,
                "Please enter at least one complete user."
            )

        else:

            try:

                response = create_users(
                    users
                )


                response_data = {
                    "created_count":
                        response.created_count,

                    "message":
                        response.message,

                    "created_users": [
                        proto_user_to_dict(user)
                        for user
                        in response.created_users
                    ],
                }


                if response.created_count > 0:

                    messages.success(
                        request,
                        response.message
                    )

                else:

                    messages.warning(
                        request,
                        response.message
                    )


            except (
                grpc.RpcError,
                ConnectionError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/create_users.html",
        {
            "response": response_data
        },
    )


# -----------------------------------------------------------------------------
# LIST USERS
# -----------------------------------------------------------------------------

def user_list(request):
    """
    List users using server-side streaming.

    Supported filters:
        all users
        hosts
        guests
    """

    role = request.GET.get(
        "role",
        ""
    ).strip().upper()

    users = []

    error = None


    # Only allow the expected filters.
    if role not in (
        "",
        "HOST",
        "GUEST"
    ):
        role = ""


    try:

        stream = list_users(
            role
        )


        for user in stream:

            users.append(
                proto_user_to_dict(
                    user
                )
            )


    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        error = grpc_error_message(
            exc
        )


    return render(
        request,
        "rentalApp/user_list.html",
        {
            "users": users,
            "role": role,
            "error": error,
        },
    )


# -----------------------------------------------------------------------------
# SEARCH USER
# -----------------------------------------------------------------------------

def user_search(request):
    """
    Search for one user using their generated user ID.

    The ID is not created in this form. This page searches for an
    already existing ID.
    """

    user_id = request.GET.get(
        "user_id",
        ""
    ).strip()

    searched = False
    result = None


    if user_id:

        searched = True

        try:

            response = search_user(
                user_id
            )


            if response.found:

                result = {
                    "found": True,
                    "message": response.message,
                    **proto_user_to_dict(
                        response.user
                    ),
                }

            else:

                result = {
                    "found": False,
                    "message": response.message,
                }


        except (
            grpc.RpcError,
            ConnectionError
        ) as exc:

            result = {
                "found": False,
                "message": grpc_error_message(
                    exc
                ),
            }


    return render(
        request,
        "rentalApp/search_user.html",
        {
            "user_id": user_id,
            "searched": searched,
            "result": result,
        },
    )


# =============================================================================
# PROPERTY MANAGEMENT
# =============================================================================


# -----------------------------------------------------------------------------
# LIST AVAILABLE PROPERTIES
# -----------------------------------------------------------------------------

def property_list(request):
    """
    List/filter available properties.

    All data is retrieved from Ballerina through gRPC.
    Django does not query PostgreSQL directly.
    """

    location_filter = request.GET.get(
        "location",
        ""
    ).strip()

    min_price_text = request.GET.get(
        "min_price",
        ""
    ).strip()

    max_price_text = request.GET.get(
        "max_price",
        ""
    ).strip()


    try:
        min_price = (
            float(min_price_text)
            if min_price_text
            else 0.0
        )
    except ValueError:
        min_price = 0.0


    try:
        max_price = (
            float(max_price_text)
            if max_price_text
            else 0.0
        )
    except ValueError:
        max_price = 0.0


    properties = []

    error = None


    try:

        stream = list_available_properties(
            location_filter=location_filter,
            min_price=min_price,
            max_price=max_price,
        )


        for property_obj in stream:

            properties.append(
                proto_property_to_dict(
                    property_obj
                )
            )


    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        error = grpc_error_message(
            exc
        )


    return render(
        request,
        "rentalApp/property_list.html",
        {
            "properties": properties,

            "location_filter":
                location_filter,

            "min_price":
                min_price_text,

            "max_price":
                max_price_text,

            "error":
                error,
        },
    )


# -----------------------------------------------------------------------------
# ADD PROPERTY
# -----------------------------------------------------------------------------

def property_create(request):
    """
    Add a new property.

    The user does NOT enter:
        property_id

    Instead:
        - host is selected from registered HOST users
        - Ballerina generates the property ID automatically
    """

    hosts = []


    try:

        hosts = get_hosts()

    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        messages.error(
            request,
            "Unable to load hosts: "
            + grpc_error_message(exc)
        )


    if request.method == "POST":

        host_id = request.POST.get(
            "host_id",
            ""
        ).strip()

        name = request.POST.get(
            "name",
            ""
        ).strip()

        location = request.POST.get(
            "location",
            ""
        ).strip()

        region = request.POST.get(
            "region",
            ""
        ).strip()

        property_type = request.POST.get(
            "property_type",
            ""
        ).strip()

        price_per_night = request.POST.get(
            "price_per_night",
            ""
        ).strip()

        description = request.POST.get(
            "description",
            ""
        ).strip()


        if not all([
            host_id,
            name,
            location,
            region,
            property_type,
            price_per_night,
        ]):

            messages.error(
                request,
                "Please complete all required property fields."
            )

        else:

            try:

                response = add_property(
                    host_id=host_id,
                    name=name,
                    location=location,
                    region=region,
                    property_type=property_type,
                    price_per_night=price_per_night,
                    description=description,
                )


                if response.success:

                    messages.success(
                        request,
                        (
                            "Property created successfully. "
                            f"Generated Property ID: "
                            f"{response.property_id}"
                        )
                    )

                    return redirect(
                        "rentalApp:property_list"
                    )


                messages.error(
                    request,
                    response.message
                )


            except (
                grpc.RpcError,
                ConnectionError,
                ValueError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/add_property.html",
        {
            "hosts": hosts
        },
    )


# -----------------------------------------------------------------------------
# SEARCH PROPERTY
# -----------------------------------------------------------------------------

def property_search(request):
    """
    Search for an existing property using its generated property ID.
    """

    property_id = request.GET.get(
        "property_id",
        ""
    ).strip()

    searched = False
    result = None
    error = None


    if property_id:

        searched = True

        try:

            response = search_property(
                property_id
            )


            if (
                response.property
                and response.property.property_id
            ):

                result = {
                    "available":
                        response.available,

                    "message":
                        response.message,

                    **proto_property_to_dict(
                        response.property
                    ),
                }

            else:

                result = {
                    "available": False,
                    "message": response.message,
                }


        except (
            grpc.RpcError,
            ConnectionError
        ) as exc:

            error = grpc_error_message(
                exc
            )


    return render(
        request,
        "rentalApp/search_property.html",
        {
            "property_id": property_id,
            "searched": searched,
            "result": result,
            "error": error,
        },
    )


# -----------------------------------------------------------------------------
# UPDATE PROPERTY
# -----------------------------------------------------------------------------

def property_update(request):
    """
    Update an existing property.

    Recommended navigation:
        Properties page
            -> click Update
            -> ?property_id=PROP-0001

    Therefore the user does not need to manually type the property ID.
    """

    property_id = (
        request.POST.get("property_id")
        or request.GET.get("property_id")
        or ""
    ).strip()

    current_property = None
    response_data = None


    # -------------------------------------------------------------------------
    # Load current property details for the form.
    # -------------------------------------------------------------------------

    if property_id:

        try:

            search_response = search_property(
                property_id
            )


            if search_response.property.property_id:

                current_property = (
                    proto_property_to_dict(
                        search_response.property
                    )
                )


        except (
            grpc.RpcError,
            ConnectionError
        ) as exc:

            messages.error(
                request,
                grpc_error_message(exc)
            )


    # -------------------------------------------------------------------------
    # Process update.
    # -------------------------------------------------------------------------

    if request.method == "POST":

        if not property_id:

            messages.error(
                request,
                "No property was selected."
            )

        else:

            price = request.POST.get(
                "price_per_night",
                ""
            ).strip()

            status = request.POST.get(
                "status",
                ""
            ).strip()

            description = request.POST.get(
                "description",
                ""
            )


            try:

                response = update_property(
                    property_id=property_id,

                    price_per_night=(
                        price
                        if price
                        else None
                    ),

                    status=(
                        status
                        if status
                        else None
                    ),

                    description=description,
                )


                response_data = {
                    "success":
                        response.success,

                    "message":
                        response.message,
                }


                if (
                    response.property
                    and response.property.property_id
                ):

                    response_data[
                        "property"
                    ] = proto_property_to_dict(
                        response.property
                    )


                if response.success:

                    messages.success(
                        request,
                        response.message
                    )

                    return redirect(
                        "rentalApp:property_list"
                    )

                else:

                    messages.error(
                        request,
                        response.message
                    )


            except (
                grpc.RpcError,
                ConnectionError,
                ValueError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/update_property.html",
        {
            "property":
                current_property,

            "property_id":
                property_id,

            "response":
                response_data,
        },
    )


# -----------------------------------------------------------------------------
# REMOVE PROPERTY
# -----------------------------------------------------------------------------

def property_remove(request):
    """
    Remove a selected property.

    The property ID should normally be passed from the property list:
        /properties/remove/?property_id=PROP-0001

    The user therefore does not manually enter the ID.
    """

    property_id = (
        request.POST.get("property_id")
        or request.GET.get("property_id")
        or ""
    ).strip()

    property_data = None
    response_data = None


    if property_id:

        try:

            search_response = search_property(
                property_id
            )


            if search_response.property.property_id:

                property_data = (
                    proto_property_to_dict(
                        search_response.property
                    )
                )


        except (
            grpc.RpcError,
            ConnectionError
        ) as exc:

            messages.error(
                request,
                grpc_error_message(exc)
            )


    if request.method == "POST":

        if not property_id:

            messages.error(
                request,
                "No property was selected."
            )

        else:

            try:

                response = remove_property(
                    property_id
                )


                response_data = {
                    "success":
                        response.success,

                    "message":
                        response.message,

                    "remaining_properties": [
                        proto_property_to_dict(
                            item
                        )
                        for item
                        in response.remaining_properties
                    ],
                }


                if response.success:

                    messages.success(
                        request,
                        response.message
                    )

                    return redirect(
                        "rentalApp:property_list"
                    )


                messages.error(
                    request,
                    response.message
                )


            except (
                grpc.RpcError,
                ConnectionError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/remove_property.html",
        {
            "property":
                property_data,

            "property_id":
                property_id,

            "response":
                response_data,
        },
    )


# =============================================================================
# BOOKING / CART
# =============================================================================


# -----------------------------------------------------------------------------
# BOOK PROPERTY
# -----------------------------------------------------------------------------

def property_book(request):
    """
    Add a property to a guest's cart.

    The user should NOT manually type:
        guest ID
        property ID

    Instead:
        - guest is selected from registered GUEST users
        - property is selected from available properties
        - clicking Book from the property list can preselect the property

    Ballerina automatically generates:
        CART-0001
        CART-0002
        ...
    """

    guests = []
    properties = []


    selected_property_id = (
        request.POST.get("property_id")
        or request.GET.get("property_id")
        or ""
    ).strip()


    selected_guest_id = (
        request.POST.get("guest_id")
        or request.GET.get("guest_id")
        or ""
    ).strip()


    response_data = None


    # -------------------------------------------------------------------------
    # Load guests.
    # -------------------------------------------------------------------------

    try:

        guests = get_guests()

    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        messages.error(
            request,
            "Unable to load guests: "
            + grpc_error_message(exc)
        )


    # -------------------------------------------------------------------------
    # Load available properties.
    # -------------------------------------------------------------------------

    try:

        properties = get_available_properties()

    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        messages.error(
            request,
            "Unable to load properties: "
            + grpc_error_message(exc)
        )


    if request.method == "POST":

        guest_id = request.POST.get(
            "guest_id",
            ""
        ).strip()

        property_id = request.POST.get(
            "property_id",
            ""
        ).strip()

        check_in = request.POST.get(
            "check_in",
            ""
        ).strip()

        check_out = request.POST.get(
            "check_out",
            ""
        ).strip()


        if not all([
            guest_id,
            property_id,
            check_in,
            check_out,
        ]):

            messages.error(
                request,
                "Please complete all booking fields."
            )

        else:

            try:

                response = book_property(
                    guest_id=guest_id,
                    property_id=property_id,
                    check_in=check_in,
                    check_out=check_out,
                )


                response_data = {
                    "success":
                        response.success,

                    "message":
                        response.message,

                    "cart_id":
                        response.cart_id,

                    "estimated_cost":
                        response.estimated_cost,

                    # Keep this so the Confirm Booking page
                    # does not ask for the guest ID again.
                    "guest_id":
                        guest_id,

                    "property_id":
                        property_id,
                }


                if response.success:

                    messages.success(
                        request,
                        (
                            f"{response.message} "
                            f"Generated cart ID: "
                            f"{response.cart_id}"
                        )
                    )

                else:

                    messages.error(
                        request,
                        response.message
                    )


            except (
                grpc.RpcError,
                ConnectionError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/book_property.html",
        {
            "guests":
                guests,

            "properties":
                properties,

            "selected_property_id":
                selected_property_id,

            "selected_guest_id":
                selected_guest_id,

            "response":
                response_data,
        },
    )


# -----------------------------------------------------------------------------
# CONFIRM BOOKING
# -----------------------------------------------------------------------------

def booking_confirm(request):
    """
    Confirm a cart item.

    The cart ID and guest ID should be passed automatically from
    BookProperty.

    Example:
        /booking/confirm/
            ?cart_id=CART-0001
            &guest_id=USR-0002

    The form should keep these values in hidden fields.

    Ballerina automatically generates:
        BKG-0001
        BKG-0002
        ...
    """

    cart_id = (
        request.POST.get("cart_id")
        or request.GET.get("cart_id")
        or ""
    ).strip()


    guest_id = (
        request.POST.get("guest_id")
        or request.GET.get("guest_id")
        or ""
    ).strip()


    booking_data = None


    if request.method == "POST":

        if not cart_id or not guest_id:

            messages.error(
                request,
                "Missing cart or guest information."
            )

        else:

            try:

                response = confirm_booking(
                    guest_id=guest_id,
                    cart_id=cart_id,
                )


                if response.success:

                    booking_data = (
                        proto_booking_to_dict(
                            response.booking
                        )
                    )


                    messages.success(
                        request,
                        (
                            f"{response.message} "
                            f"Generated Booking ID: "
                            f"{response.booking.booking_id}"
                        )
                    )

                else:

                    messages.error(
                        request,
                        response.message
                    )


            except (
                grpc.RpcError,
                ConnectionError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/confirm_booking.html",
        {
            "cart_id":
                cart_id,

            "guest_id":
                guest_id,

            "booking":
                booking_data,
        },
    )


# =============================================================================
# ACTIVE BOOKINGS
# =============================================================================


# -----------------------------------------------------------------------------
# LIST BOOKINGS
# -----------------------------------------------------------------------------

def booking_list(request):
    """
    List active bookings.

    Optional filters:
        guest_id
        property_id
    """

    guest_id = request.GET.get(
        "guest_id",
        ""
    ).strip()

    property_id = request.GET.get(
        "property_id",
        ""
    ).strip()

    bookings = []

    error = None


    try:

        stream = list_bookings(
            guest_id=guest_id,
            property_id=property_id,
        )


        for booking in stream:

            bookings.append(
                proto_booking_to_dict(
                    booking
                )
            )


    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        error = grpc_error_message(
            exc
        )


    return render(
        request,
        "rentalApp/booking_list.html",
        {
            "bookings":
                bookings,

            "guest_id":
                guest_id,

            "property_id":
                property_id,

            "error":
                error,
        },
    )


# -----------------------------------------------------------------------------
# SEARCH BOOKING
# -----------------------------------------------------------------------------

def booking_search(request):
    """
    Search for a booking.

    The service searches:
        1. active bookings
        2. removed/archive bookings
    """

    booking_id = request.GET.get(
        "booking_id",
        ""
    ).strip()

    result = None


    if booking_id:

        try:

            response = search_booking(
                booking_id
            )


            if not response.found:

                result = {
                    "found": False,
                    "message": response.message,
                }


            elif response.removed:

                removed_booking = (
                    response.removed_booking
                )

                booking = (
                    removed_booking.booking
                )


                result = {
                    "found": True,
                    "removed": True,
                    "message": response.message,

                    **proto_booking_to_dict(
                        booking
                    ),

                    "reason":
                        removed_booking.reason,

                    "removed_at":
                        removed_booking.removed_at,
                }


            else:

                result = {
                    "found": True,
                    "removed": False,
                    "message": response.message,

                    **proto_booking_to_dict(
                        response.booking
                    ),
                }


        except (
            grpc.RpcError,
            ConnectionError
        ) as exc:

            result = {
                "found": False,
                "message": grpc_error_message(
                    exc
                ),
            }


    return render(
        request,
        "rentalApp/search_booking.html",
        {
            "booking_id":
                booking_id,

            "result":
                result,
        },
    )


# -----------------------------------------------------------------------------
# REMOVE / CANCEL BOOKING
# -----------------------------------------------------------------------------

def booking_remove(request):
    """
    Remove an active booking.

    The booking is first copied into removed_bookings by Ballerina,
    then removed from the active booking table.

    The ID should normally come from the active booking list:

        /bookings/remove/?booking_id=BKG-0001

    The user therefore does not have to type it manually.
    """

    booking_id = (
        request.POST.get("booking_id")
        or request.GET.get("booking_id")
        or ""
    ).strip()


    booking_data = None
    removed = None


    # -------------------------------------------------------------------------
    # Load booking information before removal.
    # -------------------------------------------------------------------------

    if booking_id:

        try:

            response = search_booking(
                booking_id
            )


            if (
                response.found
                and not response.removed
            ):

                booking_data = (
                    proto_booking_to_dict(
                        response.booking
                    )
                )


        except (
            grpc.RpcError,
            ConnectionError
        ) as exc:

            messages.error(
                request,
                grpc_error_message(exc)
            )


    if request.method == "POST":

        reason = request.POST.get(
            "reason",
            ""
        ).strip()


        if not booking_id:

            messages.error(
                request,
                "No booking was selected."
            )


        elif not reason:

            messages.error(
                request,
                "Please provide a reason for removing the booking."
            )


        else:

            try:

                response = remove_booking(
                    booking_id=booking_id,
                    reason=reason,
                )


                if response.success:

                    removed_booking = (
                        response.removed_booking
                    )


                    removed = {
                        **proto_booking_to_dict(
                            removed_booking.booking
                        ),

                        "reason":
                            removed_booking.reason,

                        "removed_at":
                            removed_booking.removed_at,
                    }


                    messages.success(
                        request,
                        response.message
                    )


                else:

                    messages.error(
                        request,
                        response.message
                    )


            except (
                grpc.RpcError,
                ConnectionError
            ) as exc:

                messages.error(
                    request,
                    grpc_error_message(exc)
                )


    return render(
        request,
        "rentalApp/remove_booking.html",
        {
            "booking":
                booking_data,

            "booking_id":
                booking_id,

            "removed":
                removed,
        },
    )


# =============================================================================
# REMOVED BOOKING HISTORY
# =============================================================================

def removed_booking_list(request):
    """
    Display archived/removed booking records.

    Optional filters:
        guest_id
        property_id
    """

    guest_id = request.GET.get(
        "guest_id",
        ""
    ).strip()

    property_id = request.GET.get(
        "property_id",
        ""
    ).strip()

    bookings = []

    error = None


    try:

        stream = list_removed_bookings(
            guest_id=guest_id,
            property_id=property_id,
        )


        for removed_booking in stream:

            bookings.append({
                **proto_booking_to_dict(
                    removed_booking.booking
                ),

                "reason":
                    removed_booking.reason,

                "removed_at":
                    removed_booking.removed_at,
            })


    except (
        grpc.RpcError,
        ConnectionError
    ) as exc:

        error = grpc_error_message(
            exc
        )


    return render(
        request,
        "rentalApp/removed_booking_list.html",
        {
            "bookings":
                bookings,

            "guest_id":
                guest_id,

            "property_id":
                property_id,

            "error":
                error,
        },
    )