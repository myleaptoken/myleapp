"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Calendar, BookOpen, Award, Users } from "lucide-react"

const activities = [
  {
    id: 1,
    type: "event",
    title: "Sesión de Sanación Energética",
    description: "Completaste la sesión con María González",
    time: "Hace 2 horas",
    status: "completed",
    icon: Calendar,
  },
  {
    id: 2,
    type: "course",
    title: "Curso: Expansión de Consciencia",
    description: "Nuevo módulo disponible: Técnicas Avanzadas",
    time: "Hace 1 día",
    status: "new",
    icon: BookOpen,
  },
  {
    id: 3,
    type: "certificate",
    title: "Certificado Obtenido",
    description: "Sanación Energética Nivel 2",
    time: "Hace 3 días",
    status: "achieved",
    icon: Award,
  },
  {
    id: 4,
    type: "community",
    title: "Nueva Conexión",
    description: "Carlos Mendoza se unió a tu red",
    time: "Hace 5 días",
    status: "social",
    icon: Users,
  },
]

const statusColors = {
  completed: "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400",
  new: "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400",
  achieved: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400",
  social: "bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-400",
}

export function RecentActivity() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Actividad Reciente</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {activities.map((activity) => (
            <div
              key={activity.id}
              className="flex items-start space-x-4 p-4 rounded-lg hover:bg-muted/50 transition-colors"
            >
              <div className="p-2 bg-muted rounded-lg">
                <activity.icon className="h-4 w-4" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between mb-1">
                  <p className="text-sm font-medium">{activity.title}</p>
                  <Badge variant="secondary" className={statusColors[activity.status as keyof typeof statusColors]}>
                    {activity.status}
                  </Badge>
                </div>
                <p className="text-sm text-muted-foreground">{activity.description}</p>
                <p className="text-xs text-muted-foreground mt-1">{activity.time}</p>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
