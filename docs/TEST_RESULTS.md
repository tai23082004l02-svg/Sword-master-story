# Kiểm tra 2026-11-06 — 0.2.0
Godot4.6.3 Linux headless:
- Editor import: thành công.
- battle_smoke: thắng đủ3 đợt/9quái khi dùng skill, thua khi hết HP, cooldown,
  pause không tick, reset và trạng thái kết thúc: PASS.
- scene_smoke: title/start/pause/resume/skill/title/restart: PASS.
- Main scene chạy headless120frames không lỗi script.
Chưa có display renderer để duyệt ảnh; chưa kiểm cảm ứng, safe area, loa/tai nghe,
FPS/nhiệt hoặc lifecycle thực trên S23. Kiểm tự động không thay chơi thật/cân bằng.

## 0.3.0 — Aether
Godot4.6.3: import atlas và script thành công; battle_smoke, scene_smoke và
hero_art_smoke PASS. Art test kiểm dimensions/alpha,6preview, về sảnh, skill
và clock pause. Atlas đã xem; chưa render/duyệt cảnh Godot hoặc chạy máy thật.

## 0.3.1 — Quái và nền
Godot4.6.3 import thành công. battle_smoke, scene_smoke, hero_art_smoke và
enemy_art_smoke PASS. Bài mới kiểm view theo ID, windup, fade chết/dọn, pause
giữ fade, dọn về sảnh và chặn pause trạng thái kết thúc.
Đã render/chụp/xem docs/screenshots/moon_ruins_battle.png và aether_viewer.png
trên Xvfb/OpenGL Compatibility/Mesa llvmpipe với audio Dummy. Driver cảnh báo
không hỗ trợ đổi VSync; không có lỗi script. Không suy ra FPS/âm thanh S23.
