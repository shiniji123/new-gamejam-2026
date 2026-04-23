extends Node
## ===================================================
## Autoload — Global Game State (Singleton)
## ===================================================
## รับผิดชอบ: สถานะเกม (EXPLORE/COMBAT) และเลือดผู้เล่นที่ต้องคงไว้ข้ามฉาก
##
## ⚠️  ไม่ใช่ที่สำหรับเก็บค่า stat หรือ upgrade ของผู้เล่น
##     ทุกอย่างที่เกี่ยวกับ run-economy ให้ไปที่ RunManager ครับ

## ===== GAME STATE MACHINE =====
enum State { EXPLORE, COMBAT }
var current_state: State = State.EXPLORE

## ===== PLAYER PERSISTENCE (ข้ามฉาก) =====
## เลือดปัจจุบันของผู้เล่น — บันทึกทุกครั้งที่โดนตีหรือซื้ออัปเกรด
## ค่า -1.0 = ยังไม่ได้ตั้งค่า (จะเติมเต็มเมื่อโหลดตัวละครครั้งแรก)
var player_current_hp: float = -1.0
