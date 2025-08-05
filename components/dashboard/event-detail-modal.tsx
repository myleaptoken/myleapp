"use client"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Calendar, Clock, MapPin, Users, Coins, Share2, Play } from "lucide-react"
import type { EventData } from "@/hooks/use-events"

interface EventDetailModalProps {
  isOpen: boolean
  onClose: () => void
  event: EventData
}

export function EventDetailModal({ isOpen, onClose, event }: EventDetailModalProps) {
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString("es-ES", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    })
  }

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    if (hours > 0) {
      return mins > 0 ? `${hours}h ${mins}min` : `${hours}h`
    }
    return `${mins}min`
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "active":
        return { variant: "default" as const, text: "Disponible" }
      case "completed":
        return { variant: "secondary" as const, text: "Completado" }
      case "cancelled":
        return { variant: "destructive" as const, text: "Cancelado" }
      default:
        return { variant: "secondary" as const, text: "Pendiente" }
    }
  }

  const statusBadge = getStatusBadge(event.status)

  // Función para determinar si mostrar video o imagen
  const hasVideo = event.video_url && event.video_url.trim() !== ""

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader className="space-y-4">
          <div className="flex items-start justify-between">
            <DialogTitle className="text-2xl font-bold leading-tight pr-4">{event.title}</DialogTitle>
            <Badge variant={statusBadge.variant} className="flex-shrink-0">
              {statusBadge.text}
            </Badge>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Event Hero - Video o Imagen */}
          <div className="relative h-64 rounded-lg overflow-hidden">
            {hasVideo ? (
              // Mostrar video si existe video_url
              <div className="w-full h-full">
                <iframe
                  src={event.video_url}
                  title={event.title}
                  className="w-full h-full"
                  frameBorder="0"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowFullScreen
                />
              </div>
            ) : (
              // Mostrar imagen si no hay video
              <>
                <img
                  src={event.image_url || "/placeholder.svg?height=300&width=600&text=Evento"}
                  alt={event.title}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

                {/* Play button overlay solo para imágenes */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="bg-white/20 backdrop-blur-sm rounded-full p-4 hover:bg-white/30 transition-colors cursor-pointer">
                    <Play className="h-8 w-8 text-white" />
                  </div>
                </div>
              </>
            )}

            {/* Share button in top right corner - siempre visible */}
            <div className="absolute top-3 right-3">
              <Button
                variant="outline"
                size="sm"
                className="bg-white/20 backdrop-blur-sm border-white/30 text-white hover:bg-white/30"
              >
                <Share2 className="h-4 w-4 mr-1" />
                Compartir
              </Button>
            </div>

            {/* Event info overlay - solo si no hay video */}
            {!hasVideo && (
              <div className="absolute bottom-4 left-4 right-4">
                <div className="flex items-center justify-between">
                  <div className="bg-black/80 backdrop-blur-sm text-white px-3 py-2 rounded-lg">
                    <p className="text-sm font-medium">{event.facilitator_name}</p>
                    <p className="text-xs opacity-80">Facilitador</p>
                  </div>
                  <div className="gradient-balance px-3 py-2 rounded-lg text-center min-w-[160px] text-white">
                    <div className="text-xs font-medium">Reservar con</div>
                    <div className="text-sm font-bold">
                      {event.token_cost} LEAP ≈ ${(event.token_cost * 0.25).toFixed(2)} USD
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Si hay video, mostrar la info de reserva aquí */}
          {hasVideo && (
            <div className="flex items-center justify-between p-4 bg-gradient-to-r from-blue-50 via-purple-50 to-green-50 dark:from-blue-900/20 dark:via-purple-900/20 dark:to-green-900/20 rounded-lg">
              <div className="bg-muted/50 px-3 py-2 rounded-lg">
                <p className="text-sm font-medium">{event.facilitator_name}</p>
                <p className="text-xs text-muted-foreground">Facilitador</p>
              </div>
              <div className="gradient-balance px-3 py-2 rounded-lg text-center min-w-[160px] text-white">
                <div className="text-xs font-medium">Reservar con</div>
                <div className="text-sm font-bold">
                  {event.token_cost} LEAP ≈ ${(event.token_cost * 0.25).toFixed(2)} USD
                </div>
              </div>
            </div>
          )}

          {/* Facilitator Info - SIN RATING */}
          <div className="flex items-center space-x-4 p-4 bg-muted/30 rounded-lg">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-500 rounded-full flex items-center justify-center">
              <span className="text-white font-semibold text-xl">
                {event.facilitator_name
                  .split(" ")
                  .map((n) => n[0])
                  .join("")}
              </span>
            </div>
            <div className="flex-1">
              <h4 className="font-semibold text-lg">Facilitador</h4>
              <p className="text-muted-foreground">{event.facilitator_name}</p>
              <p className="text-sm text-muted-foreground mt-1">Experto certificado</p>
              {event.facilitator_specialties && event.facilitator_specialties.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-2">
                  {event.facilitator_specialties.map((specialty, index) => (
                    <Badge key={index} variant="outline" className="text-xs">
                      {specialty}
                    </Badge>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Event Details Grid */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <Calendar className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">{formatDate(event.event_date)}</p>
              <p className="text-xs text-muted-foreground">Fecha</p>
            </div>
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <Clock className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">{event.event_time}</p>
              <p className="text-xs text-muted-foreground">{formatDuration(event.duration_minutes)}</p>
            </div>
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <MapPin className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">{event.is_online ? "Online" : event.location}</p>
              <p className="text-xs text-muted-foreground">Ubicación</p>
            </div>
            <div className="text-center p-4 bg-muted/20 rounded-lg">
              <Users className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium text-sm">
                {event.current_attendees}/{event.max_attendees}
              </p>
              <p className="text-xs text-muted-foreground">Participantes</p>
            </div>
          </div>

          <Separator />

          {/* Description */}
          <div className="space-y-3">
            <h4 className="font-semibold text-lg">Descripción del Evento</h4>
            <p className="text-muted-foreground leading-relaxed">{event.description || "Descripción no disponible"}</p>
            {event.facilitator_bio && (
              <div className="mt-4 p-4 bg-muted/20 rounded-lg">
                <h5 className="font-medium text-sm mb-2">Sobre el Facilitador</h5>
                <p className="text-sm text-muted-foreground">{event.facilitator_bio}</p>
              </div>
            )}
          </div>

          {/* What's Included */}
          {event.what_includes && event.what_includes.length > 0 && (
            <div className="space-y-3">
              <h4 className="font-semibold text-lg">Qué Incluye</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {event.what_includes.map((item, index) => (
                  <div key={index} className="flex items-center space-x-2 text-sm p-2 bg-muted/20 rounded">
                    <div className="w-2 h-2 rounded-full bg-primary flex-shrink-0" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <Separator />

          {/* Action Buttons */}
          <div className="flex space-x-3 pt-4">
            <Button
              className="flex-1 gradient-balance text-white hover:opacity-90 py-3"
              size="lg"
              disabled={event.status !== "active"}
            >
              <div className="flex flex-col items-center">
                <div className="flex items-center">
                  <Coins className="h-4 w-4 mr-1" />
                  <span className="text-sm">Reservar con</span>
                </div>
                <div className="text-xs font-medium">
                  {event.token_cost} LEAP ≈ ${(event.token_cost * 0.25).toFixed(2)} USD
                </div>
              </div>
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
