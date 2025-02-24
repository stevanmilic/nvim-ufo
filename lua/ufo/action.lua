local api = vim.api
local cmd = vim.cmd
local fn = vim.fn

local utils = require('ufo.utils')

local M = {}

function M.goPreviousStartFold()
    local function getCurLnum()
        return api.nvim_win_get_cursor(0)[1]
    end

    local cnt = vim.v.count1
    local winView = fn.winsaveview()
    local curLnum = getCurLnum()
    cmd('norm! m`')
    local previousLnum
    local previousLnumList = {}
    while cnt > 0 do
        cmd([[keepj norm! zk]])
        local tLnum = getCurLnum()
        cmd([[keepj norm! [z]])
        if tLnum == getCurLnum() then
            local foldStartLnum = utils.foldClosed(0, tLnum)
            if foldStartLnum > 0 then
                cmd(('keepj norm! %dgg'):format(foldStartLnum))
            end
        end
        local nextLnum = getCurLnum()
        while curLnum > nextLnum do
            tLnum = nextLnum
            table.insert(previousLnumList, nextLnum)
            cmd([[keepj norm! zj]])
            nextLnum = getCurLnum()
            if nextLnum == tLnum then
                break
            end
        end
        if #previousLnumList == 0 then
            break
        end
        if #previousLnumList < cnt then
            cnt = cnt - #previousLnumList
            curLnum = previousLnumList[1]
            previousLnum = curLnum
            cmd(('keepj norm! %dgg'):format(curLnum))
            previousLnumList = {}
        else
            while cnt > 0 do
                previousLnum = table.remove(previousLnumList)
                cnt = cnt - 1
            end
        end
    end
    fn.winrestview(winView)
    if previousLnum then
        cmd(('norm! %dgg_'):format(previousLnum))
    end
end

function M.goPreviousClosedFold()
    local count = vim.v.count1
    local curLnum = api.nvim_win_get_cursor(0)[1]
    local cnt = 0
    local lnum
    for i = curLnum - 1, 1, -1 do
        if utils.foldClosed(0, i) == i then
            cnt = cnt + 1
            lnum = i
            if cnt == count then
                break
            end
        end
    end
    if lnum then
        api.nvim_win_set_cursor(0, {lnum, 0})
    end
end

function M.goNextClosedFold()
    local count = vim.v.count1
    local curLnum = api.nvim_win_get_cursor(0)[1]
    local lineCount = api.nvim_buf_line_count(0)
    local cnt = 0
    local lnum
    for i = curLnum + 1, lineCount do
        if utils.foldClosed(0, i) == i then
            cnt = cnt + 1
            lnum = i
            if cnt == count then
                break
            end
        end
    end
    if lnum then
        api.nvim_win_set_cursor(0, {lnum, 0})
    end
end

function M.closeAllFolds()
    local lineCount = api.nvim_buf_line_count(0)
    local winView = fn.winsaveview()
    local lnum = 1
    while lnum <= lineCount do
        if fn.foldlevel(lnum) > 0 then
            api.nvim_win_set_cursor(0, {lnum, 0})
            cmd('norm! zC')
            local endLnum = utils.foldClosedEnd(0, lnum)
            lnum = endLnum > 0 and (endLnum + 1) or (lnum + 1)
        else
            lnum = lnum + 1
        end
    end
    fn.winrestview(winView)
end

function M.openAllFolds()
    local lineCount = api.nvim_buf_line_count(0)
    local winView = fn.winsaveview()
    local lnum = 1
    while lnum <= lineCount do
        local endLnum = utils.foldClosedEnd(0, lnum)
        if endLnum > 0 then
            api.nvim_win_set_cursor(0, {lnum, 0})
            cmd('norm! zO')
            lnum = endLnum + 1
        else
            lnum = lnum + 1
        end
    end
    fn.winrestview(winView)
end

return M
