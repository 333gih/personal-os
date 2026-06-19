import { describe, expect, it } from 'vitest';
import {
  crawlChapterMeta,
  crawlStoryMeta,
  crawlVtqSyncMeta,
  findChapterSelect,
  isNoisyChapterText,
} from './dom-crawler';
import type { SiteProfileSelectors } from '../types/site-profile';

const VTQ_SELECTORS: SiteProfileSelectors = {
  tableOfContents: ['#mucluc'],
  contentRoot: ['#noidung'],
};

const VTQ_HTML = `
<html><body>
  <p>Mời đọc tác phẩm: Tu Chân Bốn Vạn Năm,</p>
  <div id="mucluc">
    <h3>Mục lục</h3>
    <a href="#c1">Chương 1: Mở đầu</a>
    <a href="#c2">Chương 2: Tu luyện</a>
    <a href="#c3">Chương 3: Đột phá</a>
  </div>
  <div id="noidung">
    <h2 id="c1">Chương 1: Mở đầu</h2>
    <p>content 1</p>
    <h2 id="c2">Chương 2: Tu luyện</h2>
    <p>content 2</p>
    <h2 id="c3">Chương 3: Đột phá</h2>
    <p>content 3</p>
  </div>
</body></html>
`;

function ctx(html: string, url: string, scrollY = 0) {
  const document = new DOMParser().parseFromString(html, 'text/html');
  return {
    document,
    window: { scrollY, innerHeight: 400 } as unknown as Window,
    url,
  };
}

