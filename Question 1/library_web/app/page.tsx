"use client";

import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";

type View = "overview" | "learning" | "assets" | "schedules" | "institutions";
type AssetStatus = "AVAILABLE" | "LOANED_OUT" | "OCCUPIED" | "UNDER_MAINTENANCE" | "DISPOSED";
type ComponentPart = { compId: string; name: string; description: string };
type Schedule = { scheduleId: string; type: string; dueDate: string; description: string; status: "PENDING" | "COMPLETED" | "CANCELLED" };
type WorkOrder = { orderId: string; status: "OPEN" | "IN_PROGRESS" | "CLOSED"; description: string; tasks: { taskId: string; description: string; completed: boolean }[] };
type Asset = { assetTag: string; name: string; description: string; institution: string; site: string; dateAcquired: string; status: AssetStatus; components: ComponentPart[]; schedules: Schedule[]; workOrders: WorkOrder[] };
type Institution = { name: string; sites: string[] };

const navigation: { id: View; label: string; icon: string }[] = [
  { id: "overview", label: "Dashboard", icon: "1" },
  { id: "learning", label: "How it works", icon: "2" },
  { id: "assets", label: "Assets", icon: "3" },
  { id: "schedules", label: "Schedules", icon: "4" },
  { id: "institutions", label: "Institutions", icon: "5" },
];

const statusLabel: Record<AssetStatus, string> = {
  AVAILABLE: "Available", LOANED_OUT: "Loaned out", OCCUPIED: "Occupied",
  UNDER_MAINTENANCE: "Maintenance", DISPOSED: "Disposed",
};

async function api<T>(path: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`/api/library${path}`, {
    ...options,
    headers: options?.body ? { "Content-Type": "application/json", ...options.headers } : options?.headers,
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.message || `Request failed with status ${response.status}`);
  return data as T;
}

function isOverdue(schedule: Schedule) {
  return schedule.status === "PENDING" && schedule.dueDate < new Date().toISOString().slice(0, 10);
}

