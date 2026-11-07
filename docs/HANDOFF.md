# Bổ sung 0.8.3 — Tốc độ trận x1/x2/x3
Nút dưới trận cạnh Âm, chuyển1→2→3→1, chỉ khi đang playing. Giữ trong session,
không ghi save/schema4. advance_battle lặp battle_speed bước min(delta,0.05),
chạy auto mỗi bước và dừng ngay khi thắng/thua; không dùng Engine.time_scale.
Visual hero playback_speed, companion/enemy sync dt nhân tốc độ; preview ngoài
trận vẫn1. Đồng hồ/kỷ lục là giây mô phỏng; delay kết quả0.85s/menu/âm giữ giờ
thực. Pause/focus dừng. Test battle_speed_smoke kiểm ratio/kết quả giống nhau,
auto/cycle/pause/focus/delta cap/art speed/receipt và chống cộng thưởng trùng.
Không đổi art, cân bằng hoặc dữ liệu lưu. Chưa thử S23/nghe âm/FPS thực.

# Rà soát tiếp 0.8.2 — 07/11/2026
Đồng bộ fast-forward main a618b2a, giữ mọi bổ sung của chatbot khác và UID test
cũ chưa track. Đọc lại README/RPG_SYSTEMS/RPG_REVIEW; chạy lại23smoke đều PASS.
Phát hiện campaign finish_run cộng5bụi khi kho đầy nhưng receipt chỉ ghi2;
UI hardcode2bụi/2mảnh/1véquét. Nay receipt dust phản ánh delta thực2hoặc7,
thêm sweep_tokens cho thắng/thua; UI dùng receipt. Không đổi phần thưởng,
schema4, dữ liệu người chơi hay art. Không tự thêm hệ thống ngoài kế hoạch.
Test campaign_reward_receipt_smoke kiểm reward thường/kho500, UI7bụi/1vé,
lỗi ghi→retry không nhân thưởng, reload và thua0thưởng. Tổng24smoke PASS.
Tiếp theo: chơi thật S23 theo ROADMAP, cân bằng và hình độc lập vẫn chờ.
Chưa thử cảm ứng/âm/FPS/nhiệt trên điện thoại.

# Rà soát tự động 0.8.1 — đã hoàn tất

Đã thực hiện lượt kiểm tra được hẹn sau hai tiếng. Remote main trước rà là
89c92f2, PR1/2/3 đã merged, không có thay đổi mã local khác; giữ nguyên UID test
chưa track đã có trong workspace. Đọc RPG_REVIEW.md cho trạng thái từng phần.

Sửa: receipt hầm có đủ bụi/gems/shards/vé quét và UI hiện đủ; tầng30 khóa nút
đánh tiếp; challenge lưu rotation_week trong pending từ lúc bắt đầu và dùng
cho cả nhóm địch/mảnh thưởng, không đổi khi qua tuần. Field này tùy chọn để đọc
pending schema4 cũ. Normalize floor/rotation_week vềint và validate metadata.
Lỗi abandon khi về sảnh/chọnải/màn RPG giữ màn/trận và báo lỗi; auto_skills chỉ
đổi sau commit thành công. Ẩn HP/nhãn địch của trận cũ trên màn kết quả.

23/23 smoke PASS với save riêng /tmp/sword-review-final/data, thêm một test rà
soát cho rollover tuần, pending cũ/validation, save failure/auto, thưởng và UI
tháp cuối. Hai ảnh thưởng render OpenGL/Mesa từ fixture mô phỏng kết quả đã xem.
Không thử điện thoại/nghe âm/đo FPS. Không thêm API, phí, runtime service, APK
hoặc tính năng ngoài kế hoạch. Hình độc lập/S23/cân bằng và giữ chân thực tế vẫn
chưa hoàn tất; không coi thống kê local là bằng chứng giữ chân.

---

# Bàn giao 0.8.0 — Mở rộng vòng chơi RPG

