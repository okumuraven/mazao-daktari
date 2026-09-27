"use client";

import { useEffect, useState } from "react";
import { Clock } from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { fetchHistory, type HistoryEntry } from "@/lib/history";
import { STRINGS, type Language } from "@/lib/strings";

interface HistoryProps {
  lang: Language;
  /** "inline" (default): collapsed behind a toggle, for the mobile stack.
   *  "card": always-expanded sidebar card, for the desktop rail. */
  variant?: "inline" | "card";
}

export function History({ lang, variant = "inline" }: HistoryProps) {
  const { user, token } = useAuth();
  const t = STRINGS[lang];
  const isCard = variant === "card";
  const [open, setOpen] = useState(isCard);
  const [entries, setEntries] = useState<HistoryEntry[] | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!open || !token || entries) return;

    Promise.resolve().then(() => {
      setLoading(true);
      fetchHistory(token)
        .then(setEntries)
        .catch(() => setEntries([]))
        .finally(() => setLoading(false));
    });
  }, [open, token, entries]);

  if (!user) return null;

  const list = (
    <div className={isCard ? "mt-3 space-y-2" : "mt-2 space-y-2"}>
      {loading && <p className="text-sm text-muted">{t.loadingHistory}</p>}
      {!loading && entries?.length === 0 && <p className="text-sm text-muted">{t.noHistory}</p>}
      {entries?.map((entry) => (
        <div key={entry.id} className="bg-bg border border-border rounded-lg p-3">
          <div className="flex items-center justify-between gap-2">
            <strong className="text-sm text-heading">
              {entry.crop} — {entry.issue}
            </strong>
          </div>
          <span className="text-xs text-muted whitespace-nowrap">
            {new Date(entry.inserted_at).toLocaleDateString()}
          </span>
          {entry.description && <p className="text-xs text-muted mt-1">{entry.description}</p>}
        </div>
      ))}
    </div>
  );

  if (isCard) {
    return (
      <div className="bg-card border border-border rounded-2xl shadow-sm p-5">
        <h3 className="font-heading font-semibold text-heading text-sm flex items-center gap-1.5">
          <Clock className="w-4 h-4" aria-hidden="true" />
          {t.history}
        </h3>
        {list}
      </div>
    );
  }

  return (
    <div className="bg-card border border-border rounded-2xl shadow-sm p-4">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="text-sm font-semibold text-primary flex items-center gap-1.5 cursor-pointer"
      >
        <Clock className="w-4 h-4" aria-hidden="true" />
        {open ? t.hideHistory : t.history}
      </button>
      {open && list}
    </div>
  );
}
