/*
 *      DARK -- Data Annotation using Rules and Knowledge
 *
 * Copyright (c) 2014  CNRS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define DARK_VERSION "0.0.1"

#define unused(v) ((void)(v))
#define swap(t, a, b) do { \
	t __t = (a);       \
	(a)   = (b);       \
	(b)   = __t;       \
} while (0)

/*******************************************************************************
 * Unicode handling
 ******************************************************************************/

/* decode:
 *   Decode and return the next unicode codepoint from the given string in utf8
 *   and update the position. Return -1 on end of string.
 *   This code is only an adaptation of the decoder written by Bjoern Hoehrmann
 *   published also under the BSD licence and keep its original copyright, see
 *       http://bjoern.hoehrmann.de/utf-8/decoder/dfa/
 *   for more details.
 */
//static inline
int decode(const char *str, int len, int *pos) {
	static const char utf8d[] = {
	    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
	    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
	    8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	    0xa,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x4,0x3,0x3,
	    0xb,0x6,0x6,0x6,0x5,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,
	    0x0,0x1,0x2,0x3,0x5,0x8,0x7,0x1,0x1,0x1,0x4,0x6,0x1,0x1,0x1,0x1,
	    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,
	    1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,
	    1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1,
	    1,3,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
	};
	const unsigned char *raw = (const unsigned char *)str;
	if (*pos >= len)
		return -1;
	int st = utf8d[256 + utf8d[raw[*pos]]];
	int cp = raw[*pos] & (255 >> utf8d[raw[*pos]]);
	for ((*pos)++ ; st > 1 && *pos < len; (*pos)++) {
		st = utf8d[256 + st * 16 + utf8d[raw[*pos]]];
		cp = (cp << 6) | (raw[*pos] & 63);
	}
	if (st == 0)
		return cp;
	return -2;
}

/*******************************************************************************
 * Hash function
 ******************************************************************************/

/* spooky:
 *   Simple implementation of Spooky hash function of Bob Jenkins optimized for
 *   short string as this is the only important case here. Return a single 64bit
 *   value but more can be returned if needed.
 */
static
unsigned long spooky(const void *buf, const size_t len) {
	union {
		const unsigned char  *p8;
		const unsigned short *p16;
		const unsigned int   *p32;
		const unsigned long  *p64;
	} key = {.p8 = buf};
	const unsigned long foo = 0xDEADBEEFCAFEBABEULL;
	unsigned long tlen = len;
	unsigned long a = foo, b = foo;
	unsigned long c = foo, d = foo;
	while (tlen >= 16) {
		c += key.p64[0]; d += key.p64[1];
		c = (c << 50) | (c >> (64 - 50)); c += d; a ^= c;
		d = (d << 52) | (d >> (64 - 52)); d += a; b ^= d;
		a = (a << 30) | (a >> (64 - 30)); a += b; c ^= a;
		b = (b << 41) | (b >> (64 - 41)); b += c; d ^= b;
		c = (c << 54) | (c >> (64 - 54)); c += d; a ^= c;
		d = (d << 48) | (d >> (64 - 48)); d += a; b ^= d;
		a = (a << 38) | (a >> (64 - 38)); a += b; c ^= a;
		b = (b << 37) | (b >> (64 - 37)); b += c; d ^= b;
		c = (c << 62) | (c >> (64 - 62)); c += d; a ^= c;
		d = (d << 34) | (d >> (64 - 34)); d += a; b ^= d;
		a = (a <<  5) | (a >> (64 -  5)); a += b; c ^= a;
		b = (b << 36) | (b >> (64 - 36)); b += c; d ^= b;
		if (tlen >= 32) {
			a += key.p64[2]; b += key.p64[3];
			tlen -= 16; key.p64 += 2;
		}
		tlen -= 16; key.p64 += 2;
	}
	d += (const unsigned long)tlen << 56;
	switch (tlen) {
		case 15: d += (const unsigned long)key.p8[14] << 48;
		case 14: d += (const unsigned long)key.p8[13] << 40;
		case 13: d += (const unsigned long)key.p8[12] << 32;
		case 12: d += key.p32[2]; c += key.p64[0];           break;
		case 11: d += (const unsigned long)key.p8[10] << 16;
		case 10: d += (const unsigned long)key.p8[ 9] <<  8;
		case  9: d += (const unsigned long)key.p8[ 8];
		case  8: c += key.p64[0];                            break;
		case  7: c += (const unsigned long)key.p8[ 6] << 48;
		case  6: c += (const unsigned long)key.p8[ 5] << 40;
		case  5: c += (const unsigned long)key.p8[ 4] << 32;
		case  4: c += key.p32[0];                            break;
		case  3: c += (const unsigned long)key.p8[ 2] << 16;
		case  2: c += (const unsigned long)key.p8[ 1] <<  8;
		case  1: c += (const unsigned long)key.p8[ 0];       break;
		case  0: c += foo; d += foo;
	}
	d ^= c; c = (c << 15) | (c >> (64 - 15)); d += c;
	a ^= d; d = (d << 52) | (d >> (64 - 52)); a += d;
	b ^= a; a = (a << 26) | (a >> (64 - 26)); b += a;
	c ^= b; b = (b << 51) | (b >> (64 - 51)); c += b;
	d ^= c; c = (c << 28) | (c >> (64 - 28)); d += c;
	a ^= d; d = (d <<  9) | (d >> (64 -  9)); a += d;
	b ^= a; a = (a << 47) | (a >> (64 - 47)); b += a;
	c ^= b; b = (b << 54) | (b >> (64 - 54)); c += b;
	d ^= c; c = (c << 32) | (c >> (64 - 32)); d += c;
	a ^= d; d = (d << 25) | (d >> (64 - 25)); a += d;
	b ^= a; a = (a << 63) | (a >> (64 - 63)); b += a;
	return a;
}

/*******************************************************************************
 * Annotated token sequence
 *
 *   Sequence object represent a sequence of tokens anotated with a set of tags
 *   that can span arbitrary number of contiguous tokens. This module provide
 *   all the basis tools to manage the tokens and the tags.
 ******************************************************************************/

typedef struct seq_s seq_t;
typedef struct tok_s tok_t;
typedef struct tag_s tag_t;
struct seq_s {
	int ntok;                   // Number of tokens in the array
	struct tok_s {
		char *raw;          // Raw token string
		int   ntag;         // Number of tag in the array
		struct tag_s {
			char *str;  // Name of the tag
			int   len;  // Number of tokens spaned
		} *tag;             // Array of tag objects
	} tok[];                    // Array of token objects
};

/* seqL_new:
 *   Create a new sequence object on the Lua side from a string or a table of
 *   tokens. If the argument is a string, it is split in space separated tokens
 *   while a table argument give the user full control over what constitue a
 *   token.
 */
