from re import S


def function(a):
    return 2*a
print(function(5))

def function(a):
    b= 2*a
    print(b)
print(function(5))


A = [1,2,3]
print(A)
B = [d,e,f]
# def copy(A,B):
#     A=B
A[0] = "4"
print(A)
# A[1] = 2
# A[2] = 3
print(A)
