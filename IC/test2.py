
cnt = 0
def static(a):
    global cnt
    cnt += a
    return cnt
print(static(1))    
print(static(1))



def add(i):
    k = 1+i
    print(k)
add(3)