static
int seqL_new(lua_State *L) {
	const int szmax = 4096;
	seq_t *seq = NULL;
	// If the argument is a string, it is splitted in white space separated
	// tokens, its the user responsibility that this lead to an approriate
	// tokenization.
	if (lua_isstring(L, 1)) {
		const char *str = lua_tostring(L, 1);
		const char *off[szmax], *end[szmax];
		int cnt = 0;
		while (*str) {
			while (isspace(*str))
				str++;
			if (*str == '\0')
				break;
			if (cnt == szmax)
				luaL_error(L, "overlong sequence");
			off[cnt] = str;
			while (*str && !isspace(*str))
				str++;
			end[cnt++] = str;
		}
		seq = lua_newuserdata(L, sizeof(seq_t) + cnt * sizeof(tok_t));
		for (int n = 0; n < cnt; n++) {
			seq->tok[n].raw  = NULL;
			seq->tok[n].tag  = NULL;
			seq->tok[n].ntag = 0;
		}
		seq->ntok = cnt;
		luaL_getmetatable(L, "seq_t");
		lua_setmetatable(L, -2);
		for (int n = 0; n < cnt; n++) {
			const int len = end[n] - off[n] + 1;
			tok_t *tok = &seq->tok[n];
			tok->raw = malloc(len);
			if (tok->raw == NULL)
				return luaL_error(L, "out of memory");
			memcpy(tok->raw, off[n], len);
			tok->raw[len - 1] = '\0';
		}
	// Else, if the argument is a table, it should contains an array of
	// strings, each one is handled as a separate token. This is the only
	// way to get tokens embedding white spaces.
	} else if (lua_istable(L, 1)) {
		const int cnt = lua_rawlen(L, 1);
		seq = lua_newuserdata(L, sizeof(seq_t) + cnt * sizeof(tok_t));
		for (int n = 0; n < cnt; n++) {
			seq->tok[n].raw  = NULL;
			seq->tok[n].tag  = NULL;
			seq->tok[n].ntag = 0;
		}
		seq->ntok = cnt;
		luaL_getmetatable(L, "seq_t");
		lua_setmetatable(L, -2);
		for (int n = 0; n < cnt; n++) {
			lua_rawgeti(L, 1, n + 1);
			const char *raw = lua_tostring(L, -1);
			luaL_argcheck(L, 1, raw != NULL, "invalid token");
			const int len = strlen(raw) + 1;
			tok_t *tok = &seq->tok[n];
			tok->raw = malloc(len);
			if (tok->raw == NULL)
				return luaL_error(L, "out of memory");
			memcpy(tok->raw, raw, len);
			lua_pop(L, 1);
		}
	} else {
		luaL_error(L, "missing or invalid argument");
	}
	return 1;
}

/* seqL_free:
 *   Release all memory used by a sequence object on the C side. This doesn't
 *   free the sequence object itself as it is allocated on the Lua side. This
 *   function should be called only by the Lua garbage collector, it should
 *   never be called directly.
 */
static
int seqL_free(lua_State *L) {
	seq_t *seq = luaL_checkudata(L, 1, "seq_t");
	for (int n = 0; n < seq->ntok; n++) {
		tok_t *tok = &seq->tok[n];
		if (tok->raw != NULL)
			free(tok->raw);
		if (tok->tag != NULL) {
			for (int t = 0; t < tok->ntag; t++)
				if (tok->tag[t].str != NULL)
					free(tok->tag[t].str);
			free(tok->tag);
		}
	}
	return 0;
}

/* seqL_len:
 *   Length meta-method, return the number of tokens in the sequence and can be
 *   used to now the useable range for indexing.
 */
static
int seqL_len(lua_State *L) {
	seq_t *seq = luaL_checkudata(L, 1, "seq_t");
	lua_pushinteger(L, seq->ntok);
	return 1;
}

/* seq_istagchr:
 *   Return true iff a character is allowed in a tag name.
 */
static inline
bool seq_istagchr(char c) {
	return isalnum(c) || c == '-' || c == '_' || c == '=';
}

/* seq_istag:
 *   Return true iff a string is a valid tag name. i.e. start with an ampersand
 *   and is followed only by allowed tag characters.
 */
static
bool seq_istag(const char *str) {
	if (str[0] != '&' || str[1] == '\0')
		return false;
	for (int i = 1; str[i] != '\0'; i++)
		if (!seq_istagchr(str[i]))
			return false;
	return true;
}

/* seq_checkindex:
 *   Check if the argument is a valid index for the given sequence and return it
 *   as a 0 based value, else return -1. This take care of handling negative
 *   index from the end of the sequence.
 */
static
int seq_checkindex(lua_State *L, int narg, const seq_t *seq) {
	int n = luaL_checkinteger(L, narg);
	if (n == 0 || abs(n) > seq->ntok)
		return -1;
	if (n < 0)
		return seq->ntok - n;
	return n - 1;
}

/* seq_optindex:
 *   Same as seq_checkindex but if the argument wasn't provided by the caller,
 *   it default to the specified value.
 */
static
int seq_optindex(lua_State *L, int narg, int def, const seq_t *seq) {
	if (lua_isnoneornil(L, narg))
		return def;
	return seq_checkindex(L, narg, seq);
}

/* seqL_index:
 *   Index meta-method:
 *     - when called with an integer argument it return a table with a "token"
 *       field with the raw string and an array part containing the tags who
 *       start at this position.
 *     - with a tag argument, it return an array of all appearance of this tag
 *       in the sequence.
 *     - else it try to find a method with this name and return it.
 */
static
int seqL_index(lua_State *L) {
	const seq_t *seq = luaL_checkudata(L, 1, "seq_t");
	// First the case of integer index is handled.
	if (lua_isnumber(L, 2)) {
		const int n = seq_checkindex(L, 2, seq);
		if (n == -1) return 0;
		const tok_t *tok = &seq->tok[n];
		lua_newtable(L);
		lua_pushstring(L, tok->raw);
		lua_setfield(L, -2, "token");
		for (int t = 0; t < tok->ntag; t++) {
			lua_newtable(L);
			lua_pushstring(L, tok->tag[t].str);
			lua_setfield(L, -2, "name");
			lua_pushinteger(L, tok->tag[t].len);
			lua_setfield(L, -2, "length");
			lua_rawseti(L, -2, t + 1);
		}
		return 1;
	}
	// If here, the argument is either a string or invalid so a basic check
	// is done to dismiss the invalid ones.
	if (!lua_isstring(L, 2))
		return 0;
	const char *idx = lua_tostring(L, 2);
	// If the string start with an ampersand, a list of tags should be build
	// and returned.
	if (seq_istag(idx)) {
		lua_newtable(L); int cnt = 0;
		for (int n = 0; n < seq->ntok; n++) {
			const tok_t *tok = &seq->tok[n];
			for (int t = 0; t < tok->ntag; t++) {
				const tag_t *tag = &tok->tag[t];
				if (!strcmp(tag->str, idx)) {
					lua_newtable(L);
					lua_pushinteger(L, n + 1);
					lua_rawseti(L, -2, 1);
					lua_pushinteger(L, n + tag->len);
					lua_rawseti(L, -2, 2);
					lua_rawseti(L, -2, ++cnt);
				}
			}
		}
		return 1;
	}
	luaL_getmetatable(L, "seq_t");
	lua_getfield(L, -1, "__metatable");
	lua_getfield(L, -1, idx);
	return 1;
}

/* seq_add:
 *   Add a new tag in the token [tok] with name [str] and spaning [tok] tokens.
 *   Duplicate tags are not added but doesn't raise an error.
 */
static
void seq_add(lua_State *L, tok_t *tok, const char *str, int len) {
	// First if an exact match of this tag already exists, the tag should
	// not be added again.
	for (int t = 0; t < tok->ntag; t++)
		if (tok->tag[t].len == len && !strcmp(tok->tag[t].str, str))
			return;
	// Next a duplicate of the tag string is done so if this fail the token
	// is left intact.
	char *dup = malloc(strlen(str) + 1);
	if (dup == NULL)
		luaL_error(L, "out of memory");
	strcpy(dup, str);
	// Next some space is made in the tag array of the token. Here also some
	// care are needed to ensure all is left unchanged in case of errors.
	const int ntag = tok->ntag + 1;
	tag_t *lst = realloc(tok->tag, ntag * sizeof(tag_t));
	if (lst == NULL) {
		free(dup);
		luaL_error(L, "out of memory");
	}
	tok->ntag = ntag, tok->tag = lst;
	// If the allocation success, the tag can be created in the new list and
	// success reported. Special care is needed to ensure that the tag list
	// remain ordered first by tag length and next by insertion order.
	int pos = ntag - 1;
	while (pos > 0) {
		if (lst[pos - 1].len <= len)
			break;
		lst[pos] = lst[pos - 1];
		pos--;
	}
	lst[pos].str = dup;
	lst[pos].len = len;
}

/* seqL_add:
 *   Method to add a tag to a sequence from Lua. Take the tag name as well as a
 *   start and end index as parameters. The end index default to the same value
 *   as the start one.
 */
