# KẾ HOẠCH DỰ ÁN & TÀI LIỆU BÁO CÁO: LẠC THẦN (2D METROIDVANIA)

Dưới đây là các thông tin chi tiết được trích xuất và chuẩn hóa để bạn đưa vào báo cáo môn học, cũng như làm kim chỉ nam để code tiếp.

---

## 1. ƯU TIÊN TRẢ LỜI (DÀNH CHO BÁO CÁO)

### 1.1. Cấu trúc Scene Tree của các thực thể chính
Dưới đây là cấu trúc Node Tree chuẩn mực trong Godot mà game đang sử dụng (và hướng tới):

**A. Character Controller (Cọi - Player)**
```text
Player (CharacterBody2D)
├── AnimatedSprite2D (Sprite và các hoạt ảnh Idle, Run, Jump...)
├── CollisionShape2D (Hitbox vật lý va chạm với môi trường)
├── Raycasts (Node2D)
│   ├── left_ray (RayCast2D - Check bám tường trái)
│   └── right_ray (RayCast2D - Check bám tường phải)
├── SwordHitbox (Area2D - Kích hoạt khi chém để gây sát thương)
│   └── CollisionShape2D
└── PlayerHurtbox (Area2D - Vùng nhận sát thương từ quái)
    └── CollisionShape2D
```

**B. Enemy (Quái thường: Sâu / Bọ)**
```text
BaseEnemy (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D (Va chạm môi trường)
├── RayCast_Floor (RayCast2D - Phát hiện mép vực để quay đầu)
├── RayCast_Wall (RayCast2D - Phát hiện tường chắn để quay đầu)
├── EnemyHitbox (Area2D - Gây sát thương khi chạm vào Player)
│   └── CollisionShape2D
├── EnemyHurtbox (Area2D - Nhận sát thương từ Sword của Player)
│   └── CollisionShape2D
└── AggroArea (Area2D - Tầm nhìn phát hiện Player, dành cho Bọ)
    └── CollisionShape2D
```

**C. Boss**
```text
Boss (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D 
├── BossHitbox (Area2D - Vùng gây sát thương va chạm)
│   └── CollisionShape2D
├── BossHurtbox (Area2D - Nhận sát thương)
│   └── CollisionShape2D
├── DashTimer (Timer - Thời gian hồi chiêu Dash Attack)
└── PoisonSpitMarkers (Node2D - Chứa các Marker2D định vị chỗ phun độc)
```

### 1.2. Thông tin về Save System
**Quyết định:** Sử dụng **JSON** (thông qua `FileAccess` của Godot).
**Lý do để báo cáo:** 
- JSON lưu trữ dưới dạng văn bản thuần (plain text), rất trực quan, dễ dàng mở file ra để đọc, debug và chỉnh sửa thông số (như Máu, Tiền, Tọa độ Save Point) trong quá trình phát triển Prototype.
- Đối với cấu trúc game hiện tại (chủ yếu lưu các biến từ Singleton `GameManager`), JSON cung cấp sự linh hoạt và gọn nhẹ, tốc độ đọc ghi hoàn toàn đáp ứng được nhu cầu mà không cần sự phức tạp của Resource Saver.

---

## 2. TRẢ LỜI CÁC CÂU HỎI CHI TIẾT TRONG BÁO CÁO

### 2.1. Cấu trúc State Machine (Máy trạng thái)
Do thời gian có hạn, việc tạo từng Node riêng biệt cho State Machine khá phức tạp. Lựa chọn tối ưu và phổ biến nhất là sử dụng biến `enum` kết hợp cấu trúc `match/case` trong script.

**Cách đặt tên trạng thái (Enum) cho Báo cáo:**
```gdscript
enum PlayerState {
    IDLE,
    RUN,
    JUMP,
    FALL,
    WALL_SLIDE,
    DASH,
    ATTACK,
    HEAL,
    DEAD
}
var current_state = PlayerState.IDLE
```

