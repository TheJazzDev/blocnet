export default function SettingsPage() {
  return (
    <>
      <div className="topbar">
        <strong>Settings</strong>
        <form action="/signout" method="post">
          <button className="button danger" type="submit">
            Sign Out
          </button>
        </form>
      </div>
      <div className="card">
        <h3>Admin Settings Shell</h3>
        <p className="muted">
          Placeholder for environment diagnostics, notification policies, and
          moderation defaults.
        </p>
      </div>
    </>
  );
}
