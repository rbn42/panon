"""
这里是为了绕过 shader program 的loadsource 无法正常工作的解决办法

在qml源码中直接嵌入qlsl


"""
import glob
import os
qml_temp=glob.glob('./plasmoid/contents/*/*.temp.qml')
root='./plasmoid/contents/shaders/'
shaders={name:open(root+name).read() for name in os.listdir(root)}
for path in qml_temp:
    path_dst=path[:-9]+'.qml'
    print(path_dst)
    src=open(path).read()
    for name in shaders:
        src=src.replace(name,shaders[name].replace('"','\\"'))
    open(path_dst,'w').write('\n'+src+'\n')
