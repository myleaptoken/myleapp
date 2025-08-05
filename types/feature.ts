export interface Feature {
  id: string
  title: string
  description: string
  icon: string
  gradient: string
  benefits: string[]
}

export interface FeatureCardProps {
  feature: Feature
  index: number
}
