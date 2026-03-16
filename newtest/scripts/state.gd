extends Node
class_name State

# Signal emitted when a state wants to transition
signal Transitioned(state: State, new_state_name: String)

# Called when the state is entered
func enter():
	pass

# Called when the state is exited
func exit():
	pass

# Called every frame by the state machine
func update(_delta: float):
	pass

# Called every physics tick by the state machine
func physics_update(_delta: float):
	pass
