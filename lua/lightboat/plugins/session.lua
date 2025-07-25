local util = require('lightboat.util')
return {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
        auto_save = util.has_root_directory,
        auto_create = util.has_root_directory,
        auto_restore = util.has_root_directory,
        git_use_branch_name = true,
        git_auto_restore_on_branch_change = true,
        continue_restore_on_error = false,
        session_lens = {
            mappings = {
                delete_session = false,
                alternate_session = false,
                copy_session = false,
            },
        },
    },
}
