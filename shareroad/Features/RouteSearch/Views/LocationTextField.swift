//
//  LocationTextField.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI

// MARK: - LocationTextField
/// Pickup veya Destination için özel TextField komponenti
struct LocationTextField: View {
    
    // MARK: - Properties
    
    @Binding var text: String
    let placeholder: String
    let iconColor: Color
    let isActive: Bool
    var onTap: (() -> Void)?
    var onClear: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Konum ikonu
            Circle()
                .fill(iconColor)
                .frame(width: 12, height: 12)
            
            // TextField
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .autocapitalization(.words)
                .autocorrectionDisabled()
                .onTapGesture {
                    onTap?()
                }
            
            Spacer()
            
            // Clear butonu (sadece text varken)
            if !text.isEmpty {
                Button {
                    text = ""
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.6))
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.white : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VStack(spacing: 12) {
        LocationTextField(
            text: .constant("Konumum"),
            placeholder: "Nereden?",
            iconColor: .green,
            isActive: true
        )
        
        LocationTextField(
            text: .constant(""),
            placeholder: "Nereye gitmek istersiniz?",
            iconColor: .black,
            isActive: false
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
#endif
