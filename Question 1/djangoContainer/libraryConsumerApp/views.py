import requests
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

BALLERINA_BASE = "http://localhost:8080/library"

from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages
import json

from . import api_client
from .api_client import BallerinaError


def _json(request):
    """Parse the JSON body of a POST/PUT request safely."""
    try:
        return json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return {}


def _forward_json(status, body):
    """Return the Ballerina response as-is (status code + body)."""
    return JsonResponse(body, safe=False, status=status)


def _forward_or_error(fn, *args, **kwargs):
    """Run an api_client call; convert connection errors to a 502 payload."""
    try:
        return fn(*args, **kwargs)
    except BallerinaError as exc:
        return 502, {"error": "Ballerina service unreachable", "detail": str(exc)}

def _proxy_get(path):
    try:
        resp = requests.get(f"{BALLERINA_BASE}{path}", timeout=10)
        return JsonResponse(resp.json(), safe=False, status=resp.status_code)
    except requests.RequestException as e:
        return JsonResponse({"error": str(e)}, status=502)

def _proxy_post(path, payload):
    try:
        resp = requests.post(f"{BALLERINA_BASE}{path}", json=payload, timeout=10)
        return JsonResponse(resp.json(), safe=False, status=resp.status_code)
    except requests.RequestException as e:
        return JsonResponse({"error": str(e)}, status=502)

def _proxy_delete(path):
    try:
        resp = requests.delete(f"{BALLERINA_BASE}{path}", timeout=10)
        return JsonResponse(resp.json(), safe=False, status=resp.status_code)
    except requests.RequestException as e:
        return JsonResponse({"error": str(e)}, status=502)


def asset_list(request):
    return _proxy_get("/assets")

def asset_detail(request, asset_tag):
    return _proxy_get(f"/assets/{asset_tag}")

def overdue_dashboard(request):
    return _proxy_get("/assets/overdue")

def assets_by_institution(request, institution):
    return _proxy_get(f"/assets/institution/{institution}")

def assets_by_institution_site(request, institution, site):
    return _proxy_get(f"/assets/institution/{institution}/site/{site}")

@csrf_exempt
def loan_asset(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = json.loads(request.body)
    return _proxy_post(f"/assets/{asset_tag}/loan", {
        "borrower": data["borrower"],
        "dueDate": data["dueDate"],
        "description": data.get("description", "")
    })

@csrf_exempt
def add_schedule(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = json.loads(request.body)
    return _proxy_post(f"/assets/{asset_tag}/schedules", data)

def institution_list(request):
    return _proxy_get("/institutions")



# ---------------------------------------------------------------------------
# Global view
# ---------------------------------------------------------------------------

def dashboard(request):
    """HTML landing page with the four main dashboards."""
    return render(request, "libraryConsumerApp/dashboard.html")


def asset_list(request):
    """Global list of every asset across the ministry."""
    status, body = _forward_or_error(api_client.list_assets)
    return _forward_json(status, body)


def overdue_dashboard(request):
    """Assets with at least one overdue PENDING schedule."""
    status, body = _forward_or_error(api_client.overdue_assets)
    return _forward_json(status, body)


# ---------------------------------------------------------------------------
# Campus view
# ---------------------------------------------------------------------------

def assets_by_institution(request, institution):
    status, body = _forward_or_error(api_client.assets_by_institution, institution)
    return _forward_json(status, body)


def assets_by_institution_site(request, institution, site):
    status, body = _forward_or_error(
        api_client.assets_by_institution_site, institution, site)
    return _forward_json(status, body)


# ---------------------------------------------------------------------------
# Loaning & booking
# ---------------------------------------------------------------------------

@csrf_exempt
def loan_asset(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = _json(request)
    status, body = _forward_or_error(
        api_client.loan_asset, asset_tag, {
            "borrower": data.get("borrower", ""),
            "dueDate": data.get("dueDate", ""),
            "description": data.get("description", ""),
        })
    return _forward_json(status, body)


@csrf_exempt
def return_asset(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    status, body = _forward_or_error(api_client.return_asset, asset_tag)
    return _forward_json(status, body)


@csrf_exempt
def book_asset(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = _json(request)
    status, body = _forward_or_error(
        api_client.book_asset, asset_tag, {
            "bookedBy": data.get("bookedBy", ""),
            "dueDate": data.get("dueDate", ""),
            "description": data.get("description", ""),
        })
    return _forward_json(status, body)


@csrf_exempt
def release_asset(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    status, body = _forward_or_error(api_client.release_asset, asset_tag)
    return _forward_json(status, body)


# ---------------------------------------------------------------------------
# Schedule manager
# ---------------------------------------------------------------------------

def list_schedules(request, asset_tag):
    status, body = _forward_or_error(api_client.list_schedules, asset_tag)
    return _forward_json(status, body)


@csrf_exempt
def add_schedule(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = _json(request)
    payload = {
        "scheduleId": data.get("scheduleId", ""),
        "type": data.get("type", "MAINTENANCE"),
        "dueDate": data.get("dueDate", ""),
        "description": data.get("description", ""),
        "status": data.get("status", "PENDING"),
    }
    status, body = _forward_or_error(api_client.add_schedule, asset_tag, payload)
    return _forward_json(status, body)


@csrf_exempt
def delete_schedule(request, asset_tag, schedule_id):
    if request.method != "DELETE":
        return JsonResponse({"error": "DELETE required"}, status=405)
    status, body = _forward_or_error(
        api_client.delete_schedule, asset_tag, schedule_id)
    return _forward_json(status, body)


# ---------------------------------------------------------------------------
# Work orders
# ---------------------------------------------------------------------------

def list_work_orders(request, asset_tag):
    status, body = _forward_or_error(api_client.list_work_orders, asset_tag)
    return _forward_json(status, body)


@csrf_exempt
def add_work_order(request, asset_tag):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = _json(request)
    payload = {
        "orderId": data.get("orderId", ""),
        "status": data.get("status", "OPEN"),
        "description": data.get("description", ""),
        "tasks": data.get("tasks", []),
    }
    status, body = _forward_or_error(api_client.add_work_order, asset_tag, payload)
    return _forward_json(status, body)


@csrf_exempt
def update_work_order(request, asset_tag, order_id):
    if request.method != "PUT":
        return JsonResponse({"error": "PUT required"}, status=405)
    data = _json(request)
    payload = {
        "orderId": order_id,
        "status": data.get("status", "OPEN"),
        "description": data.get("description", ""),
        "tasks": data.get("tasks", []),
    }
    status, body = _forward_or_error(
        api_client.update_work_order, asset_tag, order_id, payload)
    return _forward_json(status, body)


# ---------------------------------------------------------------------------
# Institutions
# ---------------------------------------------------------------------------

def institution_list(request):
    status, body = _forward_or_error(api_client.list_institutions)
    return _forward_json(status, body)


@csrf_exempt
def add_institution(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    data = _json(request)
    status, body = _forward_or_error(
        api_client.add_institution,
        {"name": data.get("name", ""), "sites": data.get("sites", [])})
    return _forward_json(status, body)


@csrf_exempt
def delete_institution(request, name):
    if request.method != "DELETE":
        return JsonResponse({"error": "DELETE required"}, status=405)
    status, body = _forward_or_error(api_client.delete_institution, name)
    return _forward_json(status, body)



