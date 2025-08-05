"use client"

import { FeatureCard } from "@/components/common/feature-card"
import { GridContainer } from "@/components/common/grid-container"
import { ScrollAnimate } from "@/components/common/scroll-animate"
import { FEATURES_DATA } from "@/constants/carousel-data"

export function FeaturesSection() {
  return (
    <section
      id="recursos"
      className="py-16 sm:py-20 lg:py-28 bg-gradient-to-b from-background to-muted/20 px-4 sm:px-6 lg:px-8"
    >
      <div className="container max-w-7xl mx-auto">
        <ScrollAnimate animation="up">
          <div className="text-center space-y-4 sm:space-y-6 mb-12 sm:mb-16 lg:mb-20">
            <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold leading-tight">
              Transforma tu{" "}
              <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-green-600 bg-clip-text text-transparent">
                Potencial
              </span>
            </h2>
            <div className="max-w-3xl mx-auto px-4">
              <p className="text-base sm:text-lg lg:text-xl text-muted-foreground leading-relaxed">
                Descubre todas las herramientas y recursos que tenemos para acelerar tu crecimiento personal y
                profesional
              </p>
            </div>
          </div>
        </ScrollAnimate>

        <div className="max-w-6xl mx-auto">
          <GridContainer cols={{ default: 1, md: 2, lg: 3 }} className="gap-6 sm:gap-8 lg:gap-10">
            {FEATURES_DATA.map((feature, index) => (
              <ScrollAnimate key={feature.id} animation="up" delay={index * 100}>
                <FeatureCard feature={feature} index={index} />
              </ScrollAnimate>
            ))}
          </GridContainer>
        </div>
      </div>
    </section>
  )
}
