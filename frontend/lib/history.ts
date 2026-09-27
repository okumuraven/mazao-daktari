import type { Diagnosis } from "./diagnosis";

export interface HistoryEntry extends Diagnosis {
  id: number;
  description: string | null;
  inserted_at: string;
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";

export async function fetchHistory(token: string): Promise<HistoryEntry[]> {
  const res = await fetch(`${API_BASE}/api/diagnoses`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    throw new Error("Failed to load diagnosis history.");
  }

  const data = (await res.json()) as { diagnoses: HistoryEntry[] };
  return data.diagnoses;
}
