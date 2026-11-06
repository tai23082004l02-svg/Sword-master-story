extends "res://game/campaign_ui.gd"
const RPG = preload("res://game/rpg_data.gd")
var page := 0
var selected_uid := 0
func header(title_value: String) -> void:
	text(title_value,Vector2(50,85),Vector2(1000,45),30,Color("edce92"))
	button("Sảnh",Vector2(1100,80),Vector2(130,50),host.to_title)
func footer(value: String = "") -> void:
	notice = text(value,Vector2(430,650),Vector2(790,48),18,Color("94cfbd"))
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
func lobby() -> void:
	header("KIẾM HÀNH · " + str(ProjectSettings.get_setting("application/config/version")))
	var portrait = preload("res://game/hero_art.gd").new()
	portrait.position = Vector2(640,545)
	portrait.scale = Vector2(1.7,1.7)
	portrait.preview = true
	add_child(portrait)
	text("AETHER\nNgười giữ lời thề Ngân Nguyệt",Vector2(450,470),Vector2(450,70),24,Color("edce92"))
	var id: int = host.progress.unlocked()
	text("HÀNH TRÌNH\nChương %d · %s\nĐã vượt %d/30 ải" % [RPG.chapter(id),Campaign.CHAPTERS[RPG.chapter(id)-1],host.progress.data.cleared.size()],Vector2(55,155),Vector2(385,115),24)
	button("Tiếp tục · " + Campaign.label(id),Vector2(55,290),Vector2(340,65),func():host.prepare_stage(id),host.progress.read_only)
	var objective := "Đã hoàn thành các mục tiêu đầu. Thử tháp và xây đội mới!"
	for goal in RPG.GOALS:
		if not goal.id in host.progress.data.rpg.goals:
			objective = "%s\n%d/%d · Thưởng %d tinh thạch" % [goal.name,mini(host.progress.goal_value(goal),goal.target),goal.target,goal.gems]
			break
	var goal_text := text("MỤC TIÊU TIẾP THEO\n" + objective,Vector2(870,165),Vector2(350,150),22,Color("edce92"))
	goal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Xem mục tiêu",Vector2(880,340),Vector2(330,55),func():host.open_rpg("goals"))
	var r: Dictionary = host.progress.data.rpg
	text("Tinh thạch %d · Vé %d\nTướng %d/8 · Tháp %d/30" % [r.gems,r.tickets,r.recruited.count(true),r.tower],Vector2(875,410),Vector2(350,80),23)
	var entries = [["Tướng", "heroes"],["Đội hình","team"],["Túi đồ","inventory"],["Triệu hồi","summon"],["Hầm ngục","dungeons"],["Mục tiêu","goals"],["Phiêu lưu","stages"]]
	for i in range(entries.size()):
		var action: String = entries[i][1]
		button(entries[i][0],Vector2(50+i*169,565),Vector2(155,65),func():host.open_rpg(action))
	footer("Vượt ải → săn đồ → phối hợp đội → thử thách mới · Chơi offline")

func stages() -> void:
	var chapter: int = host.chapter_page
	header("PHIÊU LƯU · " + Campaign.CHAPTERS[chapter])
	for c in range(3):
		var selected := c
		button("Chương %d" % (c+1),Vector2(50+c*300,140),Vector2(280,48),func():host.chapter_page=selected;host.open_stages())
	for i in range(10):
		var id := chapter*10+i+1
		var stage := Campaign.stage(id)
		var cleared: bool = id in host.progress.data.cleared
		var label := "Đã vượt" if cleared else ("Sẵn sàng" if id <= host.progress.unlocked() else "Chưa mở")
		button("%s · %s\n%s\n%s" % [Campaign.label(id),"BOSS" if id%5==0 else "%d đợt" % stage.waves.size(),stage.title,label],Vector2(50+i%5*238,210+int(i/5)*145),Vector2(224,128),func():host.prepare_stage(id),id>host.progress.unlocked() or host.progress.read_only)
	text("Săn bộ%s · Mỗi trận thắng nhận 1 món +2 bụi; đồ luân phiên, không cần chờ may mắn." % ["Tro Hồng","Thành Trì","Bình Minh"][chapter],Vector2(50,510),Vector2(1180,44),20,Color("94cfbd"))
	button("Tiếp tục · " + Campaign.label(host.progress.unlocked()),Vector2(900,575),Vector2(330,60),func():host.prepare_stage(host.progress.unlocked()))
	footer()

