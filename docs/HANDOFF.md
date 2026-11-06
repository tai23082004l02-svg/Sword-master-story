# Bổ sung 0.5.0 — Chương10ải, thưởng, chuẩn bị đội và save
Đọc CAMPAIGN.md. Đã thêm CampaignData/Progress/UI, snapshot stage/roster vào
Battle, giữ API trận cũ cho regression. Boss5/10,2loại quái/hình cũ, không copyAPK.
Flow chọn ải→chuẩn bị→trận→thưởng→ải tiếp, mở tuần tự và chơi lại. Aether luôn
đầu, bốn đồng đội chọn/đổi thứ tự; art/auto theo ID. Vàng/XP hiện chỉ tích lũy.
Save user://campaign.json schema1; audio.cfg riêng. Token trước trận, chốt cùng
thưởng/mởải ngay khi won/lost trước delay0.85s; không cộng lại. JSON normalize
ID vềint. Ghi.tmp/flush/verify/backup/rename; recover.bak, giữ.damaged, hỏng cả2
hoặc future schema thì khóa ghi, không reset. Battle bị ngắt không resume/award.
Giữ hình0.4.3, không thêm APK/online/phó bản phụ/nâng tướng/trang bị/nhạc.
Kiểm12smoke + render full scene chương trên Linux/Godot4.6.3; chưa thửS23,
Windows thực, FPS/nhiệt hoặc âm. Capture profile/save riêng trong workspace.

# Bổ sung 0.4.3 — Gỡ rig, dùng frame rời
Người dùng không chọn bộ xương, yêu cầu xóa và tiếp tục tách frame kiểu cũ.
Đã gỡ toàn bộ asset/scene/script/tool/test/docs rig và nút mở lab; giữ lịch sử Git.
Đọc SPRITE_FRAMES.md.168PNG rời/7bank, mỗi ảnh trim+padding8 và offset chân
riêng. Runtime HeroArt/CompanionArt/EnemyArt/BossArt dùng SpriteFrames bank,
không load sheet/source region. Source sheet giữ làm nguồn gốc, không repaint.
Splitter tách component2D xuyên ranh giới cả hàng/cột; ghi source hash/anchor/
offset/size trong manifest; Lyra có2override đạn rời, boss có seam cho glow dính.
Viewer có Frame trước/sau/Phát lại và chỉ số, pause đồng bộ. Không đổi chỉ số,
logic trận, audio/save. Kiểm tra PNG/margin/offset/step và render cả168frame.
Atlas nguồn có dao động chi tiết/pose sẵn có; không coi tách ảnh là vẽ lại in-between.

# Bổ sung 0.4.1 — Hình và hoạt ảnh bốn đồng đội
Đọc PARTY_ART.md. Đã thay hình học Brann/Lyra/Nyx/Sol bằng atlas24ô/tướng,
sáu trạng thái. CompanionArt kế thừa renderer HeroArt với sheet cấu hình được,
tắt overlay kiếm xanh; sync actor/pause/hurt/death/skill và reset lúc begin.
Màn xem5tướng có chọn tên và6trạng thái. Giữ logic/chỉ số/audio/save0.4.0.
PNG riêng sinh bằng OpenAI image generation, Brann/Lyra sửa alpha bằng cùng công cụ;
manifest ghi nguồn/hash, shader alpha cũ giữ nguyên. Không dùng asset game khác.
Đã render/chụp/xem scene thật và viewer bằng OpenGL/Mesa, audio Dummy.
Chưa duyệt máy S23/âm/FPS. Atlas AI có giới hạn in-between/độ ổn định giữa frame.

