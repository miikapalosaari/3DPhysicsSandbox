extends Node

const objectMoveSpeed: float = 5.0
const objectThrowSpeed: float = 5.0

enum InteractionType {
	DEFAULT
}

@export var objectReference: Node3D
@export var interactionType: InteractionType = InteractionType.DEFAULT

var canInteract: bool = true
var isInteracting: bool = false

var playerHand: Marker3D

func _ready() -> void:
	pass

# Runs once, when player first clicks on an object to interact with
func preInteract(hand: Marker3D) -> void:
	isInteracting = true
	match interactionType:
		InteractionType.DEFAULT:
			playerHand = hand

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

func _input(event: InputEvent) -> void:
	pass

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
