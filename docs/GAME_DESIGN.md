# Thiết kế
Mục tiêu: RPG fantasy nhìn ngang, đội hình tối đa năm tướng tự chiến đấu, kỹ năng
chủ động/tự động, vượt ải rồi nâng tướng/trang bị. Tham khảo Sword Master Story
về thể loại; tên, nhân vật, cốt truyện và tài nguyên riêng.

0.2 hiện có: một kiếm sĩ 220 HP, sát thương 22, chuẩn bị đòn 0.18s, nghỉ 0.48s;
kỹ năng diện rộng 48, hồi 6s. Ba đợt 2/3/4 địch, HP 67/79/91. Cận chiến đánh10,
đánh xa7, chuẩn bị 0.45s, hồi1.8s. Đây là số thử, không cân bằng cuối.
Kỹ năng phát tức thì. Đòn thường chốt ID lúc chuẩn bị, kiểm tra sống/tầm lúc chạm.
Nếu cả hai phe hết máu cùng tick, thất bại được ưu tiên. Chuyển đợt nghỉ1.2s.
Chưa có đạn bay: địch xa gây sát thương trực tiếp sau báo đòn.

Battle RefCounted giữ trạng thái thuần, main.gd trình bày/input, audio.gd phát local.
Trước mở rộng đội hình sẽ tách actor/skill/content data khỏi model nhỏ hiện tại.
