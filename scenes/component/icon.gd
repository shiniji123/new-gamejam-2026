extends Node2D

@onready var interaction_area: InteractionArea = $InteractiveArea
var player = null
#===============================================
#INTERACTION
func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	if not player:
		print("Not Assign")
	if player:
		Autoload.coin += 1
		print("+1 coin")
		queue_free()
		
#===============================================
