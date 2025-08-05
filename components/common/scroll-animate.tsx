"use client"

import type React from "react"

import { useScrollAnimation } from "@/hooks/use-scroll-animation"
import { cn } from "@/lib/utils"

interface ScrollAnimateProps {
  children: React.ReactNode
  className?: string
  animation?: "up" | "left" | "right" | "scale"
  delay?: number
  duration?: number
}

export function ScrollAnimate({
  children,
  className,
  animation = "up",
  delay = 0,
  duration = 0.8,
}: ScrollAnimateProps) {
  const { ref, isVisible } = useScrollAnimation()

  const animationClass = {
    up: "scroll-animate",
    left: "scroll-animate-left",
    right: "scroll-animate-right",
    scale: "scroll-animate-scale",
  }[animation]

  return (
    <div
      ref={ref}
      className={cn(animationClass, isVisible && "animate", className)}
      style={{
        transitionDelay: `${delay}ms`,
        transitionDuration: `${duration}s`,
      }}
    >
      {children}
    </div>
  )
}
