return {
	"3rd/image.nvim",
	event = "VeryLazy",
	opts = {
		backend = "kitty",
		processor = "magick_cli",
		integrations = {
			markdown = {
				enabled = true,
				clear_in_insert_mode = false,
				download_remote_images = true,
				only_render_image_at_cursor = false,
				filetypes = { "markdown", "vimwiki" },
			},
		},
		max_width = nil,
		max_height = nil,
		max_width_window_percentage = 100,
		max_height_window_percentage = 100,
		window_overlap_clear_enabled = true,
		window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
		editor_only_render_when_focused = true,
		tmux_show_only_in_active_window = true,
		hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
	},
	config = function(_, opts)
		local image = require("image")
		image.setup(opts)

		local function is_image_buffer(bufnr)
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			local ext = bufname:match("^.+%.(.+)$")
			local image_exts = { png = true, jpg = true, jpeg = true, gif = true, webp = true, avif = true }
			return ext and image_exts[ext:lower()] or false
		end

		local function is_in_telescope()
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(bufnr) then
					local ft = vim.bo[bufnr].filetype
					if ft and (ft:match("^[Tt]elescope") or ft == "TelescopePrompt" or ft == "TelescopeResults") then
						return true
					end
				end
			end
			return false
		end

		local function clear_images_from_buffer(bufnr)
			pcall(function()
				local images = image.get_images({ buffer = bufnr })
				for _, img in ipairs(images) do
					img:clear()
				end
			end)
			pcall(function()
				image.clear()
			end)
			pcall(function()
				vim.cmd("mode")
			end)
		end

		local clear_group = vim.api.nvim_create_augroup("ImageClear", { clear = true })

		vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "BufUnload" }, {
			group = clear_group,
			callback = function(event)
				if is_image_buffer(event.buf) and not is_in_telescope() then
					vim.defer_fn(function()
						clear_images_from_buffer(event.buf)
					end, 50)
				end
			end,
		})

		vim.api.nvim_create_autocmd("BufLeave", {
			group = clear_group,
			callback = function(event)
				if is_image_buffer(event.buf) and not is_in_telescope() then
					vim.defer_fn(function()
						clear_images_from_buffer(event.buf)
					end, 100)
				end
			end,
		})

		vim.api.nvim_create_autocmd("BufHidden", {
			group = clear_group,
			callback = function(event)
				if is_image_buffer(event.buf) and not is_in_telescope() then
					vim.defer_fn(function()
						clear_images_from_buffer(event.buf)
					end, 50)
				end
			end,
		})

		vim.api.nvim_create_autocmd("WinClosed", {
			group = clear_group,
			callback = function()
				vim.defer_fn(function()
					for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
						if is_image_buffer(bufnr) and not vim.api.nvim_buf_is_loaded(bufnr) then
							clear_images_from_buffer(bufnr)
						end
					end
				end, 100)
			end,
		})
	end,
}
