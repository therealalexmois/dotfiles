local M = {}

local ENUM_BASE_NAMES = {
  Enum = true,
  IntEnum = true,
  StrEnum = true,
  Flag = true,
  IntFlag = true,
}

local SUPPORTED_SELECTION_KINDS = {
  ["module"] = true,
  ["function"] = true,
  ["class"] = true,
  ["enum"] = true,
  ["multiple_definitions"] = true,
  ["unsupported_fragment"] = true,
}

---@param bufnr integer
---@param row integer
---@return integer
local function get_line_length(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  return #line
end

---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return integer[]
local function make_range(start_row, start_col, end_row, end_col) return { start_row, start_col, end_row, end_col } end

---@param bufnr integer
---@param range integer[]
---@return integer[]
local function normalize_range_for_buf(bufnr, range)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if line_count <= 0 then return make_range(0, 0, 0, 0) end

  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]

  local last_row = line_count - 1

  if start_row < 0 then start_row = 0 end

  if start_row > last_row then start_row = last_row end

  if end_row < start_row then end_row = start_row end

  -- Tree-sitter root node can end on line_count, which is out of bounds
  -- for nvim_buf_get_text().
  if end_row > last_row then
    end_row = last_row
    end_col = get_line_length(bufnr, last_row)
  end

  local start_line_length = get_line_length(bufnr, start_row)
  local end_line_length = get_line_length(bufnr, end_row)

  if start_col < 0 then start_col = 0 end

  if start_col > start_line_length then start_col = start_line_length end

  if end_col < 0 then end_col = 0 end

  if end_col > end_line_length then end_col = end_line_length end

  if start_row == end_row and start_col > end_col then start_col = end_col end

  return make_range(start_row, start_col, end_row, end_col)
end

---@param node TSNode
---@return integer[]
local function node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return make_range(start_row, start_col, end_row, end_col)
end

---@param bufnr integer
---@param range integer[]
---@return string
local function get_range_text(bufnr, range)
  local normalized_range = normalize_range_for_buf(bufnr, range)

  local lines = vim.api.nvim_buf_get_text(
    bufnr,
    normalized_range[1],
    normalized_range[2],
    normalized_range[3],
    normalized_range[4],
    {}
  )

  return table.concat(lines, "\n")
end

---@param text string
---@return string
local function strip_ws(text) return (text or ""):gsub("%s+", "") end

---@param outer integer[]
---@param inner integer[]
---@return boolean
local function range_contains(outer, inner)
  local outer_start_row, outer_start_col, outer_end_row, outer_end_col = outer[1], outer[2], outer[3], outer[4]
  local inner_start_row, inner_start_col, inner_end_row, inner_end_col = inner[1], inner[2], inner[3], inner[4]

  local starts_before_or_equal = (
    inner_start_row > outer_start_row or (inner_start_row == outer_start_row and inner_start_col >= outer_start_col)
  )

  local ends_after_or_equal = (
    inner_end_row < outer_end_row or (inner_end_row == outer_end_row and inner_end_col <= outer_end_col)
  )

  return starts_before_or_equal and ends_after_or_equal
end

---@param ranges integer[][]
---@param bufnr integer
---@return string
local function concat_descriptor_texts(ranges, bufnr)
  table.sort(ranges, function(left, right)
    if left[1] ~= right[1] then return left[1] < right[1] end

    return left[2] < right[2]
  end)

  local chunks = {}

  for _, range in ipairs(ranges) do
    table.insert(chunks, get_range_text(bufnr, range))
  end

  return table.concat(chunks, "\n")
end

---@param node TSNode
---@return TSNode[]
local function get_named_children(node)
  local children = {}

  for child in node:iter_children() do
    if child:named() then table.insert(children, child) end
  end

  return children
end

