class_name ControlledCamera4
extends CameraControllerBase


# the speed at which the camera moves toward the direction of the input. This should be faster than the Vessel's movement speed. 
# note this is dynamic and changes based on the target's movement speed
@export var lead_speed: float = 60
# the time delay between when the target stops moving and when the camera starts to catch up to the target.
@export var catchup_delay_duration: float = 0.1
# When the player has stopped, what speed shoud the camera move to match the vesse's position.
@export var catchup_speed: float = 60
# The maxiumum allowed distance between the vessel and the center of the camera.
@export var leash_distance: float = 15

var last_moved: float = 0.0

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

	if target.velocity != Vector3(0,0,0):
		# target is moving, reset last_moved
		last_moved = 0.0
		# move within leash_distance
		var lead_position = target_position + target.velocity.normalized() * leash_distance
		if distance > leash_distance + 0.5: # add tolerance to prevent glitching
			position = target_position + (position - lead_position).normalized() * leash_distance
		# change lead_speed to be always faster than the target
		lead_speed = target.velocity.length() * 1.2
		# move to lead position with the maximum of lead_speed or target's velocity plus 10, so the camera is always ahead
		position += (lead_position - position).normalized() * lead_speed * delta
	else:
		# increment last_moved
		last_moved += delta
		# camera catchup to target
		if last_moved >= catchup_delay_duration and distance > 0:
			if catchup_speed * delta >= distance:
				# set to target position if too close
				position = target_position
			else:
				position += (target_position - position).normalized() * (catchup_speed * delta)

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
