"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"

interface Event {
  id: string
  title: string
  description: string
  facilitator_name: string
  facilitator_bio: string
  facilitator_specialties: string[]
  facilitator_user_id: string
  event_date: string
  event_time: string
  event_date_formatted: string
  duration_minutes: number
  location: string
  is_online: boolean
  max_attendees: number
  current_attendees: number
  token_cost: number
  status: string
  image_url: string
  video_url: string
  what_includes: string[]
}

export function useEvents() {
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        console.log("🔍 Fetching events...")
        const supabase = createClientComponentClient()

        // Intentar usar la función RPC primero
        const { data: rpcData, error: rpcError } = await supabase.rpc("get_upcoming_events")

        if (rpcError) {
          console.error("❌ RPC function failed:", rpcError.message)

          // Fallback: query directo
          console.log("🔄 Falling back to direct query...")
          const { data: queryData, error: queryError } = await supabase
            .from("events")
            .select(`
              id,
              title,
              description,
              event_date,
              duration_minutes,
              location,
              is_online,
              max_attendees,
              current_attendees,
              token_cost,
              status,
              image_url,
              video_url,
              what_includes,
              facilitators!events_facilitator_id_fkey (
                bio,
                specialties,
                users!facilitators_user_id_fkey (
                  id,
                  full_name
                )
              )
            `)
            .eq("status", "active")
            .gte("event_date", new Date().toISOString())
            .order("event_date", { ascending: true })
            .limit(10)

          if (queryError) {
            console.error("❌ Direct query also failed:", queryError)
            throw queryError
          }

          console.log("✅ Direct query successful:", queryData?.length || 0, "events")

          // Transformar datos del query directo para que coincidan con el formato esperado
          const transformedEvents = (queryData || []).map((event) => ({
            id: event.id,
            title: event.title,
            description: event.description,
            facilitator_name: event.facilitators?.users?.full_name || "Facilitador no disponible",
            facilitator_bio: event.facilitators?.bio || "",
            facilitator_specialties: Array.isArray(event.facilitators?.specialties)
              ? event.facilitators.specialties
              : [],
            facilitator_user_id: event.facilitators?.users?.id || "",
            event_date: event.event_date,
            event_time: new Date(event.event_date).toLocaleDateString("es-ES", {
              hour: "2-digit",
              minute: "2-digit",
            }),
            event_date_formatted: new Date(event.event_date).toISOString().split("T")[0],
            duration_minutes: event.duration_minutes,
            location: event.location,
            is_online: event.is_online,
            max_attendees: event.max_attendees,
            current_attendees: event.current_attendees,
            token_cost: event.token_cost,
            status: event.status,
            image_url: event.image_url,
            video_url: event.video_url,
            what_includes: Array.isArray(event.what_includes) ? event.what_includes : [],
          }))

          setEvents(transformedEvents)
        } else {
          console.log("✅ RPC function successful:", rpcData?.length || 0, "events")
          setEvents(rpcData || [])
        }

        setError(null)
      } catch (err) {
        console.error("❌ Error fetching events:", err)
        setError(err instanceof Error ? err.message : "Error desconocido")
        setEvents([])
      } finally {
        setLoading(false)
      }
    }

    fetchEvents()
  }, [])

  return { events, loading, error, refetch: () => window.location.reload() }
}