static
int seqL_add(lua_State *L) {
	seq_t      *seq = luaL_checkudata  (L, 1, "seq_t");
	const char *str = luaL_checkstring (L, 2);
	luaL_argcheck(L, seq_istag(str), 2, "invalid tag name");
	const int n1 = seq_checkindex(L, 3, seq);
	const int n2 = seq_optindex  (L, 4, n1, seq);
	luaL_argcheck(L, n1 != -1, 3, "invalid index");
	luaL_argcheck(L, n2 != -1, 4, "invalid index");
	luaL_argcheck(L, n2 >= n1, 4, "invalid index");
	seq_add(L, &seq->tok[n1], str, n2 - n1 + 1);
	lua_settop(L, 1);
	return 1;
}

/* seq_rem:
 *   Remove a tag name [str] from the token [tok]. If [len] is not 0, the tag is
 *   removed only if its length match.
 */
static
void seq_rem(lua_State *L, tok_t *tok, const char *str, int len) {
	unused(L);
	// First the tag is searched in the token list, some optimization are
	// possible here but not really worthwile.
	int t;
	for (t = 0; t < tok->ntag; t++) {
		if (strcmp(tok->tag[t].str, str) != 0)  continue;
		if (len != 0 && tok->tag[t].len != len) continue;
		break;
	}
	if (t == tok->ntag)
		return;
	// If the tag was found, it should be freed and the gap should be filled
	// as no hole are allowed.
	free(tok->tag[t].str);
	tok->ntag--;
	for ( ; t < tok->ntag; t++)
		tok->tag[t] = tok->tag[t + 1];
	tok->tag = realloc(tok->tag, tok->ntag * sizeof(tag_t));
}

/* seqL_rem:
 *   Method to remove tags from Lua. This can take from zero to three arguments
 *   and will do :
 *     []            -> remove all tags
 *     [tag]         -> remove all instances of a tag
 *     [tag, p1]     -> remove a tag at a specific position
 *     [tag, p1, p2] -> remove a tag with this exact span
 */
static
int seqL_rem(lua_State *L) {
	const int narg = lua_gettop(L) - 1;
	seq_t *seq  = luaL_checkudata(L, 1, "seq_t");
	int    ntok = seq->ntok;
	// Without argument, all tags should be removed basicaly doing a big
	// part of the free method.
	if (narg == 0) {
		for (int n = 0; n < ntok; n++) {
			tok_t *tok = &seq->tok[n];
			if (tok->tag != NULL) {
				for (int t = 0; t < tok->ntag; t++)
					if (tok->tag[t].str != NULL)
						free(tok->tag[t].str);
				free(tok->tag);
				tok->tag  = NULL;
				tok->ntag = 0;
			}
		}
	// With a single argument which should be a tag name, all instance of
	// this tag should be removed.
	} else if (narg == 1) {
		const char *str = luaL_checkstring (L, 2);
		luaL_argcheck(L, seq_istag(str), 2, "invalid tag name");
		for (int n = 0; n < ntok; n++)
			seq_rem(L, &seq->tok[n], str, 0);
	// With a tag name and a single position argument, the tag should be
	// removed only at this specific position.
	} else if (narg == 2) {
		const char *str = luaL_checkstring (L, 2);
		luaL_argcheck(L, seq_istag(str), 2, "invalid tag name");
		const int n = seq_checkindex(L, 3, seq);
		luaL_argcheck(L, n != -1, 3, "invalid index");
		seq_rem(L, &seq->tok[n], str, 0);
	// And with a tag name as well as two position, the tag is removed only
	// if it cover exactly this span.
	} else {
		const char *str = luaL_checkstring (L, 2);
		luaL_argcheck(L, seq_istag(str), 2, "invalid tag name");
		const int n1 = seq_checkindex(L, 3, seq);
		const int n2 = seq_checkindex(L, 4, seq);
		luaL_argcheck(L, n1 != -1, 3, "invalid index");
		luaL_argcheck(L, n2 != -1, 4, "invalid index");
		luaL_argcheck(L, n2 >= n1, 4, "invalid index");
		seq_rem(L, &seq->tok[n1], str, n2 - n1 + 1);
	}
	lua_settop(L, 1);
	return 1;
}

/* seqL_tostring:
 *   Meta-method for conversion tostring who search the function in the table
 *   stored in __metatable field so it can be easily provided by the Lua side
 *   without exposing the metatable itself.
 */
static
int seqL_tostring(lua_State *L) {
	luaL_checkudata(L, 1, "seq_t");
	luaL_getmetatable(L, "seq_t");
	lua_getfield(L, -1, "__metatable");
	lua_getfield(L, -1, "tostring");
	if (lua_type(L, -1) == LUA_TNIL)
		return 0;
	lua_pushvalue(L, 1);
	lua_call(L, 1, 1);
	return 1;
}

/* seq_open:
 *   Setup the sequence module in the given Lua state. This mean creating the
 *   meta-table and registering the module function in the table on top of the
 *   stack.
 */
static
void seq_open(lua_State *L) {
	static const luaL_Reg seq_meta[] = {
		{"__gc",       seqL_free    },
		{"__len",      seqL_len     },
		{"__index",    seqL_index   },
		{"__tostring", seqL_tostring},
		{NULL, NULL}};
	static const luaL_Reg seq_method[] = {
		{"add",        seqL_add  },
		{"rem",        seqL_rem  },
		{NULL, NULL}};
	luaL_newmetatable(L, "seq_t");
	luaL_setfuncs(L, seq_meta, 0);
	luaL_newlib(L, seq_method);
	lua_setfield(L, -2, "__metatable");
	lua_pop(L, 1);
	lua_pushcfunction(L, seqL_new);
	lua_setfield(L, -2, "sequence");
}

/*******************************************************************************
 * Maxent model
 *
 *   This is a very small and basic implementation of maximum entropy model to
 *   predict labels for a sequence of tokens. Features are not customizable,
 *   only tokens in window of size three are used through a 2^16:4 hash kernel
 *   for simplicity and efficiency. It perform very well for simple task like
 *   pos-tagging.
 ******************************************************************************/

typedef struct mem_s mem_t;
struct mem_s {
	int nlbl; char  **lbl;
	int nftr; float  *ftr;
};

typedef struct dat_s dat_t;
typedef struct spl_s spl_t;
struct dat_s {
	int nspl;
	struct spl_s {
		int ref, ftr[12];
	} spl[];
};

/* mem_genspl:
 *   Generate a set of samples from a sequence object. For each token in the
 *   sequence a sample is build with features and stored in the [spl] array
 *   which must be big enough. The tag lists are scanned for reference label
 *   and if none are found reference is set to -1.
 */
static
int mem_genspl(const mem_t *mem, const seq_t *seq, spl_t spl[]) {
	const int nspl = seq->ntok;
	unsigned hsh[nspl + 2][4];
	hsh[0][0] = hsh[nspl + 1][0] = 0xDEAD;
	hsh[0][1] = hsh[nspl + 1][1] = 0xBEEF;
	hsh[0][2] = hsh[nspl + 1][2] = 0xCAFE;
	hsh[0][3] = hsh[nspl + 1][3] = 0xBABE;
	for (int n = 0; n < nspl; n++) {
		const char *s = seq->tok[n].raw;
		unsigned long tmp = spooky(s, strlen(s));
		hsh[n + 1][0] = (tmp >>  0) & 0xFFFF;
		hsh[n + 1][1] = (tmp >> 16) & 0xFFFF;
		hsh[n + 1][2] = (tmp >> 32) & 0xFFFF;
		hsh[n + 1][3] = (tmp >> 48) & 0xFFFF;
	}
	for (int n = 0; n < nspl; n++) {
		spl_t *s = &spl[n]; s->ref = -1;
		memcpy(s->ftr + 0, hsh[n + 1], 4 * sizeof(unsigned));
		memcpy(s->ftr + 4, hsh[n + 0], 4 * sizeof(unsigned));
		memcpy(s->ftr + 8, hsh[n + 2], 4 * sizeof(unsigned));
		for (int f = 0; f < 4; f++) {
			s->ftr[f + 0] = (s->ftr[f + 0]         ) & 0xFFFF;
			s->ftr[f + 4] = (s->ftr[f + 4] * 0x0DC7) & 0xFFFF;
			s->ftr[f + 8] = (s->ftr[f + 8] * 0x1EEF) & 0xFFFF;
		}
		for (int t = 0; s->ref == -1 && t < seq->tok[n].ntag; t++) {
			const char *lbl = seq->tok[n].tag[t].str;
			for (int l = 0; s->ref == -1 && l < mem->nlbl; l++)
				if (strcmp(lbl, mem->lbl[l]) == 0)
					s->ref = l;
		}
	}
	return nspl;
}

