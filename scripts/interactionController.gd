extends Node

@onready var interactionController = %InteractionController
@onready var interactionRaycast = %InteractionRaycast
@onready var playerCamera = %PlayerCamera3D
@onready var hand = %Hand

var currentObject: Object = null
var lastPotentialObject: Object = null
var interactionComponent: Node = null

func _ready():
	print("Interaction script attached")

func _process(delta: float) -> void:
	# If on the previous frame, there were interaction with an object, lets keep interacting with it.
	if currentObject:
		if Input.is_action_just_pressed("secondary"):
			if interactionComponent:
				interactionComponent.auxilaryInteract()
				return
		if Input.is_action_pressed("primary"):
			if interactionComponent:
				interactionComponent.interact()
				return
			
			interactionComponent.postInteract()
			return
			
	# If not interacting with something, lets see if its now possible.
	var potentialObject: Object = interactionRaycast.get_collider()
	if potentialObject and potentialObject is Node:
		var component = potentialObject.get_node_or_null("InteractionComponent")
		if component and component.canInteract:
			if Input.is_action_just_pressed("primary"):
				currentObject = potentialObject
				interactionComponent = component
				
				component.interactionEnded.connect(onInteractionEnded)
				component.preInteract(hand, playerCamera)
				
				if component.interactionType == component.InteractionType.HINGE:
					component.setDirection(currentObject.to_local(interactionRaycast.get_collision_point()))

func onInteractionEnded():
	if interactionComponent:
		interactionComponent.interactionEnded.disconnect(onInteractionEnded)

	currentObject = null
	interactionComponent = null

func isCameraLocked() -> bool:
	if interactionComponent:
		if interactionComponent.lockCamera and interactionComponent.isInteracting:
			return true
	return false
