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

## 0.3.2 — Alpha residue
Đã đo ảnh nguồn: nền ngoài hình có alpha thấp1–20/255, có cả vùng mờ cao hơn.
alpha_render.gd chạy OpenGL Compatibility kiểm từng pixel alpha0.04–0.075 ở
frame đầu hai sheet: output trùng màu nền (sai số<0.005), PASS. Import shader
không lỗi; ảnh trận/viewer đã chụp và xem lại. Chưa xác minh trực tiếp thiết bị.

##0.3.3 — Boss
boss_smoke:3đòn,phase50%một lần,skill48mọi trạng thái,pause,victory PASS.
battle_smoke: full3đợt+boss,10địch,skill ngay khi hồi thắng56HP ở60Hz.
Chưa dùng kết quả mô phỏng thay cho duyệt cân bằng/chơi thật.
scene_smoke,hero_art_smoke,enemy_art_smoke PASS. Shader alpha_render mở rộng
sang boss PASS. Đã render full trận OpenGL/Mesa llvmpipe60Hz, chụp/xem phase2
và chiến thắng; không skip3đợt. Audio Dummy, chưa nghe duyệt hoặc đo máy thật.

## 0.4.0 — Đội hình
Godot4.6.3 Linux headless, XDG_DATA_HOME riêng trong workspace:
- Import editor thành công, không lỗi script.
- battle_smoke, boss_smoke, scene_smoke, hero_art_smoke, enemy_art_smoke: PASS.
- party_smoke: đội1–5 thắng đủ10địch; skill độc lập, lá chắn, hồi máu có trần,
  không hồi sinh, leader gục vẫn chơi, toàn đội gục ưu tiên thua, pause/reset,
  quái và boss không đổi mục tiêu giữa đòn: PASS.
- party_scene_smoke: năm nút/đồng đội, hồi chiêu riêng, pause, tự động,
  về sảnh và restart một tướng: PASS.
Mô phỏng dùng skill ngay khi hồi: đội1/2/3/4/5 lần lượt36.7/33.7/25.4/23.3/22.5s;
không dùng các số này thay duyệt cân bằng thực tế. Chưa render/duyệt ảnh0.4
vì môi trường chưa có display, chưa thử S23/cảm ứng/âm thanh/FPS/nhiệt.

## 0.4.1 — Bốn đồng đội có sprite
Godot4.6.3 Linux, dữ liệu thử ở XDG_DATA_HOME riêng:
- Editor import bốn atlas và script mới: thành công, không lỗi script.
- battle_smoke, boss_smoke, scene_smoke, hero_art_smoke, enemy_art_smoke,
  party_smoke, party_scene_smoke: PASS.
- companion_art_smoke: bốn sheet đúng kích thước, sáu trạng thái theo actor,
  đóng băng khi pause, death khi toàn đội thua, reset khi chơi lại, màn xem5tướng
  và tích hợp trận: PASS.
- alpha_render trên display thực: PASS cho cả5tướng, quái và boss.
- capture_party: chụp/xem ảnh thực4viewer và đội5 trong Godot OpenGL
  Compatibility/Mesa llvmpipe trên Xorg dummy. Đã phát hiện/sửa nền mờ
  Brann/Lyra và vùng kỹ năng Lyra lộ pose kế bên; chụp/xem lại sau sửa.
Audio Dummy; cảnh báo driver không hỗ trợ đổi VSync, không có lỗi script.
Không suy ra FPS, nhiệt, âm hoặc cảm ứng trên S23 Ultra từ kiểm tra desktop.

## 0.4.2 — Bộ phận rời và rig thử Aether
Godot4.6.3, XDG_DATA_HOME riêng trong workspace:
- Extract:24PNG độc lập, alpha lọc một lần, trim viền; source kit giữ để đối chiếu.
- Build: scene editable Skeleton2D/20Bone2D/24Sprite2D/AnimationPlayer,6clip.
- aether_rig_smoke:24texture riêng đúng parent/owner,20bone,6clip có transform
  hữu hạn, chân thực sự di chuyển theo hierarchy, pause giữ transform,
  tách/ghép trả đúng offset và lab mở được: PASS.
- aether_rig_navigation: nút sảnh mở lab, Về sảnh trở lại main: PASS.
- battle_smoke, boss_smoke, scene_smoke, hero_art_smoke, enemy_art_smoke,
  party_smoke, party_scene_smoke, companion_art_smoke: PASS.
- Chụp/xem idle, overlay xương, attack và exploded trong Godot OpenGL
  Compatibility/Mesa llvmpipe/Xorg dummy. Đã sửa thứ tự lớp và điểm cầm kiếm.
Audio Dummy. Driver cảnh báo không hỗ trợ đổi VSync; không có lỗi script.
Chưa duyệt máy S23/cảm ứng/âm/FPS/nhiệt; chưa mesh deformation/IK hoặc thay rig
vào trận. Kiểm tra hiện phục vụ chuẩn bị hình và rig cutout thử.
