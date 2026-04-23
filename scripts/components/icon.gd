extends Node2D

@onready var interaction_area: InteractionArea = $InteractiveArea
@onready var player = get_tree().get_first_node_in_group("player")
#===============================================
#INTERACTION
func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	if not player:
		print("Not Assign")
	if player:
		RunManager.add_coin(1)
		print("+1 coin")
		queue_free()
		
#===============================================
