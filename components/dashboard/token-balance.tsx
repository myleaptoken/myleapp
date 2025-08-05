"use client"

import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Coins, TrendingUp, Send, Download } from "lucide-react"
import { SendTokensModal } from "./send-tokens-modal"
import { ReceiveTokensModal } from "./receive-tokens-modal"

interface TokenBalanceProps {
  balance?: number
  totalEarned?: number
  totalSpent?: number
  pendingBalance?: number
  loading?: boolean
  onRefresh?: () => void
}

export function TokenBalance({
  balance = 0,
  totalEarned = 0,
  totalSpent = 0,
  pendingBalance = 0,
  loading = false,
  onRefresh,
}: TokenBalanceProps) {
  const [showSendModal, setShowSendModal] = useState(false)
  const [showReceiveModal, setShowReceiveModal] = useState(false)

  const handleTransferComplete = () => {
    // Actualizar datos después de una transferencia exitosa
    if (onRefresh) {
      onRefresh()
    }
  }

  // Asegurar que balance sea un número válido
  const safeBalance = typeof balance === "number" && !isNaN(balance) ? Math.floor(balance) : 0
  const safeTotalEarned = typeof totalEarned === "number" && !isNaN(totalEarned) ? totalEarned : 0
  const safeTotalSpent = typeof totalSpent === "number" && !isNaN(totalSpent) ? totalSpent : 0

  if (loading) {
    return (
      <Card className="relative overflow-hidden border-0 shadow-2xl bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 dark:from-slate-800 dark:via-blue-800 dark:to-purple-800">
        <CardContent className="relative p-6 sm:p-8 lg:p-10">
          <div className="animate-pulse">
            <div className="h-6 bg-white/10 rounded mb-4"></div>
            <div className="h-12 bg-white/10 rounded mb-8"></div>
            <div className="grid grid-cols-2 gap-3">
              <div className="h-12 bg-white/10 rounded"></div>
              <div className="h-12 bg-white/10 rounded"></div>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      <Card className="relative overflow-hidden border-0 shadow-2xl bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 dark:from-slate-800 dark:via-blue-800 dark:to-purple-800">
        {/* Subtle overlay pattern */}
        <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent" />
        <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full blur-2xl transform translate-x-16 -translate-y-16" />

        <CardContent className="relative p-6 sm:p-8 lg:p-10">
          {/* Header */}
          <div className="flex items-start justify-between mb-8">
            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <span className="text-white/60 text-xs sm:text-sm font-medium uppercase tracking-wider">
                  Balance Actual
                </span>
              </div>
              <h3 className="text-xl sm:text-2xl lg:text-3xl font-bold text-white">Tokens LEAP</h3>
            </div>
            <div className="p-3 bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20">
              <Coins className="h-6 w-6 sm:h-7 sm:w-7 text-white/80" />
            </div>
          </div>

          {/* Balance Amount */}
          <div className="mb-8">
            <div className="flex items-baseline space-x-2 mb-2">
              <span className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white">{safeBalance}</span>
              <span className="text-white/60 text-lg sm:text-xl font-medium">LEAP</span>
            </div>
            <div className="flex items-center space-x-2 text-green-400">
              <TrendingUp className="h-4 w-4" />
              <span className="text-sm sm:text-base font-medium">
                +{safeTotalEarned > safeTotalSpent ? (safeTotalEarned - safeTotalSpent).toLocaleString() : "0"} esta
                semana
              </span>
              <span className="text-white/40 text-sm">+6.5%</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-3 sm:gap-4">
            <Button
              size="lg"
              onClick={() => setShowSendModal(true)}
              disabled={safeBalance <= 0}
              className="bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 hover:border-white/30 transition-all duration-300 rounded-xl h-12 sm:h-14"
            >
              <Send className="h-4 w-4 mr-2" />
              <span className="font-medium">Enviar</span>
            </Button>
            <Button
              size="lg"
              onClick={() => setShowReceiveModal(true)}
              className="bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 hover:border-white/30 transition-all duration-300 rounded-xl h-12 sm:h-14"
            >
              <Download className="h-4 w-4 mr-2" />
              <span className="font-medium">Recibir</span>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Modal para enviar tokens */}
      <SendTokensModal
        isOpen={showSendModal}
        onClose={() => setShowSendModal(false)}
        currentBalance={safeBalance}
        onTransferComplete={handleTransferComplete}
      />

      {/* Modal para recibir tokens */}
      <ReceiveTokensModal isOpen={showReceiveModal} onClose={() => setShowReceiveModal(false)} />
    </>
  )
}
