import type React from "react"
import Link from "next/link"
import { SOCIAL_LINKS } from "@/constants/social-links"
import * as Icons from "lucide-react"

export function Footer() {
  return (
    <footer className="border-t bg-background">
      <div className="container relative overflow-hidden px-4 sm:px-6 lg:px-8">
        {/* Subtle Background Effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-blue-500/3 via-purple-500/3 to-green-500/3" />

        <div className="relative z-10 py-12 sm:py-16 lg:py-20">
          {/* Main Content - Centered & Minimal */}
          <div className="max-w-4xl mx-auto text-center space-y-8 sm:space-y-12">
            {/* Brand */}
            <div className="flex items-center justify-center space-x-3">
              <div className="gradient-balance h-10 w-10 sm:h-12 sm:w-12 rounded-xl flex items-center justify-center">
                <span className="text-white font-bold text-base sm:text-lg">ML</span>
              </div>
              <span className="font-bold text-xl sm:text-2xl">MY LEAP</span>
            </div>

            {/* Tagline */}
            <p className="text-sm sm:text-base text-muted-foreground max-w-md mx-auto">
              Transformando consciencias. Expandiendo realidades.
            </p>

            {/* Social Links - Minimal */}
            <div className="flex justify-center space-x-6 sm:space-x-8">
              {SOCIAL_LINKS.map((social) => {
                const Icon = Icons[social.icon as keyof typeof Icons] as React.ComponentType<{ className?: string }>
                return (
                  <Link
                    key={social.name}
                    href={social.href}
                    className="text-muted-foreground hover:text-primary transition-all duration-300 hover:scale-110"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <Icon className="h-5 w-5 sm:h-6 sm:w-6" />
                    <span className="sr-only">{social.name}</span>
                  </Link>
                )
              })}
            </div>

            {/* Bottom Line */}
            <div className="pt-8 sm:pt-12 border-t border-border/30">
              <div className="flex flex-col sm:flex-row justify-between items-center space-y-4 sm:space-y-0 text-xs sm:text-sm text-muted-foreground">
                <p>© 2024 MY LEAP</p>
                <div className="flex space-x-6">
                  <Link href="/privacy" className="hover:text-primary transition-colors">
                    Privacidad
                  </Link>
                  <Link href="/terms" className="hover:text-primary transition-colors">
                    Términos
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
