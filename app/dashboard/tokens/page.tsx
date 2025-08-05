"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Coins, TrendingUp, Globe, Zap } from "lucide-react"

export default function TokensPage() {
  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Header */}
      <div className="space-y-2">
        <h1 className="text-2xl font-bold">Token LEAP</h1>
        <p className="text-muted-foreground">Información sobre el token nativo de MyLeap</p>
      </div>

      {/* Token Info Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {/* Token Overview */}
        <Card className="md:col-span-2 lg:col-span-1">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Coins className="h-5 w-5 text-blue-500" />
              LEAP Token
            </CardTitle>
            <CardDescription>Token nativo de la plataforma MyLeap</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Símbolo</span>
                <Badge variant="secondary">LEAP</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Tipo</span>
                <span className="text-sm font-medium">Utility Token</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Red</span>
                <span className="text-sm font-medium">Polygon</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Token Stats */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-500" />
              Estadísticas
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Supply Total</span>
                <span className="text-sm font-medium">1,000,000 LEAP</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">En Circulación</span>
                <span className="text-sm font-medium">750,000 LEAP</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Holders</span>
                <span className="text-sm font-medium">2,847</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Utility */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Zap className="h-5 w-5 text-yellow-500" />
              Utilidad
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-2">
              <div className="h-2 w-2 bg-blue-500 rounded-full"></div>
              <span className="text-sm">Acceso a cursos premium</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="h-2 w-2 bg-green-500 rounded-full"></div>
              <span className="text-sm">Recompensas por completar cursos</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="h-2 w-2 bg-purple-500 rounded-full"></div>
              <span className="text-sm">Participación en governance</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="h-2 w-2 bg-orange-500 rounded-full"></div>
              <span className="text-sm">Descuentos en certificaciones</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Token Economics */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Globe className="h-5 w-5 text-blue-500" />
            Tokenomics
          </CardTitle>
          <CardDescription>Distribución y economía del token LEAP</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="h-3 w-3 bg-blue-500 rounded-full"></div>
                <span className="text-sm font-medium">Comunidad (40%)</span>
              </div>
              <p className="text-xs text-muted-foreground">400,000 LEAP para recompensas y incentivos</p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="h-3 w-3 bg-green-500 rounded-full"></div>
                <span className="text-sm font-medium">Desarrollo (25%)</span>
              </div>
              <p className="text-xs text-muted-foreground">250,000 LEAP para desarrollo de la plataforma</p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="h-3 w-3 bg-purple-500 rounded-full"></div>
                <span className="text-sm font-medium">Equipo (20%)</span>
              </div>
              <p className="text-xs text-muted-foreground">200,000 LEAP con vesting de 2 años</p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="h-3 w-3 bg-orange-500 rounded-full"></div>
                <span className="text-sm font-medium">Reserva (15%)</span>
              </div>
              <p className="text-xs text-muted-foreground">150,000 LEAP para futuras iniciativas</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
