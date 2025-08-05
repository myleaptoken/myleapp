"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Calendar, BookOpen } from "lucide-react"

const stats = [
  {
    name: "Eventos Completados",
    value: "12",
    change: "+3 este mes",
    icon: Calendar,
    color: "text-blue-600",
    bgColor: "bg-blue-50 dark:bg-blue-900/20",
  },
  {
    name: "Cursos Activos",
    value: "4",
    change: "+1 nuevo",
    icon: BookOpen,
    color: "text-green-600",
    bgColor: "bg-green-50 dark:bg-green-900/20",
  },
]

export function DashboardStats() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 gap-4 sm:gap-6">
      {stats.map((stat) => (
        <Card key={stat.name} className="hover:shadow-md transition-shadow duration-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">{stat.name}</p>
                <p className="text-2xl font-bold mt-1">{stat.value}</p>
                {stat.name === "Cursos Activos" && <p className="text-xs text-muted-foreground mt-1">Totales 12</p>}
                <p className="text-xs text-muted-foreground mt-1">{stat.change}</p>
              </div>
              <div className={`p-3 rounded-lg ${stat.bgColor}`}>
                <stat.icon className={`h-6 w-6 ${stat.color}`} />
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
