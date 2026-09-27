"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";

export interface AuthUser {
  id: number;
  email: string;
  name: string | null;
  avatar_url: string | null;
}

interface AuthContextValue {
  user: AuthUser | null;
  token: string | null;
  loading: boolean;
  signIn: (credential: string) => Promise<void>;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";
const STORAGE_KEY = "mazao_daktari_token";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Restore a saved session on first load by re-validating the token
  // against the backend (a token could have been revoked/expired since).
  // Every setState call below runs inside a .then()/.catch()/.finally()
  // callback (a later microtask), never synchronously in the effect body
  // itself, per react-hooks/set-state-in-effect.
  useEffect(() => {
    Promise.resolve()
      .then(() => {
        try {
          return localStorage.getItem(STORAGE_KEY);
        } catch {
          // localStorage unavailable (private window, blocked storage) -
          // fall through to signed-out state rather than throwing.
          return null;
        }
      })
      .then((stored) => {
        if (!stored) {
          setLoading(false);
          return;
        }

        return fetch(`${API_BASE}/api/me`, { headers: { Authorization: `Bearer ${stored}` } })
          .then((res) => (res.ok ? res.json() : Promise.reject()))
          .then((data: { user: AuthUser }) => {
            setToken(stored);
            setUser(data.user);
          })
          .catch(() => {
            try {
              localStorage.removeItem(STORAGE_KEY);
            } catch {
              // ignore
            }
          })
          .finally(() => setLoading(false));
      });
  }, []);

  const signIn = useCallback(async (credential: string) => {
    const res = await fetch(`${API_BASE}/api/auth/google`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ credential }),
    });

    if (!res.ok) {
      throw new Error("Google sign-in failed.");
    }

    const data = (await res.json()) as { token: string; user: AuthUser };
    setToken(data.token);
    setUser(data.user);
    try {
      localStorage.setItem(STORAGE_KEY, data.token);
    } catch {
      // per-viewer convenience only - a failed write just means the
      // session won't survive a reload, not a functional break.
    }
  }, []);

  const signOut = useCallback(() => {
    setToken(null);
    setUser(null);
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
  }, []);

  return (
    <AuthContext.Provider value={{ user, token, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
