package com.fleetx.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.DecodingException;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

/** Issues and validates the HS256 tokens used by the mobile app. */
@Service
public class JwtService {

    private final SecretKey key;
    private final long expirationMs;

    public JwtService(@Value("${fleetx.jwt.secret}") String secret,
                      @Value("${fleetx.jwt.expiration-ms}") long expirationMs) {
        this.key = buildKey(secret);
        this.expirationMs = expirationMs;
    }

    /**
     * HS256 needs at least 32 bytes of key material. Accept either a base64 secret
     * or a plain string from application.properties.
     */
    private static SecretKey buildKey(String secret) {
        byte[] bytes;
        try {
            bytes = Decoders.BASE64.decode(secret);
        } catch (DecodingException | IllegalArgumentException ex) {
            bytes = secret.getBytes(StandardCharsets.UTF_8);
        }
        if (bytes.length < 32) {
            bytes = secret.getBytes(StandardCharsets.UTF_8);
        }
        return Keys.hmacShaKeyFor(bytes);
    }

    public String generateToken(UserPrincipal principal) {
        Date now = new Date();
        return Jwts.builder()
                .subject(principal.getUsername())
                .claims(Map.of(
                        "uid", principal.getId(),
                        "role", principal.getRole()))
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public String extractEmail(String token) {
        return parse(token).getSubject();
    }

    public boolean isValid(String token) {
        try {
            parse(token);
            return true;
        } catch (JwtException | IllegalArgumentException ex) {
            return false;
        }
    }

    private Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
