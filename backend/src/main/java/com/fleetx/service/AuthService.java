package com.fleetx.service;

import com.fleetx.dto.*;
import com.fleetx.entity.Role;
import com.fleetx.entity.User;
import com.fleetx.entity.Wallet;
import com.fleetx.entity.enums.RoleName;
import com.fleetx.exception.ConflictException;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.RoleRepository;
import com.fleetx.repository.UserRepository;
import com.fleetx.repository.WalletRepository;
import com.fleetx.security.JwtService;
import com.fleetx.security.UserPrincipal;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
public class AuthService {

    private static final BigDecimal SIGNUP_WALLET_BONUS = new BigDecimal("500.00");

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final WalletRepository walletRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       RoleRepository roleRepository,
                       WalletRepository walletRepository,
                       PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.walletRepository = walletRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new ConflictException("An account with this email already exists");
        }

        Role driverRole = roleRepository.findByName(RoleName.DRIVER)
                .orElseGet(() -> roleRepository.save(new Role(RoleName.DRIVER)));

        User user = new User();
        user.setName(request.name());
        user.setEmail(request.email());
        user.setPhone(request.phone());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setRole(driverRole);
        userRepository.save(user);

        // Every new driver gets a wallet with demo credit so the payment flow works right away.
        walletRepository.save(new Wallet(user, SIGNUP_WALLET_BONUS));

        return buildAuthResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.email(), request.password()));

            UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
            User user = userRepository.findById(principal.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("User", principal.getId()));

            return buildAuthResponse(user);
        } catch (BadCredentialsException ex) {
            throw new BadCredentialsException("Invalid email or password");
        }
    }

    @Transactional(readOnly = true)
    public UserResponse currentUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        return new UserResponse(user.getId(), user.getName(), user.getEmail(),
                user.getPhone(), user.getRole().getName().name(), user.isActive());
    }

    /** Prototype stub - no email is sent, the demo just confirms the address exists. */
    @Transactional(readOnly = true)
    public MessageResponse forgotPassword(ForgotPasswordRequest request) {
        boolean known = userRepository.existsByEmail(request.email());
        return new MessageResponse(known
                ? "Password reset link sent to " + request.email() + " (simulated - no email is actually sent)"
                : "If an account exists for " + request.email() + ", a reset link has been sent (simulated)");
    }

    /** Prototype stub - the OTP is always 123456. */
    public MessageResponse sendOtp(String phone) {
        return new MessageResponse("OTP sent to " + phone + ". Use 123456 for this demo.");
    }

    /** Prototype stub - accepts the fixed demo OTP only. */
    public MessageResponse verifyOtp(String otp) {
        if (!"123456".equals(otp)) {
            throw new ConflictException("Invalid OTP. Use 123456 for this demo.");
        }
        return new MessageResponse("OTP verified successfully");
    }

    private AuthResponse buildAuthResponse(User user) {
        String token = jwtService.generateToken(UserPrincipal.from(user));
        return new AuthResponse(token, user.getId(), user.getName(), user.getEmail(),
                user.getPhone(), user.getRole().getName().name());
    }
}
