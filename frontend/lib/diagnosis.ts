import type { Language } from "./strings";

export type Urgency = "low" | "medium" | "high";
export type Confidence = "low" | "medium" | "high";

export interface Diagnosis {
  mock: boolean;
  crop: string;
  issue: string;
  confidence: Confidence;
  symptoms: string[];
  treatment: string[];
  prevention: string[];
  urgency: Urgency;
  language: Language;
  note?: string;
}

interface DiagnoseError {
  error: string;
  detail?: unknown;
  raw?: string;
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";

export async function diagnoseCrop(
  description: string,
  photo: File | null,
  language: Language,
): Promise<Diagnosis> {
  const form = new FormData();
  form.append("description", description);
  form.append("language", language);
  if (photo) form.append("image", photo);

  const res = await fetch(`${API_BASE}/api/diagnose`, {
    method: "POST",
    body: form,
  });

  const data = (await res.json()) as Diagnosis | DiagnoseError;

  if (!res.ok || "error" in data) {
    const message = "error" in data ? data.error : "Diagnosis failed.";
    throw new Error(message);
  }

  return data;
}