export default function Home() {
  const [view, setView] = useState<View>("overview");
  const [assets, setAssets] = useState<Asset[]>([]);
  const [institutions, setInstitutions] = useState<Institution[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [toast, setToast] = useState("");
  const [search, setSearch] = useState("");
  const [institutionFilter, setInstitutionFilter] = useState("ALL");
  const [selectedAsset, setSelectedAsset] = useState<Asset | null>(null);
  const [showAssetForm, setShowAssetForm] = useState(false);
  const [scheduleAsset, setScheduleAsset] = useState<Asset | null>(null);
  const [activity, setActivity] = useState<{ asset: Asset; type: "loan" | "book" } | null>(null);

  const loadData = useCallback(async () => {
    setError("");
    try {
      const [assetData, institutionData] = await Promise.all([
        api<Asset[]>("/assets"), api<Institution[]>("/institutions"),
      ]);
      setAssets(assetData);
      setInstitutions(institutionData);
      setSelectedAsset((current) => current ? assetData.find((asset) => asset.assetTag === current.assetTag) || null : null);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Could not load the library service.");
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);
  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(""), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const overdueAssets = useMemo(() => assets.filter((asset) => asset.schedules.some(isOverdue)), [assets]);
  const filteredAssets = useMemo(() => {
    const query = search.trim().toLowerCase();
    return assets.filter((asset) => {
      const institutionMatch = institutionFilter === "ALL" || asset.institution === institutionFilter;
      const searchMatch = !query || [asset.name, asset.assetTag, asset.site, asset.institution].some((value) => value.toLowerCase().includes(query));
      return institutionMatch && searchMatch;
    });
  }, [assets, institutionFilter, search]);
  const allSchedules = useMemo(() => assets.flatMap((asset) => asset.schedules.map((schedule) => ({ asset, schedule }))), [assets]);

  async function removeAsset(asset: Asset) {
    if (!window.confirm(`Delete ${asset.name}? This action cannot be undone.`)) return;
    try {
      await api(`/assets/${encodeURIComponent(asset.assetTag)}`, { method: "DELETE" });
      setSelectedAsset(null); setToast("Asset removed successfully"); await loadData();
    } catch (requestError) {
      setToast(requestError instanceof Error ? requestError.message : "Could not remove asset");
    }
  }

  const sectionTitle = navigation.find((item) => item.id === view)?.label || "Overview";

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand"><div className="brand-mark">Q1</div><div><strong>Library System</strong><span>DSA612S learning project</span></div></div>
        <nav aria-label="Main navigation">
          <p className="nav-label">Project pages</p>
          {navigation.map((item) => (
            <button className={view === item.id ? "nav-item active" : "nav-item"} key={item.id} onClick={() => setView(item.id)}>
              <span className="nav-icon" aria-hidden="true">{item.icon}</span>{item.label}
              {item.id === "schedules" && overdueAssets.length > 0 && <span className="nav-count">{overdueAssets.length}</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar-status"><span className={error ? "status-dot offline" : "status-dot"} /><div><strong>{error ? "Backend not running" : "Backend connected"}</strong><span>Ballerina service on port 8080</span></div></div>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div><span className="eyebrow">Question 1 demonstration</span><h1>{sectionTitle}</h1></div>
          <div className="topbar-actions"><button className="icon-button" onClick={loadData} aria-label="Refresh data">Refresh</button><button className="primary-button" onClick={() => setShowAssetForm(true)}>+ Add asset</button></div>
        </header>

        {error && <div className="error-banner" role="alert"><div><strong>Cannot reach the library service.</strong><span>{error}</span></div><button onClick={loadData}>Try again</button></div>}

        {loading ? <LoadingState /> : <>
          {view === "overview" && <Overview assets={assets} overdueAssets={overdueAssets} institutions={institutions} onViewAsset={setSelectedAsset} onNavigate={setView} />}
          {view === "learning" && <LearningGuide />}
          {view === "assets" && <AssetsView assets={filteredAssets} institutions={institutions} search={search} institutionFilter={institutionFilter} onSearch={setSearch} onFilter={setInstitutionFilter} onView={setSelectedAsset} onLoan={(asset) => setActivity({ asset, type: "loan" })} onBook={(asset) => setActivity({ asset, type: "book" })} />}
          {view === "schedules" && <SchedulesView schedules={allSchedules} assets={assets} onAdd={setScheduleAsset} />}
          {view === "institutions" && <InstitutionsView institutions={institutions} assets={assets} />}
        </>}
      </section>

      {selectedAsset && <AssetDrawer asset={selectedAsset} onClose={() => setSelectedAsset(null)} onDelete={() => removeAsset(selectedAsset)} onSchedule={() => setScheduleAsset(selectedAsset)} onLoan={() => setActivity({ asset: selectedAsset, type: "loan" })} onBook={() => setActivity({ asset: selectedAsset, type: "book" })} />}
      {showAssetForm && <AssetForm institutions={institutions} onClose={() => setShowAssetForm(false)} onSaved={async () => { setShowAssetForm(false); setToast("Asset added to the network"); await loadData(); }} />}
      {scheduleAsset && <ScheduleForm asset={scheduleAsset} onClose={() => setScheduleAsset(null)} onSaved={async () => { setScheduleAsset(null); setToast("Schedule added successfully"); await loadData(); }} />}
      {activity && <ActivityForm asset={activity.asset} type={activity.type} onClose={() => setActivity(null)} onSaved={async () => { const message = activity.type === "loan" ? "Asset loan recorded" : "Booking confirmed"; setActivity(null); setToast(message); await loadData(); }} />}
      {toast && <div className="toast" role="status">Done: {toast}</div>}
    </main>
  );
}

function LoadingState() {
  return <div className="loading-grid" aria-label="Loading dashboard">{[1, 2, 3, 4].map((item) => <div className="loading-card" key={item} />)}</div>;
}

function Overview({ assets, overdueAssets, institutions, onViewAsset, onNavigate }: { assets: Asset[]; overdueAssets: Asset[]; institutions: Institution[]; onViewAsset: (asset: Asset) => void; onNavigate: (view: View) => void }) {
  const available = assets.filter((asset) => asset.status === "AVAILABLE").length;
  const inUse = assets.filter((asset) => ["LOANED_OUT", "OCCUPIED"].includes(asset.status)).length;
  return <div className="page-content">
    <section className="welcome-panel"><div><span className="welcome-kicker">Inter-process communication example</span><h2>Library and Resource Management System</h2><p>This page is a simple client. It sends HTTP requests containing JSON to a Ballerina service, which reads or changes data in memory.</p><button className="lesson-link" onClick={() => onNavigate("learning")}>Study how the communication works</button></div></section>
    <section className="stats-grid" aria-label="Resource summary"><StatCard label="Total assets" value={assets.length} note={`${institutions.length} institutions`} tone="navy" /><StatCard label="Available now" value={available} note="Ready to use" tone="green" /><StatCard label="Currently in use" value={inUse} note="Loans and bookings" tone="blue" /><StatCard label="Overdue attention" value={overdueAssets.length} note="Action required" tone="orange" /></section>
    <div className="overview-grid">
      <section className="panel"><div className="panel-heading"><div><span className="eyebrow">Data returned by GET /assets</span><h3>Sample assets</h3></div><button className="text-button" onClick={() => onNavigate("assets")}>View all</button></div><div className="asset-list">{assets.slice(0, 5).map((asset) => <button className="asset-list-row" key={asset.assetTag} onClick={() => onViewAsset(asset)}><AssetGlyph name={asset.name} /><span className="asset-main"><strong>{asset.name}</strong><small>{asset.assetTag} | {asset.site}</small></span><StatusPill status={asset.status} /><span className="row-arrow">Open</span></button>)}</div></section>
      <section className="panel attention-panel"><div className="panel-heading"><div><span className="eyebrow">Needs attention</span><h3>Overdue items</h3></div><span className="alert-count">{overdueAssets.length}</span></div>{overdueAssets.length === 0 ? <div className="empty-state"><span>✓</span><strong>Everything is on track</strong><p>No overdue schedules found.</p></div> : <div className="overdue-list">{overdueAssets.slice(0, 4).map((asset) => { const due = asset.schedules.find(isOverdue); return <button key={asset.assetTag} onClick={() => onViewAsset(asset)}><span className="alert-icon">!</span><span><strong>{asset.name}</strong><small>Due {due?.dueDate} · {due?.type}</small></span><span>›</span></button>; })}</div>}</section>
    </div>
  </div>;
}

function LearningGuide() {
  return <div className="page-content learning-page">
    <section className="lesson-intro">
      <span className="eyebrow">Week 3 concept: IPC</span>
      <h2>What happens when a user clicks a button?</h2>
      <p>The browser and the Ballerina service are separate processes. They cooperate by passing messages over HTTP.</p>
    </section>

    <section className="flow-lesson" aria-label="Request and response flow">
      <article><strong>1. Client</strong><p>The React page collects input and calls <code>fetch()</code>.</p></article>
      <span aria-hidden="true">-&gt;</span>
      <article><strong>2. HTTP and JSON</strong><p>A method, route, headers, and optional JSON body form the message.</p></article>
      <span aria-hidden="true">-&gt;</span>
      <article><strong>3. Service</strong><p>Ballerina selects the matching resource function and validates the data.</p></article>
      <span aria-hidden="true">-&gt;</span>
      <article><strong>4. Storage</strong><p>The handler reads or updates an in-memory table and returns a response.</p></article>
    </section>

    <div className="learning-grid">
      <section className="lesson-card">
        <h3>Methods used in this project</h3>
        <table className="study-table"><thead><tr><th>Action</th><th>Message</th><th>Meaning</th></tr></thead><tbody>
          <tr><td>List assets</td><td><code>GET /assets</code></td><td>Read data</td></tr>
          <tr><td>Add asset</td><td><code>POST /assets</code></td><td>Create data</td></tr>
          <tr><td>Update asset</td><td><code>PUT /assets/tag</code></td><td>Replace data</td></tr>
          <tr><td>Delete asset</td><td><code>DELETE /assets/tag</code></td><td>Remove data</td></tr>
        </tbody></table>
      </section>
      <section className="lesson-card">
        <h3>Questions I should be able to answer</h3>
        <details><summary>Why is this IPC?</summary><p>The browser client and Ballerina server run independently and exchange messages through an API.</p></details>
        <details><summary>Why use JSON?</summary><p>JSON provides a common representation that both TypeScript and Ballerina can serialize and understand.</p></details>
        <details><summary>Why is assetTag important?</summary><p>It is the table key, so each asset can be found uniquely and duplicates are rejected.</p></details>
        <details><summary>What happens after a restart?</summary><p>The sample data returns because storage is in memory. There is no permanent database in this version.</p></details>
      </section>
    </div>
    <aside className="student-note"><strong>Important limitation:</strong> This is a teaching prototype. It demonstrates communication, records, tables, routes, validation, and error responses; it is not a production library platform.</aside>
  </div>;
}

function StatCard({ label, value, note, tone }: { label: string; value: number; note: string; tone: string }) {
  return <article className={`stat-card ${tone}`}><span className="stat-label">{label}</span><strong>{String(value).padStart(2, "0")}</strong><small>{note}</small><i aria-hidden="true" /></article>;
}

function AssetsView({ assets, institutions, search, institutionFilter, onSearch, onFilter, onView, onLoan, onBook }: { assets: Asset[]; institutions: Institution[]; search: string; institutionFilter: string; onSearch: (value: string) => void; onFilter: (value: string) => void; onView: (asset: Asset) => void; onLoan: (asset: Asset) => void; onBook: (asset: Asset) => void }) {
  return <div className="page-content"><div className="page-intro"><div><h2>Resource catalogue</h2><p>Browse and manage every asset across the ministry network.</p></div><span className="result-count">{assets.length} results</span></div><div className="filters"><label className="search-field"><span aria-hidden="true">⌕</span><input value={search} onChange={(event) => onSearch(event.target.value)} placeholder="Search by name, tag, campus…" /></label><select value={institutionFilter} onChange={(event) => onFilter(event.target.value)} aria-label="Filter by institution"><option value="ALL">All institutions</option>{institutions.map((institution) => <option key={institution.name}>{institution.name}</option>)}</select></div><div className="table-card"><table><thead><tr><th>Asset</th><th>Institution & campus</th><th>Acquired</th><th>Status</th><th>Quick action</th><th><span className="sr-only">Open</span></th></tr></thead><tbody>{assets.map((asset) => <tr key={asset.assetTag}><td><div className="asset-cell"><AssetGlyph name={asset.name} /><span><strong>{asset.name}</strong><small>{asset.assetTag}</small></span></div></td><td><strong className="cell-primary">{asset.institution}</strong><small className="cell-secondary">{asset.site}</small></td><td>{asset.dateAcquired}</td><td><StatusPill status={asset.status} /></td><td>{asset.status === "AVAILABLE" ? <div className="quick-actions"><button onClick={() => onLoan(asset)}>Loan</button><button onClick={() => onBook(asset)}>Book</button></div> : <span className="muted">Unavailable</span>}</td><td><button className="more-button" onClick={() => onView(asset)} aria-label={`View ${asset.name}`}>•••</button></td></tr>)}</tbody></table>{assets.length === 0 && <div className="empty-table">No assets match your search.</div>}</div></div>;
}

function SchedulesView({ schedules, assets, onAdd }: { schedules: { asset: Asset; schedule: Schedule }[]; assets: Asset[]; onAdd: (asset: Asset) => void }) {
  const [assetTag, setAssetTag] = useState(assets[0]?.assetTag || ""); const selected = assets.find((asset) => asset.assetTag === assetTag);
  return <div className="page-content"><div className="page-intro"><div><h2>Schedule manager</h2><p>Monitor loans, bookings, and servicing deadlines.</p></div><div className="schedule-add"><select value={assetTag} onChange={(event) => setAssetTag(event.target.value)}>{assets.map((asset) => <option value={asset.assetTag} key={asset.assetTag}>{asset.name}</option>)}</select><button className="primary-button" disabled={!selected} onClick={() => selected && onAdd(selected)}>＋ Add schedule</button></div></div><div className="schedule-grid">{schedules.map(({ asset, schedule }) => <article className={isOverdue(schedule) ? "schedule-card overdue" : "schedule-card"} key={`${asset.assetTag}-${schedule.scheduleId}`}><div className="schedule-date"><strong>{schedule.dueDate.slice(8, 10)}</strong><span>{new Date(`${schedule.dueDate}T00:00:00`).toLocaleString("en", { month: "short" })}</span></div><div className="schedule-info"><div><span className={`schedule-type ${schedule.type.toLowerCase()}`}>{schedule.type}</span>{isOverdue(schedule) && <span className="overdue-tag">Overdue</span>}</div><h3>{asset.name}</h3><p>{schedule.description || "No description provided"}</p><small>{asset.assetTag} · {asset.site}</small></div><span className={`schedule-status ${schedule.status.toLowerCase()}`}>{schedule.status}</span></article>)}{schedules.length === 0 && <div className="empty-state wide"><span>□</span><strong>No schedules yet</strong><p>Add a schedule to an asset to see it here.</p></div>}</div></div>;
}

function InstitutionsView({ institutions, assets }: { institutions: Institution[]; assets: Asset[] }) {
  return <div className="page-content"><div className="page-intro"><div><h2>Institution network</h2><p>Campuses connected to the shared resource platform.</p></div></div><div className="institution-grid">{institutions.map((institution, index) => { const institutionAssets = assets.filter((asset) => asset.institution === institution.name); return <article className="institution-card" key={institution.name}><div className={`institution-mark mark-${index % 3}`}>{institution.name.split(" ").filter((word) => word[0] === word[0]?.toUpperCase()).slice(0, 2).map((word) => word[0]).join("")}</div><h3>{institution.name}</h3><p>{institution.sites.length} campuses · {institutionAssets.length} registered assets</p><div className="site-list">{institution.sites.map((site) => <span key={site}>⌖ {site}</span>)}</div><div className="institution-footer"><span><strong>{institutionAssets.filter((asset) => asset.status === "AVAILABLE").length}</strong> available</span><span><strong>{institutionAssets.filter((asset) => asset.status === "UNDER_MAINTENANCE").length}</strong> in maintenance</span></div></article>; })}</div></div>;
}

function AssetDrawer({ asset, onClose, onDelete, onSchedule, onLoan, onBook }: { asset: Asset; onClose: () => void; onDelete: () => void; onSchedule: () => void; onLoan: () => void; onBook: () => void }) {
  return <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}><aside className="drawer" aria-label="Asset details"><div className="drawer-header"><div className="drawer-title"><AssetGlyph name={asset.name} /><div><small>{asset.assetTag}</small><h2>{asset.name}</h2></div></div><button className="close-button" onClick={onClose} aria-label="Close">×</button></div><StatusPill status={asset.status} /><p className="drawer-description">{asset.description || "No description provided."}</p><div className="detail-grid"><Detail label="Institution" value={asset.institution} /><Detail label="Site / campus" value={asset.site} /><Detail label="Date acquired" value={asset.dateAcquired} /><Detail label="Asset tag" value={asset.assetTag} /></div><div className="drawer-section"><div className="drawer-section-heading"><h3>Schedules</h3><button onClick={onSchedule}>＋ Add</button></div>{asset.schedules.length ? asset.schedules.map((schedule) => <div className="mini-record" key={schedule.scheduleId}><span className="record-icon">□</span><div><strong>{schedule.type}</strong><small>{schedule.description} · Due {schedule.dueDate}</small></div><span className={isOverdue(schedule) ? "danger-text" : "muted"}>{isOverdue(schedule) ? "Overdue" : schedule.status}</span></div>) : <p className="muted-block">No schedules recorded.</p>}</div><div className="drawer-section"><h3>Components & work orders</h3><div className="record-summary"><span><strong>{asset.components.length}</strong> components</span><span><strong>{asset.workOrders.filter((order) => order.status !== "CLOSED").length}</strong> open work orders</span></div></div><div className="drawer-actions">{asset.status === "AVAILABLE" && <><button className="secondary-button" onClick={onLoan}>Loan asset</button><button className="secondary-button" onClick={onBook}>Book resource</button></>}<button className="danger-button" onClick={onDelete}>Delete</button></div></aside></div>;
}

function Detail({ label, value }: { label: string; value: string }) { return <div><span>{label}</span><strong>{value}</strong></div>; }

function AssetForm({ institutions, onClose, onSaved }: { institutions: Institution[]; onClose: () => void; onSaved: () => void }) {
  const [institution, setInstitution] = useState(institutions[0]?.name || ""); const [saving, setSaving] = useState(false); const [formError, setFormError] = useState(""); const selectedInstitution = institutions.find((item) => item.name === institution);
  async function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setSaving(true); setFormError(""); const form = new FormData(event.currentTarget); const payload = { assetTag: String(form.get("assetTag")), name: String(form.get("name")), description: String(form.get("description")), institution, site: String(form.get("site")), dateAcquired: String(form.get("dateAcquired")), status: String(form.get("status")), components: [], schedules: [], workOrders: [] }; try { await api("/assets", { method: "POST", body: JSON.stringify(payload) }); onSaved(); } catch (requestError) { setFormError(requestError instanceof Error ? requestError.message : "Could not add asset"); } finally { setSaving(false); } }
  return <Modal title="Register a new asset" subtitle="Add a resource to the ministry network." onClose={onClose}><form className="form" onSubmit={submit}>{formError && <p className="form-error">{formError}</p>}<div className="field-row"><label>Asset tag<input name="assetTag" placeholder="NUST-LIB-001" required /></label><label>Status<select name="status" defaultValue="AVAILABLE"><option>AVAILABLE</option><option>UNDER_MAINTENANCE</option><option>DISPOSED</option></select></label></div><label>Asset name<input name="name" placeholder="e.g. Dell Latitude 5440" required /></label><label>Description<textarea name="description" placeholder="Describe the resource and its purpose" rows={3} /></label><label>Institution<select value={institution} onChange={(event) => setInstitution(event.target.value)}>{institutions.map((item) => <option key={item.name}>{item.name}</option>)}</select></label><div className="field-row"><label>Site / campus<select name="site" key={institution}>{selectedInstitution?.sites.map((site) => <option key={site}>{site}</option>)}</select></label><label>Date acquired<input name="dateAcquired" type="date" required /></label></div><FormActions onClose={onClose} saving={saving} label="Add asset" /></form></Modal>;
}

function ScheduleForm({ asset, onClose, onSaved }: { asset: Asset; onClose: () => void; onSaved: () => void }) {
  const [saving, setSaving] = useState(false); const [formError, setFormError] = useState("");
  async function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setSaving(true); setFormError(""); const form = new FormData(event.currentTarget); const payload = { scheduleId: String(form.get("scheduleId")), type: String(form.get("type")), dueDate: String(form.get("dueDate")), description: String(form.get("description")), status: "PENDING" }; try { await api(`/assets/${encodeURIComponent(asset.assetTag)}/schedules`, { method: "POST", body: JSON.stringify(payload) }); onSaved(); } catch (requestError) { setFormError(requestError instanceof Error ? requestError.message : "Could not add schedule"); } finally { setSaving(false); } }
  return <Modal title="Add a schedule" subtitle={`${asset.name} · ${asset.assetTag}`} onClose={onClose}><form className="form" onSubmit={submit}>{formError && <p className="form-error">{formError}</p>}<div className="field-row"><label>Schedule ID<input name="scheduleId" placeholder="SCH-101" required /></label><label>Type<select name="type"><option>MAINTENANCE</option><option>BOOKING</option><option>LOAN</option><option>SERVICING</option></select></label></div><label>Due date<input name="dueDate" type="date" required /></label><label>Description<textarea name="description" rows={3} placeholder="What needs to happen?" /></label><FormActions onClose={onClose} saving={saving} label="Save schedule" /></form></Modal>;
}

function ActivityForm({ asset, type, onClose, onSaved }: { asset: Asset; type: "loan" | "book"; onClose: () => void; onSaved: () => void }) {
  const [saving, setSaving] = useState(false); const [formError, setFormError] = useState(""); const personLabel = type === "loan" ? "Borrower name" : "Booked by";
  async function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setSaving(true); setFormError(""); const form = new FormData(event.currentTarget); const name = String(form.get("person")); const payload = type === "loan" ? { borrower: name, dueDate: String(form.get("dueDate")), description: String(form.get("description")) } : { bookedBy: name, dueDate: String(form.get("dueDate")), description: String(form.get("description")) }; try { await api(`/assets/${encodeURIComponent(asset.assetTag)}/${type}`, { method: "POST", body: JSON.stringify(payload) }); onSaved(); } catch (requestError) { setFormError(requestError instanceof Error ? requestError.message : `Could not ${type} asset`); } finally { setSaving(false); } }
  return <Modal title={type === "loan" ? "Loan this asset" : "Book this resource"} subtitle={`${asset.name} · ${asset.site}`} onClose={onClose}><form className="form" onSubmit={submit}>{formError && <p className="form-error">{formError}</p>}<label>{personLabel}<input name="person" required placeholder="Enter a full name" /></label><label>Due date<input name="dueDate" type="date" required /></label><label>Note<textarea name="description" rows={3} placeholder="Optional purpose or booking note" /></label><FormActions onClose={onClose} saving={saving} label={type === "loan" ? "Confirm loan" : "Confirm booking"} /></form></Modal>;
}

function Modal({ title, subtitle, onClose, children }: { title: string; subtitle: string; onClose: () => void; children: React.ReactNode }) { return <div className="overlay centered" onMouseDown={(event) => event.target === event.currentTarget && onClose()}><section className="modal" role="dialog" aria-modal="true" aria-label={title}><div className="modal-header"><div><h2>{title}</h2><p>{subtitle}</p></div><button className="close-button" onClick={onClose} aria-label="Close">×</button></div>{children}</section></div>; }
function FormActions({ onClose, saving, label }: { onClose: () => void; saving: boolean; label: string }) { return <div className="form-actions"><button type="button" className="secondary-button" onClick={onClose}>Cancel</button><button className="primary-button" disabled={saving}>{saving ? "Saving…" : label}</button></div>; }
function StatusPill({ status }: { status: AssetStatus }) { return <span className={`status-pill ${status.toLowerCase()}`}><i />{statusLabel[status]}</span>; }
function AssetGlyph({ name }: { name: string }) { const lower = name.toLowerCase(); const glyph = lower.includes("book") || lower.includes("distributed") ? "B" : lower.includes("room") || lower.includes("lab") ? "R" : lower.includes("printer") ? "P" : "D"; return <span className={`asset-glyph glyph-${glyph.toLowerCase()}`} aria-hidden="true">{glyph}</span>; }
