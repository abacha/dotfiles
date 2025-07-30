-- vim-gist
vim.g.gist_open_browser_after_post = 1                 -- Open browser after posting
vim.g.gist_post_private = 1                            -- Make gists private
vim.g.gist_detect_filetype = 1                         -- Detect filetype automatically
vim.g.gist_clip_command = 'xclip -selection clipboard' -- Use xclip to copy
vim.g.github_token = os.getenv("GITHUB_TOKEN")         -- Use environment variable
