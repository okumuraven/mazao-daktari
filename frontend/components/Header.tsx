"use client";

import Link from "next/link";
import { Sprout } from "lucide-react";
import type { Language } from "@/lib/strings";
import { AuthBar } from "@/components/AuthBar";

export function Header({
  lang,
  onLangChange,
}: {
  lang: Language;
  onLangChange: (lang: Language) => void;
}) {
  return (
    <header className="sticky top-0 z-20 bg-card/95 backdrop-blur border-b border-border">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-3 flex items-center gap-3 flex-wrap">
        <Link
          href="/"
          className="flex items-center gap-2 font-heading font-semibold text-heading text-lg mr-auto"
        >
          <Sprout className="w-6 h-6 text-primary" aria-hidden="true" />
          Mazao Daktari
        </Link>

        <div className="flex rounded-full border border-border p-0.5 bg-bg text-sm">
          <button
            type="button"
            onClick={() => onLangChange("en")}
            className={`px-3 py-1.5 rounded-full font-medium transition-colors duration-200 cursor-pointer ${
              lang === "en" ? "bg-primary text-white" : "text-body hover:text-heading"
            }`}
          >
            EN
          </button>
          <button
            type="button"
            onClick={() => onLangChange("sw")}
            className={`px-3 py-1.5 rounded-full font-medium transition-colors duration-200 cursor-pointer ${
              lang === "sw" ? "bg-primary text-white" : "text-body hover:text-heading"
            }`}
          >
            SW
          </button>
        </div>

        <AuthBar lang={lang} />
      </div>
    </header>
  );
}