/* memL_new:
 *   Setup a new model object suitable to predict labels given in the table
 *   passed as first argument. If a second argument is given, it must be a table
 *   of sequence objects forming a training dataset for this set of labels and
 *   the model is trained using R-Prop algorithm. If no second arguments are
 *   given, the model remain initialized to zero.
 */
static
int memL_new(lua_State *L) {
	lua_settop(L, 2);
	mem_t *mem = lua_newuserdata(L, sizeof(mem_t));
	mem->nlbl =    0; mem->nftr =    0;
	mem->lbl  = NULL; mem->ftr  = NULL;
	luaL_getmetatable(L, "mem_t");
	lua_setmetatable(L, -2);
	// If the first argument is a string, it is interpreted as a model file
	// name which is loaded and returned.
	if (lua_isstring(L, 1)) {
		const char *str = lua_tostring(L, 1);
		FILE *file = fopen(str, "rb");
		if (file == NULL) {
			const char *msg = strerror(errno);
			return luaL_error(L, "cannot open file \"%s\"", msg);
		}
		fread(&mem->nlbl, sizeof(int), 1, file);
		mem->lbl = malloc(mem->nlbl * sizeof(char *));
		if (mem->lbl == NULL)
			goto error;
		for (int l = 0; l < mem->nlbl; l++)
			mem->lbl[l] = NULL;
		for (int l = 0; l < mem->nlbl; l++) {
			mem->lbl[l] = malloc(64);
			if (mem->lbl[l] == NULL)
				goto error;
			fread(mem->lbl[l], 64, 1, file);
		}
		mem->nftr = mem->nlbl * (1 << 16);
		mem->ftr  = malloc(mem->nftr * sizeof(float));
		if (mem->ftr == NULL)
			goto error;
		fread(mem->ftr, mem->nftr, sizeof(float), file);
		fclose(file);
		return 1;
	    error:
		fclose(file);
		if (mem->lbl != NULL) {
			for (int l = 0; l < mem->nlbl; l++)
				free(mem->lbl[l]);
			free(mem->lbl);
		}
		return luaL_error(L, "out of memory");
	}
	// Setup the list of labels from the table given as first argument, a
	// copy of each string must be made on C side with carefull ordering
	// so cleanup goes well in case of error.
	luaL_checktype(L, 1, LUA_TTABLE);
	mem->nlbl = lua_rawlen(L, 1);
	mem->lbl = malloc(mem->nlbl * sizeof(char *));
	for (int l = 0; l < mem->nlbl; l++)
		mem->lbl[l] = NULL;
	for (int l = 0; l < mem->nlbl; l++) {
		lua_rawgeti(L, 1, l + 1);
		const char *lbl = lua_tostring(L, -1);
		luaL_argcheck(L, 1, lbl != NULL, "invalid label");
		const int len = strlen(lbl) + 1;
		luaL_argcheck(L, 1, len < 63, "overlong label");
		mem->lbl[l] = malloc(64);
		if (mem->lbl[l] == NULL)
			return luaL_error(L, "out of memory");
		memset(mem->lbl[l], 0, 64);
		strcpy(mem->lbl[l], lbl);
		lua_pop(L, 1);
	}
	mem->nftr = mem->nlbl * (1 << 16);
	mem->ftr  = malloc(mem->nftr * sizeof(float));
	// Next, the training dataset is loaded in a temporary userdata stored
	// on the stack so the GC take care of cleaning this. The first pass
	// count the number of sample and validate the table.
	luaL_checktype(L, 2, LUA_TTABLE);
	int nseq = lua_rawlen(L, 2), nspl = 0;
	seq_t *seq[nseq];
	for (int i = 0; i < nseq; i++) {
		lua_rawgeti(L, 2, i + 1);
		seq[i] = luaL_testudata(L, -1, "seq_t");
		luaL_argcheck(L, 2, seq[i] != NULL, "invalid sample");
		nspl += seq[i]->ntok;
		lua_pop(L, 1);
	}
	const int sz = sizeof(dat_t) + nspl * sizeof(spl_t);
	dat_t *trn = lua_newuserdata(L, sz); trn->nspl = 0;
	for (int i = 0; i < nseq; i++) {
		spl_t *spl = trn->spl + trn->nspl;
		trn->nspl += mem_genspl(mem, seq[i], spl);
	}
	// And last, the model can be trained using the resilient propagation
	// algorithm for ten iterations. This should be enough to properly train
	// the model with so few features.
	#define sign(v) ((v) < 0.0f ? -1.0f : ((v) > 0.0f ? 1.0f : 0.0f))
	float *wgh = mem->ftr;
	float *grd = lua_newuserdata(L, mem->nftr * sizeof(float));
	float *gpv = lua_newuserdata(L, mem->nftr * sizeof(float));
	float *stp = lua_newuserdata(L, mem->nftr * sizeof(float));
	for (int f = 0; f < mem->nftr; f++)
		gpv[f] = 0.0f, stp[f] = 0.1f, wgh[f] = 0.0f;
	for (int it = 0; it < 10; it++) {
		// First step is to compute the gradient and value of the
		// objective function at the current point.
		float ll = 0.0f;
		for (int f = 0; f < mem->nftr; f++)
			grd[f] = 0.0f;
		for (int s = 0; s < trn->nspl; s++) {
			spl_t *spl = &trn->spl[s];
			if (spl->ref == -1)
				continue;
			float psi[mem->nlbl];
			for (int y = 0; y < mem->nlbl; y++)
				psi[y] = 0.0f;
			for (int f = 0; f < 12; f++) {
				const int base = spl->ftr[f] * mem->nlbl;
				for (int y = 0; y < mem->nlbl; y++)
					psi[y] += wgh[base + y];
			}
			float Z = psi[0];
			for (int y = 1; y < mem->nlbl; y++) {
				const float V = psi[y];
				if (Z > V) Z = Z + logf(1.0f + expf(V - Z));
				else       Z = V + logf(1.0f + expf(Z - V));
			}
			float pb[mem->nlbl];
			for (int y = 0; y < mem->nlbl; y++)
				pb[y] = expf(psi[y] - Z);
			pb[spl->ref] -= 1.0f;
			for (int f = 0; f < 12; f++) {
				const int base = spl->ftr[f] * mem->nlbl;
				for (int y = 0; y < mem->nlbl; y++)
					grd[base + y] += pb[y];
			}
			ll += Z - psi[spl->ref];
		}
		float r2 = 1.2f, l2 = 0.0f;
		for (int f = 0; f < mem->nftr; f++)
			grd[f] += wgh[f] * r2, l2 += wgh[f] * wgh[f];
		ll += l2 * r2 / 2.0f;
		// Next, this gradient is used to update the current point with
		// the R-Prop optimization algorithm.
		for (int f = 0; f < mem->nftr; f++) {
			const float sgn = grd[f] * gpv[f];
			if (sgn > 0.0f) {
				stp[f] *= 1.2f;
				wgh[f] -= sign(grd[f]) * stp[f];
				gpv[f]  = grd[f];
			} else if (sgn < 0.0f) {
				stp[f]  = stp[f] * 0.5f;
				gpv[f]  = 0.0f;
			} else {
				wgh[f] -= sign(grd[f]) * stp[f];
				gpv[f]  = grd[f];
			}
		}
	}
	lua_pop(L, 4);
	#undef sign
	return 1;
}

