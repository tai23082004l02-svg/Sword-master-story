# Thiết kế hiện hành — 0.8.0

RPG fantasy đội hình nhìn ngang, chơi offline. Mục tiêu là người chơi có lựa
chọn xây đội và mục tiêu tiến bộ rõ ràng: vượtải → săn đồ → nâng đội → mở thử
thách mới. Không sao chép nhân vật/tài nguyên từ game tham khảo.

Sảnh, tám tướng/năm slot, ba chương30ải, sáu đồ/ba bộ với UID riêng, hầm tài
nguyên/tháp/thử thách tuần, triệu hồi bằng tài nguyên chơi và mục tiêu thưởng.
Luật/chi phí/tỉ lệ/giới hạn đầy đủ ở RPG_SYSTEMS.md. Không có stamina hay nạp.

Battle giữ model thuần; main điều phối UI và snapshot. rpg_data là catalogue và
validation; Progress chốt ví/loot/mảnh/pity/cấp/thưởng cùng giao dịch. UI không
tự cộng thưởng. Save local có backup/migration, token chốt trận chống cộng lại.

Giữ cơ chế chơi cảm ứng/phím và tự dùng kỹ năng. Trận thua không trừ ví; ngắt
trận phải đánh lại. Kỹ năng không cần canh cửa sổ sơ hở. Có nội tại phối hợp,
quái giáp/hồi máu/sát thủ và boss biến thể toàn đội/truy kích để đổi cách xây đội.

Đây là thông số thử. Cần kiểm tra người chơi thật trước khi kết luận giữ chân;
đếm hoạt động trên máy chưa thay thế phân tích cộng đồng. Các tài liệu mốc cũ
là lịch sử; README/RPG_SYSTEMS/HANDOFF ghi trạng thái hiện tại.