# Bổ sung 0.4.0 — Nền đội hình
Đọc PARTY.md trước khi sửa. PartyData tạo actor riêng, Battle.heroes điều phối
đội1–5; Aether giữ nguyên chỉ số, alias một tướng giữ kiểm tra hồi quy.
Bốn đồng đội mới dùng hình học tạm tự vẽ bằng code, chưa có sprite cuối.
UI mặc định5, đổi số ở sảnh, kỹ năng riêng/phím1–5/Space và tự động.
Có lá chắn/hồi máu không hồi sinh; chỉ thua khi toàn đội gục. Quái/boss giữ
mục tiêu lúc chuẩn bị đòn. HP/shield/cooldown giữ qua đợt, reset khi chơi lại.
Giữ ba đợt/boss và audio/save cũ, không thêm dịch vụ/tài nguyên ngoài/APK.
Kiểm tra headless hồi quy và party_smoke/party_scene_smoke PASS; chưa render
ảnh0.4 hoặc thử S23/cảm ứng/âm/FPS. Cần duyệt hình tạm và cân bằng đội5.

# Bổ sung 0.3.3 — Boss đầu tiên
Người dùng chốt bỏ canh sơ hở; BossBrain không có vulnerability/multiplier.
Boss600HP sau ba đợt,3đòn,phase2ở50%, chỉ thắng khi hạboss. BossArt riêng với
shader alpha hiện có; HUD,windup và chết0.8s. Đọc BOSS.md trước khi sửa.
Giữ chỉ số Aether/quái và audio/save. boss_smoke thêm kiểm skill48 mọi trạng thái.
Mốc cảnh mẫu0.3 đã có hero/quái/boss/nền/skill; bước sau0.4 đội hình nhiều tướng.

# Bổ sung 0.3.2 — Lọc nền alpha
Người dùng thấy hình vuông mờ quanh sprite. Ảnh AI có nhiều pixel alpha1–20/255
ngoài nhân vật. HeroArt/EnemyArt dùng shader sprite_alpha: texel.a nhân smoothstep
0.08–0.20 trước vertex tint, giữ modulation/fade. Không chỉnh PNG/import/chỉ số.
Đã render kiểm low-alpha thực bằng tests/alpha_render.gd và xem lại ảnh Godot.
Chưa xác minh máy người dùng. Hiệu ứng glow rất mờ có thể giảm theo bộ lọc.

# Bổ sung 0.3.1 — Quái và nền
Người dùng đã chấp nhận Aether/hướng đồ họa0.3.0. Đã thêm2quái sprite và nền
Phế tích Ngân Nguyệt; EnemyArt theo ID, animation/windup/hurt/death và cleanup.
Đọc ENVIRONMENT_AND_ENEMIES.md. Có ảnh render Godot thật đã xem trong screenshots.
Thêm enemy_art_smoke và capture_scene (cần display). Giữ chỉ số/audio/save.
Đã chặn pause/resume mở lại trạng thái thắng/thua. Chưa có boss/multihero/parallax.

# Bổ sung 0.3.0 — Aether
Đã thay kiếm sĩ hình học bằng sheet RGBA24ô,6clip; main dùng HeroArt Node2D.
Có màn xem riêng, nút6trạng thái, đồng bộ đòn theo Battle, hurt/death/skill, pause.
Chờ duyệt hình trên máy thật; không đổi chỉ số/audio/save. Đọc CHARACTER_AETHER.md.
Kiểm tra thêm tests/hero_art_smoke.gd. Mốc0.3 mới xong phạm vi một nhân vật.

# Bàn giao 0.2.0
Repo mới Sword-master-story/main; engine xác minh Godot4.6.3. Tiếng Việt, offline,
S23 Ultra/Godot Android, Git nội bộ Termux rồi rsync. Giữ project cũ riêng.
Đã có battle model, menu/cảm ứng/phím, ba đợt, cận chiến/đánh xa, skill, pause,
focus loss, kết quả/restart, audio tổng hợp local và mute lưu riêng.
Chưa có sprite cuối, đội hình, boss, trang bị, kinh tế/save tiến trình hoặc APK.

Kiểm tra: battle_smoke cho logic; scene_smoke cho vòng menu/bắt đầu/pause/resume/
kỹ năng/về sảnh/restart. Chưa thử máy thật, duyệt hình/âm hoặc benchmark.
Bước kế: người dùng thử nhịp trận; mốc0.3 dựng một cảnh mẫu sprite để duyệt.
