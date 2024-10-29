class_name ControlledCamera3
extends CameraControllerBase


# The speed at which the camera follows the player when the player is moving. This can either be a tuned static value or a ratio of the vessel's speed.
@export var follow_speed: float = 40
# When the player has stopped, what speed shoud the camera move to match the vesse's position.
@export var catchup_speed: float = 80
# The maxiumum allowed distance between the vessel and the center of the camera.
@export var leash_distance: float = 15


func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
		
	var target_position = Vector3(target.global_position.x, position.y, target.global_position.z)
	var distance = position.distance_to(target_position)
	
	if distance > leash_distance + 0.1: # add tolerance to prevent glitching
		# the distance between the vessel and the camera should never exceed leash_distance.
		position += (target_position - position).normalized() * (distance - leash_distance)
	elif distance > 0:
		if target.velocity != Vector3(0,0,0):
			# follow the player at a follow_speed that is slower than the player 
			if follow_speed * delta >= distance:
				# set to target position if too close
				position = target_position
			else:
				position += (target_position - position).normalized() * follow_speed * delta
		else:
			# The camera will catch up when the player is not moving
			if catchup_speed * delta >= distance:
				# set to target position if too close
				position = target_position
			else:
				position += (target_position - position).normalized() * catchup_speed * delta

	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# draw a 5 by 5 unit cross in the center of the screen
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(0, 0, 2.5))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, -2.5))
	immediate_mesh.surface_add_vertex(Vector3(2.5, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(-2.5, 0, 0))
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
