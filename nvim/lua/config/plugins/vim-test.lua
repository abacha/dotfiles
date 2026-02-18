vim.cmd([[
  " Set the default strategy for running tests.
  let g:test#strategy = 'neovim'

  " Configure the position of the terminal window.
  let g:test#neovim#term_position = 'vert'

  " Define a Vimscript function for the Docker transformation.
  function! s:DockerTransformation(cmd)
    let mapping_file = expand('~/.vim-test-docker-mappings')

    " Proceed only if the mapping file exists.
    if filereadable(mapping_file)
      " Find the project root by looking for a .git directory.
      let project_root = finddir('.git', '.;')

      " If a .git directory is found, get the canonical parent directory path.
      if !empty(project_root)
        let project_root = resolve(fnamemodify(project_root, ':h:p'))
        let project_root = substitute(project_root, '/\+$', '', '')
        let lines = readfile(mapping_file)

        " Loop through the mapping file to find a matching project path.
        for line in lines
          " Skip comments and empty lines.
          if line =~# '^\s*#' || line =~# '^\s*$'
            continue
          endif

          let parts = split(line, '=')
          if len(parts) == 2
            let path = substitute(resolve(fnamemodify(parts[0], ':p')), '/\+$', '', '')
            let container = trim(parts[1])

            " If the current project root matches a mapped path...
            if project_root ==# path
              " Run inside container shell with proper escaping.
              return 'docker exec ' . shellescape(container) . ' sh -lc ' . shellescape(a:cmd)
            endif
          endif
        endfor
      endif
    endif

    " If no mapping is found, return the original command.
    return a:cmd
  endfunction

  " Register the custom transformation with vim-test.
  let g:test#custom_transformations = {'docker': function('s:DockerTransformation')}

  " By default, apply the 'docker' transformation to all test commands.
  let g:test#transformation = 'docker'
]])