/* memL_free
 *   Free all memory associated with a maxent model object, this should not be
 *   called directly but only automaticaly by the garbage collector when the
 *   object is no longer reachable.
 */
static
int memL_free(lua_State *L) {
	mem_t *mem = luaL_checkudata(L, 1, "mem_t");
	if (mem->lbl != NULL) {
		for (int l = 0; l < mem->nlbl; l++)
			if (mem->lbl[l] != NULL)
				free(mem->lbl[l]);
		free(mem->lbl);
		mem->lbl = NULL;
	}
	if (mem->ftr != NULL) {
		free(mem->ftr);
		mem->ftr = NULL;
	}
	return 0;
}

/* memL_write:
 *   Method to write the model to the file given as first argument in a format
 *   suitable for fast loading.
 */
static
int memL_write(lua_State *L) {
	mem_t *mem = luaL_checkudata(L, 1, "mem_t");
	const char *str = luaL_checkstring(L, 2);
	FILE *file = fopen(str, "wb");
	if (file == NULL) {
		const char *msg = strerror(errno);
		return luaL_error(L, "cannot open file \"%s\"", msg);
	}
	fwrite(&mem->nlbl, sizeof(int), 1, file);
	for (int l = 0; l < mem->nlbl; l++)
		fwrite(mem->lbl[l], 64, 1, file);
	fwrite(mem->ftr, mem->nftr, sizeof(float), file);
	fclose(file);
	return 0;
}

/* memL_label:
 *   Use a maxent model to make predictions for the given sequence. The labels
 *   are added as single token tags on the sequence.
 */
static
int memL_label(lua_State *L) {
	mem_t *mem = luaL_checkudata(L, 1, "mem_t");
	seq_t *seq = luaL_checkudata(L, 2, "seq_t");
	const float *wgh = mem->ftr;
	spl_t spl[seq->ntok];
	mem_genspl(mem, seq, spl);
	for (int n = 0; n < seq->ntok; n++) {
		float psi[mem->nlbl];
		for (int y = 0; y < mem->nlbl; y++)
			psi[y] = 0.0f;
		for (int f = 0; f < 12; f++) {
			const int base = spl[n].ftr[f] * mem->nlbl;
			for (int y = 0; y < mem->nlbl; y++)
				psi[y] += wgh[base + y];
		}
		int   lbl = 0;
		float bst = psi[0];
		for (int y = 1; y < mem->nlbl; y++)
			if (psi[y] > bst)
				bst = psi[y], lbl = y;
		seq_add(L, &seq->tok[n], mem->lbl[lbl], 1);
	}
	return 1;
}

/* mem_open:
 *   Setup the maxent module in the given Lua state. This mean creating the
 *   meta-table and registering the module function in the table on top of the
 *   stack.
 */
static
void mem_open(lua_State *L) {
	static const luaL_Reg mem_meta[] = {
		{"__gc",   memL_free },
		{"__call", memL_label},
		{NULL, NULL}};
	static const luaL_Reg mem_method[] = {
		{"label",  memL_label},
		{"write",  memL_write},
		{NULL, NULL}};
	luaL_newmetatable(L, "mem_t");
	luaL_setfuncs(L, mem_meta, 0);
	luaL_newlib(L, mem_method);
	lua_pushvalue(L, -1);
	lua_setfield(L, -3, "__index");
	lua_setfield(L, -2, "__metatable");
	lua_pop(L, 1);
	lua_pushcfunction(L, memL_new);
	lua_setfield(L, -2, "maxent");
}

/*******************************************************************************
 * Patterns
 ******************************************************************************/

typedef struct pat_s     pat_t;
typedef struct pat_ins_s pat_ins_t;
typedef struct pat_cap_s pat_cap_t;
struct pat_s {
	int pos,  size;
	int nstr, ncap;
	char **str;
	struct pat_ins_s {
		int opc  :  8;  // Instruction opcode
		int arg1 : 24;  // Instruction first argument
		int arg2;       // Instruction second argument
	} *code;
};
struct pat_cap_s {
	int beg, end, id;
};

enum {
	pat_Imatch, // Record a match
	pat_Itest,  // If (arg1) jump to arg2 else fail
	pat_Iany,   // Consume a token a jump to arg2
	pat_Itoken, // If (token == arg1) jump to arg2 else fail
	pat_Itag,   // If (has a tag arg1) jump to arg2 else fail
	pat_Iregex, // If (token match arg1) jump to arg2 else fail
	pat_Icall,  // if (arg1(token)) jump to arg2 else fail
	pat_Isplit, // Jump to both arg1 and arg2 (if different)
	pat_Iopen,  // Start the arg1 capture and jump to arg2
	pat_Iclose, // Finish the arg1 capture and jump to arg2
	pat_Idead,  // Dead code
};

/* pat_add:
 *   Insert the instruction (opc, a1, a2) in the code buffer at requested
 *   position. This take care of growing the buffer if needed and moving part of
 *   code. The caller must ensure that no arcs cross the [at] position or their
 *   targets will not be adjusted and bad things will result.
 */
static
void pat_add(lua_State *L, pat_t *pat, int at, int opc, int a1, int a2) {
	// First take care of resizing the buffer if not big enough and track
	// out of memory errors. After this point it can be safely assumed that
	// the buffer have enough space to add the new instruction.
	if (pat->size == pat->pos) {
		const int size = (pat->size == 0) ? 8 : pat->size * 2;
		pat_ins_t *tmp = realloc(pat->code, sizeof(pat_ins_t) * size);
		if (tmp == NULL)
			luaL_error(L, "out of memory");
		pat->code = tmp;
		pat->size = size;
	}
	// If the arc should be inserted somewhere inside the buffer and not at
	// its end, some other arcs have to be moved to make some room for it
	// and their target should be adjusted.
	if (at != pat->pos) {
		const int  size = pat->pos  - at;
		pat_ins_t *code = pat->code + at;
		memmove(code + 1, code, sizeof(pat_ins_t) * size);
		for (int i = 1; i <= size; i++) {
			if (code[i].opc == pat_Isplit) code[i].arg1++;
			if (code[i].opc != pat_Imatch) code[i].arg2++;
		}
	}
	pat->pos++;
	pat->code[at].opc  = opc;
	pat->code[at].arg1 = a1;
	pat->code[at].arg2 = a2;
}

/* pat_str:
 *   Add a new string to the string pool of the given pattern and return its
 *   identifier.
 */
static
int pat_str(lua_State *L, pat_t *pat, const char *str, int len) {
	const int nstr = pat->nstr + 1;
	char **tmp = realloc(pat->str, nstr * sizeof(char *));
	if (tmp == NULL)
		luaL_error(L, "out of memory");
	pat->str = tmp;
	char *new = malloc((len + 1) * sizeof(char));
	if (new == NULL)
		luaL_error(L, "out of memory");
	pat->str[pat->nstr++] = new;
	memcpy(new, str, len * sizeof(char));
	new[len] = '\0';
	return pat->nstr - 1;
}

/* pat_atom:
 *   Parse an atom (either a tag or litteral), insert it in the string pool and
 *   return its identifier.
 */
