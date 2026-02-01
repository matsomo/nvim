-- Telescope image preview integration
local M = {}

M.image_api = nil
M.current_images = {}
M.is_image_preview = false

M.supported_image_formats = {
	["png"] = true,
	["jpg"] = true,
	["jpeg"] = true,
	["gif"] = true,
	["webp"] = true,
	["avif"] = true,
}

function M.is_image(filepath)
	local ext = filepath:match("^.+%.(.+)$")
	return ext and M.supported_image_formats[ext:lower()] or false
end

function M.get_image_api()
	if not M.image_api then
		local ok, api = pcall(require, "image")
		if ok then
			M.image_api = api
		end
	end
	return M.image_api
end

function M.clear_all_telescope_images()
	local api = M.get_image_api()
	if not api then
		return
	end

	for bufnr, img in pairs(M.current_images) do
		pcall(function()
			img:clear()
		end)
	end
	M.current_images = {}

	pcall(function()
		local all_images = api.get_images()
		for _, img in ipairs(all_images) do
			img:clear()
		end
	end)

	M.is_image_preview = false
end

function M.create_image(filepath, winid, bufnr)
	local api = M.get_image_api()
	if not api then
		return
	end

	M.clear_all_telescope_images()

	vim.schedule(function()
		if not vim.api.nvim_win_is_valid(winid) or not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local win_width = vim.api.nvim_win_get_width(winid)
		local win_height = vim.api.nvim_win_get_height(winid)

		local cell_width = 8 -- approximate pixel width of a character
		local cell_height = 16 -- approximate pixel height of a character

		local max_pixel_width = win_width * cell_width
		local max_pixel_height = win_height * cell_height

		local img = api.from_file(filepath, {
			window = winid,
			buffer = bufnr,
			with_virtual_padding = false,
			inline = true,
			x = 0,
			y = 0,
			max_width = win_width,
			max_height = win_height,
			max_width_px = max_pixel_width,
			max_height_px = max_pixel_height,
		})

		if not img then
			return
		end

		M.current_images[bufnr] = img

		pcall(function()
			img:render()
		end)

		vim.defer_fn(function()
			if img and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_win_is_valid(winid) then
				pcall(function()
					img:render()
				end)
			end
		end, 50)

		M.is_image_preview = true
	end)
end

function M.buffer_previewer_maker(filepath, bufnr, opts)
	if M.is_image(filepath) then
		vim.defer_fn(function()
			local winid = vim.fn.bufwinid(bufnr)
			if winid ~= -1 and vim.api.nvim_win_is_valid(winid) and vim.api.nvim_buf_is_valid(bufnr) then
				M.create_image(filepath, winid, bufnr)
			end
		end, 10)
	else
		if M.is_image_preview then
			M.clear_all_telescope_images()
		end
		require("telescope.previewers").buffer_previewer_maker(filepath, bufnr, opts)
	end
end

function M.setup_cleanup_autocmds()
	local telescope_group = vim.api.nvim_create_augroup("TelescopeImageCleanup", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = telescope_group,
		pattern = "TelescopePrompt",
		callback = function()
			local function cleanup_on_close()
				vim.defer_fn(function()
					M.clear_all_telescope_images()
				end, 100)
			end

			vim.api.nvim_create_autocmd({ "WinClosed", "BufHidden" }, {
				callback = cleanup_on_close,
				once = true,
			})
		end,
	})
end

return M
