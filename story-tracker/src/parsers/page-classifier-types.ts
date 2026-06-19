export type PageKind = 'chapter' | 'story_home' | 'listing' | 'other';

export type PageClassification = {
  kind: PageKind;
  storySlug?: string;
  chapterId?: string;
  chapterTitle?: string;
  profileId?: string;
};