static
int pat_atom(lua_State *L, pat_t *pat, const char *str, int len, int *pos) {
	int  cnt = 0;
	char buf[len - *pos + 1];
	// A tag is composed of & character followed by a non-zero sequence of
	// tag characters. The & is a part of the tag name.
	if (str[*pos] == '&') {
		do {
			buf[cnt++] = str[(*pos)++];
		} while (*pos < len && seq_istagchr(str[*pos]));
		if (cnt == 1)
			luaL_error(L, "missing tag name");
	// A function call is an @ followed by a non-zero sequence of valid
	// identifier characters. The @ is not part of the function name.
	} else if (str[*pos] == '@') {
		#define isident(c) (isalnum((c)) || (c) == '_')
		(*pos)++;
		while (*pos < len && isident(str[*pos]))
			buf[cnt++] = str[(*pos)++];
		if (cnt == 0)
			luaL_error(L, "missing function name");
		#undef isident
	// A string token is a sequence of characters surrounded by "" with
	// simple escapes and may be zero length.
	} else if (str[*pos] == '"' || str[*pos] == '\'') {
		const char end = str[(*pos)++];
		while (*pos < len && str[*pos] != end) {
			if (str[*pos] == '%') {
				if (*pos == len - 1)
					luaL_error(L, "unfinished escape");
				(*pos)++;
			}
			buf[cnt++] = str[(*pos)++];
		}
		if ((*pos)++ == len)
			luaL_error(L, "unfinished token");
	// A Lua regexp is a sequence of characters surrounded by // with simple
	// escapes kept in the pattern who may be zero length.
	} else if (str[*pos] == '/') {
		(*pos)++;
		while (*pos < len && str[*pos] != '/') {
			if (str[*pos] == '%') {
				if (*pos == len - 1)
					luaL_error(L, "unfinished escape");
				buf[cnt++] = str[(*pos)++];
			}
			buf[cnt++] = str[(*pos)++];
		}
		if ((*pos)++ == len)
			luaL_error(L, "unfinished token");
	// And finally, the simple tokens who are just sequence of alphanumeric
	// characters without any marker or delimiters.
	} else if (isalnum(str[*pos])) {
		while (*pos < len && isalnum(str[*pos]))
			buf[cnt++] = str[(*pos)++];
	// Anything remaining is just an error...
	} else {
		luaL_error(L, "unexpected character '%c'", str[*pos]);
	}
	return pat_str(L, pat, buf, cnt);
}

/* pat_skip:
 *   Seek the next token start in the input string and return its first
 *   character which is consumed. If the end of string is reached, return -1.
 */
static
int pat_skip(const char *str, int len, int *pos) {
	while (*pos < len) {
		if (!isspace(str[*pos]))
			break;
		(*pos)++;
	}
	if (*pos == len)
		return -1;
	return (unsigned char)str[(*pos)++];
}

/* pat_block:
 *   Main codegen function. This handle most of the grammar with a recursive
 *   descent parser written so that recursion is only needed for grouping
 *   construct.
 *   If all goes well, code for the current block is produced in the given
 *   buffer and the [pos] variable is set to the first unused character in the
 *   buffer. In case of error, a negative error code is returned and [pos] will
 *   point on the character following the error.
 */
static
int pat_block(lua_State *L, pat_t *pat, const char *str, int len, int *pos) {
#define next()    pat_skip(str, len, pos)
#define look(c)   (*pos < len && str[*pos] == (c) ? chr = next(), 1 : 0)
#define put(i, a) pat_add(L, pat, pat->pos, (i), (a), pat->pos + 1)
	int chr = next();
	// Outer loop for alternative. Each iteration compile one of the member
	// of the current chain. This stop when no more alternative are found in
	// the current block.
	int alt_pos = pat->pos;
	int alt_jmp = -1;
	while (1) {
		// Inner loop for concatenation. Each iteration compile one item
		// of the sequence and stop either if an alternation symbol is
		// found or at end of current block.
		while (chr >= 0) {
			if (chr == ']' || chr == ')' || chr == '|')
				break;
			if (chr == '^' || chr == '$') {
				put(pat_Itest, chr);
				chr = next();
				continue;
			}
			// First an atom or a group is expected. As the stop
			// case have been handled, the lookahead character is
			// always consumed here.
			int mk = pat->pos, id = -1, nc = -1;
			switch (chr) {
				case '*': case '+': case '?':
					luaL_error(L, "bad repetition %c", chr);
				case '[':
					if (str[(*pos)] != '&')
						luaL_error(L, "miss tag name");
					nc = pat->ncap++;
					id = pat_atom(L, pat, str, len, pos);
					put(pat_Iopen, id << 8 | nc);
					chr = pat_block(L, pat, str, len, pos);
					if (chr != ']')
						luaL_error(L, "miss closing ]");
					put(pat_Iclose, nc);
					chr = next();
					break;
				case '(':
					chr = pat_block(L, pat, str, len, pos);
					if (chr != ')')
						luaL_error(L, "miss closing )");
					chr = next();
					break;
				case '.':
					put(pat_Iany, 0);
					chr = next();
					break;
				default:
					(*pos)--;
					id = pat_atom(L, pat, str, len, pos);
					     if (chr == '&')put(pat_Itag,   id);
					else if (chr == '/')put(pat_Iregex, id);
					else if (chr == '@')put(pat_Icall,  id);
					else                put(pat_Itoken, id);
					chr = next();
					break;
			}
			// Next a suffix may be present indicating some kind of
			// repetition of the matched atom starting at the marked
			// position.
			if (chr == '*') {
				int t1 = mk + 1, t2 = pat->pos + 2;
				if (look('?')) swap(int, t1, t2);
				pat_add(L, pat, mk, pat_Isplit, t1, t2);
				pat_add(L, pat, pat->pos, pat_Isplit, mk, mk);
				chr = next();
			} else if (chr == '+') {
				int t1 = mk, t2 = pat->pos + 1;
				if (look('?')) swap(int, t1, t2);
				pat_add(L, pat, pat->pos, pat_Isplit, t1, t2);
				chr = next();
			} else if (chr == '?') {
				int t1 = mk + 1, t2 = pat->pos + 1;
				if (look('?')) swap(int, t1, t2);
				pat_add(L, pat, mk, pat_Isplit, t1, t2);
				chr = next();
			}
		}
		// And the parsed sequence is added to the list of alternatives
		// like for the sequence items. If no more sequences are present
		// the parsing can be stop.
		if (chr != '|')
			break;
		pat_add(L, pat, alt_pos, pat_Isplit, alt_pos + 1, pat->pos + 2);
		if (alt_jmp != -1) {
			pat->code[alt_jmp].arg1 = pat->pos;
			pat->code[alt_jmp].arg2 = pat->pos;
		}
		alt_jmp = pat->pos; alt_pos = pat->pos + 1;
		pat_add(L, pat, pat->pos, pat_Isplit, 0, 0);
		chr = next();
	}
	if (alt_jmp != -1) {
		pat->code[alt_jmp].arg1 = pat->pos;
		pat->code[alt_jmp].arg2 = pat->pos;
	}
	return chr;
#undef put
#undef look
#undef next
}

/* patL_new:
 *   Compile and return a new pattern object ready to be applyed on sequence
 *   objects. On problem, raise an error with a meaningfull message (or try to
 *   be).
 */
static
int patL_new(lua_State *L) {
	const char *str = luaL_checkstring(L, 1);
	pat_t *pat = lua_newuserdata(L, sizeof(pat_t));
	pat->pos  = pat->size = 0;
	pat->nstr = pat->ncap = 0;
	pat->code = NULL;
	pat->str  = NULL;
	luaL_getmetatable(L, "pat_t");
	lua_setmetatable(L, -2);
	// First a jump and a ".*" is compiled at the start of the buffer to
	// allow match at any position in the target string. And next, the
	// regexp is compiled with just an additional match at the end to record
	// success.
	int pos = 0, len = strlen(str);
	pat_add(L, pat, pat->pos, pat_Isplit, 2, 1);
	pat_add(L, pat, pat->pos, pat_Iany,   0, 0);
	const int res = pat_block(L, pat, str, len, &pos);
	if (res != -1)
		luaL_error(L, "unexpected character %c", res);
	pat_add(L, pat, pat->pos, pat_Imatch, 0, 0);
	pat->size = pat->pos;
	// Now, a pipehole opimization pass is done. The codegen is allowed to
	// produce inefficient code as long as it can be easily optimized here.
	#define isjump(n) ((n).opc == pat_Isplit && (n).arg1 == (n).arg2)
	for (int pc = 1; pc < pat->pos; pc++) {
		pat_ins_t *c = pat->code;
		if (isjump(c[pc]))
			continue;
		// For splits, the first argument hold a jump target so it
		// should be optimized to its final destination.
		if (c[pc].opc == pat_Isplit) {
			int trg = c[pc].arg1;
			while (isjump(c[trg]))
				trg = c[trg].arg2;
			c[pc].arg1 = trg;
		}
		// For everything except matchs, the second argument is a jump
		// target so it should also be optimized.
		if (c[pc].opc != pat_Imatch) {
			unsigned trg = c[pc].arg2;
			while (isjump(c[trg]))
				trg = c[trg].arg2;
			c[pc].arg2 = trg;
		}
	}
	for (int pc = 0; pc < pat->pos; pc++)
		if (isjump(pat->code[pc]))
			pat->code[pc].opc = pat_Idead;
	#undef isjump
	return 1;
}

