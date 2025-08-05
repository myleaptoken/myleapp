"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { ArrowRight, Sparkles } from "lucide-react"
import Link from "next/link"
import { AuthModal } from "@/components/auth/auth-modal"
import { useAuth } from "@/hooks/use-auth"
import { supabase } from "@/lib/supabase"

interface HeroSettings {
  video_url: string | null
  fallback_image_url: string
  video_enabled: boolean
}

export function HeroSection() {
  const [isAuthModalOpen, setIsAuthModalOpen] = React.useState(false)
  const { user } = useAuth()
  const [heroSettings, setHeroSettings] = React.useState<HeroSettings | null>(null)
  const [videoError, setVideoError] = React.useState(false)
  const [videoLoaded, setVideoLoaded] = React.useState(false)
  const videoRef = React.useRef<HTMLVideoElement>(null)

  // Fetch hero settings from database
  React.useEffect(() => {
    async function fetchHeroSettings() {
      try {
        console.log("🔍 Fetching hero settings...")
        const { data, error } = await supabase.rpc("get_hero_settings")

        if (error) {
          console.error("❌ Error fetching hero settings:", error)
          // Set fallback settings if function fails
          setHeroSettings({
            video_url: null,
            fallback_image_url:
              "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png",
            video_enabled: false,
          })
          return
        }

        if (data && data.length > 0) {
          const settings = data[0]
          console.log("✅ Hero settings loaded:", settings)
          setHeroSettings(settings)
        } else {
          console.log("⚠️ No hero settings found, using defaults")
          setHeroSettings({
            video_url: null,
            fallback_image_url:
              "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png",
            video_enabled: false,
          })
        }
      } catch (error) {
        console.error("❌ Error in fetchHeroSettings:", error)
        // Set fallback settings on any error
        setHeroSettings({
          video_url: null,
          fallback_image_url:
            "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png",
          video_enabled: false,
        })
      }
    }

    fetchHeroSettings()
  }, [])

  // Get video URL from Supabase Storage
  const getVideoUrl = React.useCallback(() => {
    if (!heroSettings?.video_url) {
      console.log("❌ No video URL in settings")
      return null
    }

    try {
      // Cambiar temporalmente el nombre del archivo
      const videoFileName = "logoleapv.mp4" // Cambia aquí el nombre
      const { data } = supabase.storage.from("myleapstorage").getPublicUrl(videoFileName)
      console.log("🎬 Video URL constructed:", data.publicUrl)
      return data.publicUrl
    } catch (error) {
      console.error("❌ Error constructing video URL:", error)
      return null
    }
  }, [heroSettings?.video_url])

  const videoUrl = getVideoUrl()
  const handleVideoError = (e: React.SyntheticEvent<HTMLVideoElement, Event>) => {
    const video = e.currentTarget
    console.error("=== Video Error Details ===")
    console.error("Video error:", video.error)
    console.error("Network state:", video.networkState)
    console.error("Ready state:", video.readyState)
    console.error("Source URL:", video.src)

    if (video.error) {
      console.error("Error code:", video.error.code)
      console.error("Error message:", video.error.message)

      // Log specific error codes
      switch (video.error.code) {
        case 1:
          console.error("MEDIA_ERR_ABORTED: Video loading was aborted")
          break
        case 2:
          console.error("MEDIA_ERR_NETWORK: Network error occurred")
          break
        case 3:
          console.error("MEDIA_ERR_DECODE: Video decoding error")
          break
        case 4:
          console.error("MEDIA_ERR_SRC_NOT_SUPPORTED: Video format not supported")
          break
        default:
          console.error("Unknown video error")
      }
    }

    console.log("🔄 Switching to fallback image")
    setVideoError(true)
  }

  const handleVideoLoad = () => {
    console.log("✅ Video loaded successfully")
    setVideoLoaded(true)
    setVideoError(false)
  }

  return (
    <>
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-background via-background to-muted/20 px-4 sm:px-6 lg:px-8">
        {/* Background Effects */}
        <div className="absolute inset-0 bg-grid-pattern opacity-5" />
        <div className="absolute top-20 left-10 w-72 h-72 bg-blue-500/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-20 right-10 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl animate-pulse delay-1000" />
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-green-500/5 rounded-full blur-3xl" />

        <div className="container relative z-10 text-center max-w-6xl mx-auto py-12 sm:py-16 lg:py-20">
          <style jsx>{`
            @keyframes float {
              0%, 100% { transform: translateY(0px) rotate(0deg); }
              25% { transform: translateY(-8px) rotate(1deg); }
              50% { transform: translateY(-12px) rotate(0deg); }
              75% { transform: translateY(-8px) rotate(-1deg); }
            }
            
            @keyframes glow {
              0% { filter: drop-shadow(0 0 20px rgba(139, 92, 246, 0.3)) drop-shadow(0 0 40px rgba(59, 130, 246, 0.2)); }
              100% { filter: drop-shadow(0 0 30px rgba(139, 92, 246, 0.5)) drop-shadow(0 0 60px rgba(59, 130, 246, 0.3)); }
            }
          `}</style>

          <div className="space-y-8 sm:space-y-10 lg:space-y-12 animate-fade-in-up">
            {/* Logo Central */}
            <div className="flex justify-center mb-6 sm:mb-8 lg:mb-12">
              <div
                className="h-32 w-20 sm:h-40 sm:w-24 lg:h-48 lg:w-28 rounded-2xl flex items-center justify-center shadow-2xl overflow-hidden bg-gradient-to-br from-purple-100 to-blue-100 dark:from-purple-900/20 dark:to-blue-900/20 hover:scale-105 transition-all duration-1000 ease-in-out"
                style={{
                  animation: "float 6s ease-in-out infinite, glow 4s ease-in-out infinite alternate",
                  filter: "drop-shadow(0 0 20px rgba(139, 92, 246, 0.3))",
                  aspectRatio: "9/16",
                }}
              >
                <video
                  ref={videoRef}
                  src={videoUrl}
                  autoPlay
                  loop
                  muted
                  playsInline
                  className="w-full h-full object-cover rounded-2xl"
                  onError={handleVideoError}
                  onLoadedData={handleVideoLoad}
                  onCanPlay={() => console.log("🎬 Video can play")}
                  onLoadStart={() => console.log("⏳ Video load started")}
                  onLoadedMetadata={() => console.log("📊 Video metadata loaded")}
                  onPlay={() => console.log("▶️ Video started playing")}
                  onWaiting={() => console.log("⏸️ Video waiting for data")}
                  onStalled={() => console.log("🚫 Video stalled")}
                  onSuspend={() => console.log("⏹️ Video suspended")}
                />
              </div>
            </div>

            {/* Debug info (only in development) */}
            {process.env.NODE_ENV === "development" && (
              <div className="text-xs text-muted-foreground bg-muted/20 p-3 rounded-lg max-w-lg mx-auto">
                <div className="font-mono space-y-1">
                  <div>Settings: {heroSettings ? "✅ Loaded" : "❌ Missing"}</div>
                  <div>Video URL: {videoUrl ? "✅ Set" : "❌ Missing"}</div>
                  <div>Video Enabled: {heroSettings?.video_enabled ? "✅ Yes" : "❌ No"}</div>
                  <div>Error: {videoError ? "❌ Yes" : "✅ No"}</div>
                  <div>Loaded: {videoLoaded ? "✅ Yes" : "⏳ Loading"}</div>
                  <div>Should Show: ✅ Video</div>
                  {videoUrl && <div className="mt-2 p-2 bg-muted rounded text-xs break-all">URL: {videoUrl}</div>}
                </div>
              </div>
            )}

            {/* Powered by */}
            <div className="flex items-center justify-center space-x-2 text-sm sm:text-base text-muted-foreground mb-6 sm:mb-8">
              <Sparkles className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
              <span>Powered by Método ONE</span>
            </div>

            {/* Main Title */}
            <div className="space-y-4 sm:space-y-6 px-4 sm:px-6 lg:px-8">
              <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-bold leading-tight sm:leading-tight md:leading-tight lg:leading-tight">
                <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-green-600 bg-clip-text text-transparent block mb-2 sm:mb-4">
                  Salto Trascendental
                </span>
                <span className="text-foreground block">a una consciencia superior</span>
              </h1>
            </div>

            {/* Subtitle */}
            <div className="px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
              <p className="text-base sm:text-lg lg:text-xl text-muted-foreground leading-relaxed sm:leading-relaxed lg:leading-relaxed">
                Moviliza tu energía y sana dolores físicos. Usa tokens LEAP para acceder a facilitadores certificados,
                cursos, eventos de sanación y agentes de IA especializados.
              </p>
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-6 pt-6 sm:pt-8 lg:pt-12 px-4">
              {user ? (
                <Link href="/dashboard">
                  <Button
                    size="lg"
                    className="text-base sm:text-lg px-6 sm:px-8 py-4 sm:py-6 rounded-full shadow-lg hover:shadow-xl transition-all duration-300 group gradient-balance text-white hover:opacity-90"
                  >
                    Ir al Dashboard
                    <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
                  </Button>
                </Link>
              ) : (
                <Button
                  size="lg"
                  className="text-base sm:text-lg px-6 sm:px-8 py-4 sm:py-6 rounded-full shadow-lg hover:shadow-xl transition-all duration-300 group gradient-balance text-white hover:opacity-90"
                  onClick={() => setIsAuthModalOpen(true)}
                >
                  Comenzar Ahora
                  <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
                </Button>
              )}
              <Button
                variant="outline"
                size="lg"
                className="text-base sm:text-lg px-6 sm:px-8 py-4 sm:py-6 rounded-full bg-transparent min-w-[200px]"
              >
                Explorar Cursos
              </Button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-6 sm:gap-8 lg:gap-12 pt-12 sm:pt-16 lg:pt-20 max-w-3xl mx-auto px-4">
              <div className="text-center space-y-2 sm:space-y-3">
                <div className="text-2xl sm:text-3xl lg:text-4xl font-bold text-primary">1,000+</div>
                <div className="text-sm sm:text-base text-muted-foreground">Sanaciones</div>
              </div>
              <div className="text-center space-y-2 sm:space-y-3">
                <div className="text-2xl sm:text-3xl lg:text-4xl font-bold text-primary">5+</div>
                <div className="text-sm sm:text-base text-muted-foreground">Cursos Disponibles</div>
              </div>
              <div className="text-center space-y-2 sm:space-y-3 col-span-2 sm:col-span-1">
                <div className="text-2xl sm:text-3xl lg:text-4xl font-bold text-primary">50+</div>
                <div className="text-sm sm:text-base text-muted-foreground">Facilitadores</div>
              </div>
            </div>

            {/* Powered by Badge */}
            <div className="pt-8 sm:pt-12 lg:pt-16">
              <div className="inline-flex items-center space-x-2 px-4 sm:px-6 py-2 sm:py-3 rounded-full bg-muted/50 backdrop-blur-sm border">
                <Sparkles className="h-4 w-4 text-primary" />
                <span className="text-sm sm:text-base font-medium">Impulsado por</span>
                <span className="text-sm sm:text-base font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                  Método ONE
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <AuthModal isOpen={isAuthModalOpen} onClose={() => setIsAuthModalOpen(false)} />
    </>
  )
}
