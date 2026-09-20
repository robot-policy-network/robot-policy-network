/**
 * canonical.js — the reference implementation of settlement-spec.md §3.
 *
 * SPEC_VERSION 2. This file is the authoritative canonicalizer for the
 * protocol: it is the *only* implementation, and the contract never
 * canonicalizes anything — it stores and compares the 32-byte commitments it
 * is given (spec §3). Every hash in the protocol is keccak256 over the UTF-8
 * bytes of the string this module returns.
 *
 * Rules (spec §3):
 *   1. Object keys sorted ascending by UTF-16 code unit, recursively.
 *   2. No insignificant whitespace.
 *   3. Strings: exactly these escapes — \" \\ \b \f \n \r \t — plus \u00XX
 *      for other C0 controls. "/" is NOT escaped. Non-ASCII is emitted
 *      literally (UTF-8 when the string is later encoded).
 *   4. Numbers must be integers within Number.MAX_SAFE_INTEGER. Floats, NaN,
 *      Infinity and -0 are rejected.
 *   5. Booleans are true/false. null is rejected — omit the key instead, so
 *      "absent" has exactly one encoding.
 *   6. Arrays preserve order.
 *
 * This module has zero dependencies. `canonicalize(value)` returns the
 * canonical string; hashing (keccak256 over UTF-8 bytes) is deliberately left
 * to the caller so this file stays a pure serializer that can be diffed
 * against the spec by eye. See canonical.test.mjs for the pinned vectors.
 */

const MAX_SAFE = Number.MAX_SAFE_INTEGER;

/** Throws unless `value` is an integer the protocol accepts. */
function assertInteger(value) {
  if (typeof value !== "number" || !Number.isInteger(value)) {
    throw new TypeError("canonical: numbers must be integers");
  }
  if (Number.isNaN(value) || !Number.isFinite(value)) {
    throw new TypeError("canonical: NaN/Infinity are rejected");
  }
  if (Object.is(value, -0)) {
    throw new TypeError("canonical: -0 is rejected (emit 0)");
  }
  if (Math.abs(value) > MAX_SAFE) {
    throw new TypeError("canonical: integer outside Number.MAX_SAFE_INTEGER");
  }
}

/** C0 controls (0x00–0x1F) per spec rule 3, plus quote and backslash. DEL (0x7F) is not escaped. */
function escapeString(str) {
  let out = '"';
  for (const ch of str) {
    const code = ch.codePointAt(0);
    if (ch === '"') {
      out += '\\"';
    } else if (ch === "\\") {
      out += "\\\\";
    } else if (code < 0x20) {
      switch (ch) {
        case "\b": out += "\\b"; break;
        case "\f": out += "\\f"; break;
        case "\n": out += "\\n"; break;
        case "\r": out += "\\r"; break;
        case "\t": out += "\\t"; break;
        default: out += "\\u" + code.toString(16).padStart(4, "0");
      }
    } else if (code >= 0xd800 && code <= 0xdfff) {
      throw new TypeError("canonical: lone surrogates are not valid UTF-8");
    } else {
      out += ch; // non-ASCII emitted literally; "/" NOT escaped
    }
  }
  return out + '"';
}

function emit(value) {
  const type = typeof value;
  if (type === "string") return escapeString(value);
  if (type === "boolean") return value ? "true" : "false";
  if (type === "number") {
    assertInteger(value);
    return String(value);
  }
  if (value === null) {
    throw new TypeError("canonical: null is rejected; omit the key instead");
  }
  if (type === "undefined") {
    throw new TypeError("canonical: undefined is rejected; omit the key instead");
  }
  if (Array.isArray(value)) {
    return "[" + value.map(emit).join(",") + "]";
  }
  if (type === "object") {
    // Object.keys returns own enumerable properties; sort() orders strings by
    // UTF-16 code unit, which is exactly spec rule 1.
    const keys = Object.keys(value).sort();
    return "{" + keys.map((k) => escapeString(k) + ":" + emit(value[k])).join(",") + "}";
  }
  throw new TypeError("canonical: unsupported type " + type);
}

/**
 * Returns the canonical string for `value`.
 * @param {unknown} value
 * @returns {string} keccak256 over the UTF-8 bytes of this string is the
 *   protocol hash (the caller supplies keccak256; this file stays a pure
 *   serializer with zero dependencies).
 */
export function canonicalize(value) {
  return emit(value);
}

export default canonicalize;
