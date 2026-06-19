import type { ParserContext, StoryParser } from '../types/parser';
import type { ReadingInfo } from '../types/reading';
import { getActiveProfiles, matchProfile } from '../config/site-profile-store';
import { isChapterPage } from './page-classifier';
import { createProfileParserForProfile } from './profile-parser';
import { createNetTruyenParser } from './nettruyen-parser';
import { createTruyenQQParser } from './truyenqq-parser';
import { createTruyenFullParser } from './truyenfull-parser';
import { createVietnamThuQuanParser } from './vietnamthuquan-parser';
import { createGenericParser } from './generic-parser';
import { logger } from '../utils/logger';

type ParserFactory = (ctx: ParserContext) => StoryParser;

const LEGACY_FACTORIES: ParserFactory[] = [
  createNetTruyenParser,
  createTruyenQQParser,
  createTruyenFullParser,
  createVietnamThuQuanParser,
];

export class ParserFactoryRegistry {
  private readonly legacyFactories: ParserFactory[];

  constructor(legacyFactories: ParserFactory[] = LEGACY_FACTORIES) {
    this.legacyFactories = legacyFactories;
  }

  register(factory: ParserFactory): void {
    this.legacyFactories.unshift(factory);
  }

  async resolve(ctx: ParserContext): Promise<StoryParser> {
    const profiles = await getActiveProfiles();
    const profile = matchProfile(ctx.url, profiles);
    if (profile) {
      logger.debug(`Resolved profile parser: ${profile.id} for ${ctx.url}`);
      return createProfileParserForProfile(ctx, profile);
    }

    const parsers = this.legacyFactories
      .map((f) => f(ctx))
      .sort((a, b) => b.priority - a.priority);

    for (const parser of parsers) {
      if (parser.canHandle(ctx.url)) {
        logger.debug(`Resolved legacy parser: ${parser.siteId} for ${ctx.url}`);
        return parser;
      }
    }

    logger.debug(`No specific parser matched, using generic for ${ctx.url}`);
    return createGenericParser(ctx);
  }
}

export const parserFactory = new ParserFactoryRegistry();

export async function extractReadingInfo(ctx: ParserContext): Promise<ReadingInfo | null> {
  const profiles = await getActiveProfiles();
  if (!isChapterPage(ctx.url, profiles)) {
    return null;
  }

  const parser = await parserFactory.resolve(ctx);
  return parser.extract();
}
