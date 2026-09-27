"use client";

import { useEffect, useState } from "react";
import {
  Calendar,
  ClipboardList,
  ChevronDown,
  Stethoscope,
  FlaskConical,
  ShieldCheck,
  AlertTriangle,
} from "lucide-react";
import { STRINGS, type Language } from "@/lib/strings";
import { useAuth } from "@/lib/auth-context";
import { fetchHistory, type HistoryEntry } from "@/lib/history";
import { Header } from "@/components/Header";
import { AuthBar } from "@/components/AuthBar";
import { DiagnosisSection } from "@/components/DiagnosisSection";

const URGENCY_STYLES: Record<string, string> = {
  low: "bg-low-bg text-low",
  medium: "bg-medium-bg text-medium",
  high: "bg-high-bg text-high",
};

export default function ProfilePage() {
  const { user, token, loading: authLoading } = useAuth();
  const [lang, setLang] = useState<Language>("en");
  const [entries, setEntries] = useState<HistoryEntry[] | null>(null);
  const [loadingHistory, setLoadingHistory] = useState(false);
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const t = STRINGS[lang];

  useEffect(() => {
    if (!token) return;

    Promise.resolve().then(() => {
      setLoadingHistory(true);
      fetchHistory(token)
        .then(setEntries)
        .catch(() => setEntries([]))
        .finally(() => setLoadingHistory(false));
    });
  }, [token]);

  return (
    <div className="min-h-dvh flex flex-col bg-bg">
      <Header lang={lang} onLangChange={setLang} />

      <main className="flex-1">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-6 sm:py-10">
          {authLoading ? null : !user ? (
            <div className="bg-card border border-border rounded-2xl shadow-sm p-6 text-center">
              <p className="text-body mb-4">{t.signInToView}</p>
              <div className="flex justify-center">
                <AuthBar lang={lang} />
              </div>
            </div>
          ) : (
            <>
              <div className="bg-card border border-border rounded-2xl shadow-sm p-5 sm:p-6 flex items-center gap-4">
                {user.avatar_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={user.avatar_url}
                    alt=""
                    className="w-16 h-16 rounded-full border border-border"
                  />
                ) : (
                  <div className="w-16 h-16 rounded-full bg-low-bg text-primary flex items-center justify-center text-xl font-semibold">
                    {(user.name ?? user.email).charAt(0).toUpperCase()}
                  </div>
                )}
                <div className="min-w-0">
                  <h1 className="font-heading text-xl font-semibold text-heading truncate">
                    {user.name ?? user.email}
                  </h1>
                  <p className="text-sm text-muted truncate">{user.email}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 mt-4">
                <StatCard
                  icon={<Calendar className="w-4 h-4" aria-hidden="true" />}
                  label={t.joinedLabel}
                  value={new Date(user.joined_at).toLocaleDateString(lang === "sw" ? "sw-KE" : "en-KE", {
                    year: "numeric",
                    month: "short",
                    day: "numeric",
                  })}
                />
                <StatCard
                  icon={<ClipboardList className="w-4 h-4" aria-hidden="true" />}
                  label={t.totalDiagnoses}
                  value={entries ? String(entries.length) : "—"}
                />
              </div>

              <h2 className="font-heading font-semibold text-heading text-sm mt-8 mb-3">
                {t.allHistory}
              </h2>

              {loadingHistory && <p className="text-sm text-muted">{t.loadingHistory}</p>}
              {!loadingHistory && entries?.length === 0 && (
                <p className="text-sm text-muted">{t.noHistory}</p>
              )}

              <div className="space-y-3">
                {entries?.map((entry) => {
                  const open = expandedId === entry.id;
                  const urgencyClass = URGENCY_STYLES[entry.urgency] ?? URGENCY_STYLES.low;

                  return (
                    <div
                      key={entry.id}
                      className="bg-card border border-border rounded-2xl shadow-sm overflow-hidden"
                    >
                      <button
                        type="button"
                        onClick={() => setExpandedId(open ? null : entry.id)}
                        className="w-full flex items-center gap-3 p-4 text-left cursor-pointer"
                      >
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[0.7rem] font-semibold uppercase shrink-0 ${urgencyClass}`}
                        >
                          <AlertTriangle className="w-3.5 h-3.5" aria-hidden="true" />
                          {entry.urgency}
                        </span>
                        <div className="min-w-0 flex-1">
                          <p className="font-heading font-semibold text-heading truncate">
                            {entry.crop} — {entry.issue}
                          </p>
                          <p className="text-xs text-muted">
                            {new Date(entry.inserted_at).toLocaleDateString()}
                          </p>
                        </div>
                        <ChevronDown
                          className={`w-4 h-4 text-muted shrink-0 transition-transform duration-200 ${open ? "rotate-180" : ""}`}
                          aria-hidden="true"
                        />
                      </button>

                      {open && (
                        <div className="px-4 pb-4">
                          {entry.description && (
                            <p className="text-sm text-muted mb-2">{entry.description}</p>
                          )}
                          <DiagnosisSection
                            title={t.tSymptoms}
                            items={entry.symptoms}
                            icon={<Stethoscope className="w-4 h-4" aria-hidden="true" />}
                          />
                          <DiagnosisSection
                            title={t.tTreatment}
                            items={entry.treatment}
                            icon={<FlaskConical className="w-4 h-4" aria-hidden="true" />}
                          />
                          <DiagnosisSection
                            title={t.tPrevention}
                            items={entry.prevention}
                            icon={<ShieldCheck className="w-4 h-4" aria-hidden="true" />}
                          />
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </>
          )}
        </div>
      </main>

      <footer className="border-t border-border py-4 text-center text-xs text-muted">
        {t.footer}
      </footer>
    </div>
  );
}

function StatCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="bg-card border border-border rounded-2xl shadow-sm p-4">
      <div className="flex items-center gap-1.5 text-xs text-muted mb-1">
        {icon}
        {label}
      </div>
      <p className="font-heading font-semibold text-heading text-lg">{value}</p>
    </div>
  );
}
