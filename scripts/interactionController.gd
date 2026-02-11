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
			print("still picking")
			if interactionComponent:
				interactionComponent.interact()
		else:
			if interactionComponent:
				print("not picking")
				interactionComponent.postInteract()
				currentObject = null
	# If not interacting with something, lets see if its now possible.
	else:
		var potentialObject: Object = interactionRaycast.get_collider()
		
		if potentialObject and potentialObject is Node:
			interactionComponent = potentialObject.get_node_or_null("InteractionComponent")
			if interactionComponent:
				if interactionComponent.canInteract == false:
					print("cant interact")
					return
					
				lastPotentialObject = currentObject
				
				if Input.is_action_pressed("primary"):
					print("clicking object initial")
					currentObject = potentialObject
					interactionComponent.preInteract(hand)
