local M = {}

local default_opts = {
    no_global_cd = true,
}

local mkstate = require("glocal-states")
local api = vim.api

local augroup = api.nvim_create_augroup('NaughieWorkingUri', { clear = true })

local states = {
    local = {
        cwd = mkstate.tab(),
    },

    remote = {
        uri = mkstate.tab(),
    },
}

local function create_autocmd(opts)
    api.nvim_create_autocmd('TabNew', {
        group = augroup,
        callback = function()
            local cwd = vim.uv.cwd()
            states.local.cwd.set(cwd)
        end,
    })

    api.nvim_create_autocmd('VimEnter', {
        group = augroup,
        callback = function()
            local cwd = vim.uv.cwd()
            states.local.cwd.set(cwd)
        end,
    })

    api.nvim_create_autocmd('TabEnter', {
        group = augroup,
        callback = function()
            local cwd = states.local.cwd.get()
            local old_cwd = vim.uv.cwd()
            if cwd and cwd ~= old_cwd then vim.uv.chdir(cwd) end
        end
    })

    api.nvim_create_autocmd('TabClosed', {
        group = augroup,
        callback = function(ev)
            local tab = tonumber(ev.file) 
            states.local.cwd.clear(tab)
            states.remote.uri.clear(tab)
        end,
    })

    api.nvim_create_autocmd('DirChanged', {
        group = augroup,
        pattern = { "global", "tabpage" },
        callback = function(ev)
            local scope = vim.v.event.scope
            local new_dir = vim.v.event.cwd
            states.local.cwd.set(new_dir)

            if scope == "global" and not opts.no_global_cd then
                states.local.cwd.iter_mut(function() return new_dir end)
            end
        end,
    })
end

M.remote = {
    get = function(tab)
        return states.remote.uri.get(tab)
    end,

    set = function(uri, tab)
        return states.remote.uri.set(uri, tab)
    end,
}

function M.setup(opts)
    local merged_opts = vim.tbl_deep_extend("force", vim.deepcopy(default_opts), opts or {})
    create_autocmd(merged_opts)
end

return M
