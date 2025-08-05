import type React from "react"
import { Card, CardContent } from "@/components/ui/card"
import type { FeatureCardProps } from "@/types/feature"
import * as Icons from "lucide-react"
import { cn } from "@/lib/utils"

export function FeatureCard({ feature, index }: FeatureCardProps) {
  const Icon = Icons[feature.icon as keyof typeof Icons] as React.ComponentType<{ className?: string }>

  return (
    <Card className="group relative overflow-hidden border-0 bg-gradient-to-br from-background to-muted/50 hover:shadow-lg transition-all duration-300 hover:-translate-y-2">
      <CardContent className="p-6">
        <div
          className={cn(
            "w-12 h-12 rounded-lg flex items-center justify-center mb-4 text-white transition-transform duration-300 group-hover:scale-110",
            feature.gradient,
          )}
        >
          <Icon className="h-6 w-6" />
        </div>

        <h3 className="text-xl font-semibold mb-3 group-hover:text-primary transition-colors">{feature.title}</h3>

        <p className="text-muted-foreground mb-4 leading-relaxed">{feature.description}</p>

        <ul className="space-y-2">
          {feature.benefits.map((benefit, benefitIndex) => (
            <li key={benefitIndex} className="flex items-center text-sm text-muted-foreground">
              <div className="w-1.5 h-1.5 rounded-full bg-primary mr-2 flex-shrink-0" />
              {benefit}
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  )
}
