import { useState } from 'react';

const STEPS = [
  'Mở app Story Tracker ít nhất một lần sau khi cài TestFlight.',
  'Cài đặt → Safari → Extensions → bật Story Tracker.',
  'Trong Safari: bấm nút aA (thanh địa chỉ) → Manage Extensions → bật Story Tracker.',
  'Quay lại trang truyện → bấm aA → chọn Story Tracker (icon puzzle) để Save / Sync.',
  'Nếu chưa thấy icon: Cài đặt → Safari → Extensions → Story Tracker → Allow trên mọi website.',
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
        <p className="ios-app__setup-title">Bật extension trong Safari</p>
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
        App là bảng điều khiển. <strong>Lưu tiến độ khi đọc truyện</strong> chỉ hoạt động qua
        extension trên thanh Safari (không phải trong app).
      </p>
      <ol className="ios-app__setup-steps">
        {STEPS.map((step) => (
          <li key={step}>{step}</li>
        ))}
      </ol>
      <p className="ios-app__setup-note">
        Hỗ trợ: Vietnam Thu Quan, NetTruyen, TruyenQQ, TruyenFull và site đã cấu hình trong Cài đặt.
      </p>
      <a
        className="ios-app__setup-link"
        href="https://support.apple.com/guide/iphone/use-extensions-in-safari-iphab0432bf6/ios"
        target="_blank"
        rel="noopener noreferrer"
      >
        Hướng dẫn Apple — Safari Extensions
      </a>
    </section>
  );
}
