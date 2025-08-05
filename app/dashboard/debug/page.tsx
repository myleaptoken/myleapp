"use client"

import { DebugEventsPanel } from "@/components/dashboard/debug-events-panel"

export default function DebugPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Debug Dashboard</h1>
        <p className="text-muted-foreground">Panel de diagnóstico para eventos</p>
      </div>

      <DebugEventsPanel />
    </div>
  )
}
