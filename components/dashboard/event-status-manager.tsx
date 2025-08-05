"use client"

import { Badge } from "@/components/ui/badge"

// Función para obtener el badge del status
export const getStatusBadge = (status: string) => {
  switch (status) {
    case "active":
      return {
        variant: "default" as const,
        text: "Disponible",
        color: "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400",
      }
    case "completed":
      return {
        variant: "secondary" as const,
        text: "Completado",
        color: "bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400",
      }
    case "cancelled":
      return {
        variant: "destructive" as const,
        text: "Cancelado",
        color: "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400",
      }
    default:
      return {
        variant: "secondary" as const,
        text: "Pendiente",
        color: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400",
      }
  }
}

// Componente para mostrar el status
export function EventStatusBadge({ status }: { status: string }) {
  const statusInfo = getStatusBadge(status)

  return (
    <Badge variant={statusInfo.variant} className={statusInfo.color}>
      {statusInfo.text}
    </Badge>
  )
}

// Función para determinar si un evento permite inscripción
export const canRegisterForEvent = (status: string, eventDate: string) => {
  if (status !== "active") return false
  if (new Date(eventDate) < new Date()) return false
  return true
}
