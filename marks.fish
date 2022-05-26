# Copyright 2013 Kunal Sarkhel
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

# Fishmarks:
# Save and jump to commonly used directories
#
# Fishmarks is a a clone of bashmarks for the Fish shell. Fishmarks is
# compatible with your existing bashmarks and bookmarks added using fishmarks
# are also available in bashmarks.

if not set -q SDIRS
    set -gx SDIRS $HOME/.sdirs
end
touch $SDIRS

if not set -q NO_FISHMARKS_COMPAT_ALIASES
    alias s save_bookmark
    alias g go_to_bookmark
    alias p print_bookmark
    alias d delete_bookmark
    alias l list_bookmarks
    alias fa flushall
    alias da flushall
    alias sa save_anything
    alias lf list_with_fzf
    alias gg list_with_fzf
    alias lll list_with_fzf
    alias llll list_with_fzf
    alias lc list_and_copy_with_fzf
    alias lfc list_and_copy_with_fzf
    alias dz del_with_fzf
    alias edi edit
end



function save_bookmark --description "Save the current directory as a bookmark"
    set -l bn $argv[1]
    if [ (count $argv) -lt 1 ]
        set bn (string replace -r [^a-zA-Z0-9] _ (basename (pwd)))
    end
    if not echo $bn | grep -q "^[a-zA-Z0-9_]*\$";
        echo -e "\033[0;31mERROR: Bookmark names may only contain alphanumeric characters and underscores.\033[00m"
        return 1
    end
    if _valid_bookmark $bn;
        sed -i='' "/DIR_$bn=/d" $SDIRS
    end
    set -l pwd (pwd | sed "s#^$HOME#\$HOME#g")
    echo "export DIR_$bn=\"$pwd\"" >> $SDIRS
    _update_completions
    return 0
end

function go_to_bookmark --description "Go to (cd) to the directory associated with a bookmark"
    if [ (count $argv) -lt 1 ]
        echo -e "\033[0;31mERROR: '' bookmark does not exist\033[00m"
        return 1
    end
    if not _check_help $argv[1];
        cat $SDIRS | grep "^export DIR_" | sed "s/^export /set -x /" | sed "s/=/ /" | .
        set -l target (env | grep "^DIR_$argv[1]=" | cut -f2 -d "=")
        if [ ! -n "$target" ]
            echo -e "\033[0;31mERROR: '$argv[1]' bookmark does not exist\033[00m"
            return 1
        end
        if [ -d "$target" ]
            cd "$target"
            return 0
        else
            echo -e "\033[0;31mERROR: '$target' does not exist\033[00m"
            return 1
        end
    end
end

function print_bookmark --description "Print the directory associated with a bookmark"
    if [ (count $argv) -lt 1 ]
        echo -e "\033[0;31mERROR: bookmark name required\033[00m"
        return 1
    end
    if not _check_help $argv[1];
        cat $SDIRS | grep "^export DIR_" | sed "s/^export /set -x /" | sed "s/=/ /" | .
        env | grep "^DIR_$argv[1]=" | cut -f2 -d "="
    end
end

function delete_bookmark --description "Delete a bookmark"
    if [ (count $argv) -lt 1 ]
        echo -e "\033[0;31mERROR: bookmark name required\033[00m"
        return 1
    end
    if not _valid_bookmark $argv[1];
        echo -e "\033[0;31mERROR: bookmark '$argv[1]' does not exist\033[00m"
        return 1
    else
        sed --follow-symlinks -i='' "/DIR_$argv[1]=/d" $SDIRS
        _update_completions
    end
end






function list_bookmarks --description "List all available bookmarks"
    set with_fzf $argv[1]
    if not _check_help $argv[1];
        cat $SDIRS | grep "^export DIR_" | sed "s/^export /set -x /" | sed "s/=/ /" | .
        if test -n "$with_fzf"
            env | sort | awk '/DIR_.+/{split(substr($0,5),parts,"="); printf("%-20s %s\n", parts[1], parts[2]);}'
            return 0
        else 
            env | sort | awk '/DIR_.+/{split(substr($0,5),parts,"="); printf("\033[0;33m%-20s\033[0m %s\n", parts[1], parts[2]);}'
            return 0
        end
    end
end


