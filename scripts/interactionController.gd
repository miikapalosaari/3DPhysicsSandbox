extends Node

@onready var interactionController = %InteractionController
@onready var interactionRaycast = %InteractionRaycast
@onready var playerCamera = %PlayerCamera3D
@onready var hand = %Hand

var currentObject: Object
var lastPotentialObject: Object
var interactionComponent: Node

func _ready():
	print("Interaction script attached")

func _process(delta: float) -> void:
	# If on the previous frame, there were interaction with an object, lets keep interacting with it.
	if currentObject:
		if Input.is_action_just_pressed("secondary"):
			if interactionComponent:
				interactionComponent.auxilaryInteract()
				currentObject = null
		elif Input.is_action_pressed("primary"):
			if interactionComponent:
				interactionComponent.interact()
		else:
			if interactionComponent:
				interactionComponent.postInteract()
				currentObject = null
	# If not interacting with something, lets see if its now possible.
	else:
		var potentialObject: Object = interactionRaycast.get_collider()
		
		if potentialObject and potentialObject is Node:
			interactionComponent = potentialObject.get_node_or_null("InteractionComponent")
			if interactionComponent:
				if interactionComponent.canInteract == false:
					return
					
				lastPotentialObject = currentObject
				
				if Input.is_action_pressed("primary"):
					currentObject = potentialObject
					interactionComponent.preInteract(hand)
					
					if interactionComponent.interactionType == interactionComponent.InteractionType.HINGE:
						interactionComponent.setDirection(currentObject.to_local(interactionRaycast.get_collision_point()))

func isCameraLocked() -> bool:
	if interactionComponent:
		if interactionComponent.lockCamera and interactionComponent.isInteracting:
			return true
	return false
