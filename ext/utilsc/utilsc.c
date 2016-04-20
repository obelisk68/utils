#include "utilsc.h"

long gcd(long x, long y) {
  long tmp;
  if (x < y) {tmp = x; x = y; y = tmp;}
  if (!y) return x;
  return gcd(y, x % y);
}

VALUE totient(VALUE self) {
  int a;
  long i, se;
  
  a = 0;
  se = FIX2LONG(self);
  for (i = 1; i < se; i++) {
    if (gcd(se, i) == 1) a++;
  }
  return INT2FIX(a);
}

void Init_utilsc(void){
  VALUE fix;
  
  fix = rb_const_get(rb_cObject, rb_intern("Fixnum"));
  rb_define_method(fix, "totient", totient, 0);
}
