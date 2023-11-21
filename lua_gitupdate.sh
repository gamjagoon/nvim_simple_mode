LUA_CONFIG="$HOME/.config/nvim"
LUA_FD=$LUA_CONFIG/
LUA_INIT="$HOME/.config/nvim/init.lua"

if [ -d $LUA_FD ] && [ -f $LUA_INIT ] ;then
    echo "copy files to .config"
    cp -R $LUA_FD ./
    cp $LUA_INIT ./
fi

echo "end"
