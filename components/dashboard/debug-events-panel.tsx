"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { useEventsDebug } from "@/hooks/use-events-debug"
import { useState } from "react"
import { ChevronDown, ChevronUp, RefreshCw } from "lucide-react"

export function DebugEventsPanel() {
  const { events, loading, error, debugInfo } = useEventsDebug()
  const [showDebug, setShowDebug] = useState(false)

  return (
    <Card className="border-orange-200 bg-orange-50/50 dark:bg-orange-900/10">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-orange-800 dark:text-orange-200">🔍 Debug Panel - Próximos Eventos</CardTitle>
          <div className="flex items-center space-x-2">
            <Badge variant="outline" className="text-orange-600">
              {loading ? "Cargando..." : `${events.length} eventos`}
            </Badge>
            <Button variant="outline" size="sm" onClick={() => setShowDebug(!showDebug)}>
              {showDebug ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
              Debug
            </Button>
            <Button variant="outline" size="sm" onClick={() => window.location.reload()}>
              <RefreshCw className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Status Summary */}
        <div className="grid grid-cols-3 gap-4 text-sm">
          <div className="text-center p-2 bg-white/50 rounded">
            <div className="font-semibold text-lg">{loading ? "..." : events.length}</div>
            <div className="text-muted-foreground">Eventos</div>
          </div>
          <div className="text-center p-2 bg-white/50 rounded">
            <div className="font-semibold text-lg">{error ? "❌" : "✅"}</div>
            <div className="text-muted-foreground">Estado</div>
          </div>
          <div className="text-center p-2 bg-white/50 rounded">
            <div className="font-semibold text-lg">{debugInfo.timestamp ? "✅" : "⏳"}</div>
            <div className="text-muted-foreground">Debug</div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="p-3 bg-red-100 border border-red-200 rounded text-red-800 text-sm">
            <strong>Error:</strong> {error}
          </div>
        )}

        {/* Events List */}
        {events.length > 0 && (
          <div className="space-y-2">
            <h4 className="font-semibold text-sm">Eventos Encontrados:</h4>
            {events.slice(0, 3).map((event) => (
              <div key={event.id} className="p-2 bg-white/50 rounded text-sm">
                <div className="font-medium">{event.title}</div>
                <div className="text-muted-foreground">
                  {event.facilitator_name} • {new Date(event.event_date).toLocaleDateString("es-ES")}
                </div>
              </div>
            ))}
            {events.length > 3 && (
              <div className="text-xs text-muted-foreground">... y {events.length - 3} eventos más</div>
            )}
          </div>
        )}

        {/* Debug Info */}
        {showDebug && debugInfo.steps && (
          <div className="space-y-2">
            <h4 className="font-semibold text-sm">Debug Steps:</h4>
            <div className="max-h-60 overflow-y-auto bg-black/5 p-3 rounded text-xs font-mono space-y-1">
              {debugInfo.steps.map((step: string, index: number) => (
                <div
                  key={index}
                  className={
                    step.includes("❌")
                      ? "text-red-600"
                      : step.includes("✅")
                        ? "text-green-600"
                        : step.includes("⚠️")
                          ? "text-orange-600"
                          : "text-muted-foreground"
                  }
                >
                  {step}
                </div>
              ))}
            </div>

            {/* Detailed Debug Info */}
            {debugInfo.connectionTest && (
              <div className="text-xs space-y-1">
                <div>
                  <strong>Conexión:</strong> {debugInfo.connectionTest.success ? "✅" : "❌"}
                </div>
                <div>
                  <strong>RPC:</strong> {debugInfo.rpcQuery?.success ? "✅" : "❌"} ({debugInfo.rpcQuery?.count || 0}{" "}
                  eventos)
                </div>
                <div>
                  <strong>Join:</strong> {debugInfo.joinQuery?.success ? "✅" : "❌"} ({debugInfo.joinQuery?.count || 0}{" "}
                  eventos)
                </div>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
