extends CharacterBody3D

@onready var camera_mount = $ThirdPersonCamera
@onready var visuals = $visuals
@onready var animation_player = $visuals/mixamo_base/AnimationPlayer


var SPEED = 3.0
const JUMP_VELOCITY = 4.5

var walking_speed = 3.0
var running_speed = 5.0

var running = false

@export_group("Camera Zoom")
## Default distance to set the camera from the player.
@export var camera_default_distance := 2.0
## Maximum distance the camera can zoom out to.
@export var camera_distance_max := 4.0
## Mininum distance the camera can zoom in to.
@export var camera_distance_min := 0.01
## How far the camera will move per zoom input.
@export var camera_zoom_step := 0.2
## How quickly the camera zoom interpolates.
@export var camera_lerp_speed := 5.0

## Toggles camera processing. Setting this to false will lock the camera controls.
var enabled: bool = true:
	set(new_enabled):
		if new_enabled != enabled:
			enabled = new_enabled
			set_process(enabled)

# Variable for handling smooth zooming.
var _spring_arm_target_length := camera_default_distance

## The camera [SpringArm3D], which prevents the camera passing through objects.
@onready var spring_arm := $ThirdPersonCamera/SpringArm3D as SpringArm3D
## The main player [Camera3D].
@onready var cam := $ThirdPersonCamera/SpringArm3D/Camera3D as Camera3D



@onready var thirdPersonCamera := $ThirdPersonCamera/SpringArm3D/Camera3D as Camera3D
@onready var firstPersonCamera := $FirstPersonCamera/Camera3D as Camera3D
var currentCamera : Camera3D

var is_locked = false

@export var sens_horizontal = 0.5
@export var sens_vertical = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.spring_length = camera_default_distance
	
	currentCamera = thirdPersonCamera
	thirdPersonCamera.make_current()
	

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if currentCamera == thirdPersonCamera:
				_spring_arm_target_length -= camera_zoom_step
				_spring_arm_target_length = clamp(_spring_arm_target_length, camera_distance_min, camera_distance_max)
				
				if _spring_arm_target_length == 0.01:
					switch_camera()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if currentCamera == firstPersonCamera:
				switch_camera()
			if currentCamera == thirdPersonCamera:
				_spring_arm_target_length += camera_zoom_step
				_spring_arm_target_length = clamp(_spring_arm_target_length, camera_distance_min, camera_distance_max)
				

func _physics_process(delta):
	
	# Handle smooth camera zooming.
	if _spring_arm_target_length != spring_arm.spring_length:
		spring_arm.spring_length = lerp(spring_arm.spring_length, _spring_arm_target_length, camera_lerp_speed * delta)
		
	
		#print("Zoom To First Person Here")
	
	if !animation_player.is_playing():
		is_locked = false
	
	if Input.is_action_just_pressed("kick"):
		if is_on_floor():
			if animation_player.current_animation != "kick":
				is_locked = true
				animation_player.play("kick")
	
	if Input.is_action_pressed("run"):
		SPEED = running_speed
		running = true
	else:
		SPEED = walking_speed
		running = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if !is_locked:
			if running:
				if animation_player.current_animation != "running":
					animation_player.play("running")
			else:
				if animation_player.current_animation != "walking":
					animation_player.play("walking")
			
			visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-input_dir.x, -input_dir.y), .25)
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		if !is_locked:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
		
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if !is_locked:
		move_and_slide()

func switch_camera():
	# Toggle between third-person and first-person cameras
	if currentCamera == thirdPersonCamera:
		currentCamera = firstPersonCamera
		firstPersonCamera.make_current()
		
	else:
		currentCamera = thirdPersonCamera
		thirdPersonCamera.make_current()