func prepare(id: int) -> void:
	var stage := Campaign.stage(id)
	header(Campaign.label(id)+" · "+stage.title)
	var reward := Campaign.reward(id,not id in host.progress.data.cleared)
	text("Thắng +%d vàng +%d XP · Bộ %s · Boss mỗi 5 ải" % [reward.gold,reward.xp,["Tro Hồng","Thành Trì","Bình Minh"][RPG.chapter(id)-1]],Vector2(50,140),Vector2(1180,40),21)
	var roster: Array[int] = host.progress.formation()
	var order: Array[int] = roster.duplicate()
	for i in range(RPG.HERO_COUNT):
		if not i in order: order.append(i)
	var cards: Dictionary = {}
	for column in range(order.size()):
		var i: int = order[column]
		var hero: Dictionary = host.progress.hero_stats(i)
		var selected: bool = i in roster
		var unlocked: bool = host.progress.data.rpg.recruited[i]
		var card := button("%s · Cấp %d · %s\n%d HP · Đánh %d\n%s" % [hero.name,hero.level,"Vị trí %d" % (roster.find(i)+1) if selected else ("Dự bị" if unlocked else "Chưa mở"),hero.hp,hero.damage,hero.skill],Vector2(50+column%4*298,200+int(column/4)*130),Vector2(280,115),func():host.select_companion(i),i==0 or not unlocked)
		card.button_mask = 0
		cards[i]=card
	var drag := preload("res://game/party_drag.gd").new()
	drag.name="PartyDrag"
	drag.configure(self,host,cards,roster)
	add_child(drag)
	text("Kéo để đổi thứ tự · Chạm để thêm/bỏ · Tối đa 5 tướng, Aether giữ đầu",Vector2(50,470),Vector2(1180,35),21,Color("94cfbd"))
	text("Phối hợp: Nyx thiêu đốt + Lyra · Iris phá giáp + Aether · Brann/Rune bảo vệ + Sol/Vera",Vector2(50,510),Vector2(1180,35),19)
	button("Chọn ải khác",Vector2(50,575),Vector2(220,55),host.open_stages)
	button("Nâng tướng",Vector2(285,575),Vector2(210,55),func():host.open_growth("prepare"))
	button("Trang bị",Vector2(510,575),Vector2(210,55),func():host.open_equipment("prepare"))
	button("Túi đồ",Vector2(735,575),Vector2(200,55),func():host.open_rpg("inventory"))
	button("Bắt đầu",Vector2(950,575),Vector2(280,55),func():host.start_campaign(id),host.progress.read_only)
	button("Quét 1 lượt · 1 vé quét",Vector2(950,640),Vector2(280,50),func():host.rpg_sweep(id),not id in host.progress.data.cleared)
	footer(host.progress.last_error)
	notice.position=Vector2(230,650)
	notice.size=Vector2(690,48)

