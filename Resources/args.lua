io.write( "[lua] These args were passed into the script from C\n" );
for i=1,#arg do
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
