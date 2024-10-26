class_name ControlledCamera2
extends CameraControllerBase

@export var top_left: Vector2 = Vector2(-10, 10)
@export var bottom_right: Vector2 = Vector2(10, -10)
@export var autoscroll_speed: Vector3 = Vector3(5, 0, 5)


func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		return
	
	if draw_camera_logic:
		draw_logic()
	
	position += Vector3(autoscroll_speed.x*delta, 0, autoscroll_speed.z * delta)
	
	var left_edge = position.x + top_left.x
	var right_edge = position.x + bottom_right.x
	var top_edge = position.z + top_left.y
	var bottom_edge = position.z + bottom_right.y
	
	if target.position.x < left_edge:
		target.position.x = left_edge
	if target.position.x > right_edge:
		target.position.x = right_edge
	if target.position.z > top_edge:
		target.position.z = top_edge
	if target.position.z < bottom_edge:
		target.position.z = bottom_edge
	
	super(delta)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
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

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
