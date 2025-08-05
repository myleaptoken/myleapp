"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Users, MessageCircle, Heart, Share2 } from "lucide-react"
import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"

const categories = [
  { id: "all", name: "Todos", color: "bg-gray-100 text-gray-800" },
  { id: "desarrollo", name: "Desarrollo", color: "bg-blue-100 text-blue-800" },
  { id: "marketing", name: "Marketing", color: "bg-green-100 text-green-800" },
  { id: "alianzas", name: "Alianzas", color: "bg-purple-100 text-purple-800" },
  { id: "comunidad", name: "Comunidad", color: "bg-orange-100 text-orange-800" },
  { id: "token", name: "Token", color: "bg-yellow-100 text-yellow-800" },
  { id: "proyectos", name: "Proyectos", color: "bg-indigo-100 text-indigo-800" },
  { id: "grants", name: "Grants", color: "bg-pink-100 text-pink-800" },
]

const communityPosts = [
  {
    id: 1,
    author: "María González",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 2 horas",
    category: "desarrollo",
    title: "¡Completé mi primer curso de React!",
    content:
      "Después de 3 semanas de estudio intensivo, finalmente terminé el curso de React Fundamentals. Los proyectos prácticos fueron increíbles y ahora me siento más confiada para aplicar a trabajos frontend.",
    likes: 24,
    comments: 8,
    shares: 3,
  },
  {
    id: 2,
    author: "Carlos Ruiz",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 4 horas",
    category: "token",
    title: "¿Cuál es la mejor estrategia para ganar tokens LEAP?",
    content:
      "He estado participando en la plataforma por un mes y me gustaría optimizar mi estrategia para ganar más tokens. ¿Qué actividades dan mejores recompensas?",
    likes: 12,
    comments: 15,
    shares: 2,
  },
  {
    id: 3,
    author: "Ana Martínez",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 6 horas",
    category: "comunidad",
    title: "Mi experiencia como facilitadora en MyLeap",
    content:
      "Han pasado 6 meses desde que me uní como facilitadora y ha sido una experiencia increíble. Ver el progreso de los estudiantes y poder ayudarlos en su journey de aprendizaje es muy gratificante.",
    likes: 45,
    comments: 12,
    shares: 8,
  },
  {
    id: 4,
    author: "Diego López",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 1 día",
    category: "marketing",
    title: "Nueva campaña de referidos disponible",
    content:
      "Acabamos de lanzar una nueva campaña donde puedes ganar tokens LEAP por cada amigo que invites. ¡Comparte tu código de referido y gana recompensas!",
    likes: 18,
    comments: 6,
    shares: 12,
  },
  {
    id: 5,
    author: "Sofia Chen",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 2 días",
    category: "proyectos",
    title: "Buscando colaboradores para proyecto DeFi",
    content:
      "Estoy desarrollando una aplicación DeFi y busco desarrolladores frontend y backend para unirse al equipo. El proyecto tiene potencial de financiamiento.",
    likes: 32,
    comments: 18,
    shares: 5,
  },
  {
    id: 6,
    author: "Roberto Kim",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 3 días",
    category: "grants",
    title: "Nueva ronda de grants para desarrolladores",
    content:
      "MyLeap acaba de anunciar una nueva ronda de grants de hasta $10,000 para proyectos innovadores en Web3. Las aplicaciones cierran el 30 de este mes.",
    likes: 67,
    comments: 24,
    shares: 15,
  },
  {
    id: 7,
    author: "Laura Vega",
    avatar: "/placeholder.svg?height=40&width=40",
    time: "hace 4 días",
    category: "alianzas",
    title: "Partnership con Polygon anunciado",
    content:
      "Excelentes noticias! MyLeap acaba de anunciar una alianza estratégica con Polygon para mejorar la experiencia de los usuarios y reducir costos de transacción.",
    likes: 89,
    comments: 31,
    shares: 22,
  },
]

const getCategoryColor = (category: string) => {
  const categoryObj = categories.find((cat) => cat.id === category)
  return categoryObj ? categoryObj.color : "bg-gray-100 text-gray-800"
}

