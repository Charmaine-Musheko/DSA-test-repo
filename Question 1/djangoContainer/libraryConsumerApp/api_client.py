"""
Thin client around the Ballerina Library REST API.

All calls go through here so:
  - the base URL lives in one place
  - timeouts are consistent
  - HTTP errors are converted into a (status_code, payload) tuple the
    views can return directly.
"""
import requests
from django.conf import settings


class BallerinaError(Exception):
    """Raised when Ballerina is unreachable (connection refused, timeout)."""
    pass


def _base():
    # Override with BALLERINA_BASE_URL in settings.py if needed.
    return getattr(settings, "BALLERINA_BASE_URL",
                   "http://localhost:8080/library")


def _request(method, path, **kwargs):
    url = f"{_base()}{path}"
    kwargs.setdefault("timeout", 10)
    try:
        resp = requests.request(method, url, **kwargs)
    except requests.RequestException as exc:
        raise BallerinaError(str(exc)) from exc
    # Ballerina always returns JSON on success and on error payloads.
    try:
        body = resp.json()
    except ValueError:
        body = {"raw": resp.text}
    return resp.status_code, body


# ---------- Assets ----------

def list_assets():
    return _request("GET", "/assets")

def get_asset(asset_tag):
    return _request("GET", f"/assets/{asset_tag}")

def create_asset(payload):
    return _request("POST", "/assets", json=payload)

def update_asset(asset_tag, payload):
    return _request("PUT", f"/assets/{asset_tag}", json=payload)

def delete_asset(asset_tag):
    return _request("DELETE", f"/assets/{asset_tag}")

def assets_by_institution(institution):
    return _request("GET", f"/assets/institution/{institution}")

def assets_by_institution_site(institution, site):
    return _request("GET", f"/assets/institution/{institution}/site/{site}")

def overdue_assets():
    return _request("GET", "/assets/overdue")

def asset_status(asset_tag):
    return _request("GET", f"/assets/{asset_tag}/status")


# ---------- Loan / booking ----------

def loan_asset(asset_tag, payload):
    return _request("POST", f"/assets/{asset_tag}/loan", json=payload)

def return_asset(asset_tag):
    return _request("POST", f"/assets/{asset_tag}/return")

def book_asset(asset_tag, payload):
    return _request("POST", f"/assets/{asset_tag}/book", json=payload)

def release_asset(asset_tag):
    return _request("POST", f"/assets/{asset_tag}/release")


# ---------- Components ----------

def list_components(asset_tag):
    return _request("GET", f"/assets/{asset_tag}/components")

def add_component(asset_tag, payload):
    return _request("POST", f"/assets/{asset_tag}/components", json=payload)

def delete_component(asset_tag, comp_id):
    return _request("DELETE", f"/assets/{asset_tag}/components/{comp_id}")


# ---------- Schedules ----------

def list_schedules(asset_tag):
    return _request("GET", f"/assets/{asset_tag}/schedules")

def add_schedule(asset_tag, payload):
    return _request("POST", f"/assets/{asset_tag}/schedules", json=payload)

def update_schedule(asset_tag, schedule_id, payload):
    return _request("PUT", f"/assets/{asset_tag}/schedules/{schedule_id}", json=payload)

def delete_schedule(asset_tag, schedule_id):
    return _request("DELETE", f"/assets/{asset_tag}/schedules/{schedule_id}")


# ---------- Work orders ----------

def list_work_orders(asset_tag):
    return _request("GET", f"/assets/{asset_tag}/workorders")

def add_work_order(asset_tag, payload):
    return _request("POST", f"/assets/{asset_tag}/workorders", json=payload)

def update_work_order(asset_tag, order_id, payload):
    return _request("PUT", f"/assets/{asset_tag}/workorders/{order_id}", json=payload)

def delete_work_order(asset_tag, order_id):
    return _request("DELETE", f"/assets/{asset_tag}/workorders/{order_id}")


# ---------- Institutions ----------

def list_institutions():
    return _request("GET", "/institutions")

def get_institution(name):
    return _request("GET", f"/institutions/{name}")

def add_institution(payload):
    return _request("POST", "/institutions", json=payload)

def delete_institution(name):
    return _request("DELETE", f"/institutions/{name}")

def add_site(institution_name, site):
    return _request("POST", f"/institutions/{institution_name}/sites",
                    json={"site": site})

def delete_site(institution_name, site):
    return _request("DELETE", f"/institutions/{institution_name}/sites/{site}")


