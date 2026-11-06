# Kiểm tra 2026-11-06 — 0.2.0
Godot4.6.3 Linux headless:
- Editor import: thành công.
- battle_smoke: thắng đủ3 đợt/9quái khi dùng skill, thua khi hết HP, cooldown,
  pause không tick, reset và trạng thái kết thúc: PASS.
- scene_smoke: title/start/pause/resume/skill/title/restart: PASS.
- Main scene chạy headless120frames không lỗi script.
Chưa có display renderer để duyệt ảnh; chưa kiểm cảm ứng, safe area, loa/tai nghe,
FPS/nhiệt hoặc lifecycle thực trên S23. Kiểm tự động không thay chơi thật/cân bằng.
