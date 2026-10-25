extends Node3D

const SPEED := 7.0
const BOT_SPEED := 3.5
var hero: Node3D
var bot: Node3D
var cam: Camera3D
var hero_hp := 100
var bot_hp := 100
var attack_cd := 0.0
var skill_cd := 0.0
var bot_cd := 0.0
var game_over := false
var touch_id := -1
var touch_origin := Vector2.ZERO
var move_axis := Vector2.ZERO
var hp_label: Label
var result_label: Label
var skill_button: Button

func _ready() -> void:
    _make_arena()
    _make_hud()

func _block(label: String, position_: Vector3, dimensions: Vector3, tint: Color) -> Node3D:
    var root := Node3D.new()
    root.name = label
    root.position = position_
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    visual.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    visual.material_override = mat
    root.add_child(visual)
    add_child(root)
    return root

func _make_arena() -> void:
    _block("Arena", Vector3(0, -0.25, 0), Vector3(32, 0.5, 32), Color("#355d4c"))
    for n in [-16.0, 16.0]:
        _block("BorderX", Vector3(n, 1, 0), Vector3(0.6, 2, 32), Color("#70857a"))
        _block("BorderZ", Vector3(0, 1, n), Vector3(32, 2, 0.6), Color("#70857a"))
    _block("BlueTower", Vector3(-11, 1.5, -11), Vector3(2, 3, 2), Color("#2ea5d9"))
    _block("RedTower", Vector3(11, 1.5, 11), Vector3(2, 3, 2), Color("#d95758"))
    hero = _block("Hero", Vector3(-5, 1, 0), Vector3(1.3, 2, 1.3), Color("#32c6f4"))
    bot = _block("Bot", Vector3(6, 1, 0), Vector3(1.3, 2, 1.3), Color("#ee6268"))
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -35, 0)
    add_child(sun)
    var sky := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#8eaeb8")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#c7d7d9")
    sky.environment = env
    add_child(sky)
    cam = Camera3D.new()
    cam.current = true
    add_child(cam)
    _camera()

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_PASS
    layer.add_child(ui)
    hp_label = Label.new()
    hp_label.position = Vector2(22, 20)
    hp_label.add_theme_font_size_override("font_size", 26)
    ui.add_child(hp_label)
    result_label = Label.new()
    result_label.position = Vector2(460, 22)
    result_label.add_theme_font_size_override("font_size", 32)
    ui.add_child(result_label)
    var hint := Label.new()
    hint.text = "MOVE: touch left side / arrows"
    hint.position = Vector2(22, 75)
    ui.add_child(hint)
    var attack := Button.new()
    attack.text = "ATTACK"
    attack.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    attack.offset_left = -185
    attack.offset_top = -150
    attack.offset_right = -20
    attack.offset_bottom = -55
    attack.pressed.connect(_attack)
    ui.add_child(attack)
    skill_button = Button.new()
    skill_button.text = "SKILL"
    skill_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    skill_button.offset_left = -365
    skill_button.offset_top = -140
    skill_button.offset_right = -200
    skill_button.offset_bottom = -55
    skill_button.pressed.connect(_skill)
    ui.add_child(skill_button)
    var restart := Button.new()
    restart.text = "RESTART"
    restart.position = Vector2(22, 112)
    restart.pressed.connect(func() -> void: get_tree().reload_current_scene())
    ui.add_child(restart)
    _labels()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and touch_id == -1:
            touch_id = event.index
            touch_origin = event.position
            move_axis = Vector2.ZERO
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            move_axis = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == touch_id:
        move_axis = (event.position - touch_origin).limit_length(90.0) / 90.0

func _process(delta: float) -> void:
    if game_over:
        return
    attack_cd = maxf(0.0, attack_cd - delta)
    skill_cd = maxf(0.0, skill_cd - delta)
    bot_cd = maxf(0.0, bot_cd - delta)
    var axis := move_axis
    if axis.length_squared() < 0.01:
        axis = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    hero.position += Vector3(axis.x, 0, axis.y) * SPEED * delta
    hero.position.x = clampf(hero.position.x, -14.5, 14.5)
    hero.position.z = clampf(hero.position.z, -14.5, 14.5)
    var distance := bot.position.distance_to(hero.position)
    if distance > 2.1:
        bot.position += (hero.position - bot.position).normalized() * BOT_SPEED * delta
    elif bot_cd <= 0.0:
        hero_hp -= 9
        bot_cd = 1.1
    _camera()
    if hero_hp <= 0 or bot_hp <= 0:
        game_over = true
    _labels()

func _attack() -> void:
    if game_over or attack_cd > 0.0:
        return
    attack_cd = 0.65
    if hero.position.distance_to(bot.position) < 3.2:
        bot_hp -= 15

func _skill() -> void:
    if game_over or skill_cd > 0.0:
        return
    skill_cd = 4.0
    if hero.position.distance_to(bot.position) < 6.0:
        bot_hp -= 30

func _camera() -> void:
    cam.position = hero.position + Vector3(0, 19, 17)
    cam.look_at(hero.position, Vector3.UP)

func _labels() -> void:
    hp_label.text = "HERO %d HP  |  BOT %d HP" % [maxi(hero_hp, 0), maxi(bot_hp, 0)]
    result_label.text = "DEFEAT" if hero_hp <= 0 else ("VICTORY" if bot_hp <= 0 else "1v1 OFFLINE")
    skill_button.text = "SKILL %.1f" % skill_cd if skill_cd > 0.0 else "SKILL"
