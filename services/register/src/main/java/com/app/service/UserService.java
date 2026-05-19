package com.app.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final JdbcTemplate jdbc;

    public UserService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void register(String username, String email, String password) {

        String hashed = BCrypt.hashpw(password, BCrypt.gensalt());

        jdbc.update(
            "INSERT INTO users(username, email, password_hash) VALUES (?, ?, ?)",
            username, email, hashed
        );
    }
}