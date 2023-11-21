LUA_FD="$HOME/.config/nvim/lua"
LUA_INIT="$HOME/.config/nvim/init.lua"

if [ -d $LUA_FD ] && [ -f $LUA_INIT ] ;then
    echo "copy files to .config"
    cp -R $LUA_FD ./
    cp $LUA_INIT ./
fi

echo "end"
