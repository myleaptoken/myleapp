"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ScrollAnimate } from "@/components/common/scroll-animate"
import { Star } from "lucide-react"
import { TESTIMONIALS_DATA } from "@/constants/testimonials-data"

export function TestimonialsSection() {
  return (
    <section id="comunidad" className="py-16 sm:py-20 lg:py-28 bg-muted/20 px-4 sm:px-6 lg:px-8">
      <div className="container max-w-7xl mx-auto">
        <ScrollAnimate animation="up">
          <div className="text-center space-y-4 sm:space-y-6 mb-12 sm:mb-16 lg:mb-20">
            <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold leading-tight">
              Lo que dicen en nuestra{" "}
              <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-green-600 bg-clip-text text-transparent">
                Comunidad
              </span>
            </h2>
            <div className="max-w-3xl mx-auto px-4">
              <p className="text-base sm:text-lg lg:text-xl text-muted-foreground leading-relaxed">
                Miles de personas se han transformado con MY LEAP
              </p>
            </div>
          </div>
        </ScrollAnimate>

        <div className="max-w-6xl mx-auto">
          <ScrollAnimate animation="scale" delay={200}>
            <div className="flex overflow-x-auto gap-6 sm:gap-8 lg:gap-10 pb-4 scrollbar-hide snap-x snap-mandatory">
              {TESTIMONIALS_DATA.map((testimonial, index) => (
                <Card
                  key={testimonial.id}
                  className="group hover:shadow-lg transition-all duration-300 hover:-translate-y-1 flex-shrink-0 w-80 sm:w-96 snap-start"
                >
                  <CardContent className="p-6 sm:p-8 h-full flex flex-col">
                    <div className="flex items-center space-x-1 mb-4 sm:mb-6">
                      {[...Array(testimonial.rating)].map((_, i) => (
                        <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                      ))}
                    </div>

                    <p className="text-muted-foreground mb-6 sm:mb-8 leading-relaxed flex-1 text-sm sm:text-base">
                      "{testimonial.content}"
                    </p>

                    <div className="flex items-center space-x-3 mt-auto">
                      <Avatar className="h-10 w-10 sm:h-12 sm:w-12">
                        <AvatarImage src={testimonial.avatar || "/placeholder.svg"} alt={testimonial.name} />
                        <AvatarFallback>{testimonial.name.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <div>
                        <div className="font-semibold text-sm sm:text-base">{testimonial.name}</div>
                        <div className="text-xs sm:text-sm text-muted-foreground">
                          {testimonial.role} en {testimonial.company}
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </ScrollAnimate>
        </div>
      </div>
    </section>
  )
}
