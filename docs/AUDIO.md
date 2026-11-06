# Âm thanh 0.2
Năm WAV hit/skill/wave/win/lose được tổng hợp mới bằng tools/generate_audio.py,
Python standard library, seed cố định, PCM16 mono22050Hz; không sample bên thứ ba,
API, token hoặc chi phí dịch vụ. Tái tạo: python3 tools/generate_audio.py.
Vai trò: chạm đòn, kiếm khí, bắt đầu đợt, thắng, thua. Toàn bộ là âm thử chưa nghe duyệt.

Bốn voice, bỏ cue khi đầy; hit cooldown100ms; SFX -14dB, Master -6dB. Bus
Music/SFX/UI đã tạo, hiện chỉ có SFX; chưa nhạc, limiter, duck hoặc ưu tiên cướp voice.
Nút bật/tắt Master lưu user://audio.cfg. Background dừng voice, không phát bù.
Tính năng mixer nâng cao thuộc mốc hoàn thiện, chưa coi tương đương Game-2.5D.
Chưa đo mix hoặc nghe loa/tai nghe S23. Headless/Dummy không phải nghe duyệt.
Repo chưa có giấy phép phát hành chung; chủ repo quyết định điều khoản.
