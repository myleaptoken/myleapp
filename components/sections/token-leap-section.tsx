"use client"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ScrollAnimate } from "@/components/common/scroll-animate"
import { Coins, Zap, Gift, TrendingUp, Copy, Send, Download } from "lucide-react"

export function TokenLeapSection() {
  const copyContract = () => {
    navigator.clipboard.writeText("0x1234567890abcdef1234567890abcdef12345678")
  }

  return (
    <section
      id="tokens"
      className="py-16 sm:py-20 lg:py-28 bg-gradient-to-br from-background via-muted/10 to-background px-4 sm:px-6 lg:px-8"
    >
      <div className="container max-w-7xl mx-auto">
        <ScrollAnimate animation="up">
          <div className="text-center space-y-4 sm:space-y-6 mb-12 sm:mb-16 lg:mb-20">
            <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold leading-tight">
              Sistema de{" "}
              <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-green-600 bg-clip-text text-transparent">
                Tokens LEAP
              </span>
            </h2>
            <div className="max-w-3xl mx-auto px-4">
              <p className="text-base sm:text-lg lg:text-xl text-muted-foreground leading-relaxed">
                Gana tokens participando y úsalos para acceder a contenido premium y servicios exclusivos
              </p>
            </div>
          </div>
        </ScrollAnimate>

        <div className="space-y-8 sm:space-y-12 max-w-6xl mx-auto">
          {/* Project Information - Arriba ocupando todo el ancho */}
          <ScrollAnimate animation="scale">
            <div className="w-full">
              <Card className="border-0 shadow-xl bg-gradient-to-br from-background to-muted/20">
                <CardContent className="p-6 sm:p-8 lg:p-10">
                  <div className="flex items-center space-x-3 mb-6 sm:mb-8">
                    <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-lg bg-gradient-to-r from-blue-500 to-purple-500 flex items-center justify-center">
                      <span className="text-white font-bold text-sm sm:text-base">📊</span>
                    </div>
                    <h4 className="font-bold text-lg sm:text-xl lg:text-2xl">Información del Proyecto</h4>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6 sm:gap-8">
                    <div className="text-center">
                      <div className="text-muted-foreground text-sm sm:text-base mb-2">Supply Total</div>
                      <div className="font-semibold text-sm sm:text-base">1,000,000 LEAP</div>
                    </div>
                    <div className="text-center">
                      <div className="text-muted-foreground text-sm sm:text-base mb-2">Circulante</div>
                      <div className="font-semibold text-sm sm:text-base">750,000 LEAP</div>
                    </div>
                    <div className="text-center">
                      <div className="text-muted-foreground text-sm sm:text-base mb-2">Precio</div>
                      <div className="font-semibold text-primary text-sm sm:text-base">$0.25 USD</div>
                    </div>
                    <div className="text-center">
                      <div className="text-muted-foreground text-sm sm:text-base mb-2">Holders</div>
                      <div className="font-semibold text-sm sm:text-base">12,450</div>
                    </div>
                    <div className="text-center">
                      <div className="text-muted-foreground text-sm sm:text-base mb-2">Market Cap</div>
                      <div className="font-semibold text-sm sm:text-base">$187.5K</div>
                    </div>
                    <div className="text-center">
                      <div className="text-muted-foreground text-sm sm:text-base mb-2">Contrato</div>
                      <div className="flex items-center justify-center space-x-2">
                        <span className="font-mono text-xs sm:text-sm bg-muted px-2 py-1 rounded">0x1234...5678</span>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={copyContract}
                          className="h-6 w-6 p-0 hover:bg-muted-foreground/10"
                        >
                          <Copy className="h-3 w-3" />
                        </Button>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </ScrollAnimate>

          {/* Cards horizontales - Balance (doble ancho) + Earning Cards */}
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 sm:gap-8">
            {/* Token Balance Card - Ocupa 2 columnas */}
            <ScrollAnimate animation="left" delay={200} className="lg:col-span-2">
              <Card className="relative overflow-hidden border-0 shadow-2xl h-full bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 dark:from-slate-800 dark:via-blue-800 dark:to-purple-800">
                {/* Subtle overlay pattern */}
                <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent" />
                <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full blur-2xl transform translate-x-16 -translate-y-16" />

                <CardContent className="relative p-6 sm:p-8 lg:p-10 h-full flex flex-col justify-between">
                  {/* Header */}
                  <div className="flex items-start justify-between mb-8">
                    <div className="space-y-2">
                      <div className="flex items-center space-x-2">
                        <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                        <span className="text-white/60 text-xs sm:text-sm font-medium uppercase tracking-wider">
                          Balance
                        </span>
                      </div>
                      <h3 className="text-xl sm:text-2xl lg:text-3xl font-bold text-white">LEAP</h3>
                    </div>
                    <div className="p-3 bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20">
                      <Coins className="h-6 w-6 sm:h-7 sm:w-7 text-white/80" />
                    </div>
                  </div>

                  {/* Balance Amount */}
                  <div className="mb-8">
                    <div className="flex items-baseline space-x-2 mb-2">
                      <span className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white">2,450</span>
                      <span className="text-white/60 text-lg sm:text-xl font-medium">LEAP</span>
                    </div>
                    <div className="flex items-center space-x-2 text-green-400">
                      <TrendingUp className="h-4 w-4" />
                      <span className="text-sm sm:text-base font-medium">+150 esta semana</span>
                      <span className="text-white/40 text-sm">+6.5%</span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="grid grid-cols-2 gap-3 sm:gap-4">
                    <Button
                      size="lg"
                      className="bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 hover:border-white/30 transition-all duration-300 rounded-xl h-12 sm:h-14"
                    >
                      <Send className="h-4 w-4 mr-2" />
                      <span className="font-medium">Enviar</span>
                    </Button>
                    <Button
                      size="lg"
                      className="bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 hover:border-white/30 transition-all duration-300 rounded-xl h-12 sm:h-14"
                    >
                      <Download className="h-4 w-4 mr-2" />
                      <span className="font-medium">Recibir</span>
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </ScrollAnimate>

            {/* Earning Card 1 - Ocupa 1 columna */}
            <ScrollAnimate animation="right" delay={300} className="lg:col-span-1">
              <Card className="group relative overflow-hidden border-0 shadow-lg hover:shadow-xl transition-all duration-500 h-full bg-gradient-to-br from-yellow-50 to-orange-50 dark:from-yellow-900/20 dark:to-orange-900/20 hover:-translate-y-1">
                <div className="absolute inset-0 bg-gradient-to-br from-yellow-500/5 to-orange-500/5" />
                <div className="absolute top-0 right-0 w-20 h-20 bg-yellow-400/10 rounded-full blur-xl transform translate-x-10 -translate-y-10" />

                <CardContent className="relative p-6 sm:p-8 text-center h-full flex flex-col justify-center space-y-4">
                  <div className="mx-auto w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                    <Zap className="h-8 w-8 text-white" />
                  </div>
                  <div className="space-y-2">
                    <div className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-yellow-600 to-orange-600 bg-clip-text text-transparent">
                      +250 - 500
                    </div>
                    <div className="text-sm sm:text-base text-muted-foreground font-medium">Por evento</div>
                  </div>
                </CardContent>
              </Card>
            </ScrollAnimate>

            {/* Earning Card 2 - Ocupa 1 columna */}
            <ScrollAnimate animation="right" delay={400} className="lg:col-span-1">
              <Card className="group relative overflow-hidden border-0 shadow-lg hover:shadow-xl transition-all duration-500 h-full bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 hover:-translate-y-1">
                <div className="absolute inset-0 bg-gradient-to-br from-green-500/5 to-emerald-500/5" />
                <div className="absolute top-0 right-0 w-20 h-20 bg-green-400/10 rounded-full blur-xl transform translate-x-10 -translate-y-10" />

                <CardContent className="relative p-6 sm:p-8 text-center h-full flex flex-col justify-center space-y-4">
                  <div className="mx-auto w-16 h-16 bg-gradient-to-br from-green-400 to-emerald-500 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                    <Gift className="h-8 w-8 text-white" />
                  </div>
                  <div className="space-y-2">
                    <div className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                      +50
                    </div>
                    <div className="text-sm sm:text-base text-muted-foreground font-medium">Semanal</div>
                  </div>
                </CardContent>
              </Card>
            </ScrollAnimate>
          </div>
        </div>

        <ScrollAnimate animation="up" delay={500} className="space-y-6 sm:space-y-8 mt-16 sm:mt-20 lg:mt-24">
          <h3 className="text-xl sm:text-2xl lg:text-3xl font-bold mb-6 sm:mb-8">Usar Tokens</h3>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
            {[
              {
                title: "Cursos",
                description: "Acceso a contenido premium",
                cost: "200-500",
                icon: "📚",
                points: ["Instructores expertos", "Certificados oficiales", "Material descargable"],
              },
              {
                title: "Mentorías",
                description: "Sesiones personalizadas 1:1",
                cost: "300-800",
                icon: "👥",
                points: ["Expertos industria", "Feedback directo", "Plan personalizado"],
              },
              {
                title: "Eventos",
                description: "Acceso VIP prioritario",
                cost: "150-400",
                icon: "🎯",
                points: ["Networking exclusivo", "Contenido premium", "Acceso grabaciones"],
              },
              {
                title: "Certificados",
                description: "Reconocimiento internacional",
                cost: "500-1000",
                icon: "🏆",
                points: ["Validación oficial", "Credibilidad profesional", "Mejora CV"],
              },
            ].map((benefit, index) => (
              <ScrollAnimate key={index} animation="up" delay={600 + index * 100}>
                <Card className="hover:shadow-md transition-all duration-300">
                  <CardContent className="p-4 sm:p-6">
                    <div className="flex items-start space-x-4">
                      <div className="text-2xl sm:text-3xl flex-shrink-0 mt-1">{benefit.icon}</div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-2">
                          <h4 className="font-semibold text-sm sm:text-base">{benefit.title}</h4>
                          <div className="text-xs sm:text-sm font-medium text-primary">{benefit.cost} tokens</div>
                        </div>
                        <p className="text-xs sm:text-sm text-muted-foreground mb-3">{benefit.description}</p>
                        <ul className="space-y-1">
                          {benefit.points.map((point, pointIndex) => (
                            <li key={pointIndex} className="flex items-center text-xs text-muted-foreground">
                              <div className="w-1 h-1 rounded-full bg-primary mr-2 flex-shrink-0" />
                              {point}
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </ScrollAnimate>
            ))}
          </div>

          <ScrollAnimate animation="scale" delay={1000}>
            <Button
              size="lg"
              className="w-full text-base sm:text-lg py-4 sm:py-6 gradient-balance text-white hover:opacity-90 transition-opacity"
            >
              Explorar Marketplace
            </Button>
          </ScrollAnimate>
        </ScrollAnimate>
      </div>
    </section>
  )
}