function _check_help
    if [ (count $argv) -lt 1 ]
        return 1
    end
    if begin; [ "-h" = $argv[1] ]; or [ "-help" = $argv[1] ]; or [ "--help" = $argv[1] ]; end
        echo ''
        echo 's <bookmark_name> - Saves the current directory as "bookmark_name"'
        echo 'g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
        echo 'p <bookmark_name> - Prints the directory associated with "bookmark_name"'
        echo 'd <bookmark_name> - Deletes the bookmark'
        echo 'l - Lists all available bookmarks'
        echo ''
        return 0
    end
    return 1
end

function _valid_bookmark
    if begin; [ (count $argv) -lt 1 ]; or not [ -n $argv[1] ]; end
        return 1
    else
        cat $SDIRS | grep "^export DIR_" | sed "s/^export /set -x /" | sed "s/=/ /" | .
        set -l bookmark (env | grep "^DIR_$argv[1]=" | cut -f1 -d "=" | cut -f2 -d "_" )
        if begin; not [ -n "$bookmark" ]; or not [ $bookmark=$argv[1] ]; end
            return 1
        else
            return 0
        end
    end
end


function save_anything
    set bn $argv[1]
    
    if test -z $argv[1]
        s
        return
    end
    
    if [ -n "$argv[2]" ]
        reset_bm $bn
        echo "export DIR_$bn=\"$argv[2..-1]\"" >> $SDIRS
        return
    end    

    set cmd (echo $history[1])
    if test -n $cmd
        reset_bm $bn
        echo "export DIR_$bn=\"$cmd\"" >> $SDIRS
    else
        echo "empty history!"
    end
end

function list_with_fzf
    set need_copy $argv[1]
    if test -n $need_copy
        copy_to_clipboard $target
    end


    set data (l "with_fzf" | fzf)
    if [ ! -n "$data" ]
        return
    end
    where_go $data
end


function where_go
    set data $argv[1]
    set bn  (echo $data |  awk '{print $1}')
    set second_key  (echo $data |  awk '{print $2}')
    set target (echo $data | awk '{for (i=2; i<=NF; i++) print $i}')


    set target "$target"

    if test -n $target
        if [ -d "$target" ]
            go_to_bookmark $bn
            return
        end

        # program ?
        if type -q $second_key
            echo "========tg";
            eval $target
            return
        end
        # text
        echo $target
    end
end


function copy_to_clipboard
    echo -n $argv[1] | xclip -sel clip
end

function flushall
    while true
        read -l -P 'Do you want to delate all bookmarks? [y/N] ' confirm
        switch $confirm
                case Y y
                    true > $SDIRS
                    return 0
                case '' N n
                    return 1
        end
    end
end

function del_with_fzf
    set data (l "with_fzf" | fzf)
    if [ ! -n "$data" ] 
        return
    end
    set bn  (echo $data |  awk '{print $1}')
    delete_bookmark $bn
end

function list_and_copy_with_fzf
    list_with_fzf "copy"
end

function edit
    set seleted (list_bookmarks "with_fzf" | fzf)
    set bn  (echo $seleted |  awk '{print $1}')
    set target (echo $seleted | awk '{for (i=2; i<=NF; i++) print $i}')
    # to string
    set target "$target"

    read -c $target -x changed_content -P "$bn >>  "
    if test -n $changed_content
        set changed_content2 (string trim $changed_content)
        save_anything $bn $changed_content2
    end
end


function reset_bm
    set bn $argv[1]
    if _valid_bookmark $bn
        sed -i='' "/DIR_$bn=/d" $SDIRS
    end
end

function _update_completions
    cat $SDIRS | grep "^export DIR_" | sed "s/^export /set -x /" | sed "s/=/ /" | .
    set -x _marks (env | grep "^DIR_" | sed "s/^DIR_//" | cut -f1 -d "=" | tr '\n' ' ')
    complete -c print_bookmark -a $_marks -f
    complete -c delete_bookmark -a $_marks -f
    complete -c go_to_bookmark -a $_marks -f
    if not set -q NO_FISHMARKS_COMPAT_ALIASES
        complete -c p -a $_marks -f
        complete -c d -a $_marks -f
        complete -c g -a $_marks -f
    end
end
_update_completions
