"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Play } from "lucide-react"
import type { VideoTestimonialCardProps } from "@/types/video-testimonial"

export function VideoTestimonialCard({ testimonial, index }: VideoTestimonialCardProps) {
  return (
    <Card className="group hover:shadow-lg transition-all duration-300 hover:-translate-y-1 flex-shrink-0 w-80 sm:w-96 animate-fade-in-up">
      <CardContent className="p-0">
        {/* Video Thumbnail */}
        <div className="relative overflow-hidden rounded-t-lg">
          <img
            src={testimonial.thumbnail || "/placeholder.svg"}
            alt={`Video testimonial de ${testimonial.name}`}
            className="w-full h-48 sm:h-56 object-cover group-hover:scale-105 transition-transform duration-300"
          />

          {/* Play Button Overlay */}
          <div className="absolute inset-0 bg-black/20 flex items-center justify-center group-hover:bg-black/30 transition-colors">
            <div className="w-16 h-16 sm:w-20 sm:h-20 bg-white/90 rounded-full flex items-center justify-center group-hover:bg-white group-hover:scale-110 transition-all duration-300 cursor-pointer">
              <Play className="h-6 w-6 sm:h-8 sm:w-8 text-primary ml-1" fill="currentColor" />
            </div>
          </div>

          {/* Duration Badge */}
          <div className="absolute bottom-3 right-3 bg-black/80 text-white text-xs sm:text-sm px-2 py-1 rounded">
            {testimonial.duration}
          </div>
        </div>

        {/* Content */}
        <div className="p-4 sm:p-6">
          <h4 className="font-bold text-base sm:text-lg mb-2 text-primary">{testimonial.name}</h4>
          <h5 className="font-semibold text-sm sm:text-base mb-3 text-foreground">{testimonial.title}</h5>
          <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">"{testimonial.description}"</p>
        </div>
      </CardContent>
    </Card>
  )
}
