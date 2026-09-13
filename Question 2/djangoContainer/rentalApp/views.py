from django.shortcuts import render

from .grpc_client import list_available_properties
from .grpc_generated import rental_pb2
from .grpc_generated import rental_pb2_grpc
import grpc
from django.contrib import messages
from django.shortcuts import render, redirect

from .grpc_client import *


# ============================================================================
# DASHBOARD
# ============================================================================

def dashboard(request):
    """
    Simple landing page for the Django gRPC consumer.
    """

    return render(
        request,
        "rentalApp/dashboard.html",
    )


# ============================================================================
# LIST AVAILABLE PROPERTIES
# ============================================================================

def property_list(request):

    location = request.GET.get("location", "").strip()
    min_price = request.GET.get("min_price", "0").strip()
    max_price = request.GET.get("max_price", "0").strip()

    try:
        min_price_value = float(min_price or 0)
    except ValueError:
        min_price_value = 0.0

    try:
        max_price_value = float(max_price or 0)
    except ValueError:
        max_price_value = 0.0

    properties = []
    error = None

    try:

        response_stream = list_available_properties(
            location_filter=location,
            min_price=min_price_value,
            max_price=max_price_value,
        )

        # The Ballerina method is server-side streaming.
        for item in response_stream:

            properties.append({
                "property_id": item.property_id,
                "host_id": item.host_id,
                "name": item.name,
                "location": item.location,
                "region": item.region,
                "property_type": item.property_type,
                "price_per_night": item.price_per_night,
                "status": item.status,
                "description": item.description,
            })

    except grpc.RpcError as exc:

        error = (
            f"Rental service unavailable: "
            f"{exc.details() or str(exc)}"
        )

    return render(
        request,
        "rentalApp/property_list.html",
        {
            "properties": properties,
            "error": error,
            "location": location,
            "min_price": min_price,
            "max_price": max_price,
        },
    )


# ============================================================================
# ADD PROPERTY
# ============================================================================

def property_create(request):

    if request.method == "POST":

        try:

            response = add_property(
                host_id=request.POST.get("host_id", "").strip(),
                name=request.POST.get("name", "").strip(),
                location=request.POST.get("location", "").strip(),
                region=request.POST.get("region", "").strip(),
                property_type=request.POST.get(
                    "property_type",
                    ""
                ).strip(),
                price_per_night=request.POST.get(
                    "price_per_night",
                    "0"
                ),
                description=request.POST.get(
                    "description",
                    ""
                ).strip(),
            )

            if response.success:

                messages.success(
                    request,
                    f"Property created successfully. "
                    f"ID: {response.property_id}",
                )

                return redirect(
                    "rentalApp:property_list"
                )

            messages.error(
                request,
                response.message
            )

        except (grpc.RpcError, ValueError) as exc:

            messages.error(
                request,
                f"Unable to create property: {exc}"
            )

    return render(
        request,
        "rentalApp/add_property.html",
    )


# ============================================================================
# SEARCH PROPERTY
# ============================================================================

def property_search(request):

    result = None
    searched = False
    error = None

    property_id = request.GET.get(
        "property_id",
        ""
    ).strip()

    if property_id:

        searched = True

        try:

            response = search_property(
                property_id
            )

            result = {
                "available": response.available,
                "message": response.message,
                "property_id": response.property.property_id,
                "host_id": response.property.host_id,
                "name": response.property.name,
                "location": response.property.location,
                "region": response.property.region,
                "property_type": response.property.property_type,
                "price_per_night": response.property.price_per_night,
                "status": response.property.status,
                "description": response.property.description,
            }

        except grpc.RpcError as exc:

            error = (
                exc.details()
                or str(exc)
            )

    return render(
        request,
        "rentalApp/search_property.html",
        {
            "property_id": property_id,
            "result": result,
            "searched": searched,
            "error": error,
        },
    )


# ============================================================================
# BOOK PROPERTY
# ============================================================================

def property_book(request):

    response_data = None

    if request.method == "POST":

        try:

            response = book_property(
                guest_id=request.POST.get(
                    "guest_id",
                    ""
                ).strip(),

                property_id=request.POST.get(
                    "property_id",
                    ""
                ).strip(),

                check_in=request.POST.get(
                    "check_in",
                    ""
                ),

                check_out=request.POST.get(
                    "check_out",
                    ""
                ),
            )

            response_data = {
                "success": response.success,
                "message": response.message,
                "cart_id": response.cart_id,
                "estimated_cost": response.estimated_cost,
            }

        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )

    return render(
        request,
        "rentalApp/book_property.html",
        {
            "response": response_data
        },
    )


