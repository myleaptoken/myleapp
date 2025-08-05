"use client"

import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { useAuthContext } from "@/components/auth/auth-provider"
import { useRouter } from "next/navigation"

export function useAuth() {
  const { user, loading } = useAuthContext()
  const router = useRouter()

  // Create supabase client only when needed and in browser
  const getSupabaseClient = () => {
    if (typeof window === "undefined") return null
    if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
      console.warn("Supabase environment variables not available")
      return null
    }
    return createClientComponentClient()
  }

  const signIn = async (email: string, password: string) => {
    const supabase = getSupabaseClient()
    if (!supabase) {
      return { data: null, error: { message: "Supabase client not available" } }
    }

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        return { data: null, error }
      }

      // Redirigir manualmente después del login exitoso
      if (data.user) {
        router.push("/dashboard")
        router.refresh()
      }

      return { data, error: null }
    } catch (error) {
      console.error("Sign in exception:", error)
      return { data: null, error: { message: "Error inesperado al iniciar sesión" } }
    }
  }

  const signUp = async (email: string, password: string, fullName?: string) => {
    const supabase = getSupabaseClient()
    if (!supabase) {
      return { data: null, error: { message: "Supabase client not available" } }
    }

    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName || email.split("@")[0],
          },
        },
      })

      if (error) {
        return { data: null, error }
      }

      // Si el usuario se confirma inmediatamente, redirigir
      if (data.user && data.user.email_confirmed_at) {
        router.push("/dashboard")
        router.refresh()
      }

      return { data, error: null }
    } catch (error) {
      console.error("Sign up exception:", error)
      return { data: null, error: { message: "Error inesperado al registrarse" } }
    }
  }

  const signOut = async () => {
    const supabase = getSupabaseClient()
    if (!supabase) {
      return { error: { message: "Supabase client not available" } }
    }

    try {
      const { error } = await supabase.auth.signOut()
      if (error) {
        return { error }
      }

      router.push("/")
      router.refresh()
      return { error: null }
    } catch (error) {
      console.error("Sign out exception:", error)
      return { error: { message: "Error al cerrar sesión" } }
    }
  }

  return {
    user,
    loading,
    signIn,
    signUp,
    signOut,
  }
}