/* patL_free:
 *   Release all memory used by a pattern object on the C side. This doesn't
 *   free the pattern object itself as it is allocated on the Lua side. This
 *   function should be called only by the Lua garbage collector, it should
 *   never be called directly.
 */
static
int patL_free(lua_State *L) {
	pat_t *pat = luaL_checkudata(L, 1, "pat_t");
	if (pat->code != NULL) {
		free(pat->code);
		pat->code = NULL;
	}
	if (pat->str != NULL) {
		for (int i = 0; i < pat->nstr; i++)
			free(pat->str[i]);
		free(pat->str);
		pat->str = NULL;
	}
	return 0;
}

/* pat_exec:
 *   Execute a compiled pattern on the given sequence at position [sp] starting
 *   execution at instruction [pc] and populate [cap] with the captures found
 *   during the execution. If a match is found, return the index of the first
 *   token after the match, else return 0.
 */
static
int pat_exec(lua_State *L, int pc, int sp, pat_cap_t cap[]) {
	pat_t *pat = lua_touserdata(L, 1);
	seq_t *seq = lua_touserdata(L, 2);
	const int ntok = seq->ntok;
	while (1) {
		const pat_ins_t *ins = &pat->code[pc];
		const int a1 = ins->arg1, a2 = ins->arg2;
		switch (ins->opc) {
			// First, handle the simple non-consuming instructions
			// that don't alter the source pointer.
			case pat_Imatch:
				return sp;
			case pat_Itest:
				     if (a1 == '^' && sp == 0)        pc = a2;
				else if (a1 == '$' && sp == ntok - 1) pc = a2;
				else return -1;
				break;
			// Next the consuming instructions. Each of these assert
			// something on the input and follow a single arc if
			// possible.
			case pat_Iany:
				if (sp >= ntok)
					return -1;
				pc = a2; sp++;
				break;
			case pat_Itoken: {
				if (sp >= ntok) return -1;
				const tok_t *tok = &seq->tok[sp];
				if (strcmp(pat->str[a1], tok->raw) != 0)
					return -1;
				pc = a2; sp++;
				break;}
			case pat_Itag: {
				if (sp >= ntok) return -1;
				const tok_t *tok = &seq->tok[sp];
				const char *ref = pat->str[a1];
				int len = -1;
				for (int i = 0; len == -1 && i < tok->ntag; i++)
					if (strcmp(ref, tok->tag[i].str) == 0)
						len = tok->tag[i].len;
				if (len == -1) return -1;
				pc = a2; sp += len;
				break;}
			case pat_Iregex: {
				if (sp >= ntok) return -1;
				lua_getglobal(L, "string");
				lua_getfield(L, -1, "find");
				lua_pushstring(L, seq->tok[sp].raw);
				lua_pushstring(L, pat->str[a1]);
				lua_call(L, 2, 1);
				int res = lua_isnoneornil(L, -1);
				lua_pop(L, 2);
				if (res) return -1;
				pc = a2; sp++;
				break; }
			case pat_Icall: {
				if (sp >= ntok) return -1;
				lua_getglobal(L, pat->str[a1]);
				lua_pushvalue(L, 2);
				lua_pushinteger(L, sp + 1);
				lua_call(L, 2, 1);
				int res = lua_toboolean(L, -1);
				lua_pop(L, 1);
				if (res == 0) return -1;
				pc = a2; sp++;
				break; }
			// The split instruction who can create new threads
			// meaning in this case making a recursive call. First
			// branch should be taken first to ensure respect of the
			// priority.
			case pat_Isplit:
				if (a1 != a2) {
					int res = pat_exec(L, a1, sp, cap);
					if (res != -1)
						return res;
				}
				pc = a2;
				break;
			// And finally, the capture instructions who record the
			// matches as we go
			case pat_Iopen: {
				pat_cap_t old = cap[a1 & 0xFF];
				cap[a1 & 0xFF].id  = a1 >> 8;
				cap[a1 & 0xFF].beg = sp;
				int res = pat_exec(L, a2, sp, cap);
				if (res != -1) return res;
				cap[a1 & 0xFF] = old;
				return -1; }
			case pat_Iclose: {
				pat_cap_t old = cap[a1 & 0xFF];
				cap[a1 & 0xFF].end = sp - 1;
				int res = pat_exec(L, a2, sp, cap);
				if (res != -1) return res;
				cap[a1 & 0xFF] = old;
				return -1; }
			case pat_Idead:
				luaL_error(L, "internal error");
				return -42;
		}
	}
	return -1;
}

/* patL_exec:
 *   Apply a pre-compiled pattern on a given sequence and return true is a match
 *   was found. This take care of running the compiled pattern and adding tags
 *   corresponding to the matched captures.
 */
static
int patL_exec(lua_State *L) {
	pat_t *pat = luaL_checkudata(L, 1, "pat_t");
	seq_t *seq = luaL_checkudata(L, 2, "seq_t");
	pat_cap_t cap[pat->ncap];
	for (int sp = 0; sp < seq->ntok; ) {
		for (int i = 0; i < pat->ncap; i++)
			cap[i].id = -1;
		sp = pat_exec(L, 0, sp, cap);
		if (sp == -1)
			break;
		for (int i = 0; i < pat->ncap; i++) {
			if (cap[i].id != -1) {
				const int   beg = cap[i].beg;
				const int   len = cap[i].end - cap[i].beg + 1;
				const char *tag = pat->str[cap[i].id];
				seq_add(L, &seq->tok[beg], tag, len);
			}
		}
	}
	return 1;
}

/* patL_dump:
 *   Return a disasembly dump of the pattern compiled code. This is only
 *   intended for debuging.
 */
static
int patL_dump(lua_State *L) {
	static const char *opn[] = {
		"\033[1;34m" "match" "\033[0m", "\033[1;34m" "test"  "\033[0m",
		"\033[1;32m" "any"   "\033[0m", "\033[1;32m" "token" "\033[0m",
		"\033[1;32m" "tag"   "\033[0m", "\033[1;32m" "regex" "\033[0m",
		"\033[1;32m" "call"  "\033[0m", "\033[1;33m" "split" "\033[0m",
		"\033[1;33m" "open"  "\033[0m", "\033[1;33m" "close" "\033[0m",
		"\033[1;31m" "dead"  "\033[0m",
	};
	const pat_t *pat = luaL_checkudata(L, 1, "pat_t");
	luaL_Buffer xB, *B = &xB;
	luaL_buffinit(L, B);
	for (int pc = 0; pc < pat->size; pc++) {
		const pat_ins_t *ins = &pat->code[pc];
		lua_pushfstring(L, "%d:\t", pc);
		luaL_addvalue(B);
		luaL_addstring(B, opn[ins->opc]);
		int a1 = ins->arg1;
		switch (ins->opc) {
			case pat_Itest:
				lua_pushfstring(L, "\t%c", a1);
				luaL_addvalue(B);
				break;
			case pat_Itoken:
				lua_pushfstring(L, "\t\"%s\"", pat->str[a1]);
				luaL_addvalue(B);
				break;
			case pat_Itag:
				lua_pushfstring(L, "\t%s", pat->str[a1]);
				luaL_addvalue(B);
				break;
			case pat_Iregex:
				lua_pushfstring(L, "\t/%s/", pat->str[a1]);
				luaL_addvalue(B);
				break;
			case pat_Icall:
				lua_pushfstring(L, "\t%s", pat->str[a1]);
				luaL_addvalue(B);
				break;
			case pat_Isplit:
				lua_pushfstring(L, "\t@%d", a1);
				luaL_addvalue(B);
				break;
			case pat_Iopen:
				lua_pushfstring(L, "\t%s", pat->str[a1 >> 8]);
				a1 = a1 & 0xFF;
			case pat_Iclose:
				lua_pushfstring(L, "\t%d", a1);
				break;
		}
		if (ins->opc != pat_Imatch && ins->opc != pat_Idead) {
			lua_pushfstring(L, "\t@%d", ins->arg2);
			luaL_addvalue(B);
		}
		luaL_addstring(B, "\n");
	}
	luaL_pushresult(B);
	return 1;
}

