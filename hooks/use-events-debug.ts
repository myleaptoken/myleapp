"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"

export interface EventData {
  id: string
  title: string
  description: string
  facilitator_name: string
  facilitator_bio: string
  facilitator_rating: number
  facilitator_specialties: string[]
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
  image_url: string | null
  what_includes: string[]
}

export function useEventsDebug() {
  const [events, setEvents] = useState<EventData[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [debugInfo, setDebugInfo] = useState<any>({})

  useEffect(() => {
    const fetchEventsWithDebug = async () => {
      const debug: any = {
        timestamp: new Date().toISOString(),
        steps: [],
      }

      try {
        debug.steps.push("🔍 Iniciando debug completo...")

        // Check environment
        debug.supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ? "✅ Presente" : "❌ Faltante"
        debug.supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? "✅ Presente" : "❌ Faltante"
        debug.steps.push(`Supabase URL: ${debug.supabaseUrl}`)
        debug.steps.push(`Supabase Key: ${debug.supabaseKey}`)

        if (typeof window === "undefined") {
          debug.steps.push("❌ No estamos en el browser")
          setDebugInfo(debug)
          setLoading(false)
          return
        }

        debug.steps.push("✅ Estamos en el browser")

        const supabase = createClientComponentClient()
        debug.steps.push("✅ Cliente Supabase creado")

        // Test 1: Simple connection test
        debug.steps.push("🧪 Test 1: Conexión básica...")
        const { data: testData, error: testError } = await supabase.from("events").select("count", { count: "exact" })

        debug.connectionTest = {
          success: !testError,
          error: testError?.message,
          count: testData,
        }
        debug.steps.push(`Conexión: ${testError ? "❌ Error" : "✅ OK"}`)

        // Test 2: Simple events query
        debug.steps.push("🧪 Test 2: Consulta simple de eventos...")
        const { data: simpleEvents, error: simpleError } = await supabase
          .from("events")
          .select(`
            id,
            title,
            event_date,
            status,
            facilitator_id
          `)
          .eq("status", "active")
          .gt("event_date", new Date().toISOString())
          .limit(5)

        debug.simpleQuery = {
          success: !simpleError,
          error: simpleError?.message,
          count: simpleEvents?.length || 0,
          events: simpleEvents?.map((e) => ({ title: e.title, date: e.event_date })),
        }
        debug.steps.push(`Eventos simples: ${simpleError ? "❌ Error" : `✅ ${simpleEvents?.length || 0} encontrados`}`)

        // Test 3: RPC function
        debug.steps.push("🧪 Test 3: Función RPC get_upcoming_events...")
        const { data: rpcData, error: rpcError } = await supabase.rpc("get_upcoming_events")

        debug.rpcQuery = {
          success: !rpcError,
          error: rpcError?.message,
          count: rpcData?.length || 0,
          events: rpcData?.map((e: any) => ({ title: e.title, date: e.event_date })),
        }
        debug.steps.push(`RPC función: ${rpcError ? "❌ Error" : `✅ ${rpcData?.length || 0} encontrados`}`)

        // Test 4: Manual join query
        debug.steps.push("🧪 Test 4: Join manual eventos + facilitadores...")
        const { data: joinData, error: joinError } = await supabase
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
            what_includes,
            facilitators (
              name,
              bio,
              rating,
              specialties
            )
          `)
          .eq("status", "active")
          .gt("event_date", new Date().toISOString())
          .order("event_date", { ascending: true })
          .limit(10)

        debug.joinQuery = {
          success: !joinError,
          error: joinError?.message,
          count: joinData?.length || 0,
          events: joinData?.map((e) => ({
            title: e.title,
            date: e.event_date,
            facilitator: e.facilitators?.name,
          })),
        }
        debug.steps.push(`Join manual: ${joinError ? "❌ Error" : `✅ ${joinData?.length || 0} encontrados`}`)

        // Use the best working query
        if (rpcData && !rpcError) {
          debug.steps.push("✅ Usando datos de RPC")
          setEvents(rpcData)
        } else if (joinData && !joinError) {
          debug.steps.push("✅ Usando datos de join manual")
          // Transform join data to match expected format
          const transformedData = joinData.map((event) => ({
            id: event.id,
            title: event.title,
            description: event.description || "",
            facilitator_name: event.facilitators?.name || "Sin facilitador",
            facilitator_bio: event.facilitators?.bio || "",
            facilitator_rating: event.facilitators?.rating || 5.0,
            facilitator_specialties: event.facilitators?.specialties || [],
            event_date: event.event_date,
            event_time: new Date(event.event_date).toLocaleTimeString("es-ES", {
              hour: "2-digit",
              minute: "2-digit",
            }),
            event_date_formatted: new Date(event.event_date).toISOString().split("T")[0],
            duration_minutes: event.duration_minutes,
            location: event.location || "",
            is_online: event.is_online,
            max_attendees: event.max_attendees,
            current_attendees: event.current_attendees,
            token_cost: event.token_cost,
            status: event.status,
            image_url: event.image_url,
            what_includes: event.what_includes || [],
          }))
          setEvents(transformedData)
        } else if (simpleEvents && !simpleError) {
          debug.steps.push("⚠️ Usando datos simples (sin facilitador)")
          // Use simple data as fallback
          const fallbackData = simpleEvents.map((event) => ({
            id: event.id,
            title: event.title,
            description: "Descripción no disponible",
            facilitator_name: "Facilitador no disponible",
            facilitator_bio: "",
            facilitator_rating: 5.0,
            facilitator_specialties: [],
            event_date: event.event_date,
            event_time: new Date(event.event_date).toLocaleTimeString("es-ES", {
              hour: "2-digit",
              minute: "2-digit",
            }),
            event_date_formatted: new Date(event.event_date).toISOString().split("T")[0],
            duration_minutes: 90,
            location: "Por definir",
            is_online: true,
            max_attendees: 20,
            current_attendees: 0,
            token_cost: 250,
            status: event.status,
            image_url: null,
            what_includes: [],
          }))
          setEvents(fallbackData)
        } else {
          debug.steps.push("❌ No se pudieron obtener eventos")
          setError("No se pudieron cargar los eventos")
        }

        debug.steps.push(`✅ Debug completado. Eventos finales: ${events.length}`)
      } catch (err) {
        debug.steps.push(`❌ Excepción: ${err}`)
        console.error("Exception in debug:", err)
        setError("Error inesperado al cargar eventos")
      } finally {
        setDebugInfo(debug)
        setLoading(false)
      }
    }

    fetchEventsWithDebug()
  }, [])

  return { events, loading, error, debugInfo }
}