# ============================================================================
# CONFIRM BOOKING
# ============================================================================

def booking_confirm(request):

    booking = None

    if request.method == "POST":

        try:

            response = confirm_booking(
                guest_id=request.POST.get(
                    "guest_id",
                    ""
                ).strip(),

                cart_id=request.POST.get(
                    "cart_id",
                    ""
                ).strip(),
            )

            if response.success:

                booking = {
                    "booking_id":
                        response.booking.booking_id,

                    "property_id":
                        response.booking.property_id,

                    "guest_id":
                        response.booking.guest_id,

                    "check_in":
                        response.booking.dates.check_in,

                    "check_out":
                        response.booking.dates.check_out,

                    "total_cost":
                        response.booking.total_cost,

                    "status":
                        response.booking.status,
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

        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )

    return render(
        request,
        "rentalApp/confirm_booking.html",
        {
            "booking": booking
        },
    )


# ============================================================================
# CREATE USERS
# ============================================================================

def user_create(request):

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


            if name and email and role:

                users.append({
                    "name": name,
                    "email": email,
                    "role": role,
                    "region": region,
                })


        if not users:

            messages.error(
                request,
                "Please enter at least one user."
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
                        {
                            "user_id":
                                user.user_id,

                            "name":
                                user.name,

                            "email":
                                user.email,

                            "role":
                                "HOST"
                                if user.role == 1
                                else "GUEST",

                            "region":
                                user.region,
                        }
                        for user
                        in response.created_users
                    ],
                }

                messages.success(
                    request,
                    response.message
                )

            except grpc.RpcError as exc:

                messages.error(
                    request,
                    exc.details() or str(exc)
                )


    return render(
        request,
        "rentalApp/create_users.html",
        {
            "response": response_data
        },
    )


# ============================================================================
# LIST USERS
# ============================================================================

def user_list(request):

    role = request.GET.get(
        "role",
        ""
    ).strip()

    users = []

    error = None

    try:

        stream = list_users(role)

        for user in stream:

            users.append({
                "user_id": user.user_id,
                "name": user.name,
                "email": user.email,

                "role":
                    "HOST"
                    if user.role == 1
                    else "GUEST",

                "region": user.region,
            })

    except grpc.RpcError as exc:

        error = (
            exc.details()
            or str(exc)
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


# ============================================================================
# SEARCH USER
# ============================================================================

def user_search(request):

    user_id = request.GET.get(
        "user_id",
        ""
    ).strip()

    result = None
    searched = False

    if user_id:

        searched = True

        try:

            response = search_user(
                user_id
            )

            if response.found:

                result = {
                    "found": True,
                    "message":
                        response.message,

                    "user_id":
                        response.user.user_id,

                    "name":
                        response.user.name,

                    "email":
                        response.user.email,

                    "role":
                        "HOST"
                        if response.user.role == 1
                        else "GUEST",

                    "region":
                        response.user.region,
                }

            else:

                result = {
                    "found": False,
                    "message":
                        response.message,
                }

        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )


    return render(
        request,
        "rentalApp/search_user.html",
        {
            "user_id": user_id,
            "searched": searched,
            "result": result,
        },
    )

# ============================================================================
# UPDATE PROPERTY
# ============================================================================

def property_update(request):

    response_data = None

    if request.method == "POST":

        try:

            response = update_property(
                property_id=request.POST.get(
                    "property_id",
                    ""
                ).strip(),

                price_per_night=request.POST.get(
                    "price_per_night",
                    ""
                ),

                status=request.POST.get(
                    "status",
                    ""
                ),

                description=request.POST.get(
                    "description",
                    ""
                ),
            )


            response_data = {
                "success": response.success,
                "message": response.message,

                "property_id":
                    response.property.property_id,

                "name":
                    response.property.name,

                "price_per_night":
                    response.property.price_per_night,

                "description":
                    response.property.description,
            }


            if response.success:

                messages.success(
                    request,
                    response.message
                )

            else:

                messages.error(
                    request,
                    response.message
                )


        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )


    return render(
        request,
        "rentalApp/update_property.html",
        {
            "response": response_data
        },
    )


# ============================================================================
# REMOVE PROPERTY
# ============================================================================

