import { CheckCircle2, CircleDollarSign, FileCheck2, Scale, ShieldCheck } from "lucide-react";
import { EscrowDashboard } from "@/components/EscrowDashboard";

const workflow = [
  {
    title: "Fund",
    body: "The client deposits the full USDC budget into the escrow contract before work starts.",
    icon: CircleDollarSign
  },
  {
    title: "Approve",
    body: "Each milestone stores a delivery hash and requires explicit client approval before release.",
    icon: FileCheck2
  },
  {
    title: "Release",
    body: "Approved milestones can be released by either party, reducing manual payment friction.",
    icon: CheckCircle2
  },
  {
    title: "Resolve",
    body: "If work stalls, either side can open a dispute and the arbiter splits the unreleased balance.",
    icon: Scale
  }
];

export default function Home() {
  return (
    <main>
      <section className="hero">
        <div className="heroCopy">
          <p className="eyebrow">Remote work payments for Web3 teams</p>
          <h1>Milestone-based USDC escrow for clients and freelancers.</h1>
          <p className="lead">
            A portfolio-grade protocol showing smart contract design, payment flows, dispute handling,
            and dApp product thinking for remote blockchain engineering roles.
          </p>
          <div className="actions">
            <a href="https://github.com/2hevva" className="button primary">
              View GitHub
            </a>
            <a href="#contract" className="button secondary">
              Review Contract Flow
            </a>
          </div>
        </div>
        <EscrowDashboard />
      </section>

      <section className="section" id="contract">
        <div className="sectionHeader">
          <p className="eyebrow">Protocol workflow</p>
          <h2>Simple enough to audit, realistic enough to discuss.</h2>
        </div>
        <div className="workflowGrid">
          {workflow.map((item) => {
            const Icon = item.icon;
            return (
              <article className="workflowCard" key={item.title}>
                <Icon size={24} aria-hidden="true" />
                <h3>{item.title}</h3>
                <p>{item.body}</p>
              </article>
            );
          })}
        </div>
      </section>

      <section className="section split">
        <div>
          <p className="eyebrow">What this proves</p>
          <h2>Built for the questions hiring teams actually ask.</h2>
        </div>
        <div className="proofList">
          <div>
            <ShieldCheck size={22} aria-hidden="true" />
            <p>Custom errors, explicit state transitions, and reentrancy protection around token flows.</p>
          </div>
          <div>
            <ShieldCheck size={22} aria-hidden="true" />
            <p>Foundry tests covering funding, milestone releases, cancellation, and arbiter resolution.</p>
          </div>
          <div>
            <ShieldCheck size={22} aria-hidden="true" />
            <p>Frontend copy and layout focused on a real Web3 business use case, not a toy counter app.</p>
          </div>
        </div>
      </section>
    </main>
  );
}
