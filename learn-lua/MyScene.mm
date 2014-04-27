//
//  MyScene.m
//  learn-lua
//
//  Created by James Chen on 14-4-27.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "MyScene.h"


extern "C"
{
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}
#include <iostream>


static void stackDump (lua_State *L) {
    int i;
    int top = lua_gettop(L);
    printf("======\n");
    for (i = 1; i <= top; i++) {  /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
                
            case LUA_TSTRING:  /* strings */
                printf("`%s'", lua_tostring(L, i));
                break;
                
            case LUA_TBOOLEAN:  /* booleans */
                printf(lua_toboolean(L, i) ? "true" : "false");
                break;
                
            case LUA_TNUMBER:  /* numbers */
                printf("%g", lua_tonumber(L, i));
                break;
                
            default:  /* other values */
                printf("%s", lua_typename(L, t));
                break;
                
        }
        printf("  ");  /* put a separator */
    }
    printf("\n");     /* end the listing */
}

/* args.lua文件的内容
 io.write( "[lua] These args were passed into the script from C\n" );
 for i=1,table.getn(arg) do
 print(i,arg[i])
 end
 io.write("[lua] Script returning data back to C\n")
 local temp = {}
 temp[1]=9
 temp[2]=8
 temp[3]=7
 temp[4]=6
 temp[5]=5
 temp["test1 key"]="test1 value"
 temp[6]="test 6"
 temp["test 99"]=99
 for i,n in pairs(temp)
 do
 print (i,n)
 end
 return temp,9,1
 */
