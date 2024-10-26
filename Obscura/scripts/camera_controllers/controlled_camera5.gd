class_name ControlledCamera5
extends CameraControllerBase

# The ratio that the camera should move toward the target when it is not at the edge of the outer pushbox.
@export var push_ratio: float = 0.5
# the top left corner of the push zone border box.
@export var pushbox_top_left: Vector2 = Vector2(-20, 20)
# the bottom right corner of the push zone border box.
@export var pushbox_bottom_right: Vector2 = Vector2(20, -20)
# the top left corner of the inner border of the speedup zone.
@export var speedup_zone_top_left: Vector2 = Vector2(-10, 10)
# the bottom right cordner of the inner boarder of the speedup zone
@export var speedup_zone_bottom_right: Vector2 = Vector2(10, -10)


func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
	
	var target_velocity = target.velocity
	var target_position = target.position
	var camera_movement = Vector3(0,0,0)
	var push_left = position.x + pushbox_top_left.x
	var push_right = position.x + pushbox_bottom_right.x
	var push_top = position.z + pushbox_top_left.y
	var push_bottom = position.z + pushbox_bottom_right.y
	var speed_left = position.x + speedup_zone_top_left.x
	var speed_right = position.x + speedup_zone_bottom_right.x
	var speed_top = position.z + speedup_zone_top_left.y
	var speed_bottom = position.z + speedup_zone_bottom_right.y
	
	# target moving
	if target_velocity != Vector3(0,0,0):
		if target_position.x > speed_left and target_position.x < speed_right and target_position.z < speed_top and target_position.z > speed_bottom:
			# target is inside speedup zone
			camera_movement = Vector3(0,0,0)
		else:
			# target is touching left or right side of push box
			camera_movement.x = target_velocity.x * (1 if target.position.x <= push_left or target.position.x >= push_right else push_ratio)
			# target is touching top or down side of push box
			camera_movement.z = target_velocity.z * (1 if target.position.z >= push_top or target.position.z <= push_bottom else push_ratio)

	position += camera_movement * delta
	
	super(delta)

# helper function to draw outer and inner boxes
func draw_box(immediate_mesh: ImmediateMesh, material:ORMMaterial3D, top_left: Vector2, bottom_right: Vector2) -> void:
	var left = top_left.x
	var right = bottom_right.x
	var top = top_left.y
	var bottom = bottom_right.y
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_end()
		

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# draw push box
	draw_box(immediate_mesh, material, pushbox_top_left, pushbox_bottom_right)
	# draw speedup zone
	draw_box(immediate_mesh, material, speedup_zone_top_left, speedup_zone_bottom_right)

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
