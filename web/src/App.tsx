import { useEffect, useState } from "react";

import "./App.css";

type SectionKey = "board" | "inbox" | "insights" | "threads";

type SectionItem = {
  title: string;
  detail: string;
};

type HealthStatus = {
  status: string;
  wal_mode: string;
  database_path?: string;
};

const sections: Record<SectionKey, SectionItem[]> = {
  board: [
    {
      title: "Sprint 12 delivery lane",
      detail: "6 stories active, 2 stale, 1 waiting on review",
    },
    {
      title: "Backend integration lane",
      detail: "Bootstrap work is ready for the first implementation pass",
    },
  ],
  inbox: [
    {
      title: "Approve board sync draft",
      detail: "Agent wants confirmation before moving two items to In Progress",
    },
    {
      title: "Clarify owner for Story 1842",
      detail: "Meeting transcript referenced new work without an assignee",
    },
  ],
  insights: [
    {
      title: "Repo drift detected",
      detail: "Merged branch activity is outpacing board state in one epic",
    },
    {
      title: "Backlog hygiene gap",
      detail: "Follow-up work from the last retro has no tracked stories yet",
    },
  ],
  threads: [
    {
      title: "Weekly planning sync",
      detail: "Transcript run produced 3 insights and 2 recommended actions",
    },
    {
      title: "Repo review pass",
      detail: "Commits suggest one PR should be linked to an existing story",
    },
  ],
};

const initialOpenSections: Record<SectionKey, boolean> = {
  board: true,
  inbox: true,
  insights: true,
  threads: true,
};

function App() {
  const [openSections, setOpenSections] = useState(initialOpenSections);
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [statusLabel, setStatusLabel] = useState("Checking backend...");

  useEffect(() => {
    let active = true;

    async function loadHealth() {
      try {
        const response = await fetch("/api/health");

        if (!response.ok) {
          throw new Error(`Health request failed with ${response.status}`);
        }

        const payload = (await response.json()) as HealthStatus;

        if (active) {
          setHealth(payload);
          setStatusLabel(`Backend online • SQLite ${payload.wal_mode.toUpperCase()}`);
        }
      } catch {
        if (active) {
          setHealth(null);
          setStatusLabel("Backend offline");
        }
      }
    }

    void loadHealth();

    return () => {
      active = false;
    };
  }, []);

  function toggleSection(section: SectionKey) {
    setOpenSections((current) => ({
      ...current,
      [section]: !current[section],
    }));
  }

  return (
    <main className="app-shell">
      <div className="workspace">
        <aside className="panel rail">
          <div>
            <p className="eyebrow">Local workspace</p>
            <h1>VPM</h1>
          </div>

          <div className="summary-card">
            <strong>Bootstrap slice is live</strong>
            <p>
              This shell is the first step toward the board, inbox, insights,
              and thread workflow discussed in the PR plan.
            </p>
          </div>

          {(Object.keys(sections) as SectionKey[]).map((section) => (
            <section className="section" key={section}>
              <button type="button" onClick={() => toggleSection(section)}>
                <span>{section.charAt(0).toUpperCase() + section.slice(1)}</span>
                <span>{openSections[section] ? "−" : "+"}</span>
              </button>

              {openSections[section] && (
                <ul className="section-list">
                  {sections[section].map((item) => (
                    <li key={item.title}>
                      <strong>{item.title}</strong>
                      <span className="meta">{item.detail}</span>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          ))}
        </aside>

        <section className="panel content">
          <header className="hero">
            <div>
              <p className="eyebrow">Demo workspace</p>
              <h2>Virtual Project Manager</h2>
              <p>
                The frontend now has a real shell, live backend health check,
                and the left-rail structure we discussed: Board, Inbox,
                Insights, and Threads.
              </p>
            </div>

            <div className={`status-chip${health ? "" : " offline"}`}>
              {statusLabel}
            </div>
          </header>

          <div className="content-grid">
            <div className="composer">
              <section className="composer-card">
                <p className="eyebrow">Transcript intake</p>
                <strong>Paste notes for the agent</strong>
                <p className="meta">
                  Agent orchestration is not wired yet, but this is the review
                  surface that later PRs will connect to chat, plays, insights,
                  and action approvals.
                </p>
                <textarea
                  readOnly
                  value={
                    "Sprint review transcript placeholder:\n- Story 1842 needs follow-up work split out\n- PR 91 likely belongs to the payment epic\n- Team agreed to move board status after merge"
                  }
                />
                <div className="composer-actions">
                  <button className="primary-button" type="button">
                    Stage recommendations
                  </button>
                  <button className="secondary-button" type="button">
                    Open thread details
                  </button>
                </div>
              </section>

              <section className="status-card">
                <p className="eyebrow">Backend details</p>
                <strong>Health endpoint</strong>
                <p className="meta">
                  {health
                    ? `SQLite file: ${health.database_path ?? "unavailable"}`
                    : "Start the FastAPI backend to populate live runtime details."}
                </p>
              </section>
            </div>

            <aside className="artifacts">
              <section className="artifact-card">
                <p className="eyebrow">What this proves</p>
                <strong>Demo-ready foundation</strong>
                <ul>
                  <li>FastAPI backend is wired and reachable from the UI.</li>
                  <li>SQLite opens in WAL mode for local multi-process use.</li>
                  <li>MCP entrypoint exists for local agent clients.</li>
                  <li>Workspace layout is aligned with the agreed UX narrative.</li>
                </ul>
              </section>

              <section className="artifact-card">
                <p className="eyebrow">Next slice</p>
                <strong>Configuration and persistence</strong>
                <p className="meta">
                  The next PR will replace placeholders with a real setup flow
                  so OpenAI and Azure DevOps credentials can be saved locally.
                </p>
              </section>
            </aside>
          </div>
        </section>
      </div>
    </main>
  );
}

export default App;
