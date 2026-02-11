extends Control

@onready var centerContainer: CenterContainer = $CenterContainer
var crosshairDotColor: Color = Color.WHITE
var crosshairDotRadius: float = 1.0 

func setCrosshairDotColor(color: Color) -> void:
	crosshairDotColor = color
	queue_redraw()

func setCrosshairDotRadius(radius: float) -> void:
	crosshairDotRadius = radius
	queue_redraw()

func _draw() -> void:
	draw_circle(centerContainer.position, crosshairDotRadius, crosshairDotColor)
