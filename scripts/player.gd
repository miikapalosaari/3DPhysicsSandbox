extends CharacterBody3D

const yaw: float = 0.0005

var lateJumpTime: float = 0.15
var lateJumpTimer: float = 0.0
var sprintAcceleration: float = 0.0
var isCrouching: bool = false
var currentSpeed: float = 0.0
var currentColliderHeight: float
var currentEyeHeight: float
var bobTime: float = 0.0

@export var standingHeight: float = 2.0
@export var crouchingHeight: float = 1.0
@export var standingEyeHeight: float = 1.6
@export var crouchingEyeHeight: float = 0.8

@export var sprintTransitionSpeed: float = 5.0
@export var crouchTransitionSpeed: float = 5.0

@export var sprintSpeed: float = 6.0
@export var walkSpeed: float = 4.0
@export var crouchSpeed: float = 2.0
@export var jumpVelocity: float = 4.5

@export var sensitivity: float = 1.0

@export var bobFrequency: float = 2.5
@export var bobAmplitude: float = 0.075

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var bodyCollider = $BodyCollider
@onready var bodyCapsule: CapsuleShape3D = bodyCollider.shape

@onready var crosshair: Control = $Crosshair
@export var crosshairDotColor: Color = Color.WHITE
@export var crosshairDotRadius: float = 1.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	currentColliderHeight = standingHeight
	currentEyeHeight = standingEyeHeight
	bodyCapsule.height = standingHeight
	crosshair.setCrosshairDotColor(crosshairDotColor)
	crosshair.setCrosshairDotRadius(crosshairDotRadius)

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
		sprintAcceleration = lerp(sprintAcceleration, 1.0, delta * sprintTransitionSpeed)
	else:
		sprintAcceleration = lerp(sprintAcceleration, 0.0, delta * sprintTransitionSpeed)
	var baseSpeed = lerp(walkSpeed, sprintSpeed, sprintAcceleration)
	
	# Handle crouching
	var wantsToCrouch = Input.is_action_pressed("crouch")

	if is_on_floor():
		if wantsToCrouch:
			isCrouching = true
		else:
			# Only stand up if there is room above
			var remaining = standingHeight - currentColliderHeight
			var spaceCheck = !test_move(global_transform, Vector3.UP * remaining)
			if spaceCheck:
				isCrouching = false

	# Smooth camera + collider movement
	var targetEyeHeight: float = 0.0
	var targetColliderHeight: float = 0.0

	if isCrouching:
		targetEyeHeight = crouchingEyeHeight
		targetColliderHeight = crouchingHeight
	else:
		targetEyeHeight = standingEyeHeight
		targetColliderHeight = standingHeight

	currentColliderHeight = lerp(currentColliderHeight, targetColliderHeight, delta * crouchTransitionSpeed)
	bodyCapsule.height = currentColliderHeight
	bodyCollider.position.y = bodyCapsule.height * 0.5
	
	currentEyeHeight = lerp(currentEyeHeight, targetEyeHeight, delta * crouchTransitionSpeed)
	head.position.y = currentEyeHeight
	
	if isCrouching:
		currentSpeed = crouchSpeed
	else:
		currentSpeed = baseSpeed

	# Handle movement
	var direction: Vector3 = (head.transform.basis * Vector3(inputDirection.x, 0, inputDirection.y)).normalized()
	if is_on_floor():
		if direction.length() > 0.0:
			velocity.x = direction.x * currentSpeed
			velocity.z = direction.z * currentSpeed
		else:
			# Apply friction instead of instant stop
			velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 5.0) 
	else:
		if direction.length() > 0.0:
			velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * 5.0)
			velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * 5.0)
	# Handle headbob
	bobTime += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(bobTime)

	move_and_slide()
