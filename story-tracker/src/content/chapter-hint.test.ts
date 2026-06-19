import { describe, expect, it } from 'vitest';
import { parseChapterFromElement } from './chapter-hint';

describe('chapter-hint', () => {
  it('parses chapter from mục lục link click', () => {
    const document = new DOMParser().parseFromString(
      '<a href="#c1">Chương 1: Mở đầu</a>',
      'text/html',
    );
    const link = document.querySelector('a')!;
    const hint = parseChapterFromElement(link);
    expect(hint?.chapterNumber).toBe('1');
    expect(hint?.chapterTitle).toMatch(/Chương 1/);
    expect(hint?.anchorId).toBe('c1');
  });

  it('parses chapter from li text without hash', () => {
    const document = new DOMParser().parseFromString(
      '<ul><li>Chương 5</li></ul>',
      'text/html',
    );
    const li = document.querySelector('li')!;
    const hint = parseChapterFromElement(li);
    expect(hint?.chapterNumber).toBe('5');
    expect(hint?.anchorId).toBeUndefined();
  });

  it('parses chapter from acronym click in muluben', () => {
    const document = new DOMParser().parseFromString(
      `<div id="muluben_to"><acronym onclick="noidung1('tuaid=33083&chuongid=7')"><div><span class="chuongso">7</span></div></acronym></div>`,
      'text/html',
    );
    const span = document.querySelector('.chuongso')!;
    const hint = parseChapterFromElement(span);
    expect(hint?.chapterNumber).toBe('7');
    expect(hint?.chuongid).toBe('7');
    expect(hint?.tuaid).toBe('33083');
  });
});
