"use client"

import { useAuth } from "@/hooks/use-auth"

export function DashboardOverview() {
  const { user } = useAuth()

  const getUserName = () => {
    if (user?.user_metadata?.full_name) {
      return user.user_metadata.full_name.split(" ")[0]
    }
    return user?.email?.split("@")[0] || "Usuario"
  }

  return (
    <div className="space-y-6">
      {/* Welcome Message */}
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold">¡Hola, {getUserName()}! 👋</h1>
        <p className="text-muted-foreground mt-2">Continúa tu sanación energética</p>
      </div>
    </div>
  )
}
