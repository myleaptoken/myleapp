"use client"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { BookOpen, Clock, Users, Coins, Star, Play, Award, Heart, Share2, CheckCircle } from "lucide-react"

interface CourseDetailModalProps {
  isOpen: boolean
  onClose: () => void
  course: {
    id: number
    title: string
    instructor: string
    duration: string
    level: string
    students: number
    status: string
    tokens: number
    image_url?: string
    description?: string
    rating?: number
    modules?: number
  }
}

export function CourseDetailModal({ isOpen, onClose, course }: CourseDetailModalProps) {
  const modulesList =
    course.title === "Método ONE Nivel I"
      ? [
          { title: "Fundamentos de la Sanación Energética", duration: "2 semanas", completed: false },
          { title: "Técnicas de Respiración Consciente", duration: "2 semanas", completed: false },
          { title: "Liberación de Bloqueos Emocionales", duration: "2 semanas", completed: false },
          { title: "Práctica Integrativa y Certificación", duration: "2 semanas", completed: false },
        ]
      : [
          { title: "Sanación a Distancia", duration: "3 semanas", completed: false },
          { title: "Trabajo con Patrones Kármicos", duration: "3 semanas", completed: false },
          { title: "Activación de Dones Espirituales", duration: "3 semanas", completed: false },
          { title: "Maestría y Certificación Avanzada", duration: "3 semanas", completed: false },
        ]

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader className="space-y-4">
          <div className="flex items-start justify-between">
            <DialogTitle className="text-2xl font-bold leading-tight pr-4">{course.title}</DialogTitle>
            <Badge variant="default" className="flex-shrink-0">
              {course.level}
            </Badge>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Course Hero */}
          <div className="relative h-64 rounded-lg overflow-hidden">
            <img
              src={course.image_url || "/placeholder.svg?height=300&width=600&text=Curso"}
              alt={course.title}
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

            {/* Play button for preview */}
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="bg-white/20 backdrop-blur-sm rounded-full p-4 hover:bg-white/30 transition-colors cursor-pointer">
                <Play className="h-8 w-8 text-white" />
              </div>
            </div>

            {/* Course info overlay */}
            <div className="absolute bottom-4 left-4 right-4">
              <div className="flex items-center justify-between">
                <div className="bg-black/80 backdrop-blur-sm text-white px-3 py-2 rounded-lg">
                  <p className="text-sm font-medium">{course.instructor}</p>
                  <p className="text-xs opacity-80">Instructor</p>
                </div>
                <div className="bg-black/80 backdrop-blur-sm text-white px-3 py-2 rounded-lg text-right">
                  <p className="text-sm font-medium">{course.tokens} LEAP</p>
                  <p className="text-xs opacity-80">≈ ${(course.tokens * 0.25).toFixed(2)} USD</p>
                </div>
              </div>
            </div>
          </div>

          {/* Instructor Info */}
          <div className="flex items-center space-x-4 p-4 bg-muted/30 rounded-lg">
            <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-blue-500 rounded-full flex items-center justify-center">
              <span className="text-white font-semibold text-xl">
                {course.instructor
                  .split(" ")
                  .map((n) => n[0])
                  .join("")}
              </span>
            </div>
            <div className="flex-1">
              <h4 className="font-semibold text-lg">Instructor</h4>
              <p className="text-muted-foreground">{course.instructor}</p>
              <div className="flex items-center space-x-1 mt-1">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                ))}
                <span className="text-sm text-muted-foreground ml-1">
                  ({course.rating || 4.8}) • Experto certificado
                </span>
              </div>
            </div>
          </div>

          {/* Course Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <Clock className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">{course.duration}</p>
              <p className="text-xs text-muted-foreground">Duración</p>
            </div>
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <BookOpen className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">{course.modules || 4} módulos</p>
              <p className="text-xs text-muted-foreground">Contenido</p>
            </div>
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <Users className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">{course.students}</p>
              <p className="text-xs text-muted-foreground">Estudiantes</p>
            </div>
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <Award className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">Certificado</p>
              <p className="text-xs text-muted-foreground">Incluido</p>
            </div>
          </div>

          <Separator />

          {/* Course Description */}
          <div className="space-y-3">
            <h4 className="font-semibold text-lg">Descripción del Curso</h4>
            <p className="text-muted-foreground leading-relaxed">
              {course.description ||
                (course.title === "Método ONE Nivel I"
                  ? "Inicia tu viaje de transformación con los fundamentos del Método ONE. Aprenderás técnicas básicas de sanación energética, meditación consciente y liberación de bloqueos emocionales. Este curso te proporcionará las herramientas esenciales para comenzar tu proceso de sanación personal."
                  : "Profundiza en técnicas avanzadas del Método ONE. Explora sanación a distancia, trabajo con patrones kármicos y activación de dones espirituales. Ideal para quienes han completado el Nivel I y buscan expandir sus capacidades de sanación.")}
            </p>
          </div>

          {/* Course Curriculum */}
          <div className="space-y-3">
            <h4 className="font-semibold text-lg">Contenido del Curso</h4>
            <div className="space-y-3">
              {modulesList.map((module, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/20 transition-colors"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                      <span className="text-sm font-medium text-primary">{index + 1}</span>
                    </div>
                    <div>
                      <p className="font-medium text-sm">{module.title}</p>
                      <p className="text-xs text-muted-foreground">
                        Módulo {index + 1} • {module.duration}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    {module.completed ? (
                      <CheckCircle className="h-5 w-5 text-green-500" />
                    ) : (
                      <Play className="h-4 w-4 text-muted-foreground" />
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* What You'll Learn */}
          <div className="space-y-3">
            <h4 className="font-semibold text-lg">Lo que Aprenderás</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {(course.title === "Método ONE Nivel I"
                ? [
                    "Fundamentos de la anatomía energética",
                    "Técnicas de respiración para sanación",
                    "Identificación y liberación de bloqueos",
                    "Meditaciones guiadas especializadas",
                    "Protocolos de autosanación",
                    "Ética en la práctica energética",
                  ]
                : [
                    "Técnicas avanzadas de sanación remota",
                    "Trabajo profundo con el karma personal",
                    "Activación y desarrollo de capacidades psíquicas",
                    "Sanación transgeneracional",
                    "Canalización de energías superiores",
                    "Formación como facilitador certificado",
                  ]
              ).map((item, index) => (
                <div key={index} className="flex items-center space-x-2 text-sm p-2 bg-muted/20 rounded">
                  <div className="w-2 h-2 rounded-full bg-primary flex-shrink-0" />
                  <span>{item}</span>
                </div>
              ))}
            </div>
          </div>

          <Separator />

          {/* Pricing and Actions */}
          <div className="flex items-center justify-between p-4 bg-gradient-to-r from-blue-50 via-purple-50 to-green-50 dark:from-blue-900/20 dark:via-purple-900/20 dark:to-green-900/20 rounded-lg">
            <div className="flex items-center space-x-2">
              <Coins className="h-5 w-5 text-primary" />
              <div>
                <p className="font-semibold text-lg">{course.tokens} LEAP</p>
                <p className="text-xs text-muted-foreground">≈ ${(course.tokens * 0.25).toFixed(2)} USD</p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="outline" size="sm">
                <Heart className="h-4 w-4 mr-1" />
                Guardar
              </Button>
              <Button variant="outline" size="sm">
                <Share2 className="h-4 w-4 mr-1" />
                Compartir
              </Button>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex space-x-3 pt-4">
            <Button className="flex-1 gradient-balance text-white hover:opacity-90" size="lg">
              <Coins className="h-4 w-4 mr-2" />
              Inscribirse con LEAP
            </Button>
            <Button variant="outline" size="lg" onClick={onClose}>
              Cerrar
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
