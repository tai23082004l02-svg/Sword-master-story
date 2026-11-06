# Trang bị — 0.6.2

Sảnh → **Trang bị**, hoặc nút cùng tên ở màn chuẩn bị đội. Chọn tướng ở hàng
trên; tổng HP/đòn thường đã gồm cấp và trang bị hiển thị ngay dưới tên.
Mua một món bằng vàng, sau đó bấm **Trang bị**. Mua không tự mặc.
Mỗi tướng có một ô vũ khí và một ô giáp. Thay món trả món cũ về kho;
**Tháo vũ khí / Tháo giáp** để chuyển món sang tướng khác, không mất vàng.
Mỗi món chỉ mua được một bản, chỉ một tướng dùng tại một thời điểm.

| Món | Cộng thêm | Giá vàng |
| --- | ---: | ---: |
| Kiếm sắt | 4 đòn thường | 80 |
| Kiếm nguyệt | 9 đòn thường | 240 |
| Kiếm bình minh | 16 đòn thường | 520 |
| Giáp vải | 35 HP | 80 |
| Giáp nguyệt | 80 HP | 240 |
| Giáp bình minh | 140 HP | 520 |

Đây là catalogue/thông số thử nghiệm tự thiết kế. Vũ khí dùng chung mọi vai trò;
không đổi hình nhân vật. Chỉ số cộng cố định **sau** tăng trưởng cấp, không nhân
với cấp; kỹ năng, hồi chiêu và tốc độ không đổi. Màn nâng cấp giữ bonus trang bị
ở cả trước/sau. Chuẩn bị và trận dùng cùng công thức. Trận nhận snapshot theo ID,
đổi thứ tự đội không nhầm bonus; thay đồ lưu sau đó không đổi actor trận đã chạy.
API trận cũ không truyền trang bị vẫn dùng chỉ số cũ.

## Lưu tiến trình
Schema 3 thêm owned_equipment (ID món đã mua) và equipment (5 bộ ô weapon/armor).
Đọc schema 1/2 bổ sung kho rỗng, giữ ví, cấp (schema1 mặc định cấp1), ải, đội,
kỷ lục, tự dùng skill và token thưởng. Không ghi file chỉ vì load. Trước ghi mới,
giữ nguyên save cũ tại .v1.bak/.v2.bak theo schema nguồn, cả khi recover từ .bak.
Không ghi đè bản migration đã có. Backup luân phiên và khóa schema tương lai giữ
cơ chế hiện có. Bản game cũ không đọc được schema3; bản sao migration không chứa
những thay đổi phát sinh sau chuyển đổi.

Mua trừ vàng + thêm sở hữu cùng transaction. Mặc/tháo cùng transaction riêng;
thiếu vàng, mua trùng, ô sai, món chưa sở hữu/đang ở tướng khác hoặc lỗi ghi đều
không đổi trạng thái. Validation từ chối ID lạ, ô thiếu, sở hữu trùng và món mặc
trùng. Lỗi hiện trên màn hình, có thể thử lại thao tác.

## Cách thử
1. Vượt ải tích vàng; mở Trang bị, mua Kiếm sắt (80 vàng).
2. Mặc cho Aether: cấp1 đánh22→26. Tháo: trở lại22, món về kho.
3. Chọn Nyx, mặc cùng kiếm: đánh15→19. Không thể mặc lại cho Aether khi Nyx giữ.
4. Mua/mặc Giáp vải: HP cộng35. Nâng tướng: bonus vẫn cộng sau chỉ số cấp.
5. Về chuẩn bị, đổi đội rồi đánh: HP/đòn thường đúng theo tướng.
6. Đóng/mở game: giữ vàng, sở hữu và tướng mặc từng món.

## Kiểm tra và giới hạn
17 smoke scripts PASS với Godot4.6.3 headless, save riêng tại /tmp/sword-equipment.
Hai test mới equipment_smoke và equipment_scene_smoke kiểm migration1/2, bản sao,
mua/mặc/tháo/chuyển, chỉ số/snapshot theo ID, reload, validation, thiếu vàng,
khóa ghi/lỗi ghi và đường đi sảnh→trang bị→chuẩn bị→trận. Các regression cũ
về campaign/save/growth/party/drag/battle/boss/art/frames vẫn PASS.
Chưa render duyệt giao diện, thử S23/cảm ứng, nghe âm hoặc đo FPS/nhiệt.
Chưa có rơi đồ, ngẫu nhiên, bán, cường hóa, nhiều bản sao hay hình/icon riêng.
Không thêm tài nguyên hình/âm hoặc dịch vụ ngoài.
