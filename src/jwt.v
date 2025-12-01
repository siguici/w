module w

import time
import json
import encoding.base64
import crypto.hmac
import crypto.sha256

// --------------------------
// Base64URL helpers (RFC7515)
// --------------------------

fn base64url_encode(data []u8) string {
	mut out := base64.encode(data)
	out = out.replace('+', '-').replace('/', '_')
	return out.trim_right('=')
}

fn base64url_decode(data string) ![]u8 {
	mut d := data.replace('-', '+').replace('_', '/')
	padding := d.len % 4
	if padding > 0 {
		d += '='.repeat(4 - padding)
	}
	return base64.decode(d)
}

// --------------------------
// Claims structure
// --------------------------
pub struct Claims {
pub:
	iss       string   // issuer
	sub       string   // subject (user id)
	aud       string   // audience
	iat       i64      // issued at (unix)
	nbf       i64      // not before (unix)
	exp       i64      // expiration (unix)
	jti       string   // token id
	scopes    []string // Laravel Passport scopes
	abilities []string // Laravel Sanctum abilities
	// NOTE: add extra custom claims by extending this struct or embedding a map if needed
}

// --------------------------
// HMAC-SHA256 signing helper
// hmac.new(key, msg, sha256.sum, block_size)
// returns []u8 (raw bytes)
// --------------------------
fn sign_hs256(secret string, msg string) []u8 {
	return hmac.new(secret.bytes(), msg.bytes(), sha256.sum, 64)
}

// --------------------------
// Generate JWT (HS256)
// --------------------------
pub fn generate(claims Claims, secret string) !string {
	header_json := '{"alg":"HS256","typ":"JWT"}'
	header_b64 := base64url_encode(header_json.bytes())

	payload_json := json.encode(claims)
	payload_b64 := base64url_encode(payload_json.bytes())

	message := '${header_b64}.${payload_b64}'
	signature := sign_hs256(secret, message)
	sign_b64 := base64url_encode(signature)

	return '${header_b64}.${payload_b64}.${sign_b64}'
}

// --------------------------
// Verify JWT (HS256) -> returns Claims or error
// --------------------------
pub fn verify(token string, secret string) !Claims {
	parts := token.split('.')
	if parts.len != 3 {
		return error('invalid token format')
	}

	header_b64 := parts[0]
	payload_b64 := parts[1]
	signature_b64 := parts[2]

	// recompute signature
	message := '${header_b64}.${payload_b64}'
	expected_sig := sign_hs256(secret, message)
	expected_sig_b64 := base64url_encode(expected_sig)

	if expected_sig_b64 != signature_b64 {
		return error('invalid signature')
	}

	// decode payload
	payload_bytes := base64url_decode(payload_b64)!
	claims := json.decode(Claims, payload_bytes.bytestr())!

	// time checks
	now := time.now().unix()

	if claims.iat > 0 && now < claims.iat {
		return error('invalid iat: token issued in the future')
	}
	if claims.nbf > 0 && now < claims.nbf {
		return error('token not yet valid (nbf)')
	}
	if claims.exp > 0 && now > claims.exp {
		return error('token expired')
	}

	return claims
}
