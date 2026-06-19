import { describe, expect, it, vi } from 'vitest';
import {
  collectMulubenAcronyms,
  countMulubenAcronyms,
  isNavigationNoiseTitle,
  parseNoidungOnclick,
  readHeaderChuongNumber,
  readVtqStoryTitle,
  triggerMulubenChapter,
} from './muluben';

const VTQ_MULUBEN_HTML = `
<html><body>
  <div id="tieude"><span class="chuongso">103</span></div>
  <div id="muluben_to">
    <acronym onclick="noidung1('tuaid=33083&chuongid=1')">
      <div onclick="noidung1('tuaid=33083&chuongid=1')"><span class="chuongso">1</span> Mở đầu</div>
    </acronym>
    <acronym onclick="noidung1('tuaid=33083&chuongid=2')">
      <div><span class="chuongso">2</span></div>
    </acronym>
    <acronym onclick="noidung1('tuaid=33083&chuongid=103')">
      <div><span class="chuongso">103</span> Đột phá</div>
    </acronym>
  </div>
</body></html>
`;

describe('vtq-muluben', () => {
  it('rejects prev/next nav as story title', () => {
    expect(isNavigationNoiseTitle('<< Lui -☆- Tiến >>')).toBe(true);
    expect(isNavigationNoiseTitle('Hàng Long Quyết')).toBe(false);
  });

  it('reads story title from chuto40', () => {
    const html = `
    <html><body>
      <div class="nav"><strong>&lt;&lt; Lui -☆- Tiến &gt;&gt;</strong></div>
      <span class="chuto40">Hàng Long Quyết</span>
    </body></html>`;
    const doc = new DOMParser().parseFromString(html, 'text/html');
    expect(readVtqStoryTitle(doc)).toBe('Hàng Long Quyết');
  });

  it('skips nav chuto40 and picks the real title span', () => {
    const html = `
    <html><body>
      <div id="tieude">
        <span class="chuto40">&lt;&lt; Lui -☆- Tiến &gt;&gt;</span>
        <span class="chuto40">Tu Chân Bốn Vạn Năm</span>
      </div>
    </body></html>`;
    const doc = new DOMParser().parseFromString(html, 'text/html');
    expect(readVtqStoryTitle(doc)).toBe('Tu Chân Bốn Vạn Năm');
  });

  it('parses noidung1 onclick args', () => {
    expect(parseNoidungOnclick("noidung1('tuaid=33083&chuongid=1')")).toEqual({
      raw: 'tuaid=33083&chuongid=1',
      tuaid: '33083',
      chuongid: '1',
    });
  });

  it('counts acronym tags inside muluben_to', () => {
    const doc = new DOMParser().parseFromString(VTQ_MULUBEN_HTML, 'text/html');
    expect(countMulubenAcronyms(doc)).toBe(3);
  });

  it('reads header chuongso outside muluben_to', () => {
    const doc = new DOMParser().parseFromString(VTQ_MULUBEN_HTML, 'text/html');
    expect(readHeaderChuongNumber(doc)).toBe('103');
  });

  it('collects chuongid from each acronym', () => {
    const doc = new DOMParser().parseFromString(VTQ_MULUBEN_HTML, 'text/html');
    const entries = collectMulubenAcronyms(doc);
    expect(entries).toHaveLength(3);
    expect(entries[2].chuongid).toBe('103');
    expect(entries[2].tuaid).toBe('33083');
  });

  it('triggers noidung1 for matching chapter', () => {
    const doc = new DOMParser().parseFromString(VTQ_MULUBEN_HTML, 'text/html');
    const noidung1 = vi.fn();
    const win = window as Window & { noidung1?: (arg: string) => void };
    const previous = win.noidung1;
    win.noidung1 = noidung1;

    try {
      expect(triggerMulubenChapter(doc, '103', '103')).toBe(true);
      expect(noidung1).toHaveBeenCalledWith('tuaid=33083&chuongid=103');
    } finally {
      win.noidung1 = previous;
    }
  });
});
