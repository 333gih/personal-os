export type PageKind = 'chapter' | 'story_home' | 'listing' | 'other';

export type PageClassification = {
  kind: PageKind;
  storySlug?: string;
  chapterId?: string;
  chapterTitle?: string;
};

const CHAPTER_SEGMENT = /^(?:chuong|chương|chapter|chap|tap|tập|ep|episode)-?(\d+(?:\.\d+)?)$/i;

const EXCLUDE_PATH = [
  /^\/$/,
  /^\/danh-sach(?:\/|$)/i,
  /^\/the-loai(?:\/|$)/i,
  /^\/category(?:\/|$)/i,
  /^\/search(?:\/|$)/i,
  /^\/login(?:\/|$)/i,
  /^\/account(?:\/|$)/i,
  /^\/truyen-tranh(?:\/|$)/i,
];

export function classifyReadingPage(url: string): PageClassification {
  try {
    const parsed = new URL(url);
    const parts = parsed.pathname.split('/').filter(Boolean);

    if (parts.length === 0) {
      return { kind: 'listing' };
    }

    for (const rule of EXCLUDE_PATH) {
      if (rule.test(parsed.pathname)) {
        return { kind: 'listing' };
      }
    }

    if (parts.length === 1) {
      const chapterInOne = parts[0].match(CHAPTER_SEGMENT);
      if (chapterInOne) {
        return {
          kind: 'chapter',
          chapterId: chapterInOne[1],
          chapterTitle: `Chương ${chapterInOne[1]}`,
        };
      }
      return { kind: 'story_home', storySlug: parts[0] };
    }

    const last = parts[parts.length - 1];
    const chapterMatch = last.match(CHAPTER_SEGMENT);
    if (chapterMatch) {
      const storySlug = parts.length >= 2 ? parts[parts.length - 2] : parts[0];
      return {
        kind: 'chapter',
        storySlug,
        chapterId: chapterMatch[1],
        chapterTitle: `Chương ${chapterMatch[1]}`,
      };
    }

    if (/^truyen-tranh$/i.test(parts[0]) && parts.length >= 3) {
      const mangaChapter = parts[parts.length - 1].match(/^chuong-(\d+)/i);
      if (mangaChapter) {
        return {
          kind: 'chapter',
          storySlug: parts[1],
          chapterId: mangaChapter[1],
          chapterTitle: `Chapter ${mangaChapter[1]}`,
        };
      }
      if (parts.length === 2) {
        return { kind: 'story_home', storySlug: parts[1] };
      }
    }

    if (parts.length === 2) {
      return { kind: 'story_home', storySlug: parts[0] };
    }

    return { kind: 'other' };
  } catch {
    return { kind: 'other' };
  }
}

export function isChapterPage(url: string): boolean {
  return classifyReadingPage(url).kind === 'chapter';
}
