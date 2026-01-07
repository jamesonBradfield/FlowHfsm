class_name BehaviorMove extends StateBehavior

enum DirectionType {
    INPUT,  # Use WASD/Joystick from Blackboard
    FIXED   # Use the vector defined below (Good for Dodges/Lunges)
}

@export_group("Movement Settings")
## The movement speed in meters/second.
@export var speed: float = 5.0
## Determines where the movement direction comes from (Input or Fixed).
@export var direction_source: DirectionType = DirectionType.INPUT
## The key in the blackboard for the input direction (Vector2).
@export var input_blackboard_key: String = "input_dir"
## How fast the character rotates towards the movement direction (radians/sec).
@export var rotation_speed : float = 1.0
## Only used if direction_source is FIXED.
@export var fixed_direction: Vector2 = Vector2(0, -1) 

## The frame of reference for the movement (Camera, World, or Actor).
@export var frame_of_reference: PhysicsManager.Frame = PhysicsManager.Frame.CAMERA
## If true, the character will rotate to face the direction of movement.
@export var face_movement_direction: bool = true

func update(node, delta, actor, blackboard):
    var move_dir = Vector2.ZERO
    
    # 1. DETERMINE DIRECTION
    match direction_source:
        DirectionType.INPUT:
            # Standard Locomotion
            move_dir = blackboard.get(input_blackboard_key, Vector2.ZERO)
            
        DirectionType.FIXED:
            # Forced Movement (Dodges, Lunges, AI)
            move_dir = fixed_direction.normalized()

    # 2. SEND INTENT
    var phys: PhysicsManager = blackboard.get("physics_manager")
    if phys:
        phys.move_intent(move_dir, speed, frame_of_reference)
        
        # Only rotate if we are actually moving and we want to face it
        # (Usually fixed moves like "Backstep" do NOT rotate the character)
        if face_movement_direction and move_dir.length() > 0.1:
            _rotate_to_dir(actor, move_dir, delta)

func _rotate_to_dir(actor, dir, delta):
  # Calculate target angle based on camera (if using Camera frame)
  var target_angle = atan2(dir.x, dir.y)
  
  # If using Camera frame, we need to add camera rotation Y
  var cam = actor.get_viewport().get_camera_3d()
  if cam:
   target_angle += cam.global_rotation.y
   
  var current_rot = actor.rotation.y
  actor.rotation.y = lerp_angle(current_rot, target_angle, rotation_speed * delta)


func _calculate_local_velocity(actor: CharacterBody3D) -> Vector2:
  # Convert World Velocity -> Local Space
  # +Y is Forward, +X is Right
  var world_vel = actor.velocity
  var actor_basis = actor.global_transform.basis
  
  # Project world velocity onto actor's forward/right vectors
  var forward_dot = world_vel.dot(-actor_basis.z) # Godot forward is -Z
  var right_dot = world_vel.dot(actor_basis.x)
  
  return Vector2(right_dot, forward_dot)