Người dùng yêu cầu triển khai toàn bộ kế hoạch từ ảnh tham khảo, tập trung giữ
chân qua vòng chơi, không ưu tiên âm thanh. Đã đặt automation kiểm tra sau hai
 tiếng từ yêu cầu: rà lỗi/tiến độ và tiếp tục phần thiếu trong phạm vi này.
Đọc README và RPG_SYSTEMS.md trước khi sửa; TEST_RESULTS.md ghi kiểm tra thật.

## Đã nối vào game
- Sảnh mới với nhân vật, mục tiêu và bảy cửa hệ thống. Tướng quản lý cấp, nội tại,
  kỹ năng, bậc; có trận thử không thưởng. Đội tối đa năm, chọn trong tám tướng.
- Loot UID riêng, sáu món/ba bộ theo chương, nhận đồ xác định luân phiên; túi
  phân trang, mặc/tháo/cường hóa/phân giải có xác nhận. Tương thích đồ cũ.
- Nyx+Lyra và Iris+Aether phối hợp, Brann/Sol/Rune/Vera có nội tại hỗ trợ.
  Địch giáp/hồi máu/sát thủ, hai chương mới; boss biến thể AoE/truy kích sau.
- 30 ải, hầm vàng/nguyên liệu, tháp 30 tầng, thử thách xoay tuần. Quét ải đã
  thắng ba lần bằng vé quét riêng; vé kiếm qua thắng đánh tay.
- Triệu hồi offline 1/10 lượt, 5% gói30 mảnh/95% gói5 mảnh, đều tám tướng;
  lượt20 bảo đảm tướng mong muốn, không mất pity khi đổi. Mảnh mở và nâng bậc.
- Sáu mục tiêu đầu, thưởng thắng tuần, thống kê local theo ải và hoạt động.
  Thống kê chưa phải bằng chứng giữ chân hoặc telemetry cộng đồng.

## Kiến trúc và save
rpg_data.gd giữ catalogue/default/validation/normalize; campaign_progress.gd giữ
mọi transaction. Schema4 đọc1/2/3 không ghi ngay, giữ backup migration theo schema
nguồn, UID/số chuẩn hóa int, giữ giao dịch atomic và token chống cộng lại.
Giữ hero_levels5 cũ, extra_levels3 trongrpg; levels() mặc định trả5 để giữ legacy,
levels(true) trả8. Battle.start nhận snapshots tùy chọn sau equipment; main chụp
stats theoID, không theo slot. tactics chỉ bật ởgameplay mới/trial, APIlegacy giữ
hồi quy. rpg_ui.gd kế thừa campaign_ui.gd; menu cũ giữ ẩn để tương thích APItest,
người chơi thấy lobby mới. inventory mới và gear cũ loại trừ nhau trong cùngô.

## Giới hạn và việc cần kiểm chứng
Đây là bản chơi thử đầy đủ luồng, chưa phải cân bằng cuối hay cam kết giữ chân.
Ba tướng mới là biến thể hình Nyx/Brann/Sol; nền/quái/boss tái sử dụng bộ riêng cũ
với tint/nhãn/cơ chế mới, chưa có tranh độc lập. Không sao chép asset tham khảo.
Đã render Godot OpenGL và xem ảnh; chưa thử S23/cảm ứng thật/nghe âm/đo FPS/nhiệt.
Tuần dựa đồng hồ UTC máy, không chống chỉnh giờ. Không APK, online, PvP, bang hội,
shop tiền thật, API trả phí hoặc dịch vụ mới. Không tự thêm các mục đó khi rà sau.

Khi kiểm tra tự động: fetch/đọc status trước, không đè thay đổi. Chạy test liên
quan với XDG_DATA_HOME riêng. Nếu toàn bộ phạm vi đã hoàn tất và test sạch, rà
lỗi/mâu thuẫn tài liệu rồi báo kết quả; không tạo thêm tính năng ngoài kế hoạch.

---

