import requests
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

BALLERINA_BASE = "http://localhost:8080/library"

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

