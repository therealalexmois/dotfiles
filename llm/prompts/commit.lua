return {
  input = function(args)
    local context = args and args.context or {}

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

    local function parse_diff_files(diff_text)
      local files = {}
      local seen = {}

      for line in (diff_text or ''):gmatch('[^\r\n]+') do
        local file = line:match('^diff %-%-git a/(.-) b/.+$')
        if file and not seen[file] then
          seen[file] = true
          table.insert(files, file)
        end
      end

      return files
    end

    local function build_visual_input()
      local selected = trim(context.code or '')
      if selected == '' then
        return nil
      end

      local parts = {
        '[source]',
        'visual selection',
      }

      local files = parse_diff_files(selected)
      if #files > 0 then
        table.insert(parts, '')
        table.insert(parts, '[changed files]')
        table.insert(parts, table.concat(take(files, 30), '\n'))
      end

      table.insert(parts, '')
      table.insert(parts, '[patch preview]')
      table.insert(parts, limit_text(selected, 180, 12000))

      return trim(table.concat(parts, '\n'))
    end

    local function build_staged_input()
      local files = trim(run({ 'git', 'diff', '--name-only', '--cached' }))
      local stat = trim(run({ 'git', 'diff', '--stat', '--cached' }))
      local patch = trim(run({ 'git', 'diff', '--no-ext-diff', '--cached', '--unified=1' }))

      if patch == '' then
        return '[source]\nstaged git changes\n\n[patch preview]\n<empty>'
      end

      local parts = {
        '[source]',
        'staged git changes',
      }

      if files ~= '' then
        table.insert(parts, '')
        table.insert(parts, '[changed files]')
        table.insert(parts, table.concat(take(split_lines(files), 40), '\n'))
      end

      if stat ~= '' then
        table.insert(parts, '')
        table.insert(parts, '[diff summary]')
        table.insert(parts, limit_text(stat, 80, 4000))
      end

      table.insert(parts, '')
      table.insert(parts, '[patch preview]')
      table.insert(parts, limit_text(patch, 180, 12000))

      return trim(table.concat(parts, '\n'))
    end

    return build_visual_input() or build_staged_input()
  end,
}
