extends CharacterBody3D

const walkSpeed: float = 4.0
const sprintSpeed: float = 6.0
const sprintLerpSpeed: float = 5.0
const jumpVelocity: float = 4.5
const yaw: float = 0.0005

const bobFrequency: float = 2.5
const bobAmplitude: float = 0.075
var bobTime: float = 0.0

var lateJumpTime: float = 0.15
var lateJumpTimer: float = 0.0
var speed: float = 5.0
var sprintAcceleration: float = 0.0
var sensitivity: float = 1.0

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity * yaw)
		camera.rotate_x(-event.relative.y * sensitivity * yaw)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90));

func headbob(time) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * bobFrequency) * bobAmplitude
	pos.x = cos(time * bobFrequency / 2) * bobAmplitude
	return pos

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		lateJumpTimer -= delta
	else:
		lateJumpTimer = lateJumpTime

	# Handle jump.
	if Input.is_action_just_pressed("jump") and lateJumpTimer > 0.0:
		velocity.y = jumpVelocity

	var inputDirection = Input.get_vector("left", "right", "forward", "backwards")

	# Handle sprinting
	var wantsToSprint: bool = Input.is_action_pressed("sprint") and inputDirection.y < 0
	if wantsToSprint:
		sprintAcceleration = lerp(sprintAcceleration, 1.0, delta * sprintLerpSpeed)
	else:
		sprintAcceleration = lerp(sprintAcceleration, 0.0, delta * sprintLerpSpeed)
	speed = lerp(walkSpeed, sprintSpeed, sprintAcceleration)

	# Handle movement
	var direction: Vector3 = (head.transform.basis * Vector3(inputDirection.x, 0, inputDirection.y)).normalized()
	if is_on_floor():
		if direction.length() > 0.0:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Apply friction instead of instant stop
			velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 5.0) 
	else:
		if direction.length() > 0.0:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0)
	# Handle headbob
	bobTime += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(bobTime)

	move_and_slide()
