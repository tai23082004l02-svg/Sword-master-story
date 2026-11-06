# Âm thanh — 0.7.0

## Cách dùng
Sảnh hoặc màn tạm dừng → **Âm lượng**. Chỉnh âm lượng tổng/hiệu ứng từ0–100%,
hoặc bật **Tắt toàn bộ âm thanh**. Bấm **Lưu** áp dụng và ghi ngay; **Hủy**/đóng
hộp thoại giữ thiết lập trước. Lưu lỗi giữ hộp thoại mở, hiển thị thông báo và
không đổi thiết lập đang dùng. Không mở thiết lập giữa trận đang chạy;
tạm dừng trước để chỉnh. Nút Âm bật/tắt nhanh vẫn hoạt động như trước.

user://audio.cfg giữ cùng đường dẫn; đọc cấu hình cũ chỉ có muted với hai mức
âm lượng mặc định100%. Giá trị sai kiểu/không hữu hạn về mặc định, số ngoài
khoảng được chặn0–1. Ghi file.tmp rồi rename, chỉ cập nhật trạng thái/bus sau
thành công. Cấu hình âm thanh riêng với campaign, không đổi save tiến trình.

## Mixer
Giữ4voice và âm lượng gốc Master−6dB, từngvoice−14dB; mức100% bằng âm cũ.
Slider tổng tác động Master; slider hiệu ứng tác động SFX. Mức0 tắt bus tương
ứng; không phát cue khi muted hoặc một mức bằng0. Không phát bù khi bật lại.
Ưu tiên hit0 < skill1 < wave2 < win/lose3. Cóvoice rảnh thì dùng; nếu đầy,
cướpvoice ưu tiên thấp nhất, cũ nhất, chỉ khi cue mới có ưu tiên cao hơn.
Âm kết quả dừngvoice cũ trước phát. Hit tối đa một cue mỗi100ms, không tạo
voice mới. Pause/mất focus dừng mọivoice, resume không phát bù.

Năm WAV hit/skill/wave/win/lose tổng hợp bằng tools/generate_audio.py,
Python standard library, seed cố định, PCM16 mono22050Hz, không sample bên thứ ba,
API hoặc chi phí dịch vụ. Không thêm tài nguyên âm ởmốc0.7.0. Bus Music/UI có
sẵn nhưng chưa có nhạc/âm giao diện, limiter hoặc ducking.

## Kiểm tra
Godot4.6.3 headless/Dummy, save riêng /tmp/sword-070: audio_smoke kiểm legacy,
volume bus/reload, ưu tiên/cướpvoice, kết quả, throttle, mute/zero, cấu hình lỗi
và lỗi ghi. audio_scene_smoke kiểm Lưu/Hủy/lỗi qua UI, pause và nút theo màn,
phiên bản sảnh thống nhất. 19/19 smoke scripts PASS, hồi quy campaign/equipment/
growth/drag/party/battle/boss/art/frames. Chưa render duyệt hộp thoại, nghe
loa/tai nghe, thử S23/cảm ứng hoặc đo FPS/nhiệt. Headless không phải nghe duyệt.
Đây là phần âm thanh của0.7; safe area/UI/hiệu năng tiếp tục ởbước sau.
Repo chưa có giấy phép phát hành chung; chủ repo quyết định điều khoản.