# Bổ sung 0.7.0 — Thiết lập và ưu tiên âm
Đọc AUDIO.md. Sảnh/paused có Âm lượng mở ConfirmationDialog: master/sfx0–100%,
mute; Lưu ghi.tmp/rename trước cập nhật bus, Hủy không đổi. Legacy audio.cfg
chỉ muted vẫn đọc; không đổi tên project/save campaign.4voice ưu tiên hit<skill
<wave<win/lose, cướpvoice thấp hơn/cũ nhất; kết quả dừngvoice cũ. Pause/focus
out dừng âm. Giữ WAV/gain gốc. Version0.7.0trong project.godot và sảnh đọc cùng
nguồn.19smoke PASS headless/save riêng, cóaudio model/scene mới; chưa duyệt
render/nghe/S23/FPS. Phần UI/safe area/hiệu năng của0.7còn chờ.

# Bổ sung 0.6.2 — Trang bị
Đọc EQUIPMENT.md. Catalogue6món tự thiết kế, mỗi món một bản,5tướng×2ô.
Mua vàng và mặc/tháo dùng transaction hiện có; không tự mặc khi mua, thay món
trả kho, không cho mặc trùng. Bonus HP/ATK cộng sau cấp, growth before/after
và prep dùng cùng stats; Battle chụp equipment theoID, legacy mặc định rỗng.
Schema3migrate1/2, giữ .v1.bak/.v2.bak một lần kể cả recover backup; load không
ghi. Giữ ví/cấp/ải/đội/token. 17smoke PASS trên Godot4.6.3 headless/save riêng,
có2test equipment mới. Chưa duyệt render, S23/cảm ứng/âm/FPS. Chưa rơi đồ,
bán/cường hóa/nhiều bản sao/icon; không thêm dịch vụ/tài nguyên/APK.

# Bổ sung 0.6.1 — Kéo thả đội hình
Đọc PARTY_DRAG.md. Prep hiển thị thẻ theo roster rồi các tướng dự bị; bỏ nút
Lên trước/Ra sau. PartyDrag nhận native touch/mouse, bỏ mouse tổng hợp từ touch,
đổi tọa độ qua inverse canvas transform; ngưỡng kéo16 đơn vị. Một pointer sở hữu
thao tác, chặn pointer khác; Escape/mất focus/touch canceled hủy. Chạm thêm/bỏ,
kéo chỉ đồng đội đã chọn; Aether cố định. Thả vào đồng đội khác chèn vào vị trí đó,
lưu bằng transaction hiện có; lỗi ghi giữ đội cũ. Không đổi schema2, ví/cấp/art.
15 smoke và capture OpenGL trên Linux; chưa thử cảm ứng thật trên S23.

# Bổ sung 0.6.0 — Nâng cấp5tướng
Đọc HERO_GROWTH.md. PartyData.stats/create cấp1–20, +10%HP/ATKgốc mỗi cấp,
ceil bằng số nguyên; skill/tầm/tốc độ giữ. Giá L→L+1:30+20(L−1)vàng,10LXP.
Progress schema2 hero_levels5số, đọc/migrate schema1 giữ toàn bộ dữ liệu cũ.
Không ghi khi chỉ load; trước lần ghi mới giữ nguyên.v1.bak (cả recover từ.bak).
Upgrade trừ ví+cấp cùng commit, thiếu/đạtcap/quote cũ/lỗi ghi không đổi dữ liệu.
UI sảnh/prep chọn tướng, xem trước-sau/giá/thiếu tài nguyên, xác nhận bằng nút
nâng1cấp; cấp/HP/ATK cũng hiện ởprep vàHUD. Battle nhận snapshot cấp theoID,
đảođội không nhầm tướng và không đổi giữa trận. Legacy API mặc địnhlvl1.
Giữ project name/audio.cfg, chương10ải, frame/hình; chưa trang bị/phó bản mới.
Kiểm14smoke + render fixture schema1/nâng/trận/cap/thiếu, save riêng. Chưa thử
S23/Windows thực, FPS/nhiệt/âm. Không có code/tài nguyên game tham khảo mới.

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