/* pat_open:
 *   Setup the pattern module in the given Lua state. This mean creating the
 *   meta-table and registering the module function in the table on top of the
 *   stack.
 */
static
void pat_open(lua_State *L) {
	static const luaL_Reg pat_meta[] = {
		{"__gc",   patL_free},
		{"__call", patL_exec},
		{NULL, NULL}};
	static const luaL_Reg pat_method[] = {
		{"exec",   patL_exec},
		{"dump",   patL_dump},
		{NULL, NULL}};
	luaL_newmetatable(L, "pat_t");
	luaL_setfuncs(L, pat_meta, 0);
	luaL_newlib(L, pat_method);
	lua_pushvalue(L, -1);
	lua_setfield(L, -3, "__index");
	lua_setfield(L, -2, "__metatable");
	lua_pop(L, 1);
	lua_pushcfunction(L, patL_new);
	lua_setfield(L, -2, "pattern");
}

/*******************************************************************************
 * Lua interpreter
 *
 *   The C part of DARK above is exposed as a Lua library that can be compiled
 *   as a loadable module. The open function below will be called by Lua if this
 *   code is compiled as a shared library and 'required' by a Lua script.
 *
 *   DARK can also be compiled as an independant binary who embed the Lua
 *   interpreter. In this case, the code below will be active and take care of
 *   all the needed setup to spawn a new interpreter, open the Lua standard
 *   library and run the main support script.
 *   In this mode, the library is still not automatically loaded but some magic
 *   is done so a require will load it. This allow to use exactly the same code
 *   in both modes.
 ******************************************************************************/

/* darkL_type:
 *   An extended type function who support the new types defined in DARK.
 */
static
int darkL_type(lua_State *L) {
	lua_settop(L, 1);
	     if (luaL_testudata(L, 1, "seq_t")) lua_pushstring(L, "sequence");
	else if (luaL_testudata(L, 1, "mem_t")) lua_pushstring(L, "maxent");
	else if (luaL_testudata(L, 1, "pat_t")) lua_pushstring(L, "pattern");
	else lua_pushstring(L, luaL_typename(L, 1));
	return 1;
}

/* darkL_method:
 *   This is special function who return the table with methods for one of the
 *   DARK Lua objects. It allow the Lua side of DARK to add methods to these
 *   objects written fully in Lua.
 */
static
int darkL_method(lua_State *L) {
	const char *str = luaL_checkstring(L, 1);
	if (strcmp(str, "seq_t") != 0)
		return 0;
	luaL_getmetatable(L, str);
	lua_getfield(L, -1, "__metatable");
	return 1;
}

/* luaopen_dark:
 *   DARK module entry point. This is called by lua when module is required
 *   and is responsible to setup all the code exposed by Lost. It only return a
 *   table with all the module contents.
 */
int luaopen_dark(lua_State *L) {
	static const luaL_Reg lib[] = {
		{"type",   darkL_type  },
		{"method", darkL_method},
		{NULL, NULL}};
	luaL_newlib(L, lib);
	lua_pushstring(L, DARK_VERSION);
	lua_setfield(L, -2, "version");
	seq_open(L);
	mem_open(L);
	pat_open(L);
	return 1;
}

#ifndef DARK_SHARED
#include "dark.inc"

/* traceback:
 *   This function is called when an error occur in protected call of a Lua
 *   script. It add debug informations to the error message.
 */
static
int traceback(lua_State *L) {
	const char *msg = lua_tostring(L, 1);
	if (msg != NULL) {
		luaL_traceback(L, L, msg, 1);
	} else if (!lua_isnoneornil(L, 1)) {
		if (!luaL_callmeta(L, 1, "__tostring"))
			lua_pushliteral(L, "(no error message)");
	}
	return 1;
}

/* pmain:
 *   The true entry point called in protected environment by 'main'. Here, we
 *   can initialize the Lua state and launch the support code.
 */
static
int pmain(lua_State *L) {
	int    argc = (int    )lua_tointeger (L, 1);
	char **argv = (char **)lua_touserdata(L, 2);
	// We first open the Lua standard libs and the Lost libs, stoping the GC
	// during this step as a little optimization.
	lua_gc(L, LUA_GCSTOP, 0);
	luaL_openlibs(L);
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
	lua_pushcfunction(L, luaopen_dark);
	lua_setfield(L, -2, "dark");
	lua_settop(L, 0);
	lua_gc(L, LUA_GCRESTART, 0);
	// If the first argument start with an '@', it is removed and remaining
	// string is used as the filename for replacement script which will be
	// used instead of the internal one. If there is no filename after the
	// '@', this just mean to enable debugging on the internal script.
	bool dbg = false, ext = false;
	if (argc > 0 && argv[0][0] == '@') {
		dbg = true;
		lua_pushcfunction(L, traceback);
		const char *filename = argv[0] + 1;
		if (filename[0] != '\0') {
			ext = true;
			if (luaL_loadfile(L, filename))
				lua_error(L);
		}
		argc--, argv++;
	}
	// Next we load compiled support script stored at compilation time. We
	// do this only if no external script was loaded in the previous step.
	if (ext == false)
		if (luaL_loadbuffer(L, dark_dat, dark_len, NULL))
			lua_error(L);
	// We now have the Lua script on top of the stack and perhaps the debug
	// function just below, we can now push the argument and call execute
	// the script.
	lua_checkstack(L, lua_gettop(L) + argc);
	for (int a = 0; a < argc; a++)
		lua_pushstring(L, argv[a]);
	if (lua_pcall(L, argc, 0, dbg))
		lua_error(L);
	// Clean all and return.
	lua_settop(L, 0);
	lua_gc(L, LUA_GCCOLLECT, 0);
	return 0;
}

/* main:
 *   Main will just create the Lua state and jump into a protected environment.
 *   Execution will continue in the 'pmain' where any error can be catch by Lua
 *   and returned here.
 */
int main(int argc, char *argv[argc]) {
	lua_State *L = luaL_newstate();
	if (L == NULL) {
		fprintf(stderr, "error: cannot create Lua state\n");
		return EXIT_FAILURE;
	}
	lua_pushcfunction(L, &pmain);
	lua_pushinteger(L, argc - 1);
	lua_pushlightuserdata(L, argv + 1);
	int res = lua_pcall(L, 2, 1, 0);
	if (res != 0) {
		const char *msg = lua_tostring(L, -1);
		if (msg != NULL)
			fprintf(stderr, "error: %s\n", msg);
		else
			fprintf(stderr, "error: unknown error\n");
		lua_close(L);
		return EXIT_FAILURE;
	}
	res = lua_toboolean(L, -1);
	lua_close(L);
	return res ? EXIT_SUCCESS : EXIT_FAILURE;
}

#endif

/*******************************************************************************
 * This is the end...
 ******************************************************************************/

