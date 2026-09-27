"use client";

import Link from "next/link";
import { GoogleLogin, type CredentialResponse } from "@react-oauth/google";
import { LogOut } from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { STRINGS, type Language } from "@/lib/strings";

export function AuthBar({ lang }: { lang: Language }) {
  const { user, signIn, signOut, loading } = useAuth();
  const t = STRINGS[lang];

  if (loading) return <div className="w-24 h-9" aria-hidden="true" />;

  if (user) {
    return (
      <div className="flex items-center gap-2">
        <Link
          href="/profile"
          className="flex items-center gap-2 rounded-full hover:opacity-80 transition-opacity duration-200"
          title={t.profile}
        >
          {user.avatar_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={user.avatar_url}
              alt=""
              className="w-8 h-8 rounded-full border border-border"
            />
          ) : (
            <div className="w-8 h-8 rounded-full bg-low-bg text-primary flex items-center justify-center text-xs font-semibold">
              {(user.name ?? user.email).charAt(0).toUpperCase()}
            </div>
          )}
          <span className="hidden sm:inline text-sm text-body truncate max-w-32">
            {user.name ?? user.email}
          </span>
        </Link>
        <button
          type="button"
          onClick={signOut}
          aria-label={t.signOut}
          title={t.signOut}
          className="w-8 h-8 rounded-full flex items-center justify-center text-muted hover:text-high hover:bg-high-bg transition-colors duration-200 cursor-pointer"
        >
          <LogOut className="w-4 h-4" aria-hidden="true" />
        </button>
      </div>
    );
  }

  function handleSuccess(response: CredentialResponse) {
    if (!response.credential) return;
    signIn(response.credential).catch(() => {
      // signIn failures surface via the button staying in signed-out state;
      // no separate error UI here to keep this component simple.
    });
  }

  return (
    <div className="[&_iframe]:!rounded-full">
      <GoogleLogin onSuccess={handleSuccess} onError={() => {}} size="medium" shape="pill" text="signin" />
    </div>
  );
}
