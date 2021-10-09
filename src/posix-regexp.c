/*
** mrb_posixregexp.c - PosixRegexp class
**
** Copyright (c) Uchio Kondo 2021
**
** See Copyright Notice in LICENSE
*/

#include <mruby.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/variable.h>
#include <mruby/value.h>
#include <mruby/array.h>
#include <mruby/error.h>

#ifdef MRB_DEBUG
#include <mruby/string.h>
#endif

#include "mrb_posix_regexp.h"

#include <string.h>
#include <regex.h>

#define DONE mrb_gc_arena_restore(mrb, 0);
static mrb_value mrb_posixmatchdata_generate(mrb_state *mrb, size_t nmatch, size_t offset);

const char match_gv_names[][3] = \
  {
   "$1",
   "$2",
   "$3",
   "$4",
   "$5",
   "$6",
   "$7",
   "$8",
   "$9",
   {0}
  };

static void mrb_regfree(mrb_state *mrb, void *p) {
  if (p != NULL) {
    regfree((regex_t *)p);
    mrb_free(mrb, p);
  }
}

static const struct mrb_data_type mrb_posixregexp_data_type = {
  "regex_t", mrb_regfree,
};

struct mrb_matchdata {
  mrb_int len;
  mrb_int offset;
  regmatch_t matches[1]; /* matches is variable-length */
};

static void mrb_matchdata_free(mrb_state *mrb, void *p)
{
  if (p != NULL) {
    struct mrb_matchdata* data = p;
    mrb_free(mrb, data);
  }
}

static const struct mrb_data_type mrb_posixregexp_matchdata_type = {
  "mrb_matchdata_free", mrb_matchdata_free,
};

/* PosixRegexp */

static mrb_value mrb_posixregexp_init(mrb_state *mrb, mrb_value self)
{
  regex_t *reg;
  char *pattern, *flagstr;
  int flag = 0;

  reg = DATA_PTR(self);
  if (reg) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "initialize cannot be called twice");
  }
  DATA_TYPE(self) = &mrb_posixregexp_data_type;
  DATA_PTR(self) = NULL;

  mrb_get_args(mrb, "zz", &pattern, &flagstr);

  flag |= REG_NEWLINE;
  for(int i = 0; flagstr[i] != '\0'; ++i) {
    switch (flagstr[i]) {
    /* case 'e': */
    /*   break; */
    case 'i':
      flag |= REG_ICASE;
      break;
    case 'm':
      flag &= ~REG_NEWLINE;
      break;
    default:
      mrb_raise(mrb, E_REGEXP_ERROR, "unsupported flag");
      break;
    }
  }

  if (pattern[0] == '\0')
    flag |= REG_NOSUB;

  flag |= REG_EXTENDED;
  reg = mrb_malloc(mrb, sizeof(regex_t));
  int err = regcomp(reg, pattern, flag);
  if (err) {
    char buf[1024];
    regerror(err, reg, buf, sizeof(buf));
    regfree(reg);
    mrb_free(mrb, reg);
    #ifdef MRB_DEBUG
    mrb_warn(mrb, "source: %s\n", pattern);
    #endif
    mrb_raise(mrb, E_REGEXP_ERROR, buf);
  }
  DATA_PTR(self) = reg;

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@source"), mrb_str_new_cstr(mrb, pattern));
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@option"), mrb_fixnum_value(flag));
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@__debug_nmatch"), mrb_fixnum_value(reg->re_nsub));

  return self;
}

static mrb_value mrb_posixregexp_match(mrb_state *mrb, mrb_value self)
{
  regex_t *reg = DATA_PTR(self);
  char *input;
  mrb_int input_len, pos = 0;

  mrb_get_args(mrb, "z|i", &input, &pos);
  input_len = (mrb_int)strlen(input);

  if (pos > input_len)
    mrb_raise(mrb, E_REGEXP_ERROR, "pos goes over target string");
  if (pos)
    input = input + pos;

  size_t nmatch = reg->re_nsub + 1;
  mrb_value matched = mrb_posixmatchdata_generate(mrb, nmatch, pos);
  struct mrb_matchdata *matchedp = DATA_PTR(matched);

  int err = regexec(reg, input, nmatch, matchedp->matches, 0);

  switch (err) {
  case 0:
    break;
  case REG_NOMATCH:
    mrb_gv_set(mrb, mrb_intern_lit(mrb, "$matchdata"), mrb_ary_new(mrb));
    for (int i = 0; !match_gv_names[i]; i++) {
      mrb_gv_set(mrb, mrb_intern_cstr(mrb, match_gv_names[i]), mrb_ary_new(mrb));
    }

    return mrb_nil_value();
    break;
  default:
    {
      char buf[1024];
      #ifdef MRB_DEBUG
      mrb_warn(mrb, "source: %s, target: %s\n",
               RSTRING_PTR(mrb_funcall(mrb, self, "source", 0)),
               input);
      #endif
      regerror(err, reg, buf, sizeof(buf));
      mrb_raise(mrb, E_REGEXP_ERROR, buf);
      break;
    }
  }

  mrb_iv_set(mrb, matched, mrb_intern_lit(mrb, "@regexp"), self);
  mrb_iv_set(mrb, matched, mrb_intern_lit(mrb, "@string"), mrb_str_new_cstr(mrb, input - pos));
  mrb_iv_set(mrb, matched, mrb_intern_lit(mrb, "@length"), mrb_fixnum_value(nmatch));

  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$matchdata"), matched);
  for (int i = 0; (i < nmatch - 1 && match_gv_names[i]) ; i++) {
    mrb_gv_set(mrb, mrb_intern_cstr(mrb, match_gv_names[i]),
               mrb_funcall(mrb, matched, "[]", 1, mrb_fixnum_value(i + 1)));
  }

  return matched;
}

