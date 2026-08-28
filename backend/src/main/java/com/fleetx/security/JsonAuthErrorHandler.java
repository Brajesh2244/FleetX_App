package com.fleetx.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fleetx.dto.ApiError;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Returns the same JSON error shape for 401 and 403 as the rest of the API,
 * so the Flutter client can parse every failure the same way.
 */
@Component
public class JsonAuthErrorHandler implements AuthenticationEntryPoint, AccessDeniedHandler {

    private final ObjectMapper objectMapper;

    public JsonAuthErrorHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void commence(jakarta.servlet.http.HttpServletRequest request,
                         HttpServletResponse response,
                         org.springframework.security.core.AuthenticationException authException) throws IOException {
        write(request, response, HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized",
                "Authentication required. Please log in again.");
    }

    @Override
    public void handle(jakarta.servlet.http.HttpServletRequest request,
                       HttpServletResponse response,
                       org.springframework.security.access.AccessDeniedException accessDeniedException) throws IOException {
        write(request, response, HttpServletResponse.SC_FORBIDDEN, "Forbidden",
                "You do not have permission to perform this action.");
    }

    private void write(jakarta.servlet.http.HttpServletRequest request,
                       HttpServletResponse response,
                       int status,
                       String error,
                       String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getWriter(),
                new ApiError(status, error, message, request.getRequestURI()));
    }
}
