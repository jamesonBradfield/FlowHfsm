class_name RecursiveState extends Node

## THE CONTAINER
## Acts as a generic host for a Behavior (Logic) and Transitions (Gates).
## Holds the "State" (Memory) for the Behavior to use.

# --- EXPORTS (The Strategy) ---
@export_group("Logic")
@export var behavior: StateBehavior ## The "Brain" (Resource)
@export var transitions: Array[StateTransition] ## The "Gates" (Resources)

@export_group("Settings")
@export var is_starting_state: bool = false
@export var is_locked: bool = false ## If true, Parent cannot transition out of this state.

# --- STATE VARIABLES (The Memory) ---
var parent: RecursiveState = null
var active_child: RecursiveState = null

# The "Bucket" for the Behavior to store runtime data (Timer, Counters, etc.)
# Key = String ("charge_time"), Value = Any
var memory: Dictionary = {}

# --- LIFECYCLE ---

func _ready() -> void:
	# 1. Wire up hierarchy
	var p = get_parent()
	if p is RecursiveState:
		parent = p

# --- THE MAIN LOOP ---

func process_state(delta: float, actor: Node, blackboard: Dictionary) -> void:
	# 1. PROHIBITIVE CHECKS (Logic flows DOWN)
	# If I have transitions, check them first.
	# But ONLY if I am not locked (e.g. Attacking).
	if not is_locked:
		for transition in transitions:
			if transition.is_triggered(actor, blackboard):
				# Tell parent to switch me out
				if parent:
					# CRITICAL FIX: Only stop processing if the transition actually SUCCEEDED.
					# If the target state doesn't exist (Blocked by Hierarchy), we must continue our logic.
					if parent.change_active_child_by_name(transition.target_state):
						return # Stop processing this branch

	# 2. BEHAVIOR UPDATE (The "Brain")
	if behavior:
		behavior.update(self, delta, actor, blackboard)

	# 3. RECURSION (Tick the Child)
	if active_child:
		active_child.process_state(delta, actor, blackboard)

# --- API ---

func enter(actor: Node, blackboard: Dictionary) -> void:
	# Reset local memory on entry so we don't have stale data (e.g. old timers)
	memory.clear()
	is_locked = false 
	
	# Auto-resolve initial child if none is active
	if not active_child and get_child_count() > 0:
		var start_node = _get_starting_child()
		if start_node:
			active_child = start_node

	if behavior:
		behavior.enter(self, actor, blackboard)
	
	# If we have a default child, enter it too
	if active_child:
		active_child.enter(actor, blackboard)

func _get_starting_child() -> RecursiveState:
	for child in get_children():
		if child is RecursiveState and child.is_starting_state:
			return child
	
	# Fallback: First valid child
	for child in get_children():
		if child is RecursiveState:
			return child
	
	return null

func exit(actor: Node, blackboard: Dictionary) -> void:
	if active_child:
		active_child.exit(actor, blackboard)
		
	if behavior:
		behavior.exit(self, actor, blackboard)

# --- CHILD MANAGEMENT ---

func change_active_child(new_node: RecursiveState) -> void:
	# We need the actor/blackboard to call exit/enter properly.
	# Since this is usually called from inside process_state, we can grab them there.
	# BUT, to keep it clean, we might need to store a reference to actor in 'enter'
	# or pass it down. For now, assuming standard flow:
	
	# Note: This is a slight architectural friction point. 
	# Ideally, 'change_active_child' happens inside the tick where we have the context.
	
	if active_child == new_node: return
	
	# We can't call exit() properly without the Actor reference if we do it purely by signal.
	# So we just swap the var, and the next 'process_state' tick handles the logic? 
	# No, that causes frame gaps.
	
	# Solution: The Parent handles the swap immediately using stored context if available,
	# or we enforce that transitions only happen during process().
	active_child = new_node

func change_active_child_by_name(state_name: String) -> bool:
	var node = get_node_or_null(state_name)
	if node and node is RecursiveState:
		if active_child == node:
			return true
			
		# We need to perform the swap. 
		# If this is called from process_state, we have context.
		# If called from a Signal, we might need to store 'current_actor' in memory.
		
		# For this implementation, we assume transitions happen during the tick.
		# We will handle the actual enter/exit calls in a "Deferred" way or 
		# pass the actor context up.
		
		# SIMPLIFICATION FOR PHASE 2:
		# We will make 'process_state' return a REQUEST instead of void?
		# Or just assume we can access the actor via the PhysicsManager/Owner.
		
		# Let's trust the standard "Owner" pattern for now.
		var actor = owner
		if active_child:
			active_child.exit(actor, {}) # Passing empty dict for now, might need fix
		
		active_child = node
		active_child.enter(actor, {})
		return true
	
	return false