func heroes(index: int) -> void:
	header("TƯỚNG · ĐỘI HÌNH VÀ PHÁT TRIỂN")
	for i in range(RPG.HERO_COUNT):
		var selected := i
		button(Party.HEROES[i].name + ("" if host.progress.data.rpg.recruited[i] else " · Khóa"),Vector2(50,150+i*57),Vector2(220,48),func():host.open_rpg("heroes",selected))
	var hero: Dictionary = host.progress.hero_stats(index)
	var art = preload("res://game/hero_art.gd").new() if index==0 else preload("res://game/companion_art.gd").new()
	if index>0: art.configure(hero.id)
	art.position=Vector2(495,570)
	art.scale=Vector2(1.25,1.25)
	art.preview=true
	add_child(art)
	var r: Dictionary=host.progress.data.rpg
	text("%s · %s\nCấp %d/20 · Bậc %d/5\n%d HP · Đánh %d\n%s · Kỹ năng %d/5\nMảnh %d/30 để mở, dùng nâng bậc nếu đã mở" % [hero.name,hero.role,hero.level,r.ascension[index],hero.hp,hero.damage,hero.skill,r.skill_levels[index],r.shards[index]],Vector2(700,155),Vector2(530,195),23,Color(hero.color))
	var passive := text("Nội tại: "+RPG.PASSIVES[index],Vector2(700,360),Vector2(520,85),21)
	passive.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var opened: bool=r.recruited[index]
	button("Nâng 1 cấp · %d vàng/%d XP" % [30+(hero.level-1)*20,hero.level*10] if opened else "Mở tướng · 30 mảnh",Vector2(700,455),Vector2(530,50),func():host.rpg_action("level" if opened else "recruit",index,hero.level),hero.level>=20 if opened else r.shards[index]<30)
	button("Kỹ năng +15%% · %d vàng/%d bụi" % [r.skill_levels[index]*100,r.skill_levels[index]*10],Vector2(700,515),Vector2(530,50),func():host.rpg_action("skill",index,int(r.skill_levels[index])),not opened or r.skill_levels[index]>=5)
	button("Nâng bậc · %d mảnh · +5%% HP/đánh" % [(r.ascension[index]+1)*30],Vector2(700,575),Vector2(530,50),func():host.rpg_action("ascend",index),not opened or r.ascension[index]>=5)
	button("Thử tướng · Không tính thưởng",Vector2(300,590),Vector2(360,45),func():host.start_trial(index))
	footer("Iris/Rune/Vera đang dùng hình biến thể từ tài nguyên riêng sẵn có; chưa có hình độc lập." if index>=5 else "Chọn tướng để xem nội tại, nâng kỹ năng và bậc. Trang bị trong Túi đồ.")

func inventory(index: int, page_value: int) -> void:
	header("TÚI ĐỒ · BỤI %d · %d/500 món" % [host.progress.data.rpg.dust,host.progress.data.rpg.inventory.size()])
	for i in range(RPG.HERO_COUNT):
		var selected:=i
		button(Party.HEROES[i].name,Vector2(50+i*148,145),Vector2(138,45),func():host.rpg_page=0;host.open_rpg("inventory",selected))
	text("Đang chọn: "+Party.HEROES[index].name+" · Mặc đủ 2 món cùng bộ: Tro Hồng +10% đánh / Thành Trì +15% HP / Bình Minh −10% hồi",Vector2(50,200),Vector2(1180,40),18)
	var items: Array=host.progress.data.rpg.inventory
	var start:=page_value*6
	for row in range(6):
		if start+row>=items.size():break
		var item:Dictionary=items[start+row]
		var base:Dictionary=RPG.ITEMS[item.base]
		var uid:=int(item.uid)
		var owner:int=host.progress.item_user(uid)
		var y:=250+row*52
		text("#%d %s +%d · +%d%s\n%s" % [uid,base.name,item.rank,ceili((base.hp if base.slot=="armor" else base.damage)*(1.0+item.rank*0.15))," HP" if base.slot=="armor" else " đánh","Trong kho" if owner<0 else "Đang dùng: "+Party.HEROES[owner].name],Vector2(50,y),Vector2(560,46),18)
		button("Mặc" if owner<0 else "Tháo",Vector2(625,y),Vector2(130,43),func():host.rpg_action("equip" if owner<0 else "unequip",index,uid),owner>=0 and owner!=index or not host.progress.data.rpg.recruited[index])
		button("+ · %dv/%db" % [40*(item.rank+1),3*(item.rank+1)],Vector2(770,y),Vector2(220,43),func():host.rpg_action("enhance",uid,int(item.rank)),item.rank>=10)
		button("Phân giải",Vector2(1005,y),Vector2(225,43),func():host.confirm_dismantle(uid),owner>=0)
	if items.is_empty():text("Vượt ải đầu tiên để nhận trang bị. Mỗi trận thắng có 1 món; đồ luân phiên theoải.",Vector2(50,300),Vector2(1180,90),25)
	button("Trang trước",Vector2(50,580),Vector2(210,48),func():host.rpg_page=maxi(0,page_value-1);host.open_rpg("inventory",index),page_value==0)
	button("Trang sau",Vector2(280,580),Vector2(210,48),func():host.rpg_page=page_value+1;host.open_rpg("inventory",index),(page_value+1)*6>=items.size())
	button("Trang bị cũ",Vector2(950,580),Vector2(280,48),func():host.screen="title";host.open_equipment("title",mini(index,4)))
	footer("Bộ theo chương 1/2/3 · Phân giải có xác nhận, không hoàn tác · Đồ đang mặc cần tháo trước.")

