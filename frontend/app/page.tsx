"use client";

import { useRef, useState } from "react";
import {
  Camera,
  Stethoscope,
  FlaskConical,
  ShieldCheck,
  AlertTriangle,
  Loader2,
  ImageUp,
  X,
} from "lucide-react";
import { STRINGS, type Language } from "@/lib/strings";
import { diagnoseCrop, type Diagnosis } from "@/lib/diagnosis";
import { useAuth } from "@/lib/auth-context";
import { Header } from "@/components/Header";
import { History } from "@/components/History";
import { DiagnosisSection } from "@/components/DiagnosisSection";

const URGENCY_STYLES: Record<string, string> = {
  low: "bg-low-bg text-low",
  medium: "bg-medium-bg text-medium",
  high: "bg-high-bg text-high",
};

export default function Home() {
  const { token } = useAuth();
  const [lang, setLang] = useState<Language>("en");
  const [description, setDescription] = useState("");
  const [photo, setPhoto] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<Diagnosis | null>(null);
  const resultRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const t = STRINGS[lang];

  function handlePhotoChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    setPhoto(file);
    setPreviewUrl(file ? URL.createObjectURL(file) : null);
  }

  function clearPhoto() {
    setPhoto(null);
    setPreviewUrl(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  async function handleSubmit() {
    if (!description.trim() && !photo) {
      setError(t.needInput);
      return;
    }

    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const diagnosis = await diagnoseCrop(description.trim(), photo, lang, token);
      setResult(diagnosis);
      requestAnimationFrame(() =>
        resultRef.current?.scrollIntoView({ behavior: "smooth", block: "start" }),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : t.failed);
    } finally {
      setLoading(false);
    }
  }

  const urgencyClass = result ? (URGENCY_STYLES[result.urgency] ?? URGENCY_STYLES.low) : "";

  return (
    <div className="min-h-dvh flex flex-col bg-bg">
      <Header lang={lang} onLangChange={setLang} />

      {/* Hero */}
      <section className="bg-gradient-to-br from-primary-dark to-primary text-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
          <h1 className="font-heading font-bold text-2xl sm:text-4xl leading-tight max-w-2xl">
            {t.heroTitle}
          </h1>
          <p className="mt-2 sm:mt-3 text-white/90 max-w-xl text-sm sm:text-base">{t.heroSubtitle}</p>

          <div className="mt-6 hidden sm:flex gap-8 text-sm">
            <Step icon={<Camera className="w-5 h-5" aria-hidden="true" />} label={t.stepPhoto} />
            <Step icon={<Stethoscope className="w-5 h-5" aria-hidden="true" />} label={t.stepDiagnose} />
            <Step icon={<FlaskConical className="w-5 h-5" aria-hidden="true" />} label={t.stepTreat} />
          </div>
        </div>
      </section>

      <main className="flex-1">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-6 sm:py-10 grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
          <section className="min-w-0">
            <div className="bg-card border border-border rounded-2xl shadow-sm p-4 sm:p-6">
              <label htmlFor="description" className="block text-sm font-semibold text-heading mb-1.5">
                {t.labelDesc}
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder={t.placeholder}
                className="w-full min-h-[5.5rem] p-3 rounded-xl border border-border text-[0.95rem] resize-y focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-shadow"
              />

              <span className="block text-sm font-semibold text-heading mt-4 mb-1.5">{t.labelPhoto}</span>

              {!previewUrl ? (
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full flex flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-border py-6 text-muted hover:border-primary hover:text-primary transition-colors duration-200 cursor-pointer"
                >
                  <ImageUp className="w-7 h-7" aria-hidden="true" />
                  <span className="text-sm font-medium">{t.uploadPrompt}</span>
                </button>
              ) : (
                <div className="relative inline-block">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={previewUrl}
                    alt="Selected crop"
                    className="max-w-full max-h-56 rounded-xl border border-border"
                  />
                  <button
                    type="button"
                    onClick={clearPhoto}
                    aria-label={t.removePhoto}
                    className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-heading text-white flex items-center justify-center shadow-sm cursor-pointer"
                  >
                    <X className="w-4 h-4" aria-hidden="true" />
                  </button>
                </div>
              )}
              {/* No `capture` attribute: on mobile browsers that forces the
                  camera to open directly, skipping the native picker's
                  gallery/files option entirely. Omitting it lets the OS
                  show its normal "Camera / Photo Library / Files" choice. */}
              <input
                ref={fileInputRef}
                id="photo"
                type="file"
                accept="image/*"
                onChange={handlePhotoChange}
                className="sr-only"
              />

              <button
                type="button"
                onClick={handleSubmit}
                disabled={loading}
                className="w-full mt-5 min-h-12 py-3.5 rounded-xl bg-primary text-white font-heading font-semibold flex items-center justify-center gap-2 hover:bg-primary-dark active:scale-[0.99] disabled:opacity-60 disabled:active:scale-100 transition-all duration-200 cursor-pointer"
              >
                {loading && <Loader2 className="w-5 h-5 animate-spin" aria-hidden="true" />}
                {loading ? t.submitting : t.submit}
              </button>
              <p className="text-xs text-muted mt-2">{t.hint}</p>
              {error && <p className="text-sm text-high mt-2 font-medium">{error}</p>}
            </div>

            {result && (
              <div
                ref={resultRef}
                className="bg-card border border-border rounded-2xl shadow-sm p-4 sm:p-6 mt-6 animate-[fadeIn_0.35s_ease-out]"
              >
                {result.mock && (
                  <div className="bg-medium-bg text-medium border border-medium/30 rounded-lg px-3 py-2 text-[0.78rem] mb-4">
                    {t.mockNote}
                  </div>
                )}

                <div className="flex items-center gap-2 mb-1 flex-wrap">
                  <span
                    className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[0.72rem] font-semibold uppercase ${urgencyClass}`}
                  >
                    <AlertTriangle className="w-3.5 h-3.5" aria-hidden="true" />
                    {result.urgency} · {result.confidence}
                  </span>
                  <strong className="text-body">{result.crop}</strong>
                </div>
                <h2 className="font-heading text-xl font-semibold text-heading mb-2">{result.issue}</h2>

                <DiagnosisSection title={t.tSymptoms} items={result.symptoms} icon={<Stethoscope className="w-4 h-4" aria-hidden="true" />} />
                <DiagnosisSection title={t.tTreatment} items={result.treatment} icon={<FlaskConical className="w-4 h-4" aria-hidden="true" />} />
                <DiagnosisSection title={t.tPrevention} items={result.prevention} icon={<ShieldCheck className="w-4 h-4" aria-hidden="true" />} />
              </div>
            )}

            <div className="lg:hidden mt-6">
              <History lang={lang} />
            </div>
          </section>

          <aside className="hidden lg:block">
            <div className="sticky top-20 space-y-4">
              <div className="bg-card border border-border rounded-2xl shadow-sm p-5">
                <h3 className="font-heading font-semibold text-heading text-sm mb-3">{t.howItWorks}</h3>
                <ol className="space-y-3">
                  <SidebarStep n={1} icon={<Camera className="w-4 h-4" aria-hidden="true" />} label={t.stepPhoto} />
                  <SidebarStep n={2} icon={<Stethoscope className="w-4 h-4" aria-hidden="true" />} label={t.stepDiagnose} />
                  <SidebarStep n={3} icon={<FlaskConical className="w-4 h-4" aria-hidden="true" />} label={t.stepTreat} />
                </ol>
              </div>

              <History lang={lang} variant="card" />
            </div>
          </aside>
        </div>
      </main>

      <footer className="border-t border-border py-4 text-center text-xs text-muted">
        {t.footer}
      </footer>
    </div>
  );
}

function Step({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-8 h-8 rounded-full bg-white/15 flex items-center justify-center">{icon}</span>
      <span>{label}</span>
    </div>
  );
}

function SidebarStep({ n, icon, label }: { n: number; icon: React.ReactNode; label: string }) {
  return (
    <li className="flex items-center gap-3 text-sm text-body">
      <span className="w-7 h-7 shrink-0 rounded-full bg-low-bg text-primary flex items-center justify-center font-semibold text-xs">
        {n}
      </span>
      <span className="flex items-center gap-1.5">
        {icon}
        {label}
      </span>
    </li>
  );
}
