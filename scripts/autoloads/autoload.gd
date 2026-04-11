extends Node

var current_state:State = State.EXPLORE
enum State { EXPLORE, COMBAT }

var coin:int = 0

# --- ตัวแปรสำหรับร้านค้าค้า (Shop Upgrades) ---
var damage_bonus: float = 0.0      # +25% ต่อการซื้อ 1 ครั้ง (0.25, 0.50...)
var multishot_level: int = 0       # ยิงเพิ่มกี่นัด (0=นัดเดียว, 1=สองนัดพร้อมกัน...)
var max_hp_bonus: float = 0.0      # HP โบนัสสำหรับตัวละครผู้เล่น

# ตัวแปรจำเลือดปัจจุบัน ไม่ให้เลือดเด้งเต็มหลอดเวลาเปลี่ยนฉาก! (-1 คือตอนเริ่มเกม)
var player_current_hp: float = -1.0 
# ---------------------------------------------
