# Đội hình — prototype 0.5.0

## Cách thử
Chọn ải → màn chuẩn bị: thêm/bớt bốn đồng đội và đổi thứ tự bằng nút;
Aether giữ đầu. Đội mặc định5, có thể1–5; lựa chọn lưu trong campaign profile.
Bắt đầu, tướng tự di chuyển/đánh. Năm thẻ dưới trận hiển thị HP, hồi chiêu
và trạng thái gục. Chạm thẻ hoặc phím 1–5 để dùng kỹ năng; Space vẫn là Aether.
Chạm **Kỹ năng: tay** để bật tự động. Bật lại để dùng tay. Tự động ưu tiên
lá chắn, hồi máu nếu có tướng còn sống thiếu ít nhất 30 HP, rồi sát thương.
Có thể bấm tay cả khi tự động đang bật. Tùy chọn đội/tự động lưu cùng tiến trình.

| Tướng | Vai trò | HP | Đánh thường | Kỹ năng | Hồi |
| --- | --- | ---: | ---: | --- | ---: |
| Aether | Kiếm sĩ | 220 | 22 | Kiếm khí: 48 toàn bộ địch | 6s |
| Brann | Hộ vệ | 320 | 13 | Hộ thuẫn: lá chắn 35 mỗi đồng đội sống | 10s |
| Lyra | Cung thủ | 145 | 17 | Xuyên tinh: 85 địch gần mình nhất | 8s |
| Nyx | Pháp sư | 130 | 15 | Tinh hỏa: 38 toàn bộ địch | 9s |
| Sol | Trị liệu | 155 | 8 | Bình minh: hồi 55 mỗi đồng đội sống | 10s |

Lá chắn hấp thụ trước HP, không cộng dồn (lấy mức lớn hơn), giữ đến khi bị đánh
hoặc kết thúc trận. Hồi máu không vượt HP tối đa, không hồi sinh. Tướng gục
không di chuyển, đánh hoặc dùng chiêu. Thua khi toàn đội gục, kể cả Aether đã
chết trước đó; HP/lá chắn/hồi chiêu giữ qua đợt, reset khi chơi lại.
Quái và boss chọn tướng sống gần nhất lúc chuẩn bị đòn và giữ mục tiêu đến
lúc đánh; mục tiêu chết thì đòn đó không chuyển sang đồng đội khác.
Ba đợt và boss giữ thông số cũ, không có sơ hở/multiplier hoặc cửa sổ kỹ năng.
Đánh xa vẫn là sát thương trực tiếp sau windup, chưa có đạn vật lý.

## Cấu trúc và tài nguyên
`game/party_data.gd` chứa thông số tướng/kỹ năng và tạo trạng thái actor riêng.
`Battle.heroes` giữ actor; Battle điều phối mục tiêu, đòn thường, hồi chiêu,
lá chắn/hồi máu và kết quả. Alias hero_hp/hero_x/cooldown giữ API một tướng
cho kiểm tra hồi quy. `start()` mặc định một tướng; UI gọi `start(party_size)`.
`main.gd` quản lý nút, tự động và trình bày, không quyết định sát thương.
Aether giữ atlas đã duyệt. Bốn đồng đội đã có frame PNG fantasy riêng (xem SPRITE_FRAMES.md), dùng chung
renderer với Aether và đồng bộ qua `companion_art.gd`; xem PARTY_ART.md cho nguồn
và giới hạn. Không thêm âm thanh, dịch vụ hoặc API runtime. Không đổi save âm thanh.

## Giới hạn và kiểm tra
Đã có chọn/đổi thứ tự đồng đội, chương10ải và lưu local; chưa kho tướng mở rộng,
trang bị, nâng tướng hoặc APK. Xem CAMPAIGN.md. Chưa coi chỉ số là cân bằng cuối; đội năm
hiện mạnh hơn nhiều so với trận thiết kế cho một tướng. Không có thưởng mới.

Godot 4.6.3 headless: kiểm tra một tướng cũ và đội 1–5, chiêu độc lập,
lá chắn, hồi máu/không hồi sinh, mục tiêu đã chốt, pause, reset và thắng/thua.
Kiểm scene cho năm nút, đồng đội, tự động, về sảnh, khởi động lại một tướng.
Đã render/chụp/xem cảnh đội5 và màn xem bốn nhân vật ở0.4.1. Chưa thử cảm ứng,
âm thanh hoặc đo FPS trên S23 Ultra; cần duyệt mỹ thuật trên thiết bị.
