#!/usr/bin/env lua
local function get_first_heading(content)
  -- Match the first # heading, trim spaces
  local heading = content:match("^#%s*(.-)%s*()") or content:match("\n#%s*(.-)%s*()")
  return heading
end

local function sanitize_filename(desired_filename)
  -- Convert the desired filename into safe filename
  local filename = desired_filename:gsub("[^%w%s-]", "") -- Remove special chars
  --  :gsub("%s+", "-")       -- Replace spaces with hyphens
  --  :lower()                -- Convert to lowercase
  return filename .. ".md"
end

local function make_unique_filename(desired_filename, existing_files)
  -- Check if the desired filename already exists
  if not existing_files[desired_filename] then
    return desired_filename
  end

  -- Append a number to the filename if it already exist
  local name = desired_filename:gsub("%.md$", "")
  local counter = 1
  local new_filename

  -- Increment the number to append to the file as long as there
  -- is still a duplicate
  repeat
    new_filename = string.format("%s-%d.md", name, counter)
    counter = counter + 1
  until not existing_files[new_filename]

  return new_filename
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if not file then return false end
  file:write(content)
  file:close()
  return true
end

local function get_files_in_directory(path)
  -- Get a list of file paths within the given path
  local files = {}
  local p = io.popen('find "' .. path .. '" -type f -name "*.md" 2>/dev/null')
  if p then
    for file in p:lines() do
      table.insert(files, file)
    end
    p:close()
  end
  return files
end

local function get_files_in_directory_non_recursive(path)
  local files = {}
  local p = io.popen('ls "' .. path .. '"*.md 2>/dev/null')
  if p then
    for file in p:lines() do
      table.insert(files, file)
    end
    p:close()
  end
  return files
end

local function rename_file(old_path, new_path)
  local ok, err = os.rename(old_path, new_path)
  if not ok then
    print(string.format("Error renaming %s to %s: %s", old_path, new_path, err))
    return false
  end
  return true
end

local function rename_notes(recursive)
  -- Get folder path from user or command line argument
  local folder_path = arg[1]

  -- Flag to specify whether or not we should perform the rename operation recursively
  local recursive =(arg[2] and arg[2] == "--recursive") or false
  if not folder_path then
    io.write("Enter the folder path: ")
    folder_path = io.read()
  end

  if folder_path == "" then
    print("No folder path provided")
    return
  end

  -- Ensure folder path ends with separator
  folder_path = folder_path:gsub("[\\/]$", "") .. "/"

  -- Get all markdown files
  local files
  if recursive then
    files = get_files_in_directory(folder_path)
  else
    files = get_files_in_directory_non_recursive(folder_path)
  end
  local file_mapping = {}
  local existing_files = {}

  -- First pass: Generate new filenames
  for _, file_path in ipairs(files) do
    -- Read the file content
    local content = read_file(file_path)
    if content then
      local heading = get_first_heading(content)
      if heading then
        -- Extract the filename, it's the part at the end of the file that does
        -- not contain any forward slash '/'
        local old_filename = file_path:match("([^/]+)$")

        -- Sanitize the heading and make it safe to use
        local new_filename = sanitize_filename(heading)

        -- Ensure that the filename is unique
        new_filename = make_unique_filename(new_filename, existing_files)

        -- Create a mapping for the old filename to the new filename
        file_mapping[old_filename] = new_filename

        -- Update the existence of the current filename
        existing_files[new_filename] = true
      end
    end
  end

  -- Second pass: Update links/references and rename files
  for _, file_path in ipairs(files) do
    local content = read_file(file_path)
    if content then
      local modified = false
      local new_content = content

      -- Update references in content
      for old_name, new_name in pairs(file_mapping) do
        -- Remove .md extension for matching in-line links
        local old_base = old_name:gsub("%.md$", "")
        local new_base = new_name:gsub("%.md$", "")

        -- Replace references (supporting both [[<filename>]] and (<filename>.md) markdown link formats)
        new_content = new_content:gsub("%[%[" .. old_base .. "%]%]", "[[" .. new_base .. "]]")
        new_content = new_content:gsub("%(" .. old_base .. "%.md%)", "(" .. new_base .. ".md)")

        if new_content ~= content then
          modified = true
        end
      end

      -- Write updated content if modified
      if modified then
        write_file(file_path, new_content)
      end

      -- Rename the file
      local old_filename = file_path:match("([^/]+)$")
      if file_mapping[old_filename] then
        local new_path = folder_path .. file_mapping[old_filename]
        if rename_file(file_path, new_path) then
          print(string.format("Renamed: %s -> %s", old_filename, file_mapping[old_filename]))
        end
      end
    end
  end

  print("Note renaming completed!")
end

-- Call the function
rename_notes()