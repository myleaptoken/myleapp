"use client"

import { useState, useEffect } from "react"
import { supabase } from "@/lib/supabase"
import { useAuth } from "@/hooks/use-auth"

interface DashboardStats {
  tokenBalance: number
  totalEarned: number
  totalSpent: number
  pendingBalance: number
  completedEvents: number
  recentTransactions: any[]
}

export function useDashboardData() {
  const { user } = useAuth()
  const [stats, setStats] = useState<DashboardStats>({
    tokenBalance: 0,
    totalEarned: 0,
    totalSpent: 0,
    pendingBalance: 0,
    completedEvents: 0,
    recentTransactions: [],
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchDashboardData = async () => {
    if (!user) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      setError(null)

      console.log("🔄 Fetching dashboard data for user:", user.id)

      // Primero intentar con la función atómica
      let tokenBalance = 0
      let totalEarned = 0
      let totalSpent = 0
      let pendingBalance = 0

      try {
        const { data: balanceData, error: balanceError } = await supabase.rpc("get_user_balance_atomic", {
          p_user_id: user.id,
        })

        if (balanceError) {
          console.error("❌ Error with atomic balance:", balanceError)
          throw balanceError
        }

        if (balanceData && balanceData.length > 0) {
          const balance = balanceData[0]
          tokenBalance = Number(balance.available_balance) || 0
          totalEarned = Number(balance.total_earned) || 0
          totalSpent = Number(balance.total_spent) || 0
          pendingBalance = Number(balance.pending_balance) || 0
          console.log("✅ Got atomic balance:", { tokenBalance, totalEarned, totalSpent, pendingBalance })
        }
      } catch (atomicError) {
        console.error("❌ Atomic balance failed, trying fallback:", atomicError)

        // Fallback 1: user_balances table
        try {
          const { data: userBalanceData, error: userBalanceError } = await supabase
            .from("user_balances")
            .select("available_balance, total_earned, total_spent, pending_balance")
            .eq("user_id", user.id)
            .eq("balance_type", "tokens")
            .single()

          if (!userBalanceError && userBalanceData) {
            tokenBalance = Number(userBalanceData.available_balance) || 0
            totalEarned = Number(userBalanceData.total_earned) || 0
            totalSpent = Number(userBalanceData.total_spent) || 0
            pendingBalance = Number(userBalanceData.pending_balance) || 0
            console.log("✅ Got balance from user_balances:", { tokenBalance, totalEarned, totalSpent })
          } else {
            throw new Error("No user_balances data")
          }
        } catch (userBalanceError) {
          console.error("❌ user_balances failed, trying users table:", userBalanceError)

          // Fallback 2: users table (más confiable)
          const { data: userData, error: userError } = await supabase
            .from("users")
            .select("token_balance")
            .eq("id", user.id)
            .single()

          if (userError) {
            console.error("❌ users table failed:", userError)
            throw userError
          }

          tokenBalance = Number(userData?.token_balance) || 0
          totalEarned = tokenBalance // Asumir que todo es earned si no hay otros datos
          totalSpent = 0
          pendingBalance = 0
          console.log("✅ Got balance from users table (final fallback):", tokenBalance)
        }
      }

      // Validar que los números sean válidos
      tokenBalance = isNaN(tokenBalance) ? 0 : tokenBalance
      totalEarned = isNaN(totalEarned) ? 0 : totalEarned
      totalSpent = isNaN(totalSpent) ? 0 : totalSpent
      pendingBalance = isNaN(pendingBalance) ? 0 : pendingBalance

      // Obtener transacciones recientes (opcional, no crítico)
      let recentTransactions = []
      try {
        const { data: transactionsData } = await supabase
          .from("token_transactions")
          .select("*")
          .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`)
          .order("created_at", { ascending: false })
          .limit(5)

        recentTransactions = transactionsData || []
      } catch (transactionError) {
        console.log("⚠️ Transactions not available:", transactionError)
      }

      const newStats = {
        tokenBalance,
        totalEarned,
        totalSpent,
        pendingBalance,
        completedEvents: 0,
        recentTransactions,
      }

      console.log("✅ Final dashboard stats:", newStats)
      setStats(newStats)
    } catch (err) {
      console.error("❌ Dashboard data error:", err)
      setError(err instanceof Error ? err.message : "Error loading dashboard data")

      // En caso de error total, al menos mostrar 0
      setStats({
        tokenBalance: 0,
        totalEarned: 0,
        totalSpent: 0,
        pendingBalance: 0,
        completedEvents: 0,
        recentTransactions: [],
      })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchDashboardData()
  }, [user])

  const refreshData = () => {
    console.log("🔄 Refreshing dashboard data...")
    fetchDashboardData()
  }

  return {
    stats,
    loading,
    error,
    refreshData,
  }
}
