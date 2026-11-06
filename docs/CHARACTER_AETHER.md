# Aether — Kiếm sĩ Ngân Nguyệt · 0.3.0

Thiết kế riêng: tóc bạc, áo choàng xanh đêm lót ngọc, giáp bạc viền vàng,
kiếm bạc xanh ngọc. Fantasy anime chi tiết, góc nghiêng hướng phải.
Nguồn: OpenAI image generation trong phiên ngày2026-11-06. Không dùng ảnh,
nhân vật hoặc asset của Sword Master Story; không dùng sample hình bên thứ ba.
PNG RGBA1536×1024,24ô256×256; file gốc được giữ nguyên, không cắt nền bằng code.
Manifest nằm assets/hero/manifest.json. Không gán nhãn vẽ tay/CC0.

Sáu trạng thái: đứng6, chạy6, chém6, kỹ năng3, đau1, ngã2. Hurt là một pose giữ,
death là hai pose; chưa phải bộ hoạt ảnh thủ công nhiều in-between. Sheet sinh
bằng AI có thể có dao động chi tiết/tỷ lệ giữa frame; chờ người dùng xem máy thật.
Texture nearest; phong cách minh họa sprite có shading chi tiết, chưa ép palette
pixel giới hạn. Không khẳng định đạt chất lượng cuối trước khi người dùng duyệt.

Vào sảnh → Xem nhân vật · Aether. Bấm6 nút để xem; preview phóng1.75lần. Trong trận
hình tạm của kiếm sĩ đã thay hoàn toàn bằng atlas. Đứng/chạy theo chuyển động thật;
chém theo windup/recovery, thời điểm sát thương cũ0.18s tương ứng frame vung;
kỹ năng phản ứng khi skill được chấp nhận; hurt theo HP giảm; death trước kết quả.
Không thay220HP/22damage/48skill/6s cooldown hoặc logic quái. Kỹ năng vẫn gây
sát thương tức thì như0.2; hoạt ảnh/arc là trình bày, không tăng delay gameplay.
Pause đóng băng clock, background vẫn dùng cơ chế pause cũ. Không thêm audio.

Quái, nền và UI trận vẫn là placeholder0.2. Bản này hoàn thiện phạm vi một nhân vật,
không coi hoàn tất toàn bộ mốc0.3(quái/boss/nền). Chưa có ảnh render Godot được
kiểm trực quan hoặc thử S23 trong môi trường trợ lý. Atlas đã xem trực tiếp.