export default function CommunityPage() {
  const [selectedCategory, setSelectedCategory] = useState("all")
  const [currentPage, setCurrentPage] = useState(1)
  const [selectedPost, setSelectedPost] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const postsPerPage = 5

  const filteredPosts =
    selectedCategory === "all" ? communityPosts : communityPosts.filter((post) => post.category === selectedCategory)

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Header */}
      <div className="space-y-2">
        <h1 className="text-2xl font-bold">Comunidad</h1>
        <p className="text-muted-foreground">Conecta con otros estudiantes y comparte tu experiencia</p>
      </div>

      {/* Community Stats */}
      <div className="grid gap-6 md:grid-cols-1">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Holders</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">2,847</div>
            <p className="text-xs text-muted-foreground">+12% desde el mes pasado</p>
          </CardContent>
        </Card>
      </div>

      {/* Community Feed */}
      <Card>
        <CardHeader>
          <CardTitle>Foro de la Comunidad</CardTitle>
          <CardDescription>Las últimas publicaciones de nuestra comunidad</CardDescription>

          {/* Category Filter */}
          <div className="overflow-x-auto pb-2">
            <div className="flex gap-2 min-w-max">
              {categories.map((category) => (
                <Button
                  key={category.id}
                  variant={selectedCategory === category.id ? "default" : "outline"}
                  size="sm"
                  onClick={() => setSelectedCategory(category.id)}
                  className={`text-xs whitespace-nowrap ${
                    selectedCategory === category.id
                      ? ""
                      : `hover:${category.color.replace("100", "200")} border-gray-200`
                  }`}
                >
                  {category.name}
                </Button>
              ))}
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Paginated Posts */}
          {(() => {
            const startIndex = (currentPage - 1) * postsPerPage
            const endIndex = startIndex + postsPerPage
            const paginatedPosts = filteredPosts.slice(startIndex, endIndex)
            const totalPages = Math.ceil(filteredPosts.length / postsPerPage)

            return (
              <>
                {paginatedPosts.map((post) => (
                  <div
                    key={post.id}
                    className="border border-gray-100 rounded-lg p-4 hover:shadow-md transition-all cursor-pointer"
                    onClick={() => {
                      setSelectedPost(post)
                      setIsModalOpen(true)
                    }}
                  >
                    {/* Simplified Post Header */}
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center space-x-3">
                        <Avatar className="h-8 w-8">
                          <AvatarImage src={post.avatar || "/placeholder.svg"} alt={post.author} />
                          <AvatarFallback className="text-xs">
                            {post.author
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="flex items-center space-x-2">
                            <h4 className="text-sm font-semibold">{post.author}</h4>
                            <Badge variant="secondary" className={`text-xs ${getCategoryColor(post.category)}`}>
                              {categories.find((cat) => cat.id === post.category)?.name || post.category}
                            </Badge>
                          </div>
                          <p className="text-xs text-muted-foreground">{post.time}</p>
                        </div>
                      </div>
                    </div>

                    {/* Simplified Content */}
                    <div className="space-y-2 mb-3">
                      <h3 className="font-medium text-sm line-clamp-1">{post.title}</h3>
                      <p className="text-sm text-muted-foreground line-clamp-2">{post.content}</p>
                    </div>

                    {/* Quick Stats */}
                    <div className="flex items-center space-x-4 text-xs text-muted-foreground">
                      <span className="flex items-center">
                        <Heart className="h-3 w-3 mr-1" />
                        {post.likes}
                      </span>
                      <span className="flex items-center">
                        <MessageCircle className="h-3 w-3 mr-1" />
                        {post.comments}
                      </span>
                      <span className="flex items-center">
                        <Share2 className="h-3 w-3 mr-1" />
                        {post.shares}
                      </span>
                    </div>
                  </div>
                ))}

                {/* Pagination */}
                {totalPages > 1 && (
                  <div className="flex justify-center items-center space-x-2 pt-4">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentPage((prev) => Math.max(prev - 1, 1))}
                      disabled={currentPage === 1}
                    >
                      Anterior
                    </Button>

                    <div className="flex space-x-1">
                      {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                        <Button
                          key={page}
                          variant={currentPage === page ? "default" : "outline"}
                          size="sm"
                          onClick={() => setCurrentPage(page)}
                          className="w-8 h-8 p-0"
                        >
                          {page}
                        </Button>
                      ))}
                    </div>

                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentPage((prev) => Math.min(prev + 1, totalPages))}
                      disabled={currentPage === totalPages}
                    >
                      Siguiente
                    </Button>
                  </div>
                )}
              </>
            )
          })()}

          {filteredPosts.length === 0 && (
            <div className="text-center py-8 text-muted-foreground">
              <MessageCircle className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No hay publicaciones en esta categoría aún.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Post Detail Modal */}
      {selectedPost && (
        <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
          <DialogContent className="w-[calc(100vw-1rem)] sm:w-full max-w-2xl mx-auto max-h-[90vh] overflow-y-auto p-3 sm:p-6">
            <DialogHeader>
              <div className="flex items-center space-x-3 mb-4">
                <Avatar className="h-12 w-12">
                  <AvatarImage src={selectedPost.avatar || "/placeholder.svg"} alt={selectedPost.author} />
                  <AvatarFallback>
                    {selectedPost.author
                      .split(" ")
                      .map((n) => n[0])
                      .join("")}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <div className="flex items-center space-x-2">
                    <DialogTitle className="text-base font-semibold">{selectedPost.author}</DialogTitle>
                    <Badge variant="secondary" className={`text-xs ${getCategoryColor(selectedPost.category)}`}>
                      {categories.find((cat) => cat.id === selectedPost.category)?.name || selectedPost.category}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">{selectedPost.time}</p>
                </div>
              </div>
            </DialogHeader>

            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold mb-2">{selectedPost.title}</h2>
                <p className="text-muted-foreground leading-relaxed">{selectedPost.content}</p>
              </div>

              {/* Action Buttons */}
              <div className="pt-4 border-t">
                <div className="flex flex-wrap items-center gap-2 sm:gap-4">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-muted-foreground hover:text-red-500 text-xs sm:text-sm"
                  >
                    <Heart className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
                    <span className="hidden sm:inline">Me gusta</span> ({selectedPost.likes})
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-muted-foreground hover:text-blue-500 text-xs sm:text-sm"
                  >
                    <MessageCircle className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
                    <span className="hidden sm:inline">Comentar</span> ({selectedPost.comments})
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-muted-foreground hover:text-green-500 text-xs sm:text-sm"
                  >
                    <Share2 className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
                    <span className="hidden sm:inline">Compartir</span> ({selectedPost.shares})
                  </Button>
                </div>
              </div>

              {/* Comments Section */}
              <div className="space-y-3 pt-4 border-t">
                <h3 className="font-medium">Comentarios</h3>
                <div className="space-y-3 max-h-60 overflow-y-auto">
                  {/* Sample comments */}
                  <div className="flex space-x-3 p-3 bg-muted/50 rounded-lg">
                    <Avatar className="h-8 w-8">
                      <AvatarFallback className="text-xs">JD</AvatarFallback>
                    </Avatar>
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <span className="text-sm font-medium">Juan Díaz</span>
                        <span className="text-xs text-muted-foreground">hace 1 hora</span>
                      </div>
                      <p className="text-sm text-foreground mt-1">¡Excelente post! Me ayudó mucho.</p>
                    </div>
                  </div>
                  <div className="flex space-x-3 p-3 bg-muted/50 rounded-lg">
                    <Avatar className="h-8 w-8">
                      <AvatarFallback className="text-xs">MP</AvatarFallback>
                    </Avatar>
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <span className="text-sm font-medium">María Pérez</span>
                        <span className="text-xs text-muted-foreground">hace 2 horas</span>
                      </div>
                      <p className="text-sm text-foreground mt-1">Gracias por compartir tu experiencia.</p>
                    </div>
                  </div>
                </div>

                {/* Add Comment */}
                <div className="flex flex-col sm:flex-row gap-2">
                  <input
                    type="text"
                    placeholder="Escribe un comentario..."
                    className="flex-1 px-3 py-2 border border-input rounded-lg text-sm bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring min-w-0"
                  />
                  <Button size="sm" className="w-full sm:w-auto">
                    Enviar
                  </Button>
                </div>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