### 2.2. Hàm di chuyển và Cơ chế vật lý (Physics)
Sử dụng hàm tích hợp `_physics_process(delta)` kết hợp với `move_and_slide()` của `CharacterBody2D`.

**Code mẫu cho báo cáo (Coyote Time & Jump Buffer):**
Đây là 2 cơ chế giúp game platformer "dễ thở" và mượt mà hơn.
```gdscript
# Khai báo biến
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
const COYOTE_TIME = 0.15 # Thời gian cho phép nhảy sau khi rớt khỏi mép
const JUMP_BUFFER_TIME = 0.1 # Lưu phím nhảy bấm sớm

func _physics_process(delta):
    # 1. Logic Coyote Time
    if is_on_floor():
        coyote_timer = COYOTE_TIME
    else:
        coyote_timer -= delta

    # 2. Logic Jump Buffer
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = JUMP_BUFFER_TIME
    else:
        jump_buffer_timer -= delta

    # 3. Thực hiện nhảy nếu cả 2 điều kiện đều thỏa mãn
    if jump_buffer_timer > 0 and coyote_timer > 0:
        velocity.y = -jump_force
        jump_buffer_timer = 0.0 # Reset buffer
        coyote_timer = 0.0      # Reset coyote
```

### 2.3. Sơ đồ Communication Diagram
**Câu hỏi:** Sơ đồ Communication Diagram mà bạn đề xuất có phù hợp không? Có cần làm lại không?
**Trả lời:** Sơ đồ này **RẤT PHÙ HỢP** và cực kỳ chuẩn xác với hệ thống của Godot (sử dụng Area2D và Signals). **Bạn KHÔNG CẦN phải vẽ lại sơ đồ khác**. Sơ đồ này giải thích hoàn hảo luồng tín hiệu khi Player chém trúng Enemy:
1. `PlayerController` nhận input tấn công -> Chuyển animation tấn công.
2. Tại frame chém, bật `CollisionShape2D` của `Weapon Hitbox`.
3. Khi Hitbox chạm vào `Hurtbox` của Enemy, Godot phát Signal `area_entered`.
4. Signal gọi hàm trừ máu và bật hiệu ứng giật lùi (knockback/flinch) trên Enemy.

---

## 3. LỘ TRÌNH CODE TIẾP THEO (DÀNH CHO BẠN)
Dựa theo tình trạng dự án ("Chưa làm", "Lỗi"), đây là thứ tự ưu tiên tớ sẽ giúp bạn làm để kịp ra Demo:

1. **Khắc phục triệt để Lỗi Player (Refactor nhẹ):**
   - Đưa hệ thống Enum State Machine vào `player_controller.gd` thay vì dùng quá nhiều biến boolean rời rạc (`is_dasing`, `is_attacking`...). Điều này sẽ sửa dứt điểm các lỗi xung đột Animation.
2. **Hoàn thiện Quái cơ bản & Area2D Combat:**
   - Setup chuẩn Hitbox/Hurtbox cho Cọi và Sâu. Đảm bảo chém trúng Sâu thì Sâu mất máu, Sâu chạm vào Cọi thì Cọi mất máu (`Globals.health -= 1`).
3. **Healing & UI:**
   - Bơm linh hồn (Soul) vào UI. Ấn `A` sẽ trừ Soul và cộng Health (Đã code ở hàm `healing()` nhưng cần gắn với UI).
4. **GameManager & Save/Load JSON:**
   - Viết Autoload GameManager. Bấm Save sẽ ghi file `save.json` chứa `{"hp": 5, "soul": 1.0, "coins": 100, "current_level": "level_1"}`. Bấm Load sẽ đọc lên.
5. **Level Transition (Chuyển cảnh):**
   - Scene Transition đen màn hình Fade In/Out khi đi qua cửa. Mở khóa Level 2.
6. **Boss Fight (Giai đoạn cuối):**
   - Viết AI đơn giản: Boss chỉ lướt trái phải (Dash Attack). Mất máu xuống 50% thì nhảy vào giữa map spam độc.
