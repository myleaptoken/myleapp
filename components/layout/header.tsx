"use client"

import * as React from "react"
import Link from "next/link"
import { Menu, X } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/common/theme-toggle"
import { AuthModal } from "@/components/auth/auth-modal"
import { MAIN_NAVIGATION } from "@/constants/navigation"
import { useAuth } from "@/hooks/use-auth"

export function Header() {
  const [isOpen, setIsOpen] = React.useState(false)
  const [isAuthModalOpen, setIsAuthModalOpen] = React.useState(false)
  const { user, signOut } = useAuth()

  const handleSignOut = async () => {
    await signOut()
  }

  return (
    <>
      <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container flex h-16 sm:h-18 lg:h-20 items-center justify-between px-4 sm:px-6 lg:px-8">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2 sm:space-x-3">
            <div className="gradient-balance h-8 w-8 sm:h-10 sm:w-10 rounded-lg flex items-center justify-center overflow-hidden">
              <img
                src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png"
                alt="MY LEAP Logo"
                className="w-full h-full object-contain"
              />
            </div>
            <span className="font-bold text-lg sm:text-xl lg:text-2xl">MY LEAP</span>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center space-x-6 lg:space-x-8">
            {MAIN_NAVIGATION.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="text-sm lg:text-base font-medium transition-colors hover:text-primary"
              >
                {item.title}
              </Link>
            ))}
          </nav>

          {/* Desktop Actions */}
          <div className="hidden md:flex items-center space-x-3 lg:space-x-4">
            <ThemeToggle />
            {user ? (
              <div className="flex items-center space-x-3">
                <Link href="/dashboard">
                  <Button size="sm" variant="outline">
                    Dashboard
                  </Button>
                </Link>
                <Button size="sm" variant="ghost" onClick={handleSignOut}>
                  Cerrar Sesión
                </Button>
              </div>
            ) : (
              <Button
                size="sm"
                className="text-sm lg:text-base px-4 lg:px-6 gradient-balance text-white hover:opacity-90 transition-opacity"
                onClick={() => setIsAuthModalOpen(true)}
              >
                Iniciar Sanación
              </Button>
            )}
          </div>

          {/* Mobile Menu Button */}
          <div className="flex md:hidden items-center space-x-2">
            <ThemeToggle />
            <Button variant="ghost" size="sm" onClick={() => setIsOpen(!isOpen)}>
              {isOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </Button>
          </div>
        </div>

        {/* Mobile Navigation */}
        {isOpen && (
          <div className="md:hidden border-t bg-background">
            <nav className="container py-6 px-4 sm:px-6 space-y-4">
              {MAIN_NAVIGATION.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="block text-base font-medium transition-colors hover:text-primary py-2"
                  onClick={() => setIsOpen(false)}
                >
                  {item.title}
                </Link>
              ))}
              <div className="pt-4 space-y-3 border-t">
                {user ? (
                  <>
                    <Link href="/dashboard">
                      <Button size="sm" className="w-full bg-transparent" variant="outline">
                        Dashboard
                      </Button>
                    </Link>
                    <Button size="sm" className="w-full" variant="ghost" onClick={handleSignOut}>
                      Cerrar Sesión
                    </Button>
                  </>
                ) : (
                  <Button
                    size="sm"
                    className="w-full text-base py-3 gradient-balance text-white hover:opacity-90 transition-opacity"
                    onClick={() => setIsAuthModalOpen(true)}
                  >
                    Iniciar Sanación
                  </Button>
                )}
              </div>
            </nav>
          </div>
        )}
      </header>

      <AuthModal isOpen={isAuthModalOpen} onClose={() => setIsAuthModalOpen(false)} />
    </>
  )
}
