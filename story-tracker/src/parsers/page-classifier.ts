import type { PageClassification, PageKind } from './page-classifier-types';
import type { SiteProfile } from '../types/site-profile';
import { getBuiltinProfiles, matchProfile, profileMatchesUrl } from '../config/site-profile-builtin';
import {
  extractQueryStoryId,
  extractUrlHashId,
  formatHashChapterTitle,
  hasReadingUrlSignals,
  isLikelyListingPage,
} from './url-detector';

export type { PageClassification, PageKind } from './page-classifier-types';

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

export function classifyReadingPage(
  url: string,
  profiles: SiteProfile[] = getBuiltinProfiles(),
): PageClassification {
  try {
    const parsed = new URL(url);

    const profile = matchProfile(url, profiles);
    if (profile) {
      const fromProfile = classifyWithProfile(parsed, profile);
      if (fromProfile) return fromProfile;
    }

    const generic = classifyGenericPath(parsed);
    if (generic) return generic;

    if (hasReadingUrlSignals(url) && !isLikelyListingPage(url)) {
      return {
        kind: 'chapter',
        storySlug: parsed.hostname,
        chapterId: extractUrlHashId(url) ?? 'auto',
      };
    }

    return { kind: 'other' };
  } catch {
    return { kind: 'other' };
  }
}

export function isChapterPage(
  url: string,
  profiles: SiteProfile[] = getBuiltinProfiles(),
): boolean {
  return classifyReadingPage(url, profiles).kind === 'chapter';
}

function classifyWithProfile(parsed: URL, profile: SiteProfile): PageClassification | null {
  const url = parsed.href;

  if (profile.urlRules.pathRegex && profile.urlRules.queryParams?.story) {
    const tid = extractQueryStoryId(url, profile.urlRules.queryParams.story);
    if (tid && new RegExp(profile.urlRules.pathRegex, 'i').test(parsed.pathname)) {
      const hash = extractUrlHashId(url);
      return {
        kind: 'chapter',
        storySlug: tid,
        chapterId: hash ?? 'reader',
        chapterTitle: hash ? formatHashChapterTitle(hash) : undefined,
        profileId: profile.id,
      };
    }
  }

  const fromPath = classifyGenericPath(parsed);
  if (fromPath?.kind === 'chapter') {
    return { ...fromPath, profileId: profile.id };
  }

  if (profile.id === 'generic-vi-reading' || profileMatchesUrl(url, profile)) {
    if (hasReadingUrlSignals(url)) {
      const hash = extractUrlHashId(url);
      const tid = profile.urlRules.queryParams?.story
        ? extractQueryStoryId(url, profile.urlRules.queryParams.story)
        : undefined;
      return {
        kind: 'chapter',
        storySlug: tid ?? parsed.hostname,
        chapterId: hash ?? tid ?? 'auto',
        chapterTitle: hash ? formatHashChapterTitle(hash) : undefined,
        profileId: profile.id,
      };
    }
  }

  return null;
}

function classifyGenericPath(parsed: URL): PageClassification | null {
  const parts = parsed.pathname.split('/').filter(Boolean);

  if (parts.length === 0) return { kind: 'listing' };

  for (const rule of EXCLUDE_PATH) {
    if (rule.test(parsed.pathname)) return { kind: 'listing' };
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
    if (parts.length === 2) return { kind: 'story_home', storySlug: parts[1] };
  }

  if (parts.length === 2) return { kind: 'story_home', storySlug: parts[0] };

  return null;
}
