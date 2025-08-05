"use client"

import { useState, useEffect } from "react"
import { supabase } from "@/lib/supabase"

interface HeroSettings {
  video_url: string | null
  fallback_image_url: string
  video_enabled: boolean
}

export function useHeroSettings() {
  const [settings, setSettings] = useState<HeroSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchSettings() {
      try {
        setLoading(true)
        console.log("🔍 Fetching hero settings...")

        const { data, error } = await supabase.rpc("get_hero_settings")

        if (error) {
          console.error("❌ Error fetching hero settings:", error)
          setError(error.message)
          return
        }

        if (data && data.length > 0) {
          const heroSettings = data[0]
          console.log("✅ Hero settings loaded:", heroSettings)
          setSettings(heroSettings)
        } else {
          console.log("⚠️ No hero settings found, using defaults")
          setSettings({
            video_url: null,
            fallback_image_url:
              "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png",
            video_enabled: false,
          })
        }
      } catch (err) {
        console.error("❌ Error in fetchSettings:", err)
        setError(err instanceof Error ? err.message : "Unknown error")
      } finally {
        setLoading(false)
      }
    }

    fetchSettings()
  }, [])

  return { settings, loading, error }
}
