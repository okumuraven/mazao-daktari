export type Language = "en" | "sw";

export const STRINGS: Record<Language, Record<string, string>> = {
  en: {
    tagline: "Snap a photo, get advice.",
    labelDesc: "Describe the problem (optional)",
    labelPhoto: "Add a photo of the crop",
    placeholder: "e.g. Yellow spots on maize leaves, started this week",
    hint: "Works with just a description if you can't take a photo. Data used only for this diagnosis.",
    submit: "Diagnose",
    submitting: "Diagnosing...",
    tSymptoms: "Symptoms matched",
    tTreatment: "Treatment",
    tPrevention: "Prevention",
    needInput: "Provide a photo, a description, or both.",
    failed: "Something went wrong. Try again.",
    mockNote:
      "Demo mode: this is a sample diagnosis, not a live AI call. Set GEMINI_API_KEY on the server for real results.",
  },
  sw: {
    tagline: "Piga picha, pata ushauri.",
    labelDesc: "Eleza tatizo (si lazima)",
    labelPhoto: "Ongeza picha ya zao",
    placeholder: "mfano: Madoa ya njano kwenye majani ya mahindi, yalianza wiki hii",
    hint: "Inafanya kazi kwa maelezo tu ukikosa picha. Data hutumika kwa uchunguzi huu tu.",
    submit: "Chunguza",
    submitting: "Inachunguza...",
    tSymptoms: "Dalili zinazofanana",
    tTreatment: "Tiba",
    tPrevention: "Kinga",
    needInput: "Weka picha, maelezo, au vyote viwili.",
    failed: "Hitilafu imetokea. Jaribu tena.",
    mockNote:
      "Hali ya majaribio: hii ni mfano wa uchunguzi, si wito wa moja kwa moja wa AI. Weka GEMINI_API_KEY kwenye seva kwa matokeo halisi.",
  },
};
