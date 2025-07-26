require('lightboat.core').init()
return {
    { 'KaiserYang/LightBoat', lazy = false, priority = 10000, opts = {} },
    require('lightboat.plugins.treesitter'),
    require('lightboat.plugins.save'),
    require('lightboat.plugins.guess_indent'),
}
