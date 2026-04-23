extends Node

# ตัวรับผิดชอบเรื่องเสียงดนตรีพื้นหลัง
var bgm_player: AudioStreamPlayer
var tween: Tween
var current_bgm_track: AudioStream = null

## ความดังเป้าหมายของเพลง BGM (ยิ่งลบยิ่งเบา เช่น -40 เบากว่า -10)
@export var default_bgm_volume_db: float = -20.0

func _ready():
	# 1. แอบสร้างเครื่องเล่นแผ่นเสียง (AudioStreamPlayer) ฝังไว้ในตัวเองอัตโนมัติ 
	# (วิธีนี้ทำให้คุณไม่ต้องสร้าง Scene หรือลากโหนดอะไรเลยครับ)
	bgm_player = AudioStreamPlayer.new()
	
	# 2. ให้มันส่งเสียงออกลำโพง Master (ถ้าเบสิคๆ ก็ Master ได้เลยครับ)
	bgm_player.bus = "Master" 
	
	# 3. นำเข้าไปเป็นลูกของโหนดตัวเอง
	add_child(bgm_player)
	
	# 4. สั่งให้เล่นวนซ้ำทันทีเมื่อเพลงจบ 
	bgm_player.finished.connect(_loop_music_forever)

func _loop_music_forever():
	# ถ้าเป็นเพลงหลัก ให้กดเปิดเพลงอีกรอบเลย!
	if current_bgm_track:
		bgm_player.play()


# ฟังก์ชันหลักสำหรับเรียกใช้จากสคริปต์อื่นๆ ทั่วทั้งโปรเจกต์
# ตัวอย่าง: AudioManager.play_bgm(preload("res://music/battle.ogg"))
func play_bgm(stream: AudioStream, fade_duration: float = 1.0):
	# ถ้ากดเล่นเพลงเดิมซ้ำ เราจะไม่เปลี่ยนเพลง หรือเริ่มเพลงใหม่จาก 0 ครับ
	if current_bgm_track == stream and bgm_player.playing:
		return
		
	current_bgm_track = stream

	# ถ้าเคลียร์ Tween ตัวเก่าที่กำลัง Fade ยังไม่เสร็จ
	if tween and tween.is_valid():
		tween.kill()

	# ถ้าลำโพงกำลังเล่นเพลงฉากเก่าอยู่ เราจะจับมันหรี่เสียงเบาลง (Fade Out) ให้เนียนๆ ก่อน
	if bgm_player.playing and fade_duration > 0:
		tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE)
		
		# พอมัน Fade Out จบปุ๊บ ค่อยเรียกใช้ฟังก์ชันเริ่มเล่นเพลงใหม่
		tween.tween_callback(func(): _start_new_bgm(stream, fade_duration))
	else:
		# ถ้าเปิดเกมมาลำโพงว่างๆ อยู่ ก็เปิดเพลงใหม่ได้ทันทีเลย
		_start_new_bgm(stream, fade_duration)


# ฟังก์ชันเอาไว้เร่งเสียงเพลงขึ้นมา (Fade In)
func _start_new_bgm(stream: AudioStream, fade_duration: float):
	bgm_player.stream = stream
	bgm_player.play()
	
	var target_volume := default_bgm_volume_db
	
	if fade_duration > 0:
		bgm_player.volume_db = -80.0
		tween = create_tween()
		# เปลี่ยนจาก 0.0 เป็น target_volume
		tween.tween_property(bgm_player, "volume_db", target_volume, fade_duration).set_trans(Tween.TRANS_SINE)
	else:
		bgm_player.volume_db = target_volume

# ฟังก์ชันเผื่อเอาไว้ดับเพลงเฉยๆ 
func stop_bgm(fade_duration: float = 1.0):
	current_bgm_track = null
	
	if tween and tween.is_valid():
		tween.kill()
		
	if fade_duration > 0:
		tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(bgm_player.stop)
	else:
		bgm_player.stop()

# =========================================================
# ระบบเสียง Effect (SFX) ระดับโปร - เสก (Spawn) ตัวเล่นเสียงอัตโนมัติ
# =========================================================
func play_sfx(stream: AudioStream, randomize_pitch: bool = false, bus: String = "Master"):
	if not stream:
		return
		
	# 1. แอบสร้างเครื่องเล่นเสียงชั่วคราวขึ้นมา
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = bus
	
	# 2. ปรับ Pitch เล็กน้อยเพื่อไม่ให้เสียงซ้ำซากเกินไปถ้ายิงรัวๆ (จำลองความหลากหลาย)
	if randomize_pitch:
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		
	# 3. นำเข้าสู่ระบบ (Scene Tree) 
	add_child(sfx_player)
	
	# 4. สั่งเล่นเสียง
	sfx_player.play()
	
	# 5. ทริคสำคัญ (Garbage Collection): เมื่อเล่นจบ ให้จับเวลาแล้วระเบิดตัวนี้ทิ้งเพื่อคืนแรมให้เครื่อง!
	sfx_player.finished.connect(sfx_player.queue_free)
