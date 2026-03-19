extends HitboxComponent
class_name Spike

# By extending HitboxComponent, the Spike node becomes an Area2D that 
# automatically interfaces with the player's HurtboxComponent.
# The user's HurtboxComponent will detect this area as a HitboxComponent
# and take the appropriate amount of damage.

# You can adjust the "damage" property directly in the Godot Inspector.

func _ready() -> void:
	pass
