import type { SyncNowResult } from '../types/reading';

export function formatSyncResultMessage(result: SyncNowResult): string {
  if (result.failed > 0 && result.synced === 0) {
    if (result.error?.includes('ring-balancer') || result.error?.includes('Kong')) {
      return 'API Personal OS đang lỗi (503). Server chưa nhận được data — cần sửa Kong/backend trên VPS.';
    }
    return result.error ?? 'Đồng bộ thất bại. Kiểm tra đăng nhập hoặc mạng.';
  }

  if (result.localCount === 0) {
    if (result.serverCount > 0) {
      return `Cloud đã có ${result.serverCount} truyện. Máy bạn chưa có lịch sử local — hãy Save trên trang chương trước.`;
    }
    if (result.serverCount === 0) {
      return 'Chưa có truyện nào trên máy. Mở chương truyện, bấm Save progress, rồi đồng bộ lại.';
    }
    return 'Không kiểm tra được cloud. Thử lại sau hoặc mở Entertainment trên web.';
  }

  if (result.synced > 0) {
    const failedSuffix = result.failed > 0 ? ` (${result.failed} lỗi)` : '';
    const serverSuffix =
      result.serverCount >= 0 ? ` Cloud hiện có ${result.serverCount} truyện.` : '';
    return `Đã đồng bộ ${result.synced}/${result.localCount} truyện lên Personal OS${failedSuffix}.${serverSuffix}`;
  }

  if (result.serverCount > 0) {
    return `Cloud đã có ${result.serverCount} truyện (không có thay đổi mới từ máy).`;
  }

  if (result.serverCount === 0) {
    return 'Chưa có data trên cloud. Kiểm tra API Personal OS hoặc đăng nhập cùng tài khoản trên web.';
  }

  return 'Không kiểm tra được cloud sau khi đồng bộ. Mở Entertainment trên web để xác nhận.';
}
