"use client"

import { useEvents } from "@/hooks/use-events"
import { UpcomingEvents } from "@/components/dashboard/upcoming-events"
import { useAuth } from "@/hooks/use-auth"
import { Loader2 } from "lucide-react"
import { useEffect } from "react"

export default function EventsPage() {
  const { user, loading: authLoading } = useAuth()
  const { events, loading: eventsLoading, error: eventsError } = useEvents()

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  if (authLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center space-y-4">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="text-muted-foreground">Cargando eventos...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center space-y-4">
          <p className="text-muted-foreground">Acceso no autorizado</p>
        </div>
      </div>
    )
  }

  if (eventsError) {
    console.error("❌ Events error:", eventsError)
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Page Header */}
      <div className="space-y-2">
        <h1 className="text-2xl font-bold">Eventos</h1>
        <p className="text-muted-foreground">Descubre y participa en nuestros próximos eventos</p>
      </div>

      {/* Upcoming Events */}
      <UpcomingEvents events={events || []} loading={eventsLoading} />
    </div>
  )
}
