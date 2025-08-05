import { createMiddlewareClient } from "@supabase/auth-helpers-nextjs"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()

  // Only apply middleware to dashboard routes
  if (!req.nextUrl.pathname.startsWith("/dashboard")) {
    return res
  }

  // Check if environment variables are available
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    console.warn("Supabase environment variables not available in middleware")
    return NextResponse.redirect(new URL("/", req.url))
  }

  try {
    const supabase = createMiddlewareClient({ req, res })
    const {
      data: { session },
    } = await supabase.auth.getSession()

    // If no session, redirect to home
    if (!session) {
      return NextResponse.redirect(new URL("/", req.url))
    }

    return res
  } catch (error) {
    console.error("Middleware error:", error)
    return NextResponse.redirect(new URL("/", req.url))
  }
}

export const config = {
  matcher: ["/dashboard/:path*"],
}
