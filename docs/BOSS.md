# Kỵ sĩ Nguyệt Thực — 0.3.3

## Quyết định người dùng
Không có sơ hở tăng sát thương, invulnerability, parry hoặc yêu cầu canh kỹ năng.
Skill Aether luôn gây48damage nếu dùng hợp lệ, kể cả boss đang chuẩn bị đòn hoặc
đổi giai đoạn. Đòn báo trước chỉ giúp đọc diễn biến; trận hiện không có né chủ động.

## Vòng trận
Giữ ba đợt2/3/4quái cũ. Sau đợt3 nghỉ1.2s, boss xuất hiện như chặng4; chỉ thắng sau
khi hạ boss. Giữ nguyên HP Aether còn lại, không hồi đầy tự động. Boss600HP.
Một mình boss, không gọi lính. Hai giai đoạn:
- Giai đoạn1: Chém đại kiếm9damage, Sóng nguyệt thực12, Phán quyết bóng đêm17.
- Dưới hoặc bằng50%HP: chuyển giai đoạn2 đúng một lần, hiệu ứng tím, mỗi đòn+2damage,
  thời gian nghỉ nhân0.8. Không đổi sát thương nhận, không dừng trận hay khóa kỹ năng.

Chu kỳ đòn cố định; chuẩn bị lần lượt0.55/0.8/1.1s, nghỉ1.65/1.9/2s. Boss di chuyển
vào khoảng125 để ra đòn. Tầm155/1000/180. Sóng và cột chém là VFX khi damage áp dụng,
không phải đạn vật lý, không có cơ chế né. Không cam kết cân bằng cuối từ bot test.
Model BossBrain tách khỏi trình bày BossArt; Battle điều phối và dừng khi pause.

## Hình và âm
PNG riêng24ô256², giáp đen bạc, choàng đỏ, kiếm tím. Có đi/đứng, chém, phép/đòn mạnh,
biến đổi2frame, trúng đòn1frame và chết3frame. Hai chiêu lớn dùng chung6frame phép,
phân biệt bằng sóng ngang/cột chém. Ảnh tạo mới bằng OpenAI image generation,
không lấy asset game khác; chi tiết trong manifest. Giữ shader lọc nền0.3.2.
Chưa coi sheet AI là hoạt ảnh thủ công hoặc duyệt mỹ thuật cuối trên thiết bị.

Dùng lại wave.wav khi xuất hiện, skill.wav khi chuyển giai đoạn, win/lose/hit hiện có.
Không thêm audio/API/dịch vụ, pool/cooldown/mute giữ nguyên. Không có nghe duyệt mới.
Chết0.8s trước màn kết quả; thanh boss ghi HP, giai đoạn và tên đòn đang chuẩn bị.

## Kiểm tra
boss_smoke kiểm3đòn, ngưỡng phase một lần, damage skill48 ở cả nghỉ/windup/phase2,
pause và kết thúc. battle_smoke chạy đủ9quái+boss với skill ngay khi hồi: thắng,
Aether còn56HP ở mô phỏng60Hz, khoảng36.7s. Đây là kiểm logic, không duyệt độ vui.
Capture_boss chạy full trận bằng scene thực và chụp phase2/kết quả trong Godot,
không bỏ qua ba đợt. Chưa thử S23/Windows thật, FPS/nhiệt hoặc nghe audio.

Cách thử: Bắt đầu, qua3đợt, xem boss đổi giai đoạn ở300HP; thử pause/chuyển ứng dụng,
chơi lại sau thắng/thua. Có thể dùng kỹ năng bất cứ khi nào nút sẵn sàng.
