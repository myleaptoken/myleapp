"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Search, Send, AlertCircle, CheckCircle2 } from "lucide-react"
import { supabase } from "@/lib/supabase"
import { useAuth } from "@/hooks/use-auth"

interface User {
  id: string
  email: string
  full_name: string | null
  user_id: string | null
}

interface SendTokensModalProps {
  isOpen: boolean
  onClose: () => void
  currentBalance: number
  onTransferComplete: () => void
}

export function SendTokensModal({ isOpen, onClose, currentBalance, onTransferComplete }: SendTokensModalProps) {
  const { user } = useAuth()
  const [searchQuery, setSearchQuery] = useState("")
  const [searchResults, setSearchResults] = useState<User[]>([])
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")
  const [isSearching, setIsSearching] = useState(false)
  const [isTransferring, setIsTransferring] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")
  const [debugInfo, setDebugInfo] = useState<any>(null)

  const searchUsers = async (query: string) => {
    if (!query.trim()) {
      setSearchResults([])
      return
    }

    setIsSearching(true)
    setError("")

    try {
      const { data, error } = await supabase
        .from("users")
        .select("id, email, full_name, user_id")
        .or(`email.ilike.%${query}%,full_name.ilike.%${query}%,user_id.ilike.%${query}%`)
        .neq("id", user?.id) // Exclude current user
        .limit(10)

      if (error) throw error

      setSearchResults(data || [])
    } catch (err) {
      console.error("Search error:", err)
      setError("Error searching users")
    } finally {
      setIsSearching(false)
    }
  }

  const handleSearch = (query: string) => {
    setSearchQuery(query)
    searchUsers(query)
  }

  const selectUser = (selectedUser: User) => {
    setSelectedUser(selectedUser)
    setSearchQuery("")
    setSearchResults([])
  }

  const handleTransfer = async () => {
    if (!selectedUser || !amount || !user) {
      setError("Please fill in all required fields")
      return
    }

    const transferAmount = Number.parseFloat(amount)
    if (isNaN(transferAmount) || transferAmount <= 0) {
      setError("Please enter a valid amount")
      return
    }

    // Siempre enviamos el monto en formato LEAP a la función SQL
    // La función se encargará de detectar y convertir según sea necesario

    console.log("Transfer validation:", {
      transferAmount,
      currentBalance,
      isValid: true, // Dejamos que la función SQL valide
    })

    setIsTransferring(true)
    setError("")
    setSuccess("")
    setDebugInfo(null)

    try {
      const { data, error } = await supabase.rpc("transfer_tokens_atomic", {
        sender_id: user.id,
        receiver_id: selectedUser.id,
        amount_tokens: transferAmount,
        description_text: description || "Token transfer",
      })

      if (error) {
        console.error("Supabase RPC error:", error)
        throw error
      }

      console.log("Transfer response:", data)

      const result = typeof data === "string" ? JSON.parse(data) : data

      if (result.success) {
        setSuccess(
          `Successfully sent ${transferAmount} LEAP tokens to ${selectedUser.email || selectedUser.full_name || "user"}`,
        )
        onTransferComplete()

        // Reset form
        setTimeout(() => {
          setSelectedUser(null)
          setAmount("")
          setDescription("")
          setSuccess("")
          onClose()
        }, 2000)
      } else {
        console.error("Transfer failed:", result)
        setDebugInfo(result)
        throw new Error(result.error || "Transfer failed")
      }
    } catch (err: any) {
      console.error("Transfer error:", err)
      setError(err.message || "Transfer failed")
    } finally {
      setIsTransferring(false)
    }
  }

  const resetModal = () => {
    setSelectedUser(null)
    setAmount("")
    setDescription("")
    setSearchQuery("")
    setSearchResults([])
    setError("")
    setSuccess("")
    setDebugInfo(null)
  }

  const handleClose = () => {
    resetModal()
    onClose()
  }

  // Siempre mostramos el balance como LEAP
  // Si es mayor a 10 millones, asumimos que está en formato atómico y lo convertimos
  const displayBalance = currentBalance > 10000000 ? currentBalance / 1000000000 : currentBalance

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Send className="h-5 w-5" />
            Send LEAP Tokens
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* Balance Display */}
          <div className="bg-blue-50 dark:bg-blue-950 p-3 rounded-lg">
            <p className="text-sm text-blue-600 dark:text-blue-400">Available Balance</p>
            <p className="text-lg font-semibold text-blue-700 dark:text-blue-300">
              {displayBalance.toLocaleString()} LEAP
            </p>
            <p className="text-xs text-blue-500 dark:text-blue-400">
              Raw balance: {currentBalance.toLocaleString()}
              {currentBalance > 10000000 ? " (atomic)" : " (LEAP)"}
            </p>
          </div>

          {/* Error/Success Messages */}
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {success && (
            <Alert className="border-green-200 bg-green-50 text-green-800">
              <CheckCircle2 className="h-4 w-4" />
              <AlertDescription>{success}</AlertDescription>
            </Alert>
          )}

          {/* Debug Info */}
          {debugInfo && (
            <div className="bg-gray-50 dark:bg-gray-800 p-3 rounded-lg text-xs overflow-auto max-h-32">
              <p className="font-medium mb-1">Debug Info:</p>
              <pre>{JSON.stringify(debugInfo, null, 2)}</pre>
            </div>
          )}

          {/* User Selection */}
          {!selectedUser ? (
            <div className="space-y-2">
              <Label htmlFor="search">Search Recipients</Label>
              <div className="relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                <Input
                  id="search"
                  placeholder="Search by email, name, or user ID..."
                  value={searchQuery}
                  onChange={(e) => handleSearch(e.target.value)}
                  className="pl-10"
                />
              </div>

              {/* Search Results */}
              {searchResults.length > 0 && (
                <div className="border rounded-lg max-h-40 overflow-y-auto">
                  {searchResults.map((user) => (
                    <button
                      key={user.id}
                      onClick={() => selectUser(user)}
                      className="w-full p-3 text-left hover:bg-gray-50 dark:hover:bg-gray-800 border-b last:border-b-0"
                    >
                      <div className="font-medium">{user.full_name || "No name"}</div>
                      <div className="text-sm text-gray-500">{user.email}</div>
                      {user.user_id && <div className="text-xs text-gray-400">{user.user_id}</div>}
                    </button>
                  ))}
                </div>
              )}

              {isSearching && <p className="text-sm text-gray-500">Searching...</p>}
            </div>
          ) : (
            <div className="bg-gray-50 dark:bg-gray-800 p-3 rounded-lg">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">{selectedUser.full_name || "No name"}</p>
                  <p className="text-sm text-gray-500">{selectedUser.email}</p>
                  {selectedUser.user_id && <p className="text-xs text-gray-400">{selectedUser.user_id}</p>}
                </div>
                <Button variant="outline" size="sm" onClick={() => setSelectedUser(null)}>
                  Change
                </Button>
              </div>
            </div>
          )}

          {/* Amount Input */}
          <div className="space-y-2">
            <Label htmlFor="amount">Amount (LEAP)</Label>
            <Input
              id="amount"
              type="number"
              placeholder="Enter amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              min="0"
              step="0.000000001"
              max={displayBalance}
            />
            <p className="text-xs text-gray-500">Maximum: {displayBalance.toLocaleString()} LEAP</p>
          </div>

          {/* Description Input */}
          <div className="space-y-2">
            <Label htmlFor="description">Description (Optional)</Label>
            <Textarea
              id="description"
              placeholder="What's this for?"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
            />
          </div>

          {/* Action Buttons */}
          <div className="flex gap-2 pt-4">
            <Button variant="outline" onClick={handleClose} className="flex-1 bg-transparent" disabled={isTransferring}>
              Cancel
            </Button>
            <Button onClick={handleTransfer} disabled={!selectedUser || !amount || isTransferring} className="flex-1">
              {isTransferring ? "Sending..." : "Send Tokens"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
