"use client";

import { useRef, useState } from "react";
import { STRINGS, type Language } from "@/lib/strings";
import { diagnoseCrop, type Diagnosis } from "@/lib/diagnosis";

const URGENCY_STYLES: Record<string, string> = {
  low: "bg-green-100 text-green-800",
  medium: "bg-amber-100 text-amber-800",
  high: "bg-red-100 text-red-800",
};

export default function Home() {
  const [lang, setLang] = useState<Language>("en");
  const [description, setDescription] = useState("");
  const [photo, setPhoto] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<Diagnosis | null>(null);
  const resultRef = useRef<HTMLDivElement>(null);

  const t = STRINGS[lang];

  function handlePhotoChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    setPhoto(file);
    setPreviewUrl(file ? URL.createObjectURL(file) : null);
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
      const diagnosis = await diagnoseCrop(description.trim(), photo, lang);
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

  const urgencyClass = result ? URGENCY_STYLES[result.urgency] ?? URGENCY_STYLES.low : "";

  return (
    <div className="min-h-screen bg-[#f6f8f4] text-[#1b2318] pb-8">
      <header className="sticky top-0 z-10 bg-[#1e6b3c] text-white px-4 pt-4 pb-5">
        <h1 className="text-lg font-bold">🌱 Mazao Daktari</h1>
        <p className="text-sm opacity-90 mt-0.5">{t.tagline}</p>
        <div className="flex gap-2 mt-3">
          <button
            type="button"
            onClick={() => setLang("en")}
            className={`flex-1 rounded-lg border border-white/50 py-2 text-sm ${
              lang === "en" ? "bg-white text-[#14492a] font-semibold" : "text-white"
            }`}
          >
            English
          </button>
          <button
            type="button"
            onClick={() => setLang("sw")}
            className={`flex-1 rounded-lg border border-white/50 py-2 text-sm ${
              lang === "sw" ? "bg-white text-[#14492a] font-semibold" : "text-white"
            }`}
          >
            Kiswahili
          </button>
        </div>
      </header>

      <main className="max-w-[480px] mx-auto px-4">
        <div className="bg-white border border-[#dde5da] rounded-xl p-4 mt-4">
          <label htmlFor="description" className="block text-sm font-semibold mb-1.5">
            {t.labelDesc}
          </label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t.placeholder}
            className="w-full min-h-[4.5rem] p-2.5 rounded-lg border border-[#dde5da] text-[0.95rem] resize-y"
          />

          <label htmlFor="photo" className="block text-sm font-semibold mt-3 mb-1.5">
            {t.labelPhoto}
          </label>
          <input
            id="photo"
            type="file"
            accept="image/*"
            capture="environment"
            onChange={handlePhotoChange}
            className="block text-sm"
          />
          {previewUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={previewUrl}
              alt="Selected crop"
              className="mt-2.5 max-w-full rounded-lg"
            />
          )}

          <button
            type="button"
            onClick={handleSubmit}
            disabled={loading}
            className="w-full mt-3 py-3.5 rounded-xl bg-[#1e6b3c] text-white font-semibold disabled:opacity-60"
          >
            {loading ? t.submitting : t.submit}
          </button>
          <p className="text-xs text-[#5c6b5c] mt-1.5">{t.hint}</p>
          {error && <p className="text-sm text-[#b3261e] mt-1.5">{error}</p>}
        </div>

        {result && (
          <div ref={resultRef} className="bg-white border border-[#dde5da] rounded-xl p-4 mt-4">
            {result.mock && (
              <div className="bg-amber-50 text-amber-800 border border-amber-200 rounded-lg px-3 py-2 text-[0.78rem] mb-3">
                {t.mockNote}
              </div>
            )}

            <div className="flex items-center gap-2 mb-1">
              <span className={`px-2.5 py-1 rounded-full text-[0.72rem] font-semibold uppercase ${urgencyClass}`}>
                {result.urgency} · {result.confidence}
              </span>
              <strong>{result.crop}</strong>
            </div>
            <h2 className="text-lg font-semibold mb-1">{result.issue}</h2>

            <Section title={t.tSymptoms} items={result.symptoms} />
            <Section title={t.tTreatment} items={result.treatment} />
            <Section title={t.tPrevention} items={result.prevention} />
          </div>
        )}
      </main>
    </div>
  );
}

function Section({ title, items }: { title: string; items: string[] }) {
  return (
    <>
      <div className="text-xs font-bold uppercase text-[#5c6b5c] mt-3.5 mb-1">{title}</div>
      <ul className="list-disc pl-5 space-y-1">
        {items.map((item, i) => (
          <li key={i} className="text-[0.92rem]">
            {item}
          </li>
        ))}
      </ul>
    </>
  );
}
