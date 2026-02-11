extends Node

const objectMoveSpeed: float = 5.0
const objectThrowSpeed: float = 5.0

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

var playerHand: Marker3D

func _ready() -> void:
	match interactionType:
		InteractionType.HINGE:
			startingRotation = pivotPoint.rotation.x
			maximumRotation = deg_to_rad(rad_to_deg(startingRotation) + maximumRotation)

# Runs once, when player first clicks on an object to interact with
func preInteract(hand: Marker3D) -> void:
	isInteracting = true
	match interactionType:
		InteractionType.DEFAULT:
			playerHand = hand
		InteractionType.HINGE:
			lockCamera = true

# Runs every frame
func interact() -> void:
	if not canInteract:
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

func _input(event: InputEvent) -> void:
	if isInteracting:
		match interactionType:
			InteractionType.HINGE:
				if event is InputEventMouseMotion:
					if isFront:
						pivotPoint.rotate_y(-event.relative.y * 0.001)
					else:
						pivotPoint.rotate_y(event.relative.y * 0.001)
					
					pivotPoint.rotation.y = clamp(pivotPoint.rotation.y, startingRotation, maximumRotation)

func defaultInteract() -> void:
	var objectCurrentPosition: Vector3 = objectReference.global_transform.origin
	var playerHandposition: Vector3 = playerHand.global_transform.origin
	var objectDistance: Vector3 = playerHandposition - objectCurrentPosition
	
	var rigidBody3D: RigidBody3D = objectReference as RigidBody3D
	if rigidBody3D:
		# Heavier objects move slower than lighter objects
		rigidBody3D.set_linear_velocity((objectDistance) * (objectMoveSpeed / rigidBody3D.mass))

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

func setDirection(normal: Vector3) -> void:
	if normal.z > 0:
		isFront = true
	else:
		isFront = false
