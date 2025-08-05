export interface VideoTestimonial {
  id: string
  name: string
  title: string
  description: string
  duration: string
  thumbnail: string
  videoUrl?: string
}

export interface VideoTestimonialCardProps {
  testimonial: VideoTestimonial
  index: number
}
