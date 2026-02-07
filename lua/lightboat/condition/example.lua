-- Example usage of the refactored condition module
local cond = require('lightboat.condition')

-- Example 1: Simple condition check
print('Example 1: Simple filetype check')
local check1 = cond():filetype('lua')
-- Usage: if check1() then ... end

-- Example 2: Chaining multiple conditions
print('Example 2: Chaining conditions')
local check2 = cond()
  :filetype({ 'lua', 'python', 'javascript' })
  :git_executable()
  :is_git_repository()
-- All conditions must be true (connected with AND)

-- Example 3: Using value condition
print('Example 3: Value condition')
local some_config = true
local check3 = cond():value(some_config)
-- Returns true if some_config is truthy

-- Example 4: Complex chaining
print('Example 4: Complex condition chain')
local check4 = cond()
  :value(not vim.g.vscode)
  :filetype('lua')
  :treesitter_available()

-- Example 5: Create instance with .new()
print('Example 5: Using .new()')
local check5 = cond.new():filetype('lua'):git_executable()

-- Example 6: Completion-related conditions
print('Example 6: Completion conditions')
local check6 = cond()
  :completion_menu_visible()
  :completion_item_selected()

-- Example 7: Not filetype condition
print('Example 7: Not filetype')
local check7 = cond():not_filetype('alpha')

-- Example 8: Check git availability
print('Example 8: Git checks')
local check8 = cond():git_executable():is_git_repository()

print('\nAll example conditions created successfully!')
print('Use check() to evaluate any condition')
