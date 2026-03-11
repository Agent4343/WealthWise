const crypto = require('crypto');

/**
 * Generates a JWT token for APNs HTTP/2 authentication.
 * Apple requires a new token generated at most every 20 minutes and at least every 60 minutes.
 *
 * @param {string} privateKey - PEM-encoded ES256 private key from Apple Developer Portal
 * @param {string} keyId - The Key ID from Apple (10-character string)
 * @param {string} teamId - Your Apple Developer Team ID (10-character string)
 * @returns {string} Signed JWT token
 */
function generateApnsToken(privateKey, keyId, teamId) {
  const header = Buffer.from(JSON.stringify({
    alg: 'ES256',
    kid: keyId,
  })).toString('base64url');

  const payload = Buffer.from(JSON.stringify({
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
  })).toString('base64url');

  const signingInput = `${header}.${payload}`;

  const sign = crypto.createSign('SHA256');
  sign.update(signingInput);
  sign.end();

  const signature = sign.sign({ key: privateKey, dsaEncoding: 'ieee-p1363' }).toString('base64url');

  return `${signingInput}.${signature}`;
}

module.exports = { generateApnsToken };
