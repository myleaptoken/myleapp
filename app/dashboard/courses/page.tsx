"use client"

import { AvailableCourses } from "@/components/dashboard/available-courses"
import { useAuth } from "@/hooks/use-auth"
import { Loader2 } from "lucide-react"
import { useEffect } from "react"

export default function CoursesPage() {
  const { user, loading: authLoading } = useAuth()

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  if (authLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center space-y-4">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="text-muted-foreground">Cargando cursos...</p>
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

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Page Header */}
      <div className="space-y-2">
        <h1 className="text-2xl font-bold">Cursos</h1>
        <p className="text-muted-foreground">Explora nuestros cursos disponibles y comienza tu aprendizaje</p>
      </div>

      {/* Available Courses */}
      <AvailableCourses />
    </div>
  )
}