func summon_page() -> void:
	header("TRIỆU HỒI · TINH THẠCH %d · VÉ %d" % [host.progress.data.rpg.gems,host.progress.data.rpg.tickets])
	text("Mỗi lượt: 1 vé hoặc 100 tinh thạch · Mỗi lượt đều nhận mảnh\n5% nhận 30 mảnh của 1 tướng; 95% nhận 5 mảnh · Chọn tướng đều trong 8 tướng\nLượt 20 chưa nhận gói 30 mảnh: bảo đảm 30 mảnh tướng mong muốn\nĐủ 30 mảnh tự mở tướng chưa có; tướng trùng giữ mảnh để nâng bậc.",Vector2(50,150),Vector2(1180,150),23)
	for i in range(RPG.HERO_COUNT):
		var selected:=i
		var r:Dictionary=host.progress.data.rpg
		button(("★ " if r.wishlist==i else "")+Party.HEROES[i].name+"\nMảnh %d · %s" % [r.shards[i],"Đã mở" if r.recruited[i] else "Chưa mở"],Vector2(50+i%4*298,330+int(i/4)*85),Vector2(280,72),func():host.rpg_action("wishlist",selected))
	text("Bảo đảm: %d/20 · Mong muốn: %s" % [host.progress.data.rpg.pity,Party.HEROES[int(host.progress.data.rpg.wishlist)].name],Vector2(50,515),Vector2(1180,40),25,Color("edce92"))
	button("Triệu hồi 1 lần",Vector2(50,575),Vector2(300,60),func():host.rpg_summon(1))
	button("Triệu hồi 10 lần",Vector2(370,575),Vector2(300,60),func():host.rpg_summon(10))
	button("Xem / thử tướng",Vector2(930,575),Vector2(300,60),func():host.open_rpg("heroes",int(host.progress.data.rpg.wishlist)))
	footer("Vượt ải mới nhận vé/tinh thạch; mục tiêu, tháp và thưởng tuần cho thêm. Không có nạp tiền.")

func dungeons() -> void:
	header("HẦM NGỤC · TÀI NGUYÊN VÀ THỬ THÁCH")
	var modes=["gold","material","tower","challenge"]
	var names=["HẦM VÀNG","HẦM NGUYÊN LIỆU","THÁP THỬ THÁCH","THỬ THÁCH TUẦN"]
	var descriptions=["120 vàng +40 XP\n1 món +3 bụi\nĐịch có giáp: dùng phá giáp", "35 vàng +40 XP\n1 món +15 bụi\nHạ địch hồi máu trước", "30 tầng tăng dần\n50 tinh thạch/tầng\nTiến độ %d/30" % host.progress.data.rpg.tower, "35 vàng +40 XP +1 món\n5 mảnh %s\nĐiều kiện đổi mỗi tuần" % Party.HEROES[RPG.week_now()%RPG.HERO_COUNT].name]
	for i in range(4):
		var mode:String=modes[i]
		var x:=50+i*298
		text(names[i],Vector2(x,190),Vector2(280,50),23,Color("edce92"))
		var label:=text(descriptions[i],Vector2(x,270),Vector2(270,180),23)
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button("Chiến đấu",Vector2(x,490),Vector2(280,60),func():host.start_activity(mode),host.progress.data.cleared.size()<5 or mode=="tower" and host.progress.data.rpg.tower>=30)
	button("Chuẩn bị đội",Vector2(50,580),Vector2(280,55),func():host.prepare_stage(host.progress.unlocked()))
	footer("Mở sauải 1-05 · Không giới hạn lượt đánh tay · Dùng đội hình đang lưu.")

