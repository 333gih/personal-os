import { useState } from 'react';

const STEPS = [
  'Cài app Story Tracker từ TestFlight (bạn đang dùng bước này).',
  'Vào Cài đặt → Safari → Extensions → bật Story Tracker.',
  'Cho phép extension trên các trang truyện bạn đọc.',
  'Mở chương truyện trong Safari, bấm icon extension để Save / Sync.',
];

export function SafariSetupBanner() {
  const [open, setOpen] = useState(true);

  if (!open) {
    return (
      <button type="button" className="ios-app__setup-collapsed" onClick={() => setOpen(true)}>
        Hướng dẫn bật Safari extension
      </button>
    );
  }

  return (
    <section className="ios-app__setup" aria-label="Enable Safari extension">
      <div className="ios-app__setup-head">
        <p className="ios-app__setup-title">Đọc truyện trong Safari</p>
        <button
          type="button"
          className="ios-app__setup-dismiss"
          onClick={() => setOpen(false)}
          aria-label="Thu gọn"
        >
          ×
        </button>
      </div>
      <p className="ios-app__setup-lead">
        App này là bảng điều khiển. Theo dõi chương, lưu tiến độ và đồng bộ Personal OS chạy qua
        <strong> Safari extension</strong> khi bạn đọc trên web.
      </p>
      <ol className="ios-app__setup-steps">
        {STEPS.map((step) => (
          <li key={step}>{step}</li>
        ))}
      </ol>
      <a
        className="ios-app__setup-link"
        href="https://support.apple.com/guide/iphone/use-extensions-in-safari-iphab0432bf6/ios"
        target="_blank"
        rel="noopener noreferrer"
      >
        Hướng dẫn Apple về Safari Extensions
      </a>
    </section>
  );
}
