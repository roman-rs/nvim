local M = {}

-- Locate the nearest split in the requested axis, including nested layouts.
local function boundary(node, current, axis)
  if node[1] == "leaf" then return node[2] == current, nil end
  for index, child in ipairs(node[2]) do
    local contains, edge = boundary(child, current, axis)
    if contains then
      if edge then return true, edge end
      if node[1] == axis then
        return true, node[2][math.min(index, #node[2] - 1)]
      end
      return true, nil
    end
  end
  return false, nil
end

local function edge_window(node, axis)
  if node[1] == "leaf" then return node[2] end
  local index = node[1] == axis and #node[2] or 1
  return edge_window(node[2][index], axis)
end

function M.move(axis, offset)
  local current = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(current).relative ~= "" then return end
  local _, edge = boundary(vim.fn.winlayout(), current, axis)
  if not edge then return end
  local window = vim.fn.win_id2win(edge_window(edge, axis))
  if axis == "row" then
    vim.fn.win_move_separator(window, offset)
  else
    vim.fn.win_move_statusline(window, offset)
  end
end

return M
