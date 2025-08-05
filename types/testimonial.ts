export interface Testimonial {
  id: string
  name: string
  role: string
  company: string
  content: string
  avatar: string
  rating: number
}

export interface TestimonialCardProps {
  testimonial: Testimonial
}
