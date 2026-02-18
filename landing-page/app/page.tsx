import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#09090b] text-[#f4f4f5] font-[var(--font-geist-sans)]">

      {/* ── Navbar ─────────────────────────────────────────────────────────── */}
      <header className="sticky top-0 z-50 border-b border-[#27272a] bg-[#09090b]/90 backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3 sm:px-6">
          <div className="flex items-center gap-2">
            <Image src="/logo.png" alt="Blocnet" width={32} height={32} className="rounded-lg" />
            <span className="text-base font-semibold tracking-tight">Blocnet</span>
          </div>
          <nav className="hidden items-center gap-6 text-sm text-[#71717a] sm:flex">
            <a href="#features" className="transition-colors hover:text-[#f4f4f5]">Features</a>
            <a href="#wallet" className="transition-colors hover:text-[#f4f4f5]">Wallet</a>
            <a href="#hunters" className="transition-colors hover:text-[#f4f4f5]">Hunters</a>
            <a href="#community" className="transition-colors hover:text-[#f4f4f5]">Community</a>
          </nav>
          <a
            href="https://x.com/blocnet"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 rounded-lg bg-[#2dd4bf] px-3 py-1.5 text-xs font-semibold text-[#09090b] transition-opacity hover:opacity-90 sm:px-4 sm:text-sm"
          >
            Follow on X
          </a>
        </div>
      </header>

      {/* ── Hero ───────────────────────────────────────────────────────────── */}
      <section className="relative overflow-hidden px-4 pb-16 pt-16 sm:px-6 sm:pb-24 sm:pt-24">
        <div
          className="pointer-events-none absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage:
              "linear-gradient(#2dd4bf 1px, transparent 1px), linear-gradient(90deg, #2dd4bf 1px, transparent 1px)",
            backgroundSize: "48px 48px",
          }}
        />
        <div className="pointer-events-none absolute left-1/2 top-0 h-72 w-72 -translate-x-1/2 rounded-full bg-[#2dd4bf]/10 blur-3xl sm:h-96 sm:w-96" />

        <div className="relative mx-auto max-w-3xl text-center">
          <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-[#2dd4bf]/30 bg-[#2dd4bf]/5 px-3 py-1 text-xs font-medium text-[#2dd4bf] sm:text-sm">
            <span className="inline-block h-1.5 w-1.5 rounded-full bg-[#2dd4bf]" />
            Welcome to the future of crypto connections
          </div>

          <h1 className="mb-4 text-3xl font-bold leading-tight tracking-tight sm:text-5xl md:text-6xl">
            Your one-stop hub for{" "}
            <span className="text-[#2dd4bf]">Web3 growth</span>
          </h1>

          <p className="mx-auto mb-8 max-w-xl text-sm leading-relaxed text-[#71717a] sm:text-base md:text-lg">
            A community of everything blockchain — mining updates, airdrop alerts,
            staking opportunities, jobs, learning, and more. Say{" "}
            <strong className="text-[#f4f4f5]">NO</strong> to missed airdrops
            and mining updates.
          </p>

          <div className="flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href="https://x.com/blocnet"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full rounded-xl bg-[#2dd4bf] px-6 py-3 text-sm font-semibold text-[#09090b] transition-opacity hover:opacity-90 sm:w-auto"
            >
              Join the Revolution →
            </a>
            <a
              href="#features"
              className="w-full rounded-xl border border-[#27272a] bg-[#111114] px-6 py-3 text-sm font-medium text-[#f4f4f5] transition-colors hover:border-[#3f3f46] sm:w-auto"
            >
              See Features
            </a>
          </div>
        </div>
      </section>

      {/* ── Community pillars ──────────────────────────────────────────────── */}
      <section id="community" className="border-y border-[#27272a] bg-[#111114] px-4 py-12 sm:px-6 sm:py-16">
        <div className="mx-auto max-w-6xl">
          <p className="mb-8 text-center text-xs font-semibold uppercase tracking-widest text-[#71717a] sm:text-sm">
            Everything blockchain, in one place
          </p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-6 md:gap-4">
            {[
              { icon: "⛏️", label: "Mining Updates" },
              { icon: "🎁", label: "Airdrop Alerts" },
              { icon: "🪙", label: "Staking" },
              { icon: "💼", label: "Web3 Jobs" },
              { icon: "📚", label: "Learning" },
              { icon: "🤝", label: "Community" },
            ].map((item) => (
              <div
                key={item.label}
                className="flex flex-col items-center gap-2 rounded-xl border border-[#27272a] bg-[#18181c] px-3 py-4 text-center sm:px-4 sm:py-5"
              >
                <span className="text-2xl">{item.icon}</span>
                <span className="text-xs font-medium text-[#a1a1aa] sm:text-sm">{item.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ───────────────────────────────────────────────────────── */}
      <section id="features" className="px-4 py-16 sm:px-6 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <div className="mb-10 text-center sm:mb-14">
            <h2 className="mb-3 text-2xl font-bold sm:text-3xl md:text-4xl">
              Everything you need to stay ahead
            </h2>
            <p className="mx-auto max-w-lg text-sm text-[#71717a] sm:text-base">
              Never miss a moment in crypto. Blocnet keeps you connected to what matters most.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 sm:gap-6 lg:grid-cols-4">
            {[
              {
                icon: "⚡",
                title: "Real-time Project Updates",
                desc: "Get instant intel from vetted hunters tracking the projects you follow.",
              },
              {
                icon: "🔔",
                title: "Airdrop & Mining Alerts",
                desc: "Never miss a drop or mining opportunity again — stay notified as it happens.",
              },
              {
                icon: "💎",
                title: "Curated Gems",
                desc: "Discover high-signal projects handpicked and verified by the Blocnet community.",
              },
              {
                icon: "🌐",
                title: "Web3 Jobs & Learning",
                desc: "Access job listings and educational resources to grow your Web3 career.",
              },
            ].map((f) => (
              <div
                key={f.title}
                className="rounded-2xl border border-[#27272a] bg-[#111114] p-5 sm:p-6"
              >
                <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-[#2dd4bf]/10 text-xl">
                  {f.icon}
                </div>
                <h3 className="mb-2 text-sm font-semibold text-[#f4f4f5] sm:text-base">{f.title}</h3>
                <p className="text-xs leading-relaxed text-[#71717a] sm:text-sm">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Wallet ─────────────────────────────────────────────────────────── */}
      <section id="wallet" className="border-y border-[#27272a] bg-[#111114] px-4 py-16 sm:px-6 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-col gap-10 lg:flex-row lg:items-center lg:gap-16">
            <div className="flex-1">
              <div className="mb-3 inline-flex items-center gap-2 rounded-full border border-[#2dd4bf]/30 bg-[#2dd4bf]/5 px-3 py-1 text-xs font-medium text-[#2dd4bf]">
                Coming Soon
              </div>
              <h2 className="mb-4 text-2xl font-bold leading-tight sm:text-3xl md:text-4xl">
                A wallet built for{" "}
                <span className="text-[#2dd4bf]">Web3 natives</span>
              </h2>
              <p className="mb-6 text-sm leading-relaxed text-[#71717a] sm:text-base">
                The Blocnet wallet is your gateway to the decentralised economy.
                Fund, send, receive, and earn — all without leaving the app.
              </p>
              <ul className="space-y-3">
                {[
                  { icon: "💰", text: "Fund wallet & convert to BNT at live rates" },
                  { icon: "🎁", text: "Tip hunters who give you valuable alpha" },
                  { icon: "🏆", text: "Earn BNT for quality engagement & referrals" },
                  { icon: "↔️", text: "P2P transfers & withdraw to external wallets" },
                ].map((item) => (
                  <li key={item.text} className="flex items-start gap-3 text-sm text-[#a1a1aa] sm:text-base">
                    <span className="mt-0.5 shrink-0 text-base">{item.icon}</span>
                    {item.text}
                  </li>
                ))}
              </ul>
            </div>

            <div className="flex flex-1 justify-center lg:justify-end">
              <div className="w-full max-w-sm rounded-2xl border border-[#27272a] bg-[#18181c] p-6">
                <div className="mb-4 flex items-center gap-3">
                  <Image src="/logo.png" alt="Blocnet" width={40} height={40} className="rounded-full" />
                  <div>
                    <p className="text-xs font-medium text-[#f4f4f5]">BlocNet Token</p>
                    <p className="text-xs text-[#71717a]">BNT</p>
                  </div>
                </div>
                <p className="mb-1 text-xs uppercase tracking-widest text-[#71717a]">Total Balance</p>
                <div className="mb-4 flex items-end gap-2">
                  <span className="text-4xl font-bold text-[#f4f4f5]">0</span>
                  <span className="mb-1 text-base font-semibold text-[#2dd4bf]">BNT</span>
                </div>
                <p className="mb-5 text-xs text-[#52525b]">≈ $0.00 USD</p>
                <div className="grid grid-cols-4 gap-2">
                  {["Send", "Receive", "Swap", "Buy"].map((a) => (
                    <div
                      key={a}
                      className="flex flex-col items-center gap-1 rounded-xl border border-[#27272a] bg-[#111114] py-2"
                    >
                      <span className="text-xs text-[#71717a]">{a}</span>
                    </div>
                  ))}
                </div>
                <div className="mt-4 rounded-xl border border-[#2dd4bf]/20 bg-[#2dd4bf]/5 px-4 py-3 text-center text-xs text-[#2dd4bf]">
                  🔔 Notify me at launch
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Hunter System ──────────────────────────────────────────────────── */}
      <section id="hunters" className="px-4 py-16 sm:px-6 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <div className="mb-10 text-center sm:mb-14">
            <h2 className="mb-3 text-2xl font-bold sm:text-3xl md:text-4xl">
              Meet the <span className="text-[#2dd4bf]">Hunters</span>
            </h2>
            <p className="mx-auto max-w-xl text-sm text-[#71717a] sm:text-base">
              Blocnet recognises creators who dedicate time to researching
              airdrops, mining apps, and trading calls. The community rewards them directly.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-3 sm:gap-6">
            {[
              {
                icon: "🕵️",
                title: "Research & Signal",
                desc: "Hunters dig deep into airdrop listings, mining opportunities, buy signals, and futures calls — then post verified updates for the community.",
              },
              {
                icon: "💸",
                title: "Community Tips",
                desc: "Members who benefit from hunter intel can tip them directly in BNT as a token of appreciation. Your alpha has real value.",
              },
              {
                icon: "🏅",
                title: "Elite Status",
                desc: "Top hunters earn Elite status based on accuracy and community feedback, unlocking visibility and platform rewards.",
              },
            ].map((h) => (
              <div
                key={h.title}
                className="rounded-2xl border border-[#27272a] bg-[#111114] p-5 sm:p-6"
              >
                <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-[#6366f1]/10 text-xl">
                  {h.icon}
                </div>
                <h3 className="mb-2 text-sm font-semibold text-[#f4f4f5] sm:text-base">{h.title}</h3>
                <p className="text-xs leading-relaxed text-[#71717a] sm:text-sm">{h.desc}</p>
              </div>
            ))}
          </div>

          <div className="mt-6 rounded-2xl border border-[#6366f1]/20 bg-[#6366f1]/5 p-5 text-center sm:mt-8 sm:p-6">
            <p className="text-sm text-[#a1a1aa] sm:text-base">
              🎉 Community members benefiting from hunter updates will be able to tip admins as a token of appreciation and support.
            </p>
          </div>
        </div>
      </section>

      {/* ── CTA ────────────────────────────────────────────────────────────── */}
      <section className="border-t border-[#27272a] bg-[#111114] px-4 py-16 sm:px-6 sm:py-24">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="mb-4 text-2xl font-bold sm:text-3xl md:text-4xl">
            Join the revolution
          </h2>
          <p className="mb-8 text-sm leading-relaxed text-[#71717a] sm:text-base">
            Be part of the fastest growing Web3 community. Stay ahead of the
            market, connect with top hunters, and never miss another alpha drop.
          </p>
          <div className="flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href="https://x.com/blocnet"
              target="_blank"
              rel="noopener noreferrer"
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#2dd4bf] px-6 py-3 text-sm font-semibold text-[#09090b] transition-opacity hover:opacity-90 sm:w-auto"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.746l7.73-8.835L1.254 2.25H8.08l4.259 5.631 5.905-5.631Zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
              </svg>
              Follow @blocnet
            </a>
            <a
              href="#features"
              className="w-full rounded-xl border border-[#27272a] bg-transparent px-6 py-3 text-sm font-medium text-[#f4f4f5] transition-colors hover:border-[#3f3f46] sm:w-auto"
            >
              Learn More
            </a>
          </div>
        </div>
      </section>

      {/* ── Footer ─────────────────────────────────────────────────────────── */}
      <footer className="border-t border-[#27272a] px-4 py-8 sm:px-6">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 sm:flex-row">
          <div className="flex items-center gap-2">
            <Image src="/logo.png" alt="Blocnet" width={28} height={28} className="rounded-lg" />
            <span className="text-sm font-semibold">Blocnet</span>
          </div>

          <p className="text-center text-xs text-[#52525b]">
            BNT is Blocnet&apos;s native utility token. Not a security or financial instrument.
            All wallet features are under active development.
          </p>

          <a
            href="https://x.com/blocnet"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 text-xs text-[#71717a] transition-colors hover:text-[#f4f4f5]"
          >
            <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-current" aria-hidden="true">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.746l7.73-8.835L1.254 2.25H8.08l4.259 5.631 5.905-5.631Zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
            </svg>
            @blocnet
          </a>
        </div>
      </footer>

    </div>
  );
}
