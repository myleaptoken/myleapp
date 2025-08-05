"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { QrCode, Copy, CheckCircle2 } from "lucide-react"
import { useAuth } from "@/hooks/use-auth"

interface ReceiveTokensModalProps {
  isOpen: boolean
  onClose: () => void
}

export function ReceiveTokensModal({ isOpen, onClose }: ReceiveTokensModalProps) {
  const { user } = useAuth()
  const [copied, setCopied] = useState(false)

  const handleCopyUserId = async () => {
    if (user?.id) {
      try {
        await navigator.clipboard.writeText(user.id)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
      } catch (err) {
        console.error("Failed to copy:", err)
      }
    }
  }

  const handleCopyEmail = async () => {
    if (user?.email) {
      try {
        await navigator.clipboard.writeText(user.email)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
      } catch (err) {
        console.error("Failed to copy:", err)
      }
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <QrCode className="h-5 w-5" />
            Receive LEAP Tokens
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {/* QR Code Placeholder */}
          <div className="flex justify-center">
            <div className="w-48 h-48 bg-gray-100 dark:bg-gray-800 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300 dark:border-gray-600">
              <div className="text-center">
                <QrCode className="h-12 w-12 text-gray-400 mx-auto mb-2" />
                <p className="text-sm text-gray-500">QR Code</p>
                <p className="text-xs text-gray-400">Coming Soon</p>
              </div>
            </div>
          </div>

          {/* User Information */}
          <div className="space-y-4">
            <div>
              <Label className="text-sm font-medium text-gray-700 dark:text-gray-300">Your Email</Label>
              <div className="flex items-center gap-2 mt-1">
                <Input value={user?.email || ""} readOnly className="flex-1" />
                <Button size="sm" variant="outline" onClick={handleCopyEmail}>
                  {copied ? <CheckCircle2 className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                </Button>
              </div>
            </div>

            <div>
              <Label className="text-sm font-medium text-gray-700 dark:text-gray-300">Your User ID</Label>
              <div className="flex items-center gap-2 mt-1">
                <Input value={user?.id || ""} readOnly className="flex-1 font-mono text-sm" />
                <Button size="sm" variant="outline" onClick={handleCopyUserId}>
                  {copied ? <CheckCircle2 className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                </Button>
              </div>
            </div>
          </div>

          {/* Instructions */}
          <div className="p-4 bg-blue-50 dark:bg-blue-950 rounded-lg">
            <h4 className="font-medium text-blue-900 dark:text-blue-100 mb-2">How to receive tokens:</h4>
            <ul className="text-sm text-blue-700 dark:text-blue-300 space-y-1">
              <li>• Share your email or User ID with the sender</li>
              <li>• They can search for you in their Send Tokens modal</li>
              <li>• Tokens will appear in your balance instantly</li>
            </ul>
          </div>

          {/* Close Button */}
          <Button onClick={onClose} className="w-full">
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