describe('dom-crawler VTQ mục lục', () => {
  it('extracts story from invite line', () => {
    const meta = crawlStoryMeta(
      ctx(VTQ_HTML, 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau'),
      VTQ_SELECTORS,
      'tid',
    );
    expect(meta.storyTitle).toBe('Tu Chân Bốn Vạn Năm');
    expect(meta.storyId).toBe('abc');
  });

  it('prefers chuto40 over nav buttons for story title', () => {
    const html = `
    <html><body>
      <div class="nav"><strong>&lt;&lt; Lui -☆- Tiến &gt;&gt;</strong></div>
      <span class="chuto40">Hàng Long Quyết</span>
      <h1>&lt;&lt; Lui -☆- Tiến &gt;&gt;</h1>
    </body></html>`;
    const meta = crawlStoryMeta(
      ctx(html, 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau'),
      { storyTitle: ['span.chuto40', 'h1'] },
      'tid',
    );
    expect(meta.storyTitle).toBe('Hàng Long Quyết');
    expect(meta.source).toBe('vtq_chuto40');
  });

  it('skips nav chuto40 when a second span has the real title', () => {
    const html = `
    <html><body>
      <div id="tieude">
        <span class="chuto40">&lt;&lt; Lui -☆- Tiến &gt;&gt;</span>
        <span class="chuto40">Thiên Tài Tiên Đạo</span>
      </div>
    </body></html>`;
    const meta = crawlStoryMeta(
      ctx(html, 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau'),
      {},
      'tid',
    );
    expect(meta.storyTitle).toBe('Thiên Tài Tiên Đạo');
  });

  it('resolves chapter from mục lục at start of page', () => {
    const url = 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau';
    const chapter = crawlChapterMeta(ctx(VTQ_HTML, url, 0), VTQ_SELECTORS, ['dom_toc']);
    expect(chapter.source).toBe('dom_toc');
    expect(chapter.chapterTitle).toMatch(/Chương 1/);
    expect(chapter.chapterUrl).toBe(
      'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#c1',
    );
    expect(chapter.chapterId).toBe('phandau:c1');
    expect(chapter.partTitle).toBe('Phần đầu');
  });

  it('detects Chương 103 from content heading, not nav buttons', () => {
    const html = `
    <html><body>
      <div class="nav"><strong>&lt;&lt; Lui -☆- Tiến &gt;&gt;</strong></div>
      <div id="noidung">
        <h2 id="c100">Chương 100</h2><p>...</p>
        <h2 id="c103">Chương 103: Đột phá cảnh giới</h2><p>content here</p>
      </div>
    </body></html>`;
    const url = 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau';
    const chapter = crawlChapterMeta(ctx(html, url, 800), VTQ_SELECTORS, [
      'dom_content_heading',
    ]);
    expect(chapter.source).toBe('dom_content_heading');
    expect(chapter.chapterTitle).toMatch(/Chương 103/);
    expect(chapter.chapterUrl).toContain('#c103');
    expect(chapter.chapterId).toBe('phandau:chuong-103');
  });

  it('resolves chapter from click hint when URL has only #phandau', () => {
    const url = 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau';
    const chapter = crawlChapterMeta(
      {
        ...ctx(VTQ_HTML, url, 0),
        chapterHint: {
          chapterNumber: '1',
          chapterTitle: 'Chương 1: Mở đầu',
          anchorId: 'c1',
          clickedAt: Date.now(),
        },
      },
      VTQ_SELECTORS,
      ['dom_click_hint'],
    );
    expect(chapter.source).toBe('dom_click_hint');
    expect(chapter.chapterTitle).toMatch(/Chương 1/);
    expect(chapter.chapterUrl).toBe(
      'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#c1',
    );
    expect(chapter.chapterId).toBe('phandau:chuong-1');
    expect(chapter.partTitle).toBe('Phần đầu');
  });

  it('sync mode scans catalog and matches current title', () => {
    const html = `
    <html><head><title>Chương 103 - Tu Chân Bốn Vạn Năm</title></head><body>
      <div id="mucluc">
        <a href="#c1">Chương 1</a>
        <a href="#c2">Chương 2</a>
        <a href="#c103">Chương 103</a>
      </div>
      <h2 id="TenChuong">Chương 103: Đột phá cảnh giới</h2>
      <select id="lstChuong">
        <option>Chương 1</option>
        <option selected>Chương 103: Đột phá cảnh giới</option>
        <option>Chương 104</option>
      </select>
    </body></html>`;
    const url = 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau';
    const meta = crawlVtqSyncMeta(ctx(html, url, 0), VTQ_SELECTORS);
    expect(meta.source).toBe('vtq_sync');
    expect(meta.totalChapters).toBeGreaterThanOrEqual(3);
    expect(meta.chapterTitle).toMatch(/Chương 103/);
    expect(meta.chapterIndex).toBe(3);
    expect(findChapterSelect(new DOMParser().parseFromString(html, 'text/html'))?.id).toBe('lstChuong');
  });

  it('reads current chapter from .chuongso and catalog from #muluben_to acronyms', () => {
    const html = `
    <html><body>
      <div id="tieude"><span class="chuongso">103</span></div>
      <div id="muluben_to">
        <acronym onclick="noidung1('tuaid=33083&chuongid=1')"><div><span class="chuongso">1</span></div></acronym>
        <acronym onclick="noidung1('tuaid=33083&chuongid=2')"><div><span class="chuongso">2</span></div></acronym>
        <acronym onclick="noidung1('tuaid=33083&chuongid=103')"><div><span class="chuongso">103</span></div></acronym>
        <acronym onclick="noidung1('tuaid=33083&chuongid=104')"><div><span class="chuongso">104</span></div></acronym>
      </div>
    </body></html>`;
    const url = 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau';
    const selectors = { tableOfContents: ['#muluben_to'] };

    const chapter = crawlChapterMeta(ctx(html, url, 0), selectors, ['dom_chuongso']);
    expect(chapter.source).toBe('dom_chuongso');
    expect(chapter.chapterTitle).toBe('Chương 103');
    expect(chapter.chapterId).toBe('phandau:chuong-103');
    expect(chapter.totalChapters).toBe(4);

    const syncMeta = crawlVtqSyncMeta(ctx(html, url, 0), selectors);
    expect(syncMeta.totalChapters).toBe(4);
    expect(syncMeta.chapterIndex).toBe(3);
    expect(syncMeta.chapterTitle).toMatch(/Chương 103/);
  });

  it('reads chapter from select dropdown (VTQ postback)', () => {
    const html = `
    <html><body>
      <select id="ddlChuong">
        <option>Chương 1</option>
        <option selected>Chương 103: Đột phá</option>
        <option>Chương 104</option>
      </select>
    </body></html>`;
    const url = 'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc#phandau';
    const chapter = crawlChapterMeta(ctx(html, url, 0), VTQ_SELECTORS, ['dom_select']);
    expect(chapter.source).toBe('dom_select');
    expect(chapter.chapterTitle).toMatch(/Chương 103/);
    expect(chapter.chapterId).toBe('phandau:chuong-103');
  });

  it('rejects noisy toolbar and mục lục blob as chapter text', () => {
    const noisy =
      'Phần đầu — A+ A- Cỡ chữ 16 Cỡ chữ 18 Mục Lục Chương 1 Chương 2 Chương 3';
    expect(isNoisyChapterText(noisy)).toBe(true);
  });
});