int lua_main()
{
    int status;
    
    // lua_open: 创建一个新的lua环境
    lua_State* state = luaL_newstate();
    
    // 在state环境上打开标准库，
    // 标准库包括：
    // luaopen_base
    // luaopen_package
    // luaopen_table
    // luaopen_io
    // luaopen_os
    // luaopen_string
    // luaopen_math
    // luaopen_debug
    
    int top = 0;
    top = lua_gettop(state);
    luaL_openlibs(state);  /* open libraries */
    top = lua_gettop(state);
    status = luaL_loadfile( state, "/Users/james/Library/Developer/Xcode/DerivedData/learn-lua-dptjrwjptpwptyervgfdqbyazfeg/Build/Products/Debug/learn-lua.app/Contents/Resources/args.lua" );
    
    std::cout << "[C++] Passing 'arg' array to script" << std::endl;
    
    top = lua_gettop(state);
    // 创建一个新的表
    lua_newtable( state );
    
    top = lua_gettop(state);
    //
    // set first element "1" to value 45
    //
    // 调用lua的函数，都是通过压栈出栈来完成的
    // 为表执行一个t[k]=v的操作,则需要先将k压栈，再将v压栈，再调用操作函数
    // 这个操作函数会使用栈上的元素，并“可能”将弹出元素和压入元素
    // lua_rawset直接赋值（不触发metamethods方法）。
    
    // lua_rawset/lua_settable使用:
    // 它从栈中获取参数。以table在栈中的索引作为参数，
    // 并将栈中的key和value出栈。
    // lua_pushnumber函数调用之前，
    // table是在栈顶位置(索引为-1)。index和value入栈之后，
    // table索引变为-3。
    lua_pushnumber( state, 1 );
    lua_pushnumber( state, 45 );
    
    top = lua_gettop(state);
    
    lua_rawset( state, -3 );
    
    top = lua_gettop(state);
    
    // set second element "2" to value 99
    lua_pushnumber( state, 2 );
    lua_pushnumber( state, 99 );
    lua_rawset( state, -3 );
    top = lua_gettop(state);
    // set the number of elements (index to the last array element)
    // lua_pushliteral压入一个字符串，不需要指定长度
    // 如果lua_pushlstring,则需要指定长度
    lua_pushliteral( state, "n" );
    lua_pushnumber( state, 2 );
    lua_rawset( state, -3 );
    top = lua_gettop(state);
    // set the name of the array that the script will access
    // Pops a value from the stack and sets it as the new value of global name.
    // 从栈顶弹出一个值，并将其设置全局变量"arg"的新值。
    lua_setglobal( state, "arg" );
    
    top = lua_gettop(state);
    std::cout << "[C++] Running script" << std::endl;
    
    int result = 0;
    if (status == 0)
    {
        result = lua_pcall( state, 0, LUA_MULTRET, 0 );
    }
    else
    {
        std::cout << "bad" << std::endl;
    }
    
    if (result != 0)
    {
        std::cerr << "[C++] script failed" << std::endl;
    }
    
    std::cout << "[C++] These values were returned from the script" << std::endl;
    
    // lua_gettop返回栈顶的索引
    // 如果索引为0，则表示栈为空
    
    stackDump(state);
    while (lua_gettop( state ))
    {
        stackDump(state);
        top = lua_gettop(state);
        switch (lua_type( state, lua_gettop( state ) ))
        {
            case LUA_TNUMBER:
            {
                std::cout << "script returned " << lua_tonumber( state, lua_gettop( state ) ) << std::endl;
                break;
            }
            case LUA_TTABLE:
            {
                std::cout << "script returned a table" << std::endl;
                
                // 简单的遍历表的功能
                // ***好像lua不保存表的元素的添加顺序***
                
                // 压入第一个键
                lua_pushnil(state);  /* 第一个 key */
                int t = -2;
                top = lua_gettop(state);
                stackDump(state);
                while (lua_next(state, t) != 0)
                {
                    top = lua_gettop(state);
                    stackDump(state);
                    /* 'key' (索引-2) 和 'value' (索引-1) */
                    const char* key = "unknown";
                    const char* value;
                    if(lua_type(state, -2) == LUA_TSTRING)
                    {
                        key = lua_tostring(state, -2);
                        value = lua_tostring(state, -1);
                    }
                    else if(lua_type(state, -2) == LUA_TNUMBER)
                    {
                        // 因为lua_tostring会更改栈上的元素，
                        // 所以不能直接在key上进行lua_tostring
                        // 因此，复制一个key，压入栈顶，进行lua_tostring
                        lua_pushvalue(state, -2);
                        stackDump(state);
                        key = lua_tostring(state, -1);
                        stackDump(state);
                        lua_pop(state, 1);
                        stackDump(state);
                        value = lua_tostring(state, -1);
                        stackDump(state);
                        
//                        value = lua_tostring(state, -1);
//                        stackDump(state);
//                        key = lua_tostring(state, -2);
//                        stackDump(state);
//                        lua_pop(state, 2);
                    }
                    else
                    {
                        value = lua_tostring(state, -1);
                    }
                    
                    std::cout    <<"key="<< key
                    << ", value=" << value << std::endl;
                    
                    /* 移除 'value' ；保留 'key' 做下一次迭代 */
                    lua_pop(state, 1);
                    stackDump(state);
                }
                
                break;
            }
            case LUA_TSTRING:
            {
                std::cout << "script returned " << lua_tostring( state, lua_gettop( state ) ) << std::endl;
                break;
            }
            case LUA_TBOOLEAN:
            {
                std::cout << "script returned " << lua_toboolean( state, lua_gettop( state ) ) << std::endl;
                break;
            }
            default:
                std::cout << "script returned unknown param" << std::endl;
                break;
        }
        lua_pop( state, 1 );
    }   
    lua_close( state );   
    return 0;   
}

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        lua_main();
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];
    }
    return self;
}

-(void)mouseDown:(NSEvent *)theEvent {
     /* Called when a mouse click occurs */
    
    CGPoint location = [theEvent locationInNode:self];
    
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    
    sprite.position = location;
    sprite.scale = 0.5;
    
    SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
    
    [sprite runAction:[SKAction repeatActionForever:action]];
    
    [self addChild:sprite];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
