import type { ParserContext, StoryParser } from '../types/parser';
import type { ReadingInfo } from '../types/reading';
import { isChapterPage } from './page-classifier';
import { createNetTruyenParser } from './nettruyen-parser';
import { createTruyenQQParser } from './truyenqq-parser';
import { createTruyenFullParser } from './truyenfull-parser';
import { createVietnamThuQuanParser } from './vietnamthuquan-parser';
import { createGenericParser } from './generic-parser';
import { logger } from '../utils/logger';

type ParserFactory = (ctx: ParserContext) => StoryParser;

const PARSER_FACTORIES: ParserFactory[] = [
  createNetTruyenParser,
  createTruyenQQParser,
  createTruyenFullParser,
  createVietnamThuQuanParser,
];

export class ParserFactoryRegistry {
  private readonly factories: ParserFactory[];

  constructor(factories: ParserFactory[] = PARSER_FACTORIES) {
    this.factories = factories;
  }

  register(factory: ParserFactory): void {
    this.factories.unshift(factory);
  }

  resolve(ctx: ParserContext): StoryParser {
    const parsers = this.factories.map((f) => f(ctx));
    const sorted = parsers.sort((a, b) => b.priority - a.priority);

    for (const parser of sorted) {
      if (parser.canHandle(ctx.url)) {
        logger.debug(`Resolved parser: ${parser.siteId} for ${ctx.url}`);
        return parser;
      }
    }

    logger.debug(`No specific parser matched, using generic for ${ctx.url}`);
    return createGenericParser(ctx);
  }
}

export const parserFactory = new ParserFactoryRegistry();

export async function extractReadingInfo(ctx: ParserContext): Promise<ReadingInfo | null> {
  if (!isChapterPage(ctx.url)) {
    return null;
  }

  const parser = parserFactory.resolve(ctx);
  return parser.extract();
}