static mrb_value mrb_posixmatchdata_generate(mrb_state *mrb, size_t nmatch, size_t offset)
{
  struct RClass *c = mrb_class_get(mrb, "PosixMatchData");
  if(!c)
    mrb_sys_fail(mrb, "[BUG] PosixMatchData undefined");

  mrb_value self = mrb_obj_new(mrb, c, 0, NULL);
  DATA_TYPE(self) = &mrb_posixregexp_matchdata_type;

  struct mrb_matchdata *data = mrb_calloc(mrb, 1, sizeof(struct mrb_matchdata) + (nmatch - 1) * sizeof(regmatch_t));
  data->len = (mrb_int)nmatch;
  data->offset = (mrb_int)offset;
  DATA_PTR(self) = data;

  return self;
}

static mrb_value mrb_posixmatchdata_begin(mrb_state *mrb, mrb_value self)
{
  struct mrb_matchdata *data = DATA_PTR(self);
  if(!data)
    mrb_sys_fail(mrb, "[BUG] PosixMatchData invaidly initialized");

  mrb_int pos;
  mrb_get_args(mrb, "i", &pos);

  if(pos >= data->len)
    return mrb_nil_value();

  int d = data->matches[pos].rm_so;
  if (d == -1)
    return mrb_nil_value();

  return mrb_fixnum_value(d + data->offset);
}

mrb_value mrb_posixregexp_quote(mrb_state *mrb, mrb_value self);

static mrb_value mrb_posixmatchdata_end(mrb_state *mrb, mrb_value self)
{
  struct mrb_matchdata *data = DATA_PTR(self);
  if(!data)
    mrb_sys_fail(mrb, "[BUG] PosixMatchData invaidly initialized");

  mrb_int pos;
  mrb_get_args(mrb, "i", &pos);

  if(pos > data->len)
    return mrb_nil_value();

  int d = data->matches[pos].rm_eo;
  if (d == -1)
    return mrb_nil_value();

  return mrb_fixnum_value(d + data->offset);
}

void mrb_mruby_posix_regexp_gem_init(mrb_state *mrb)
{
  struct RClass *posixregexp;
  posixregexp = mrb_define_class(mrb, "PosixRegexp", mrb->object_class);
  MRB_SET_INSTANCE_TT(posixregexp, MRB_TT_DATA);
  mrb_define_method(mrb, posixregexp, "initialize", mrb_posixregexp_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, posixregexp, "match", mrb_posixregexp_match, MRB_ARGS_ARG(1, 1));

  mrb_define_const(mrb, posixregexp, "REG_ICASE", mrb_fixnum_value(REG_ICASE));
  mrb_define_const(mrb, posixregexp, "REG_NEWLINE", mrb_fixnum_value(REG_NEWLINE));

  mrb_define_class_method(mrb, posixregexp, "quote", mrb_posixregexp_quote, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, posixregexp, "escape", mrb_posixregexp_quote, MRB_ARGS_REQ(1));

  struct RClass *matchdata;
  matchdata = mrb_define_class(mrb, "PosixMatchData", mrb->object_class);
  MRB_SET_INSTANCE_TT(matchdata, MRB_TT_DATA);
  mrb_define_method(mrb, matchdata, "begin", mrb_posixmatchdata_begin, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, matchdata, "end", mrb_posixmatchdata_end, MRB_ARGS_REQ(1));
  DONE;
}

void mrb_mruby_posix_regexp_gem_final(mrb_state *mrb)
{
}
