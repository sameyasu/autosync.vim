" Author: sameyasu
" Description: Automatic synchronization on save your file.

let s:msg_prefix = '[autosync.vim] '

let s:required = [
\ 'g:autosync_local_base_path',
\ 'g:autosync_remote_base_path',
\ 'g:autosync_remote_host',
\ 'g:autosync_exclude_opts',
\ ]

for v in s:required
    if !exists(v)
        echo s:msg_prefix . 'No set variable "' . v . '"'
        finish
    endif
endfor

let s:rsync = '/usr/bin/rsync'
let s:local_base_path = g:autosync_local_base_path
let s:remote_base_path = g:autosync_remote_base_path
" Recommend: Host alias of your ssh config (~/.ssh/config)
let s:remote_host = g:autosync_remote_host
let s:exclude_opt = join(map(g:autosync_exclude_opts, '"--exclude=\"" . v:val . "\""'), " ")


" autocmdのパターンに変数が使えないから、仕方なく環境変数に突っ込む
let $_AUTOSYNC_FILE_PATTERN = s:local_base_path . '*'

function! s:sync_with_server(src_path) abort
    if match(a:src_path, s:local_base_path) !=# -1
        echo s:msg_prefix . 'Syncing files with ' . s:remote_host . ' ...'
        let l:dest_path = substitute(a:src_path, s:local_base_path, s:remote_base_path, '')
        " FIXME: OS Command Injection
        let l:sync_cmd = s:rsync . ' -av --delete ' . s:exclude_opt . ' ' . a:src_path . ' ' . s:remote_host . ':' . l:dest_path
        echo l:sync_cmd
        echo system(l:sync_cmd)
    else
        echo s:msg_prefix . 'No need to sync.'
    endif
endfunction

function! s:turn_on_autosync() abort
    augroup autosync
        autocmd!
        autocmd BufWritePost $_AUTOSYNC_FILE_PATTERN :call s:sync_with_server(expand('%:p'))
    augroup END
    echo s:msg_prefix . 'Turned On.'
endfunction

function! s:turn_off_autosync() abort
    augroup autosync
        autocmd!
    augroup END
    echo s:msg_prefix . 'Turned Off.'
endfunction

command! AutoSyncOn call s:turn_on_autosync()
command! AutoSyncOff call s:turn_off_autosync()

" 強制同期コマンド
command! SyncNow call s:sync_with_server(s:local_base_path)

" noremap <C-s> :SyncNow<CR>
