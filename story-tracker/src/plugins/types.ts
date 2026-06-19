import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';
import type { DomChapterResult, SiteProfile, SiteProfileExtension } from '../types/site-profile';

/**
 * Unified pipeline contract:
 * Core parser produces `base` ReadingInfo → optional site plugin enhances → sync/storage.
 * Input and output shape are always ReadingInfo.
 */
export type SitePluginInput = {
  ctx: ParserContext;
  profile: SiteProfile;
  extension: SiteProfileExtension;
  storyId: string;
  partId?: string;
  chapterMeta: DomChapterResult;
  base: ReadingInfo;
};

export type ResumeChapterPayload = {
  chapterNumber: string;
  chuongid?: string;
  tuaid?: string;
  /** Exact `noidung1('…')` argument saved from muluben onclick. */
  noidungArg?: string;
};

export interface SitePlugin {
  id: string;
  label: string;
  description: string;
  builtin: boolean;
  /** Transform generic core output into site-optimized ReadingInfo. */
  enhance(input: SitePluginInput): Promise<ReadingInfo>;
  /** Open/switch to the saved chapter (postback readers). */
  resumeChapter?(document: Document, payload: ResumeChapterPayload): Promise<boolean>;
}

export type SitePluginSummary = Pick<SitePlugin, 'id' | 'label' | 'description' | 'builtin'>;
