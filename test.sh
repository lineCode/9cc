#!/bin/bash
try() {
  expected="$1"
  input="$2"

  ./9cc "$input" > tmp.s
  gcc -static -o tmp tmp.s tmp-test.o
  ./tmp
  actual="$?"

  if [ "$actual" == "$expected" ]; then
    echo "$input => $actual"
  else
    echo "$input: $expected expected, but got $actual"
    exit 1
  fi
}

cat <<EOF | gcc -xc -c -o tmp-test.o -
int plus(int x, int y) { return x + y; }

int *alloc1(int x, int y) {
  static int arr[2];
  arr[0] = x;
  arr[1] = y;
  return arr;
}

int *alloc2(int x, int y) {
  static int arr[2];
  arr[0] = x;
  arr[1] = y;
  return arr + 1;
}

int **alloc_ptr_ptr(int x) {
  static int **p;
  static int *q;
  static int r;
  r = x;
  q = &r;
  p = &q;
  return p;
}
EOF

try 1 'int main() { return 1; }'
try 10 'int main() { return 2*3+4; }'
try 14 'int main() { return 2+3*4; }'
try 26 'int main() { return 2*3+4*5; }'
try 5 'int main() { return 50/10; }'
try 9 'int main() { return 6*3/2; }'

try 0 'int main() { return 0; }'
try 42 'int main() { return 42; }'
try 21 'int main() { 1+2; return 5+20-4; }'
try 41 'int main() { return  12 + 34 - 5 ; }'
try 45 'int main() { return (2+3)*(4+5); }'
try 153 'int main() { return 1+2+3+4+5+6+7+8+9+10+11+12+13+14+15+16+17; }'

try 2 'int main() { int a=2; return a; }'
try 10 'int main() { int a=2; int b; b=3+2; return a*b; }'
try 2 'int main() { if (1) return 2; return 3; }'
try 3 'int main() { if (0) return 2; return 3; }'
try 2 'int main() { if (1) return 2; else return 3; }'
try 3 'int main() { if (0) return 2; else return 3; }'

try 5 'int main() { return plus(2, 3); }'
try 1 'int one() { return 1; } int main() { return one(); }'
try 3 'int one() { return 1; } int two() { return 2; } int main() { return one()+two(); }'
try 6 'int mul(int a, int b) { return a * b; } int main() { return mul(2, 3); }'
try 21 'int add(int a, int b, int c, int d, int e, int f) { return a+b+c+d+e+f; } int main() { return add(1,2,3,4,5,6); }'

try 0 'int main() { return 0||0; }'
try 1 'int main() { return 1||0; }'
try 1 'int main() { return 0||1; }'
try 1 'int main() { return 1||1; }'

try 0 'int main() { return 0&&0; }'
try 0 'int main() { return 1&&0; }'
try 0 'int main() { return 0&&1; }'
try 1 'int main() { return 1&&1; }'

try 0 'int main() { return 0<0; }'
try 0 'int main() { return 1<0; }'
try 1 'int main() { return 0<1; }'
try 0 'int main() { return 0>0; }'
try 0 'int main() { return 0>1; }'
try 1 'int main() { return 1>0; }'

try 60 'int main() { int sum=0; int i; for (i=10; i<15; i=i+1) sum = sum + i; return sum;}'
try 89 'int main() { int i=1; int j=1; for (int k=0; k<10; k=k+1) { int m=i+j; i=j; j=m; } return i;}'

try 8 'int main() { int *p = alloc1(3, 5); return *p + *(p + 1); }'
try 9 'int main() { int *p = alloc2(2, 7); return *p + *(p - 1); }'
try 2 'int main() { int **p = alloc_ptr_ptr(2); return **p; }'

try 3 'int main() { int ary[2]; *ary=1; *(ary+1)=2; return *ary + *(ary+1);}'
try 5 'int main() { int x; int *p = &x; x = 5; return *p;}'

try 3 'int main() { int ary[2]; ary[0]=1; ary[1]=2; return ary[0] + ary[1];}'
try 5 'int main() { int x; int *p = &x; x = 5; return p[0];}'

try 4 'int main() { int x; return sizeof(x); }'
try 8 'int main() { int *x; return sizeof x; }'
try 16 'int main() { int x[4]; return sizeof x; }'

echo OK
