"use client"
import { ThemeToggle } from "@/components/common/theme-toggle"

export function DashboardHeader() {
  return (
    <header className="sticky top-0 z-30 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
      <div className="flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
        {/* Logo for mobile - only visible when sidebar is collapsed */}
        <div className="flex items-center space-x-3 lg:hidden ml-2">
          <div className="gradient-balance h-8 w-8 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">ML</span>
          </div>
          <span className="font-bold text-lg">MY LEAP</span>
        </div>

        {/* Actions */}
        <div className="flex items-center">
          <ThemeToggle />
        </div>
      </div>
    </header>
  )
}
