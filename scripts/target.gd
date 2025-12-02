extends CSGBox3D

var hits = 0
var max_hits = 3
var is_destroyed = false

# Visual feedback
var original_color = Color(0.8, 0.2, 0.2)
var hit_color = Color(1.0, 1.0, 0.0)

func _ready():
	# Set initial color
	var material = StandardMaterial3D.new()
	material.albedo_color = original_color
	set_material_override(material)
	
	# Add collision
	use_collision = true

func hit(hit_position: Vector3):
	if is_destroyed:
		return
		
	hits += 1
	print("Target hit! Count: ", hits, "/", max_hits)
	
	# Visual feedback
	_flash_hit()
	
	# Scale down slightly
	var new_scale = scale * 0.9
	var tween = create_tween()
	tween.tween_property(self, "scale", new_scale, 0.1)
	
	if hits >= max_hits:
		_destroy()

func _flash_hit():
	# Flash yellow on hit
	var material = get_material_override() as StandardMaterial3D
	if material:
		material.albedo_color = hit_color
		await get_tree().create_timer(0.1).timeout
		material.albedo_color = original_color

func _destroy():
	is_destroyed = true
	print("Target destroyed!")
	
	# Destroy animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_property(self, "rotation", rotation + Vector3(0, PI * 2, 0), 0.3)
	
	await tween.finished
	
	# Respawn after delay
	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn():
	print("Target respawning...")
	hits = 0
	is_destroyed = false
	scale = Vector3.ONE
	rotation = Vector3.ZERO
	
	var material = get_material_override() as StandardMaterial3D
	if material:
		material.albedo_color = original_color