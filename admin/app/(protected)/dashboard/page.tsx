export default function DashboardPage() {
  return (
    <>
      <div className="topbar">
        <strong>Dashboard</strong>
        <span className="muted">Shell mode</span>
      </div>
      <div className="grid">
        <div className="card">
          <h3>Total Projects</h3>
          <p className="muted">Wired later to /api/projects</p>
        </div>
        <div className="card">
          <h3>Pending Applications</h3>
          <p className="muted">Wired later to /api/admin-applications</p>
        </div>
        <div className="card">
          <h3>Unread Notifications</h3>
          <p className="muted">Wired later to moderation queue</p>
        </div>
      </div>
    </>
  );
}
