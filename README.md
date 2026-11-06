# Kiếm Hành — prototype 0.2.0

Game nhập vai đội hình nhìn ngang, tham khảo nhịp chơi Sword Master Story.
Đang ở mốc nền tảng + trận đánh một kiếm sĩ, **chưa phải game đội năm tướng**.
Hình vẽ hình học bằng code là placeholder, chưa phải sprite anime/pixel cuối.

## Chơi thử
Godot 4.6.3, renderer Compatibility. Import `project.godot`, đợi import, Run.
Màn hình ngang 1280×720 logical, canvas co theo màn hình.
- Bấm Bắt đầu; kiếm sĩ tự chạy tới địch và đánh.
- Chạm Kiếm khí (hoặc Space): 48 sát thương toàn bộ địch, hồi 6 giây.
- Ba đợt gồm 2/3/4 quái cận chiến và đánh xa; kỹ năng giúp vượt trận.
- Tạm dừng hoặc Esc; chuyển ứng dụng tự pause, quay lại bấm Tiếp tục.
- Có thắng/thua, chơi lại, về sảnh khi pause và bật/tắt âm lưu riêng.
- Chưa có thưởng, save tiến trình, trang bị, boss, nhạc hoặc APK.

## Cập nhật trên S23 Ultra
Giữ SSH hiện có. Repo này có thư mục riêng, không ghi đè Game-2.5D.
Lần đầu trong Termux (đã cài git, openssh, rsync và cấp quyền storage):

```sh
mkdir -p ~/repos
git clone git@github.com:tai23082004l02-svg/Sword-master-story.git ~/repos/Sword-master-story
mkdir -p /storage/emulated/0/Download/GodotProjects/Sword-master-story
```

Lưu và đóng Godot trước mỗi lần cập nhật:

```sh
git -C ~/repos/Sword-master-story status
git -C ~/repos/Sword-master-story pull --ff-only
rsync -rc --backup --backup-dir="$HOME/sword-backup-before-sync" --exclude='.git/' --exclude='.godot/' "$HOME/repos/Sword-master-story/" /storage/emulated/0/Download/GodotProjects/Sword-master-story/
```

Nếu pull báo thay đổi local, giữ file và xử lý; không reset --hard.
Import project.godot ở thư mục mới. Không cần ZIP hoặc APK.

## Kiểm tra phát triển

```sh
godot --headless --path . --editor --import
XDG_DATA_HOME=/tmp/sword-test godot --headless --path . --script tests/battle_smoke.gd
XDG_DATA_HOME=/tmp/sword-test godot --headless --path . --script tests/scene_smoke.gd
```

Xem [thiết kế](docs/GAME_DESIGN.md), [lộ trình](docs/ROADMAP.md),
[âm thanh](docs/AUDIO.md), [bàn giao](docs/HANDOFF.md), [kiểm tra](docs/TEST_RESULTS.md).
