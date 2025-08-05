"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Upload, Video, AlertCircle, CheckCircle } from "lucide-react"
import { supabase } from "@/lib/supabase"

interface HeroSettings {
  video_url: string | null
  fallback_image_url: string
  video_enabled: boolean
}

export function HeroVideoUploader() {
  const [settings, setSettings] = React.useState<HeroSettings>({
    video_url: null,
    fallback_image_url:
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logomyleap-37GUK91dbp1Doo4vgaDxsr4HMi129U.png",
    video_enabled: false,
  })
  const [uploading, setUploading] = React.useState(false)
  const [message, setMessage] = React.useState<{ type: "success" | "error"; text: string } | null>(null)
  const [videoFile, setVideoFile] = React.useState<File | null>(null)

  // Load current settings
  React.useEffect(() => {
    loadSettings()
  }, [])

  const loadSettings = async () => {
    try {
      const { data, error } = await supabase.rpc("get_hero_settings")
      if (error) throw error

      if (data && data.length > 0) {
        setSettings(data[0])
      }
    } catch (error) {
      console.error("Error loading settings:", error)
      setMessage({ type: "error", text: "Error loading current settings" })
    }
  }

  const handleVideoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // Validate file type
    if (!file.type.startsWith("video/")) {
      setMessage({ type: "error", text: "Please select a video file" })
      return
    }

    // Validate file size (max 50MB)
    if (file.size > 50 * 1024 * 1024) {
      setMessage({ type: "error", text: "Video file must be less than 50MB" })
      return
    }

    setVideoFile(file)
    setMessage(null)
  }

  const uploadVideo = async () => {
    if (!videoFile) return

    setUploading(true)
    setMessage(null)

    try {
      // Generate unique filename
      const fileExt = videoFile.name.split(".").pop()
      const fileName = `hero-video-${Date.now()}.${fileExt}`

      // Upload to Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from("myleapstorage")
        .upload(fileName, videoFile, {
          cacheControl: "3600",
          upsert: false,
        })

      if (uploadError) throw uploadError

      // Update settings with new video URL
      const newSettings = {
        ...settings,
        video_url: fileName,
      }

      // Update database
      const { error: updateError } = await supabase.rpc("update_hero_settings", {
        p_video_url: fileName,
        p_fallback_image_url: settings.fallback_image_url,
        p_video_enabled: settings.video_enabled,
      })

      if (updateError) throw updateError

      setSettings(newSettings)
      setVideoFile(null)
      setMessage({ type: "success", text: "Video uploaded successfully!" })

      // Reset file input
      const fileInput = document.getElementById("video-upload") as HTMLInputElement
      if (fileInput) fileInput.value = ""
    } catch (error) {
      console.error("Upload error:", error)
      setMessage({ type: "error", text: `Upload failed: ${error.message}` })
    } finally {
      setUploading(false)
    }
  }

  const updateSettings = async () => {
    setUploading(true)
    setMessage(null)

    try {
      const { error } = await supabase.rpc("update_hero_settings", {
        p_video_url: settings.video_url,
        p_fallback_image_url: settings.fallback_image_url,
        p_video_enabled: settings.video_enabled,
      })

      if (error) throw error

      setMessage({ type: "success", text: "Settings updated successfully!" })
    } catch (error) {
      console.error("Update error:", error)
      setMessage({ type: "error", text: `Update failed: ${error.message}` })
    } finally {
      setUploading(false)
    }
  }

  const getVideoUrl = () => {
    if (!settings.video_url) return null
    const { data } = supabase.storage.from("myleapstorage").getPublicUrl(settings.video_url)
    return data.publicUrl
  }

  return (
    <div className="max-w-2xl mx-auto p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Video className="h-5 w-5" />
            Hero Video Settings
          </CardTitle>
          <CardDescription>Upload and configure the hero section video with fallback image</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Video Upload */}
          <div className="space-y-4">
            <Label htmlFor="video-upload" className="text-base font-medium">
              Upload Video
            </Label>
            <div className="flex items-center gap-4">
              <Input id="video-upload" type="file" accept="video/*" onChange={handleVideoUpload} disabled={uploading} />
              {videoFile && (
                <Button onClick={uploadVideo} disabled={uploading}>
                  <Upload className="h-4 w-4 mr-2" />
                  {uploading ? "Uploading..." : "Upload"}
                </Button>
              )}
            </div>
            {videoFile && (
              <p className="text-sm text-muted-foreground">
                Selected: {videoFile.name} ({(videoFile.size / 1024 / 1024).toFixed(2)} MB)
              </p>
            )}
          </div>

          {/* Current Video Preview */}
          {settings.video_url && (
            <div className="space-y-2">
              <Label className="text-base font-medium">Current Video</Label>
              <div className="border rounded-lg p-4">
                <video
                  src={getVideoUrl()}
                  controls
                  className="w-full max-w-md mx-auto rounded"
                  style={{ maxHeight: "200px" }}
                >
                  Your browser does not support the video tag.
                </video>
                <p className="text-sm text-muted-foreground mt-2">File: {settings.video_url}</p>
              </div>
            </div>
          )}

          {/* Video Enabled Toggle */}
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="video-enabled" className="text-base font-medium">
                Enable Video
              </Label>
              <p className="text-sm text-muted-foreground">Show video instead of fallback image</p>
            </div>
            <Switch
              id="video-enabled"
              checked={settings.video_enabled}
              onCheckedChange={(checked) => setSettings({ ...settings, video_enabled: checked })}
            />
          </div>

          {/* Fallback Image URL */}
          <div className="space-y-2">
            <Label htmlFor="fallback-image" className="text-base font-medium">
              Fallback Image URL
            </Label>
            <Input
              id="fallback-image"
              type="url"
              value={settings.fallback_image_url}
              onChange={(e) => setSettings({ ...settings, fallback_image_url: e.target.value })}
              placeholder="https://example.com/image.jpg"
            />
            <p className="text-sm text-muted-foreground">Image shown when video is disabled or fails to load</p>
          </div>

          {/* Fallback Image Preview */}
          {settings.fallback_image_url && (
            <div className="space-y-2">
              <Label className="text-base font-medium">Fallback Image Preview</Label>
              <div className="border rounded-lg p-4">
                <img
                  src={settings.fallback_image_url || "/placeholder.svg"}
                  alt="Fallback preview"
                  className="w-24 h-24 object-contain mx-auto rounded"
                  onError={(e) => {
                    e.currentTarget.src = "/placeholder.svg?height=96&width=96&text=Error"
                  }}
                />
              </div>
            </div>
          )}

          {/* Update Button */}
          <Button onClick={updateSettings} disabled={uploading} className="w-full">
            {uploading ? "Updating..." : "Update Settings"}
          </Button>

          {/* Status Message */}
          {message && (
            <div
              className={`flex items-center gap-2 p-3 rounded-lg ${
                message.type === "success"
                  ? "bg-green-50 text-green-700 border border-green-200"
                  : "bg-red-50 text-red-700 border border-red-200"
              }`}
            >
              {message.type === "success" ? <CheckCircle className="h-4 w-4" /> : <AlertCircle className="h-4 w-4" />}
              {message.text}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