def property_remove(request):

    response_data = None

    if request.method == "POST":

        property_id = request.POST.get(
            "property_id",
            ""
        ).strip()

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
                    {
                        "property_id":
                            item.property_id,

                        "name":
                            item.name,

                        "region":
                            item.region,

                        "price_per_night":
                            item.price_per_night,
                    }
                    for item
                    in response.remaining_properties
                ],
            }


            if response.success:

                messages.success(
                    request,
                    response.message
                )

            else:

                messages.error(
                    request,
                    response.message
                )


        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )


    return render(
        request,
        "rentalApp/remove_property.html",
        {
            "response": response_data
        },
    )


# ============================================================================
# LIST ACTIVE BOOKINGS
# ============================================================================

def booking_list(request):

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

            bookings.append({
                "booking_id":
                    booking.booking_id,

                "property_id":
                    booking.property_id,

                "guest_id":
                    booking.guest_id,

                "check_in":
                    booking.dates.check_in,

                "check_out":
                    booking.dates.check_out,

                "total_cost":
                    booking.total_cost,

                "status":
                    booking.status,
            })


    except grpc.RpcError as exc:

        error = (
            exc.details()
            or str(exc)
        )


    return render(
        request,
        "rentalApp/booking_list.html",
        {
            "bookings": bookings,
            "guest_id": guest_id,
            "property_id": property_id,
            "error": error,
        },
    )


# ============================================================================
# SEARCH BOOKING
# ============================================================================

def booking_search(request):

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

            if response.found:

                if response.removed:

                    item = (
                        response
                        .removed_booking
                        .booking
                    )

                    result = {
                        "found": True,
                        "removed": True,

                        "message":
                            response.message,

                        "booking_id":
                            item.booking_id,

                        "property_id":
                            item.property_id,

                        "guest_id":
                            item.guest_id,

                        "check_in":
                            item.dates.check_in,

                        "check_out":
                            item.dates.check_out,

                        "total_cost":
                            item.total_cost,

                        "status":
                            item.status,

                        "reason":
                            response
                            .removed_booking
                            .reason,

                        "removed_at":
                            response
                            .removed_booking
                            .removed_at,
                    }

                else:

                    item = response.booking

                    result = {
                        "found": True,
                        "removed": False,

                        "message":
                            response.message,

                        "booking_id":
                            item.booking_id,

                        "property_id":
                            item.property_id,

                        "guest_id":
                            item.guest_id,

                        "check_in":
                            item.dates.check_in,

                        "check_out":
                            item.dates.check_out,

                        "total_cost":
                            item.total_cost,

                        "status":
                            item.status,
                    }

            else:

                result = {
                    "found": False,
                    "message":
                        response.message,
                }


        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )


    return render(
        request,
        "rentalApp/search_booking.html",
        {
            "booking_id": booking_id,
            "result": result,
        },
    )


# ============================================================================
# REMOVE BOOKING
# ============================================================================

def booking_remove(request):

    removed = None

    if request.method == "POST":

        booking_id = request.POST.get(
            "booking_id",
            ""
        ).strip()

        reason = request.POST.get(
            "reason",
            ""
        ).strip()


        try:

            response = remove_booking(
                booking_id,
                reason,
            )


            if response.success:

                item = (
                    response
                    .removed_booking
                    .booking
                )

                removed = {
                    "booking_id":
                        item.booking_id,

                    "property_id":
                        item.property_id,

                    "guest_id":
                        item.guest_id,

                    "reason":
                        response
                        .removed_booking
                        .reason,

                    "removed_at":
                        response
                        .removed_booking
                        .removed_at,
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


        except grpc.RpcError as exc:

            messages.error(
                request,
                exc.details() or str(exc)
            )


    return render(
        request,
        "rentalApp/remove_booking.html",
        {
            "removed": removed
        },
    )


# ============================================================================
# REMOVED BOOKING HISTORY
# ============================================================================

def removed_booking_list(request):

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
            guest_id,
            property_id,
        )


        for removed in stream:

            booking = removed.booking

            bookings.append({
                "booking_id":
                    booking.booking_id,

                "property_id":
                    booking.property_id,

                "guest_id":
                    booking.guest_id,

                "check_in":
                    booking.dates.check_in,

                "check_out":
                    booking.dates.check_out,

                "total_cost":
                    booking.total_cost,

                "status":
                    booking.status,

                "reason":
                    removed.reason,

                "removed_at":
                    removed.removed_at,
            })


    except grpc.RpcError as exc:

        error = (
            exc.details()
            or str(exc)
        )


    return render(
        request,
        "rentalApp/removed_booking_list.html",
        {
            "bookings": bookings,
            "guest_id": guest_id,
            "property_id": property_id,
            "error": error,
        },
    )
