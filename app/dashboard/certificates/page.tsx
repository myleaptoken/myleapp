"use client"

import { useState, useRef, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Award, Download, Eye, Star } from "lucide-react"

const certificates = [
  {
    id: 1,
    title: "React Fundamentals",
    instructor: "María González",
    completedDate: "2024-01-15",
    duration: "40 horas",
    score: 95,
    skills: ["React", "JavaScript", "JSX", "Hooks"],
    image: "/placeholder.svg?height=200&width=300&text=React+Certificate",
  },
  {
    id: 2,
    title: "Node.js Backend Development",
    instructor: "Carlos Ruiz",
    completedDate: "2024-01-08",
    duration: "60 horas",
    score: 88,
    skills: ["Node.js", "Express", "MongoDB", "API REST"],
    image: "/placeholder.svg?height=200&width=300&text=Node.js+Certificate",
  },
  {
    id: 3,
    title: "Web3 Development Basics",
    instructor: "Ana Martínez",
    completedDate: "2023-12-20",
    duration: "35 horas",
    score: 92,
    skills: ["Blockchain", "Solidity", "Web3.js", "Smart Contracts"],
    image: "/placeholder.svg?height=200&width=300&text=Web3+Certificate",
  },
  {
    id: 4,
    title: "UI/UX Design Principles",
    instructor: "Diego López",
    completedDate: "2023-12-10",
    duration: "45 horas",
    score: 97,
    skills: ["Figma", "Design Systems", "Prototyping", "User Research"],
    image: "/placeholder.svg?height=200&width=300&text=UI/UX+Certificate",
  },
  {
    id: 5,
    title: "Python Data Science",
    instructor: "Laura Fernández",
    completedDate: "2023-11-25",
    duration: "55 horas",
    score: 90,
    skills: ["Python", "Pandas", "NumPy", "Matplotlib"],
    image: "/placeholder.svg?height=200&width=300&text=Python+Certificate",
  },
]

export default function CertificatesPage() {
  const [currentIndex, setCurrentIndex] = useState(0)
  const itemsPerPage = 3
  const scrollContainerRef = useRef<HTMLDivElement>(null)
  const [isAtStart, setIsAtStart] = useState(true)
  const [isAtEnd, setIsAtEnd] = useState(false)

  useEffect(() => {
    const checkScrollPosition = () => {
      if (!scrollContainerRef.current) return

      const element = scrollContainerRef.current
      setIsAtStart(element.scrollLeft === 0)
      setIsAtEnd(element.scrollLeft + element.clientWidth === element.scrollWidth)
    }

    // Initial check
    checkScrollPosition()

    // Check on scroll
    scrollContainerRef.current?.addEventListener("scroll", checkScrollPosition)

    // Cleanup
    return () => {
      scrollContainerRef.current?.removeEventListener("scroll", checkScrollPosition)
    }
  }, [])

  const scrollLeft = () => {
    scrollContainerRef.current?.scrollBy({
      left: -300,
      behavior: "smooth",
    })
  }

  const scrollRight = () => {
    scrollContainerRef.current?.scrollBy({
      left: 300,
      behavior: "smooth",
    })
  }

  const getScoreColor = (score: number) => {
    if (score >= 95) return "text-green-600"
    if (score >= 90) return "text-blue-600"
    if (score >= 85) return "text-yellow-600"
    return "text-gray-600"
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Header */}
      <div className="space-y-2">
        <h1 className="text-2xl font-bold">Certificados</h1>
        <p className="text-muted-foreground">Tus logros y certificaciones completadas</p>
      </div>

      {/* Certificates Stats */}
      <div className="grid gap-6 md:grid-cols-1">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Certificados</CardTitle>
            <Award className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{certificates.length}</div>
            <p className="text-xs text-muted-foreground">Certificados completados</p>
          </CardContent>
        </Card>
      </div>

      {/* Certificates Carousel */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Mis Certificados</CardTitle>
              <CardDescription>Navega por tus certificaciones completadas</CardDescription>
            </div>
            <div className="flex space-x-2">
              <Button variant="outline" size="icon" onClick={scrollLeft} disabled={isAtStart}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button variant="outline" size="icon" onClick={scrollRight} disabled={isAtEnd}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="overflow-x-auto scrollbar-hide">
          <div ref={scrollContainerRef} className="flex space-x-4 py-2 scroll-smooth">
            {certificates.map((certificate) => (
              <div key={certificate.id} className="w-80 shrink-0">
                <Card className="overflow-hidden">
                  <div className="aspect-video bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
                    <img
                      src={certificate.image || "/placeholder.svg"}
                      alt={certificate.title}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <CardContent className="p-4">
                    <div className="space-y-3">
                      <div>
                        <h3 className="font-semibold text-sm">{certificate.title}</h3>
                        <p className="text-xs text-muted-foreground">por {certificate.instructor}</p>
                      </div>

                      <div className="flex justify-between text-xs text-muted-foreground">
                        <span>Completado: {new Date(certificate.completedDate).toLocaleDateString()}</span>
                        <span>{certificate.duration}</span>
                      </div>

                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-1">
                          <Star className="h-3 w-3 fill-current text-yellow-400" />
                          <span className={`text-sm font-medium ${getScoreColor(certificate.score)}`}>
                            {certificate.score}%
                          </span>
                        </div>
                      </div>

                      <div className="flex flex-wrap gap-1">
                        {certificate.skills.slice(0, 3).map((skill) => (
                          <Badge key={skill} variant="secondary" className="text-xs">
                            {skill}
                          </Badge>
                        ))}
                        {certificate.skills.length > 3 && (
                          <Badge variant="secondary" className="text-xs">
                            +{certificate.skills.length - 3}
                          </Badge>
                        )}
                      </div>

                      <div className="flex space-x-2 pt-2">
                        <Button size="sm" variant="outline" className="flex-1 bg-transparent">
                          <Eye className="h-3 w-3 mr-1" />
                          Ver
                        </Button>
                        <Button size="sm" variant="outline" className="flex-1 bg-transparent">
                          <Download className="h-3 w-3 mr-1" />
                          PDF
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
import { ChevronLeft, ChevronRight } from "lucide-react"