---@param node TSNode
---@param bufnr integer
---@return TSNode, string[]
local function unwrap_definition_node(node, bufnr)
  if node:type() ~= "decorated_definition" then return node, {} end

  local decorators = {}
  local inner = nil

  for _, child in ipairs(get_named_children(node)) do
    if child:type() == "decorator" then
      local text = get_range_text(bufnr, node_range(child))
      text = text:gsub("^@", "")
      text = text:gsub("%b()", "")
      text = vim.trim(text)
      if text ~= "" then table.insert(decorators, text) end
    else
      inner = child
    end
  end

  return inner or node, decorators
end

---@param node TSNode|nil
---@param field string
---@return TSNode|nil
local function get_field(node, field)
  if node == nil then return nil end

  local ok, nodes = pcall(function() return node:field(field) end)

  if not ok or type(nodes) ~= "table" or #nodes == 0 then return nil end

  return nodes[1]
end

---@param node TSNode|nil
---@param bufnr integer
---@return string|nil
local function get_node_text(node, bufnr)
  if node == nil then return nil end

  return get_range_text(bufnr, node_range(node))
end

---@param node TSNode|nil
---@param bufnr integer
---@return string|nil
local function find_first_identifier_text(node, bufnr)
  if node == nil then return nil end

  if node:type() == "identifier" then return get_node_text(node, bufnr) end

  for _, child in ipairs(get_named_children(node)) do
    local value = find_first_identifier_text(child, bufnr)
    if value ~= nil and value ~= "" then return value end
  end

  return nil
end

---@param params_node TSNode|nil
---@param bufnr integer
---@return string[]
local function extract_parameter_names(params_node, bufnr)
  if params_node == nil then return {} end

  local names = {}
  local seen = {}

  for _, child in ipairs(get_named_children(params_node)) do
    local name = find_first_identifier_text(child, bufnr)
    if name ~= nil and name ~= "" and not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end

  return names
end

---@param body_node TSNode|nil
---@return boolean
local function has_explicit_raise(body_node)
  if body_node == nil then return false end

  if body_node:type() == "raise_statement" then return true end

  for _, child in ipairs(get_named_children(body_node)) do
    if has_explicit_raise(child) then return true end
  end

  return false
end

