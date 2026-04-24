extends Node2D

var player = null
@onready var label = $Label
 
const base_text = "[E] to "

var active_area = []
@export var can_interact = true

func register_area(area):
	active_area.push_back(area)
	
func unregister_area(area):
	var index = active_area.find(area)
	if index != -1:
		active_area.remove_at(index)

func _process(delta):
	if active_area.size() > 0 && can_interact:
		if not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("player")
			if not player:
				return
				
		active_area.sort_custom(_sort_by_distace_to_player)
		
		var action_label : String 
		if active_area[0].get_parent().has_method("get_action_name"):
			action_label = active_area[0].get_parent().get_action_name()
		else:
			action_label = active_area[0].action_name

		label.text = base_text + str(action_label)
		label.reset_size()
		label.global_position = active_area[0].global_position
		label.global_position.y -= 90
		label.global_position.x -= label.size.x /2
		label.show()
	else:
		label.hide()
		
func _sort_by_distace_to_player(area1,area2):
		var area1_to_player = player.global_position.distance_to(area1.global_position)
		var area2_to_player = player.global_position.distance_to(area2.global_position)
		return area1_to_player < area2_to_player
		
func _input(event):
	if event.is_action_pressed("interact")&& can_interact:
		if active_area.size() > 0 :
			can_interact = false
			label.hide()
			
			await  active_area[0].interact.call()
			
			can_interact = true
