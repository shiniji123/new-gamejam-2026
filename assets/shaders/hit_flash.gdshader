// ============================================================
// hit_flash.gdshader — Shader สำหรับเอฟเฟกต์ Flash เมื่อโดนโจมตี
// ============================================================
// ใช้โดยการตั้ง flash_intensity เป็น 1.0 เพื่อให้ sprite กลายเป็นสีขาว
// แล้วค่อยๆ ลดกลับเป็น 0.0 เพื่อกลับเป็นปกติ
// ============================================================
shader_type canvas_item;

// ความเข้มของ flash (0.0 = ปกติ, 1.0 = flash เต็มที่)
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
// สีของ flash (ค่าเริ่มต้น = ขาว)
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// ดึงสีเดิมจาก texture
	vec4 original_color = texture(TEXTURE, UV);
	// ผสมสีเดิมกับสี flash ตามค่า intensity
	// เก็บ alpha เดิมไว้เพื่อไม่ให้พื้นที่โปร่งใสถูก flash
	COLOR = vec4(
		mix(original_color.rgb, flash_color.rgb, flash_intensity),
		original_color.a
	);
}
