/* ported from Ruby's rb_reg_quote() */
#include <mruby.h>
#include <mruby/data.h>
#include <mruby/string.h>

mrb_value mrb_posixregexp_quote(mrb_state *mrb, mrb_value self)
{
  char *s, *send, *t;
  mrb_value str, tmp;

  mrb_get_args(mrb, "o", &str);
  if (!mrb_string_p(str))
    str = mrb_funcall(mrb, str, "source", 0);

  tmp = mrb_str_dup(mrb, str);
  mrb_str_resize(mrb, tmp, RSTRING_LEN(str)*2);
  t = RSTRING_PTR(tmp);

  s = RSTRING_PTR(str);
  send = s + RSTRING_LEN(str);

  while (s < send) {
    switch (*s) {
    case '[': case ']': case '{': case '}':
    case '(': case ')': case '|': case '-':
    case '*': case '.': case '\\':
    case '?': case '+': case '^': case '$':
    case '#':
      t[0] = '\\';
      t += 1;
      break;
    case ' ':
      t[0] = '\\';
      t += 1;
      t[0] = ' ';
      t += 1;
      s += 1;
      continue;
    case '\t':
      t[0] = '\\';
      t += 1;
      t[0] = 't';
      t += 1;
      s += 1;
      continue;
    case '\n':
      t[0] = '\\';
      t += 1;
      t[0] = 'n';
      t += 1;
      s += 1;
      continue;
    case '\r':
      t[0] = '\\';
      t += 1;
      t[0] = 'r';
      t += 1;
      s += 1;
      continue;
    case '\f':
      t[0] = '\\';
      t += 1;
      t[0] = 'f';
      t += 1;
      s += 1;
      continue;
    case '\v':
      t[0] = '\\';
      t += 1;
      t[0] = 'v';
      t += 1;
      s += 1;
      continue;
    }
    t[0] = *s;
    t += 1;

    s += 1;
  }

  mrb_str_resize(mrb, tmp, t - RSTRING_PTR(tmp));
  return tmp;
}
