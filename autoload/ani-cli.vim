function! s:version_info()
	echomsg "0.0.1"
	let g:ANI_CLI_TO_EXIT
endfunction

function! s:help_info()
	let old_bufnr = bufnr()
	let bufnr = bufadd('AniCli.vim help')
	call bufload(bufnr)
	execute bufnr.'buffer'
	if !&modifiable
		return
	endif
	call append(line('$'), split("
	\Usage:
	\\n:Ani [options] [query]
	\\n:Ani [query] [options]
	\\n:Ani [options] [query] [options]
	\\n
	\\nOptions (case sensitive):
	\\n	-c, --continue
	\\n		Continue watching from history
	\\n	-d, --download
	\\n		Download the video instead of playing it
	\\n	-D, --delete
	\\n		Delete history
	\\n	-l, --logview
	\\n		Show logs (not supported)
	\\n	-s, --syncplay
	\\n		Use Syncplay to watch with friends
	\\n	-S, --select-nth
	\\n		Select nth entry
	\\n	-q, --quality
	\\n		Specify the video quality
	\\n	-v, --vlc
	\\n		Use VLC to play the video
	\\n	-V, --version
	\\n		Show the version of the plugin
	\\n	-h, --help
	\\n		Show this help message and exit
	\\n	-e, --episode, -r, --range
	\\n		Specify the number of episodes to watch
	\\n	--dub
	\\n		Play dubbed version
	\\n	--skip
	\\n		Use ani-skip to skip the intro of the episode (mpv only)
	\\n	--no-detach
	\\n		Don't detach the player (useful for in-terminal playback, mpv only)
	\\n	--exit-after-play
	\\n		Exit the player, and return the player exit code (useful for non interactive scenarios, works only if --no-detach is used, mpv only)
	\\n	--skip-title <title>
	\\n		Use given title as ani-skip query
	\\n	-N, --nextep-countdown
	\\n		Display a countdown to the next episode
	\\nSome example usages:
	\\n	:Ani -q 720p banana fish
	\\n	:Ani --skip --skip-title \"one piece\" -S 2 one piece
	\\n	:Ani -d -e 2 cyperpunk edgerunners
	\\n	:Ani --vlc cyperpunk edgerunners -q 1080p -e 4
	\\n	:Ani blue lock -e 5-6
	\\n	:Ani -e \"5 6\" blue lock
	\", "\n"))
	1delete
	setlocal nomodified
	setlocal nomodifiable
	setlocal buftype=nofile
	setlocal filetype=
	setlocal undolevels=-1
	let prev_filetype = g:prev_filetype
	execute "noremap <buffer> q <cmd>execute bufnr().\"bwipeout!\"<bar>".(prev_filetype==#"alpha"?"Alpha":old_bufnr."buffer")."<cr>"
	execute "noremap <buffer> <leader>? <cmd>execute bufnr().\"bwipeout!\"<bar>".(prev_filetype==#"alpha"?"Alpha":old_bufnr."buffer")."<cr>"
	let g:ANI_CLI_TO_EXIT = 1
endfunction

if !exists('*Repr_Shell')
	function Repr_Shell(string)
		let result = ''
		let state = 'norm'
		for char in a:string
			if state ==# 'norm'
				if char ==# '\'
					let state = 'backslash'
				elseif char ==# ' '
					let result .= '\ '
				elseif char ==# '('
					let result .= '\('
				elseif char ==# ')'
					let result .= '\)'
				elseif char ==# '*'
					let result .= '\*'
				elseif char ==# '#'
					let result .= '\#'
				elseif char ==# '?'
					let result .= '\?'
				elseif char ==# '['
					let result .= '\['
				elseif char ==# ']'
					let result .= '\]'
				elseif char ==# '{'
					let result .= '\{'
				elseif char ==# '}'
					let result .= '\}'
				elseif char ==# '$'
					let result .= '\$'
				elseif char ==# '^'
					let result .= '\^'
				elseif char ==# '&'
					let result .= '\&'
				elseif char ==# '!'
					let result .= '\!'
				elseif char ==# '~'
					let result .= '\~'
				elseif char ==# ''''
					let result .= '\'''
				elseif char ==# '"'
					let result .= '\"'
				elseif char ==# '`'
					let result .= '\`'
				elseif char ==# '<'
					let result .= '\<'
				elseif char ==# '>'
					let result .= '\>'
				elseif char ==# '|'
					let result .= '\|'
				elseif char ==# ';'
					let result .= '\;'
				elseif char ==# "\n"
					let result .= '\\n'
				else
					let result .= char
				endif
			elseif state ==# 'backslash'
				if char ==# '\'
					let result .= '\\\\'
				elseif v:false
				\|| char ==# 'n'
				\|| char ==# 't'
					let result .= '\\'.char
				else
					let result .= '\'.char
				endif
				let state = 'norm'
			else
				echohl ErrorMsg
				echomsg "AniCli.vim: Repr_Shell: Internal Error: Invalid state: ".state
				echohl Normal
			endif
		endfor
		if state ==# 'backslash'
			let result .= '\\'
		endif
		return result
	endfunction
endif

function! s:episodes_list(id, allanime_refr, allanime_api, agent, mode)
	let episodes_list_gql = 'query ($showId: String!) {    show(        _id: $showId    ) {        _id availableEpisodesDetail    }}'
	return system('curl -e '.a:allanime_refr.' -s -G '.a:allanime_api.'/api --data-urlencode '.Repr_Shell('variables={"showId":"'.a:id.'"}').' --data-urlencode query='.Repr_Shell(episodes_list_gql).' -A '.Repr_Shell(a:agent).'|sed -nE s\|.\*'.a:mode.'\":\\\[\(\[0-9.\",\]\*\)\].\*\|\\1\|p|sed s\|,\|\\n\|g\;s\|\"\|\|g|sort -n -k 1')
endfunction

function! s:process_hist_entry(ep_no, id, title, allanime_refr, allanime_api, agent, mode)
	let ep_list = s:episodes_list(a:id, a:allanime_refr, a:allanime_api, a:agent, a:mode)
	let latest_ep = split(ep_list, "\n")[-1]
	let title = substitute(a:title, '[0-9]\+ episodes', latest_ep.' episodes', '')
	if a:ep_no ># len(ep_list)
		return ""
	endif
	return a:id."\t".a:title." - episode ".a:ep_no."\n"
endfunction

function! s:nth(list, prompt)
	if len(a:list) ==# 1
		let first = a:list[0]
		let first = split(first, "\t")
		return first[1] . "\t" . first[2]
	endif
	let lines = []
	for line in a:list
		let line = split(line, "\t")
		let line = line[0] . "\t". line[2]
		let line = substitute(line, "\t", " ", "")
		let lines += [[line, 'execute']]
	endfor
	let opts = {'title': 'AniCli.vim: '.a:prompt}
	return quickui#listbox#inputlist(lines, opts)
endfunction

function! s:provider_init(name, pattern, resp)
	let output = system('printf '.Repr_Shell(a:resp).'|sed -n '.Repr_Shell(a:pattern))
	let output = trim(output)
	let output = split(output, ":")
	if len(output) <# 2
		echohl ErrorMsg
		echomsg "AniCli.vim: warning: Wrong link"
		echohl Normal
		return ''
	endif
	let output = output[1]
	let output = trim(substitute(output, "..", "&\n", "g"))
	let output_array = split(output, "\n")
	let output = ""
	for item in output_array
		if v:false
		elseif item ==# "01"
			let output .= "9"
		elseif item ==# "08"
			let output .= "0"
		elseif item ==# "05"
			let output .= "="
		elseif item ==# "0a"
			let output .= "2"
		elseif item ==# "0b"
			let output .= "3"
		elseif item ==# "0c"
			let output .= "4"
		elseif item ==# "07"
			let output .= "?"
		elseif item ==# "00"
			let output .= "8"
		elseif item ==# "5c"
			let output .= "d"
		elseif item ==# "0f"
			let output .= "7"
		elseif item ==# "5e"
			let output .= "f"
		elseif item ==# "17"
			let output .= "/"
		elseif item ==# "54"
			let output .= "l"
		elseif item ==# "09"
			let output .= "1"
		elseif item ==# "48"
			let output .= "p"
		elseif item ==# "4f"
			let output .= "w"
		elseif item ==# "0e"
			let output .= "6"
		elseif item ==# "5b"
			let output .= "c"
		elseif item ==# "5d"
			let output .= "e"
		elseif item ==# "0d"
			let output .= "5"
		elseif item ==# "53"
			let output .= "k"
		elseif item ==# "1e"
			let output .= "&"
		elseif item ==# "5a"
			let output .= "b"
		elseif item ==# "59"
			let output .= "a"
		elseif item ==# "4a"
			let output .= "r"
		elseif item ==# "4c"
			let output .= "t"
		elseif item ==# "4e"
			let output .= "v"
		elseif item ==# "57"
			let output .= "o"
		elseif item ==# "51"
			let output .= "i"
		endif
	endfor
	let output = substitute(output, '/clock', '/clock.json', '')
	return output
endfunction

function! s:get_links(provider_id, allanime_refr, allanime_base, agent, provider_name)
	let episode_link=system('curl -e '.Repr_Shell(a:allanime_refr).' -s https://'.Repr_Shell(a:allanime_base).Repr_Shell(a:provider_id).' -A '.Repr_Shell(a:agent))
	echomsg "eplink is: ".episode_link.";"
	let episode_link=substitute(episode_link, '},{', '\n', 'g')
	let matches=matchlist(episode_link, '[^\n]*link":"\([^"]*\)"[^\n]*"resolutionStr":"\([^"]*\)".*')
	let episode_link=matches[2].' >'.matches[1]
	let matches=matchlist(episode_link, '.*hls","url":"\([^"]*\)".*"hardsub_lang":"en-US".*')
	if len(matches) >=# 2
		let episode_link=matches
	endif
	unlet matches
	echomsg "episode_link is: ".episode_link.";"
	
	if v:false
	elseif episode_link =~# 'repackager.winxmp.com'
		let extract_link_2 = []
		let extract_link = split(episode_link, "\n")
		for i in extract_link
			let i = split(i, '>')[1]
			let i = substitute(i, 'repackager.winxmp.com/', '', 'g')
			let i = substitute(i, '\.urlset.*', '', 'g')
			let extract_link_2 += [i]
		endfor
		let extract_link = extract_link_2
		let episode_link_2 = substitute('.*/,\([^/]*\),/mp4.*', '\1', '')
		let episode_link_2 = split(episode_link_2, ",")
		let result = []
		for i in episode_link_2
			let j = j.' >'.extract_link
			let j = substitute(result, ',[^/]*', j, 'g')
			let result += [j]
		endfor
		call sort(result, 'N')
		call reverse(result)
	elseif v:false
	\|| episode_link =~# 'vipanicdn'
	\|| episode_link =~# 'anifastcdn'
		let episode_link = split(episode_link, "\n")
		if stridx(episode_link[0], 'original.m3u') !=# -1
			let result = episode_link
		else
			let extract_link = episode_link[0]
			let extract_link = split(extract_link, '>')[1]
			let relative_link = substitute(extract_link, '[^/]*$', '', '')
			let result = system('curl -e '.Repr_Shell(a:allanime_refr).' -s '.Repr_Shell(extract_link).' -A '.Repr_Shell(a:agent).'|sed s\|\^\#.\*x\|\|g\;s\|,.\*\|p\|g;/\^\#/d\;\$\!N\;s\|\\n\|\ \>\||sed s\|\>\|\>'.Repr_Shell(relative_link).'\|g')
			let result = split(result, "\n")
			call sort(result, 'N')
			call reverse(result)
		endif
	else
		if episode_link !=# ""
			let result = episode_link
		else
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Something went wrong"
			echomsg "AniCli.vim: abort"
			echohl Normal
			let g:ANI_CLI_TO_EXIT = v:true
			return
		endif
	endif
	if !exists('g:ANI_CLI_NON_INTERACTIVE') || !g:ANI_CLI_NON_INTERACTIVE
		echomsg a:provider_name." Links fetched"
	endif
	return result
endfunction

function! s:generate_link(number, resp, allanime_refr, allanime_base, agent)
	if v:false
	elseif a:number ==# 1
		let provider_name = "winxmp"
		let provider_id = s:provider_init(provider_name, "/Default :/p", a:resp)
	elseif a:number ==# 2
		let provider_name = "dropbox"
		let provider_id = s:provider_init(provider_name, "/Sak :/p", a:resp)
	elseif a:number ==# 3
		let provider_name = "wetransfer"
		let provider_id = s:provider_init(provider_name, "/Kir :/p", a:resp)
	elseif a:number ==# 4
		let provider_name = "sharepoint"
		let provider_id = s:provider_init(provider_name, "/S-mp4 :/p", a:resp)
	else
		let provider_name = "gogoanime"
		let provider_id = s:provider_init(provider_name, "/Luf-mp4 :/p", a:resp)
	endif

	if provider_id ==# ""
		echohl ErrorMsg
		echomsg "AniCli.vim: warning: wrong provider id"
		echohl Normal
		return ''
	endif
	return s:get_links(provider_id, a:allanime_refr, a:allanime_base, a:agent, provider_name)
endfunction

function! s:select_quality(quality, links)
	if v:false
	elseif a:quality ==# "best"
		let result = a:links[0]
	elseif a:quality ==# "worst"
		let links = reverse(copy(a:links))
		let result = links[match(links, '^[0-9][0-9][0-9][0-9]\?')]
		unlet links
	else
		let result = a:links[match(a:links, a:quality)]
	endif
	if result ==# ""
		echomsg "Specified quality not found, defaulting to best"
		let result = a:links[0]
	endif
	let result = split(result, '>')[1]
	return result
endfunction

function! s:get_episode_url(allanime_refr, allanime_api, id, mode, ep_no, agent, allanime_base, quality, ep_list)
	let episode_embed_gql = 'query\ \(\$showId:\ String\!,\ \$translationType:\ VaildTranslationTypeEnumType\!,\ \$episodeString:\ String\!\)\ \{\ \ \ \ episode\(\ \ \ \ \ \ \ \ showId:\ \$showId\ \ \ \ \ \ \ \ translationType:\ \$translationType\ \ \ \ \ \ \ \ episodeString:\ \$episodeString\ \ \ \ \)\ \{\ \ \ \ \ \ \ \ episodeString\ sourceUrls\ \ \ \ \}\}'
	let resp = system('curl -e '.Repr_Shell(a:allanime_refr).' -s -G '.Repr_Shell(a:allanime_api).'/api --data-urlencode variables={\"showId\":\"'.Repr_Shell(a:id).'\",\"translationType\":\"'.Repr_Shell(a:mode).'\",\"episodeString\":\"'.Repr_Shell(a:ep_no).'\"\} --data-urlencode query='.episode_embed_gql.' -A '.Repr_Shell(a:agent).'|tr \{\} \\n|sed s\|\\\\u002F\|\\/\|g\;s\|\\\\\|\|g|sed -nE s\|.\*sourceUrl\":\"--\(\[\^\"\]\*\)\".\*sourceName\":\"\(\[\^\"\]\*\)\".\*\|\\2\ :\\1\|p')

	let links = []
	for provider in range(5)
		let link = s:generate_link(provider, resp, a:allanime_refr, a:allanime_base, a:agent)
		if exists('g:ANI_CLI_TO_EXIT') && g:ANI_CLI_TO_EXIT
			return ''
		endif
		if link !=# ''
			let links += [link]
		endif
	endfor

	let links2=[]
	for link in links
		let link = substitute(link, '^Mp4-', '', '')
		if link =~# "http" && link !~# "Alt"
			let links2 += [link]
		endif
	endfor
	call sort(links2, 'N')
	call reverse(links2)

	unlet links

	let episode = s:select_quality(a:quality, links2)
	let found = v:false
	for i in a:ep_no
		if match(a:ep_list, i) !=# -1
			let found = v:true
			break
		endif
	endfor
	if found
		if episode ==# ""
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Episode is released, but no valid sources!"
			echomsg "AniCli.vim: abort"
			echohl Normal
			let g:ANI_CLI_TO_EXIT = v:true
		endif
	else
		if episode ==# ""
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Episode not released!"
			echomsg "AniCli.vim: abort"
			echohl Normal
			let g:ANI_CLI_TO_EXIT = v:true
		endif
	endif
	return episode
endfunction

function! s:play_episode(ep_no, player_function, log_episode, skip_intro, mal_id, episode, agent, allanime_refr, allanime_api, id, mode, allanime_base, quality, ep_list)
	if a:log_episode && a:player_function !=# "debug" && a:player_function !=# "download"
		echohl ErrorMsg
		echomsg "AniCli.vim: error: logging is not supported"
		echomsg "AniCli.vim: abort"
		echohl Normal
		let g:ANI_CLI_TO_EXIT = v:true
		return
	endif
	if a:skip_intro
		let skip_flag = system('ani-skip -q '.a:mal_id.' -e '.a:ep_no)
	endif
	let episode = a:episode
	if episode ==# ""
		let episode = s:get_episode_url(a:allanime_refr, a:allanime_api, a:id, a:mode, a:ep_no, a:agent, a:allanime_base, a:quality, a:ep_list)
	endif
	if v:false
	elseif a:player_function ==# "android_mpv"
		silent! call system('nohup am start --user 0 -a android.intent.action.VIEW -d '.Repr_Shell(episode).' -n is.xyz.mpv/.MPVActivity')
	else
		echomsg "Not implemented yet"
	endif
endfunction

function! s:play(ep_no, ep_list, player_function, log_episode, skip_intro, mal_id, episode, agent, allanime_refr, allanime_api, id, mode, allanime_base, quality)
	let start = system('printf %s '.a:ep_no.'|grep -Eo \^\(-1\|\[0-9\]+\(\\.\[0-9\]+\)\?\)')
	let end = system('printf %s '.a:ep_no.'|grep -Eo \(-1\|\[0-9\]+\(\\.\[0-9\]+\)\?\)\$')
	let ep_list = split(a:ep_list, "\n")
	let ep_no = a:ep_no
	if start ==# -1
		let ep_no = ep_list[-1]
		let start = ""
	endif
	if end ==# "" || end ==# start
		let start = ""
		let end = ""
	endif
	if end ==# -1
		let end = ep_list[-1]
	endif
	let ep_no = split(ep_no, "\n")
	let line_count = len(ep_no)
	if line_count !=# 1 || start !=# ""
		if start ==# ""
			let start = ep_no[0]
		endif
		if end ==# ""
			let end = ep_no[-1]
		endif
		let range = system('printf %s'."\n".' '.Repr_Shell(join(ep_list, "\n")).'|sed -nE /\^'.start.'\$/,/\^'.end.'\$/p')
		if range ==# ""
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Invalid range"
			echomsg "AniCli.vim: abort"
			echohl Normal
			let g:ANI_CLI_TO_EXIT = 1
			return
		endif
		let range = split(range, "\n")
		for i in range
			echomsg "Playing episode ".ep_no."..."
			call s:play_episode(ep_no, a:player_function, a:log_episode, a:skip_intro, a:mal_id, a:episode, a:agent, a:allanime_refr, a:allanime_api, a:id, a:mode, a:allanime_base, a:quality, ep_list)
			if exists('g:ANI_CLI_TO_EXIT') && g:ANI_CLI_TO_EXIT
				return
			endif
		endfor
	else
		call s:play_episode(ep_no, a:player_function, a:log_episode, a:skip_intro, a:mal_id, a:episode, a:agent, a:allanime_refr, a:allanime_api, a:id, a:mode, a:allanime_base, a:quality, ep_list)
	endif
endfunction

function! AniCli(...)
	if exists('g:ANI_CLI_TO_EXIT')
		unlet g:ANI_CLI_TO_EXIT
	endif

	let agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
	let allanime_refr="https://allmanga.to"
	let allanime_base="allanime.day"
	let allanime_api="https://api.".allanime_base
	if $ANI_CLI_MODE ==# ""
		let mode="sub"
	else
		let mode=$ANI_CLI_MODE
	endif
	if $ANI_CLI_DOWNLOAD_DIR ==# ""
		let download_dir="."
	else
		let download_dir=$ANI_CLI_DOWNLOAD_DIR
	endif
	if $ANI_CLI_LOG ==# ""
		let log_episode=0
	else
		let log_episode=$ANI_CLI_LOG
	endif
	if $ANI_CLI_QUALITY ==# ""
		let quality="best"
	else
		let quality=$ANI_CLI_QUALITY
	endif

	if $ANI_CLI_PLAYER ==# ""
		let os = system('uname -a')
		if v:false
		elseif os =~# 'Darwin'
			let player_function = system('where_iina')
		elseif os =~# 'ndroid'
			let player_function="android_mpv"
		elseif os =~# 'neptune'
			let player_function="flatpak_mpv"
		elseif os =~# 'MINGW' || os =~# 'WSL2'
			let player_function="mpv.exe"
		elseif os =~# 'ish'
			let player_function="iSH"
		else
			let player_function="mpv"
		endif
	else
		let player_function=$ANI_CLI_PLAYER
	endif

	if $ANI_CLI_NO_DETACH ==# ""
		let no_detach = 0
	else
		let no_detach = $ANI_CLI_NO_DETACH
	endif
	if $ANI_CLI_EXIT_AFTER_PLAY ==# ""
		let exit_after_play = 0
	else
		let exit_after_play = $ANI_CLI_EXIT_AFTER_PLAY
	endif
	if $ANI_CLI_EXTERNAL_MENU ==# ""
		let use_external_menu = 0
	else
		let use_external_menu = $ANI_CLI_EXTERNAL_MENU
	endif
	if $ANI_CLI_SKIP_INTRO ==# ""
		let skip_intro = 0
	else
		let skip_intro = $ANI_CLI_SKIP_INTRO
	endif
	if $ANI_CLI_SKIP_TITLE ==# ""
		let skip_title = 0
	else
		let skip_title = $ANI_CLI_SKIP_TITLE
	endif
	if $ANI_CLI_HIST_DIR ==# ""
		if $XDG_STATE_HOME ==# ""
			let hist_dir = $HOME.'/.local/state'
		else
			let hist_dir = $XDG_STATE_HOME
		endif
		let hist_dir .= '/ani-cli'
	else
		let hist_dir = $ANI_CLI_HIST_DIR
	endif
	let hist_dir = expand(hist_dir)
	if !isdirectory(hist_dir)
		call mkdir(hist_dir, 'p')
	endif
	let histfile = hist_dir.'/ani-hsts'
	if !filereadable(histfile)
		if writefile([], histfile, '') ==# -1
			echohl ErrorMsg
			echomsg "Ani-cli.vim: error: unable to write file"
			echomsg "Ani-cli.vim: abort"
			echohl Normal
			return
		endif
	endif
	if $ANI_CLI_DEFAULT_SOURCE ==# ""
		let search = "scrape"
	else
		let search = $ANI_CLI_DEFAULT_SOURCE
	endif

	let query = ''
	let index = ''

	let idx = 0
	let skip = 0
	for argument in a:000
		if exists('g:ANI_CLI_TO_EXIT') && g:ANI_CLI_TO_EXIT
			return
		endif
		if skip ># 0
			let skip -= 1
			let idx += 1
			continue
		endif
		if a:0 ># index + 1
			let next_argument = a:000[index + 1]
		endif
		if argument ==# "-v" || argument ==# "--vlc"
			let os = system('uname -a')
			if v:false
			elseif os =~# 'ndroid'
				let player_function='android_vlc'
			elseif os =~# '^MINGW' || os =~# 'WSL2'
				let player_function='vlc.exe'
			elseif os =~# 'ish'
				let player_function='iSH'
			else
				let player_function='vlc'
			endif
		elseif argument ==# "-s" || argument ==# "--syncplay"
			let os = system('uname -s')
			if os =~# '^Darwin'
				let player_function = "/Applications/Syncplay.app/Contents/MacOS/syncplay"
			elseif os =~# '^MINGW' || os =~# 'Msys$'
				call setenv('PATH', $PATH.':/c/Program Files (x86)/Syncplay/')
				let player_function = 'syncplay.exe'
			else
				let player_function = 'syncplay'
			endif
		elseif argument ==# "-q" || argument ==# "--quality"
			if !exists('next_argument')
				echohl ErrorMsg
				echomsg "AniCli.vim: error: missing argument for --quality"
				echomsg "AniCli.vim: abort"
				echohl Normal
				return
			endif
			let quality = next_argument
			let skip = 1
		elseif argument ==# "-S" || argument ==# "--select-nth"
			if !exists('next_argument')
				echohl ErrorMsg
				echomsg "AniCli.vim: error: missing argument for --select-nth"
				echomsg "AniCli.vim: abort"
				echohl Normal
				return
			endif
			let index = next_argument
			let skip = 1
		elseif argument ==# "-c" || argument ==# "--continue"
			let search = "history"
		elseif argument ==# "-d" || argument ==# "--download"
			let player_function = "download"
		elseif argument ==# "-D" || argument ==# "--delete"
			call writefile([], histfile, '')
			return
		elseif argument ==# "-l" || argument ==# "--logview"
			echohl ErrorMsg
			echomsg "AniCli.vim: error: logging is not supported"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		elseif argument ==# "-V" || argument ==# "--version"
			call s:version_info()
		elseif argument ==# "-h" || argument ==# "--help"
			call s:help_info()
		elseif v:false
		\|| argument ==# "-e"
		\|| argument ==# "--episode"
		\|| argument ==# "-r"
		\|| argument ==# "--range"
			if !exists('next_argument')
				echohl ErrorMsg
				echomsg "AniCli.vim: error: missing argument for --episode or --range"
				echomsg "AniCli.vim: abort"
				echohl Normal
				return
			endif
			let ep_no = next_argument
			if !exists('index')
				let g:ANI_CLI_NON_INTERACTIVE = v:true
			endif
			let skip = 1
		elseif argument ==# "--dub"
			let mode = "dub"
		elseif argument ==# "--no-detach"
			let no_detach = 1
		elseif argument ==# "--exit-after-play"
			let exit_after_play = 1
		elseif argument ==# "--rofi"
			echohl ErrorMsg
			echomsg "AniCli.vim: error: rofi is not supported"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		elseif argument ==# "--skip"
			let skip_intro = 1
		elseif argument ==# "--skip-title"
			if !exists('next_argument')
				echohl ErrorMsg
				echomsg "AniCli.vim: error: missing argument for --skip-title"
				echomsg "AniCli.vim: abort"
				echohl Normal
				return
			endif
			let skip_title = next_argument
			let skip = 1
		elseif argument ==# "-N" || argument ==# "--nextep-countdown"
			let search = "nextep"
		elseif argument ==# "-U" || argument ==# "--update"
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Please update plugin by your plugin manager"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		else
			let argument = trim(argument)
			let argument = substitute(argument, ' ', '+', 'g')
			let query .= " ".argument
		endif
		let idx += 1
	endfor

	if exists('g:ANI_CLI_TO_EXIT') && g:ANI_CLI_TO_EXIT
		return
	endif

	if !executable('curl')
		echohl ErrorMsg
		echomsg "AniCli.vim: error: curl is not installed"
		echomsg "AniCli.vim: abort"
		echohl Normal
		return
	endif
	if skip_intro && !executable('ani-skip')
		echohl ErrorMsg
		echomsg "AniCli.vim: error: ani-skip is not installed"
		echomsg "AniCli.vim: abort"
		echohl Normal
		return
	endif
	if v:false
	elseif player_function ==# "debug"
	elseif player_function ==# "download"
		if !executable('ffmpeg')
			echohl ErrorMsg
			echomsg "AniCli.vim: error: ffmpeg is not installed"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		endif
		if !executable('aria2c')
			echohl ErrorMsg
			echomsg "AniCli.vim: error: aria2c is not installed"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		endif
	elseif player_function =~# '^flatpak'
		if !executable('flatpak')
			echohl ErrorMsg
			echomsg "AniCli.vim: error: flatpak is not installed"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		endif
		silent! call system('flatpak info io.mpv.Mpv')
		if v:shell_error !=# 0
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Program \"mpv (flatpak)\" not found. Please install it."
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		endif
	elseif player_function =~# '^android'
		echomsg "Checking of players on Android is disabled"
	elseif player_function =~# 'iSH'
		echomsg "Checking of players on iOS is disabled"
	elseif player_function =~# 'iina'
	else
		if !executable(player_function)
			echohl ErrorMsg
			echomsg "AniCli.vim: error: Program ".player_function." is not installed"
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		endif
	endif

	if search ==# "history"
		let anime_list = []
		let lines = readfile(histfile, '')
		for line in lines
			let split = split(line, "\t")
			if len(split) <# 3
				echohl ErrorMsg
				echomsg "AniCli.vim: error: Cannot read history"
				echomsg "AniCli.vim: abort"
				echohl Normal
				return
			endif
			let ep_no = split[0]
			let id = split[1]
			let title = split[2]
			let anime_list += [s:process_hist_entry(ep_no, id, title, allanime_refr, allanime_api, agent, mode)]
		endfor

		if len(anime_list) <# 1
			echomsg "No unwatched series in history!"
			echohl ErrorMsg
			echomsg "AniCli.vim: abort"
			echohl Normal
			return
		endif

		let index = substitute(index, "[^0-9]", '', '')
		if index ==# ""
			let anime_list_2 = []
			let i = 0
			for anime in anime_list
				let anime = i."\t".anime
				let anime_list_2 += [anime]
				let i += 1
			endfor
			let index = s:nth(anime_list_2, "Select anime: ")
			unlet anime_list_2
		endif
		let anime = anime_list[index]
		let anime = split(anime, "\t")
		let anime[1] = trim(anime[1])
		let id = anime[0]
		let title = substitute(anime[1], ' - episode [0-9]\+\n$', '', '')
		let ep_list = s:episodes_list(id, allanime_refr, allanime_api, agent, mode)
		let ep_no = substitute(anime[1], '.* - episode \([0-9]\+\)$', '\1', '')
		let allanime_title = trim(split(title, '(')[0])
	endif

	if skip_intro
		if skip_title ==# ""
			let ani_skip_query = title
		else
			let ani_skip_query = skip_title
		endif
		let mal_id = system('ani-skip -q '.ani_skip_query)
		unlet ani_skip_query
	else
		let mal_id = ""
	endif

	call s:play(ep_no, ep_list, player_function, log_episode, skip_intro, mal_id, '', agent, allanime_refr, allanime_api, id, mode, allanime_base, quality)

	if exists('g:ANI_CLI_TO_EXIT') && g:ANI_CLI_TO_EXIT
		return
	endif
endfunction

command! -nargs=* Ani call AniCli(<q-args>)
