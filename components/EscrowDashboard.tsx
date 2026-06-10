const milestones = [
  {
    name: "Scope and wireframes",
    amount: "1,000 USDC",
    status: "Released"
  },
  {
    name: "Smart contract delivery",
    amount: "2,000 USDC",
    status: "Approved"
  },
  {
    name: "Frontend integration",
    amount: "2,500 USDC",
    status: "Pending"
  }
];

export function EscrowDashboard() {
  return (
    <aside className="dashboard" aria-label="Escrow dashboard preview">
      <div className="dashboardTop">
        <div>
          <p className="muted">Escrow Balance</p>
          <strong>4,500 USDC</strong>
        </div>
        <span>Funded</span>
      </div>

      <div className="progress">
        <div />
      </div>

      <div className="partyGrid">
        <div>
          <p className="muted">Client</p>
          <strong>0xC11E...42c9</strong>
        </div>
        <div>
          <p className="muted">Freelancer</p>
          <strong>0xF411...9e03</strong>
        </div>
      </div>

      <div className="milestones">
        {milestones.map((milestone) => (
          <div className="milestone" key={milestone.name}>
            <div>
              <strong>{milestone.name}</strong>
              <p>{milestone.amount}</p>
            </div>
            <span data-status={milestone.status}>{milestone.status}</span>
          </div>
        ))}
      </div>

      <div className="dashboardActions">
        <button type="button">Approve milestone</button>
        <button type="button">Open dispute</button>
      </div>
    </aside>
  );
}
