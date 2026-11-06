# Phế tích Ngân Nguyệt — 0.3.1

Người dùng đã thử và chấp nhận hướng hình của Aether0.3.0; giữ nguyên thiết kế đó.
Bản này tiếp tục cảnh mẫu: thay cả hai hình quái tạm bằng sprite riêng và nền vẽ
fantasy đồng bộ. Không thêm tướng/đội hình/boss/ải hoặc đổi chỉ số trận.

## Tài nguyên mới
- Kỵ sĩ Hắc giáp: giáp thép tối, áo choàng đỏ rách, mắt hổ phách và kiếm gai.
- Pháp sư U ảnh: áo choàng tím, mặt nạ xương và trượng thạch anh tím.
- Mỗi loại có6frame di chuyển và6frame đánh. Đứng dùng frame đầu; khi trúng đòn
  đổi sắc ngắn. Chết nghiêng/fade0.5s bằng code, chưa có sheet chết riêng.
- Phế tích Ngân Nguyệt: cầu đá, cổng đổ nát, rừng, lâu đài và trăng lớn.
  Một ảnh tĩnh1536×1024 được scale1280×720; không phải nền parallax nhiều lớp.

Nguồn: hai ảnh được tạo mới bằng OpenAI image generation trong phiên2026-11-06.
PNG gốc giữ nguyên; không cắt/chỉnh ảnh bằng code. Manifest ở từng thư mục assets.
Không lấy asset trò chơi khác, không API runtime, không dịch vụ âm thanh/chi phí mới.
Chưa gán giấy phép phát hành chung/CC0. Sheet AI có thể dao động chi tiết giữa frame;
không coi là animation thủ công hoàn chỉnh.

## Đồng bộ
EnemyArt trình bày theo ID từ Battle; di chuyển/đứng/windup/recovery theo trạng thái
thật. Đòn đánh frame3 đi cùng điểm gây damage sau windup0.45s. Mage có vệt tím ngắn
sau phát đòn; đây là cue trang trí, damage vẫn tức thì như model cũ, không đạn bay.
Tự quay về phía hero khi hai bên đổi vị trí. View chết giữ lại tối đa0.5s rồi giải phóng,
không gây thêm damage. Pause giữ clock/fade, về sảnh và restart dọn toàn bộ view.
Giữ hai archetype và ba đợt2/3/4, các chỉ số/skill/audio/save không đổi.

Sửa lỗi0.3.0: chỉ cho pause khi Battle đang playing. Trước đó cửa sổ0.85s sau thắng/
thua cho phép pause/resume đặt model trở lại playing. Giờ trạng thái kết thúc giữ nguyên.

## Kiểm tra và cách thử
Godot4.6.3 Compatibility trên Linux, Xvfb+Mesa llvmpipe, audio Dummy. Đã chụp và xem
ảnh cảnh trận và viewer thật ở docs/screenshots, không phải ảnh ghép minh họa.
Không dùng kết quả này làm bằng chứng FPS/âm thanh hoặc cảm ứng điện thoại.
Bắt đầu trận để xem quái chạy/đánh và nền mới; dùng kiếm khí xem hurt/death;
pause/chuyển ứng dụng, chơi lại, vào viewer Aether để kiểm giao diện.

Mốc0.3 còn boss mẫu. Đội năm tướng thuộc0.4, chưa triển khai.
