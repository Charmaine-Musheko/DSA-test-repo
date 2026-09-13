from django.shortcuts import render

from .grpc_client import list_available_properties
import grpc
from django.contrib import messages
from django.shortcuts import render, redirect

from .grpc_client import (
    add_property,
    list_available_properties,
    search_property,
    book_property,
    confirm_booking,
)


def property_list(request):
    location = request.GET.get("location", "")
    min_price = request.GET.get("min_price", "0")
    max_price = request.GET.get("max_price", "0")

    try:
        min_price = float(min_price or 0)
    except ValueError:
        min_price = 0.0

    try:
        max_price = float(max_price or 0)
    except ValueError:
        max_price = 0.0

    properties = []

    try:
        response_stream = list_available_properties(
            location_filter=location,
            min_price=min_price,
            max_price=max_price,
        )

        for property_item in response_stream:
            properties.append({
                "property_id": property_item.property_id,
                "host_id": property_item.host_id,
                "name": property_item.name,
                "location": property_item.location,
                "region": property_item.region,
                "property_type": property_item.property_type,
                "price_per_night": property_item.price_per_night,
                "status": property_item.status,
                "description": property_item.description,
            })

        error = None

    except Exception as exc:
        error = str(exc)

    return render(
        request,
        "rentalApp/property_list.html",
        {
            "properties": properties,
            "error": error,
        },
    )


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
