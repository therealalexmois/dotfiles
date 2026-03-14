return {
  status = function(args)
    local function run(cmd)
      local result = vim.system(cmd, { text = true }):wait()
      return result.stdout or ''
    end

    local function trim(text)
      return (text or ''):gsub('%s+$', '')
    end

    return trim(run({ 'git', 'status', '--short' }))
  end,

  files = function(args)
    local function run(cmd)
      local result = vim.system(cmd, { text = true }):wait()
      return result.stdout or ''
    end

    local function trim(text)
      return (text or ''):gsub('%s+$', '')
    end

    local function split_lines(text)
      local items = {}
      for line in (text or ''):gmatch('[^\r\n]+') do
        if line ~= '' then
          table.insert(items, line)
        end
      end
      return items
    end

    local function unique(items)
      local seen = {}
      local result = {}

      for _, item in ipairs(items) do
        if item ~= '' and not seen[item] then
          seen[item] = true
          table.insert(result, item)
        end
      end

      return result
    end

    local function take(items, limit)
      if #items <= limit then
        return items
      end

      local result = {}
      for index = 1, limit do
        table.insert(result, items[index])
      end
      table.insert(result, ('... +%d more'):format(#items - limit))

      return result
    end

    local staged = split_lines(run({ 'git', 'diff', '--name-only', '--cached' }))
    local unstaged = split_lines(run({ 'git', 'diff', '--name-only' }))
    local untracked = split_lines(run({ 'git', 'ls-files', '--others', '--exclude-standard' }))

    local files = unique(vim.list_extend(vim.list_extend(staged, unstaged), untracked))

    return trim(table.concat(take(files, 40), '\n'))
  end,

  stat = function(args)
    local function run(cmd)
      local result = vim.system(cmd, { text = true }):wait()
      return result.stdout or ''
    end

    local function trim(text)
      return (text or ''):gsub('%s+$', '')
    end

    local function split_lines(text)
      local items = {}
      for line in (text or ''):gmatch('[^\r\n]+') do
        if line ~= '' then
          table.insert(items, line)
        end
      end
      return items
    end

    local function limit_text(text, max_lines, max_chars)
      local result = {}
      local lines = 0
      local chars = 0

      for line in (text or ''):gmatch('[^\r\n]+') do
        local next_chars = chars + #line + 1
        if lines >= max_lines or next_chars > max_chars then
          table.insert(result, '... [truncated]')
          break
        end

        table.insert(result, line)
        lines = lines + 1
        chars = next_chars
      end

      return table.concat(result, '\n')
    end

    local parts = {}

    local staged = trim(run({ 'git', 'diff', '--stat', '--cached' }))
    if staged ~= '' then
      table.insert(parts, '[staged]\n' .. staged)
    end

    local unstaged = trim(run({ 'git', 'diff', '--stat' }))
    if unstaged ~= '' then
      table.insert(parts, '[unstaged]\n' .. unstaged)
    end

    local untracked = split_lines(run({ 'git', 'ls-files', '--others', '--exclude-standard' }))
    if #untracked > 0 then
      local preview = {}
      local limit = math.min(#untracked, 20)

      for index = 1, limit do
        table.insert(preview, untracked[index])
      end

      if #untracked > limit then
        table.insert(preview, ('... +%d more'):format(#untracked - limit))
      end

      table.insert(parts, '[untracked]\n' .. table.concat(preview, '\n'))
    end

    return limit_text(trim(table.concat(parts, '\n\n')), 80, 4000)
  end,

  diff = function(args)
    local function run(cmd)
      local result = vim.system(cmd, { text = true }):wait()
      return result.stdout or ''
    end

    local function trim(text)
      return (text or ''):gsub('%s+$', '')
    end

    local function split_lines(text)
      local items = {}
      for line in (text or ''):gmatch('[^\r\n]+') do
        if line ~= '' then
          table.insert(items, line)
        end
      end
      return items
    end

    local function limit_text(text, max_lines, max_chars)
      local result = {}
      local lines = 0
      local chars = 0

      for line in (text or ''):gmatch('[^\r\n]+') do
        local next_chars = chars + #line + 1
        if lines >= max_lines or next_chars > max_chars then
          table.insert(result, '... [truncated]')
          break
        end

        table.insert(result, line)
        lines = lines + 1
        chars = next_chars
      end

      return table.concat(result, '\n')
    end

    local function get_repo_root()
      return trim(run({ 'git', 'rev-parse', '--show-toplevel' }))
    end

    local function diff_untracked_file(root, path)
      local abs_path = root .. '/' .. path
      local result = vim.system(
        { 'git', 'diff', '--no-index', '--unified=0', '--', '/dev/null', abs_path },
        { text = true }
      ):wait()

      return (result.stdout and result.stdout ~= '' and result.stdout) or ''
    end

    local parts = {}

    local staged = trim(run({ 'git', 'diff', '--no-ext-diff', '--cached', '--unified=0' }))
    if staged ~= '' then
      table.insert(parts, '[staged patch]\n' .. staged)
    end

    local unstaged = trim(run({ 'git', 'diff', '--no-ext-diff', '--unified=0' }))
    if unstaged ~= '' then
      table.insert(parts, '[unstaged patch]\n' .. unstaged)
    end

    local root = get_repo_root()
    local untracked = split_lines(run({ 'git', 'ls-files', '--others', '--exclude-standard' }))

    if root ~= '' and #untracked > 0 then
      local chunks = {}
      local file_limit = math.min(#untracked, 2)

      for index = 1, file_limit do
        local patch = trim(diff_untracked_file(root, untracked[index]))
        if patch ~= '' then
          table.insert(chunks, patch)
        end
      end

      if #chunks > 0 then
        table.insert(parts, '[untracked patch]\n' .. table.concat(chunks, '\n\n'))
      end

      if #untracked > file_limit then
        table.insert(parts, ('[untracked omitted]\n... +%d more files'):format(#untracked - file_limit))
      end
    end

    return limit_text(trim(table.concat(parts, '\n\n')), 120, 6000)
  end,
}
