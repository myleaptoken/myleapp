export interface User {
  id: string
  email: string
  full_name?: string
  avatar_url?: string
  token_balance: number
  created_at: string
  updated_at: string
}

export interface Event {
  id: string
  title: string
  description: string
  date: string
  location: string
  price: number
  token_cost: number
  image_url?: string
  category: string
  max_attendees: number
  current_attendees: number
  created_at: string
  updated_at: string
}

export interface Course {
  id: string
  title: string
  description: string
  instructor: string
  duration: string
  level: "beginner" | "intermediate" | "advanced"
  token_cost: number
  image_url?: string
  category: string
  rating: number
  students_count: number
  created_at: string
  updated_at: string
}

export interface UserEvent {
  id: string
  user_id: string
  event_id: string
  status: "registered" | "attended" | "cancelled"
  created_at: string
}

export interface TokenTransaction {
  id: string
  user_id: string
  amount: number
  type: "earned" | "spent" | "bonus"
  description: string
  created_at: string
}
