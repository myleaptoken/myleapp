import { MainLayout } from "@/components/layout/main-layout"
import { HeroSection } from "@/components/sections/hero-section"
import { FeaturesSection } from "@/components/sections/features-section"
import { TokenLeapSection } from "@/components/sections/token-leap-section"
import { VideoTestimonialsSection } from "@/components/sections/video-testimonials-section"
import { TestimonialsSection } from "@/components/sections/testimonials-section"

export default function Page() {
  return (
    <MainLayout>
      <HeroSection />
      <FeaturesSection />
      <TokenLeapSection />
      <VideoTestimonialsSection />
      <TestimonialsSection />
    </MainLayout>
  )
}
