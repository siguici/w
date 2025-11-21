module w

import crypto.bcrypt

@[params]
struct BcryptOptions {
	cost int = 10
}

// Hash a password using bcrypt (Laravel compatible)
pub fn bcrypt_hash(password string, opts BcryptOptions) !string {
	// Default cost in Laravel is 10
	cost := if opts.cost < 4 { 10 } else { opts.cost }
	hash := bcrypt.generate_from_password(password.bytes(), cost)!
	return hash
}

// Verify a plain password against a bcrypt hash
pub fn bcrypt_verify(password string, hashed string) bool {
	return if _ := bcrypt.compare_hash_and_password(password.bytes(), hashed.bytes()) {
		true
	} else {
		false
	}
}
