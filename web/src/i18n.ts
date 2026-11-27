/** Every word on the site, in each language. Components take one `Copy` and never hold text of their own. */
export const locales = ["ja", "en"] as const;
export type Locale = (typeof locales)[number];

export type Copy = {
  lang: Locale;
  title: string;
  description: string;
  headline: [string, string];
  lead: [string, string];
  download: string;
  showcaseLabel: string;
  finder: { title: string; recents: string; downloads: string; documents: string; desktop: string };
  releaseToOpen: string;
  zeroLines: string;
  copy: string;
  keys: { open: string; paste: string; copyAll: string };
  footerNote: string;
  /** The header toggle's accessible name; aria-pressed says whether dark is on. */
  darkMode: string;
  /** Describes /og.png, the social preview image, which is the same for every language. */
  ogImageAlt: string;
  /** The Open Graph locale, e.g. ja_JP. */
  ogLocale: string;
  /** The link to the other language, written in that language. */
  otherLanguage: string;
};

export const copy: Record<Locale, Copy> = {
  ja: {
    lang: "ja",
    title: "Wavi — エディタを立ち上げるほどでもない時に。",
    description: "落としたファイルも、貼ったログも。開いた瞬間に、サイズと中身がわかる。macOS のテキストビューア。",
    headline: ["エディタを立ち上げる", "ほどでもない時に。"],
    lead: ["落としたファイルも、貼ったログも。", "開いた瞬間に、サイズと中身がわかる。"],
    download: "無料でダウンロード",
    showcaseLabel:
      "Finder のダウンロードフォルダから webhook-event.json をドラッグし、Wavi のウィンドウに重ねている場面。Wavi のウィンドウ全体が薄い青になり、タブの位置に開く予定のファイル名とサイズ、1行目に「離すと開きます」とだけ表示されている",
    finder: { title: "ダウンロード", recents: "最近の項目", downloads: "ダウンロード", documents: "書類", desktop: "デスクトップ" },
    releaseToOpen: "離すと開きます",
    zeroLines: "0 行",
    copy: "コピー",
    keys: { open: "開く", paste: "貼り付け", copyAll: "全部コピー" },
    footerNote: "Wavi — ワビとも、ウェイビーとも。",
    darkMode: "ダークモード",
    ogImageAlt: "Wavi のアイコンと、Wavi の文字",
    ogLocale: "ja_JP",
    otherLanguage: "English",
  },
  en: {
    lang: "en",
    title: "Wavi — for when an editor is too much.",
    description: "A downloaded file, a pasted log. See its size and contents the moment it opens. A text viewer for macOS.",
    headline: ["For when an editor", "is too much."],
    lead: ["A downloaded file, a pasted log.", "See its size and contents the moment it opens."],
    download: "Download for free",
    showcaseLabel:
      "webhook-event.json is dragged from the Downloads folder in Finder onto the Wavi window. The whole window turns light blue, the tab shows the file's name and size, and the first line says only “Release to open”",
    finder: { title: "Downloads", recents: "Recents", downloads: "Downloads", documents: "Documents", desktop: "Desktop" },
    releaseToOpen: "Release to open",
    zeroLines: "0 lines",
    copy: "Copy",
    keys: { open: "Open", paste: "Paste", copyAll: "Copy all" },
    footerNote: "Wavi — say “wabi” or “wavy”.",
    darkMode: "Dark mode",
    ogImageAlt: "The Wavi icon and the word Wavi",
    ogLocale: "en_US",
    otherLanguage: "日本語",
  },
};