---@param node TSNode
---@return TSNode|nil
local function get_body_node(node)
  local body = get_field(node, "body")
  if body ~= nil then return body end

  local children = get_named_children(node)
  return children[#children]
end

---@param first_statement TSNode|nil
---@return boolean
local function is_docstring_statement(first_statement)
  if first_statement == nil then return false end

  if first_statement:type() ~= "expression_statement" then return false end

  local first_child = first_statement:named_child(0)
  if first_child == nil then return false end

  local child_type = first_child:type()

  return child_type == "string" or child_type == "concatenated_string"
end

---@param node TSNode
---@param bufnr integer
---@return integer[]|nil, string|nil
local function find_existing_docstring(node, bufnr)
  local body_node = nil

  if node:type() == "module" then
    local first_statement = node:named_child(0)
    if not is_docstring_statement(first_statement) then return nil, nil end

    local doc_range = normalize_range_for_buf(bufnr, node_range(first_statement))
    return doc_range, get_range_text(bufnr, doc_range)
  end

  body_node = get_body_node(node)
  if body_node == nil then return nil, nil end

  local first_statement = body_node:named_child(0)
  if not is_docstring_statement(first_statement) then return nil, nil end

  local doc_range = normalize_range_for_buf(bufnr, node_range(first_statement))
  return doc_range, get_range_text(bufnr, doc_range)
end

---@param bufnr integer
---@param node TSNode
---@param body_node TSNode|nil
---@return integer[]|nil
local function compute_signature_range(bufnr, node, body_node)
  if body_node == nil then return nil end

  local start_row, start_col = node:range()
  local body_start_row, body_start_col = body_node:range()

  if body_start_row == start_row then
    return normalize_range_for_buf(bufnr, make_range(start_row, start_col, body_start_row, body_start_col))
  end

  local signature_end_row = body_start_row - 1
  local signature_end_col = get_line_length(bufnr, signature_end_row)

  return normalize_range_for_buf(bufnr, make_range(start_row, start_col, signature_end_row, signature_end_col))
end

---@param text string|nil
---@return boolean
local function is_enum_signature(text)
  if text == nil or text == "" then return false end

  for base_name, _ in pairs(ENUM_BASE_NAMES) do
    if text:match("%f[%w_]" .. base_name .. "%f[^%w_]") then return true end
  end

  return false
end

---@param raw_kind string
---@param parent_kind string|nil
---@param signature_text string|nil
---@return string
local function normalize_kind(raw_kind, parent_kind, signature_text)
  if raw_kind == "class" and is_enum_signature(signature_text) then return "enum" end

  if raw_kind == "function" and (parent_kind == "class" or parent_kind == "enum") then return "method" end

  return raw_kind
end

---@param bufnr integer
---@param node TSNode
---@param raw_kind string
---@param parent_kind string|nil
---@param decorators string[]
---@return table
local function build_descriptor(bufnr, node, raw_kind, parent_kind, decorators)
  local body_node = get_body_node(node)
  local node_range_value = normalize_range_for_buf(bufnr, node_range(node))
  local body_range_value = body_node and normalize_range_for_buf(bufnr, node_range(body_node)) or nil
  local signature_range_value = compute_signature_range(bufnr, node, body_node)
  local signature_text = get_range_text(bufnr, signature_range_value or node_range_value)
  local existing_doc_range, existing_doc_text = find_existing_docstring(node, bufnr)
  local name_node = get_field(node, "name")
  local params_node = get_field(node, "parameters")
  local return_type_node = get_field(node, "return_type")

  local kind = normalize_kind(raw_kind, parent_kind, signature_text)

  return {
    kind = kind,
    name = get_node_text(name_node, bufnr),
    lang = "python",
    node_range = node_range_value,
    signature_range = signature_range_value,
    body_range = body_range_value,
    existing_doc_range = existing_doc_range,
    existing_doc_text = existing_doc_text,
    text = get_range_text(bufnr, node_range_value),
    has_explicit_raise = has_explicit_raise(body_node),
    parameters = extract_parameter_names(params_node, bufnr),
    returns_annotation = get_node_text(return_type_node, bufnr),
    decorators = decorators or {},
    parent_kind = parent_kind,
  }
end

---@param node TSNode
---@param bufnr integer
---@param parent_kind string|nil
---@param acc table[]
local function collect_descriptors_from_node(node, bufnr, parent_kind, acc)
  local node_type = node:type()

  if node_type == "decorated_definition" then
    local inner, decorators = unwrap_definition_node(node, bufnr)
    local inner_type = inner:type()

    if inner_type == "function_definition" then
      table.insert(acc, build_descriptor(bufnr, inner, "function", parent_kind, decorators))
      return
    end

    if inner_type == "class_definition" then
      local descriptor = build_descriptor(bufnr, inner, "class", parent_kind, decorators)
      table.insert(acc, descriptor)

      local body_node = get_body_node(inner)
      if body_node ~= nil then
        for _, child in ipairs(get_named_children(body_node)) do
          collect_descriptors_from_node(child, bufnr, descriptor.kind, acc)
        end
      end

      return
    end
  end

  if node_type == "function_definition" then
    table.insert(acc, build_descriptor(bufnr, node, "function", parent_kind, {}))
    return
  end

  if node_type == "class_definition" then
    local descriptor = build_descriptor(bufnr, node, "class", parent_kind, {})
    table.insert(acc, descriptor)

    local body_node = get_body_node(node)
    if body_node ~= nil then
      for _, child in ipairs(get_named_children(body_node)) do
        collect_descriptors_from_node(child, bufnr, descriptor.kind, acc)
      end
    end

    return
  end

  for _, child in ipairs(get_named_children(node)) do
    collect_descriptors_from_node(child, bufnr, parent_kind, acc)
  end
end

---@param bufnr integer
---@return table
local function build_module_descriptor(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()
  local root_range = normalize_range_for_buf(bufnr, node_range(root))
  local module_doc_range, module_doc_text = find_existing_docstring(root, bufnr)

  return {
    kind = "module",
    name = nil,
    lang = "python",
    node_range = root_range,
    signature_range = nil,
    body_range = root_range,
    existing_doc_range = module_doc_range,
    existing_doc_text = module_doc_text,
    text = get_range_text(bufnr, root_range),
    has_explicit_raise = false,
    parameters = {},
    returns_annotation = nil,
    decorators = {},
    parent_kind = nil,
  }
end

---@param bufnr integer
---@return table[]
local function collect_supported_descriptors(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()

  local descriptors = {}
  collect_descriptors_from_node(root, bufnr, nil, descriptors)

  return descriptors
end

---@param descriptor table
---@return string
local function get_selection_kind_from_descriptor(descriptor)
  if descriptor.kind == "method" then return "function" end

  if SUPPORTED_SELECTION_KINDS[descriptor.kind] then return descriptor.kind end

  return "unsupported_fragment"
end

---@param bufnr integer
---@param selection_range integer[]
---@return table
function M.extract_range(bufnr, selection_range)
  local normalized_selection_range = normalize_range_for_buf(bufnr, selection_range)
  local module_descriptor = build_module_descriptor(bufnr)
  local selection_text = get_range_text(bufnr, normalized_selection_range)
  local normalized_selection_text = strip_ws(selection_text)

  if normalized_selection_text ~= "" and normalized_selection_text == strip_ws(module_descriptor.text) then
    return {
      lang = "python",
      selection_kind = "module",
      selection_range = normalized_selection_range,
      descriptors = { module_descriptor },
    }
  end

  local all_descriptors = collect_supported_descriptors(bufnr)
  local matched = {}

  for _, descriptor in ipairs(all_descriptors) do
    if range_contains(normalized_selection_range, descriptor.node_range) then table.insert(matched, descriptor) end
  end

  if #matched == 0 then
    return {
      lang = "python",
      selection_kind = "unsupported_fragment",
      selection_range = normalized_selection_range,
      descriptors = {},
    }
  end

  if #matched == 1 then
    local descriptor = matched[1]
    if normalized_selection_text == strip_ws(descriptor.text) then
      return {
        lang = "python",
        selection_kind = get_selection_kind_from_descriptor(descriptor),
        selection_range = normalized_selection_range,
        descriptors = { descriptor },
      }
    end

    return {
      lang = "python",
      selection_kind = "unsupported_fragment",
      selection_range = normalized_selection_range,
      descriptors = {},
    }
  end

  local descriptor_ranges = {}
  for _, descriptor in ipairs(matched) do
    table.insert(descriptor_ranges, descriptor.node_range)
  end

  local combined_text = concat_descriptor_texts(descriptor_ranges, bufnr)
  if normalized_selection_text == strip_ws(combined_text) then
    return {
      lang = "python",
      selection_kind = "multiple_definitions",
      selection_range = normalized_selection_range,
      descriptors = matched,
    }
  end

  return {
    lang = "python",
    selection_kind = "unsupported_fragment",
    selection_range = normalized_selection_range,
    descriptors = {},
  }
end

---@param bufnr integer
---@return integer[]|nil, string|nil
function M.get_visual_selection_range(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"

  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3] - 1

  if start_row < 0 or end_row < 0 then return nil, "Visual selection is not available" end

  if end_col >= get_line_length(bufnr, end_row) then
    end_col = get_line_length(bufnr, end_row)
  else
    end_col = end_col + 1
  end

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  return normalize_range_for_buf(bufnr, make_range(start_row, start_col, end_row, end_col)), nil
end

---@param bufnr integer|nil
---@return table|nil, string|nil
function M.extract_visual_selection(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local filetype = vim.bo[bufnr].filetype
  if filetype ~= "python" then return nil, ("Unsupported filetype for POC extractor: %s"):format(filetype) end

  local selection_range, err = M.get_visual_selection_range(bufnr)
  if selection_range == nil then return nil, err end

  local ok, result = pcall(M.extract_range, bufnr, selection_range)
  if not ok then return nil, result end

  return result, nil
end

return M
