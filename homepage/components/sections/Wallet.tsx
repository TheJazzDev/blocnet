'use client';

export function Wallet() {
  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background Grid */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />

      <div className="relative z-10 max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-10 items-center">
          {/* Content */}
          <div>
            <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
              Multi-Asset <span className="text-teal-400">Wallet</span>
            </h2>

            <p className="text-sm sm:text-base text-muted mb-6 sm:mb-8">
              Manage all your crypto assets in one place. Track balances, view
              USD values, and make transfers with ease.
            </p>

            <div className="space-y-3 sm:space-y-4 mb-6 sm:mb-8">
              {[
                {
                  icon: '🔒',
                  title: 'Secure Storage',
                  description: 'Industry-standard security with KYC protection',
                },
                {
                  icon: '💱',
                  title: 'Multi-Asset Support',
                  description: 'BNT and other crypto assets in one wallet',
                },
                {
                  icon: '📊',
                  title: 'Real-time Pricing',
                  description: 'Live USD conversion and asset tracking',
                },
                {
                  icon: '⚡',
                  title: 'Instant Transfers',
                  description: 'Quick internal transfers and withdrawals',
                },
              ].map((feature) => (
                <div key={feature.title} className="flex gap-3 sm:gap-4">
                  <div className="shrink-0 w-10 h-10 sm:w-12 sm:h-12 flex items-center justify-center bg-teal-500/10 rounded-lg text-lg sm:text-xl">
                    {feature.icon}
                  </div>
                  <div>
                    <h4 className="text-sm sm:text-base font-semibold text-foreground mb-0.5 sm:mb-1">
                      {feature.title}
                    </h4>
                    <p className="text-xs sm:text-sm text-muted">
                      {feature.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <a
              href="#"
              className="inline-block px-5 py-2.5 sm:px-6 sm:py-3 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base"
            >
              Open Wallet
            </a>
          </div>

          {/* Wallet Card Mockup */}
          <div className="relative">
            <div className="relative p-5 sm:p-6 bg-surface-2 border border-border rounded-xl">
              {/* Wallet Header */}
              <div className="flex items-center justify-between mb-6 sm:mb-7">
                <div>
                  <div className="text-xs sm:text-sm text-muted mb-1">
                    Total Balance
                  </div>
                  <div className="text-2xl sm:text-3xl font-bold text-foreground">
                    $12,450.00
                  </div>
                </div>
                <div className="w-10 h-10 sm:w-12 sm:h-12 bg-teal-500/10 rounded-full flex items-center justify-center text-lg sm:text-xl">
                  💼
                </div>
              </div>

              {/* Asset Cards */}
              <div className="space-y-3 sm:space-y-4">
                {[
                  {
                    symbol: 'BNT',
                    name: 'Blocnet Token',
                    amount: '8,450',
                    value: '$10,125.00',
                    change: '+5.2%',
                    positive: true,
                  },
                  {
                    symbol: 'BNB',
                    name: 'BNB',
                    amount: '3.5',
                    value: '$2,325.00',
                    change: '+2.1%',
                    positive: true,
                  },
                ].map((asset) => (
                  <div
                    key={asset.symbol}
                    className="p-3 sm:p-4 bg-surface border border-border rounded-lg"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 sm:gap-3">
                        <div className="w-8 h-8 sm:w-10 sm:h-10 bg-teal-500/10 rounded-full flex items-center justify-center text-teal-400 font-bold text-xs sm:text-sm">
                          {asset.symbol.charAt(0)}
                        </div>
                        <div>
                          <div className="text-sm sm:text-base font-semibold text-foreground">
                            {asset.symbol}
                          </div>
                          <div className="text-xs sm:text-sm text-muted">
                            {asset.name}
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-sm sm:text-base font-semibold text-foreground">
                          {asset.amount}
                        </div>
                        <div className="flex items-center gap-1.5 sm:gap-2">
                          <span className="text-xs sm:text-sm text-muted">
                            {asset.value}
                          </span>
                          <span
                            className={`text-xs sm:text-sm ${
                              asset.positive ? 'text-green-400' : 'text-red-400'
                            }`}
                          >
                            {asset.change}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Action Buttons */}
              <div className="grid grid-cols-2 gap-2 sm:gap-3 mt-4 sm:mt-5">
                <button className="px-3 py-2 sm:px-4 sm:py-2.5 bg-teal-500 text-white rounded-lg font-medium text-xs sm:text-sm">
                  Transfer
                </button>
                <button className="px-3 py-2 sm:px-4 sm:py-2.5 bg-surface border border-border text-foreground rounded-lg font-medium text-xs sm:text-sm">
                  Withdraw
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Transaction History Preview */}
        <div className="mt-10 sm:mt-12">
          <div className="flex items-center justify-between mb-4 sm:mb-5">
            <h3 className="text-lg sm:text-xl font-bold text-foreground">
              Recent Transactions
            </h3>
            <a
              href="#"
              className="text-xs sm:text-sm text-teal-400"
            >
              View All →
            </a>
          </div>

          <div className="space-y-2 sm:space-y-3">
            {[
              {
                type: 'Received',
                amount: '+125 BNT',
                time: '2 hours ago',
                positive: true,
              },
              {
                type: 'Mining Claim',
                amount: '+450 BNT',
                time: '1 day ago',
                positive: true,
              },
              {
                type: 'Transfer',
                amount: '-50 BNT',
                time: '3 days ago',
                positive: false,
              },
            ].map((tx, index) => (
              <div
                key={index}
                className="flex items-center justify-between p-3 sm:p-4 bg-surface-2/50 border border-border rounded-lg"
              >
                <div className="flex items-center gap-2 sm:gap-3">
                  <div
                    className={`w-8 h-8 sm:w-10 sm:h-10 ${
                      tx.positive ? 'bg-teal-500/10' : 'bg-red-500/10'
                    } rounded-full flex items-center justify-center text-sm sm:text-base`}
                  >
                    {tx.positive ? '↓' : '↑'}
                  </div>
                  <div>
                    <div className="text-xs sm:text-sm font-semibold text-foreground">
                      {tx.type}
                    </div>
                    <div className="text-[10px] sm:text-xs text-muted">
                      {tx.time}
                    </div>
                  </div>
                </div>
                <div
                  className={`text-xs sm:text-sm font-semibold ${
                    tx.positive ? 'text-teal-400' : 'text-red-400'
                  }`}
                >
                  {tx.amount}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
