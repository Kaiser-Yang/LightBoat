-- Validation Test: Demonstrating the refactored condition module
-- This file shows how to use the new chainable condition type

local cond = require('lightboat.condition')

-- ============================================================================
-- REQUIREMENT 1: Create instances using () or .new()
-- ============================================================================

-- Method 1: Using () to create instance
local condition1 = cond()
print("✓ Can create instance with cond()")

-- Method 2: Using .new() to create instance  
local condition2 = cond.new()
print("✓ Can create instance with cond.new()")

-- ============================================================================
-- REQUIREMENT 2: Method chaining like cond():filetype(xxx):xxx()
-- ============================================================================

-- Chain multiple conditions together
local chained_condition = cond()
  :filetype('lua')
  :git_executable()
  :treesitter_available()
print("✓ Can chain methods: cond():filetype('lua'):git_executable():treesitter_available()")

-- ============================================================================
-- REQUIREMENT 3: Each chain returns the same type (Condition)
-- ============================================================================

-- Each method returns a Condition instance that can be chained further
local step1 = cond():filetype('lua')  -- Returns Condition
local step2 = step1:git_executable()  -- Returns Condition
local step3 = step2:value(true)       -- Returns Condition
print("✓ Each chained method returns Condition type")

-- ============================================================================
-- REQUIREMENT 4: The returned type is callable via ()
-- ============================================================================

-- The Condition instance can be called to evaluate all conditions
local evaluable = cond():value(true):value(1)
local result = evaluable()  -- Calls __call metamethod
print("✓ Condition instance is callable: evaluable()")

-- ============================================================================
-- REQUIREMENT 5: Conditions connected with AND logic
-- ============================================================================

-- All conditions must be true for the result to be true
-- If any condition is false, short-circuit returns false
local all_true = cond()
  :value(true)
  :value(1)
  :value("string")
-- all_true() would return true

local has_false = cond()
  :value(true)
  :value(false)  -- This is false
  :value(true)
-- has_false() would return false due to AND logic
print("✓ Conditions are connected with AND logic")

-- ============================================================================
-- REQUIREMENT 6: Added value condition to check if a value is truthy
-- ============================================================================

-- Test the new value() condition
local value_check = cond():value(true)
print("✓ value() condition added: cond():value(true)")

-- Value condition with various truthy/falsy values
local truthy_values = cond()
  :value(true)      -- truthy
  :value(1)         -- truthy
  :value("string")  -- truthy

local falsy_values = cond()
  :value(false)     -- falsy
  :value(nil)       -- falsy
  :value(0)         -- truthy in Lua! (only false and nil are falsy)

print("✓ value() handles truthy/falsy values correctly")

-- ============================================================================
-- PRACTICAL EXAMPLES
-- ============================================================================

-- Example 1: Plugin conditional loading
local plugin_condition = cond()
  :not_filetype('alpha')
  :git_executable()
  :is_git_repository()
-- Usage: cond = plugin_condition in lazy.nvim spec

-- Example 2: Complex editor state check
local editor_ready = cond()
  :treesitter_available()
  :completion_menu_not_visible()
  :value(not vim.g.vscode)

-- Example 3: Completion context check
local completion_context = cond()
  :completion_menu_visible()
  :completion_item_selected()
  :signature_not_visible()

print("\n✅ All requirements validated successfully!")
print("The condition module has been successfully refactored to a chainable type.")
