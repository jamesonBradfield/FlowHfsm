# Plan: HFSM Workbench Context Redesign

## 1. Goal
Transform the "Context Mode" (State Editing) from a linear inspector-mirror to a rich, tabbed workspace that improves manageability of complex states.

## 2. Architecture
The `Context Mode` UI will be split into three main tabs via a `TabContainer`:

### Tab 1: Overview (Structure)
Focuses on the State's place in the hierarchy and its transition logic.
- **Header**: State Name, "Active" status (if running).
- **Activation Logic**:
    - **Activation Mode**: Dropdown (AND/OR).
    - **Conditions List**: Re-implement condition editing (was missing).
- **Children Preview**:
    - A read-only grid or list of child states.
    - Quick "Add Child" button.

### Tab 2: Logic (Behaviors)
Uses a **Master-Detail** layout to handle multiple behaviors without scrolling fatigue.
- **Layout**: `HSplitContainer`.
- **Left (Master)**: `ItemList` showing assigned behaviors.
    - Toolbar: Add, Remove, Move Up/Down.
- **Right (Detail)**: Property Editor for the *selected* behavior.
    - Uses `HFSMPropertyFactory` to generate fields.
    - If no behavior selected, show "Select a behavior to edit".

### Tab 3: Memory (Variables)
Focuses on the Blackboard/Variables definition.
- **Layout**: List of Variable Cards (similar to current, but tighter).
- **Toolbar**: "Add Variable", "Clean Unused" (future).

## 3. Implementation Steps

### Step 1: Scaffold Tabs
- Modify `_build_context_ui` to create the `TabContainer`.
- Create placeholder functions `_build_tab_overview`, `_build_tab_logic`, `_build_tab_memory`.

### Step 2: Implement Logic Tab (Master-Detail)
- This is the biggest UX win.
- Create the `ItemList` and connect selection signals.
- Create a dynamic property container that clears/rebuilds when selection changes.

### Step 3: Implement Overview Tab
- Port the "Add Child" button here.
- Add the "Activation Conditions" editor (critical missing feature).
    - Reuse `HFSMPropertyFactory` logic but customized for Conditions (ResourcePicker).

### Step 4: Implement Memory Tab
- Port existing Variable editor logic here.

## 4. Dependencies
- `HFSMPropertyFactory` (reused for property generation).
- `EditorInterface` (for UndoRedo).

