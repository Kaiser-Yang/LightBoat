# Condition Module

A chainable condition builder for LightBoat that allows creating complex conditional logic with a fluent interface.

## Features

- Create instances using `cond()` or `cond.new()`
- Chain multiple conditions together
- All conditions are connected with `and` logic (short-circuit evaluation)
- Callable instances that return boolean results

## Usage

### Basic Usage

```lua
local cond = require('lightboat.condition')

-- Create a simple condition
local check = cond():filetype('lua')
if check() then
  print('Current filetype is lua')
end
```

### Chaining Conditions

```lua
local cond = require('lightboat.condition')

-- Chain multiple conditions
local check = cond()
  :filetype('lua')
  :git_executable()
  :is_git_repository()

-- Evaluate all conditions (connected with and)
if check() then
  print('All conditions passed!')
end
```

### Value Condition

```lua
local cond = require('lightboat.condition')

-- Check if a value is truthy
local some_config = true
local check = cond():value(some_config):filetype('lua')

if check() then
  print('Config is enabled and filetype is lua')
end
```

### Creating Instances

```lua
local cond = require('lightboat.condition')

-- Method 1: Using () 
local check1 = cond()

-- Method 2: Using .new()
local check2 = cond.new()
```

## Available Conditions

- `filetype(ft)` - Check if current filetype matches (supports string or array)
- `not_filetype(ft)` - Check if current filetype doesn't match
- `last_key(key)` - Check if last pressed key matches
- `treesitter_available()` - Check if treesitter parser is available
- `completion_menu_visible()` - Check if completion menu is visible
- `completion_menu_not_visible()` - Check if completion menu is not visible
- `completion_item_selected()` - Check if completion item is selected
- `snippet_active()` - Check if snippet is active
- `documentation_visible()` - Check if documentation is visible
- `signature_visible()` - Check if signature is visible
- `signature_not_visible()` - Check if signature is not visible
- `git_executable()` - Check if git is executable
- `is_git_repository()` - Check if in a git repository
- `value(val)` - Check if a value is truthy

## Examples

### Plugin Conditional Loading

```lua
local cond = require('lightboat.condition')

local spec = {
  'some-plugin',
  cond = cond():not_filetype('alpha'):git_executable(),
}
```

### Complex Conditions

```lua
local cond = require('lightboat.condition')

-- Only enable in Lua files within git repositories
local check = cond()
  :filetype('lua')
  :is_git_repository()
  :treesitter_available()

if check() then
  -- Enable some feature
end
```
