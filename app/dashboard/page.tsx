"use client"

import { useDashboardData } from "@/hooks/use-dashboard-data"
import { DashboardOverview } from "@/components/dashboard/dashboard-overview"
import { TokenBalance } from "@/components/dashboard/token-balance"

export default function DashboardPage() {
  const { stats, loading, error, refreshData } = useDashboardData()

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-red-600 mb-4">Error Loading Dashboard</h1>
          <p className="text-gray-600 mb-4">{error}</p>
          <button onClick={refreshData} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            Try Again
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 space-y-8">
      {/* Welcome Message */}
      <DashboardOverview />

      {/* Token Balance Card */}
      <TokenBalance
        balance={stats.tokenBalance}
        totalEarned={stats.totalEarned}
        totalSpent={stats.totalSpent}
        pendingBalance={stats.pendingBalance}
        loading={loading}
        onRefresh={refreshData}
      />
    </div>
  )
}
