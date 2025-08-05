"use client"

import * as React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { BookOpen, Clock, Users, Star } from "lucide-react"
import { CourseDetailModal } from "./course-detail-modal"

const courses = [
  {
    id: 1,
    title: "Método ONE Nivel I",
    instructor: "María González",
    duration: "8 semanas",
    level: "Principiante",
    students: 245,
    status: "available",
    tokens: 800,
    image_url: "/placeholder.svg?height=200&width=300&text=Método+ONE+Nivel+I",
    description:
      "Inicia tu viaje de transformación con los fundamentos del Método ONE. Aprenderás técnicas básicas de sanación energética.",
    rating: 4.9,
    modules: 4,
  },
  {
    id: 2,
    title: "Método ONE Nivel II",
    instructor: "Carlos Mendoza",
    duration: "12 semanas",
    level: "Intermedio",
    students: 156,
    status: "available",
    tokens: 1200,
    image_url: "/placeholder.svg?height=200&width=300&text=Método+ONE+Nivel+II",
    description:
      "Profundiza en técnicas avanzadas del Método ONE. Explora sanación a distancia y trabajo con patrones kármicos.",
    rating: 4.8,
    modules: 4,
  },
]

export function AvailableCourses() {
  const [selectedCourse, setSelectedCourse] = React.useState<(typeof courses)[0] | null>(null)
  const [isModalOpen, setIsModalOpen] = React.useState(false)

  const handleViewDetails = (course: (typeof courses)[0]) => {
    setSelectedCourse(course)
    setIsModalOpen(true)
  }

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Cursos Disponibles</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex overflow-x-auto gap-4 sm:gap-6 pb-4 snap-x snap-mandatory px-4 sm:px-0 -mx-4 sm:mx-0">
            {courses.map((course) => (
              <div
                key={course.id}
                className="flex-shrink-0 w-72 sm:w-80 group cursor-pointer snap-start first:ml-0 last:mr-4 sm:last:mr-0"
                onClick={() => handleViewDetails(course)}
              >
                <Card className="overflow-hidden hover:shadow-lg transition-all duration-300 hover:-translate-y-1 h-[420px] flex flex-col">
                  {/* Course Image */}
                  <div className="relative h-48 overflow-hidden">
                    <img
                      src={course.image_url || "/placeholder.svg"}
                      alt={course.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

                    {/* Level Badge */}
                    <div className="absolute top-3 right-3">
                      <Badge variant="default">{course.level}</Badge>
                    </div>

                    {/* Token Cost */}
                    <div className="absolute bottom-3 left-3">
                      <div className="bg-black/80 backdrop-blur-sm text-white px-3 py-1 rounded-full text-sm font-medium">
                        {course.tokens} LEAP
                      </div>
                    </div>

                    {/* Rating */}
                    <div className="absolute top-3 left-3">
                      <div className="bg-black/80 backdrop-blur-sm text-white px-2 py-1 rounded-full text-xs flex items-center space-x-1">
                        <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                        <span>{course.rating}</span>
                      </div>
                    </div>
                  </div>

                  <CardContent className="p-4 flex-1 flex flex-col">
                    <div className="space-y-3 flex-1 flex flex-col justify-between">
                      {/* Title and Instructor */}
                      <div>
                        <h4 className="font-semibold text-base line-clamp-2 mb-1">{course.title}</h4>
                        <p className="text-sm text-muted-foreground">con {course.instructor}</p>
                      </div>

                      {/* Course Details */}
                      <div className="grid grid-cols-2 gap-2 text-xs text-muted-foreground">
                        <div className="flex items-center space-x-1">
                          <Clock className="h-3 w-3" />
                          <span>{course.duration}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <BookOpen className="h-3 w-3" />
                          <span>{course.modules} módulos</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Users className="h-3 w-3" />
                          <span>{course.students} estudiantes</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Badge variant="outline" className="text-xs px-1 py-0">
                            Disponible
                          </Badge>
                        </div>
                      </div>

                      {/* Description */}
                      <p className="text-xs text-muted-foreground line-clamp-2">{course.description}</p>

                      {/* Action Button */}
                      <Button size="sm" className="w-full mt-3 bg-transparent" variant="outline">
                        Ver Detalles
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {selectedCourse && (
        <CourseDetailModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} course={selectedCourse} />
      )}
    </>
  )
}
