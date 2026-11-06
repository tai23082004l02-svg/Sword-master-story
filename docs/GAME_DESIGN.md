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
0.4 đã tách dữ liệu tướng/kỹ năng vào party_data.gd, actor là dictionary riêng
trong Battle.heroes. UI mặc định5, API start() vẫn hỗ trợ một tướng để hồi quy.

##0.3.3
Trận hiện gồm ba đợt cũ+boss; thắng ởchặng4, tổng10địch. Không canh sơ hở,
không buff damage theo thời điểm. Skill cố định48; xem BOSS.md cho thông số.

## 0.4.0
Đội tối đa5, kỹ năng riêng và tự động; thông số/quy tắc hiện hành trong PARTY.md.
Mô tả0.2/0.3 ở trên là lịch sử bản một tướng. Toàn đội gục mới thua.

## 0.5.0 — Campaign
Hiện hành:10ải cấu hình riêng, boss5/10; chọn đội Aether+0–4đồng đội, thứ tự lưu.
Thưởng trận và thưởng đầu, mở tuần tự, XP/vàng chỉ tích lũy. Save local transaction
với run token, backup và schema validation. Xem CAMPAIGN.md cho toàn bộ thông số.
Mô tả trận4chặng ở0.3.3 chỉ là APIlegacy cho regression, không phải mọi ải hiện tại.
