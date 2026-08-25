export interface NewsItem {
  /** Slug da notícia no site oficial — único, serve como id. */
  id: string;
  title: string;
  category: string;
  /** ISO `YYYY-MM-DD`, ou string vazia se a data não pôde ser lida. */
  publishedAt: string;
  imageUrl: string;
  url: string;
}

export type NewsContentBlock =
  | { type: 'paragraph'; text: string }
  | { type: 'link'; text: string; url: string };

export interface NewsArticle extends NewsItem {
  content: NewsContentBlock[];
}

export type NewsArticleResult =
  | { available: true; article: NewsArticle }
  | { available: false; url: string };
