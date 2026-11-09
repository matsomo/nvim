-- Go to definition without a language server.
--
-- 1. Names defined in this file: tree-sitter `locals` queries (parameters,
--    inner variables, any language that ships them), then top-level
--    declarations (classes, interfaces, types, enums, ... which the JS/TS
--    locals queries don't cover).
-- 2. Imported names (JS/TS): resolve the import path the way TypeScript does
--    (relative path, tsconfig `paths`, node_modules / workspace symlinks,
--    package.json `exports`), then find the declaration in that file,
--    following barrel re-exports (`export { X } from`, `export * from`).
-- 3. Otherwise: the attached language server if one is running, else rg for a
--    declaration of the name in the repo.
--
-- What it can't do: jumps that need types, like `user.profile.getName()`.
-- Those go to the language server when one is running (<leader>cs).
local M = {}

local uv = vim.uv
local api = vim.api
local ts = vim.treesitter

local JS_FT = {
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
}
local EXTS = { ".ts", ".tsx", ".d.ts", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts", ".d.mts", ".d.cts" }
-- What TypeScript tries, in order, for an import written with a JS extension.
local TS_FOR_JS = {
	js = { ".ts", ".tsx", ".d.ts" },
	jsx = { ".tsx", ".ts", ".d.ts" },
	mjs = { ".mts", ".d.mts" },
	cjs = { ".cts", ".d.cts" },
}
local PKG_FIELDS = { "source", "types", "typings", "module", "main" }
local EXPORT_CONDITIONS = { "source", "types", "import", "module", "default", "require" }

-- ---------------------------------------------------------------------------
-- Files and JSON

local function stat_type(p)
	local s = uv.fs_stat(p)
	return s and s.type
end

local function is_file(p)
	return stat_type(p) == "file"
end

local function is_dir(p)
	return stat_type(p) == "directory"
end

local function real(p)
	return uv.fs_realpath(p) or p
end

local function join(dir, rel)
	if rel:sub(1, 1) == "/" then
		return vim.fn.simplify(rel)
	end
	return vim.fn.simplify(dir .. "/" .. rel)
end

local function read(p)
	local f = io.open(p, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

-- tsconfig.json is JSONC: strip comments (outside strings) and trailing commas.
local function decode_jsonc(text)
	local out, i, n, run = {}, 1, #text, 1
	while i <= n do
		local c = text:byte(i)
		if c == 34 then -- "
			i = i + 1
			while i <= n do
				local d = text:byte(i)
				if d == 92 then -- backslash
					i = i + 2
				elseif d == 34 then
					break
				else
					i = i + 1
				end
			end
			i = i + 1
		elseif c == 47 and text:byte(i + 1) == 47 then -- //
			out[#out + 1] = text:sub(run, i - 1)
			i = text:find("\n", i, true) or n + 1
			run = i
		elseif c == 47 and text:byte(i + 1) == 42 then -- /*
			out[#out + 1] = text:sub(run, i - 1)
			local _, e = text:find("*/", i + 2, true)
			i = (e or n) + 1
			run = i
		else
			i = i + 1
		end
	end
	out[#out + 1] = text:sub(run)
	local s = table.concat(out):gsub(",(%s*[}%]])", "%1")
	local ok, res = pcall(vim.json.decode, s, { luanil = { object = true, array = true } })
	return ok and type(res) == "table" and res or nil
end

local json_cache = {}
local function load_json(p)
	local s = uv.fs_stat(p)
	if not s or s.type ~= "file" then
		return nil
	end
	local hit = json_cache[p]
	if hit and hit.mtime == s.mtime.sec and hit.size == s.size then
		return hit.data
	end
	local text = read(p)
	local data = text and decode_jsonc(text)
	json_cache[p] = { mtime = s.mtime.sec, size = s.size, data = data }
	return data
end

-- ---------------------------------------------------------------------------
-- Module resolution

local resolve_file

local function pick_export(e)
	if type(e) == "string" then
		return e
	end
	if type(e) ~= "table" then
		return nil
	end
	if vim.islist(e) then
		for _, x in ipairs(e) do
			local r = pick_export(x)
			if r then
				return r
			end
		end
		return nil
	end
	for _, k in ipairs(EXPORT_CONDITIONS) do
		local r = e[k] ~= nil and pick_export(e[k])
		if r then
			return r
		end
	end
	for _, v in pairs(e) do
		local r = pick_export(v)
		if r then
			return r
		end
	end
end

-- Directory as a module: package.json entry fields, then index.*
local function resolve_dir(p)
	local pkg = load_json(p .. "/package.json")
	if pkg then
		for _, field in ipairs(PKG_FIELDS) do
			if type(pkg[field]) == "string" then
				local target = join(p, pkg[field])
				if target ~= p and not is_dir(target) then
					local r = resolve_file(target, true)
					if r then
						return r
					end
				end
			end
		end
	end
	for _, ext in ipairs(EXTS) do
		if is_file(p .. "/index" .. ext) then
			return p .. "/index" .. ext
		end
	end
end

-- A path as TypeScript would try it: a `.js` import's `.ts`/`.d.ts` first,
-- then the exact file, added extensions, then a directory.
function resolve_file(p, no_dir)
	local stem, jsext = p:match("^(.*)%.([mc]?jsx?)$")
	for _, ext in ipairs(stem and TS_FOR_JS[jsext] or {}) do
		if is_file(stem .. ext) then
			return stem .. ext
		end
	end
	if is_file(p) then
		return p
	end
	for _, ext in ipairs(EXTS) do
		if is_file(p .. ext) then
			return p .. ext
		end
	end
	if not no_dir and is_dir(p) then
		return resolve_dir(p)
	end
end

local function find_up(start_dir, names)
	return vim.fs.find(names, { upward = true, path = start_dir, type = "file" })[1]
end

local function find_node_module(name, from_dir)
	local dir = from_dir
	while dir do
		local pd = dir .. "/node_modules/" .. name
		if stat_type(pd) then
			return real(pd)
		end
		local parent = vim.fs.dirname(dir)
		if parent == dir then
			return nil
		end
		dir = parent
	end
end

local function split_package(spec)
	if spec:sub(1, 1) == "@" then
		return spec:match("^(@[^/]+/[^/]+)/?(.*)$")
	end
	return spec:match("^([^/]+)/?(.*)$")
end

local resolve_in_package

local function is_typed(p)
	return p:match("%.[mc]?tsx?$") ~= nil
end

local function resolve_package(spec, from_dir)
	local name, sub = split_package(spec)
	if not name then
		return nil
	end
	local candidates = { name }
	if name:sub(1, 1) == "@" then
		candidates[2] = "@types/" .. name:sub(2):gsub("/", "__")
	else
		candidates[2] = "@types/" .. name
	end
	local js_only
	for _, n in ipairs(candidates) do
		local r = resolve_in_package(n, sub, from_dir)
		if r and is_typed(r) then
			return r
		end
		js_only = js_only or r
	end
	return js_only
end

function resolve_in_package(n, sub, from_dir)
	local pd = find_node_module(n, from_dir)
	if pd and is_dir(pd) then
		local pkg = load_json(pd .. "/package.json") or {}
		local exports = pkg.exports
		if type(exports) == "table" and not vim.islist(exports) then
			local key = sub == "" and "." or "./" .. sub
			local entry, star = exports[key], nil
			if entry == nil then
				for k, v in pairs(exports) do
					local pre, post = k:match("^(.-)%*(.*)$")
					if
						pre
						and #key >= #pre + #post
						and key:sub(1, #pre) == pre
						and (post == "" or key:sub(-#post) == post)
					then
						entry, star = v, key:sub(#pre + 1, #key - #post)
						break
					end
				end
			end
			local target = pick_export(entry)
			if target then
				if star then
					target = target:gsub("%*", function()
						return star
					end)
				end
				local r = resolve_file(join(pd, target))
				if r then
					return real(r)
				end
			end
		end
		local r = resolve_file(sub == "" and pd or join(pd, sub))
		if r then
			return real(r)
		end
	end
end

local function resolve_extends(spec, dir)
	local p
	if spec:sub(1, 1) == "." or spec:sub(1, 1) == "/" then
		p = join(dir, spec)
	else
		local name, sub = split_package(spec)
		local pd = name and find_node_module(name, dir)
		if not pd then
			return nil
		end
		p = sub == "" and pd or join(pd, sub)
	end
	if is_dir(p) then
		p = p .. "/tsconfig.json"
	elseif not is_file(p) and is_file(p .. ".json") then
		p = p .. ".json"
	end
	return is_file(p) and p or nil
end

-- `paths` and the directory they're relative to: `baseUrl` if set anywhere in
-- the `extends` chain, else the config that declares `paths`.
local function tsconfig_info(path, depth)
	depth = depth or 0
	local info = {}
	local cfg = depth < 10 and load_json(path)
	if not cfg then
		return info
	end
	local dir = vim.fs.dirname(path)
	local ext = cfg.extends
	if type(ext) == "string" then
		ext = { ext }
	end
	for _, e in ipairs(type(ext) == "table" and ext or {}) do
		local p = type(e) == "string" and resolve_extends(e, dir)
		if p then
			local parent = tsconfig_info(p, depth + 1)
			info.paths = parent.paths or info.paths
			info.paths_base = parent.paths_base or info.paths_base
			info.base_url = parent.base_url or info.base_url
		end
	end
	local co = type(cfg.compilerOptions) == "table" and cfg.compilerOptions or {}
	if type(co.baseUrl) == "string" then
		info.base_url = join(dir, co.baseUrl)
	end
	if type(co.paths) == "table" then
		info.paths = co.paths
		info.paths_base = dir
	end
	return info
end

local function resolve_paths(spec, info)
	if not info.paths then
		return nil
	end
	local best, best_len, star = nil, -1, nil
	for key, targets in pairs(info.paths) do
		local pre, post = key:match("^(.-)%*(.*)$")
		if pre then
			if
				#spec >= #pre + #post
				and spec:sub(1, #pre) == pre
				and (post == "" or spec:sub(-#post) == post)
				and #pre > best_len
			then
				best, best_len, star = targets, #pre, spec:sub(#pre + 1, #spec - #post)
			end
		elseif key == spec then
			best, best_len, star = targets, math.huge, nil
		end
	end
	if type(best) ~= "table" then
		return nil
	end
	local base = info.base_url or info.paths_base
	for _, t in ipairs(best) do
		if type(t) == "string" then
			if star then
				t = t:gsub("%*", function()
					return star
				end)
			end
			local r = resolve_file(join(base, t))
			if r then
				return real(r)
			end
		end
	end
end

--- Resolve an import specifier written in `from_file` to a file path.
function M.resolve_module(spec, from_file)
	local from_dir = vim.fs.dirname(from_file)
	if spec:sub(1, 1) == "." or spec:sub(1, 1) == "/" then
		local r = resolve_file(join(from_dir, spec))
		return r and real(r)
	end
	local tsconfig = find_up(from_dir, { "tsconfig.json", "jsconfig.json" })
	if tsconfig then
		local r = resolve_paths(spec, tsconfig_info(tsconfig))
		if r then
			return r
		end
	end
	return resolve_package(spec, from_dir)
end

-- ---------------------------------------------------------------------------
-- Parsing

local function lang_for(path)
	if path:match("%.tsx$") then
		return "tsx"
	elseif path:match("%.[mc]?ts$") then
		return "typescript"
	elseif path:match("%.[mc]?jsx?$") then
		return "javascript"
	end
end

-- Cheap text check before parsing: could this file declare or export `name`,
-- or pass it through with `export * from` / `export type * from`?
local DECL_KEYWORDS = { "const", "let", "var", "function", "class", "interface", "type", "enum", "namespace", "module" }
local function may_export(src, name)
	if src:find("%*%s*from") then
		return true
	end
	local w = "%f[%w_$]" .. name:gsub("%$", "%%$") .. "%f[^%w_$]"
	if src:find("export%s*{[^}]*" .. w) or src:find("export%s+type%s*{[^}]*" .. w) then
		return true
	end
	for _, kw in ipairs(DECL_KEYWORDS) do
		if src:find("%f[%w_$]" .. kw .. "%*?%s+" .. w) then
			return true
		end
	end
	return false
end

local function loaded_buf(path)
	for _, b in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_is_loaded(b) and api.nvim_buf_get_name(b) == path then
			return b
		end
	end
end

-- Parse a file without opening it in a buffer (no autocmds, no LSP/lint
-- side effects). An already-loaded buffer is used as is, unsaved edits included.
-- With `needle`, a file on disk that can't export it (see may_export) is
-- skipped unparsed: the common case when walking barrel chains.
local function parse_file(path, needle)
	local lang = lang_for(path)
	if not lang then
		return nil
	end
	local buf = loaded_buf(path)
	local src, ok, parser
	if buf then
		src = buf
		ok, parser = pcall(ts.get_parser, buf, lang)
	else
		src = read(path)
		if not src then
			return nil
		end
		if needle and not may_export(src, needle) then
			return nil
		end
		ok, parser = pcall(ts.get_string_parser, src, lang)
	end
	if not ok or not parser then
		return nil
	end
	local tree = parser:parse()[1]
	return tree and { root = tree:root(), src = src, path = path }
end

local function text(node, src)
	return ts.get_node_text(node, src)
end

local function unquote(s)
	return (s:gsub("^['\"`]", ""):gsub("['\"`]$", ""))
end

local function loc(path, node)
	local row, col = node:start()
	return { path = path, row = row, col = col }
end

-- Names bound by a pattern (`const { a, b: c, ...d } = ...`).
local function pattern_names(node, src, out)
	local t = node:type()
	if t == "identifier" or t == "shorthand_property_identifier_pattern" then
		out[#out + 1] = { name = text(node, src), node = node }
	elseif t == "object_assignment_pattern" or t == "assignment_pattern" then
		local left = node:field("left")[1]
		if left then
			pattern_names(left, src, out)
		end
	elseif t == "pair_pattern" then
		local value = node:field("value")[1]
		if value then
			pattern_names(value, src, out)
		end
	else
		for child in node:iter_children() do
			if child:named() then
				pattern_names(child, src, out)
			end
		end
	end
end

local NAMED_DECLS = {
	function_declaration = true,
	generator_function_declaration = true,
	function_signature = true,
	class_declaration = true,
	abstract_class_declaration = true,
	interface_declaration = true,
	type_alias_declaration = true,
	enum_declaration = true,
	module = true,
	internal_module = true,
}

-- Names a top-level statement declares.
local function decl_names(node, src)
	local out = {}
	local t = node:type()
	if t == "lexical_declaration" or t == "variable_declaration" then
		for child in node:iter_children() do
			if child:type() == "variable_declarator" then
				local name = child:field("name")[1]
				if name then
					pattern_names(name, src, out)
				end
			end
		end
	elseif t == "ambient_declaration" or t == "expression_statement" then
		for child in node:iter_children() do
			if child:named() then
				vim.list_extend(out, decl_names(child, src))
			end
		end
	elseif t == "export_statement" then
		local decl = node:field("declaration")[1]
		if decl then
			out = decl_names(decl, src)
		end
	elseif NAMED_DECLS[t] then
		local name = node:field("name")[1]
		if name then
			out[#out + 1] = { name = unquote(text(name, src)), node = name }
		end
	end
	return out
end

-- local name -> { spec = "module", name = "imported" | "default" | "*", node }
local function imports_of(root, src)
	local map = {}
	for stmt in root:iter_children() do
		local source = stmt:type() == "import_statement" and stmt:field("source")[1]
		if source then
			local spec = unquote(text(source, src))
			for clause in stmt:iter_children() do
				if clause:type() == "import_clause" then
					for c in clause:iter_children() do
						local t = c:type()
						if t == "identifier" then
							map[text(c, src)] = { spec = spec, name = "default", node = c }
						elseif t == "namespace_import" then
							local id = c:named_child(0)
							if id then
								map[text(id, src)] = { spec = spec, name = "*", node = id }
							end
						elseif t == "named_imports" then
							for s in c:iter_children() do
								if s:type() == "import_specifier" then
									local n, a = s:field("name")[1], s:field("alias")[1]
									if n then
										map[text(a or n, src)] =
											{ spec = spec, name = unquote(text(n, src)), node = a or n }
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return map
end

local function top_of(path)
	return { path = path, row = 0, col = 0 }
end

-- Find where `path` exports `name` ("default" for the default export),
-- following re-exports. Non-exported top-level declarations count too, so the
-- same function answers "where is X declared in this file".
local function find_export(path, name, seen, depth)
	seen = seen or {}
	depth = depth or 0
	local key = path .. "\0" .. name
	if depth > 15 or seen[key] then
		return nil
	end
	seen[key] = true
	local f = parse_file(path, name ~= "default" and name or nil)
	if not f then
		return nil
	end
	local root, src = f.root, f.src

	local function follow(spec, imported, fallback_node)
		local target = M.resolve_module(spec, path)
		if not target then
			return fallback_node and loc(path, fallback_node)
		end
		if imported == "*" then
			return top_of(target)
		end
		return find_export(target, imported, seen, depth + 1) or top_of(target)
	end

	local decls, stars, namespaces = {}, {}, {}
	local want, export_assign = name, nil
	for stmt in root:iter_children() do
		if stmt:named() and stmt:type() == "export_statement" then
			local decl = stmt:field("declaration")[1]
			local value = stmt:field("value")[1]
			local source = stmt:field("source")[1]
			local is_default, is_assign = false, false
			local clause, ns_export
			for c in stmt:iter_children() do
				local t = c:type()
				if t == "=" then
					is_assign = true
				elseif t == "default" then
					is_default = true
				elseif t == "export_clause" then
					clause = c
				elseif t == "namespace_export" then
					ns_export = c
				end
			end
			if is_assign then
				-- `export = X` (CommonJS-style typings): X is the default export,
				-- and with `declare namespace X {}` its members are named exports.
				local id = stmt:named_child(0)
				export_assign = id and text(id, src)
				if name == "default" and export_assign then
					want = export_assign
				end
			elseif decl then
				local names = decl_names(decl, src)
				for _, d in ipairs(names) do
					if d.name == name and not (is_default and name ~= "default") then
						return loc(path, d.node)
					end
					decls[d.name] = decls[d.name] or d.node
				end
				if is_default and name == "default" then
					return loc(path, names[1] and names[1].node or decl)
				end
			elseif value and is_default and name == "default" then
				if value:type() == "identifier" then
					want = text(value, src)
				else
					return loc(path, value)
				end
			end
			if clause then
				for s in clause:iter_children() do
					if s:type() == "export_specifier" then
						local n, a = s:field("name")[1], s:field("alias")[1]
						local orig = n and unquote(text(n, src))
						if orig and unquote(text(a or n, src)) == name then
							if source then
								return follow(unquote(text(source, src)), orig, s)
							end
							want = orig
						end
					end
				end
			elseif source and ns_export then
				local id = ns_export:named_child(0)
				if id and text(id, src) == name then
					return follow(unquote(text(source, src)), "*", id)
				end
			elseif source and not decl then
				stars[#stars + 1] = unquote(text(source, src))
			end
		elseif stmt:named() then
			for _, d in ipairs(decl_names(stmt, src)) do
				decls[d.name] = decls[d.name] or d.node
			end
			local ns = stmt:type() == "ambient_declaration" and stmt:named_child(0) or stmt
			if ns and (ns:type() == "internal_module" or ns:type() == "module") then
				namespaces[#namespaces + 1] = ns
			end
		end
	end

	if decls[want] then
		return loc(path, decls[want])
	end
	local imp = imports_of(root, src)[want]
	if imp then
		return follow(imp.spec, imp.name, imp.node)
	end
	-- Members of `declare namespace X {}`, preferring the one `export = X` names.
	if name ~= "default" then
		table.sort(namespaces, function(a, b)
			local an, bn = a:field("name")[1], b:field("name")[1]
			return (an and text(an, src) == export_assign or false) and not (bn and text(bn, src) == export_assign)
		end)
		for _, ns in ipairs(namespaces) do
			local body = ns:field("body")[1]
			for member in (body and body:iter_children() or function() end) do
				if member:named() then
					for _, d in ipairs(decl_names(member, src)) do
						if d.name == name then
							return loc(path, d.node)
						end
					end
				end
			end
		end
	end
	if name ~= "default" then
		for _, spec in ipairs(stars) do
			local target = M.resolve_module(spec, path)
			local r = target and find_export(target, name, seen, depth + 1)
			if r then
				return r
			end
		end
	end
end

M.find_export = find_export

-- Lookups that land in node_modules follow long `export *` chains through
-- typings (MUI: >1 s the first time) and don't change between installs.
local nm_cache = {}
local function find_export_cached(path, name)
	if not path:find("/node_modules/", 1, true) then
		return find_export(path, name)
	end
	local s = uv.fs_stat(path)
	local key = path .. "\0" .. name .. "\0" .. (s and s.mtime.sec or 0)
	if nm_cache[key] == nil then
		nm_cache[key] = find_export(path, name) or false
	end
	return nm_cache[key] or nil
end

-- ---------------------------------------------------------------------------
-- Same-file definitions via tree-sitter `locals` queries

local function node_size(n)
	local _, _, sb = n:start()
	local _, _, eb = n:end_()
	return eb - sb
end

local function contains(outer, inner)
	local sr, sc, er, ec = outer:range()
	local ir, ic, jr, jc = inner:range()
	return (sr < ir or (sr == ir and sc <= ic)) and (er > jr or (er == jr and ec >= jc))
end

local function before(a, b)
	local ar, ac = a:start()
	local br, bc = b:start()
	return ar < br or (ar == br and ac <= bc)
end

local function find_local(bufnr, node, name)
	local ok, parser = pcall(ts.get_parser, bufnr)
	if not ok or not parser then
		return nil
	end
	local query = ts.query.get(parser:lang(), "locals")
	local tree = parser:parse()[1]
	if not query or not tree then
		return nil
	end
	local root = tree:root()
	local scopes, defs = {}, {}
	for id, n, meta in query:iter_captures(root, bufnr) do
		local cap = query.captures[id]
		if cap == "local.scope" then
			scopes[#scopes + 1] = n
		elseif
			cap:find("^local%.definition")
			and cap ~= "local.definition.associated"
			and n:type() ~= "property_identifier"
			and text(n, bufnr) == name
		then
			local parent_scope = false
			for k, v in pairs(meta or {}) do
				if type(k) == "string" and k:find("%.scope$") and v == "parent" then
					parent_scope = true
				end
			end
			defs[#defs + 1] = { node = n, parent_scope = parent_scope }
		end
	end

	local best, best_size
	for _, d in ipairs(defs) do
		local chain = {}
		for _, s in ipairs(scopes) do
			if contains(s, d.node) then
				chain[#chain + 1] = s
			end
		end
		table.sort(chain, function(a, b)
			return node_size(a) < node_size(b)
		end)
		local scope = chain[d.parent_scope and 2 or 1] or root
		if contains(scope, node) then
			local size = node_size(scope)
			-- innermost scope wins; within one scope, the last definition before
			-- the cursor (shadowing), else the first after it (hoisting)
			if
				not best
				or size < best_size
				or (
					size == best_size
					and before(d.node, node)
					and (not before(best.node, node) or before(best.node, d.node))
				)
			then
				best, best_size = d, size
			end
		end
	end
	return best and best.node
end

-- ---------------------------------------------------------------------------
-- Jumping

local function jump(target, tagname)
	local from = vim.fn.getpos(".")
	from[1] = api.nvim_get_current_buf()
	vim.fn.settagstack(api.nvim_get_current_win(), { items = { { tagname = tagname, from = from } } }, "t")
	vim.cmd("normal! m'")
	if target.path and target.path ~= api.nvim_buf_get_name(0) then
		vim.cmd.edit(vim.fn.fnameescape(target.path))
	end
	local last = api.nvim_buf_line_count(0)
	pcall(api.nvim_win_set_cursor, 0, { math.min(target.row + 1, last), target.col })
	vim.cmd("normal! zv")
end

local function lsp_definition()
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		if c:supports_method("textDocument/definition") then
			vim.lsp.buf.definition()
			return true
		end
	end
	return false
end

local function repo_root(path)
	return vim.fs.root(path, { ".git" }) or vim.fn.getcwd()
end

-- Last resort for JS/TS: rg for something that declares `name`.
local function rg_declaration(name, dir)
	if not name:match("^[%w_$]+$") then
		return {}
	end
	local word = name:gsub("%$", "\\$")
	local pattern = "(function\\*?|class|interface|type|enum|const|let|var|namespace)\\s+" .. word .. "\\b"
	local res = vim.system({
		"rg",
		"--vimgrep",
		"--no-messages",
		"--case-sensitive", -- override a smart-case/ignore-case ripgreprc
		"-e",
		pattern,
		"-g",
		"*.{ts,tsx,js,jsx,mjs,cjs,mts,cts}",
		"-g",
		"!*.test.*",
		"-g",
		"!*.spec.*",
		"-g",
		"!*.stories.*",
		dir,
	}, { text = true }):wait(3000)
	local out = {}
	for line in (res.stdout or ""):gmatch("[^\n]+") do
		local file, row, col, rest = line:match("^(.-):(%d+):(%d+):(.*)$")
		if file then
			out[#out + 1] = { path = file, row = tonumber(row) - 1, col = tonumber(col) - 1, text = vim.trim(rest) }
		end
		if #out >= 200 then
			break
		end
	end
	return out
end

local function choose(items, name)
	if #items == 1 then
		return jump(items[1], name)
	end
	local cwd = vim.fn.getcwd() .. "/"
	vim.ui.select(items, {
		prompt = "Definitions of " .. name,
		format_item = function(it)
			local p = it.path:sub(1, #cwd) == cwd and it.path:sub(#cwd + 1) or it.path
			return ("%s:%d  %s"):format(p, it.row + 1, it.text or "")
		end,
	}, function(it)
		if it then
			jump(it, name)
		end
	end)
end

local NAME_TYPES = {
	identifier = true,
	type_identifier = true,
	property_identifier = true,
	shorthand_property_identifier = true,
	shorthand_property_identifier_pattern = true,
	statement_identifier = true,
}

local function ancestor(node, t)
	while node do
		if node:type() == t then
			return node
		end
		node = node:parent()
	end
end

-- JS/TS: returns a location, or nil plus an optional hint for the fallback.
local function resolve_js(bufnr, node)
	local path = api.nvim_buf_get_name(bufnr)
	local root = node:tree():root()
	local t = node:type()

	-- On the module string of an import/export: open that module.
	if t == "string_fragment" or t == "string" then
		local stmt = node:parent()
		while stmt and stmt:type() ~= "import_statement" and stmt:type() ~= "export_statement" do
			stmt = stmt:parent()
		end
		local source = stmt and stmt:field("source")[1]
		if source and contains(source, node) then
			local target = M.resolve_module(unquote(text(source, bufnr)), path)
			return target and top_of(target)
		end
		return nil
	end
	local imports = imports_of(root, bufnr)
	if not NAME_TYPES[t] then
		-- A word in a comment (`{@link Foo}`) or JSX text: no scope to go on,
		-- so try it as an import, then a top-level name, then rg.
		local word = vim.fn.expand("<cword>")
		if word == "" then
			return nil
		end
		local found = imports[word] and M.resolve_module(imports[word].spec, path)
		if found then
			return imports[word].name == "*" and top_of(found) or find_export(found, imports[word].name) or top_of(found)
		end
		return find_export(path, word), { dir = repo_root(path), name = word }
	end

	local name = text(node, bufnr)
	local parent = node:parent()

	local function from_import(imp)
		local target = M.resolve_module(imp.spec, path)
		if not target then
			return nil, { dir = repo_root(path) }
		end
		if imp.name == "*" then
			return top_of(target)
		end
		local r = find_export_cached(target, imp.name)
		if r then
			return r
		end
		if imp.name == "default" or target:find("/node_modules/", 1, true) then
			return top_of(target)
		end
		-- Resolved the module but couldn't place the name: search its package.
		local pkg = find_up(vim.fs.dirname(target), { "package.json" })
		return nil, { dir = pkg and vim.fs.dirname(pkg) or repo_root(path), file = target }
	end

	-- `Ns.Member` where Ns is `import * as Ns`: the member is an export of Ns.
	local ptype = parent and parent:type()
	if
		t == "property_identifier"
		or (t == "type_identifier" and ptype == "nested_type_identifier")
		or (t == "identifier" and ptype == "nested_identifier")
	then
		local object = parent:field("object")[1] or parent:field("module")[1] or parent:named_child(0)
		if object and object ~= node and contains(parent, node) then
			local imp = object:type() == "identifier" and imports[text(object, bufnr)]
			if imp and imp.name == "*" then
				local target = M.resolve_module(imp.spec, path)
				return target and (find_export(target, name) or top_of(target))
			end
			if t == "property_identifier" then
				-- A property of a value: depends on types.
				return nil, { needs_types = true }
			end
		end
		if t == "property_identifier" then
			return nil, { needs_types = true }
		end
	end

	-- On an import specifier itself.
	if ancestor(node, "import_statement") then
		local imp = imports[name]
		if imp then
			return from_import(imp)
		end
		local spec = ancestor(node, "import_specifier")
		local alias = spec and spec:field("alias")[1]
		imp = alias and imports[text(alias, bufnr)]
		if imp then
			return from_import(imp)
		end
	end

	-- Scoped definitions in this file (parameters, locals, shadowing).
	local def = find_local(bufnr, node, name)
	if def and not ancestor(def, "import_statement") then
		return loc(path, def)
	end

	if imports[name] then
		return from_import(imports[name])
	end

	-- Top-level declarations the locals queries don't know about.
	local r = find_export(path, name)
	if r then
		return r
	end
	return nil, { dir = repo_root(path) }
end

function M.goto_definition()
	local bufnr = api.nvim_get_current_buf()
	local ok, node = pcall(ts.get_node, { ignore_injections = true })
	if not ok then
		node = nil
	end
	local name = node and NAME_TYPES[node:type()] and text(node, bufnr) or vim.fn.expand("<cword>")

	if node and JS_FT[vim.bo[bufnr].filetype] then
		local target, hint = resolve_js(bufnr, node)
		if target then
			return jump(target, name)
		end
		if lsp_definition() then
			return
		end
		hint = hint or {}
		name = hint.name or name
		if hint.needs_types then
			return vim.notify(
				("gd: `%s` depends on types; start a language server with <leader>cs"):format(name),
				vim.log.levels.INFO
			)
		end
		local hits = rg_declaration(name, hint.dir or repo_root(api.nvim_buf_get_name(bufnr)))
		if #hits > 0 then
			return choose(hits, name)
		end
		if hint.file then
			return jump(top_of(hint.file), name)
		end
		return vim.notify(("gd: no definition found for `%s`"):format(name), vim.log.levels.INFO)
	end

	-- Other languages: tree-sitter locals, then a language server, then Vim's own gd.
	local def = node and NAME_TYPES[node:type()] and find_local(bufnr, node, name)
	if def then
		return jump(loc(api.nvim_buf_get_name(bufnr), def), name)
	end
	if lsp_definition() then
		return
	end
	vim.cmd("normal! gd")
end

return M
