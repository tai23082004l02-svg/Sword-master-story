# Bổ sung 0.3.1 — Quái và nền
Người dùng đã chấp nhận Aether/hướng đồ họa0.3.0. Đã thêm2quái sprite và nền
Phế tích Ngân Nguyệt; EnemyArt theo ID, animation/windup/hurt/death và cleanup.
Đọc ENVIRONMENT_AND_ENEMIES.md. Có ảnh render Godot thật đã xem trong screenshots.
Thêm enemy_art_smoke và capture_scene (cần display). Giữ chỉ số/audio/save.
Đã chặn pause/resume mở lại trạng thái thắng/thua. Chưa có boss/multihero/parallax.

# Bổ sung 0.3.0 — Aether
Đã thay kiếm sĩ hình học bằng sheet RGBA24ô,6clip; main dùng HeroArt Node2D.
Có màn xem riêng, nút6trạng thái, đồng bộ đòn theo Battle, hurt/death/skill, pause.
Chờ duyệt hình trên máy thật; không đổi chỉ số/audio/save. Đọc CHARACTER_AETHER.md.
Kiểm tra thêm tests/hero_art_smoke.gd. Mốc0.3 mới xong phạm vi một nhân vật.

# Bàn giao 0.2.0
Repo mới Sword-master-story/main; engine xác minh Godot4.6.3. Tiếng Việt, offline,
S23 Ultra/Godot Android, Git nội bộ Termux rồi rsync. Giữ project cũ riêng.
Đã có battle model, menu/cảm ứng/phím, ba đợt, cận chiến/đánh xa, skill, pause,
focus loss, kết quả/restart, audio tổng hợp local và mute lưu riêng.
Chưa có sprite cuối, đội hình, boss, trang bị, kinh tế/save tiến trình hoặc APK.

Kiểm tra: battle_smoke cho logic; scene_smoke cho vòng menu/bắt đầu/pause/resume/
kỹ năng/về sảnh/restart. Chưa thử máy thật, duyệt hình/âm hoặc benchmark.
Bước kế: người dùng thử nhịp trận; mốc0.3 dựng một cảnh mẫu sprite để duyệt.
