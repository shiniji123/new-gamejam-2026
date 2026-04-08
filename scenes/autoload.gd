extends Node

var current_state = State.EXPLORE
enum State { EXPLORE, COMBAT }

#func _physics_process(delta):
	#match current_state:
		#State.EXPLORE:
			#pass
			#handle_exploration_movement(delta)
		#State.COMBAT:
			#pass
			#handle_combat_movement(delta)
