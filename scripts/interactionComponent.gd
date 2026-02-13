extends Node

const objectMoveSpeed: float = 5.0
const objectThrowSpeed: float = 5.0
signal interactionEnded

enum InteractionType {
	DEFAULT,
	HINGE
}

@export var objectReference: Node3D
@export var interactionType: InteractionType = InteractionType.DEFAULT
@export var maximumRotation: float = 90
@export var pivotPoint: Node3D

var canInteract: bool = true
var isInteracting: bool = false
var lockCamera: bool = false
var isFront: bool = false
var startingRotation: float

var grabDistance: float = 0.0
var minDistance: float = 1.5
var maxDistance: float = 3.0
var targetGrabDistance: float = 0.0
var scrollLerpSpeed: float = 8.0

var initialRotation: Basis
var initialOffset: Vector3

var playerHand: Marker3D
var playerCamera: Camera3D

func _ready() -> void:
	match interactionType:
		InteractionType.HINGE:
			startingRotation = pivotPoint.rotation.x
			maximumRotation = deg_to_rad(rad_to_deg(startingRotation) + maximumRotation)

# Runs once, when player first clicks on an object to interact with
func preInteract(hand: Marker3D, camera: Camera3D) -> void:
	isInteracting = true
	playerHand = hand
	playerCamera = camera
	
	var rigidBody3D: RigidBody3D = objectReference as RigidBody3D
	if rigidBody3D:
		rigidBody3D.linear_velocity = Vector3.ZERO
		rigidBody3D.angular_velocity = Vector3.ZERO
		rigidBody3D.sleeping = false
	
	initialRotation = objectReference.global_transform.basis
	initialOffset = objectReference.global_transform.origin - playerHand.global_transform.origin
	
	grabDistance = playerCamera.global_transform.origin.distance_to(objectReference.global_transform.origin)
	targetGrabDistance = grabDistance
	
	match interactionType:
		InteractionType.HINGE:
			lockCamera = true

# Runs every frame
func interact() -> void:
	if not canInteract or not isInteracting:
		return
		
	match interactionType:
		InteractionType.DEFAULT:
			defaultInteract()

func auxilaryInteract() -> void:
	if not canInteract:
		return
		
	match interactionType:
		InteractionType.DEFAULT:
			defaultThrow()

# Runs once, when the player last interacts with an object
func postInteract() -> void:
	isInteracting = false
	lockCamera = false
	var rigidBody3D: RigidBody3D = objectReference as RigidBody3D
	if rigidBody3D:
		rigidBody3D.angular_velocity = Vector3.ZERO
		rigidBody3D.sleeping = false
		rigidBody3D.apply_impulse(Vector3.DOWN * 0.1)
		rigidBody3D.angular_damp = 0.0
	emit_signal("interactionEnded")

func _input(event: InputEvent) -> void:
	if isInteracting:
		match interactionType:
			InteractionType.DEFAULT:
				var rigidBody3D: RigidBody3D = objectReference as RigidBody3D
				if not rigidBody3D:
					return
				if event is InputEventMouseButton:
					var scrollSpeed: float =  0.4 / max(rigidBody3D.mass, 0.5)
					if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						targetGrabDistance = clamp(targetGrabDistance + scrollSpeed, minDistance, maxDistance)
					elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						targetGrabDistance = clamp(targetGrabDistance - scrollSpeed, minDistance, maxDistance)
			
			InteractionType.HINGE:
				if event is InputEventMouseMotion:
					if isFront:
						pivotPoint.rotate_y(-event.relative.y * 0.001)
					else:
						pivotPoint.rotate_y(event.relative.y * 0.001)
					
					pivotPoint.rotation.y = clamp(pivotPoint.rotation.y, startingRotation, maximumRotation)

func defaultInteract() -> void:
	var rigidBody3D: RigidBody3D = objectReference as RigidBody3D
	if not rigidBody3D:
		return
		
	rigidBody3D.angular_damp = 5.0
	
	grabDistance = lerp(grabDistance, targetGrabDistance, scrollLerpSpeed * get_process_delta_time())
	var targetPosition: Vector3 = playerCamera.global_transform.origin + playerCamera.global_transform.basis.z * -grabDistance
	var objectCurrentPosition: Vector3 = rigidBody3D.global_transform.origin
	var objectDistance: Vector3 = targetPosition - objectCurrentPosition
	
	if objectDistance.length() > grabDistance + 1.0:
		postInteract()
		return

	var stiffness: float = 40.0
	var friction: float = 12.0
	var force: Vector3 = objectDistance * stiffness - rigidBody3D.linear_velocity * friction

	rigidBody3D.apply_central_force(force)
	rigidBody3D.sleeping = false
	var isColliding: bool = rigidBody3D.get_contact_count() > 0
	if not isColliding:
		# Smoothly restore rotation
		var currentBasis = rigidBody3D.global_transform.basis
		var targetBasis = initialRotation

		# Rotation difference
		var qCurrent = currentBasis.get_rotation_quaternion()
		var qTarget = targetBasis.get_rotation_quaternion()
		var qDelta = qCurrent.inverse() * qTarget

		var axis = qDelta.get_axis()
		var angle = qDelta.get_angle()

		var mass = rigidBody3D.mass
		var kp = 8.0 / mass
		var kd = 1.5 / mass

		var torque = axis * angle * kp - rigidBody3D.angular_velocity * kd
		rigidBody3D.apply_torque(torque)


func defaultThrow() -> void:
	var objectCurrentPosition: Vector3 = objectReference.global_transform.origin
	var playerHandposition: Vector3 = playerHand.global_transform.origin
	var objectDistance: Vector3 = playerHandposition - objectCurrentPosition
	
	var rigidBody3D: RigidBody3D = objectReference as RigidBody3D
	if rigidBody3D:
		var throwDirection: Vector3 = -playerHand.global_transform.basis.z.normalized()
		var throwStrength: float = objectThrowSpeed / rigidBody3D.mass
		rigidBody3D.set_linear_velocity(throwDirection * throwStrength)
		canInteract = false
		await get_tree().create_timer(1.0).timeout
		canInteract = true
	postInteract()

func setDirection(normal: Vector3) -> void:
	if normal.z > 0:
		isFront = true
	else:
		isFront = false
