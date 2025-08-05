import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"

// Cliente para componentes del lado del cliente
export const supabase = createClientComponentClient()

// Función singleton para evitar múltiples instancias
let supabaseInstance: ReturnType<typeof createClientComponentClient> | null = null

export function getSupabaseClient() {
  if (!supabaseInstance) {
    // Check if we're in a browser environment and have the required env vars
    if (
      typeof window !== "undefined" &&
      process.env.NEXT_PUBLIC_SUPABASE_URL &&
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    ) {
      supabaseInstance = createClientComponentClient()
    } else if (typeof window === "undefined") {
      // Server-side: return null or a mock client
      return null
    }
  }
  return supabaseInstance
}

// Safe client creation that won't fail during build
export function createSafeSupabaseClient() {
  try {
    if (process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
      return createClientComponentClient()
    }
    return null
  } catch (error) {
    console.warn("Supabase client creation failed:", error)
    return null
  }
}
