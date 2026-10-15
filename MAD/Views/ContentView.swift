//
//  ContentView.swift
//  MAD
//
//  Created by Fabian Gerö on 21.09.26.
//

import SwiftUI

struct ContentView: View {
    private enum Field {
        case email
        case password
    }
    
    private let networkingService = NetworkingService()
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showValidationError = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @FocusState private var focusedField: Field?
    
    private var isEmailInvalid: Bool {
        showValidationError && email.isEmpty
    }
    
    private var isPasswordInvalid: Bool {
        showValidationError && password.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Login")
                .font(.largeTitle.weight(.bold))
            
            form
            logInButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: 420)
        .tint(.indigo)
        .disabled(isLoading)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            inputRow("Email", systemImage: "envelope", isFocused: focusedField == .email, isInvalid: isEmailInvalid) {
                TextField("E-Mail", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .password
                    }
            }
            
            inputRow("Password", systemImage: "lock", isFocused: focusedField == .password, isInvalid: isPasswordInvalid) {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .keyboardType(.default)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit(logIn)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                Text("Please enter your email and password.")
            }
            .font(.footnote)
            .foregroundStyle(.red)
            .opacity(isEmailInvalid || isPasswordInvalid ? 1 : 0)
        }
    }
    
    private var logInButton: some View {
        Button(action: logIn) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                    Text("Logging in…")
                } else {
                    Text("Log in")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.tint, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
    
    private func inputRow<Input: View>(
        _ title: LocalizedStringKey,
        systemImage: String,
        isFocused: Bool,
        isInvalid: Bool,
        @ViewBuilder input: () -> Input
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(isInvalid ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                    .frame(width: 20)
                    .accessibilityHidden(true)
                
                input()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderStyle(isFocused: isFocused, isInvalid: isInvalid), lineWidth: 1.5)
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
    }
    
    private func borderStyle(isFocused: Bool, isInvalid: Bool) -> AnyShapeStyle {
        if isInvalid {
            return AnyShapeStyle(.red)
        }
        if isFocused {
            return AnyShapeStyle(.tint)
        }
        return AnyShapeStyle(Color.clear)
    }
    
    private func logIn() {
        guard !isLoading else { return }
        
        guard !email.isEmpty, !password.isEmpty else {
            withAnimation {
                showValidationError = true
            }
            focusedField = email.isEmpty ? .email : .password
            return
        }
        
        showValidationError = false
        focusedField = nil
        isLoading = true
        
        networkingService.login(email: email, password: password) { user, error in
            isLoading = false
            
            if let user {
                presentAlert(title: "Logged in", message: "You're now logged in as \(user.email).")
            } else if let error {
                presentAlert(title: "Login failed", message: errorMessage(for: error))
            }
        }
    }
    
    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func errorMessage(for error: NetworkingError) -> String {
        switch error {
        case .serializationFailed(let description):
            return "Your login data couldn't be prepared. \(description)"
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailNotFound:
            return "There's no account with this email address."
        case .wrongPassword:
            return "The password is incorrect. Please try again."
        case .invalidCredentials:
            return "The email or password is incorrect. Please try again."
        case .offline(let description):
            return description
        case .invalidResponseFormat:
            return "The server sent a response that couldn't be read. Please try again later."
        case .serverError(let statusCode, let message):
            if let message {
                return "The server returned an error (\(statusCode)): \(message)"
            }
            return "The server returned an error (\(statusCode)). Please try again later."
        case .unexpected(let description):
            return description
        }
    }
}

#Preview {
    ContentView()
}