func goals() -> void:
	header("MỤC TIÊU · HÀNH TRÌNH VÀ THƯỞNG TUẦN")
	for i in range(RPG.GOALS.size()):
		var goal:Dictionary=RPG.GOALS[i]
		var claimed:bool=goal.id in host.progress.data.rpg.goals
		var amount:int=host.progress.goal_value(goal)
		var y:=150+i*62
		text("%s · %d/%d · %d vàng/%d tinh thạch" % [goal.name,mini(amount,goal.target),goal.target,goal.gold,goal.gems],Vector2(50,y),Vector2(860,48),21)
		var id:String=goal.id
		button("Đã nhận" if claimed else ("Nhận" if amount>=goal.target else "Đi tới"),Vector2(950,y),Vector2(280,48),func():host.rpg_goal(id),claimed)
	var r:Dictionary=host.progress.data.rpg
	var wins:int=r.weekly_wins if r.week==RPG.week_now() else 0
	text("Tuần: thắng %d/10 trận → 300 tinh thạch +3 vé" % wins,Vector2(50,540),Vector2(860,48),23,Color("edce92"))
	button("Nhận thưởng tuần",Vector2(950,540),Vector2(280,48),func():host.rpg_action("weekly"),wins<10 or r.weekly_claimed and r.week==RPG.week_now())
	text("Nhật ký local: %d trận · %d thắng · %d ngày hoạt động · %d lượt quét" % [r.stats.runs,r.stats.wins,r.active_days.size(),r.stats.sweeps],Vector2(50,600),Vector2(1180,35),20)
	button("Thống kê local",Vector2(950,600),Vector2(280,40),func():host.open_rpg("stats"))
	footer("Mục tiêu có thưởng một lần; tuần theoUTC. Không mất chuỗi, không ép đăng nhập mỗi ngày.")

func activity_result(receipt: Dictionary) -> void:
	header("CHIẾN THẮNG" if host.battle.state=="won" else "THẤT BẠI")
	text(host.battle_stage.title,Vector2(70,170),Vector2(1140,45),30,Color("edce92"))
	if not receipt.get("ok",false):
		text("Chưa lưu kết quả: "+str(receipt.get("error","")),Vector2(70,260),Vector2(1140,90),24)
		button("Thử lưu lại",Vector2(850,550),Vector2(360,65),host.show_campaign_result)
	else:
		var detail: String="+%d vàng · +%d XP\n%s" % [receipt.gold,receipt.xp,receipt.get("loot",{}).get("name","")]
		detail += "\n+%d bụi · +%d tinh thạch · +%d vé quét" % [receipt.get("dust",0),receipt.get("gems",0),receipt.get("sweep_tokens",0)]
		if receipt.get("shards",0)>0:
			detail += "\n+%d mảnh %s" % [receipt.shards,Party.HEROES[int(receipt.shard_hero)].name]
		if not receipt.won:detail="Không mất tài nguyên. Thử thay đội hoặc nâng trang bị."
		text(detail,Vector2(70,270),Vector2(1140,160),28,Color("94cfbd"))
		button("Hầm ngục",Vector2(70,550),Vector2(360,65),func():host.open_rpg("dungeons"))
		var tower_done: bool = host.activity_mode=="tower" and host.progress.data.rpg.tower>=30
		button("Đã hoàn thành tháp" if tower_done else "Đánh tiếp",Vector2(850,550),Vector2(360,65),func():host.start_activity(host.activity_mode),tower_done)
	footer("Nyx + Lyra đối phó nhóm địch; Iris + Aether phá giáp; hộ vệ và trị liệu giúp sống lâu.")

func stats_page() -> void:
	header("THỐNG KÊ LOCAL · KIỂM CHỨNG VÒNG CHƠI")
	var r: Dictionary=host.progress.data.rpg
	var lines: PackedStringArray=[]
	for key in r.stage_attempts:
		lines.append("%s: %d lượt bắt đầu / %d lần thua" % [Campaign.label(int(key)),r.stage_attempts[key],r.stage_losses.get(key,0)])
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(50,290)
	scroll.size=Vector2(1180,320)
	add_child(scroll)
	var label:=Label.new()
	label.text="\n".join(lines) if not lines.is_empty() else "Chưa có lượt chơi."
	label.add_theme_font_size_override("font_size",22)
	scroll.add_child(label)
	text("%d trận kết thúc · %d thắng · %d ngày hoạt động\n%d lần nâng tướng · %d lần cường hóa · %d lượt triệu hồi · %d lượt quét" % [r.stats.runs,r.stats.wins,r.active_days.size(),r.stats.upgrades,r.stats.enhance,r.stats.summons,r.stats.sweeps],Vector2(50,150),Vector2(1180,100),24)
	footer("Chỉ lưu trên máy, không gửi mạng. Lượt bắt đầu chưa kết thúc có thể do thoát trận; chưa phải số liệu giữ chân cả cộng đồng.")
