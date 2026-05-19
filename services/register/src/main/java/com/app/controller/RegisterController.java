package com.app.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.app.model.User;
import com.app.service.UserService;
//import org.springframework.data.redis.core.StringRedisTemplate;

@RestController
@RequestMapping("/register")
public class RegisterController {

    private final UserService userService;
    //private final StringRedisTemplate redis;
    private static final Logger log = LoggerFactory.getLogger(RegisterController.class);

    public RegisterController(UserService userService) {
        this.userService = userService;
        //this.redis = redis;
    }

    @PostMapping
    public ResponseEntity<?> register(@RequestBody User user) {

        if (user.username == null || user.password == null || user.email == null) {
            return ResponseEntity
                    .badRequest()
                    .body("Missing required fields (username, email, password)");
        }

        log.info("register_attempt username={}", user.username);

        try {
            // 1. Save to DB
            userService.register(user.username, user.email, user.password);

            // 2. Cache user (optional)
            //redis.opsForValue().set(
            //    "user:" + user.username,
            //    user.email
            //);
            log.info("register_success username={}", user.username);

            return ResponseEntity.ok("User registered");

        } catch (Exception e) {
            log.error("register_error {}", e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
