"use client"

import * as React from "react"
import { VideoTestimonialCard } from "@/components/common/video-testimonial-card"
import { ScrollAnimate } from "@/components/common/scroll-animate"
import { VIDEO_TESTIMONIALS_DATA } from "@/constants/video-testimonials-data"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { Button } from "@/components/ui/button"

export function VideoTestimonialsSection() {
  const [currentIndex, setCurrentIndex] = React.useState(0)
  const scrollContainerRef = React.useRef<HTMLDivElement>(null)

  const scrollToIndex = (index: number) => {
    if (scrollContainerRef.current) {
      const cardWidth = 384 // w-96 = 384px
      const gap = 32 // gap-8 = 32px
      const scrollPosition = index * (cardWidth + gap)
      scrollContainerRef.current.scrollTo({
        left: scrollPosition,
        behavior: "smooth",
      })
      setCurrentIndex(index)
    }
  }

  const scrollLeft = () => {
    const newIndex = Math.max(0, currentIndex - 1)
    scrollToIndex(newIndex)
  }

  const scrollRight = () => {
    const maxIndex = Math.max(0, VIDEO_TESTIMONIALS_DATA.length - 3)
    const newIndex = Math.min(maxIndex, currentIndex + 1)
    scrollToIndex(newIndex)
  }

  return (
    <section
      id="testimonios"
      className="py-16 sm:py-20 lg:py-28 bg-gradient-to-b from-muted/10 to-background px-4 sm:px-6 lg:px-8"
    >
      <div className="container max-w-7xl mx-auto">
        <ScrollAnimate animation="up">
          <div className="text-center space-y-4 sm:space-y-6 mb-12 sm:mb-16 lg:mb-20">
            <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold leading-tight">
              Testimonios de{" "}
              <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-green-600 bg-clip-text text-transparent">
                Transformación
              </span>
            </h2>
            <div className="max-w-4xl mx-auto px-4">
              <p className="text-base sm:text-lg lg:text-xl text-muted-foreground leading-relaxed">
                Historias reales de miembros de nuestra comunidad que lograron sanación energética y expansión de
                consciencia usando MY LEAP Powered by Método ONE
              </p>
            </div>
          </div>
        </ScrollAnimate>

        <div className="max-w-6xl mx-auto">
          <ScrollAnimate animation="up" delay={200}>
            <h3 className="text-xl sm:text-2xl font-bold text-center mb-8 sm:mb-12">Video Testimonios</h3>
          </ScrollAnimate>

          {/* Carousel Container */}
          <ScrollAnimate animation="scale" delay={400}>
            <div className="relative">
              {/* Navigation Arrows */}
              <Button
                variant="outline"
                size="icon"
                className="absolute left-0 top-1/2 -translate-y-1/2 z-10 bg-background/80 backdrop-blur-sm hover:bg-background"
                onClick={scrollLeft}
                disabled={currentIndex === 0}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>

              <Button
                variant="outline"
                size="icon"
                className="absolute right-0 top-1/2 -translate-y-1/2 z-10 bg-background/80 backdrop-blur-sm hover:bg-background"
                onClick={scrollRight}
                disabled={currentIndex >= VIDEO_TESTIMONIALS_DATA.length - 3}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>

              {/* Video Cards Carousel */}
              <div
                ref={scrollContainerRef}
                className="flex overflow-x-auto gap-6 sm:gap-8 pb-4 scrollbar-hide snap-x snap-mandatory px-12"
              >
                {VIDEO_TESTIMONIALS_DATA.map((testimonial, index) => (
                  <div key={testimonial.id} className="snap-start">
                    <VideoTestimonialCard testimonial={testimonial} index={index} />
                  </div>
                ))}
              </div>
            </div>
          </ScrollAnimate>

          {/* Pagination Dots */}
          <ScrollAnimate animation="up" delay={600}>
            <div className="flex justify-center space-x-2 mt-8 sm:mt-12">
              {Array.from({ length: Math.max(1, VIDEO_TESTIMONIALS_DATA.length - 2) }).map((_, index) => (
                <button
                  key={index}
                  onClick={() => scrollToIndex(index)}
                  className={`w-2 h-2 sm:w-3 sm:h-3 rounded-full transition-all duration-300 ${
                    index === currentIndex
                      ? "bg-primary scale-125"
                      : "bg-muted-foreground/30 hover:bg-muted-foreground/50"
                  }`}
                />
              ))}
            </div>
          </ScrollAnimate>
        </div>
      </div>
    </section>
  )
}
